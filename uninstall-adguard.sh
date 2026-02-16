#!/bin/bash
# =============================================================================
# uninstall-adguard.sh
# Desinstalle l'ancienne installation binaire d'AdGuard Home (systemd)
# avant la migration vers Docker.
# Usage: sudo ./uninstall-adguard.sh
# =============================================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
    log_error "Ce script doit etre lance en root (sudo)"
    exit 1
fi

echo "============================================="
echo " Desinstallation AdGuard Home (binaire/systemd)"
echo " Migration vers Docker"
echo "============================================="
echo ""

# --- Arreter le service systemd ---
if systemctl is-active --quiet AdGuardHome 2>/dev/null; then
    log_info "Arret du service AdGuardHome..."
    systemctl stop AdGuardHome
    log_info "Service arrete"
else
    log_info "Le service AdGuardHome n'est pas actif"
fi

# --- Desinstaller via le binaire ---
if [ -x "/opt/AdGuardHome/AdGuardHome" ]; then
    log_info "Desinstallation du service via le binaire AdGuard..."
    cd /opt/AdGuardHome
    ./AdGuardHome -s uninstall 2>/dev/null || true
    log_info "Service systemd desinstalle"
else
    log_info "Binaire AdGuard Home non trouve, nettoyage systemd manuel..."
    systemctl disable AdGuardHome 2>/dev/null || true
    rm -f /etc/systemd/system/AdGuardHome.service
    systemctl daemon-reload 2>/dev/null || true
fi

# --- Sauvegarder la config existante ---
BACKUP_DIR="/opt/data/config/adguard"
if [ -f "/opt/AdGuardHome/AdGuardHome.yaml" ]; then
    log_info "Sauvegarde de la configuration vers ${BACKUP_DIR}..."
    mkdir -p "$BACKUP_DIR"
    cp -n /opt/AdGuardHome/AdGuardHome.yaml "$BACKUP_DIR/AdGuardHome.yaml" 2>/dev/null || true
    log_info "Configuration sauvegardee"
fi

# --- Supprimer les fichiers binaires ---
if [ -d "/opt/AdGuardHome" ]; then
    log_info "Suppression de /opt/AdGuardHome..."
    rm -rf /opt/AdGuardHome
    log_info "Repertoire supprime"
else
    log_info "/opt/AdGuardHome n'existe pas"
fi

# --- Supprimer l'ancien conteneur Docker si existant ---
if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^adguardhome$"; then
    log_info "Suppression de l'ancien conteneur Docker adguardhome..."
    docker rm -f adguardhome 2>/dev/null || true
    log_info "Ancien conteneur supprime"
fi

echo ""
log_info "============================================="
log_info " Desinstallation terminee !"
log_info "============================================="
log_info ""
log_info "La configuration a ete sauvegardee dans: ${BACKUP_DIR}/"
log_info "Lancez maintenant install.sh pour deployer AdGuard en Docker."
