#!/bin/bash
set -e

echo "=== Desinstallation de l'ancien Mosquitto ==="

# Arreter le service systemd
echo "[1/5] Arret du service systemd mosquitto..."
sudo systemctl stop mosquitto 2>/dev/null || true
sudo systemctl disable mosquitto 2>/dev/null || true

# Arreter et supprimer le conteneur Docker
echo "[2/5] Arret du conteneur Docker mosquitto..."
sudo docker compose -f /opt/essensys/mosquitto/docker-compose.yml down 2>/dev/null || true
sudo docker rm -f mosquitto 2>/dev/null || true

# Supprimer le service systemd
echo "[3/5] Suppression du service systemd..."
sudo rm -f /etc/systemd/system/mosquitto.service
sudo systemctl daemon-reload

# Supprimer l'ancienne image
echo "[4/5] Suppression de l'ancienne image Docker..."
sudo docker rmi eclipse-mosquitto:2 2>/dev/null || true

# Supprimer les anciens fichiers (garder les donnees pour migration)
echo "[5/5] Nettoyage des fichiers..."
if [ -d "/opt/essensys/mosquitto" ]; then
    echo "  Les donnees sont conservees dans /opt/essensys/mosquitto/ pour migration."
    echo "  Elles seront migrees vers /opt/data/ par Ansible lors du prochain install.sh."
    echo "  Vous pourrez supprimer /opt/essensys/mosquitto/ manuellement apres verification."
fi

echo ""
echo "=== Desinstallation terminee ==="
echo "Vous pouvez maintenant lancer install.sh pour deployer Mosquitto via Docker Compose."
