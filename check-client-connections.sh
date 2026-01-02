#!/bin/bash

# Script pour vérifier les connexions du client legacy
# Affiche les logs Traefik et backend pour diagnostiquer les problèmes de connexion

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CLIENT_IP="${1:-192.168.1.151}"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info "Vérification des connexions du client $CLIENT_IP"
log_info "=============================================="
log_info ""

# Vérifier les logs Traefik
log_info "=== Logs Traefik (dernières 50 lignes) ==="
if [ -f "/var/log/traefik/traefik.log" ]; then
    echo "Recherche de $CLIENT_IP dans les logs Traefik..."
    grep -i "$CLIENT_IP" /var/log/traefik/traefik.log | tail -20 || log_warn "Aucune trace de $CLIENT_IP dans les logs Traefik"
else
    log_warn "Fichier de log Traefik introuvable: /var/log/traefik/traefik.log"
fi
echo ""

# Vérifier les logs d'accès Traefik
log_info "=== Logs d'accès Traefik (dernières 50 lignes) ==="
if [ -f "/var/log/traefik/access.log" ]; then
    echo "Recherche de $CLIENT_IP dans les logs d'accès Traefik..."
    grep -i "$CLIENT_IP" /var/log/traefik/access.log | tail -20 || log_warn "Aucune trace de $CLIENT_IP dans les logs d'accès Traefik"
else
    log_warn "Fichier de log d'accès Traefik introuvable: /var/log/traefik/access.log"
fi
echo ""

# Vérifier les logs backend
log_info "=== Logs Backend (dernières 50 lignes) ==="
if [ -f "/var/logs/Essensys/backend/console.out.log" ]; then
    echo "Recherche de $CLIENT_IP dans les logs backend..."
    grep -i "$CLIENT_IP" /var/logs/Essensys/backend/console.out.log | tail -20 || log_warn "Aucune trace de $CLIENT_IP dans les logs backend"
else
    log_warn "Fichier de log backend introuvable: /var/logs/Essensys/backend/console.out.log"
fi
echo ""

# Vérifier les logs nginx (si utilisé)
log_info "=== Logs Nginx (dernières 50 lignes) ==="
if [ -f "/var/log/nginx/essensys-access.log" ]; then
    echo "Recherche de $CLIENT_IP dans les logs nginx..."
    grep -i "$CLIENT_IP" /var/log/nginx/essensys-access.log | tail -20 || log_warn "Aucune trace de $CLIENT_IP dans les logs nginx"
else
    log_warn "Fichier de log nginx introuvable: /var/log/nginx/essensys-access.log"
fi
echo ""

# Vérifier les connexions actives
log_info "=== Connexions réseau actives ==="
echo "Recherche de connexions depuis $CLIENT_IP..."
if command -v ss &> /dev/null; then
    ss -tn | grep "$CLIENT_IP" || log_warn "Aucune connexion active depuis $CLIENT_IP"
elif command -v netstat &> /dev/null; then
    netstat -tn | grep "$CLIENT_IP" || log_warn "Aucune connexion active depuis $CLIENT_IP"
else
    log_warn "ss et netstat ne sont pas disponibles"
fi
echo ""

# Vérifier le statut des services
log_info "=== Statut des services ==="
if systemctl is-active --quiet traefik; then
    log_info "✓ Traefik: actif"
else
    log_error "✗ Traefik: inactif"
fi

if systemctl is-active --quiet essensys-backend; then
    log_info "✓ Backend: actif"
else
    log_error "✗ Backend: inactif"
fi

if systemctl is-active --quiet nginx; then
    log_info "✓ Nginx: actif"
else
    log_warn "⚠ Nginx: inactif"
fi
echo ""

# Vérifier les ports en écoute
log_info "=== Ports en écoute ==="
if command -v ss &> /dev/null; then
    ss -tlnp | grep -E ':(80|443|8080|8081)' || log_warn "Aucun port trouvé"
elif command -v netstat &> /dev/null; then
    netstat -tlnp | grep -E ':(80|443|8080|8081)' || log_warn "Aucun port trouvé"
fi
echo ""

log_info "=== Recommandations ==="
log_info "1. Vérifiez que le client $CLIENT_IP peut atteindre le serveur (ping)"
log_info "2. Vérifiez que le client utilise le bon DNS (mon.essensys.fr)"
log_info "3. Surveillez les logs en temps réel:"
log_info "   - Traefik: sudo tail -f /var/log/traefik/traefik.log"
log_info "   - Backend: sudo tail -f /var/logs/Essensys/backend/console.out.log"
log_info "4. Testez depuis le serveur: curl -v http://mon.essensys.fr/api/serverinfos"
log_info ""

