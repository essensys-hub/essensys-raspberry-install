#!/bin/bash

# Script pour générer le fichier htpasswd pour l'authentification Traefik
# Usage: ./generate-htpasswd.sh [username]

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

# Vérifier que htpasswd est installé
if ! command -v htpasswd &> /dev/null; then
    log_error "htpasswd n'est pas installé. Installation..."
    if [ "$EUID" -ne 0 ]; then 
        log_error "Ce script doit être exécuté en tant que root pour installer htpasswd"
        exit 1
    fi
    apt-get update
    apt-get install -y apache2-utils
fi

# Demander le nom d'utilisateur
if [ -z "$1" ]; then
    read -p "Nom d'utilisateur: " USERNAME
else
    USERNAME="$1"
fi

if [ -z "$USERNAME" ]; then
    log_error "Le nom d'utilisateur ne peut pas être vide"
    exit 1
fi

# Fichier de sortie
HTPASSWD_FILE="/etc/traefik/users.htpasswd"

# Créer le répertoire si nécessaire
mkdir -p "$(dirname "$HTPASSWD_FILE")"

# Demander le mot de passe (sans l'afficher)
read -sp "Mot de passe: " PASSWORD
echo ""

if [ -z "$PASSWORD" ]; then
    log_error "Le mot de passe ne peut pas être vide"
    exit 1
fi

# Générer le fichier htpasswd
log_info "Génération du fichier htpasswd..."
htpasswd -nbB "$USERNAME" "$PASSWORD" > "$HTPASSWD_FILE"

# Si le fichier existe déjà, ajouter l'utilisateur au lieu de le remplacer
if [ -f "$HTPASSWD_FILE" ] && [ $(wc -l < "$HTPASSWD_FILE") -gt 0 ]; then
    log_warn "Le fichier existe déjà. Ajout de l'utilisateur..."
    htpasswd -nbB "$USERNAME" "$PASSWORD" >> "$HTPASSWD_FILE"
fi

# Définir les permissions
chmod 600 "$HTPASSWD_FILE"
chown root:root "$HTPASSWD_FILE"

log_info "Fichier htpasswd créé avec succès: $HTPASSWD_FILE"
log_info "Utilisateur: $USERNAME"
log_info ""
log_info "Pour ajouter d'autres utilisateurs, exécutez à nouveau ce script"

