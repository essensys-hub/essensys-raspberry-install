#!/bin/bash

# Essensys - DuckDNS Setup Script
# Configures Dynamic DNS updates for essensys server

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ESSENSYS_DIR="/opt/essensys"
DUCKDNS_DIR="$ESSENSYS_DIR/duckdns"
DOMAIN_FILE="/home/essensys/domain.txt"
LOG_FILE="$DUCKDNS_DIR/duck.log"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check root
if [ "$EUID" -ne 0 ]; then 
  log_error "Ce script doit être exécuté en tant que root (sudo)."
  exit 1
fi

echo "=========================================="
echo "   Configuration DuckDNS pour Essensys"
echo "=========================================="
echo ""

# 1. Prompt for Token
echo "1. Connectez-vous sur https://www.duckdns.org"
echo "2. Copiez votre 'Token' affiché en haut de page."
echo ""
read -p "Entrez votre Token DuckDNS : " DUCK_TOKEN

if [ -z "$DUCK_TOKEN" ]; then
    log_error "Token vide. Annulation."
    exit 1
fi

# 2. Prompt for Domain
echo ""
echo "3. Créez un domaine sur DuckDNS (ex: 'mon-maison' pour 'mon-maison.duckdns.org')"
read -p "Entrez votre SOUS-DOMAINE (juste la partie avant .duckdns.org) : " DUCK_SUBDOMAIN

if [ -z "$DUCK_SUBDOMAIN" ]; then
    log_error "Sous-domaine vide. Annulation."
    exit 1
fi

FULL_DOMAIN="${DUCK_SUBDOMAIN}.duckdns.org"
log_info "Domaine complet : $FULL_DOMAIN"

# 3. Validation
log_info "Test de la configuration auprès de DuckDNS..."
RESPONSE=$(curl -s -k "https://www.duckdns.org/update?domains=${DUCK_SUBDOMAIN}&token=${DUCK_TOKEN}&ip=")

if [ "$RESPONSE" != "OK" ]; then
    log_error "Échec du test DuckDNS ! Le serveur a répondu : '$RESPONSE'"
    log_warn "Vérifiez votre Token et votre Sous-domaine."
    exit 1
fi

log_info "Test réussi ! Configuration valide."

# 4. Installation des fichiers
mkdir -p "$DUCKDNS_DIR"

# Config file
cat > "$DUCKDNS_DIR/duck.conf" <<EOF
DUCK_TOKEN="${DUCK_TOKEN}"
DUCK_SUBDOMAIN="${DUCK_SUBDOMAIN}"
EOF

# Update script
SCRIPT_PATH="$DUCKDNS_DIR/duckdns-update.sh"
cat > "$SCRIPT_PATH" <<EOF
#!/bin/bash
# Script de mise à jour automatique DuckDNS généré par Essensys
source $DUCKDNS_DIR/duck.conf
echo url="https://www.duckdns.org/update?domains=\${DUCK_SUBDOMAIN}&token=\${DUCK_TOKEN}&ip=" | curl -s -k -o $LOG_FILE -K -
EOF

chmod +x "$SCRIPT_PATH"
log_info "Fichiers de configuration créés dans $DUCKDNS_DIR"

# 5. Configuration Cron (toutes les 5 minutes)
# Nettoyage ancienne tâche si existe
crontab -l 2>/dev/null | grep -v "duckdns-update.sh" | crontab -

# Ajout nouvelle tâche
(crontab -l 2>/dev/null; echo "*/5 * * * * $SCRIPT_PATH >/dev/null 2>&1") | crontab -
log_info "Tâche planifiée (Cron) configurée : mise à jour toutes les 5 minutes."

# Exécution immédiate
log_info "Première mise à jour de l'IP..."
$SCRIPT_PATH

# 6. Mise à jour Essensys (Traefik)
log_info "Mise à jour de la configuration Essensys ($DOMAIN_FILE)..."
echo "$FULL_DOMAIN" > "$DOMAIN_FILE"
# Assurer les permissions pour l'utilisateur essensys
if id "essensys" &>/dev/null; then
    chown essensys:essensys "$DOMAIN_FILE"
fi

log_info "Redémarrage de Traefik pour prise en compte du nouveau domaine..."
systemctl restart traefik

echo ""
echo "=========================================="
echo "   Installation Terminée avec Succès !"
echo "=========================================="
echo "Domaine configuré : https://$FULL_DOMAIN"
echo "Une certification SSL (Let's Encrypt) va être générée automatiquement."
echo "Attendez quelques secondes puis testez l'accès."
echo ""
