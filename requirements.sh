#!/bin/bash
# Script de pré-requis pour l'installation Essensys
# Usage: curl -sL https://raw.githubusercontent.com/essensys-hub/essensys-raspberry-install/main/requirements.sh | sudo bash

if [ "$EUID" -ne 0 ]; then
  echo "Erreur: Ce script doit être exécuté avec sudo"
  exit 1
fi

# Détecter l'utilisateur réel (celui qui a lancé sudo)
REAL_USER=${SUDO_USER:-$USER}
if [ "$REAL_USER" = "root" ]; then
    echo "Attention: Installation en tant que root direct."
    HOME_DIR="/root"
else
    HOME_DIR=$(getent passwd "$REAL_USER" | cut -d: -f6)
fi

echo "=== Installation des pré-requis Essensys ==="

# 1. Installation de Git
echo "[1/3] Mise à jour apt et installation de Git..."
apt-get update >/dev/null
apt-get install -y git >/dev/null

# 2. Clonage du dépôt
TARGET_DIR="$HOME_DIR/essensys-raspberry-install"
REPO_URL="https://github.com/essensys-hub/essensys-raspberry-install.git"

echo "[2/3] Préparation du dossier $TARGET_DIR..."

if [ -d "$TARGET_DIR" ]; then
    echo "      Le dossier existe déjà. Mise à jour..."
    cd "$TARGET_DIR"
    sudo -u "$REAL_USER" git pull
else
    echo "      Clonage du dépôt..."
    sudo -u "$REAL_USER" git clone "$REPO_URL" "$TARGET_DIR"
fi

# 3. Permissions
echo "[3/3] Configuration des permissions..."
chmod +x "$TARGET_DIR/install.sh"
chmod +x "$TARGET_DIR/setup_duckdns.sh"

echo ""
echo "=== Pré-requis terminés ! ==="
echo ""
echo "Pour lancer l'installation complète :"
echo "  cd $TARGET_DIR"
echo "  sudo ./install.sh"
echo ""
