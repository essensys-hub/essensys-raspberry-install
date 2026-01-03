# Traefik

Traefik est un reverse proxy avancé qui gère l'accès WAN avec HTTPS et authentification.

## Configuration

- **Fichier principal** : `/etc/traefik/traefik.yml`
- **Routes locales** : `/etc/traefik/dynamic/local-routes.yml`
- **Routes WAN** : `/etc/traefik/dynamic/wan-routes.yml`
- **Port 443** : Frontend WAN HTTPS

## Rôles

1. **Frontend WAN** : HTTPS avec authentification basique
2. **API /api/admin/inject WAN** : HTTPS avec authentification
3. **Blocage autres API WAN** : 403 Forbidden
4. **Certificats Let's Encrypt** : Génération automatique

## Sécurité

- Authentification HTTP Basic Auth
- HTTPS obligatoire pour WAN
- Blocage des API non autorisées
