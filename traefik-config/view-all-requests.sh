#!/bin/bash

# Script pour voir TOUTES les requêtes reçues par Traefik en temps réel
# Usage: ./view-all-requests.sh [OPTIONS]
# Options:
#   -e, --errors   : Afficher uniquement les erreurs
#   -f, --follow   : Suivre en temps réel (défaut)

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SHOW_ERRORS=false
FOLLOW=true

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--errors)
            SHOW_ERRORS=true
            shift
            ;;
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -e, --errors   Afficher uniquement les erreurs HTTP (4xx, 5xx)"
            echo "  -f, --follow   Suivre les logs en temps réel (défaut)"
            echo "  -h, --help     Afficher cette aide"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

ACCESS_LOG="/var/log/traefik/access.log"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

if [ ! -f "$ACCESS_LOG" ]; then
    log_error "Fichier de log introuvable: $ACCESS_LOG"
    exit 1
fi

if [ "$SHOW_ERRORS" = true ]; then
    log_info "Affichage des ERREURS HTTP uniquement (codes 4xx et 5xx)"
    log_info "Appuyez sur Ctrl+C pour arrêter"
    echo ""
    
    if command -v jq &> /dev/null; then
        tail -f "$ACCESS_LOG" | jq -r 'select(.DownstreamStatus >= 400) | "\(.time) | \(.RequestMethod) \(.RequestPath) | Status:\(.DownstreamStatus) | IP:\(.RequestAddr) | Router:\(.RouterName // "none")"' 2>/dev/null
    else
        tail -f "$ACCESS_LOG" | grep --line-buffered -E '"DownstreamStatus":[4-5][0-9][0-9]'
    fi
else
    log_info "Affichage de TOUTES les requêtes reçues par Traefik"
    log_info "Appuyez sur Ctrl+C pour arrêter"
    echo ""
    
    if [ "$FOLLOW" = true ]; then
        if command -v jq &> /dev/null; then
            tail -f "$ACCESS_LOG" | jq -r '. | "\(.time) | \(.RequestMethod) \(.RequestPath) | Status:\(.DownstreamStatus) | IP:\(.RequestAddr) | Router:\(.RouterName // "none")"' 2>/dev/null
        else
            tail -f "$ACCESS_LOG"
        fi
    else
        if command -v jq &> /dev/null; then
            tail -50 "$ACCESS_LOG" | jq -r '. | "\(.time) | \(.RequestMethod) \(.RequestPath) | Status:\(.DownstreamStatus) | IP:\(.RequestAddr) | Router:\(.RouterName // "none")"' 2>/dev/null
        else
            tail -50 "$ACCESS_LOG"
        fi
    fi
fi

