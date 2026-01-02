#!/bin/bash

# Script pour voir les logs Traefik filtrés par IP client
# Usage: ./view-traefik-logs.sh [IP_CLIENT]

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CLIENT_IP="${1:-192.168.1.151}"
ACCESS_LOG="/var/log/traefik/access.log"
TRAEFIK_LOG="/var/log/traefik/traefik.log"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info "Recherche des connexions du client $CLIENT_IP"
log_info "=============================================="
log_info ""

# Vérifier les logs d'accès (format JSON)
log_info "=== Logs d'accès Traefik (format JSON) ==="
if [ -f "$ACCESS_LOG" ]; then
    echo "Recherche de $CLIENT_IP dans les logs d'accès..."
    if command -v jq &> /dev/null; then
        # Si jq est disponible, formater le JSON
        grep "$CLIENT_IP" "$ACCESS_LOG" | tail -20 | jq -r '. | "\(.RequestMethod) \(.RequestPath) - \(.DownstreamStatus) - \(.RequestAddr) - \(.Duration)"' || \
        grep "$CLIENT_IP" "$ACCESS_LOG" | tail -20
    else
        # Sinon, afficher le JSON brut
        grep "$CLIENT_IP" "$ACCESS_LOG" | tail -20 || log_warn "Aucune trace de $CLIENT_IP dans les logs d'accès"
    fi
else
    log_warn "Fichier de log d'accès introuvable: $ACCESS_LOG"
fi
echo ""

# Vérifier les logs Traefik (format texte)
log_info "=== Logs Traefik (format texte) ==="
if [ -f "$TRAEFIK_LOG" ]; then
    echo "Recherche de $CLIENT_IP dans les logs Traefik..."
    grep -i "$CLIENT_IP" "$TRAEFIK_LOG" | tail -20 || log_warn "Aucune trace de $CLIENT_IP dans les logs Traefik"
else
    log_warn "Fichier de log Traefik introuvable: $TRAEFIK_LOG"
fi
echo ""

# Afficher toutes les IPs qui se connectent
log_info "=== Toutes les IPs qui se connectent (dernières 50 requêtes) ==="
if [ -f "$ACCESS_LOG" ]; then
    if command -v jq &> /dev/null; then
        tail -50 "$ACCESS_LOG" | jq -r '.RequestAddr' | sort | uniq -c | sort -rn
    else
        # Extraire les IPs manuellement depuis le JSON
        tail -50 "$ACCESS_LOG" | grep -o '"RequestAddr":"[^"]*"' | sed 's/"RequestAddr":"\([^"]*\)"/\1/' | sort | uniq -c | sort -rn
    fi
else
    log_warn "Fichier de log d'accès introuvable"
fi
echo ""

log_info "=== Pour surveiller en temps réel ==="
log_info "sudo tail -f $ACCESS_LOG | grep $CLIENT_IP"
log_info "sudo tail -f $TRAEFIK_LOG | grep -i $CLIENT_IP"
log_info ""

