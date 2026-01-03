# Accès local

Accès aux services Essensys depuis le réseau local (LAN).

## URLs locales

- **Frontend** : `http://mon.essensys.fr/` ou `http://<ip-raspberry>/`
- **API** : `http://mon.essensys.fr/api/*`
- **Health check** : `http://mon.essensys.fr/health`

## Configuration DNS locale

Pour que `mon.essensys.fr` fonctionne, configurer le DNS sur votre routeur ou utiliser `/etc/hosts`.

### Via /etc/hosts

Sur chaque machine qui doit accéder au Raspberry Pi :

```bash
sudo nano /etc/hosts
```

Ajouter :
```
192.168.1.101 mon.essensys.fr
```

### Via routeur DNS

Configurer le DNS sur votre routeur pour que `mon.essensys.fr` pointe vers l'IP du Raspberry Pi.

Voir [Configuration Routeur](../router/index.md) pour plus de détails.

## Test de l'accès

### Test frontend

```bash
# Depuis un navigateur
http://mon.essensys.fr/

# Ou via curl
curl http://mon.essensys.fr/
```

### Test API

```bash
# Health check
curl http://mon.essensys.fr/health

# API serverinfos
curl http://mon.essensys.fr/api/serverinfos
```

## Sécurité locale

- **Pas d'authentification** : L'accès local est ouvert (pas de mot de passe)
- **HTTP uniquement** : Pas de HTTPS en local
- **Réseau local uniquement** : Les services ne sont pas accessibles depuis Internet

## Dépannage

### Impossible d'accéder au frontend

1. Vérifier que Nginx est démarré :
```bash
sudo systemctl status nginx
```

2. Vérifier que le port 80 est ouvert :
```bash
sudo netstat -tlnp | grep :80
```

3. Vérifier la résolution DNS :
```bash
ping mon.essensys.fr
```

### Les API ne fonctionnent pas

1. Vérifier que le backend est démarré :
```bash
sudo systemctl status essensys-backend
```

2. Tester directement le backend :
```bash
curl http://localhost:7070/health
```

