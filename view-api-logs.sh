#!/bin/bash

# Script pour visualiser les logs API nginx de manière lisible
# Usage: ./view-api-logs.sh [options]

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

API_DETAILED_LOG="/var/log/nginx/essensys-api-detailed.log"
API_ERROR_LOG="/var/log/nginx/essensys-api-error.log"

show_help() {
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  -f, --follow      Suivre les logs en temps réel (tail -f)"
    echo "  -e, --errors       Afficher uniquement les erreurs"
    echo "  -m, --mystatus     Filtrer les requêtes /api/mystatus"
    echo "  -a, --myactions    Filtrer les requêtes /api/myactions"
    echo "  -s, --serverinfos Filtrer les requêtes /api/serverinfos"
    echo "  -d, --done         Filtrer les requêtes /api/done"
    echo "  -i, --inject       Filtrer les requêtes /api/admin/inject"
    echo "  -n, --lines N      Afficher les N dernières lignes (défaut: 50)"
    echo "  -h, --help         Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 -f                    # Suivre tous les logs API en temps réel"
    echo "  $0 -m -n 100             # Afficher les 100 dernières requêtes mystatus"
    echo "  $0 -e                    # Afficher les erreurs"
    echo "  $0 -s -f                 # Suivre les requêtes serverinfos en temps réel"
}

# Vérifier les permissions
if [ ! -r "$API_DETAILED_LOG" ] && [ ! -r "$API_ERROR_LOG" ]; then
    echo "Erreur: Impossible de lire les logs API"
    echo "Les fichiers doivent être accessibles:"
    echo "  - $API_DETAILED_LOG"
    echo "  - $API_ERROR_LOG"
    exit 1
fi

# Options par défaut
FOLLOW=false
SHOW_ERRORS=false
FILTER=""
LINES=50

# Parser les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -e|--errors)
            SHOW_ERRORS=true
            shift
            ;;
        -m|--mystatus)
            FILTER="/api/mystatus"
            shift
            ;;
        -a|--myactions)
            FILTER="/api/myactions"
            shift
            ;;
        -s|--serverinfos)
            FILTER="/api/serverinfos"
            shift
            ;;
        -d|--done)
            FILTER="/api/done"
            shift
            ;;
        -i|--inject)
            FILTER="/api/admin/inject"
            shift
            ;;
        -n|--lines)
            LINES="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Afficher les erreurs
if [ "$SHOW_ERRORS" = true ]; then
    echo -e "${RED}=== Logs d'erreur API ===${NC}"
    if [ "$FOLLOW" = true ]; then
        tail -f "$API_ERROR_LOG"
    else
        tail -n "$LINES" "$API_ERROR_LOG"
    fi
    exit 0
fi

# Afficher les logs détaillés
echo -e "${GREEN}=== Logs API détaillés ===${NC}"
if [ -n "$FILTER" ]; then
    echo -e "${BLUE}Filtre: $FILTER${NC}"
fi
echo ""

if [ "$FOLLOW" = true ]; then
    if [ -n "$FILTER" ]; then
        tail -f "$API_DETAILED_LOG" | grep --line-buffered "$FILTER"
    else
        tail -f "$API_DETAILED_LOG"
    fi
else
    if [ -n "$FILTER" ]; then
        grep "$FILTER" "$API_DETAILED_LOG" | tail -n "$LINES"
    else
        tail -n "$LINES" "$API_DETAILED_LOG"
    fi
fi

