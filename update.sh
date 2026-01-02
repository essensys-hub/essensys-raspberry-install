#!/bin/bash

# Script de mise à jour Essensys pour Raspberry Pi 4
# Ce script met à jour les dépôts, recompile et redémarre les services

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

# Mettre à jour le backend
log_info "Mise à jour du backend..."
cd "$HOME_DIR/essensys-server-backend"
sudo -u "$SERVICE_USER" git pull
if [ $? -ne 0 ]; then
    log_error "Échec de la mise à jour du backend"
    exit 1
fi

# Copier les fichiers vers le répertoire d'installation
log_info "Copie des fichiers backend..."
cp -r "$HOME_DIR/essensys-server-backend"/* "$BACKEND_DIR/"

# Recompiler le backend
log_info "Recompilation du backend..."
cd "$BACKEND_DIR"
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
    exit 1
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

# Redémarrer les services
log_info "Redémarrage des services..."
systemctl restart essensys-backend
if [ $? -ne 0 ]; then
    log_error "Échec du redémarrage du service essensys-backend"
    exit 1
fi

systemctl reload nginx
if [ $? -ne 0 ]; then
    log_error "Échec du rechargement de nginx"
    exit 1
fi

# Vérifier le statut des services
log_info "Vérification du statut des services..."
sleep 2
if systemctl is-active --quiet essensys-backend; then
    log_info "✓ Service essensys-backend est actif"
else
    log_error "✗ Service essensys-backend n'est pas actif"
    systemctl status essensys-backend --no-pager -l
    exit 1
fi

if systemctl is-active --quiet nginx; then
    log_info "✓ Service nginx est actif"
else
    log_error "✗ Service nginx n'est pas actif"
    systemctl status nginx --no-pager -l
    exit 1
fi

# Mettre à jour ce dépôt (essensys-raspberry-install) si on est dans le bon répertoire
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/.git" ]; then
    log_info "Mise à jour du dépôt essensys-raspberry-install..."
    cd "$SCRIPT_DIR"
    
    # Vérifier s'il y a des modifications
    if [ -n "$(git status --porcelain)" ]; then
        log_info "Modifications détectées dans le dépôt, commit et push..."
        git add -A
        git commit -m "Mise à jour automatique après update.sh - $(date '+%Y-%m-%d %H:%M:%S')"
        git push
        if [ $? -eq 0 ]; then
            log_info "✓ Commit et push effectués avec succès"
        else
            log_warn "⚠ Échec du push (peut-être pas de remote configuré)"
        fi
    else
        log_info "Aucune modification dans le dépôt essensys-raspberry-install"
    fi
fi

log_info ""
log_info "=========================================="
log_info "Mise à jour terminée avec succès!"
log_info "=========================================="
log_info ""
log_info "Services redémarrés:"
log_info "  - essensys-backend"
log_info "  - nginx"
log_info ""
log_info "Pour vérifier les logs:"
log_info "  journalctl -u essensys-backend -f"
log_info "  tail -f /var/log/nginx/essensys-error.log"
log_info ""
log_info "Pour tester:"
log_info "  curl http://localhost/health"
log_info "  curl http://localhost:8080/health"
log_info ""

