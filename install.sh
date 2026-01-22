#!/bin/bash

# Script d'installation Essensys pour Raspberry Pi
# Verifie Git + Ansible, puis clone ou met a jour essensys-ansible

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

if [ "$EUID" -ne 0 ]; then
    log_error "Ce script doit etre execute en tant que root (utilisez sudo)"
    exit 1
fi

SERVICE_USER="essensys"
HOME_DIR="/home/$SERVICE_USER"
BOOTSTRAP_DIR="$HOME_DIR/essensys-raspberry-install"
REPO_URL="https://github.com/essensys-hub/essensys-ansible.git"
TARGET_DIR="/opt/essensys-ansible"

log_info "Verification des prerequis (git, ansible)..."

apt-get update

if ! command -v git >/dev/null 2>&1; then
    log_warn "Git non trouve, installation..."
    apt-get install -y git
else
    log_info "Git deja installe"
fi

if [ ! -f "${BASH_SOURCE[0]}" ]; then
    log_info "Execution via curl | bash detectee, bootstrap du depot..."
    if ! id "$SERVICE_USER" &>/dev/null; then
        log_info "Creation de l'utilisateur $SERVICE_USER..."
        useradd -m -s /bin/bash -d "$HOME_DIR" "$SERVICE_USER"
    fi
    if [ ! -d "$BOOTSTRAP_DIR/.git" ]; then
        log_info "Clonage de essensys-raspberry-install dans $BOOTSTRAP_DIR..."
        sudo -u "$SERVICE_USER" git clone "https://github.com/essensys-hub/essensys-raspberry-install.git" "$BOOTSTRAP_DIR"
    else
        log_info "Depot essensys-raspberry-install deja present, mise a jour..."
        sudo -u "$SERVICE_USER" git -C "$BOOTSTRAP_DIR" pull --ff-only
    fi
fi

if command -v resize2fs_once >/dev/null 2>&1; then
    log_info "Execution de resize2fs_once..."
    resize2fs_once
else
    log_warn "resize2fs_once introuvable, etape ignoree"
fi

if ! command -v ansible-playbook >/dev/null 2>&1; then
    log_warn "Ansible non trouve, installation..."
    apt-get install -y ansible
else
    log_info "Ansible deja installe"
fi

if [ -d "$TARGET_DIR/.git" ]; then
    log_info "Depot deja present, mise a jour..."
    git -C "$TARGET_DIR" pull --ff-only
else
    log_info "Clonage du depot essensys-ansible..."
    git clone "$REPO_URL" "$TARGET_DIR"
fi

log_info "Lancement du playbook d'installation Raspberry Pi..."
if [ ! -f "$TARGET_DIR/inventory" ]; then
    log_error "Fichier inventory introuvable dans $TARGET_DIR"
    exit 1
fi

if [ ! -f "$TARGET_DIR/install.raspberrypi.yml" ]; then
    log_error "Playbook install.raspberrypi.yml introuvable dans $TARGET_DIR"
    exit 1
fi

ansible-playbook -i "$TARGET_DIR/inventory" "$TARGET_DIR/install.raspberrypi.yml"

log_info "Termine. Installation lancee via Ansible."
