#!/bin/bash

# Script de correction rapide pour le port invalide dans config.yaml
# Usage: sudo ./fix-port.sh

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

log_info "Correction du port dans config.yaml"
log_info "===================================="

if [ ! -f "$BACKEND_DIR/config.yaml" ]; then
    log_error "Le fichier $BACKEND_DIR/config.yaml n'existe pas"
    exit 1
fi

# Arrêter le service avant modification
log_info "Arrêt du service essensys-backend..."
systemctl stop essensys-backend 2>/dev/null || log_warn "Le service n'était pas démarré"

# Lire le port actuel
current_port=$(grep -E "^[[:space:]]*port:[[:space:]]*[0-9]+" "$BACKEND_DIR/config.yaml" | sed 's/.*port:[[:space:]]*\([0-9]*\).*/\1/' | head -1)

if [ -z "$current_port" ]; then
    log_warn "Aucun port trouvé dans config.yaml, ajout de port: 8080"
    sed -i '/^server:/a\  port: 8080' "$BACKEND_DIR/config.yaml"
    log_info "✓ Port 8080 ajouté"
elif [ "$current_port" -lt 1 ] || [ "$current_port" -gt 65535 ]; then
    log_warn "Port invalide détecté: $current_port"
    log_info "Correction à 8080..."
    sed -i 's/^\([[:space:]]*port:[[:space:]]*\)[0-9]*/\18080/' "$BACKEND_DIR/config.yaml"
    log_info "✓ Port corrigé à 8080"
elif [ "$current_port" != "8080" ]; then
    log_warn "Port actuel: $current_port (attendu: 8080)"
    read -p "Voulez-vous le corriger à 8080? (oui/non): " confirm
    if [ "$confirm" = "oui" ]; then
        sed -i 's/^\([[:space:]]*port:[[:space:]]*\)[0-9]*/\18080/' "$BACKEND_DIR/config.yaml"
        log_info "✓ Port corrigé à 8080"
    else
        log_info "Port conservé à $current_port"
    fi
else
    log_info "✓ Port déjà correct: 8080"
fi

# Vérifier la correction
new_port=$(grep -E "^[[:space:]]*port:[[:space:]]*[0-9]+" "$BACKEND_DIR/config.yaml" | sed 's/.*port:[[:space:]]*\([0-9]*\).*/\1/' | head -1)
log_info "Port actuel dans config.yaml: $new_port"

# Redémarrer le service
log_info "Redémarrage du service essensys-backend..."
systemctl start essensys-backend
if [ $? -eq 0 ]; then
    log_info "✓ Service redémarré avec succès"
    sleep 2
    systemctl status essensys-backend --no-pager -l | head -10
else
    log_error "Échec du démarrage du service"
    exit 1
fi

log_info ""
log_info "Correction terminée!"

