#!/bin/bash

# Script de mise à jour Essensys pour Raspberry Pi 4
# Ce script met à jour Nginx, Traefik, Backend et Frontend

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables de configuration
INSTALL_DIR="/opt/essensys"
BACKEND_DIR="$INSTALL_DIR/backend"
FRONTEND_DIR="$INSTALL_DIR/frontend"
SERVICE_USER="essensys"
HOME_DIR="/home/essensys"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NGINX_CONFIG_DIR="$SCRIPT_DIR/nginx-config"
TRAEFIK_CONFIG_DIR="$SCRIPT_DIR/traefik-config"
DOMAIN_FILE="$HOME_DIR/domain.txt"

# Fonction pour afficher les messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier que le script est exécuté en tant que root
if [ "$EUID" -ne 0 ]; then 
    log_error "Ce script doit être exécuté en tant que root (utilisez sudo)"
    exit 1
fi

log_info "Démarrage de la mise à jour Essensys"
log_info "======================================"

# Vérifier que les répertoires existent
if [ ! -d "$HOME_DIR/essensys-server-backend" ]; then
    log_error "Le dépôt backend n'existe pas dans $HOME_DIR/essensys-server-backend"
    exit 1
fi

if [ ! -d "$HOME_DIR/essensys-server-frontend" ]; then
    log_error "Le dépôt frontend n'existe pas dans $HOME_DIR/essensys-server-frontend"
    exit 1
fi

# Arrêter les services avant la mise à jour
log_info "Arrêt des services avant mise à jour..."
systemctl stop essensys-backend || true

# Mettre à jour le backend
log_info "Mise à jour du backend..."
cd "$HOME_DIR/essensys-server-backend"
sudo -u "$SERVICE_USER" git pull
if [ $? -ne 0 ]; then
    log_error "Échec de la mise à jour du backend"
    exit 1
fi

# Recompiler le backend dans le dépôt source (avant copie)
log_info "Recompilation du backend dans le dépôt source..."
export PATH=$PATH:/usr/local/go/bin

# Synchroniser les dépendances
log_info "Synchronisation des dépendances Go..."
cd "$HOME_DIR/essensys-server-backend"
go mod tidy
if [ $? -ne 0 ]; then
    log_warn "go mod tidy a échoué, tentative avec go mod download..."
    go mod download
    go mod tidy
fi

# Compiler dans le dépôt source
log_info "Compilation du binaire..."
go build -o server ./cmd/server
if [ $? -ne 0 ]; then
    log_error "La compilation du backend a échoué"
    exit 1
fi

# Copier les fichiers vers le répertoire d'installation (après arrêt du service)
log_info "Copie des fichiers backend..."
# Copier tout sauf le binaire server (qui sera copié séparément)
rsync -a --exclude='server' "$HOME_DIR/essensys-server-backend/" "$BACKEND_DIR/" 2>/dev/null || \
    find "$HOME_DIR/essensys-server-backend" -mindepth 1 -maxdepth 1 ! -name 'server' -exec cp -r {} "$BACKEND_DIR/" \;

# Copier le nouveau binaire (le service est arrêté, donc pas de conflit)
log_info "Copie du nouveau binaire server..."
cp "$HOME_DIR/essensys-server-backend/server" "$BACKEND_DIR/server"
if [ $? -ne 0 ]; then
    log_error "Échec de la copie du binaire server"
    exit 1
fi

# Valider et corriger le port dans config.yaml si nécessaire
if [ -f "$BACKEND_DIR/config.yaml" ]; then
    current_port=$(grep -E "^[[:space:]]*port:[[:space:]]*[0-9]+" "$BACKEND_DIR/config.yaml" | sed 's/.*port:[[:space:]]*\([0-9]*\).*/\1/' | head -1)
    if [ -n "$current_port" ]; then
        # Vérifier si le port est valide (entre 1 et 65535)
        if [ "$current_port" -lt 1 ] || [ "$current_port" -gt 65535 ]; then
            log_warn "Port invalide détecté ($current_port), correction à 7070..."
            sed -i 's/^\([[:space:]]*port:[[:space:]]*\)[0-9]*/\17070/' "$BACKEND_DIR/config.yaml"
            log_info "Port corrigé à 7070"
        elif [ "$current_port" != "7070" ]; then
            log_info "Port actuel: $current_port (attendu: 7070)"
            sed -i 's/^\([[:space:]]*port:[[:space:]]*\)[0-9]*/\17070/' "$BACKEND_DIR/config.yaml"
            log_info "Port corrigé à 7070"
        fi
    else
        # Si aucun port n'est trouvé, l'ajouter
        log_warn "Aucun port trouvé dans config.yaml, ajout de port: 7070"
        sed -i '/^server:/a\  port: 7070' "$BACKEND_DIR/config.yaml"
    fi
fi

# Mettre à jour le frontend
log_info "Mise à jour du frontend..."
cd "$HOME_DIR/essensys-server-frontend"
sudo -u "$SERVICE_USER" git pull
if [ $? -ne 0 ]; then
    log_error "Échec de la mise à jour du frontend"
    exit 1
fi

# Copier les fichiers vers le répertoire d'installation
log_info "Copie des fichiers frontend..."
cp -r "$HOME_DIR/essensys-server-frontend"/* "$FRONTEND_DIR/"

# Rebuild le frontend
log_info "Rebuild du frontend..."
cd "$FRONTEND_DIR"
sudo -u "$SERVICE_USER" npm install
if [ $? -ne 0 ]; then
    log_error "Échec de l'installation des dépendances frontend"
    exit 1
fi

sudo -u "$SERVICE_USER" npm run build
if [ $? -ne 0 ]; then
    log_error "Le build du frontend a échoué"
    exit 1
fi

if [ ! -d "$FRONTEND_DIR/dist" ]; then
    log_error "Le répertoire dist n'existe pas après le build"
    exit 1
fi

# Configurer les permissions
log_info "Configuration des permissions..."
chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"

# Lire le domaine WAN depuis le fichier domain.txt
WAN_DOMAIN="essensys.acme.com"  # Valeur par défaut
if [ -f "$DOMAIN_FILE" ]; then
    WAN_DOMAIN=$(cat "$DOMAIN_FILE" | tr -d '\n\r ' | head -1)
    if [ -z "$WAN_DOMAIN" ]; then
        log_warn "Le fichier $DOMAIN_FILE est vide, utilisation du domaine par défaut: $WAN_DOMAIN"
    else
        log_info "Domaine WAN lu depuis $DOMAIN_FILE: $WAN_DOMAIN"
    fi
else
    log_warn "Le fichier $DOMAIN_FILE n'existe pas, utilisation du domaine par défaut: $WAN_DOMAIN"
fi

# Mettre à jour la configuration Nginx
log_info "Mise à jour de la configuration Nginx..."
if [ -d "$NGINX_CONFIG_DIR" ]; then
    # Copier le format de log personnalisé pour les API
    if [ -f "$NGINX_CONFIG_DIR/essensys-api-log-format.conf" ]; then
        cp "$NGINX_CONFIG_DIR/essensys-api-log-format.conf" /etc/nginx/conf.d/essensys-api-log-format.conf
        log_info "Format de log nginx mis à jour"
    fi
    
    # Générer la configuration du site à partir du template
    if [ -f "$NGINX_CONFIG_DIR/essensys.template" ]; then
        sed "s|{{FRONTEND_DIR}}|$FRONTEND_DIR|g" "$NGINX_CONFIG_DIR/essensys.template" > /etc/nginx/sites-available/essensys
        log_info "Configuration nginx mise à jour"
        
        # Activer le site et désactiver la configuration par défaut
        ln -sf /etc/nginx/sites-available/essensys /etc/nginx/sites-enabled/
        rm -f /etc/nginx/sites-enabled/default
        
        # Tester la configuration nginx
        nginx -t
        if [ $? -ne 0 ]; then
            log_error "La configuration nginx est invalide"
            exit 1
        fi
    fi
    
    # Mettre à jour la configuration nginx pour le frontend interne
    if [ -f "$TRAEFIK_CONFIG_DIR/nginx-frontend-internal.conf" ]; then
        sed "s|{{FRONTEND_DIR}}|$FRONTEND_DIR|g" "$TRAEFIK_CONFIG_DIR/nginx-frontend-internal.conf" > /etc/nginx/sites-available/essensys-frontend-internal
        ln -sf /etc/nginx/sites-available/essensys-frontend-internal /etc/nginx/sites-enabled/essensys-frontend-internal
        log_info "Configuration nginx frontend interne mise à jour"
        
        # Tester la configuration nginx
        nginx -t
        if [ $? -ne 0 ]; then
            log_error "La configuration nginx est invalide"
            exit 1
        fi
    fi
else
    log_warn "Répertoire nginx-config introuvable, utilisation de la configuration existante"
fi

# Mettre à jour la configuration Traefik
log_info "Mise à jour de la configuration Traefik..."
if [ -d "$TRAEFIK_CONFIG_DIR" ]; then
    # Mettre à jour la configuration principale Traefik
    if [ -f "$TRAEFIK_CONFIG_DIR/traefik.yml" ]; then
        cp "$TRAEFIK_CONFIG_DIR/traefik.yml" /etc/traefik/traefik.yml
        log_info "Configuration Traefik principale mise à jour"
    fi
    
    # Générer les fichiers de configuration dynamique avec le bon chemin frontend et domaine WAN
    if [ -f "$TRAEFIK_CONFIG_DIR/dynamic/local-routes.yml" ]; then
        sed -e "s|{{FRONTEND_DIR}}|$FRONTEND_DIR|g" -e "s|{{WAN_DOMAIN}}|$WAN_DOMAIN|g" "$TRAEFIK_CONFIG_DIR/dynamic/local-routes.yml" > /etc/traefik/dynamic/local-routes.yml
        log_info "Configuration routes locales mise à jour"
    fi
    
    if [ -f "$TRAEFIK_CONFIG_DIR/dynamic/wan-routes.yml" ]; then
        sed -e "s|{{FRONTEND_DIR}}|$FRONTEND_DIR|g" -e "s|{{WAN_DOMAIN}}|$WAN_DOMAIN|g" "$TRAEFIK_CONFIG_DIR/dynamic/wan-routes.yml" > /etc/traefik/dynamic/wan-routes.yml
        log_info "Configuration routes WAN mise à jour avec domaine: $WAN_DOMAIN"
    fi
else
    log_warn "Répertoire traefik-config introuvable, utilisation de la configuration existante"
fi

# Redémarrer les services
log_info "Redémarrage des services..."
log_info "Démarrage du service essensys-backend..."
systemctl start essensys-backend
if [ $? -ne 0 ]; then
    log_error "Échec du démarrage du service essensys-backend"
    exit 1
fi

# Redémarrer Traefik (Traefik ne supporte pas reload, il faut restart)
log_info "Redémarrage de Traefik..."

# Arrêter Traefik proprement avant de redémarrer
log_info "Arrêt de Traefik..."
systemctl stop traefik || true
sleep 2  # Attendre que Traefik s'arrête complètement

# Vérifier qu'aucun processus Traefik ne tourne encore
if pgrep -f "traefik.*configfile" > /dev/null; then
    log_warn "Des processus Traefik sont encore actifs, arrêt forcé..."
    pkill -9 -f "traefik.*configfile" || true
    sleep 1
fi

# Redémarrer Traefik
log_info "Démarrage de Traefik..."
systemctl start traefik
sleep 5  # Attendre un peu plus pour que Traefik démarre

# Redémarrer le service de blocage si nécessaire
if systemctl is-active --quiet traefik-block-service; then
    log_info "Redémarrage du service de blocage..."
    systemctl restart traefik-block-service
fi

# Redémarrer nginx
log_info "Redémarrage de nginx..."
systemctl reload nginx || systemctl restart nginx
if [ $? -ne 0 ]; then
    log_error "Échec du rechargement de nginx"
    exit 1
fi

# Vérifier le statut des services
log_info "Vérification du statut des services..."
sleep 5  # Augmenter le délai pour laisser le temps aux services de démarrer

# Vérifier le backend
if systemctl is-active --quiet essensys-backend; then
    log_info "✓ Backend: actif"
else
    log_error "✗ Backend: inactif"
    log_error "Logs backend:"
    journalctl -u essensys-backend -n 10 --no-pager || true
fi

# Vérifier Traefik
if systemctl is-active --quiet traefik; then
    log_info "✓ Traefik: actif"
elif pgrep -f "traefik.*configfile" > /dev/null; then
    log_warn "⚠ Traefik: processus actif mais systemd indique inactif"
else
    log_error "✗ Traefik: inactif"
    if [ -f "/var/log/traefik/traefik-error.log" ]; then
        tail -20 /var/log/traefik/traefik-error.log || true
    fi
fi

# Vérifier Nginx
if systemctl is-active --quiet nginx; then
    log_info "✓ Nginx: actif"
else
    log_error "✗ Nginx: inactif"
    systemctl status nginx --no-pager -l
fi

log_info ""
log_info "=========================================="
log_info "Mise à jour terminée avec succès!"
log_info "=========================================="
log_info ""
log_info "Services mis à jour:"
log_info "  - Backend Go: compilé et redémarré"
log_info "  - Frontend React: buildé et redéployé"
log_info "  - Traefik: configuration mise à jour et rechargée"
log_info "  - Nginx: configuration mise à jour et rechargée"
log_info ""
log_info "Pour vérifier les logs:"
log_info "  - Backend: tail -f /var/logs/Essensys/backend/console.out.log"
log_info "  - Traefik: tail -f /var/log/traefik/traefik.log"
log_info "  - Nginx: tail -f /var/log/nginx/essensys-error.log"
log_info ""
