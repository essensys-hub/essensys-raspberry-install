#!/bin/bash

# Script d'installation Essensys pour Raspberry Pi 4
# Ce script installe et configure le backend et le frontend Essensys

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

log_info "Démarrage de l'installation Essensys pour Raspberry Pi 4"

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
    
    # Configurer les capacités pour écouter sur le port 8080 (non-privilégié, pas besoin de setcap)
    # Le backend écoutera sur 8080, nginx sur 80 proxy vers 8080
    
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
    
    # Modifier le port dans config.yaml pour utiliser 8080 (nginx écoutera sur 80 et proxy vers 8080)
    # Les clients BP_MQX_ETH se connecteront au port 80, nginx les proxy vers le backend sur 8080
    if grep -q "port: 80" "$BACKEND_DIR/config.yaml"; then
        sed -i 's/port: 80/port: 8080/' "$BACKEND_DIR/config.yaml"
    fi
else
    log_error "Le fichier go.mod n'a pas été trouvé dans $BACKEND_DIR"
    exit 1
fi

# Le frontend a déjà été copié plus haut

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

# Configurer nginx
log_info "Configuration de nginx..."
cat > /etc/nginx/sites-available/essensys <<EOF
server {
    listen 80;
    server_name _;
    
    root $FRONTEND_DIR/dist;
    index index.html index.htm;
    
    # Types MIME
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Charset
    charset utf-8;
    
    # Logs
    access_log /var/log/nginx/essensys-access.log;
    error_log /var/log/nginx/essensys-error.log;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json application/javascript;
    
    # Cache pour les assets statiques
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|map)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Servir les fichiers HTML directement
    location ~* \.html$ {
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
    }
    
    # Proxy pour les API vers le backend
    # CRITIQUE: Configuration compatible avec client legacy BP_MQX_ETH
    # Le client nécessite des réponses en un seul paquet TCP
    location /api/ {
        proxy_pass http://127.0.0.1:8080/api/;
        proxy_http_version 1.1;
        
        # Headers de requête
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Connection "";
        
        # CRITIQUE: Bufferiser la réponse complète pour single-packet TCP
        # Le client legacy ne peut pas gérer les réponses fragmentées
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
        # Bufferiser toute la réponse avant d'envoyer
        proxy_max_temp_file_size 0;
        
        # Désactiver gzip pour les API (évite la fragmentation)
        gzip off;
        
        # Préserver les headers originaux du backend
        # Le backend envoie déjà Content-Type avec espace avant ;charset
        proxy_pass_header Content-Type;
        proxy_pass_header Content-Length;
        proxy_pass_header Connection;
        
        # Ne pas modifier les headers de réponse
        proxy_hide_header X-Powered-By;
        proxy_hide_header Server;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Fermer la connexion après la réponse (compatible avec Connection: close)
        proxy_set_header Connection "close";
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:8080/health;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        access_log off;
    }
    
    # Servir les fichiers statiques existants
    location / {
        try_files \$uri \$uri/ @fallback;
    }
    
    # Fallback pour SPA - rediriger vers index.html si fichier non trouvé
    location @fallback {
        try_files /index.html =404;
    }
    
    # Sécurité - bloquer l'accès aux fichiers cachés
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Désactiver les logs pour favicon
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }
    
    # Désactiver les logs pour robots.txt
    location = /robots.txt {
        log_not_found off;
        access_log off;
    }
}
EOF

# Activer le site nginx
ln -sf /etc/nginx/sites-available/essensys /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Tester la configuration nginx
log_info "Vérification de la configuration nginx..."
nginx -t

# Recharger systemd et démarrer les services
log_info "Configuration des services systemd..."
systemctl daemon-reload
systemctl enable essensys-backend
systemctl enable nginx

# Démarrer les services
log_info "Démarrage des services..."
systemctl restart essensys-backend
systemctl restart nginx

# Vérifier le statut des services
log_info "Vérification du statut des services..."
sleep 2
systemctl status essensys-backend --no-pager -l
systemctl status nginx --no-pager -l

log_info ""
log_info "=========================================="
log_info "Installation terminée avec succès!"
log_info "=========================================="
log_info ""
log_info "Configuration:"
log_info "  - Frontend: http://localhost (port 80)"
log_info "  - Backend API: http://localhost/api/* (proxifié par nginx)"
log_info "  - Backend direct: http://localhost:8080 (pour les tests)"
log_info ""
log_info "Les clients BP_MQX_ETH doivent se connecter au port 80"
log_info "Nginx proxy automatiquement les requêtes /api/* vers le backend sur 8080"
log_info ""
log_info "Services:"
log_info "  - Backend: systemctl status essensys-backend"
log_info "  - Nginx: systemctl status nginx"
log_info ""
log_info "Logs:"
log_info "  - Backend: tail -f /var/logs/Essensys/backend/console.out.log"
log_info "  - Nginx: tail -f /var/log/nginx/essensys-error.log"
log_info ""
log_info "Pour tester:"
log_info "  curl http://localhost/health"
log_info "  curl http://localhost:8080/health"
log_info "  curl http://localhost/api/serverinfos"
log_info ""

