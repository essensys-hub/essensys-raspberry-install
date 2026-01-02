#!/bin/bash

# Script de désinstallation Essensys pour Raspberry Pi 4
# Ce script supprime complètement l'installation Essensys

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables de configuration
INSTALL_DIR="/opt/essensys"
SERVICE_USER="essensys"
HOME_DIR="/home/essensys"

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

log_info "Démarrage de la désinstallation Essensys"
log_info "========================================="

# Demander confirmation
log_warn "ATTENTION: Cette opération va supprimer complètement l'installation Essensys"
log_warn "Les données suivantes seront supprimées:"
log_warn "  - Services systemd (essensys-backend, traefik, traefik-block-service)"
log_warn "  - Configuration nginx (essensys, essensys-frontend-internal)"
log_warn "  - Configuration Traefik (/etc/traefik)"
log_warn "  - Fichiers d'installation dans $INSTALL_DIR (backend, frontend)"
log_warn "  - Logs dans /var/logs/Essensys et /var/log/traefik"
log_warn ""
read -p "Voulez-vous vraiment continuer? (tapez 'oui' pour confirmer): " confirmation

if [ "$confirmation" != "oui" ]; then
    log_info "Désinstallation annulée"
    exit 0
fi

# Arrêter et désactiver les services
log_info "Arrêt et désactivation des services..."

# Service backend
if systemctl is-active --quiet essensys-backend 2>/dev/null; then
    log_info "Arrêt du service essensys-backend..."
    systemctl stop essensys-backend
fi

if systemctl is-enabled --quiet essensys-backend 2>/dev/null; then
    log_info "Désactivation du service essensys-backend..."
    systemctl disable essensys-backend
fi

# Service Traefik
if systemctl is-active --quiet traefik 2>/dev/null; then
    log_info "Arrêt du service traefik..."
    systemctl stop traefik
fi

if systemctl is-enabled --quiet traefik 2>/dev/null; then
    log_info "Désactivation du service traefik..."
    systemctl disable traefik
fi

# Service Traefik Block Service
if systemctl is-active --quiet traefik-block-service 2>/dev/null; then
    log_info "Arrêt du service traefik-block-service..."
    systemctl stop traefik-block-service
fi

if systemctl is-enabled --quiet traefik-block-service 2>/dev/null; then
    log_info "Désactivation du service traefik-block-service..."
    systemctl disable traefik-block-service
fi

# Supprimer les fichiers de service systemd
log_info "Suppression des fichiers de service systemd..."
SERVICES_REMOVED=false

if [ -f "/etc/systemd/system/essensys-backend.service" ]; then
    rm -f /etc/systemd/system/essensys-backend.service
    log_info "✓ Fichier essensys-backend.service supprimé"
    SERVICES_REMOVED=true
fi

if [ -f "/etc/systemd/system/traefik.service" ]; then
    rm -f /etc/systemd/system/traefik.service
    log_info "✓ Fichier traefik.service supprimé"
    SERVICES_REMOVED=true
fi

if [ -f "/etc/systemd/system/traefik-block-service.service" ]; then
    rm -f /etc/systemd/system/traefik-block-service.service
    log_info "✓ Fichier traefik-block-service.service supprimé"
    SERVICES_REMOVED=true
fi

if [ "$SERVICES_REMOVED" = true ]; then
    systemctl daemon-reload
    systemctl reset-failed
fi

# Supprimer la configuration nginx
log_info "Suppression de la configuration nginx..."
NGINX_CONFIG_REMOVED=false

# Configuration principale essensys
if [ -f "/etc/nginx/sites-available/essensys" ]; then
    rm -f /etc/nginx/sites-available/essensys
    log_info "✓ Configuration nginx essensys supprimée"
    NGINX_CONFIG_REMOVED=true
fi

if [ -L "/etc/nginx/sites-enabled/essensys" ]; then
    rm -f /etc/nginx/sites-enabled/essensys
    log_info "✓ Lien symbolique nginx essensys supprimé"
    NGINX_CONFIG_REMOVED=true
fi

# Configuration frontend interne (pour Traefik)
if [ -f "/etc/nginx/sites-available/essensys-frontend-internal" ]; then
    rm -f /etc/nginx/sites-available/essensys-frontend-internal
    log_info "✓ Configuration nginx frontend interne supprimée"
    NGINX_CONFIG_REMOVED=true
fi

if [ -L "/etc/nginx/sites-enabled/essensys-frontend-internal" ]; then
    rm -f /etc/nginx/sites-enabled/essensys-frontend-internal
    log_info "✓ Lien symbolique nginx frontend interne supprimé"
    NGINX_CONFIG_REMOVED=true
fi

# Supprimer aussi le format de log personnalisé
if [ -f "/etc/nginx/conf.d/essensys-api-log-format.conf" ]; then
    rm -f /etc/nginx/conf.d/essensys-api-log-format.conf
    log_info "✓ Format de log nginx supprimé"
    NGINX_CONFIG_REMOVED=true
fi

# Recharger nginx seulement si la configuration a été modifiée et si nginx est actif
if [ "$NGINX_CONFIG_REMOVED" = true ] && systemctl is-active --quiet nginx 2>/dev/null; then
    log_info "Test de la configuration nginx..."
    if nginx -t 2>/dev/null; then
        log_info "Rechargement de nginx..."
        systemctl reload nginx
        if [ $? -ne 0 ]; then
            log_warn "Échec du rechargement de nginx (peut être normal si aucun site n'est configuré)"
        fi
    else
        log_warn "La configuration nginx est invalide (peut être normal après suppression)"
        # Essayer de redémarrer nginx si possible, sinon l'arrêter
        if [ -f "/etc/nginx/sites-enabled/default" ] || [ "$(ls -A /etc/nginx/sites-enabled/ 2>/dev/null)" ]; then
            log_info "Tentative de redémarrage de nginx..."
            systemctl restart nginx 2>/dev/null || log_warn "Impossible de redémarrer nginx"
        else
            log_info "Aucun site nginx configuré, arrêt de nginx..."
            systemctl stop nginx 2>/dev/null || log_warn "Impossible d'arrêter nginx"
        fi
    fi
fi

# Supprimer les fichiers d'installation
log_info "Suppression des fichiers d'installation..."
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    log_info "✓ Répertoire $INSTALL_DIR supprimé"
else
    log_info "Le répertoire $INSTALL_DIR n'existe pas"
fi

# Supprimer les logs
log_info "Suppression des logs..."
if [ -d "/var/logs/Essensys" ]; then
    rm -rf /var/logs/Essensys
    log_info "✓ Répertoire de logs /var/logs/Essensys supprimé"
else
    log_info "Le répertoire de logs n'existe pas"
fi

# Supprimer la configuration Traefik
log_info "Suppression de la configuration Traefik..."
if [ -d "/etc/traefik" ]; then
    rm -rf /etc/traefik
    log_info "✓ Configuration Traefik supprimée (/etc/traefik)"
else
    log_info "Le répertoire /etc/traefik n'existe pas"
fi

# Supprimer le binaire Traefik
if [ -f "/usr/local/bin/traefik" ]; then
    rm -f /usr/local/bin/traefik
    log_info "✓ Binaire Traefik supprimé"
fi

# Supprimer le script de service de blocage
if [ -f "/usr/local/bin/traefik-block-service.py" ]; then
    rm -f /usr/local/bin/traefik-block-service.py
    log_info "✓ Script traefik-block-service.py supprimé"
fi

# Supprimer les logs Traefik
log_info "Suppression des logs Traefik..."
if [ -d "/var/log/traefik" ]; then
    rm -rf /var/log/traefik
    log_info "✓ Répertoire de logs Traefik supprimé (/var/log/traefik)"
else
    log_info "Le répertoire de logs Traefik n'existe pas"
fi

# Supprimer les logs nginx spécifiques à Essensys
log_info "Nettoyage des logs nginx..."
if [ -f "/var/log/nginx/essensys-access.log" ]; then
    rm -f /var/log/nginx/essensys-access.log
    log_info "✓ Log nginx essensys-access.log supprimé"
fi
if [ -f "/var/log/nginx/essensys-error.log" ]; then
    rm -f /var/log/nginx/essensys-error.log
    log_info "✓ Log nginx essensys-error.log supprimé"
fi
if [ -f "/var/log/nginx/essensys-api-detailed.log" ]; then
    rm -f /var/log/nginx/essensys-api-detailed.log
    log_info "✓ Log nginx essensys-api-detailed.log supprimé"
fi
if [ -f "/var/log/nginx/essensys-api-trace.log" ]; then
    rm -f /var/log/nginx/essensys-api-trace.log
    log_info "✓ Log nginx essensys-api-trace.log supprimé"
fi
if [ -f "/var/log/nginx/essensys-api-error.log" ]; then
    rm -f /var/log/nginx/essensys-api-error.log
    log_info "✓ Log nginx essensys-api-error.log supprimé"
fi
if [ -f "/var/log/nginx/frontend-internal-error.log" ]; then
    rm -f /var/log/nginx/frontend-internal-error.log
    log_info "✓ Log nginx frontend-internal-error.log supprimé"
fi

# Demander si on veut supprimer l'utilisateur et les dépôts
log_warn ""
log_warn "L'utilisateur $SERVICE_USER et les dépôts dans $HOME_DIR seront conservés"
log_warn "Si vous voulez les supprimer également, répondez 'oui' à la question suivante"
read -p "Voulez-vous supprimer l'utilisateur $SERVICE_USER et ses dépôts? (oui/non): " delete_user

if [ "$delete_user" = "oui" ]; then
    log_info "Suppression de l'utilisateur et des dépôts..."
    
    # Supprimer les dépôts
    if [ -d "$HOME_DIR/essensys-server-backend" ]; then
        rm -rf "$HOME_DIR/essensys-server-backend"
        log_info "✓ Dépôt backend supprimé"
    fi
    
    if [ -d "$HOME_DIR/essensys-server-frontend" ]; then
        rm -rf "$HOME_DIR/essensys-server-frontend"
        log_info "✓ Dépôt frontend supprimé"
    fi
    
    # Supprimer l'utilisateur
    if id "$SERVICE_USER" &>/dev/null; then
        userdel -r "$SERVICE_USER" 2>/dev/null || userdel "$SERVICE_USER"
        log_info "✓ Utilisateur $SERVICE_USER supprimé"
    else
        log_info "L'utilisateur $SERVICE_USER n'existe pas"
    fi
else
    log_info "Conservation de l'utilisateur $SERVICE_USER et des dépôts"
    log_info "  - Dépôts conservés dans: $HOME_DIR"
    log_info "  - Utilisateur conservé: $SERVICE_USER"
fi

log_info ""
log_info "=========================================="
log_info "Désinstallation terminée avec succès!"
log_info "=========================================="
log_info ""
log_info "Résumé des suppressions:"
log_info "  ✓ Services systemd supprimés (essensys-backend, traefik, traefik-block-service)"
log_info "  ✓ Configuration nginx supprimée (essensys, essensys-frontend-internal)"
log_info "  ✓ Configuration Traefik supprimée (/etc/traefik)"
log_info "  ✓ Binaires supprimés (traefik, traefik-block-service.py)"
log_info "  ✓ Fichiers d'installation supprimés ($INSTALL_DIR)"
log_info "  ✓ Logs supprimés (/var/logs/Essensys, /var/log/traefik, logs nginx)"
if [ "$delete_user" = "oui" ]; then
    log_info "  ✓ Utilisateur $SERVICE_USER supprimé"
    log_info "  ✓ Dépôts supprimés"
else
    log_info "  - Utilisateur $SERVICE_USER conservé"
    log_info "  - Dépôts conservés dans $HOME_DIR"
fi
log_info ""
log_info "Pour réinstaller, exécutez: sudo ./install.sh"
log_info ""

