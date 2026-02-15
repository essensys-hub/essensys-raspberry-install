# Architecture

Vue d'ensemble de l'architecture Essensys sur Raspberry Pi.

## Composants

1. **[Backend](backend.md)** - API Go et communication avec clients legacy
2. **[Frontend](frontend.md)** - Interface web React
3. **[Nginx](nginx.md)** - Reverse proxy pour API locales
4. **[Traefik](traefik.md)** - Reverse proxy pour accès WAN
5. **[AdGuard Home](adguard.md)** - Service DNS local et filtrage
6. **[MCP](../maintenance/mcp.md)** - Serveur MCP (Model Context Protocol) pour le pilotage IA
7. **[Ports](ports.md)** - Ports utilisés par les services

## Architecture globale

```mermaid
graph TB
    Client[Client Essensys<br/>192.168.1.151]
    BrowserLocal[Navigateur Local<br/>mon.essensys.fr]
    BrowserWAN[Navigateur WAN<br/>essensys.acme.com]
    Agent[Agent IA<br/>OpenClaw / Cursor / Claude]
    
    AdGuard[AdGuard Home<br/>Port 53: DNS]
    Nginx[Nginx<br/>Port 80: API locales<br/>Port 9090: Frontend interne]
    Traefik[Traefik<br/>Port 443: Frontend WAN HTTPS]
    Backend[Backend Go<br/>Port 7070]
    MCP[Serveur MCP<br/>Port 8083: SSE + HTTP]
    Redis[(Redis<br/>File d'ordres)]
    Frontend[Frontend React<br/>Fichiers statiques]
    
    Client -->|DNS| AdGuard
    BrowserLocal -->|DNS| AdGuard
    AdGuard -->|mon.essensys.fr = 192.168.x.x| Client
    
    Client -->|mon.essensys.fr/api/*| Nginx
    BrowserLocal -->|mon.essensys.fr/| Nginx
    BrowserWAN -->|essensys.acme.com/| Traefik
    
    Agent -->|SSE + JSON-RPC| MCP
    MCP -->|Redis actions| Redis
    Redis -->|File d'ordres| Backend
    
    Nginx -->|/api/*| Backend
    Nginx -->|/| Frontend
    Traefik -->|Frontend| Nginx
    
    style AdGuard fill:#dcedc8
    style Client fill:#e1f5ff
    style BrowserLocal fill:#fff4e1
    style BrowserWAN fill:#fff4e1
    style Agent fill:#fce4ec
    style Nginx fill:#e8f5e9
    style Traefik fill:#e3f2fd
    style Backend fill:#f3e5f5
    style MCP fill:#fff3e0
    style Redis fill:#ffecb3
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

### Flux MCP (Pilotage IA)

```mermaid
sequenceDiagram
    participant A as Agent IA
    participant M as MCP Port 8083
    participant R as Redis
    participant B as Backend Port 7070
    participant C as Client Essensys
    
    A->>M: GET /sse (connexion SSE)
    M-->>A: Stream ouvert
    
    A->>M: POST /messages (find_device_index)
    M->>M: Recherche index device
    M-->>A: Index + valeur trouvés
    
    A->>M: POST /messages (send_order)
    M->>R: Écriture dans essensys:global:actions
    R->>B: Consommation file d'ordres
    B->>C: Exécution commande (lumière/volet/...)
    M-->>A: Confirmation ordre envoyé
```
