# Architecture

Vue d'ensemble de l'architecture Essensys sur Raspberry Pi.

## Composants

1. **[Backend](backend.md)** - API Go et communication avec clients legacy
2. **[Frontend](frontend.md)** - Interface web React
3. **[Nginx](nginx.md)** - Reverse proxy pour API locales
4. **[Traefik](traefik.md)** - Reverse proxy pour accès WAN
5. **[Ports](ports.md)** - Ports utilisés par les services

## Architecture globale

```mermaid
graph TB
    Client[Client Essensys<br/>192.168.1.151]
    BrowserLocal[Navigateur Local<br/>mon.essensys.fr]
    BrowserWAN[Navigateur WAN<br/>essensys.acme.com]
    
    Nginx[Nginx<br/>Port 80: API locales<br/>Port 9090: Frontend interne]
    Traefik[Traefik<br/>Port 443: Frontend WAN HTTPS]
    Backend[Backend Go<br/>Port 7070]
    Frontend[Frontend React<br/>Fichiers statiques]
    
    Client -->|mon.essensys.fr/api/*| Nginx
    BrowserLocal -->|mon.essensys.fr/| Nginx
    BrowserWAN -->|essensys.acme.com/| Traefik
    
    Nginx -->|/api/*| Backend
    Nginx -->|/| Frontend
    Traefik -->|Frontend| Nginx
    
    style Client fill:#e1f5ff
    style BrowserLocal fill:#fff4e1
    style BrowserWAN fill:#fff4e1
    style Nginx fill:#e8f5e9
    style Traefik fill:#e3f2fd
    style Backend fill:#f3e5f5
    style Frontend fill:#fff4e1
```

## Flux de données

### Flux local (API)

```mermaid
sequenceDiagram
    participant C as Client Essensys
    participant N as Nginx Port 80
    participant B as Backend Port 7070
    
    C->>N: GET /api/serverinfos
    N->>B: Proxy vers backend
    B->>N: Réponse (single-packet TCP)
    N->>C: Réponse complète
```

### Flux WAN (Frontend)

```mermaid
sequenceDiagram
    participant U as Utilisateur WAN
    participant T as Traefik Port 443
    participant N as Nginx Port 9090
    participant F as Frontend
    
    U->>T: https://essensys.acme.com/
    T->>T: Authentification Basic Auth
    T->>N: Proxy vers Nginx
    N->>F: Servir fichiers statiques
    F->>N: index.html + assets
    N->>T: Réponse
    T->>U: Frontend React (HTTPS)
```
