#!/bin/bash

# Script de mise à jour pour Essensys avec Traefik
# Met à jour le backend, le frontend et la configuration Traefik

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Variables
INSTALL_DIR="/opt/essensys"
BACKEND_DIR="$INSTALL_DIR/backend"
FRONTEND_DIR="$INSTALL_DIR/frontend"
HOME_DIR="/home/essensys"
SERVICE_USER="essensys"
BACKEND_REPO="https://github.com/essensys-hub/essensys-server-backend.git"
FRONTEND_REPO="https://github.com/essensys-hub/essensys-server-frontend.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

log_info "Mise à jour Essensys avec Traefik"

# Arrêter le service backend avant la compilation
log_info "Arrêt du service backend..."
systemctl stop essensys-backend || true

# Mettre à jour le backend
log_info "Mise à jour du backend..."
if [ -d "$HOME_DIR/essensys-server-backend" ]; then
    cd "$HOME_DIR/essensys-server-backend"
    sudo -u "$SERVICE_USER" git pull
    log_info "Backend mis à jour"
    
    # Copier vers le répertoire d'installation
    log_info "Copie des fichiers backend..."
    cp -r "$HOME_DIR/essensys-server-backend"/* "$BACKEND_DIR/"
    
    # Compiler le backend
    if [ -f "$BACKEND_DIR/go.mod" ]; then
        log_info "Compilation du backend..."
        cd "$BACKEND_DIR"
        
        # Exporter le PATH pour Go
        export PATH=$PATH:/usr/local/go/bin
        
        # Synchroniser les dépendances
        log_info "Synchronisation des dépendances Go..."
        go mod tidy
        if [ $? -ne 0 ]; then
            log_warn "go mod tidy a échoué, tentative avec go mod download..."
            go mod download
            go mod tidy
        fi
        
        # Compiler
        log_info "Compilation du binaire..."
        go build -o server ./cmd/server
        if [ $? -ne 0 ]; then
            log_error "La compilation du backend a échoué"
            log_error "Vérifiez que toutes les dépendances sont disponibles"
            exit 1
        fi
        
        # Vérifier et corriger le port dans config.yaml
        if [ -f "$BACKEND_DIR/config.yaml" ]; then
            current_port=$(grep -E "^[[:space:]]*port:[[:space:]]*[0-9]+" "$BACKEND_DIR/config.yaml" | sed 's/.*port:[[:space:]]*\([0-9]*\).*/\1/')
            if [ -n "$current_port" ] && [ "$current_port" != "8080" ]; then
                sed -i 's/^\([[:space:]]*port:[[:space:]]*\)[0-9]*/\18080/' "$BACKEND_DIR/config.yaml"
                log_info "Port configuré à 8080 dans config.yaml"
            elif [ -z "$current_port" ]; then
                sed -i '/^server:/a\  port: 8080' "$BACKEND_DIR/config.yaml"
                log_info "Port 8080 ajouté dans config.yaml"
            fi
        fi
        
        log_info "Backend compilé avec succès"
    else
        log_error "Le fichier go.mod n'a pas été trouvé dans $BACKEND_DIR"
        exit 1
    fi
else
    log_error "Le répertoire backend n'existe pas: $HOME_DIR/essensys-server-backend"
    exit 1
fi

# Mettre à jour le frontend
log_info "Mise à jour du frontend..."
if [ -d "$HOME_DIR/essensys-server-frontend" ]; then
    cd "$HOME_DIR/essensys-server-frontend"
    sudo -u "$SERVICE_USER" git pull
    log_info "Frontend mis à jour"
    
    # Copier vers le répertoire d'installation
    log_info "Copie des fichiers frontend..."
    cp -r "$HOME_DIR/essensys-server-frontend"/* "$FRONTEND_DIR/"
    
    # Installer les dépendances et builder
    if [ -f "$FRONTEND_DIR/package.json" ]; then
        log_info "Installation des dépendances frontend..."
        cd "$FRONTEND_DIR"
        npm install
        
        log_info "Build du frontend pour la production..."
        npm run build
        
        if [ ! -d "$FRONTEND_DIR/dist" ]; then
            log_error "Le build du frontend a échoué"
            exit 1
        fi
        
        log_info "Frontend buildé avec succès"
    else
        log_error "Le fichier package.json n'a pas été trouvé dans $FRONTEND_DIR"
        exit 1
    fi
else
    log_error "Le répertoire frontend n'existe pas: $HOME_DIR/essensys-server-frontend"
    exit 1
fi

# Configurer les permissions
log_info "Configuration des permissions..."
chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"

# Mettre à jour la configuration Traefik si nécessaire
log_info "Mise à jour de la configuration Traefik..."
if [ -d "$SCRIPT_DIR/traefik-config" ]; then
    # Copier le format de log personnalisé pour les API (si nécessaire)
    if [ -f "$SCRIPT_DIR/traefik-config/essensys-api-log-format.conf" ]; then
        cp "$SCRIPT_DIR/traefik-config/essensys-api-log-format.conf" /etc/nginx/conf.d/essensys-api-log-format.conf 2>/dev/null || true
    fi
    
    # Mettre à jour la configuration principale Traefik
    if [ -f "$SCRIPT_DIR/traefik-config/traefik.yml" ]; then
        cp "$SCRIPT_DIR/traefik-config/traefik.yml" /etc/traefik/traefik.yml
        log_info "Configuration Traefik principale mise à jour"
    fi
    
    # Générer les fichiers de configuration dynamique avec le bon chemin frontend
    if [ -f "$SCRIPT_DIR/traefik-config/dynamic/local-routes.yml" ]; then
        sed "s|{{FRONTEND_DIR}}|$FRONTEND_DIR|g" "$SCRIPT_DIR/traefik-config/dynamic/local-routes.yml" > /etc/traefik/dynamic/local-routes.yml
        log_info "Configuration routes locales mise à jour"
    fi
    
    if [ -f "$SCRIPT_DIR/traefik-config/dynamic/wan-routes.yml" ]; then
        sed "s|{{FRONTEND_DIR}}|$FRONTEND_DIR|g" "$SCRIPT_DIR/traefik-config/dynamic/wan-routes.yml" > /etc/traefik/dynamic/wan-routes.yml
        log_info "Configuration routes WAN mise à jour"
    fi
    
    # Mettre à jour la configuration nginx pour le frontend interne
    if [ -f "$SCRIPT_DIR/traefik-config/nginx-frontend-internal.conf" ]; then
        sed "s|{{FRONTEND_DIR}}|$FRONTEND_DIR|g" "$SCRIPT_DIR/traefik-config/nginx-frontend-internal.conf" > /etc/nginx/sites-available/essensys-frontend-internal
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
systemctl restart traefik
if [ $? -ne 0 ]; then
    log_error "Échec du redémarrage de Traefik"
    exit 1
fi

# Redémarrer le service de blocage si nécessaire
if systemctl is-active --quiet traefik-block-service; then
    log_info "Redémarrage du service de blocage..."
    systemctl restart traefik-block-service
fi

# Redémarrer nginx si nécessaire
if systemctl is-active --quiet nginx; then
    log_info "Redémarrage de nginx..."
    systemctl reload nginx || systemctl restart nginx
    if [ $? -ne 0 ]; then
        log_error "Échec du rechargement de nginx"
        exit 1
    fi
fi

# Vérifier le statut des services
log_info "Vérification du statut des services..."
sleep 2
if systemctl is-active --quiet essensys-backend; then
    log_info "✓ Backend: actif"
else
    log_error "✗ Backend: inactif"
fi

if systemctl is-active --quiet traefik; then
    log_info "✓ Traefik: actif"
else
    log_error "✗ Traefik: inactif"
fi

if systemctl is-active --quiet nginx; then
    log_info "✓ Nginx: actif"
else
    log_warn "⚠ Nginx: inactif (peut être normal si non utilisé)"
fi

# Note: Pas de commit/push automatique dans le script update
# Les modifications doivent être commitées manuellement si nécessaire

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
log_info "  - Nginx: tail -f /var/log/nginx/frontend-internal-error.log"
log_info ""

