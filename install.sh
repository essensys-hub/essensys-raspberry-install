#!/bin/bash

# Script d'installation Essensys pour Raspberry Pi
# Bootstrap minimal : installe les prerequis puis delegue tout a Ansible

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
    log_error "Ce script doit etre execute en tant que root (utilisez sudo)"
    exit 1
fi

# ============================================
# Configuration
# ============================================
SERVICE_USER="essensys"
HOME_DIR="/home/$SERVICE_USER"
BOOTSTRAP_DIR="$HOME_DIR/essensys-raspberry-install"
ANSIBLE_REPO="https://github.com/essensys-hub/essensys-ansible.git"
ANSIBLE_DIR="/opt/essensys-ansible"

ESSENSYS_VERSION="V.1.3.0"
ANSIBLE_REF="$ESSENSYS_VERSION"
INSTALL_REF="$ESSENSYS_VERSION"

DOMAIN_FILE="$HOME_DIR/domain.txt"

log_info "=========================================="
log_info "  Essensys Installer - $ESSENSYS_VERSION"
log_info "=========================================="

# ============================================
# 1. Prerequis systeme (git + ansible)
# ============================================
log_info "1/5 - Prerequis systeme..."
apt-get update -qq

for pkg in git ansible; do
    if ! command -v $pkg >/dev/null 2>&1; then
        log_warn "$pkg non trouve, installation..."
        apt-get install -y -qq $pkg
    else
        log_info "$pkg OK"
    fi
done

# ============================================
# 2. Utilisateur de service
# ============================================
log_info "2/5 - Utilisateur de service..."
if ! id "$SERVICE_USER" &>/dev/null; then
    log_info "Creation de l'utilisateur $SERVICE_USER..."
    useradd -m -s /bin/bash -d "$HOME_DIR" "$SERVICE_USER"
else
    log_info "Utilisateur $SERVICE_USER existant"
fi

# ============================================
# 3. Bootstrap du depot raspberry-install (si curl | bash)
# ============================================
if [ ! -f "${BASH_SOURCE[0]}" ]; then
    log_info "Execution via curl | bash detectee, bootstrap du depot..."
    if [ ! -d "$BOOTSTRAP_DIR/.git" ]; then
        sudo -u "$SERVICE_USER" git clone -b "$INSTALL_REF" \
            "https://github.com/essensys-hub/essensys-raspberry-install.git" "$BOOTSTRAP_DIR"
    else
        sudo -u "$SERVICE_USER" git -C "$BOOTSTRAP_DIR" fetch --all --tags
        sudo -u "$SERVICE_USER" git -C "$BOOTSTRAP_DIR" checkout "$INSTALL_REF"
        sudo -u "$SERVICE_USER" git -C "$BOOTSTRAP_DIR" pull --ff-only || true
    fi
fi

# ============================================
# 4. Saisie du domaine WAN
# ============================================
log_info "3/5 - Configuration du domaine WAN..."
prompt_domain() {
    if [ -r /dev/tty ]; then
        read -r -p "$1" WAN_DOMAIN < /dev/tty
        return 0
    fi
    log_warn "Aucun TTY disponible pour la saisie interactive."
    WAN_DOMAIN=""
    return 1
}

if [ -f "$DOMAIN_FILE" ]; then
    EXISTING_DOMAIN=$(tr -d '[:space:]' < "$DOMAIN_FILE")
    if [ -n "$EXISTING_DOMAIN" ]; then
        log_info "Domaine existant: $EXISTING_DOMAIN"
    else
        log_warn "domain.txt vide."
        log_info "ref: https://essensys-hub.github.io/essensys-raspberry-install/installation/wan/"
        prompt_domain "Domaine WAN (ex: mon.monwan.io): "
        [ -n "$WAN_DOMAIN" ] && echo "$WAN_DOMAIN" > "$DOMAIN_FILE" && chown "$SERVICE_USER:$SERVICE_USER" "$DOMAIN_FILE"
    fi
else
    log_warn "domain.txt absent."
    log_info "ref: https://essensys-hub.github.io/essensys-raspberry-install/installation/wan/"
    prompt_domain "Domaine WAN (ex: mon.monwan.io): "
    if [ -n "$WAN_DOMAIN" ]; then
        echo "$WAN_DOMAIN" > "$DOMAIN_FILE"
        chown "$SERVICE_USER:$SERVICE_USER" "$DOMAIN_FILE"
        log_info "domain.txt cree"
    else
        log_warn "Domaine vide, domain.txt non cree"
    fi
fi

# Resize filesystem si disponible
command -v resize2fs_once >/dev/null 2>&1 && resize2fs_once || true

# ============================================
# 5. Clone/update essensys-ansible et lancer le playbook
# ============================================
log_info "4/5 - Mise a jour essensys-ansible ($ANSIBLE_REF)..."
if [ -d "$ANSIBLE_DIR/.git" ]; then
    git -C "$ANSIBLE_DIR" fetch --all --tags
    git -C "$ANSIBLE_DIR" checkout "$ANSIBLE_REF"
    git -C "$ANSIBLE_DIR" pull --ff-only || true
else
    git clone -b "$ANSIBLE_REF" "$ANSIBLE_REPO" "$ANSIBLE_DIR"
fi

# Creer l'inventory si absent
if [ ! -f "$ANSIBLE_DIR/inventory" ]; then
    cat > "$ANSIBLE_DIR/inventory" <<'EOF'
[raspberrypi]
localhost ansible_connection=local
EOF
fi

log_info "5/5 - Lancement du playbook Ansible..."
if [ ! -f "$ANSIBLE_DIR/install.raspberrypi.yml" ]; then
    log_error "Playbook install.raspberrypi.yml introuvable"
    exit 1
fi

# Installer les collections Ansible requises (community.docker, etc.)
if [ -f "$ANSIBLE_DIR/requirements.yml" ]; then
    log_info "Installation des collections Ansible..."
    ansible-galaxy collection install -r "$ANSIBLE_DIR/requirements.yml" --force
fi

ansible-playbook -i "$ANSIBLE_DIR/inventory" "$ANSIBLE_DIR/install.raspberrypi.yml"

log_info "=========================================="
log_info "  Installation terminee !"
log_info "=========================================="
log_info ""
log_info "Commandes utiles :"
log_info "  docker ps                                  # Conteneurs actifs"
log_info "  docker logs essensys-control-plane         # Logs Control Plane"
log_info "  systemctl status nginx traefik redis docker"
log_info ""
