# Configuration Traefik pour Essensys

Cette configuration permet de déployer Essensys avec Traefik comme reverse proxy, avec :
- **Accès local** : `mon.essensys.fr` (port 80, sans authentification)
- **Accès WAN** : `essensys.acme.com` (port 443 HTTPS, avec authentification basique)

## Architecture

```
Internet (WAN)
    ↓
Traefik (port 443) → Authentification basique → Frontend (/)
                    → Authentification basique → /api/inject
                    → Blocage (403) → Autres /api/*

Réseau local
    ↓
Traefik (port 80) → Frontend (/) - Sans auth
                 → Toutes les API (/api/*) - Sans auth

Backend:
- Frontend: Nginx sur port 8081 (interne)
- Backend Go: Port 8080
- Block Service: Port 8082 (retourne 403)
```

## Installation

### 1. Installer Traefik

```bash
cd ~/essensys-raspberry-install
sudo ./install-traefik.sh
```

Ce script :
- Installe Traefik
- Configure les routes locales et WAN
- Configure nginx pour servir le frontend sur le port 8081 (interne)
- Installe le service de blocage (port 8082)
- Configure Let's Encrypt pour HTTPS

### 2. Configurer l'authentification

Générer le fichier htpasswd avec les utilisateurs autorisés :

```bash
cd ~/essensys-raspberry-install/traefik-config
sudo ./generate-htpasswd.sh [username]
```

Exemple :
```bash
sudo ./generate-htpasswd.sh admin
# Entrer le mot de passe quand demandé
```

Pour ajouter d'autres utilisateurs, exécutez à nouveau le script.

### 3. Configurer le DNS

Assurez-vous que :
- `mon.essensys.fr` pointe vers l'adresse IP locale du Raspberry Pi
- `essensys.acme.com` pointe vers l'adresse IP publique du Raspberry Pi (accessible depuis Internet)

### 4. Configurer le firewall

Ouvrir les ports nécessaires :
- Port 80 (HTTP, pour Let's Encrypt et accès local)
- Port 443 (HTTPS, pour accès WAN)

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## Configuration

### Routes locales (mon.essensys.fr)

- **Frontend** : `http://mon.essensys.fr/` - Sans authentification
- **API inject** : `http://mon.essensys.fr/api/inject` - Sans authentification
- **Toutes les API** : `http://mon.essensys.fr/api/*` - Sans authentification
- **Health check** : `http://mon.essensys.fr/health` - Sans authentification

### Routes WAN (essensys.acme.com)

- **Frontend** : `https://essensys.acme.com/` - **Avec authentification basique**
- **API inject** : `https://essensys.acme.com/api/inject` - **Avec authentification basique**
- **Autres API** : `https://essensys.acme.com/api/*` - **Bloquées (403 Forbidden)**

### Authentification

L'authentification utilise HTTP Basic Auth. Les identifiants sont stockés dans `/etc/traefik/users.htpasswd`.

Pour ajouter/modifier des utilisateurs :
```bash
sudo ./generate-htpasswd.sh username
```

## Services

### Traefik
```bash
sudo systemctl status traefik
sudo systemctl restart traefik
sudo systemctl stop traefik
```

### Service de blocage (403)
```bash
sudo systemctl status traefik-block-service
sudo systemctl restart traefik-block-service
```

### Nginx (frontend interne)
```bash
sudo systemctl status nginx
sudo systemctl restart nginx
```

## Logs

- **Traefik** : `/var/log/traefik/traefik.log`
- **Traefik access** : `/var/log/traefik/access.log`
- **Traefik errors** : `/var/log/traefik/traefik-error.log`
- **Nginx frontend interne** : `/var/log/nginx/frontend-internal-error.log`

Voir les logs en temps réel :
```bash
sudo tail -f /var/log/traefik/traefik.log
sudo tail -f /var/log/traefik/access.log
```

## Certificats Let's Encrypt

Les certificats SSL/TLS sont générés automatiquement par Let's Encrypt et stockés dans `/etc/traefik/acme.json`.

Pour vérifier les certificats :
```bash
sudo cat /etc/traefik/acme.json
```

Les certificats sont renouvelés automatiquement avant expiration.

## Dépannage

### Traefik ne démarre pas

Vérifier la configuration :
```bash
sudo /usr/local/bin/traefik --configfile=/etc/traefik/traefik.yml --check
```

Vérifier les logs :
```bash
sudo journalctl -u traefik -f
```

### Certificats Let's Encrypt non générés

1. Vérifier que le DNS `essensys.acme.com` pointe vers l'IP publique
2. Vérifier que le port 80 est accessible depuis Internet (pour le challenge HTTP)
3. Vérifier les logs Traefik pour les erreurs Let's Encrypt

### Authentification ne fonctionne pas

1. Vérifier que le fichier htpasswd existe et contient des utilisateurs :
```bash
sudo cat /etc/traefik/users.htpasswd
```

2. Vérifier les permissions :
```bash
sudo ls -la /etc/traefik/users.htpasswd
# Doit être : -rw------- root root
```

### Les API sont bloquées depuis le WAN

C'est normal ! Seules `/api/inject` est accessible depuis le WAN (avec authentification). Toutes les autres API retournent 403 Forbidden.

Pour tester depuis le WAN :
```bash
# Devrait fonctionner (avec auth)
curl -u username:password https://essensys.acme.com/api/inject

# Devrait retourner 403
curl https://essensys.acme.com/api/serverinfos
```

## Mise à jour

Pour mettre à jour la configuration Traefik :

1. Modifier les fichiers dans `traefik-config/`
2. Copier les fichiers mis à jour :
```bash
sudo cp traefik-config/traefik.yml /etc/traefik/
sudo cp traefik-config/dynamic/*.yml /etc/traefik/dynamic/
```
3. Redémarrer Traefik :
```bash
sudo systemctl restart traefik
```

## Désinstallation

Pour désinstaller Traefik :

```bash
sudo systemctl stop traefik
sudo systemctl stop traefik-block-service
sudo systemctl disable traefik
sudo systemctl disable traefik-block-service
sudo rm -rf /etc/traefik
sudo rm -rf /var/log/traefik
sudo rm /usr/local/bin/traefik
sudo rm /etc/systemd/system/traefik.service
sudo rm /etc/systemd/system/traefik-block-service.service
sudo systemctl daemon-reload
```

