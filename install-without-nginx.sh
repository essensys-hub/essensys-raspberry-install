#!/bin/bash

# Script d'installation Essensys pour Raspberry Pi 4 SANS NGINX
# Backend sur port 80, Frontend sur port 8080
# Ce script permet de tester si nginx bloque le client legacy

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

log_info "Démarrage de l'installation Essensys SANS NGINX pour Raspberry Pi 4"
log_info "Backend sur port 80, Frontend sur port 8080"
log_warn "ATTENTION: Ce script installe SANS nginx pour tester si nginx bloque le client legacy"

# Mettre à jour le système
log_info "Mise à jour du système..."
apt-get update
apt-get upgrade -y

# Installer les dépendances de base
log_info "Installation des dépendances de base..."
apt-get install -y git curl wget build-essential

# Installer Go
if ! command -v go &> /dev/null; then
    log_info "Installation de Go..."
    GO_VERSION="1.21.5"
    wget -q https://go.dev/dl/go${GO_VERSION}.linux-arm64.tar.gz
    tar -C /usr/local -xzf go${GO_VERSION}.linux-arm64.tar.gz
    rm go${GO_VERSION}.linux-arm64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
else
    log_info "Go est déjà installé"
    export PATH=$PATH:/usr/local/go/bin
fi

# Installer Node.js et npm
if ! command -v node &> /dev/null; then
    log_info "Installation de Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
else
    log_info "Node.js est déjà installé"
fi

# Créer l'utilisateur essensys si nécessaire
if ! id "$SERVICE_USER" &>/dev/null; then
    log_info "Création de l'utilisateur $SERVICE_USER..."
    useradd -m -s /bin/bash "$SERVICE_USER"
else
    log_info "L'utilisateur $SERVICE_USER existe déjà"
fi

# Créer les répertoires
log_info "Création des répertoires..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$BACKEND_DIR"
mkdir -p "$FRONTEND_DIR"
mkdir -p "$HOME_DIR"

# Cloner les dépôts
log_info "Clonage des dépôts..."

if [ ! -d "$HOME_DIR/essensys-server-backend" ]; then
    log_info "Clonage du backend..."
    sudo -u "$SERVICE_USER" git clone "$BACKEND_REPO" "$HOME_DIR/essensys-server-backend"
else
    log_info "Le dépôt backend existe déjà, mise à jour..."
    cd "$HOME_DIR/essensys-server-backend"
    sudo -u "$SERVICE_USER" git pull
fi

if [ ! -d "$HOME_DIR/essensys-server-frontend" ]; then
    log_info "Clonage du frontend..."
    sudo -u "$SERVICE_USER" git clone "$FRONTEND_REPO" "$HOME_DIR/essensys-server-frontend"
else
    log_info "Le dépôt frontend existe déjà, mise à jour..."
    cd "$HOME_DIR/essensys-server-frontend"
    sudo -u "$SERVICE_USER" git pull
fi

# Compiler le backend
log_info "Compilation du backend..."
cd "$HOME_DIR/essensys-server-backend"
export PATH=$PATH:/usr/local/go/bin

log_info "Synchronisation et téléchargement des dépendances Go..."
go mod tidy
if [ $? -ne 0 ]; then
    log_warn "go mod tidy a échoué, tentative avec go mod download puis retry go mod tidy..."
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

# Copier le binaire et les fichiers nécessaires
log_info "Copie des fichiers backend..."
cp "$HOME_DIR/essensys-server-backend/server" "$BACKEND_DIR/server"
cp -r "$HOME_DIR/essensys-server-backend"/* "$BACKEND_DIR/" 2>/dev/null || true

# Configurer le backend pour écouter sur le port 80
log_info "Configuration du backend pour écouter sur le port 80..."
if [ ! -f "$BACKEND_DIR/config.yaml" ]; then
    log_info "Création du fichier de configuration backend..."
    cat > "$BACKEND_DIR/config.yaml" <<EOF
server:
  port: 80
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

# Modifier le port dans config.yaml pour utiliser 80
if [ -f "$BACKEND_DIR/config.yaml" ]; then
    current_port=$(grep -E "^[[:space:]]*port:[[:space:]]*[0-9]+" "$BACKEND_DIR/config.yaml" | sed 's/.*port:[[:space:]]*\([0-9]*\).*/\1/' | head -1)
    if [ -n "$current_port" ] && [ "$current_port" != "80" ]; then
        sed -i 's/^\([[:space:]]*port:[[:space:]]*\)[0-9]*/\180/' "$BACKEND_DIR/config.yaml"
        log_info "Port configuré à 80 dans config.yaml"
    elif [ -z "$current_port" ]; then
        sed -i '/^server:/a\  port: 80' "$BACKEND_DIR/config.yaml"
        log_info "Port 80 ajouté dans config.yaml"
    else
        log_info "Port déjà configuré à 80 dans config.yaml"
    fi
fi

# Configurer les capacités pour écouter sur le port 80 (nécessite setcap)
log_info "Configuration des capacités pour écouter sur le port 80..."
setcap 'cap_net_bind_service=+ep' "$BACKEND_DIR/server" 2>/dev/null || {
    log_warn "setcap a échoué, le backend devra être exécuté en root pour écouter sur le port 80"
    log_warn "Ou configurez un port forwarding avec iptables"
}

# Copier le frontend
log_info "Copie des fichiers frontend..."
cp -r "$HOME_DIR/essensys-server-frontend"/* "$FRONTEND_DIR/"

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
Description=Essensys Backend Server (SANS NGINX - Port 80)
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

# Créer un service simple pour servir le frontend sur le port 8080
log_info "Création du service systemd pour le frontend (port 8080)..."
cat > /etc/systemd/system/essensys-frontend.service <<EOF
[Unit]
Description=Essensys Frontend Server (Port 8080)
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$FRONTEND_DIR
ExecStart=/usr/bin/python3 -m http.server 8080 --directory $FRONTEND_DIR/dist
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Installer Python3 si nécessaire
if ! command -v python3 &> /dev/null; then
    log_info "Installation de Python3..."
    apt-get install -y python3
fi

# Recharger systemd et démarrer les services
log_info "Configuration des services systemd..."
systemctl daemon-reload
systemctl enable essensys-backend
systemctl enable essensys-frontend

# Démarrer les services
log_info "Démarrage des services..."
systemctl restart essensys-backend
systemctl restart essensys-frontend

# Vérifier le statut des services
log_info "Vérification du statut des services..."
sleep 2
systemctl status essensys-backend --no-pager -l
systemctl status essensys-frontend --no-pager -l

log_info ""
log_info "=========================================="
log_info "Installation terminée avec succès!"
log_info "=========================================="
log_info ""
log_info "Configuration SANS NGINX:"
log_info "  - Backend: http://localhost:80 (port 80 - pour client legacy)"
log_info "  - Frontend: http://localhost:8080 (port 8080)"
log_info ""
log_info "Les clients BP_MQX_ETH doivent se connecter directement au port 80"
log_info "Le backend Go gère directement les requêtes HTTP (sans proxy nginx)"
log_info ""
log_info "Services:"
log_info "  - Backend: systemctl status essensys-backend"
log_info "  - Frontend: systemctl status essensys-frontend"
log_info ""
log_info "Logs:"
log_info "  - Backend: tail -f /var/logs/Essensys/backend/console.out.log"
log_info ""
log_info "Pour tester:"
log_info "  curl http://localhost:80/health"
log_info "  curl http://localhost:80/api/serverinfos"
log_info "  curl http://localhost:8080"
log_info ""

