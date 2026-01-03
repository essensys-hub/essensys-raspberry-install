# Dépannage

Guide de dépannage pour les problèmes courants.

## Services ne démarrent pas

### Backend

```bash
# Vérifier les logs
sudo journalctl -u essensys-backend -n 50

# Vérifier le binaire
ls -la /opt/essensys/backend/server

# Vérifier la configuration
cat /opt/essensys/backend/config.yaml
```

### Nginx

```bash
# Vérifier la configuration
sudo nginx -t

# Vérifier les logs
sudo tail -f /var/log/nginx/error.log

# Vérifier le port
sudo netstat -tlnp | grep :80
```

### Traefik

```bash
# Vérifier les logs
sudo tail -f /var/log/traefik/traefik.log

# Vérifier la configuration
sudo cat /etc/traefik/traefik.yml

# Vérifier les ports
sudo netstat -tlnp | grep -E ':(80|443)'
```

## Problèmes de connexion

### Client Essensys ne peut pas se connecter

1. Vérifier que Nginx écoute sur le port 80
2. Vérifier que le backend fonctionne
3. Vérifier les logs API détaillés
4. Vérifier le firewall

### Frontend ne s'affiche pas

1. Vérifier que les fichiers existent : `ls -la /opt/essensys/frontend/dist/`
2. Vérifier les logs Nginx
3. Vérifier les permissions

### Accès WAN ne fonctionne pas

1. Vérifier le NAT/port forwarding
2. Vérifier le domaine WAN dans `/home/essensys/domain.txt`
3. Vérifier les certificats SSL
4. Vérifier les logs Traefik

## Problèmes de ports

### Port déjà utilisé

```bash
# Trouver le processus
sudo lsof -i :7070
sudo lsof -i :80
sudo lsof -i :443

# Arrêter le processus
sudo kill <PID>
```

### Conflit entre Nginx et Traefik

Nginx et Traefik peuvent coexister sur le port 80 grâce aux `server_name` différents. Si problème, vérifier la configuration.
