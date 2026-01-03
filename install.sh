#!/bin/bash

# Script d'installation Essensys pour Raspberry Pi 4
# Ce script installe et configure Nginx, Traefik, Backend et Frontend

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
BACKEND_USER="essensys"
SERVICE_USER="essensys"
HOME_DIR="/home/essensys"
BACKEND_REPO="https://github.com/essensys-hub/essensys-server-backend.git"
FRONTEND_REPO="https://github.com/essensys-hub/essensys-server-frontend.git"
DOMAIN_FILE="$HOME_DIR/domain.txt"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRAEFIK_CONFIG_DIR="$SCRIPT_DIR/traefik-config"
NGINX_CONFIG_DIR="$SCRIPT_DIR/nginx-config"
ACME_EMAIL="admin@acme.com"  # À modifier avec votre email
TRAEFIK_VERSION="v2.11"

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

log_info "Démarrage de l'installation Essensys pour Raspberry Pi 4"
log_info "Installation complète: Nginx + Traefik + Backend + Frontend"

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
    log_warn "Créez le fichier avec: echo 'essensys.acme.com' > $DOMAIN_FILE"
fi

# Mettre à jour le système
log_info "Mise à jour du système..."
apt-get update
apt-get upgrade -y

# Installer les dépendances système
log_info "Installation des dépendances système..."
apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    nginx \
    apache2-utils \
    python3 \
    libcap2-bin \
    ca-certificates \
    openssh-client

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
  port: 7070
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
    
    # Modifier le port dans config.yaml pour utiliser 7070
    if [ -f "$BACKEND_DIR/config.yaml" ]; then
        current_port=$(grep -E "^[[:space:]]*port:[[:space:]]*[0-9]+" "$BACKEND_DIR/config.yaml" | sed 's/.*port:[[:space:]]*\([0-9]*\).*/\1/')
        if [ -n "$current_port" ] && [ "$current_port" != "7070" ]; then
            sed -i 's/^\([[:space:]]*port:[[:space:]]*\)[0-9]*/\17070/' "$BACKEND_DIR/config.yaml"
            log_info "Port configuré à 7070 dans config.yaml"
        elif [ -z "$current_port" ]; then
            sed -i '/^server:/a\  port: 7070' "$BACKEND_DIR/config.yaml"
            log_info "Port 7070 ajouté dans config.yaml"
        else
            log_info "Port déjà configuré à 7070 dans config.yaml"
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

# Configurer Nginx
log_info "Configuration de Nginx..."

# Vérifier que le répertoire nginx-config existe
if [ ! -d "$NGINX_CONFIG_DIR" ] || [ ! -f "$NGINX_CONFIG_DIR/essensys-api-log-format.conf" ]; then
    log_error "Répertoire nginx-config introuvable: $NGINX_CONFIG_DIR"
    exit 1
fi

if [ ! -f "$NGINX_CONFIG_DIR/essensys.template" ]; then
    log_error "Template de configuration nginx introuvable: $NGINX_CONFIG_DIR/essensys.template"
    exit 1
fi

log_info "Configuration nginx trouvée dans: $NGINX_CONFIG_DIR"

# Copier le format de log personnalisé pour les API
log_info "Installation du format de log nginx..."
cp "$NGINX_CONFIG_DIR/essensys-api-log-format.conf" /etc/nginx/conf.d/essensys-api-log-format.conf

# Générer la configuration du site à partir du template
log_info "Génération de la configuration nginx..."
sed "s|{{FRONTEND_DIR}}|$FRONTEND_DIR|g" "$NGINX_CONFIG_DIR/essensys.template" > /etc/nginx/sites-available/essensys

# Activer le site nginx
ln -sf /etc/nginx/sites-available/essensys /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Créer les répertoires de logs si nécessaire
mkdir -p /var/log/nginx
touch /var/log/nginx/essensys-api-detailed.log
touch /var/log/nginx/essensys-api-trace.log
touch /var/log/nginx/essensys-api-error.log
chown -R www-data:www-data /var/log/nginx/essensys-*.log 2>/dev/null || chown -R nginx:nginx /var/log/nginx/essensys-*.log 2>/dev/null || true

# Configurer Nginx pour servir le frontend sur le port 9090 (interne pour Traefik)
log_info "Configuration de Nginx pour le frontend interne (port 9090)..."
if [ -f "$TRAEFIK_CONFIG_DIR/nginx-frontend-internal.conf" ]; then
    sed "s|{{FRONTEND_DIR}}|$FRONTEND_DIR|g" "$TRAEFIK_CONFIG_DIR/nginx-frontend-internal.conf" > /etc/nginx/sites-available/essensys-frontend-internal
    ln -sf /etc/nginx/sites-available/essensys-frontend-internal /etc/nginx/sites-enabled/essensys-frontend-internal
    log_info "Configuration nginx créée pour le port 9090 (interne)"
fi

# Tester la configuration nginx
log_info "Vérification de la configuration nginx..."
nginx -t

# Télécharger et installer Traefik
log_info "Téléchargement de Traefik..."
TRAEFIK_BINARY="/usr/local/bin/traefik"
if [ ! -f "$TRAEFIK_BINARY" ]; then
    ARCH="arm64"  # Pour Raspberry Pi 4
    if [ "$(uname -m)" = "armv7l" ]; then
        ARCH="armv7"
    fi
    
    log_info "Architecture détectée: $ARCH"
    
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
    
    if "$TRAEFIK_BINARY" version >/dev/null 2>&1; then
        VERSION=$("$TRAEFIK_BINARY" version | head -1)
        log_info "Traefik installé avec succès: $VERSION"
    else
        log_info "Traefik installé avec succès"
    fi
else
    log_info "Traefik est déjà installé"
fi

# Créer les répertoires nécessaires pour Traefik
log_info "Création des répertoires Traefik..."
mkdir -p /etc/traefik/dynamic
mkdir -p /etc/traefik
mkdir -p /var/log/traefik
mkdir -p /var/lib/traefik

# Copier la configuration principale Traefik
log_info "Installation de la configuration Traefik..."
if [ ! -d "$TRAEFIK_CONFIG_DIR" ]; then
    log_error "Répertoire de configuration Traefik introuvable: $TRAEFIK_CONFIG_DIR"
    exit 1
fi

cp "$TRAEFIK_CONFIG_DIR/traefik.yml" /etc/traefik/traefik.yml

# Modifier l'email Let's Encrypt dans la configuration
sed -i "s|admin@acme.com|$ACME_EMAIL|g" /etc/traefik/traefik.yml

# Générer les fichiers de configuration dynamique avec le bon chemin frontend et domaine WAN
log_info "Génération des fichiers de configuration dynamique Traefik..."
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

# Recharger systemd et démarrer les services
log_info "Configuration des services systemd..."
systemctl daemon-reload
systemctl enable essensys-backend
systemctl enable nginx
systemctl enable traefik-block-service
systemctl enable traefik

# Démarrer les services
log_info "Démarrage des services..."
systemctl restart essensys-backend
systemctl restart traefik-block-service
systemctl restart traefik
systemctl restart nginx

# Vérifier le statut des services
log_info "Vérification du statut des services..."
sleep 3
systemctl status essensys-backend --no-pager -l || true
systemctl status traefik --no-pager -l || true
systemctl status nginx --no-pager -l || true

log_info ""
log_info "=========================================="
log_info "Installation terminée avec succès!"
log_info "=========================================="
log_info ""
log_info "Architecture installée:"
log_info "  - Backend Go: port 7070 (géré par Nginx pour API locales)"
log_info "  - Frontend React: servi par Nginx port 9090 (interne)"
log_info "  - Nginx: port 80 pour API locales (client Essensys legacy)"
log_info "  - Traefik: port 80 pour frontend local, port 443 pour frontend WAN"
log_info ""
log_info "Configuration:"
log_info "  - Local API: http://mon.essensys.fr/api/* (Nginx port 80)"
log_info "  - Local Frontend: http://mon.essensys.fr/ (Traefik port 80 -> Nginx 9090)"
log_info "  - WAN Frontend: https://$WAN_DOMAIN/ (Traefik port 443 -> Nginx 9090, avec auth)"
log_info ""
log_info "IMPORTANT:"
log_info "  1. Configurez le fichier htpasswd:"
log_info "     sudo $TRAEFIK_CONFIG_DIR/generate-htpasswd.sh username"
log_info "  2. Vérifiez que le DNS $WAN_DOMAIN pointe vers cette machine"
log_info "  3. Les certificats Let's Encrypt seront générés automatiquement"
log_info "  4. Domaine WAN lu depuis: $DOMAIN_FILE"
log_info ""
log_info "Services:"
log_info "  - Backend: systemctl status essensys-backend"
log_info "  - Traefik: systemctl status traefik"
log_info "  - Nginx: systemctl status nginx"
log_info "  - Block Service: systemctl status traefik-block-service"
log_info ""
log_info "Logs:"
log_info "  - Backend: tail -f /var/logs/Essensys/backend/console.out.log"
log_info "  - Traefik: tail -f /var/log/traefik/traefik.log"
log_info "  - Nginx: tail -f /var/log/nginx/essensys-error.log"
log_info ""
log_info "Pour tester:"
log_info "  curl http://localhost/health"
log_info "  curl http://localhost/api/serverinfos"
log_info "  curl http://localhost:7070/health"
log_info ""
