# Accès aux services

Cette section explique comment accéder aux services Essensys en local et depuis Internet (WAN).

## Sections

1. **[Accès local](local.md)** - Accéder aux services depuis le réseau local
2. **[Accès WAN](wan.md)** - Accéder aux services depuis Internet

## Vue d'ensemble

```mermaid
graph TB
    Local[Accès Local<br/>mon.essensys.fr]
    WAN[Accès WAN<br/>essensys.acme.com]
    
    Local -->|HTTP| Nginx[Nginx Port 80]
    WAN -->|HTTPS + Auth| Traefik[Traefik Port 443]
    
    Nginx --> Backend[Backend Port 7070]
    Nginx --> Frontend[Frontend]
    Traefik --> Nginx
    
    style Local fill:#e1f5ff
    style WAN fill:#fff4e1
    style Nginx fill:#e8f5e9
    style Traefik fill:#e3f2fd
    style Backend fill:#f3e5f5
    style Frontend fill:#fff4e1
```

