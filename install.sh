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
ESSENSYS_VERSION="V.1.2.3"
ANSIBLE_REF="$ESSENSYS_VERSION"
INSTALL_REF="$ESSENSYS_VERSION"

# Chemins de configuration auth
AUTH_DIR="/etc/essensys/auth"
CONFIG_FILE="$AUTH_DIR/config.env"
HTPASSWD_FILE="$AUTH_DIR/users.htpasswd"
CADDY_TEMPLATES="/opt/essensys-caddy"

DOMAIN_FILE="$HOME_DIR/domain.txt"
PASSWORD_CONFIRM_FILE="$HOME_DIR/password_confirm.txt"

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

# ============================================
# Configuration de l'authentification Caddy
# ============================================

setup_auth() {
    log_info "Configuration de l'authentification..."
    
    # Créer le répertoire auth
    mkdir -p "$AUTH_DIR"
    chmod 700 "$AUTH_DIR"
    
    # Installer les templates Caddy
    mkdir -p "$CADDY_TEMPLATES"
    cp "$BOOTSTRAP_DIR/caddy-config/"Caddyfile.* "$CADDY_TEMPLATES/"
    chmod 644 "$CADDY_TEMPLATES/"*
    
    # Installer le script essensys-auth
    cp "$BOOTSTRAP_DIR/scripts/essensys-auth" /usr/local/bin/
    chmod 755 /usr/local/bin/essensys-auth
    
    # Créer le répertoire de logs Caddy
    mkdir -p /var/log/caddy
    chown caddy:caddy /var/log/caddy
    
    # Configuration interactive
    local auth_enabled=1
    local lan_noauth=0
    local username=""
    local password=""
    
    # Vérifier si password_confirm.txt existe et contient "true"
    local use_default_credentials=false
    if [ -f "$PASSWORD_CONFIRM_FILE" ]; then
        local confirm_value=$(cat "$PASSWORD_CONFIRM_FILE" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        if [ "$confirm_value" = "true" ]; then
            use_default_credentials=true
            log_info "password_confirm.txt detecte avec 'true' - utilisation des credentials par defaut"
        fi
    fi
    
    echo
    log_info "=== Configuration authentification Essensys ==="
    echo
    
    # Si password_confirm.txt contient "true", utiliser les valeurs par défaut
    if [ "$use_default_credentials" = true ]; then
        auth_enabled=1
        lan_noauth=0
        username="admin"
        password="Essensys"
        log_info "Utilisation des credentials par defaut: admin/Essensys"
    # Sinon, demander interactivement
    elif [ -r /dev/tty ]; then
        read -r -p "Activer l'authentification? (O/n): " auth_choice < /dev/tty
        case "$auth_choice" in
            [Nn]*)
                auth_enabled=0
                log_warn "⚠️  Authentification désactivée - Accès libre!"
                ;;
            *)
                auth_enabled=1
                log_info "Authentification activée"
                
                # Demander LAN sans auth
                read -r -p "Autoriser l'accès LAN sans mot de passe? (o/N): " lan_choice < /dev/tty
                case "$lan_choice" in
                    [Oo]*)
                        lan_noauth=1
                        log_warn "⚠️  LAN sans authentification activé"
                        ;;
                    *)
                        lan_noauth=0
                        log_info "Authentification requise partout"
                        ;;
                esac
                
                # Créer l'utilisateur admin
                echo
                log_info "Création du compte administrateur..."
                read -r -p "Nom d'utilisateur (défaut: admin): " username < /dev/tty
                username="${username:-admin}"
                
                while true; do
                    echo -n "Mot de passe: "
                    read -rs password < /dev/tty
                    echo
                    echo -n "Confirmer le mot de passe: "
                    read -rs password_confirm < /dev/tty
                    echo
                    
                    if [ "$password" = "$password_confirm" ] && [ -n "$password" ]; then
                        break
                    else
                        log_error "Les mots de passe ne correspondent pas ou sont vides"
                    fi
                done
                ;;
        esac
    else
        log_warn "Pas de TTY disponible, utilisation des valeurs par défaut"
        auth_enabled=1
        lan_noauth=0
        username="admin"
        password="essensys"
        log_warn "⚠️  Mot de passe par défaut: essensys - Changez-le immédiatement!"
    fi
    
    # Créer config.env
    cat > "$CONFIG_FILE" <<EOF
# Configuration authentification Essensys
# Généré automatiquement le $(date)

ESSENSYS_AUTH_ENABLED=$auth_enabled
ESSENSYS_LAN_NOAUTH=$lan_noauth
ESSENSYS_AUTH_REALM="Essensys"
EOF
    chmod 600 "$CONFIG_FILE"
    
    # Créer htpasswd avec l'utilisateur initial
    if [ "$auth_enabled" = "1" ] && [ -n "$password" ]; then
        # Générer le hash bcrypt avec caddy
        local hash
        hash=$(caddy hash-password --plaintext "$password" 2>/dev/null)
        echo "${username}:${hash}" > "$HTPASSWD_FILE"
        chmod 600 "$HTPASSWD_FILE"
        log_info "Utilisateur '$username' créé"
    else
        touch "$HTPASSWD_FILE"
        chmod 600 "$HTPASSWD_FILE"
    fi
    
    # Générer la configuration Caddy initiale
    essensys-auth status || true
    
    log_info "Configuration authentification terminée"
}

# Installer Caddy si nécessaire
install_caddy() {
    if command -v caddy >/dev/null 2>&1; then
        log_info "Caddy déjà installé"
        return
    fi
    
    log_info "Installation de Caddy..."
    
    # Installer les dépendances
    apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
    
    # Ajouter le repo Caddy
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
    
    apt-get update
    apt-get install -y caddy
    
    # Désactiver le démarrage automatique (sera géré après config)
    systemctl stop caddy || true
    
    log_info "Caddy installé"
}

# Appeler l'installation de Caddy et la configuration auth
log_info "Installation du reverse-proxy Caddy..."
install_caddy

log_info "Configuration de l'authentification..."
setup_auth

log_info "Démarrage de Caddy..."
systemctl enable caddy
systemctl start caddy

log_info "Termine. Installation complete."
log_info ""
log_info "=== Commandes utiles ==="
log_info "  essensys-auth status     - Voir le statut d'authentification"
log_info "  essensys-auth add-user   - Ajouter un utilisateur"
log_info "  essensys-auth lan-noauth - Configurer l'accès LAN"
log_info ""
