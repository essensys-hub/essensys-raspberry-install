#!/bin/bash

# Script pour capturer le trafic réseau au niveau TCP/IP
# Utile pour voir les connexions même si Traefik les rejette avant le parsing HTTP
# Usage: ./capture-network-traffic.sh [IP_CLIENT] [INTERFACE]

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

CLIENT_IP="${1:-192.168.1.151}"
INTERFACE="${2:-eth0}"
CAPTURE_FILE="/tmp/traefik-capture-$(date +%Y%m%d-%H%M%S).pcap"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier que tcpdump est installé
if ! command -v tcpdump &> /dev/null; then
    log_error "tcpdump n'est pas installé"
    log_info "Installation: sudo apt-get install tcpdump"
    exit 1
fi

# Vérifier les permissions
if [ "$EUID" -ne 0 ]; then 
    log_error "Ce script doit être exécuté en tant que root (utilisez sudo)"
    exit 1
fi

log_info "Capture du trafic réseau pour le client $CLIENT_IP"
log_info "Interface: $INTERFACE"
log_info "Fichier de capture: $CAPTURE_FILE"
log_info "Appuyez sur Ctrl+C pour arrêter"
log_info ""

# Capturer le trafic
log_info "Démarrage de la capture..."
log_info "Filtre: host $CLIENT_IP and port 80"
log_info ""

# Options tcpdump:
# -i: interface réseau
# -nn: ne pas résoudre les noms d'hôtes et ports
# -s 0: capturer les paquets complets (pas de troncature)
# -w: écrire dans un fichier pcap
# -v: verbose (plus de détails)
# -A: afficher le contenu ASCII (pour voir les requêtes HTTP)
tcpdump -i "$INTERFACE" -nn -s 0 -v -A "host $CLIENT_IP and port 80" -w "$CAPTURE_FILE" 2>&1 | tee /tmp/traefik-capture-live.txt &
TCPDUMP_PID=$!

log_info "Capture en cours (PID: $TCPDUMP_PID)"
log_info "Pour voir les paquets en temps réel, ouvrez un autre terminal et exécutez:"
log_info "  sudo tcpdump -r $CAPTURE_FILE -nn -A 'host $CLIENT_IP and port 80'"
log_info ""

# Attendre l'interruption
trap "kill $TCPDUMP_PID 2>/dev/null; log_info 'Capture arrêtée'; log_info 'Fichier sauvegardé: $CAPTURE_FILE'; exit 0" INT TERM

# Surveiller en temps réel
tail -f /tmp/traefik-capture-live.txt 2>/dev/null || wait $TCPDUMP_PID

