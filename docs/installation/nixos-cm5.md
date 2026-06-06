# Préparation NixOS — Gateway CM5

Automatisation Ansible pour migrer une CM5 Essensys vers **NixOS** (branche `nixos` de `essensys-raspberry-gateway`).

## Playbooks

| Playbook | Rôle | Usage |
|----------|------|--------|
| `uninstall.cm5.yml` | `raspberry_cm5_uninstall` | Retire stack Ansible/Docker/gateway |
| `prepare.nixos-cm5.yml` | `raspberry_cm5_nixos` | Clone flake, installe Nix, prépare eMMC/NVMe |

## Ordre recommandé

```bash
cd essensys-ansible

# 1. Désinstaller la stack Debian/Ansible (optionnel si migration)
ansible-playbook uninstall.cm5.yml -i inventory.gateway \
  -e confirm_cm5_uninstall=true

# 2. Préparer NixOS (non destructif sur eMMC par défaut)
ansible-playbook prepare.nixos-cm5.yml -i inventory.gateway \
  -e confirm_cm5_nixos_prep=true
```

## Sur la CM5 après prepare

- Flake cloné : `/opt/essensys-nixos`
- Override hardware : `nix/hosts/gateway-cm5/hardware-cm5.generated.nix`
- Script repartition eMMC (boot recovery uniquement) : `/usr/local/sbin/essensys-prepare-nixos-mmc.sh`

## Repartition eMMC

**Ne pas** repartitionner l'eMMC depuis le système qui boot dessus.

1. Boot recovery (USB/SD)
2. Exécuter le script prepare mmc
3. `nixos-install --flake /opt/essensys-nixos#gateway-cm5`

Le **NVMe** (`essensys-data`) est préservé par défaut pour `/mnt/nvme` et les données.

## Documentation complète

- [nixos-install-cm5.md](https://github.com/essensys-hub/essensys-raspberry-gateway/blob/nixos/docs/nixos-install-cm5.md) (dépôt gateway)
- `essensys-ansible/roles/raspberry_cm5_nixos/README.md`
