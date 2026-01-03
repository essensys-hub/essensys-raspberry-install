# Connexion SSH

Cette section explique comment se connecter au Raspberry Pi via SSH.

## Prérequis

- Raspberry Pi OS installé et démarré
- SSH activé dans Raspberry Pi Imager (ou activé manuellement)
- Raspberry Pi connecté au réseau (Ethernet ou Wi-Fi)
- Adresse IP du Raspberry Pi connue

## Trouver l'adresse IP

### Méthode 1 : Via le routeur

1. Se connecter à l'interface d'administration du routeur
2. Chercher dans la liste des appareils connectés
3. Identifier le Raspberry Pi par :
   - Nom d'hôte : `raspberrypi` (par défaut)
   - Adresse MAC : Commence par `B8:27:EB`, `DC:A6:32`, ou `E4:5F:01`

### Méthode 2 : Scan réseau

Depuis votre ordinateur sur le même réseau :

**Linux/Mac :**
```bash
# Scanner le réseau local
nmap -sn 192.168.1.0/24

# Ou utiliser arp
arp -a | grep -i "b8:27:eb\|dc:a6:32\|e4:5f:01"
```

**Windows :**
```powershell
# Scanner le réseau
nmap -sn 192.168.1.0/24
```

### Méthode 3 : Via mDNS (si activé)

Si mDNS est activé, vous pouvez utiliser le nom d'hôte :

```bash
ssh essensys@raspberrypi.local
# ou
ssh essensys@mon.essensys.fr  # Si DNS configuré
```

## Connexion SSH

### Connexion basique

```bash
ssh essensys@<ip-raspberry>
```

Exemple :
```bash
ssh essensys@192.168.1.101
```

### Connexion avec clé SSH (recommandé)

#### Générer une clé SSH (si vous n'en avez pas)

```bash
# Sur votre machine locale
ssh-keygen -t ed25519 -C "essensys-raspberry"
```

#### Copier la clé publique sur le Raspberry Pi

```bash
# Méthode 1 : ssh-copy-id
ssh-copy-id essensys@<ip-raspberry>

# Méthode 2 : Manuellement
cat ~/.ssh/id_ed25519.pub | ssh essensys@<ip-raspberry> "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

#### Connexion sans mot de passe

Une fois la clé copiée, vous pouvez vous connecter sans mot de passe :

```bash
ssh essensys@<ip-raspberry>
```

## Configuration SSH

### Modifier le port SSH (optionnel)

Éditer `/etc/ssh/sshd_config` :

```bash
sudo nano /etc/ssh/sshd_config
```

Changer la ligne :
```
#Port 22
Port 2222  # Nouveau port
```

Redémarrer SSH :
```bash
sudo systemctl restart sshd
```

### Désactiver l'authentification par mot de passe (sécurité)

Une fois les clés SSH configurées :

```bash
sudo nano /etc/ssh/sshd_config
```

Modifier :
```
PasswordAuthentication no
PubkeyAuthentication yes
```

Redémarrer SSH :
```bash
sudo systemctl restart sshd
```

## Dépannage

### Impossible de se connecter

1. **Vérifier que SSH est activé** :
```bash
# Sur le Raspberry Pi
sudo systemctl status ssh
```

2. **Vérifier le pare-feu** :
```bash
# Sur le Raspberry Pi
sudo ufw status
sudo ufw allow 22/tcp  # Si nécessaire
```

3. **Vérifier la connexion réseau** :
```bash
# Depuis votre machine
ping <ip-raspberry>
```

4. **Vérifier les logs SSH** :
```bash
# Sur le Raspberry Pi
sudo tail -f /var/log/auth.log
```

### Erreur "Connection refused"

- Vérifier que SSH est démarré : `sudo systemctl start ssh`
- Vérifier que le port 22 n'est pas bloqué par le pare-feu

### Erreur "Permission denied"

- Vérifier le nom d'utilisateur (par défaut : `essensys` ou `pi`)
- Vérifier le mot de passe
- Vérifier les permissions de `~/.ssh/authorized_keys` (doit être 600)

## Prochaines étapes

Une fois connecté en SSH :

1. [Configuration réseau](configuration-reseau.md) - Configurer le réseau si nécessaire
2. [Installation Essensys](../installation/essensys-installation.md) - Installer Essensys

