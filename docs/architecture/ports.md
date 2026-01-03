# Ports utilisés

Tableau récapitulatif des ports utilisés par les services Essensys.

| Service | Port | Protocole | Description |
|---------|------|-----------|-------------|
| Nginx | 80 | TCP | Frontend local + API locales |
| Nginx | 9090 | TCP | Frontend interne (Traefik) |
| Backend Go | 7070 | TCP | API backend |
| Traefik | 443 | TCP | Frontend WAN HTTPS |
| Traefik | 8080 | TCP | Dashboard Traefik |
| Traefik | 8081 | TCP | API interne Traefik |
| Traefik Block Service | 8082 | TCP | Service de blocage (403) |

## Conflits de ports

- Le port 80 est partagé entre Nginx (API locales) et Traefik (frontend local) grâce aux `server_name`
- Le port 443 est exclusivement utilisé par Traefik pour le WAN
- Le port 7070 est exclusivement utilisé par le backend Go
