# Docker Compose - Configuration cible

## docker-compose.yml

```yaml
version: "3.9"

x-common: &common
  restart: unless-stopped
  logging:
    driver: json-file
    options:
      max-size: "10m"
      max-file: "3"

services:
  # ═══════════════════════════════════════════
  #  Core Services
  # ═══════════════════════════════════════════

  essensys-backend:
    <<: *common
    image: ghcr.io/essensys-hub/backend:${ESSENSYS_VERSION:-V.1.2.2}
    container_name: essensys-backend
    ports:
      - "7070:7070"
    volumes:
      - backend-config:/etc/essensys
      - backend-logs:/var/logs/Essensys
    environment:
      - REDIS_ADDR=redis:6379
    depends_on:
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:7070/health"]
      interval: 30s
      timeout: 5s
      retries: 3
    networks:
      - essensys

  essensys-mcp:
    <<: *common
    image: ghcr.io/essensys-hub/mcp:${ESSENSYS_VERSION:-V.1.2.2}
    container_name: essensys-mcp
    ports:
      - "8083:8083"
    volumes:
      - mcp-config:/etc/essensys
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - MCP_REDIS_ADDR=redis:6379
      - MCP_BACKEND_URL=http://essensys-backend:7070
      - MCP_DOCKER_SOCKET=/var/run/docker.sock
    depends_on:
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8083/health"]
      interval: 30s
      timeout: 5s
      retries: 3
    networks:
      - essensys

  essensys-frontend:
    <<: *common
    image: ghcr.io/essensys-hub/frontend:${ESSENSYS_VERSION:-V.1.2.2}
    container_name: essensys-frontend
    volumes:
      - frontend-dist:/app/dist:ro
    networks:
      - essensys

  # ═══════════════════════════════════════════
  #  Infrastructure Services
  # ═══════════════════════════════════════════

  redis:
    <<: *common
    image: redis:7-alpine
    container_name: redis
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    networks:
      - essensys

  nginx:
    <<: *common
    image: nginx:alpine
    container_name: nginx
    ports:
      - "80:80"
      - "9090:9090"
    volumes:
      - ./config/nginx/essensys.conf:/etc/nginx/conf.d/essensys.conf:ro
      - ./config/nginx/frontend-internal.conf:/etc/nginx/conf.d/frontend-internal.conf:ro
      - frontend-dist:/var/www/essensys:ro
      - nginx-logs:/var/log/nginx
    depends_on:
      - essensys-backend
      - essensys-frontend
    networks:
      essensys:
      # Le réseau host est nécessaire pour que le client legacy
      # puisse atteindre Nginx sur 192.168.x.x:80
      # Alternative: network_mode: host (perd l'isolation)

  traefik:
    <<: *common
    image: traefik:v2.11
    container_name: traefik
    ports:
      - "443:443"
      - "8080:8080"   # Dashboard Traefik (optionnel)
    volumes:
      - ./config/traefik/traefik.yml:/etc/traefik/traefik.yml:ro
      - ./config/traefik/dynamic/:/etc/traefik/dynamic/:ro
      - traefik-acme:/etc/traefik/acme
      - traefik-htpasswd:/etc/traefik/auth
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - essensys

  adguard:
    <<: *common
    image: adguard/adguardhome:latest
    container_name: adguard
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "3000:3000"   # UI AdGuard
    volumes:
      - adguard-work:/opt/adguardhome/work
      - adguard-conf:/opt/adguardhome/conf
    networks:
      - essensys

  mosquitto:
    <<: *common
    image: eclipse-mosquitto:2
    container_name: mosquitto
    ports:
      - "1883:1883"
    volumes:
      - ./config/mosquitto/mosquitto.conf:/mosquitto/config/mosquitto.conf:ro
      - mosquitto-data:/mosquitto/data
      - mosquitto-logs:/mosquitto/log
    networks:
      - essensys

  monitor:
    <<: *common
    image: ghcr.io/essensys-hub/monitor:${ESSENSYS_VERSION:-V.1.2.2}
    container_name: monitor
    ports:
      - "5000:5000"
    environment:
      - MQTT_BROKER=mosquitto
      - MQTT_PORT=1883
    depends_on:
      - mosquitto
    networks:
      - essensys

  # ═══════════════════════════════════════════
  #  IA & Automatisation
  # ═══════════════════════════════════════════

  openclaw:
    <<: *common
    image: ghcr.io/essensys-hub/openclaw:${OPENCLAW_VERSION:-latest}
    container_name: openclaw
    ports:
      - "3100:3100"
    volumes:
      - openclaw-data:/data
    environment:
      - OPENCLAW_MCP_URL=http://essensys-mcp:8083
      - OPENCLAW_MCP_TOKEN_FILE=/data/mcp.token
      - OPENCLAW_N8N_WEBHOOK_URL=http://n8n:5678/webhook
      - OPENCLAW_PROMETHEUS_URL=http://prometheus:9090
    depends_on:
      essensys-mcp:
        condition: service_healthy
    networks:
      - essensys

  n8n:
    <<: *common
    image: n8nio/n8n:latest
    container_name: n8n
    ports:
      - "5678:5678"
    volumes:
      - n8n-data:/home/node/.n8n
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://n8n:5678/
      - N8N_METRICS=true
      - N8N_METRICS_PREFIX=n8n_
      # Connexions MCP et services
      - MCP_URL=http://essensys-mcp:8083
      - OPENCLAW_URL=http://openclaw:3100
      - PROMETHEUS_URL=http://prometheus:9090
    depends_on:
      - essensys-mcp
    networks:
      - essensys

  # ═══════════════════════════════════════════
  #  Observabilité & Gestion
  # ═══════════════════════════════════════════

  prometheus:
    <<: *common
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./config/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./config/prometheus/alert-rules.yml:/etc/prometheus/alert-rules.yml:ro
      - ./config/prometheus/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'
    networks:
      - essensys

  control-plane:
    <<: *common
    image: ghcr.io/essensys-hub/control-plane:${CP_VERSION:-latest}
    container_name: control-plane
    ports:
      - "9100:9100"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - cp-data:/data
    environment:
      - CP_DOCKER_SOCKET=/var/run/docker.sock
      - CP_REGISTRY=ghcr.io/essensys-hub
      - CP_MCP_URL=http://essensys-mcp:8083
      - CP_BACKEND_URL=http://essensys-backend:7070
      - CP_REDIS_ADDR=redis:6379
      - CP_PROMETHEUS_URL=http://prometheus:9090
      - CP_N8N_URL=http://n8n:5678
      - CP_OPENCLAW_URL=http://openclaw:3100
    depends_on:
      - redis
      - prometheus
    networks:
      - essensys

# ═══════════════════════════════════════════
#  Networks
# ═══════════════════════════════════════════

networks:
  essensys:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

# ═══════════════════════════════════════════
#  Volumes
# ═══════════════════════════════════════════

volumes:
  backend-config:
  backend-logs:
  mcp-config:
  frontend-dist:
  redis-data:
  nginx-logs:
  traefik-acme:
  traefik-htpasswd:
  adguard-work:
  adguard-conf:
  mosquitto-data:
  mosquitto-logs:
  openclaw-data:
  n8n-data:
  prometheus-data:
  cp-data:
```

## Fichier .env

```bash
# Version Essensys (utilisée par docker-compose)
ESSENSYS_VERSION=V.1.2.2

# Version Control Plane
CP_VERSION=latest

# Version OpenClaw
OPENCLAW_VERSION=latest

# Domaine WAN
WAN_DOMAIN=essensys.acme.com

# ACME email (Let's Encrypt)
ACME_EMAIL=admin@acme.com
```

## Point d'attention : Client legacy et réseau

Le client Essensys legacy (BP_MQX_ETH) se connecte en TCP directement sur l'IP du Pi, port 80. Le NAT Docker peut poser problème car :

1. Le client attend des **réponses single-packet TCP**
2. Le client utilise des **headers HTTP non-standard**

Deux options pour Nginx :

| Option | Comment | Pour | Contre |
|--------|---------|------|--------|
| **Port mapping** | `ports: "80:80"` (mode bridge) | Isolation réseau | NAT peut fragmenter les réponses |
| **Network host** | `network_mode: host` sur Nginx | Pas de NAT, comportement identique à aujourd'hui | Perd l'isolation Docker pour ce container |

**Recommandation** : commencer en mode bridge, tester avec le client legacy. Si des problèmes apparaissent, passer Nginx en `network_mode: host`.

## Commandes utiles

```bash
# Démarrer toute la stack
docker compose up -d

# Voir les logs d'un service
docker compose logs -f essensys-mcp

# Mettre à jour un service
docker compose pull essensys-backend
docker compose up -d essensys-backend

# Mettre à jour toute la stack
docker compose pull
docker compose up -d

# Rollback un service (changer le tag dans .env)
ESSENSYS_VERSION=V.1.2.1 docker compose up -d essensys-backend

# Voir le statut
docker compose ps

# Accéder au shell d'un container
docker compose exec essensys-mcp sh
```
