# MCP Essensys (Guide opérationnel)

Ce guide décrit l'état actuel du serveur MCP Essensys, les outils disponibles, et comment l'intégrer rapidement dans OpenClaw.

## Vue d'ensemble

- Service systemd: `essensys-mcp`
- Transport: SSE + messages HTTP
- Endpoints:
  - `GET /sse`
  - `POST /messages`
- Port local usuel: `8083`
- Authentification: `Authorization: Bearer <token>`
- Token local: `/etc/essensys/mcp.token`

## Flux de commande

1. L'agent appelle un outil MCP (ex: `send_order`).
2. Le MCP écrit l'action dans Redis (`essensys:global:actions`).
3. Le backend et le client legacy consomment via le flux normal (`/api/myactions`).

Pour les commandes lumières/volets, `send_order` complète automatiquement le bloc legacy (`590` + `605..622`) si nécessaire.

## Outils MCP disponibles actuellement

## `read_exchange_table`

- Lit toute la table d'échange d'un client.
- Usage: inspection rapide des index/valeurs.

## `read_exchange_value`

- Lit une valeur précise par index.
- Usage: vérification ciblée d'un état.

## `set_exchange_value`

- Écrit directement un index dans la table d'échange.
- Attention: bypass de la logique file d'ordres (usage debug uniquement).

## `find_device_index`

- Recherche index/valeur à partir d'un nom d'équipement.
- Support:
  - recherche partielle
  - filtre `category` (`light`, `shutter`, `scenario`, `security`, `heating`, `irrigation`)
  - filtre `action` (`allumer`, `eteindre`, `ouvrir`, `fermer`)
- Retourne aussi l'action opposée quand elle est dérivable (ex: allumer <-> eteindre).

## `send_order`

- Envoie un ordre vers la file globale backend.
- Paramètre principal: `params_json` (liste `[{k,v}]`).
- Normalise automatiquement le payload legacy si index lumière/volet détecté.

## `download_essensys_skill`

- Retourne un JSON prêt à écrire localement:
  - `SKILL.md`
  - `reference.md`
  - `skill-manifest.json`
- Objectif: accélérer l'agent en évitant des échanges longs sur la table de référence.

## Exemples utiles

### Vérifier le service

```bash
sudo systemctl status essensys-mcp --no-pager
sudo journalctl -u essensys-mcp -n 50 --no-pager
```

### Tester l'endpoint SSE

```bash
MCP_TOKEN=$(sudo cat /etc/essensys/mcp.token)
curl -N -H "Authorization: Bearer $MCP_TOKEN" -H "Accept: text/event-stream" http://localhost:8083/sse
```

### Trouver un index de device

Exemple de recherche:
- `device_name="chevet petite chambre 3"`
- `category="light"`
- `action="allumer"` ou `action="eteindre"`

### Envoyer un ordre

Exemple simple:

```json
{
  "guid": "mcp-demo-1",
  "params_json": "[{\"k\":613,\"v\":\"64\"}]"
}
```

Le MCP complètera le bloc legacy si requis.

## Texte prêt à coller dans OpenClaw

Copier-coller ce texte dans la configuration/prompt système OpenClaw:

```text
Tu pilotes Essensys via MCP SSE.

Règles:
1) Toujours appeler find_device_index avant send_order quand la commande vient d'un nom naturel.
2) Pour lumières/volets, préciser action (allumer/eteindre/ouvrir/fermer) car l'index peut changer selon le sens.
3) Utiliser send_order pour l'exécution. Ne pas utiliser set_exchange_value sauf debug explicite.
4) Si ambiguïté de device, demander une clarification courte.
5) Répondre de façon concise: Cause -> Preuve technique (index/valeur) -> Commande exécutée.

MCP tools disponibles:
- read_exchange_table
- read_exchange_value
- set_exchange_value
- find_device_index
- send_order
- download_essensys_skill

Connexion:
- SSE: http://localhost:8083/sse
- Messages: http://localhost:8083/messages
- Header: Authorization: Bearer <token>
```

## Dépannage rapide

- `401/403`: token manquant/invalide.
- `500 /sse`: vérifier logs `essensys-mcp` et compatibilité reverse proxy.
- Ordre non exécuté: vérifier que `send_order` est utilisé (pas `set_exchange_value`) et contrôler Redis + backend.
