#!/bin/bash

# Script pour libérer les ports et arrêter les services en conflit
# Usage: sudo ./fix-ports.sh

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

log_info "Libération des ports et arrêt des services en conflit"
log_info "====================================================="

# Arrêter tous les services Essensys
log_info "Arrêt des services Essensys..."
systemctl stop essensys-backend 2>/dev/null && log_info "✓ essensys-backend arrêté" || log_info "essensys-backend n'était pas démarré"
systemctl stop essensys-frontend 2>/dev/null && log_info "✓ essensys-frontend arrêté" || log_info "essensys-frontend n'était pas démarré"
systemctl stop nginx 2>/dev/null && log_info "✓ nginx arrêté" || log_info "nginx n'était pas démarré"

# Fonction pour trouver et arrêter un processus sur un port
kill_port() {
    local PORT=$1
    local PORT_NAME=$2
    
    log_info "Vérification du port $PORT ($PORT_NAME)..."
    
    PID=""
    
    # Essayer avec ss (généralement disponible sur Debian/Raspberry Pi OS)
    if command -v ss &> /dev/null; then
        PID=$(ss -tlnp 2>/dev/null | grep ":$PORT " | grep -oP 'pid=\K[0-9]+' | head -1)
    fi
    
    # Si ss ne fonctionne pas, essayer avec netstat
    if [ -z "$PID" ] && command -v netstat &> /dev/null; then
        PID=$(netstat -tlnp 2>/dev/null | grep ":$PORT " | awk '{print $7}' | cut -d'/' -f1 | head -1)
    fi
    
    # Si netstat ne fonctionne pas, essayer avec lsof (peut ne pas être installé)
    if [ -z "$PID" ] && command -v lsof &> /dev/null; then
        PID=$(lsof -ti:$PORT 2>/dev/null)
    fi
    
    # Dernière tentative avec fuser (si disponible)
    if [ -z "$PID" ] && command -v fuser &> /dev/null; then
        PID=$(fuser $PORT/tcp 2>/dev/null | awk '{print $1}' | head -1)
    fi
    
    if [ -n "$PID" ]; then
        PROCESS_NAME=$(ps -p "$PID" -o comm= 2>/dev/null || echo "inconnu")
        log_warn "Le port $PORT est utilisé par le processus PID $PID ($PROCESS_NAME)"
        
        # Si c'est un service systemd, l'arrêter proprement
        if systemctl is-active --quiet "$PROCESS_NAME" 2>/dev/null; then
            log_info "Arrêt du service $PROCESS_NAME..."
            systemctl stop "$PROCESS_NAME" 2>/dev/null || true
        else
            log_info "Arrêt du processus $PID..."
            kill "$PID" 2>/dev/null || kill -9 "$PID" 2>/dev/null || log_warn "Impossible d'arrêter le processus"
            sleep 1
        fi
        
        # Vérifier que le port est libéré
        sleep 1
        NEW_PID=""
        if command -v ss &> /dev/null; then
            NEW_PID=$(ss -tlnp 2>/dev/null | grep ":$PORT " | grep -oP 'pid=\K[0-9]+' | head -1)
        elif command -v netstat &> /dev/null; then
            NEW_PID=$(netstat -tlnp 2>/dev/null | grep ":$PORT " | awk '{print $7}' | cut -d'/' -f1 | head -1)
        elif command -v lsof &> /dev/null; then
            NEW_PID=$(lsof -ti:$PORT 2>/dev/null)
        fi
        
        if [ -z "$NEW_PID" ]; then
            log_info "✓ Port $PORT libéré"
        else
            log_warn "Le port $PORT est toujours utilisé par PID $NEW_PID"
        fi
    else
        log_info "✓ Port $PORT libre"
    fi
}

# Libérer les ports
kill_port 80 "HTTP (nginx/backend)"
kill_port 8080 "Backend Go"
kill_port 9090 "Frontend"

log_info ""
log_info "Vérification finale des ports..."
echo ""

# Afficher les ports utilisés avec la méthode disponible
if command -v ss &> /dev/null; then
    ss -tlnp 2>/dev/null | grep -E ":(80|8080|9090) " || log_info "Aucun processus trouvé sur les ports 80, 8080, 9090"
elif command -v netstat &> /dev/null; then
    netstat -tlnp 2>/dev/null | grep -E ":(80|8080|9090) " || log_info "Aucun processus trouvé sur les ports 80, 8080, 9090"
elif command -v lsof &> /dev/null; then
    lsof -i :80 -i :8080 -i :9090 2>/dev/null || log_info "Aucun processus trouvé sur les ports 80, 8080, 9090"
else
    log_warn "Aucun outil disponible pour vérifier les ports (ss, netstat, lsof)"
    log_info "Vous pouvez installer un outil avec: sudo apt-get install net-tools"
fi

log_info ""
log_info "=========================================="
log_info "Ports libérés!"
log_info "=========================================="
log_info ""
log_info "Vous pouvez maintenant:"
log_info "  - Exécuter: sudo ./install.sh (pour config avec nginx)"
log_info "  - Ou: sudo ./install-without-nginx.sh (pour config sans nginx)"
log_info ""

