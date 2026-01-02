#!/bin/bash

# Script pour basculer de la configuration sans nginx vers la configuration avec nginx
# Ce script arrête les services sans nginx et prépare pour la configuration avec nginx

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables de configuration
BACKEND_DIR="/opt/essensys/backend"

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

log_info "Basculement vers la configuration avec nginx"
log_info "============================================="

# Arrêter les services sans nginx
log_info "Arrêt des services sans nginx..."

if systemctl is-active --quiet essensys-backend 2>/dev/null; then
    log_info "Arrêt du service essensys-backend..."
    systemctl stop essensys-backend
fi

if systemctl is-active --quiet essensys-frontend 2>/dev/null; then
    log_info "Arrêt du service essensys-frontend..."
    systemctl stop essensys-frontend
fi

# Désactiver les services sans nginx
if systemctl is-enabled --quiet essensys-frontend 2>/dev/null; then
    log_info "Désactivation du service essensys-frontend..."
    systemctl disable essensys-frontend
fi

# Vérifier ce qui utilise le port 8080
log_info "Vérification du port 8080..."
PORT_8080_PID=$(lsof -ti:8080 2>/dev/null || netstat -tlnp 2>/dev/null | grep :8080 | awk '{print $7}' | cut -d'/' -f1 | head -1)
if [ -n "$PORT_8080_PID" ]; then
    log_warn "Le port 8080 est utilisé par le processus PID: $PORT_8080_PID"
    PROCESS_NAME=$(ps -p "$PORT_8080_PID" -o comm= 2>/dev/null || echo "inconnu")
    log_warn "Processus: $PROCESS_NAME"
    
    read -p "Voulez-vous arrêter ce processus? (oui/non): " kill_process
    if [ "$kill_process" = "oui" ]; then
        log_info "Arrêt du processus $PORT_8080_PID..."
        kill "$PORT_8080_PID" 2>/dev/null || kill -9 "$PORT_8080_PID" 2>/dev/null || log_warn "Impossible d'arrêter le processus"
        sleep 2
    fi
fi

# Vérifier ce qui utilise le port 80
log_info "Vérification du port 80..."
PORT_80_PID=$(lsof -ti:80 2>/dev/null || netstat -tlnp 2>/dev/null | grep :80 | awk '{print $7}' | cut -d'/' -f1 | head -1)
if [ -n "$PORT_80_PID" ]; then
    log_warn "Le port 80 est utilisé par le processus PID: $PORT_80_PID"
    PROCESS_NAME=$(ps -p "$PORT_80_PID" -o comm= 2>/dev/null || echo "inconnu")
    log_warn "Processus: $PROCESS_NAME"
    
    if [ "$PROCESS_NAME" != "nginx" ]; then
        read -p "Voulez-vous arrêter ce processus? (oui/non): " kill_process
        if [ "$kill_process" = "oui" ]; then
            log_info "Arrêt du processus $PORT_80_PID..."
            kill "$PORT_80_PID" 2>/dev/null || kill -9 "$PORT_80_PID" 2>/dev/null || log_warn "Impossible d'arrêter le processus"
            sleep 2
        fi
    else
        log_info "Nginx utilise déjà le port 80, c'est normal"
    fi
fi

# Modifier la configuration backend pour utiliser le port 8080
log_info "Configuration du backend pour le port 8080..."
if [ -f "$BACKEND_DIR/config.yaml" ]; then
    current_port=$(grep -E "^[[:space:]]*port:[[:space:]]*[0-9]+" "$BACKEND_DIR/config.yaml" | sed 's/.*port:[[:space:]]*\([0-9]*\).*/\1/' | head -1)
    if [ -n "$current_port" ] && [ "$current_port" != "8080" ]; then
        log_info "Modification du port de $current_port à 8080..."
        sed -i 's/^\([[:space:]]*port:[[:space:]]*\)[0-9]*/\18080/' "$BACKEND_DIR/config.yaml"
        log_info "✓ Port configuré à 8080"
    elif [ "$current_port" = "8080" ]; then
        log_info "✓ Port déjà configuré à 8080"
    else
        log_warn "Aucun port trouvé, ajout de port: 8080"
        sed -i '/^server:/a\  port: 8080' "$BACKEND_DIR/config.yaml"
    fi
else
    log_warn "Fichier config.yaml introuvable, il sera créé lors de l'installation"
fi

# Vérifier que nginx est installé
if ! command -v nginx &> /dev/null; then
    log_warn "Nginx n'est pas installé"
    read -p "Voulez-vous installer nginx? (oui/non): " install_nginx
    if [ "$install_nginx" = "oui" ]; then
        log_info "Installation de nginx..."
        apt-get update
        apt-get install -y nginx
    else
        log_error "Nginx est requis pour cette configuration"
        exit 1
    fi
fi

log_info ""
log_info "=========================================="
log_info "Basculement terminé!"
log_info "=========================================="
log_info ""
log_info "Prochaines étapes:"
log_info "  1. Exécutez: sudo ./install.sh"
log_info "     (ou relancez l'installation avec nginx)"
log_info ""
log_info "  2. Vérifiez que les ports sont libres:"
log_info "     sudo lsof -i :80"
log_info "     sudo lsof -i :8080"
log_info "     sudo lsof -i :9090"
log_info ""
log_info "Configuration attendue:"
log_info "  - Backend: port 8080"
log_info "  - Nginx: port 80 (API) et port 9090 (frontend)"
log_info ""

