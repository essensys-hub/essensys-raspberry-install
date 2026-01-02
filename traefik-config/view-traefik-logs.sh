#!/bin/bash

# Script pour voir les logs Traefik filtrés par IP client
# Usage: ./view-traefik-logs.sh [IP_CLIENT] [OPTIONS]
# Options:
#   -a, --all      : Afficher toutes les requêtes (pas seulement le client)
#   -e, --errors   : Afficher uniquement les erreurs
#   -t, --tail     : Suivre les logs en temps réel

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

CLIENT_IP="${1:-192.168.1.151}"
SHOW_ALL=false
SHOW_ERRORS=false
FOLLOW=false

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            SHOW_ALL=true
            shift
            ;;
        -e|--errors)
            SHOW_ERRORS=true
            shift
            ;;
        -t|--tail)
            FOLLOW=true
            shift
            ;;
        *)
            if [[ ! "$1" =~ ^- ]]; then
                CLIENT_IP="$1"
            fi
            shift
            ;;
    esac
done

ACCESS_LOG="/var/log/traefik/access.log"
TRAEFIK_LOG="/var/log/traefik/traefik.log"
ERROR_LOG="/var/log/traefik/traefik-error.log"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

if [ "$SHOW_ALL" = true ]; then
    log_info "Affichage de TOUTES les requêtes reçues par Traefik"
else
    log_info "Recherche des connexions du client $CLIENT_IP"
fi
log_info "=============================================="
log_info ""

# Vérifier les logs d'accès (format JSON)
if [ "$SHOW_ERRORS" = true ]; then
    log_info "=== Logs d'accès Traefik - ERREURS UNIQUEMENT ==="
    FILTER_CMD="grep -E '\"DownstreamStatus\":[4-5][0-9][0-9]'"
elif [ "$SHOW_ALL" = true ]; then
    log_info "=== Logs d'accès Traefik - TOUTES LES REQUÊTES ==="
    FILTER_CMD="cat"
else
    log_info "=== Logs d'accès Traefik (format JSON) ==="
    FILTER_CMD="grep \"$CLIENT_IP\""
fi

if [ -f "$ACCESS_LOG" ]; then
    if [ "$FOLLOW" = true ]; then
        log_info "Suivi en temps réel (Ctrl+C pour arrêter)..."
        if command -v jq &> /dev/null; then
            tail -f "$ACCESS_LOG" | $FILTER_CMD | jq -r '. | "\(.RequestMethod) \(.RequestPath) - Status:\(.DownstreamStatus) - IP:\(.RequestAddr) - Duration:\(.Duration)ms"' 2>/dev/null || \
            tail -f "$ACCESS_LOG" | $FILTER_CMD
        else
            tail -f "$ACCESS_LOG" | $FILTER_CMD
        fi
        exit 0
    fi
    
    if command -v jq &> /dev/null; then
        # Si jq est disponible, formater le JSON de manière détaillée
        if [ "$SHOW_ERRORS" = true ]; then
            tail -100 "$ACCESS_LOG" | jq -r 'select(.DownstreamStatus >= 400) | "\(.RequestMethod) \(.RequestPath) - Status:\(.DownstreamStatus) - IP:\(.RequestAddr) - Duration:\(.Duration)ms - Router:\(.RouterName // "none")"' 2>/dev/null | tail -30 || \
            tail -100 "$ACCESS_LOG" | grep -E '"DownstreamStatus":[4-5][0-9][0-9]' | tail -30
        elif [ "$SHOW_ALL" = true ]; then
            tail -50 "$ACCESS_LOG" | jq -r '. | "\(.RequestMethod) \(.RequestPath) - Status:\(.DownstreamStatus) - IP:\(.RequestAddr) - Duration:\(.Duration)ms - Router:\(.RouterName // "none")"' 2>/dev/null || \
            tail -50 "$ACCESS_LOG"
        else
            grep "$CLIENT_IP" "$ACCESS_LOG" | tail -30 | jq -r '. | "\(.RequestMethod) \(.RequestPath) - Status:\(.DownstreamStatus) - IP:\(.RequestAddr) - Duration:\(.Duration)ms - Router:\(.RouterName // "none")"' 2>/dev/null || \
            grep "$CLIENT_IP" "$ACCESS_LOG" | tail -30
        fi
    else
        # Sinon, afficher le JSON brut
        if [ "$SHOW_ERRORS" = true ]; then
            tail -100 "$ACCESS_LOG" | grep -E '"DownstreamStatus":[4-5][0-9][0-9]' | tail -30 || log_warn "Aucune erreur trouvée dans les logs d'accès"
        elif [ "$SHOW_ALL" = true ]; then
            tail -50 "$ACCESS_LOG" || log_warn "Fichier de log vide"
        else
            grep "$CLIENT_IP" "$ACCESS_LOG" | tail -30 || log_warn "Aucune trace de $CLIENT_IP dans les logs d'accès"
        fi
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

# Afficher les erreurs HTTP
log_info "=== Erreurs HTTP (codes 4xx et 5xx) ==="
if [ -f "$ACCESS_LOG" ]; then
    if command -v jq &> /dev/null; then
        tail -100 "$ACCESS_LOG" | jq -r 'select(.DownstreamStatus >= 400) | "\(.RequestMethod) \(.RequestPath) - Status:\(.DownstreamStatus) - IP:\(.RequestAddr) - Router:\(.RouterName // "none") - Service:\(.ServiceName // "none")"' 2>/dev/null | tail -20 || \
        tail -100 "$ACCESS_LOG" | grep -E '"DownstreamStatus":[4-5][0-9][0-9]' | tail -20
    else
        tail -100 "$ACCESS_LOG" | grep -E '"DownstreamStatus":[4-5][0-9][0-9]' | tail -20 || log_info "Aucune erreur HTTP trouvée"
    fi
else
    log_warn "Fichier de log d'accès introuvable"
fi
echo ""

# Afficher les logs d'erreur Traefik
if [ -f "$ERROR_LOG" ]; then
    log_info "=== Logs d'erreur Traefik ==="
    tail -30 "$ERROR_LOG" || log_warn "Aucune erreur dans le fichier d'erreur"
    echo ""
fi

log_info "=== Commandes utiles ==="
log_info "Voir toutes les requêtes en temps réel:"
log_info "  sudo $0 --all --tail"
log_info ""
log_info "Voir uniquement les erreurs:"
log_info "  sudo $0 --errors"
log_info ""
log_info "Voir les requêtes d'un client spécifique:"
log_info "  sudo $0 192.168.1.151"
log_info ""
log_info "Voir toutes les requêtes (dernières 50):"
log_info "  sudo $0 --all"
log_info ""

