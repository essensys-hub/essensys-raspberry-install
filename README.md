# Installation Essensys sur Raspberry Pi 4

Ce projet contient les scripts d'installation pour déployer le backend et le frontend Essensys sur un Raspberry Pi 4.

## Architecture

L'installation configure :

- **Backend Go** : Écoute sur le port 8080, gère les API et la communication avec les clients BP_MQX_ETH
- **Frontend React** : Application web compilée et servie par nginx
- **Nginx** : Reverse proxy sur le port 80 qui :
  - Sert le frontend React
  - Proxy les requêtes `/api/*` vers le backend sur le port 8080
  - Permet aux clients BP_MQX_ETH de se connecter au port 80 (compatible avec le firmware)

## Prérequis

- Raspberry Pi 4 avec Raspberry Pi OS (Debian-based)
- Accès root (sudo)
- Connexion Internet pour télécharger les dépendances
- **Accès SSH configuré pour GitHub** : Le script clone les dépôts depuis GitHub en utilisant SSH. Vous devez avoir :
  - Une clé SSH configurée pour l'utilisateur qui exécute le script
  - Les clés SSH copiées dans `/home/essensys/.ssh/` OU configurées globalement pour root
  - Accès aux dépôts privés `essensys-hub/essensys-server-backend` et `essensys-hub/essensys-server-frontend`

## Installation

### Option 1 : Installation automatique (recommandée)

1. Cloner ce dépôt :
```bash
git clone <url-du-repo-essensys-raspberry-install>
cd essensys-raspberry-install
```

2. **Configurer l'accès SSH à GitHub** (important) :
   
   Le script clone automatiquement les dépôts depuis GitHub dans `/home/essensys`. Le script essaiera automatiquement de copier les clés SSH de root vers l'utilisateur essensys si elles existent.
   
   **Option A : Le script copie automatiquement les clés de root (recommandé)**
   
   Si vous avez déjà des clés SSH configurées pour root, le script les copiera automatiquement :
   ```bash
   # Vérifier que vous avez des clés SSH pour root
   sudo ls -la /root/.ssh/
   
   # Si vous n'en avez pas, générer une clé SSH
   sudo ssh-keygen -t ed25519 -C "essensys@raspberrypi"
   
   # Afficher la clé publique et l'ajouter dans GitHub
   sudo cat /root/.ssh/id_ed25519.pub
   # Copiez cette clé dans GitHub : Settings > SSH and GPG keys > New SSH key
   ```
   
   **Option B : Configurer manuellement les clés pour l'utilisateur essensys**
   
   Si vous préférez configurer les clés après la création de l'utilisateur :
   ```bash
   # Générer une clé SSH pour l'utilisateur essensys
   sudo -u essensys ssh-keygen -t ed25519 -C "essensys@raspberrypi"
   
   # Afficher la clé publique
   sudo -u essensys cat /home/essensys/.ssh/id_ed25519.pub
   # Copiez cette clé dans GitHub : Settings > SSH and GPG keys > New SSH key
   ```
   
   **Tester la connexion SSH :**
   ```bash
   sudo -u essensys ssh -T git@github.com
   # Vous devriez voir : "Hi username! You've successfully authenticated..."
   ```

3. Exécuter le script d'installation :
```bash
sudo ./install.sh
```

Le script va :
- Mettre à jour le système
- Créer l'utilisateur `essensys` avec home directory `/home/essensys`
- Cloner les dépôts backend et frontend depuis GitHub dans `/home/essensys`
- Installer Go, Node.js, npm et nginx
- Compiler le backend Go
- Builder le frontend React
- Configurer nginx comme reverse proxy
- Créer les services systemd
- Démarrer les services

### Option 2 : Installation manuelle

Si vous préférez cloner manuellement les dépôts :

1. Créer l'utilisateur et cloner les projets :
```bash
sudo useradd -m -s /bin/bash essensys
sudo -u essensys bash -c "cd /home/essensys && git clone git@github.com:essensys-hub/essensys-server-backend.git"
sudo -u essensys bash -c "cd /home/essensys && git clone git@github.com:essensys-hub/essensys-server-frontend.git"
```

2. Exécuter le script d'installation (il détectera les dépôts existants et les mettra à jour).

## Structure après installation

```
/home/essensys/
├── essensys-server-backend/    # Dépôt cloné depuis GitHub
└── essensys-server-frontend/   # Dépôt cloné depuis GitHub

/opt/essensys/
├── backend/
│   ├── server          # Binaire compilé
│   ├── config.yaml     # Configuration
│   └── ...
├── frontend/
│   ├── dist/           # Frontend compilé
│   └── ...
└── logs/               # Logs de l'application
```

## Configuration

### Backend

Le fichier de configuration se trouve dans `/opt/essensys/backend/config.yaml`.

Pour modifier la configuration :
```bash
sudo nano /opt/essensys/backend/config.yaml
sudo systemctl restart essensys-backend
```

### Nginx

La configuration nginx se trouve dans `/etc/nginx/sites-available/essensys`.

Pour modifier la configuration :
```bash
sudo nano /etc/nginx/sites-available/essensys
sudo nginx -t  # Vérifier la configuration
sudo systemctl reload nginx
```

## Gestion des services

### Démarrer les services
```bash
sudo systemctl start essensys-backend
sudo systemctl start nginx
```

### Arrêter les services
```bash
sudo systemctl stop essensys-backend
sudo systemctl stop nginx
```

### Redémarrer les services
```bash
sudo systemctl restart essensys-backend
sudo systemctl restart nginx
```

### Vérifier le statut
```bash
sudo systemctl status essensys-backend
sudo systemctl status nginx
```

### Activer le démarrage automatique
```bash
sudo systemctl enable essensys-backend
sudo systemctl enable nginx
```

## Logs

### Backend
```bash
# Voir les logs en temps réel
sudo journalctl -u essensys-backend -f

# Voir les dernières lignes
sudo journalctl -u essensys-backend -n 50

# Voir les logs depuis le démarrage
sudo journalctl -u essensys-backend -b
```

### Nginx
```bash
# Logs d'erreur
sudo tail -f /var/log/nginx/essensys-error.log

# Logs d'accès
sudo tail -f /var/log/nginx/essensys-access.log
```

## Tests

### Vérifier que le backend fonctionne
```bash
# Health check direct
curl http://localhost:8080/health

# Health check via nginx
curl http://localhost/health

# Test API
curl http://localhost/api/serverinfos
```

### Vérifier que le frontend fonctionne
```bash
# Ouvrir dans un navigateur
http://<ip-du-raspberry-pi>
```

### Vérifier les ports
```bash
# Vérifier que nginx écoute sur le port 80
sudo netstat -tlnp | grep :80

# Vérifier que le backend écoute sur le port 8080
sudo netstat -tlnp | grep :8080
```

## Configuration réseau

### Problème : L'interface Ethernet (eth0) ne démarre pas

Si vous ne pouvez pas démarrer l'interface Ethernet sur votre Raspberry Pi 4, utilisez les scripts de configuration réseau fournis.

#### Solution rapide : Réactiver l'interface

```bash
sudo ./fix-network.sh
```

Ce script va :
- Arrêter puis réactiver l'interface eth0
- Redémarrer le service dhcpcd
- Vérifier la configuration IP
- Tester la connectivité

#### Configuration complète du réseau

Pour configurer le réseau (DHCP ou IP statique) :

```bash
sudo ./configure-network.sh
```

Le script vous demandera :
- **Mode DHCP** : Configuration automatique via votre routeur
- **IP statique** : Configuration manuelle avec IP, masque, gateway et DNS

**Exemple de configuration IP statique :**
- Adresse IP : `192.168.1.37`
- Masque : `24` (ou `255.255.255.0`)
- Passerelle : `192.168.1.1`
- DNS : `8.8.8.8 8.8.4.4`

#### Commandes manuelles de dépannage réseau

```bash
# Vérifier l'état de l'interface
ip link show eth0

# Activer l'interface
sudo ip link set eth0 up

# Vérifier l'adresse IP
ip addr show eth0

# Redémarrer le service réseau
sudo systemctl restart dhcpcd

# Tester la connectivité
ping -c 3 8.8.8.8

# Vérifier la configuration dans /etc/dhcpcd.conf
cat /etc/dhcpcd.conf
```

#### Configuration SSH sans mot de passe

Une fois que l'interface eth0 fonctionne et que vous avez une IP (ex: 192.168.1.37), vous pouvez vous connecter en SSH :

```bash
# Depuis votre machine locale
ssh essensys@192.168.1.37
```

Si vous avez déjà configuré l'accès SSH sans mot de passe, la connexion devrait fonctionner automatiquement.

## Dépannage

### Le backend ne démarre pas

1. Vérifier les logs :
```bash
sudo journalctl -u essensys-backend -n 100
```

2. Vérifier que le binaire existe et est exécutable :
```bash
ls -la /opt/essensys/backend/server
```

3. Vérifier la configuration :
```bash
cat /opt/essensys/backend/config.yaml
```

### Nginx ne démarre pas

1. Vérifier la configuration :
```bash
sudo nginx -t
```

2. Vérifier les logs :
```bash
sudo tail -f /var/log/nginx/error.log
```

3. Vérifier que le port 80 n'est pas utilisé par un autre service :
```bash
sudo lsof -i :80
```

### Le frontend ne s'affiche pas

1. Vérifier que le build existe :
```bash
ls -la /opt/essensys/frontend/dist
```

2. Vérifier les logs nginx :
```bash
sudo tail -f /var/log/nginx/essensys-error.log
```

3. Vérifier les permissions :
```bash
sudo ls -la /opt/essensys/frontend/dist
```

### Les clients BP_MQX_ETH ne peuvent pas se connecter

1. Vérifier que nginx écoute sur le port 80 :
```bash
sudo netstat -tlnp | grep :80
```

2. Vérifier que le backend fonctionne :
```bash
curl http://localhost:8080/health
```

3. Vérifier que nginx proxy correctement :
```bash
curl http://localhost/api/serverinfos
```

4. Vérifier le firewall (si activé) :
```bash
sudo ufw status
sudo ufw allow 80/tcp
```

## Mise à jour

### Mettre à jour le backend

```bash
# Mettre à jour depuis GitHub
cd /home/essensys/essensys-server-backend
sudo -u essensys git pull

# Recompiler et copier
sudo -u essensys go mod download
sudo -u essensys go build -o server ./cmd/server
cp server /opt/essensys/backend/
cp config.yaml /opt/essensys/backend/ 2>/dev/null || true

# Redémarrer le service
sudo systemctl restart essensys-backend
```

### Mettre à jour le frontend

```bash
# Mettre à jour depuis GitHub
cd /home/essensys/essensys-server-frontend
sudo -u essensys git pull

# Rebuild et copier
sudo -u essensys npm install
sudo -u essensys npm run build
cp -r dist/* /opt/essensys/frontend/dist/

# Recharger nginx
sudo systemctl reload nginx
```

## Désinstallation

Pour désinstaller complètement :

```bash
# Arrêter et désactiver les services
sudo systemctl stop essensys-backend
sudo systemctl disable essensys-backend
sudo systemctl stop nginx
sudo systemctl disable nginx

# Supprimer les fichiers de service
sudo rm /etc/systemd/system/essensys-backend.service
sudo systemctl daemon-reload

# Supprimer la configuration nginx
sudo rm /etc/nginx/sites-available/essensys
sudo rm /etc/nginx/sites-enabled/essensys
sudo systemctl reload nginx

# Supprimer les fichiers d'installation
sudo rm -rf /opt/essensys

# Supprimer l'utilisateur (optionnel)
sudo userdel essensys
```

## Sécurité

### Recommandations

1. **Changer les mots de passe par défaut** dans `config.yaml`
2. **Activer l'authentification** si nécessaire :
```yaml
auth:
  enabled: true
  clients:
    client1: motdepasse_securise
```

3. **Configurer un firewall** :
```bash
sudo ufw enable
sudo ufw allow 80/tcp
sudo ufw allow 22/tcp  # SSH
```

4. **Mettre à jour régulièrement** le système :
```bash
sudo apt update && sudo apt upgrade -y
```

5. **Utiliser HTTPS** en production (nécessite un certificat SSL)

## Support

Pour toute question ou problème, consultez :
- La documentation du backend : `essensys-server-backend/README.md`
- La documentation du frontend : `essensys-server-frontend/README.md`

## Licence

Voir le fichier LICENSE pour plus d'informations.
