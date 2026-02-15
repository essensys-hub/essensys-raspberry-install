# Backend

Le backend Essensys est écrit en Go et gère les API REST et la communication avec les clients Essensys legacy.

## Caractéristiques

- **Langage** : Go
- **Port** : 7070
- **Emplacement** : `/opt/essensys/backend/`
- **Configuration** : `/opt/essensys/backend/config.yaml`
- **Dépendance file d'ordres** : Redis (`essensys:global:actions`)

## MCP (Model Context Protocol)

Le serveur MCP Essensys est embarqué côté backend et expose :

- `GET /sse` (stream)
- `POST /messages` (JSON-RPC)

Il permet deux familles d'usage :

- **Pilotage** : recherche d'index, lecture/écriture table d'échange, envoi d'ordres.
- **Ops/diagnostic** : statut services, logs système, ports, métriques et auto-diagnostic.

### Outils MCP de pilotage

- `read_exchange_table`
- `read_exchange_value`
- `set_exchange_value` (debug uniquement)
- `find_device_index`
- `send_order`

### Outils MCP de diagnostic et réparation

- `list_service_status`
- `read_service_logs`
- `restart_service`
- `get_port_diagnostics`
- `get_system_metrics`
- `run_self_diagnostic` (option `auto_repair=true`)

> [!NOTE]
> `send_order` complète automatiquement le bloc legacy (`590` + `605..622`) si une commande lumières/volets est détectée.

## API Endpoints

- `GET /health` - Health check
- `GET /api/serverinfos` - Informations serveur
- `GET /api/mystatus` - Statut actuel
- `POST /api/myactions` - Actions utilisateur
- `POST /api/done` - Confirmation
- `POST /api/admin/inject` - Injection de commandes

## Compatibilité client legacy

Le backend est conçu pour être compatible avec le client Essensys legacy (BP_MQX_ETH) qui :
- Ne respecte pas complètement le standard HTTP
- Nécessite des réponses en un seul paquet TCP
- Utilise des headers HTTP non-standard

## Logs

Les logs sont disponibles dans `/var/logs/Essensys/backend/console.out.log`.
