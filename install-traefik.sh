#!/bin/bash

# Script d'installation Traefik pour Essensys
# Remplace nginx par Traefik avec configuration locale et WAN

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
TRAEFIK_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/traefik-config"
TRAEFIK_VERSION="v2.11"
ACME_EMAIL="admin@acme.com"  # À modifier avec votre email
BACKEND_USER="essensys"
SERVICE_USER="essensys"
HOME_DIR="/home/essensys"
BACKEND_REPO="https://github.com/essensys-hub/essensys-server-backend.git"
FRONTEND_REPO="https://github.com/essensys-hub/essensys-server-frontend.git"
DOMAIN_FILE="$HOME_DIR/domain.txt"

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

log_info "Installation de Traefik pour Essensys"

# Lire le domaine WAN depuis le fichier domain.txt
WAN_DOMAIN="essensys.acme.com"  # Valeur par défaut
if [ -f "$DOMAIN_FILE" ]; then
    WAN_DOMAIN=$(cat "$DOMAIN_FILE" | tr -d '\n\r ' | head -1)
    if [ -z "$WAN_DOMAIN" ]; then
        log_warn "Le fichier $DOMAIN_FILE est vide, utilisation du domaine par défaut: $WAN_DOMAIN"
    else
        log_info "Domaine WAN lu depuis $DOMAIN_FILE: $WAN_DOMAIN"
    fi
else
    log_warn "Le fichier $DOMAIN_FILE n'existe pas, utilisation du domaine par défaut: $WAN_DOMAIN"
    log_warn "Créez le fichier avec: echo 'essensys.rhinosys.io' > $DOMAIN_FILE"
fi

# Vérifier que le répertoire de configuration existe
if [ ! -d "$TRAEFIK_CONFIG_DIR" ]; then
    log_error "Répertoire de configuration Traefik introuvable: $TRAEFIK_CONFIG_DIR"
    exit 1
fi

# Installer les dépendances système
log_info "Installation des dépendances système..."
apt-get update
apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    nginx \
    apache2-utils \
    python3 \
    libcap2-bin \
    ca-certificates

# Installer Go
log_info "Installation de Go..."
if ! command -v go &> /dev/null; then
    GO_VERSION="1.21.5"
    GO_ARCH="armv6l"
    if [ "$(uname -m)" = "aarch64" ]; then
        GO_ARCH="arm64"
    fi
    
    GO_TAR="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    cd /tmp
    wget "https://go.dev/dl/${GO_TAR}"
    tar -C /usr/local -xzf "${GO_TAR}"
    rm "${GO_TAR}"
    
    # Ajouter Go au PATH
    if ! grep -q "/usr/local/go/bin" /etc/profile; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    fi
    export PATH=$PATH:/usr/local/go/bin
else
    log_info "Go est déjà installé"
    export PATH=$PATH:/usr/local/go/bin
fi

# Installer Node.js (via NodeSource)
log_info "Installation de Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
else
    log_info "Node.js est déjà installé"
fi

# Vérifier les versions installées
log_info "Vérification des versions installées..."
go version
node --version
npm --version

# Créer l'utilisateur de service avec home directory
log_info "Création de l'utilisateur de service..."
if ! id "$SERVICE_USER" &>/dev/null; then
    useradd -m -s /bin/bash -d "$HOME_DIR" "$SERVICE_USER"
    log_info "Utilisateur $SERVICE_USER créé avec home directory $HOME_DIR"
else
    log_info "L'utilisateur $SERVICE_USER existe déjà"
    # S'assurer que le home directory existe
    if [ ! -d "$HOME_DIR" ]; then
        mkdir -p "$HOME_DIR"
        chown "$SERVICE_USER:$SERVICE_USER" "$HOME_DIR"
    fi
fi

# Créer les répertoires
log_info "Création des répertoires d'installation..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$BACKEND_DIR"
mkdir -p "$FRONTEND_DIR"
mkdir -p "$INSTALL_DIR/logs"

# Cloner les dépôts dans le home directory de l'utilisateur essensys
log_info "Clonage des dépôts depuis GitHub (HTTPS)..."
log_info "Backend: $BACKEND_REPO"
log_info "Frontend: $FRONTEND_REPO"

# Cloner le backend
log_info "Clonage du backend..."
if [ -d "$HOME_DIR/essensys-server-backend" ]; then
    log_info "Le dépôt backend existe déjà, mise à jour..."
    if ! sudo -u "$SERVICE_USER" bash -c "cd $HOME_DIR/essensys-server-backend && git pull"; then
        log_error "Échec de la mise à jour du backend. Vérifiez la connexion Internet et les permissions."
        exit 1
    fi
else
    if ! sudo -u "$SERVICE_USER" bash -c "cd $HOME_DIR && git clone $BACKEND_REPO"; then
        log_error "Échec du clonage du backend."
        log_error "Vérifiez que :"
        log_error "  1. La connexion Internet fonctionne"
        log_error "  2. Le dépôt est accessible publiquement"
        log_error "  3. Git est correctement installé"
        exit 1
    fi
fi

# Cloner le frontend
log_info "Clonage du frontend..."
if [ -d "$HOME_DIR/essensys-server-frontend" ]; then
    log_info "Le dépôt frontend existe déjà, mise à jour..."
    if ! sudo -u "$SERVICE_USER" bash -c "cd $HOME_DIR/essensys-server-frontend && git pull"; then
        log_error "Échec de la mise à jour du frontend. Vérifiez la connexion Internet et les permissions."
        exit 1
    fi
else
    if ! sudo -u "$SERVICE_USER" bash -c "cd $HOME_DIR && git clone $FRONTEND_REPO"; then
        log_error "Échec du clonage du frontend."
        log_error "Vérifiez que :"
        log_error "  1. La connexion Internet fonctionne"
        log_error "  2. Le dépôt est accessible publiquement"
        log_error "  3. Git est correctement installé"
        exit 1
    fi
fi

# Copier les fichiers depuis le home directory vers les répertoires d'installation
log_info "Copie des fichiers vers les répertoires d'installation..."
cp -r "$HOME_DIR/essensys-server-backend"/* "$BACKEND_DIR/"
cp -r "$HOME_DIR/essensys-server-frontend"/* "$FRONTEND_DIR/"

# Compiler le backend
if [ -f "$BACKEND_DIR/go.mod" ]; then
    log_info "Compilation du backend..."
    cd "$BACKEND_DIR"
    log_info "Synchronisation et téléchargement des dépendances Go..."
    go mod tidy
    if [ $? -ne 0 ]; then
        log_warn "go mod tidy a échoué, tentative avec go mod download..."
        go mod download
        go mod tidy
    fi
    log_info "Compilation du binaire..."
    go build -o server ./cmd/server
    if [ $? -ne 0 ]; then
        log_error "La compilation du backend a échoué"
        log_error "Vérifiez que toutes les dépendances sont disponibles"
        exit 1
    fi
    
    # Créer le fichier de configuration si nécessaire
    if [ ! -f "$BACKEND_DIR/config.yaml" ]; then
        log_info "Création du fichier de configuration backend..."
        cp "$BACKEND_DIR/config.yaml.example" "$BACKEND_DIR/config.yaml" 2>/dev/null || cat > "$BACKEND_DIR/config.yaml" <<EOF
server:
  port: 8080
  read_timeout: 10s
  write_timeout: 10s
  idle_timeout: 60s

auth:
  enabled: false
  clients:
    testclient: testpass

logging:
  level: info
  format: text
EOF
    fi
    
    # Modifier le port dans config.yaml pour utiliser 8080
    if [ -f "$BACKEND_DIR/config.yaml" ]; then
        current_port=$(grep -E "^[[:space:]]*port:[[:space:]]*[0-9]+" "$BACKEND_DIR/config.yaml" | sed 's/.*port:[[:space:]]*\([0-9]*\).*/\1/')
        if [ -n "$current_port" ] && [ "$current_port" != "8080" ]; then
            sed -i 's/^\([[:space:]]*port:[[:space:]]*\)[0-9]*/\18080/' "$BACKEND_DIR/config.yaml"
            log_info "Port configuré à 8080 dans config.yaml"
        elif [ -z "$current_port" ]; then
            sed -i '/^server:/a\  port: 8080' "$BACKEND_DIR/config.yaml"
            log_info "Port 8080 ajouté dans config.yaml"
        else
            log_info "Port déjà configuré à 8080 dans config.yaml"
        fi
    fi
else
    log_error "Le fichier go.mod n'a pas été trouvé dans $BACKEND_DIR"
    exit 1
fi

# Installer les dépendances et builder le frontend
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
    log_info "Build du frontend terminé avec succès"
else
    log_error "Le fichier package.json n'a pas été trouvé dans $FRONTEND_DIR"
    exit 1
fi

# Configurer les permissions
log_info "Configuration des permissions..."
chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"

# Créer le répertoire de logs
log_info "Création du répertoire de logs..."
mkdir -p /var/logs/Essensys/backend
chown -R "$SERVICE_USER:$SERVICE_USER" /var/logs/Essensys

# Créer le service systemd pour le backend
log_info "Création du service systemd pour le backend..."
cat > /etc/systemd/system/essensys-backend.service <<EOF
[Unit]
Description=Essensys Backend Server
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$BACKEND_DIR
ExecStart=$BACKEND_DIR/server
Restart=always
RestartSec=5
StandardOutput=append:/var/logs/Essensys/backend/console.out.log
StandardError=append:/var/logs/Essensys/backend/console.out.log

# Environment variables
Environment="LOG_LEVEL=info"
Environment="AUTH_ENABLED=false"

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$INSTALL_DIR /var/logs/Essensys

[Install]
WantedBy=multi-user.target
EOF

# Télécharger et installer Traefik
log_info "Téléchargement de Traefik..."
TRAEFIK_BINARY="/usr/local/bin/traefik"
if [ ! -f "$TRAEFIK_BINARY" ]; then
    ARCH="arm64"  # Pour Raspberry Pi 4
    if [ "$(uname -m)" = "armv7l" ]; then
        ARCH="armv7"
    fi
    
    log_info "Architecture détectée: $ARCH"
    
    # Essayer plusieurs formats d'URL possibles
    # Format 1: traefik_v2.11.0_linux_arm64.tar.gz (v2.x)
    # Format 2: traefik_v3.0_linux_arm64.tar.gz (v3.x si disponible)
    # Format 3: traefik_linux_arm64.tar.gz (format alternatif)
    
    TRAEFIK_URLS=(
        "https://github.com/traefik/traefik/releases/download/v2.11.3/traefik_v2.11.3_linux_${ARCH}.tar.gz"
        "https://github.com/traefik/traefik/releases/download/v2.11.0/traefik_v2.11.0_linux_${ARCH}.tar.gz"
        "https://github.com/traefik/traefik/releases/download/v2.10.7/traefik_v2.10.7_linux_${ARCH}.tar.gz"
    )
    
    cd /tmp
    DOWNLOADED=0
    
    for TRAEFIK_URL in "${TRAEFIK_URLS[@]}"; do
        log_info "Essai de téléchargement depuis: $TRAEFIK_URL"
        if wget -q --timeout=10 "$TRAEFIK_URL" -O traefik.tar.gz 2>/dev/null; then
            # Vérifier que le fichier téléchargé n'est pas vide et est valide
            if [ -s traefik.tar.gz ] && tar -tzf traefik.tar.gz >/dev/null 2>&1; then
                DOWNLOADED=1
                log_info "Téléchargement réussi!"
                break
            else
                log_warn "Fichier invalide, essai suivant..."
                rm -f traefik.tar.gz
            fi
        else
            log_warn "Échec du téléchargement, essai suivant..."
        fi
    done
    
    if [ "$DOWNLOADED" -eq 0 ]; then
        log_error "Échec du téléchargement de Traefik après plusieurs tentatives"
        log_error ""
        log_error "Options:"
        log_error "1. Vérifiez votre connexion Internet"
        log_error "2. Téléchargez manuellement depuis: https://github.com/traefik/traefik/releases"
        log_error "3. Placez le binaire dans: $TRAEFIK_BINARY"
        log_error "4. Rendez-le exécutable: chmod +x $TRAEFIK_BINARY"
        exit 1
    fi
    
    # Extraire le binaire
    log_info "Extraction du binaire Traefik..."
    tar -xzf traefik.tar.gz
    if [ ! -f traefik ]; then
        log_error "Le binaire traefik n'a pas été trouvé dans l'archive"
        rm -f traefik.tar.gz
        exit 1
    fi
    
    mv traefik "$TRAEFIK_BINARY"
    chmod +x "$TRAEFIK_BINARY"
    rm -f traefik.tar.gz
    
    # Vérifier la version installée
    if "$TRAEFIK_BINARY" version >/dev/null 2>&1; then
        VERSION=$("$TRAEFIK_BINARY" version | head -1)
        log_info "Traefik installé avec succès: $VERSION"
    else
        log_info "Traefik installé avec succès"
    fi
else
    log_info "Traefik est déjà installé"
fi

# Créer les répertoires nécessaires
log_info "Création des répertoires..."
mkdir -p /etc/traefik/dynamic
mkdir -p /etc/traefik
mkdir -p /var/log/traefik
mkdir -p /var/lib/traefik

# Copier la configuration principale
log_info "Installation de la configuration Traefik..."
cp "$TRAEFIK_CONFIG_DIR/traefik.yml" /etc/traefik/traefik.yml

# Modifier l'email Let's Encrypt dans la configuration
sed -i "s|admin@acme.com|$ACME_EMAIL|g" /etc/traefik/traefik.yml

# Générer les fichiers de configuration dynamique avec le bon chemin frontend et domaine WAN
log_info "Génération des fichiers de configuration dynamique..."
sed -e "s|{{FRONTEND_DIR}}|$FRONTEND_DIR|g" -e "s|{{WAN_DOMAIN}}|$WAN_DOMAIN|g" "$TRAEFIK_CONFIG_DIR/dynamic/local-routes.yml" > /etc/traefik/dynamic/local-routes.yml
sed -e "s|{{FRONTEND_DIR}}|$FRONTEND_DIR|g" -e "s|{{WAN_DOMAIN}}|$WAN_DOMAIN|g" "$TRAEFIK_CONFIG_DIR/dynamic/wan-routes.yml" > /etc/traefik/dynamic/wan-routes.yml
log_info "Domaine WAN configuré: $WAN_DOMAIN"

# Créer le fichier acme.json pour Let's Encrypt
log_info "Création du fichier acme.json..."
touch /etc/traefik/acme.json
chmod 600 /etc/traefik/acme.json

# Créer le fichier htpasswd (vide pour l'instant, à remplir avec generate-htpasswd.sh)
log_info "Création du fichier htpasswd..."
touch /etc/traefik/users.htpasswd
chmod 600 /etc/traefik/users.htpasswd
log_warn "Le fichier htpasswd est vide. Exécutez generate-htpasswd.sh pour ajouter des utilisateurs"

# Installer le service de blocage (Python)
log_info "Installation du service de blocage..."
cp "$TRAEFIK_CONFIG_DIR/block-service.py" /usr/local/bin/traefik-block-service.py
chmod +x /usr/local/bin/traefik-block-service.py

# Créer le service systemd pour le service de blocage
log_info "Création du service systemd pour le service de blocage..."
cat > /etc/systemd/system/traefik-block-service.service <<EOF
[Unit]
Description=Traefik Block Service (403 Forbidden)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /usr/local/bin/traefik-block-service.py 8082
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Créer le service systemd pour Traefik
log_info "Création du service systemd pour Traefik..."
cat > /etc/systemd/system/traefik.service <<EOF
[Unit]
Description=Traefik Reverse Proxy
After=network.target

[Service]
Type=simple
User=root
ExecStart=$TRAEFIK_BINARY --configfile=/etc/traefik/traefik.yml
Restart=always
RestartSec=5
StandardOutput=append:/var/log/traefik/traefik.log
StandardError=append:/var/log/traefik/traefik-error.log

# Sécurité
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/etc/traefik /var/log/traefik /var/lib/traefik

[Install]
WantedBy=multi-user.target
EOF

# Configurer nginx pour servir le frontend sur le port 8081 (interne)
log_info "Configuration de nginx pour servir le frontend en interne..."
if [ -f "$TRAEFIK_CONFIG_DIR/nginx-frontend-internal.conf" ]; then
    # Générer la configuration nginx pour le port 8081
    sed "s|{{FRONTEND_DIR}}|$FRONTEND_DIR|g" "$TRAEFIK_CONFIG_DIR/nginx-frontend-internal.conf" > /etc/nginx/sites-available/essensys-frontend-internal
    ln -sf /etc/nginx/sites-available/essensys-frontend-internal /etc/nginx/sites-enabled/essensys-frontend-internal
    log_info "Configuration nginx créée pour le port 8081 (interne)"
    
    # Tester la configuration nginx
    nginx -t
    if [ $? -ne 0 ]; then
        log_error "La configuration nginx est invalide"
        exit 1
    fi
else
    log_warn "Template de configuration nginx introuvable. Nginx doit être configuré manuellement pour servir le frontend sur le port 8081"
fi

# Recharger systemd
log_info "Rechargement de systemd..."
systemctl daemon-reload

# Démarrer les services
log_info "Démarrage des services..."
systemctl enable essensys-backend
systemctl enable traefik-block-service
systemctl enable traefik
systemctl start essensys-backend
systemctl start traefik-block-service
systemctl start traefik

# Redémarrer nginx si nécessaire
if systemctl is-active --quiet nginx; then
    log_info "Redémarrage de nginx..."
    systemctl restart nginx
fi

# Vérifier le statut
log_info "Vérification du statut des services..."
sleep 2
systemctl status essensys-backend --no-pager -l || true
systemctl status traefik --no-pager -l || true
systemctl status traefik-block-service --no-pager -l || true

log_info ""
log_info "=========================================="
log_info "Installation Traefik terminée!"
log_info "=========================================="
log_info ""
log_info "Configuration:"
log_info "  - Local: http://mon.essensys.fr/ (port 80, sans authentification)"
log_info "  - WAN: https://$WAN_DOMAIN/ (port 443, avec authentification)"
log_info ""
log_info "IMPORTANT:"
log_info "  1. Configurez le fichier htpasswd:"
log_info "     sudo $TRAEFIK_CONFIG_DIR/generate-htpasswd.sh"
log_info "  2. Vérifiez que le DNS $WAN_DOMAIN pointe vers cette machine"
log_info "  3. Les certificats Let's Encrypt seront générés automatiquement"
log_info "  4. Domaine WAN lu depuis: $DOMAIN_FILE"
log_info ""
log_info "Services:"
log_info "  - Backend: systemctl status essensys-backend"
log_info "  - Traefik: systemctl status traefik"
log_info "  - Block Service: systemctl status traefik-block-service"
log_info "  - Nginx (frontend interne): systemctl status nginx"
log_info ""
log_info "Logs:"
log_info "  - Backend: tail -f /var/logs/Essensys/backend/console.out.log"
log_info "  - Traefik: tail -f /var/log/traefik/traefik.log"
log_info "  - Traefik errors: tail -f /var/log/traefik/traefik-error.log"
log_info ""

