#!/bin/bash
# Noms personnalises des lumieres (Feature noms-lumieres-2026-11-004, essensys-feature-lifecycle#41)
#
# Cree le repertoire du fichier light-names.json, donne les droits d'ecriture
# au service et pose la cle `light_names.path` dans le config.yaml du backend,
# de facon idempotente (aucune modification si la cle existe deja, y compris
# le bloc gere par Ansible).
#
# Usage : setup-light-names.sh <config.yaml> <repertoire> <utilisateur>
#
# Le service systemd du backend est durci (ProtectSystem=strict, ecriture
# limitee a /opt/essensys et /var/log/essensys) : le repertoire doit donc rester
# sous /opt/essensys. Sur les installations pilotees par Docker Compose (Ansible),
# le repertoire est /opt/data/light-names, monte sur /var/lib/essensys/names.
set -euo pipefail

CONFIG="${1:?config.yaml manquant}"
NAMES_DIR="${2:?repertoire manquant}"
SERVICE_USER="${3:?utilisateur manquant}"

mkdir -p "$NAMES_DIR"
chmod 0750 "$NAMES_DIR"
# Hors root (tests), le chown est ignore.
if [ "$(id -u)" -eq 0 ]; then
    chown "$SERVICE_USER:$SERVICE_USER" "$NAMES_DIR"
fi

if [ ! -f "$CONFIG" ]; then
    echo "[WARN] $CONFIG introuvable : cle light_names.path non posee" >&2
    exit 0
fi

if grep -Eq '^light_names:' "$CONFIG"; then
    echo "[INFO] light_names deja present dans $CONFIG"
else
    # Ligne vide de securite si le fichier ne se termine pas par un saut de ligne.
    [ -n "$(tail -c1 "$CONFIG")" ] && echo >> "$CONFIG"
    {
        echo "light_names:"
        echo "  path: \"$NAMES_DIR/light-names.json\""
    } >> "$CONFIG"
    echo "[INFO] light_names.path ajoute dans $CONFIG"
fi
