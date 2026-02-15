# Migration vers Docker - Vue d'ensemble

Ce document décrit l'architecture cible pour industrialiser la solution Essensys sur Raspberry Pi en utilisant **Docker** comme runtime de containers et un **Control Plane** centralisé pour la gestion des versions, des mises à jour et du monitoring.

## Pourquoi migrer ?

| Problème actuel | Solution Docker |
|----------------|----------------|
| Compilation Go/Node **sur le Pi** (lent, fragile) | Images pré-compilées en CI, le Pi ne fait que `docker pull` |
| Versions hard-codées dans `install.sh` et Ansible | Registry d'images tagguées, versions déclaratives dans `docker-compose.yml` |
| Pas de rollback facile | Rollback = changer le tag image et `docker compose up -d` |
| Dépendances système manuelles (Go, Node, Python) | Tout est embarqué dans les images, le Pi n'a besoin que de Docker |
| Pas de visibilité centralisée | Control Plane avec dashboard pour statut, versions, logs |
| MCP couplé au backend | MCP devient un **service autonome** avec son propre cycle de vie |

## Architecture cible

```mermaid
graph TB
    subgraph Internet
        BrowserWAN[Navigateur WAN<br/>essensys.acme.com]
    end

    subgraph Raspberry Pi - Docker Host
        subgraph Essensys Core
            Backend[essensys-backend<br/>:7070 API Go]
            MCP[essensys-mcp<br/>:8083 SSE + JSON-RPC]
            Frontend[essensys-frontend<br/>Fichiers statiques]
            Redis[(redis<br/>:6379)]
        end

        subgraph Réseau & Accès
            Traefik[traefik<br/>:443 HTTPS WAN]
            Nginx[nginx<br/>:80 API locale<br/>:9090 Frontend]
            AdGuard[adguard<br/>:53 DNS]
        end

        subgraph IA & Automatisation
            OpenClaw[OpenClaw<br/>:3100 Agent IA]
            N8N[n8n<br/>:5678 Workflow Automation]
        end

        subgraph Observabilité
            Prometheus[prometheus<br/>:9090 Métriques + Alertes]
            ControlPlane[control-plane<br/>:9100 API + UI]
        end

        subgraph IoT
            Mosquitto[mosquitto<br/>:1883 MQTT]
            Monitor[monitor<br/>:5000 Debug MQTT]
        end
    end

    subgraph LAN
        Client[Client Essensys Legacy<br/>192.168.1.151]
        BrowserLocal[Navigateur Local<br/>mon.essensys.fr]
        AdminUI[Admin<br/>cp.essensys.local]
    end

    Client -->|DNS| AdGuard
    BrowserLocal -->|DNS| AdGuard
    Client -->|/api/*| Nginx
    BrowserLocal -->|/| Nginx
    BrowserWAN -->|HTTPS| Traefik

    Nginx -->|proxy| Backend
    Nginx -->|static| Frontend
    Traefik -->|proxy| Nginx

    MCP -->|ordres| Redis
    Backend -->|file d'ordres| Redis

    OpenClaw -->|SSE + JSON-RPC| MCP
    N8N -->|SSE + JSON-RPC| MCP
    N8N -->|webhooks| OpenClaw

    Prometheus -->|scrape /metrics| Backend
    Prometheus -->|scrape /metrics| MCP
    Prometheus -->|scrape /metrics| ControlPlane
    Prometheus -->|alertmanager| N8N
    Prometheus -->|alertmanager| OpenClaw

    ControlPlane -->|health checks| Backend
    ControlPlane -->|health checks| MCP
    ControlPlane -->|query| Prometheus
    ControlPlane -->|Docker API| Traefik

    Monitor -->|MQTT sub| Mosquitto
    MCP -->|MQTT events| Mosquitto

    AdminUI -->|:9100| ControlPlane

    style MCP fill:#fff3e0,stroke:#e65100,stroke-width:3px
    style ControlPlane fill:#e8eaf6,stroke:#1a237e,stroke-width:3px
    style OpenClaw fill:#fce4ec,stroke:#c62828,stroke-width:3px
    style N8N fill:#e8f5e9,stroke:#2e7d32,stroke-width:3px
    style Prometheus fill:#fff8e1,stroke:#f57f17,stroke-width:3px
    style Redis fill:#ffecb3
    style Backend fill:#f3e5f5
    style Frontend fill:#fff4e1
    style Nginx fill:#e8f5e9
    style Traefik fill:#e3f2fd
    style AdGuard fill:#dcedc8
    style Mosquitto fill:#f1f8e9
    style Monitor fill:#f1f8e9
```

## Services Docker

### Core Essensys

| Service | Image | Port(s) | Rôle |
|---------|-------|---------|------|
| `essensys-backend` | `ghcr.io/essensys-hub/backend` | 7070 | API Go, communication client legacy |
| `essensys-mcp` | `ghcr.io/essensys-hub/mcp` | 8083 | **Service central** MCP (pilotage IA + diagnostic) |
| `essensys-frontend` | `ghcr.io/essensys-hub/frontend` | - | Build React statique (servi par Nginx) |

### IA & Automatisation

| Service | Image | Port(s) | Rôle |
|---------|-------|---------|------|
| `openclaw` | `ghcr.io/essensys-hub/openclaw` | 3100 | **Agent IA** connecté au MCP pour le pilotage intelligent |
| `n8n` | `n8nio/n8n` | 5678 | **Workflow automation** : scénarios user/IA, notifications, chaînes d'actions |

### Observabilité & Gestion

| Service | Image | Port(s) | Rôle |
|---------|-------|---------|------|
| `prometheus` | `prom/prometheus` | 9090 | **Métriques + alertes** : collecte, stockage, alertmanager → N8N + OpenClaw |
| `control-plane` | `ghcr.io/essensys-hub/control-plane` | 9100 | Dashboard, gestion versions, logs, updates |

### Infrastructure

| Service | Image | Port(s) | Rôle |
|---------|-------|---------|------|
| `nginx` | `nginx:alpine` | 80, 9090 | Reverse proxy local (API + Frontend) |
| `traefik` | `traefik:v2.11` | 443 | Reverse proxy WAN + HTTPS + Basic Auth |
| `redis` | `redis:7-alpine` | 6379 | File d'ordres + cache |
| `adguard` | `adguard/adguardhome` | 53, 3000 | DNS local + filtrage |
| `mosquitto` | `eclipse-mosquitto:2` | 1883 | Broker MQTT |
| `monitor` | `ghcr.io/essensys-hub/monitor` | 5000 | Debug MQTT (Flask + SocketIO) |

## Pages détaillées

- **[Control Plane](control-plane.md)** - Architecture du control plane, interface de gestion, API
- **[MCP Standalone](mcp-standalone.md)** - Séparation du MCP en service autonome
- **[N8N, OpenClaw & Prometheus](n8n-openclaw-prometheus.md)** - Automatisation IA, métriques et alertes
- **[Docker Compose](docker-compose.md)** - Configuration Docker Compose cible
- **[CI/CD Pipeline](cicd.md)** - Build des images et déploiement automatique
- **[Plan de migration](migration-plan.md)** - Migration par phases depuis l'architecture actuelle
