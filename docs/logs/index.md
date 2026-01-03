# Logs

Cette section explique comment consulter et analyser les logs des différents composants.

## Sections

1. **[Logs Backend](backend.md)** - Logs du backend Go
2. **[Logs Nginx](nginx.md)** - Logs du serveur web Nginx
3. **[Logs Traefik](traefik.md)** - Logs du reverse proxy Traefik

## Vue d'ensemble des emplacements

| Composant | Fichier de log | Commande |
|-----------|----------------|----------|
| Backend | `/var/logs/Essensys/backend/console.out.log` | `sudo tail -f /var/logs/Essensys/backend/console.out.log` |
| Nginx (accès) | `/var/log/nginx/essensys-access.log` | `sudo tail -f /var/log/nginx/essensys-access.log` |
| Nginx (erreurs) | `/var/log/nginx/essensys-error.log` | `sudo tail -f /var/log/nginx/essensys-error.log` |
| Nginx (API détaillé) | `/var/log/nginx/essensys-api-detailed.log` | `sudo tail -f /var/log/nginx/essensys-api-detailed.log` |
| Traefik | `/var/log/traefik/traefik.log` | `sudo tail -f /var/log/traefik/traefik.log` |
| Traefik (accès) | `/var/log/traefik/access.log` | `sudo tail -f /var/log/traefik/access.log` |

## Scripts utiles

Des scripts sont fournis pour faciliter la consultation des logs :

```bash
# Voir les logs API détaillés
./view-api-logs.sh -f

# Voir les logs Traefik
./traefik-config/view-traefik-logs.sh
```

