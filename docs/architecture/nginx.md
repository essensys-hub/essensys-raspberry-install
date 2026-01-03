# Nginx

Nginx sert de reverse proxy pour les API locales et le frontend local.

## Configuration

- **Fichier de configuration** : `/etc/nginx/sites-available/essensys`
- **Port 80** : API locales et frontend local
- **Port 9090** : Frontend interne (utilisé par Traefik)

## Rôles

1. **Proxy API locales** : `/api/*` → Backend port 7070
2. **Servir frontend local** : `/` → Fichiers statiques
3. **Compatibilité client legacy** : Configuration spéciale pour single-packet TCP

## Logs

- Accès : `/var/log/nginx/essensys-access.log`
- Erreurs : `/var/log/nginx/essensys-error.log`
- API détaillé : `/var/log/nginx/essensys-api-detailed.log`
