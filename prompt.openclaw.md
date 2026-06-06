# Prompt de contexte — Intégration OpenClaw dans Essensys

## Objectif du projet

Intégrer **OpenClaw** (assistant IA multi-canal) dans l'infrastructure domotique **Essensys** déployée sur Raspberry Pi via Ansible + Docker Compose. OpenClaw doit :

1. Recevoir les alertes Prometheus/Alertmanager via webhook
2. Les reformuler en langage clair via un LLM (OpenAI)
3. Les envoyer sur **WhatsApp** à l'utilisateur
4. Se connecter au **MCP Essensys** (Model Context Protocol) pour interroger l'état du système
5. Être accessible en UI via Nginx sur `/openclaw/`

---

## Architecture

```
Alertmanager --webhook--> OpenClaw (:18789/hooks/agent) --WhatsApp--> Utilisateur
                              |
                              +---> MCP Essensys (:8083/sse) pour consulter Redis/services
                              |
Nginx (/openclaw/) ---proxy---> OpenClaw UI (:18789)
```

- Tous les conteneurs tournent en `network_mode: host` sur le Raspberry Pi
- L'image Docker : `coollabsio/openclaw:latest`
- LLM : OpenAI (`openai/gpt-4o-mini` par défaut, actuellement configuré `openai/gpt-5.2`)
- Canal de communication : WhatsApp via Baileys (pairing mode)

---

## Dépôt et fichiers concernés

Dépôt : `essensys-hub/essensys-ansible` — branche `V.1.3.0`

### Rôle Ansible `raspberry_openclaw`

| Fichier | Rôle |
|---------|------|
| `roles/raspberry_openclaw/defaults/main.yml` | Variables par défaut (image, port 18789, chemins) |
| `roles/raspberry_openclaw/tasks/main.yml` | Création des répertoires, génération des tokens (gateway + hooks), lecture de la clé OpenAI depuis `~/OpenIA.txt`, déploiement de la config JSON et du `.env` |
| `roles/raspberry_openclaw/templates/openclaw.json.j2` | Configuration OpenClaw (agents, WhatsApp, hooks Alertmanager, MCP) |
| `roles/raspberry_openclaw/templates/env.j2` | Fichier `.env` avec `OPENAI_API_KEY` et `OPENCLAW_GATEWAY_TOKEN` |

### Fichiers modifiés dans d'autres rôles

| Fichier | Modification |
|---------|-------------|
| `roles/raspberry_compose/templates/docker-compose.yml.j2` | Ajout du service `essensys-openclaw` avec `PORT=18789`, `BROWSER_ENABLED=false` |
| `roles/raspberry_compose/tasks/main.yml` | Ajout wait_for sur port 18789 (ignore_errors: true) + message debug |
| `roles/raspberry_prometheus/tasks/main.yml` | Lecture du token hooks OpenClaw avant le rendu d'`alertmanager.yml.j2` (car Prometheus s'exécute avant OpenClaw) |
| `roles/raspberry_prometheus/templates/alertmanager.yml.j2` | Webhook receivers pointant vers `http://127.0.0.1:18789/hooks/agent` avec Bearer token |
| `roles/raspberry_nginx/templates/default.conf.j2` | Ajout `location /openclaw/` proxifiant vers port 18789 avec support WebSocket |
| `roles/raspberry_nginx/defaults/main.yml` | Ajout variable `openclaw_port: 18789` |
| `install.raspberrypi.yml` | Ajout du rôle `raspberry_openclaw` entre `raspberry_prometheus` et `raspberry_compose` |

### Ordre d'exécution des rôles (playbook)

```
raspberry_common → raspberry_docker → raspberry_mosquitto → raspberry_redis →
raspberry_backend → raspberry_mcp → raspberry_frontend → raspberry_nginx →
raspberry_traefik → raspberry_control_plane → raspberry_adguard →
raspberry_prometheus → raspberry_openclaw → raspberry_compose →
raspberry_monitor → raspberry_logrotate → raspberry_push_status
```

---

## Chemins sur le Raspberry Pi

| Chemin | Contenu |
|--------|---------|
| `/opt/data/config/openclaw/.env` | Clé OpenAI + token gateway |
| `/opt/data/config/openclaw/gateway.token` | Token gateway (généré une fois) |
| `/opt/data/config/openclaw/hooks.token` | Token hooks pour auth Alertmanager (généré une fois) |
| `/opt/data/openclaw/.openclaw/openclaw.json` | Configuration principale OpenClaw |
| `/opt/data/openclaw/` | Volume data monté en `/data` dans le conteneur |
| `/home/essensys/OpenIA.txt` | Fichier contenant la clé API OpenAI (lu automatiquement par Ansible si présent) |

---

## Dernier état du déploiement (2026-02-20)

### Le playbook Ansible s'exécute maintenant avec succès

```
PLAY RECAP
localhost : ok=119  changed=12  unreachable=0  failed=0  skipped=10  rescued=0  ignored=1
```

Le `ignored=1` correspond au wait_for d'OpenClaw (ignore_errors: true).

### Problèmes résolus

1. **`openclaw_hooks_token is undefined` dans le rôle Prometheus** — Corrigé en lisant le fichier token directement dans `raspberry_prometheus/tasks/main.yml` avant de rendre `alertmanager.yml.j2` (placeholder `NOT_YET_CONFIGURED` si le fichier n'existe pas encore au premier déploiement).

2. **Timeout wait_for OpenClaw (port 18789)** — Rendu non-bloquant avec `ignore_errors: true` pour ne pas casser le déploiement.

3. **Crash OpenClaw : `host not found in upstream "browser"`** — Le nginx interne d'OpenClaw référençait un conteneur "browser" (navigateur headless) inexistant. Corrigé en ajoutant `BROWSER_ENABLED=false` dans le docker-compose.

4. **Boucle infinie `doctor --fix` sur config `identity`** — L'ancien format `identity` au top-level causait une boucle de migration. Migré vers le nouveau format `agents.list[].identity`.

### Problèmes potentiellement encore présents (à vérifier)

- **Le conteneur OpenClaw ne listen peut-être toujours pas sur le port 18789** — Les logs montraient une boucle de restart due au crash nginx interne. Après les corrections (BROWSER_ENABLED=false, fix identity), il faut vérifier que le conteneur démarre maintenant correctement.

- **L'image `coollabsio/openclaw:latest` existe-t-elle en ARM64 ?** — Le Raspberry Pi est ARM64. Si l'image n'est pas multi-arch, le conteneur ne démarrera pas. Vérifier avec `docker inspect` ou les logs.

- **Variable d'environnement `PORT`** — On a mis `PORT=18789` mais OpenClaw pourrait utiliser une autre variable pour son port d'écoute (ex: `OPENCLAW_PORT`, `HTTP_PORT`, `NGINX_PORT`). À vérifier dans la doc OpenClaw ou les logs du conteneur.

- **WhatsApp non encore pairé** — Le pairing WhatsApp n'a pas encore été fait. Après que le conteneur démarre, il faudra :
  ```bash
  docker exec -it essensys-openclaw openclaw whatsapp pair --phone +33XXXXXXXXX
  ```
  Puis scanner le code ou entrer le code de pairing.

- **Proxy Nginx `/openclaw/`** — Si le port interne d'OpenClaw n'est pas 18789 mais 8080 (port par défaut du nginx interne d'OpenClaw), il faudra ajuster le proxy Nginx.

---

## Commandes de debug utiles (sur le Raspberry Pi)

```bash
# Voir l'état des conteneurs
docker ps -a | grep openclaw

# Logs du conteneur OpenClaw
docker logs essensys-openclaw --tail 100

# Logs en temps réel
docker logs -f essensys-openclaw

# Vérifier si le port écoute
ss -tlnp | grep 18789

# Vérifier la config déployée
cat /opt/data/openclaw/.openclaw/openclaw.json | python3 -m json.tool

# Vérifier le .env
cat /opt/data/config/openclaw/.env

# Vérifier les tokens
cat /opt/data/config/openclaw/hooks.token
cat /opt/data/config/openclaw/gateway.token

# Redémarrer OpenClaw seul
docker compose -f /opt/data/config/compose/docker-compose.yml restart essensys-openclaw

# Tester le webhook manuellement
HOOKS_TOKEN=$(cat /opt/data/config/openclaw/hooks.token)
curl -X POST http://127.0.0.1:18789/hooks/agent \
  -H "Authorization: Bearer $HOOKS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"source":"alertmanager","alerts":[{"labels":{"alertname":"TestAlert","severity":"warning"},"annotations":{"summary":"Test alert from debug"}}]}'

# Vérifier l'architecture de l'image
docker inspect essensys-openclaw | grep Architecture
```

---

## Configuration Docker Compose d'OpenClaw

```yaml
essensys-openclaw:
  image: coollabsio/openclaw:latest
  container_name: essensys-openclaw
  network_mode: host
  restart: unless-stopped
  env_file:
    - /opt/data/config/openclaw/.env
  environment:
    - OPENCLAW_HOME=/data/.openclaw
    - PORT=18789
    - BROWSER_ENABLED=false
  volumes:
    - /opt/data/openclaw:/data
  depends_on:
    - essensys-mcp
```

---

## Configuration OpenClaw (openclaw.json)

```json
{
  "models": { "default": "openai/gpt-4o-mini" },
  "agents": {
    "list": [{
      "id": "main",
      "identity": { "name": "Essensys Assistant" },
      "systemPrompt": "Tu es l'assistant IA du systeme domotique Essensys..."
    }]
  },
  "channels": {
    "whatsapp": { "enabled": true, "dmPolicy": "pairing", "groupPolicy": "disabled" }
  },
  "hooks": {
    "enabled": true,
    "token": "<hooks_token>",
    "path": "/hooks",
    "mappings": {
      "alertmanager": {
        "match": { "source": "alertmanager" },
        "action": "agent",
        "defaults": { "deliver": true, "channel": "whatsapp" }
      }
    }
  },
  "mcpServers": {
    "essensys": {
      "url": "http://127.0.0.1:8083/sse",
      "headers": { "Authorization": "Bearer <mcp_token>" }
    }
  }
}
```

---

## Prochaines étapes

1. **Vérifier que le conteneur OpenClaw démarre** — `docker logs essensys-openclaw`
2. **Vérifier le port d'écoute** — `ss -tlnp | grep 18789` et/ou `grep 8080`
3. **Si le port est 8080 au lieu de 18789**, ajuster `PORT` ou le proxy Nginx
4. **Si l'image n'est pas ARM64**, chercher une image alternative ou builder localement
5. **Pairer WhatsApp** une fois OpenClaw fonctionnel
6. **Tester le webhook Alertmanager** avec la commande curl ci-dessus
7. **Vérifier l'accès UI** via `http://mon.essensys.fr/openclaw/`

---

## Commits Git réalisés (branche V.1.3.0)

| Hash | Message |
|------|---------|
| `e254168` | feat: integrate OpenClaw AI assistant with WhatsApp and Alertmanager |
| `e174245` | fix: resolve openclaw_hooks_token undefined in Prometheus role |
| `42c0620` | fix: make OpenClaw readiness check non-blocking |
| `6b4a11b` | feat: add OpenClaw UI proxy in Nginx on /openclaw/ |
| `92015ef` | fix: resolve OpenClaw startup crash (browser upstream + legacy identity) |
