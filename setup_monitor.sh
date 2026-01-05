#!/bin/bash

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITOR_SCRIPT="$SCRIPT_DIR/monitor.py"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Installation du Moniteur Essensys ===${NC}"

# 1. Rendre le script exécutable
if [ -f "$MONITOR_SCRIPT" ]; then
    chmod +x "$MONITOR_SCRIPT"
    echo -e "${GREEN}[OK]${NC} Script rendu exécutable : $MONITOR_SCRIPT"
else
    echo -e "${RED}[ERROR]${NC} Fichier introuvable : $MONITOR_SCRIPT"
    exit 1
fi

# 2. Vérifier les dépendances
echo -e "\nVérification des dépendances..."
if command -v python3 &> /dev/null; then
    echo -e "${GREEN}[OK]${NC} Python 3 est installé"
else
    echo -e "${RED}[ERROR]${NC} Python 3 n'est pas installé. Installez-le avec 'sudo apt install python3'"
fi

if command -v ss &> /dev/null; then
    echo -e "${GREEN}[OK]${NC} ss (iproute2) est installé"
else
    echo -e "${YELLOW}[WARN]${NC} ss n'est pas trouvé. Le compteur de clients risque de ne pas fonctionner."
fi

# 3. Vérifier les permissions logs
LOG_FILE="/var/logs/Essensys/backend/console.out.log"
if [ -r "$LOG_FILE" ]; then
    echo -e "${GREEN}[OK]${NC} Le fichier de log est lisible"
elif [ -f "$LOG_FILE" ]; then
    echo -e "${YELLOW}[WARN]${NC} Le fichier de log existe mais n'est pas lisible par l'utilisateur actuel."
    echo "       Le script devra probablement être lancé avec 'sudo'."
else
    echo -e "${YELLOW}[WARN]${NC} Le fichier de log n'existe pas encore ($LOG_FILE)."
fi

# 4. Instructions pour le démarrage automatique
echo -e "\n${GREEN}=== Instructions pour le démarrage automatique ===${NC}"
echo "Pour lancer ce moniteur automatiquement au démarrage sur l'écran connecté (HDMI/Ecran officiel),"
echo "ajoutez les lignes suivantes à la fin de votre fichier ~/.bashrc :"
echo ""
echo -e "${YELLOW}"
echo "# Lancer le moniteur Essensys uniquement sur tty1 (écran physique)"
echo "if [ -z \"\$SSH_CLIENT\" ] && [ -z \"\$SSH_TTY\" ]; then"
echo "    if [ \"\$(tty)\" = \"/dev/tty1\" ]; then"
echo "        # Attendre un peu que le réseau soit prêt"
echo "        # sleep 5"
echo "        sudo $MONITOR_SCRIPT"
echo "    fi"
echo "fi"
echo -e "${NC}"
echo ""
echo "Assurez-vous également que le Raspberry Pi est configuré pour se connecter automatiquement en console (Autologin Console)."
echo "Vous pouvez configurer cela via 'sudo raspi-config' -> 'System Options' -> 'Boot / Auto Login' -> 'Console Autologin'."
echo ""
echo "Pour tester le moniteur maintenant :"
echo "sudo $MONITOR_SCRIPT"
