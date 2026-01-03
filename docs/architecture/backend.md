# Backend

Le backend Essensys est écrit en Go et gère les API REST et la communication avec les clients Essensys legacy.

## Caractéristiques

- **Langage** : Go
- **Port** : 7070
- **Emplacement** : `/opt/essensys/backend/`
- **Configuration** : `/opt/essensys/backend/config.yaml`

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
