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

# Versions des dépôts (alignées avec ansible vars)
ESSENSYS_VERSION="V.1.2.2"
ANSIBLE_REF="$ESSENSYS_VERSION"
INSTALL_REF="$ESSENSYS_VERSION"

DOMAIN_FILE="$HOME_DIR/domain.txt"

log_info "=========================================="
log_info "Installation Essensys - Version $ESSENSYS_VERSION"
log_info "=========================================="
log_info "  - essensys-raspberry-install: $INSTALL_REF"
log_info "  - essensys-ansible: $ANSIBLE_REF"
log_info "=========================================="

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
        log_info "Clonage de essensys-raspberry-install (branche $INSTALL_REF) dans $BOOTSTRAP_DIR..."
        sudo -u "$SERVICE_USER" git clone -b "$INSTALL_REF" "https://github.com/essensys-hub/essensys-raspberry-install.git" "$BOOTSTRAP_DIR"
    else
        log_info "Depot essensys-raspberry-install deja present, mise a jour vers $INSTALL_REF..."
        sudo -u "$SERVICE_USER" git -C "$BOOTSTRAP_DIR" fetch --all --tags
        sudo -u "$SERVICE_USER" git -C "$BOOTSTRAP_DIR" checkout "$INSTALL_REF"
        sudo -u "$SERVICE_USER" git -C "$BOOTSTRAP_DIR" pull --ff-only
    fi
fi
echo "----------------------------------------"
echo "DOMAIN_FILE: $DOMAIN_FILE"
echo "----------------------------------------"
prompt_domain() {
    local prompt_message="$1"
    if [ -r /dev/tty ]; then
        read -r -p "$prompt_message" WAN_DOMAIN < /dev/tty
        return 0
    fi
    log_warn "Aucun TTY disponible pour la saisie interactive."
    WAN_DOMAIN=""
    return 1
}
if [ -f "$DOMAIN_FILE" ]; then
    # Lire le domaine depuis le fichier (enlever les espaces et sauts de ligne)
    EXISTING_DOMAIN=$(cat "$DOMAIN_FILE" | tr -d '[:space:]')
    if [ -n "$EXISTING_DOMAIN" ]; then
        log_info "domain.txt detecte avec le domaine: $EXISTING_DOMAIN"
        log_info "Utilisation du domaine existant, pas de saisie necessaire."
    else
        log_warn "domain.txt existe mais est vide. Saisissez le domaine WAN a utiliser."
        log_info "ref: https://essensys-hub.github.io/essensys-raspberry-install/installation/wan/"
        prompt_domain "Domaine WAN (ex: mon.monwan.io):  "
        if [ -n "$WAN_DOMAIN" ]; then
            echo "$WAN_DOMAIN" > "$DOMAIN_FILE"
            chown "$SERVICE_USER:$SERVICE_USER" "$DOMAIN_FILE"
            log_info "Domaine enregistre dans $DOMAIN_FILE"
        else
            log_warn "Domaine vide, domain.txt reste vide"
        fi
    fi
else
    log_warn "domain.txt absent. Creation du fichier."
    log_info "ref: https://essensys-hub.github.io/essensys-raspberry-install/installation/wan/"
    prompt_domain "Domaine WAN (ex: mon.monwan.io):  "
    if [ -n "$WAN_DOMAIN" ]; then
        echo "$WAN_DOMAIN" > "$DOMAIN_FILE"
        chown "$SERVICE_USER:$SERVICE_USER" "$DOMAIN_FILE"
        log_info "domain.txt cree dans $DOMAIN_FILE"
    else
        log_warn "Domaine vide, domain.txt non cree"
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

# ============================================
# Installation de Go (Prerequis pour Backend/MCP)
# ============================================
check_go() {
    log_info "Verification de Go..."
    # Ensure go is available or upgrade if too old
    NEED_GO_INSTALL=true
    if command -v /usr/local/go/bin/go >/dev/null 2>&1; then
        GO_VERSION=$(/usr/local/go/bin/go version | awk '{print $3}' | sed 's/go//')
        # Check if version starts with 1.23 or higher (basic string compare works for now)
        if [[ "$GO_VERSION" > "1.23" ]] || [[ "$GO_VERSION" == "1.23"* ]]; then
             NEED_GO_INSTALL=false
             log_info "Go version $GO_VERSION detectee (suffisant)"
        fi
    elif command -v go >/dev/null 2>&1; then
        # Check system go if /usr/local/go/bin/go not found
         GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
         if [[ "$GO_VERSION" > "1.23" ]] || [[ "$GO_VERSION" == "1.23"* ]]; then
             NEED_GO_INSTALL=false
             log_info "Go version $GO_VERSION (system) detectee (suffisant)"
        fi
    fi

    if [ "$NEED_GO_INSTALL" = true ]; then
        log_warn "Installation/Mise a jour de Go vers 1.23.4..."
        wget https://go.dev/dl/go1.23.4.linux-arm64.tar.gz -O /tmp/go.tar.gz
        rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tar.gz
        export PATH=$PATH:/usr/local/go/bin
        rm /tmp/go.tar.gz
    else
        export PATH=$PATH:/usr/local/go/bin
    fi
}
check_go

if [ -d "$TARGET_DIR/.git" ]; then
    log_info "Depot deja present, mise a jour..."
    git -C "$TARGET_DIR" fetch --all --tags
    git -C "$TARGET_DIR" checkout "$ANSIBLE_REF"
    git -C "$TARGET_DIR" pull --ff-only
else
    log_info "Clonage du depot essensys-ansible..."
    git clone -b "$ANSIBLE_REF" "$REPO_URL" "$TARGET_DIR"
fi

log_info "Lancement du playbook d'installation Raspberry Pi..."
if [ ! -f "$TARGET_DIR/inventory" ]; then
    log_warn "Fichier inventory introuvable dans $TARGET_DIR"
    log_info "Creation d'un inventory local..."
    cat > "$TARGET_DIR/inventory" <<'EOF'
[raspberrypi]
localhost ansible_connection=local
EOF
fi

if [ ! -f "$TARGET_DIR/install.raspberrypi.yml" ]; then
    log_error "Playbook install.raspberrypi.yml introuvable dans $TARGET_DIR"
    exit 1
fi

ansible-playbook -i "$TARGET_DIR/inventory" "$TARGET_DIR/install.raspberrypi.yml"

# Note: MCP configuration is now handled by Ansible role 'raspberry_mcp'

cleanup_caddy() {
    log_info "Suppression de Caddy (stack Traefik only)..."
    systemctl disable --now caddy >/dev/null 2>&1 || true
    apt-get purge -y caddy >/dev/null 2>&1 || true
    apt-get autoremove -y >/dev/null 2>&1 || true
    rm -rf /etc/caddy /var/log/caddy /opt/essensys-caddy
    rm -f /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    rm -f /etc/apt/sources.list.d/caddy-stable.list
}

cleanup_homeassistant() {
    log_info "Suppression de Home Assistant..."
    systemctl disable --now homeassistant >/dev/null 2>&1 || true
    rm -f /etc/systemd/system/homeassistant.service
    systemctl daemon-reload >/dev/null 2>&1 || true
    rm -rf /opt/essensys/homeassistant
}

cleanup_caddy
cleanup_homeassistant

log_info "Termine. Installation complete."
log_info ""
log_info "=== Commandes utiles ==="
log_info "  systemctl status nginx traefik"
log_info "  ss -ltnp | grep -E ':80|:443'"
log_info "  /usr/local/bin/generate-htpasswd-essensys.sh"
log_info ""
