# Configuration réseau

Cette section explique comment configurer le réseau sur le Raspberry Pi (DHCP ou IP statique).

## Configuration automatique (DHCP)

Par défaut, le Raspberry Pi utilise DHCP pour obtenir automatiquement une adresse IP.

### Vérifier la configuration actuelle

```bash
# Voir l'adresse IP
ip addr show eth0

# Ou
ifconfig eth0
```

### Redémarrer le service réseau

Si l'interface ne fonctionne pas :

```bash
sudo systemctl restart dhcpcd
```

## Configuration IP statique

### Méthode 1 : Via dhcpcd.conf

Éditer `/etc/dhcpcd.conf` :

```bash
sudo nano /etc/dhcpcd.conf
```

Ajouter à la fin du fichier :

```bash
# Configuration IP statique pour eth0
interface eth0
static ip_address=192.168.1.101/24
static routers=192.168.1.1
static domain_name_servers=8.8.8.8 8.8.4.4
```

**Paramètres :**
- `static ip_address` : Adresse IP et masque (format CIDR)
- `static routers` : Passerelle (routeur)
- `static domain_name_servers` : Serveurs DNS

Redémarrer le service :

```bash
sudo systemctl restart dhcpcd
```

### Méthode 2 : Via netplan (si disponible)

Créer `/etc/netplan/01-netcfg.yaml` :

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.1.101/24
      gateway4: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

Appliquer la configuration :

```bash
sudo netplan apply
```

## Configuration DNS

### DNS local (mon.essensys.fr)

Pour que `mon.essensys.fr` pointe vers le Raspberry Pi, configurer le DNS sur votre routeur ou utiliser `/etc/hosts` :

```bash
sudo nano /etc/hosts
```

Ajouter :
```
192.168.1.101 mon.essensys.fr
```

### DNS via routeur

Configurer le DNS sur votre routeur pour que `mon.essensys.fr` pointe vers `192.168.1.101`.

Voir la section [Configuration Routeur](../router/index.md) pour plus de détails.

## Dépannage réseau

### L'interface eth0 ne démarre pas

```bash
# Vérifier l'état de l'interface
ip link show eth0

# Activer l'interface
sudo ip link set eth0 up

# Redémarrer le service
sudo systemctl restart dhcpcd
```

### Pas d'adresse IP

```bash
# Forcer la demande DHCP
sudo dhclient eth0

# Vérifier les logs
sudo journalctl -u dhcpcd -n 50
```

### Problème de connectivité

```bash
# Tester la connectivité
ping -c 3 8.8.8.8

# Tester la résolution DNS
nslookup google.com

# Vérifier la route
ip route show
```

## Scripts de configuration

Des scripts sont fournis pour faciliter la configuration :

### Script de réparation rapide

```bash
cd ~/essensys-raspberry-install
sudo ./fix-network.sh
```

### Script de configuration complète

```bash
cd ~/essensys-raspberry-install
sudo ./configure-network.sh
```

Le script vous demandera :
- Mode DHCP ou IP statique
- Adresse IP (si statique)
- Masque de sous-réseau
- Passerelle
- Serveurs DNS

## Prochaines étapes

Une fois le réseau configuré :

1. [Installation Essensys](../installation/essensys-installation.md) - Installer Essensys
2. [Configuration Routeur](../router/index.md) - Configurer le NAT/port forwarding

