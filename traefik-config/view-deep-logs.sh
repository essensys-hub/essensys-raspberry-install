#!/bin/bash

# Script pour voir TOUTES les traces Traefik en mode TRACE
# Affiche les logs Traefik, les logs d'accès, et les erreurs
# Usage: ./view-deep-logs.sh [IP_CLIENT] [OPTIONS]

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

CLIENT_IP="${1:-192.168.1.151}"
FOLLOW=false
SHOW_ALL=false

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -a|--all)
            SHOW_ALL=true
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

TRAEFIK_LOG="/var/log/traefik/traefik.log"
ACCESS_LOG="/var/log/traefik/access.log"
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

log_info "=== Logs Traefik en mode TRACE ==="
log_info "Client IP: $CLIENT_IP"
log_info ""

if [ "$FOLLOW" = true ]; then
    log_info "Suivi en temps réel (Ctrl+C pour arrêter)..."
    log_info ""
    
    # Afficher les logs Traefik en temps réel
    if [ "$SHOW_ALL" = true ]; then
        log_info "--- Logs Traefik (TOUTES les traces) ---"
        tail -f "$TRAEFIK_LOG" 2>/dev/null &
        TRAEFIK_PID=$!
    else
        log_info "--- Logs Traefik (client $CLIENT_IP uniquement) ---"
        tail -f "$TRAEFIK_LOG" 2>/dev/null | grep --line-buffered -i "$CLIENT_IP" &
        TRAEFIK_PID=$!
    fi
    
    # Afficher les logs d'accès en temps réel
    if [ -f "$ACCESS_LOG" ]; then
        if [ "$SHOW_ALL" = true ]; then
            log_info "--- Logs d'accès (TOUTES les requêtes) ---"
            tail -f "$ACCESS_LOG" 2>/dev/null &
            ACCESS_PID=$!
        else
            log_info "--- Logs d'accès (client $CLIENT_IP uniquement) ---"
            tail -f "$ACCESS_LOG" 2>/dev/null | grep --line-buffered "$CLIENT_IP" &
            ACCESS_PID=$!
        fi
    fi
    
    # Attendre l'interruption
    trap "kill $TRAEFIK_PID $ACCESS_PID 2>/dev/null; exit 0" INT TERM
    wait
else
    # Afficher les dernières lignes
    log_info "=== Dernières traces Traefik (mode TRACE) ==="
    if [ -f "$TRAEFIK_LOG" ]; then
        if [ "$SHOW_ALL" = true ]; then
            tail -100 "$TRAEFIK_LOG"
        else
            tail -200 "$TRAEFIK_LOG" | grep -i "$CLIENT_IP" | tail -50 || log_warn "Aucune trace de $CLIENT_IP dans les logs Traefik"
        fi
    else
        log_warn "Fichier de log Traefik introuvable: $TRAEFIK_LOG"
    fi
    echo ""
    
    log_info "=== Dernières requêtes d'accès ==="
    if [ -f "$ACCESS_LOG" ]; then
        if [ "$SHOW_ALL" = true ]; then
            tail -50 "$ACCESS_LOG"
        else
            tail -100 "$ACCESS_LOG" | grep "$CLIENT_IP" | tail -30 || log_warn "Aucune trace de $CLIENT_IP dans les logs d'accès"
        fi
    else
        log_warn "Fichier de log d'accès introuvable: $ACCESS_LOG"
    fi
    echo ""
    
    log_info "=== Erreurs Traefik ==="
    if [ -f "$ERROR_LOG" ]; then
        tail -50 "$ERROR_LOG" || log_info "Aucune erreur récente"
    else
        log_warn "Fichier de log d'erreur introuvable: $ERROR_LOG"
    fi
    echo ""
    
    log_info "=== Conseils ==="
    log_info "Pour voir les logs en temps réel:"
    log_info "  sudo $0 $CLIENT_IP --follow"
    log_info ""
    log_info "Pour voir toutes les traces (pas seulement le client):"
    log_info "  sudo $0 --all --follow"
    log_info ""
    log_info "Si aucune trace n'apparaît, le client peut être bloqué au niveau TCP:"
    log_info "  sudo ./capture-network-traffic.sh $CLIENT_IP"
    log_info ""
fi

