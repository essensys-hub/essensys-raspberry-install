# Désinstallation

Guide pour désinstaller complètement Essensys du Raspberry Pi.

## Désinstallation automatique

## Gateway CM5 (Ansible)

Pour la **CM5 Essensys** (stack Docker + dual-NIC + NVMe) :

```bash
cd essensys-ansible
ansible-playbook uninstall.cm5.yml -i inventory.gateway \
  -e confirm_cm5_uninstall=true
```

Options :

| Variable | Effet |
|----------|--------|
| `cm5_remove_nvme_fstab=true` | Retire le montage NVMe du fstab |
| `cm5_wipe_nvme_data=true` | Efface la partition NVMe (**irréversible**) |
| `cm5_remove_docker_packages=true` | Désinstalle Docker |

Voir `essensys-ansible/roles/raspberry_cm5_uninstall/README.md`.

## Migration NixOS CM5

Préparation du flake NixOS (clone, Nix, script repartition eMMC **offline**) :

```bash
ansible-playbook prepare.nixos-cm5.yml -i inventory.gateway \
  -e confirm_cm5_nixos_prep=true
```

Documentation : `essensys-raspberry-gateway/docs/nixos-install-cm5.md` et role `raspberry_cm5_nixos`.

### Script uninstall.sh

Le script `uninstall.sh` automatise la désinstallation complète :

```bash
cd ~/essensys-raspberry-install
sudo ./uninstall.sh
```

Le script va :
1. Demander confirmation
2. Arrêter et désactiver tous les services
3. Supprimer les fichiers de service systemd
4. Supprimer la configuration Nginx
5. Supprimer la configuration Traefik
6. Supprimer les binaires
7. Supprimer les fichiers d'installation
8. Supprimer tous les logs
9. Optionnellement supprimer l'utilisateur et les dépôts

## Désinstallation manuelle

### Arrêter les services

```bash
sudo systemctl stop essensys-backend
sudo systemctl stop traefik
sudo systemctl stop traefik-block-service
sudo systemctl stop nginx
```

### Supprimer les services

```bash
sudo systemctl disable essensys-backend
sudo systemctl disable traefik
sudo systemctl disable traefik-block-service
sudo rm /etc/systemd/system/essensys-backend.service
sudo rm /etc/systemd/system/traefik.service
sudo rm /etc/systemd/system/traefik-block-service.service
sudo systemctl daemon-reload
```

### Supprimer les fichiers

```bash
# Configuration
sudo rm -rf /etc/traefik
sudo rm /etc/nginx/sites-available/essensys
sudo rm /etc/nginx/sites-enabled/essensys

# Installation
sudo rm -rf /opt/essensys

# Logs
sudo rm -rf /var/logs/Essensys
sudo rm -rf /var/log/traefik
sudo rm -f /var/log/nginx/essensys-*.log

# Binaires
sudo rm -f /usr/local/bin/traefik
sudo rm -f /usr/local/bin/traefik-block-service.py
```

### Supprimer l'utilisateur (optionnel)

```bash
sudo userdel -r essensys
```
