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
FRONTEND_DIR="$INSTALL_DIR/frontend"
TRAEFIK_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/traefik-config"
TRAEFIK_VERSION="v2.11"
ACME_EMAIL="admin@acme.com"  # À modifier avec votre email

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

# Vérifier que le répertoire de configuration existe
if [ ! -d "$TRAEFIK_CONFIG_DIR" ]; then
    log_error "Répertoire de configuration Traefik introuvable: $TRAEFIK_CONFIG_DIR"
    exit 1
fi

# Installer les dépendances
log_info "Installation des dépendances..."
apt-get update
apt-get install -y curl wget apache2-utils python3

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

# Générer les fichiers de configuration dynamique avec le bon chemin frontend
log_info "Génération des fichiers de configuration dynamique..."
sed "s|{{FRONTEND_DIR}}|$FRONTEND_DIR|g" "$TRAEFIK_CONFIG_DIR/dynamic/local-routes.yml" > /etc/traefik/dynamic/local-routes.yml
sed "s|{{FRONTEND_DIR}}|$FRONTEND_DIR|g" "$TRAEFIK_CONFIG_DIR/dynamic/wan-routes.yml" > /etc/traefik/dynamic/wan-routes.yml

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
systemctl enable traefik-block-service
systemctl enable traefik
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
systemctl status traefik --no-pager -l || true
systemctl status traefik-block-service --no-pager -l || true

log_info ""
log_info "=========================================="
log_info "Installation Traefik terminée!"
log_info "=========================================="
log_info ""
log_info "Configuration:"
log_info "  - Local: http://mon.essensys.fr/ (port 80, sans authentification)"
log_info "  - WAN: https://essensys.acme.com/ (port 443, avec authentification)"
log_info ""
log_info "IMPORTANT:"
log_info "  1. Configurez le fichier htpasswd:"
log_info "     sudo $TRAEFIK_CONFIG_DIR/generate-htpasswd.sh"
log_info "  2. Vérifiez que le DNS essensys.acme.com pointe vers cette machine"
log_info "  3. Les certificats Let's Encrypt seront générés automatiquement"
log_info ""
log_info "Services:"
log_info "  - Traefik: systemctl status traefik"
log_info "  - Block Service: systemctl status traefik-block-service"
log_info ""
log_info "Logs:"
log_info "  - Traefik: tail -f /var/log/traefik/traefik.log"
log_info "  - Traefik errors: tail -f /var/log/traefik/traefik-error.log"
log_info ""

