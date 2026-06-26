# Versions du Système

Cette page répertorie les versions du système Essensys.

## Versions

| Version | Statut | Date de sortie | Description |
| :--- | :--- | :--- | :--- |
| V.1.4.0 | **Gateway CM5 pilote** | Juin 2026 | Gestion scénarios (UI `/scenarios`, API, sync cloud 591–919) |
| V.1.3.1 | **Gateway CM5 pilote** | Juin 2026 | Sync cloud scheduler (profils 3 h, pull/push planifié) — voir `essensys-raspberry-gateway/docs` |
| V.1.2.2 | ** Dev version ** | 30 Janvier 2026 | **Version Actuelle.** Intégration UniFi Protect. |
| V.1.2.1 | ** Dev version ** | 25 Janvier 2026 | Intégration Home Assistant via MQTT. |
| V.1.2.0 | ** Dev version ** | 25 Janvier 2026 | Intégration Home Assistant. |
| V.1.1.0 | **Production (Stable) Legacy** | 11 Janvier 2026 | Intégration complète de Redis pour la persistance et la fiabilité. |
| **V.1.0.0** | **Production (Stable) Legacy ** | 11 Janvier 2026 | Ancienne version stable sans Redis. Support limité. |

## Détails de la Version V.1.4.0 (Scénarios)

- Page **Scénarios** dans le frontend LAN et portail distant
- API ` /api/scenarios/*` (gateway) et `/api/portal/scenarios/*` (OVH)
- Profil sync cloud **Scénarios** (591–919) ; exclusion trigger 590 du push
- Documentation : `essensys-raspberry-gateway/docs/maintenance/scenarios.md`
- **LAN IAM (preview)** : comptes `lan_users`, login UI `/login`, pages `/settings/account` et `/settings/users` — voir [Authentification](installation/authentication.md#mode-lan-iam-openspec-2026-06-017)

## Détails de la Version V.1.2.2 (UniFi Protect)

La version V.1.2.2 ajoute l'intégration UniFi Protect pour l'affichage des caméras.

### Nouveautés majeures :
*   **Intégration UniFi Protect** : Affichage des caméras UniFi (notamment Sonnet) sur le dashboard principal et page dédiée.
*   **Proxy API UniFi** : Le backend fait office de proxy sécurisé vers l'API UniFi Protect.
*   **Snapshots en temps réel** : Rafraîchissement automatique des images des caméras toutes les 10-15 secondes.
*   **Interface utilisateur** : Nouvelle page "UniFi Protect" avec filtres et grille responsive.
*   **Documentation MCP** : Ajout d'un guide opérationnel MCP avec outils actifs, exemples de commandes et texte prêt pour intégration OpenClaw (`docs/maintenance/mcp.md`).
*   **MCP Ops** : Ajout d'outils de diagnostic/réparation (`list_service_status`, `read_service_logs`, `restart_service`, `get_port_diagnostics`, `get_system_metrics`, `run_self_diagnostic`).
*   **CM5 Ansible** : Rôles `raspberry_cm5_uninstall` et `raspberry_cm5_nixos` + playbooks `uninstall.cm5.yml` / `prepare.nixos-cm5.yml` (doc `docs/installation/nixos-cm5.md`).

> [!NOTE]
> Cette version nécessite un UniFi Dream Machine Pro (UDM Pro) accessible via HTTPS. La configuration se fait dans `config.yaml` du backend.

## Détails de la Version V.1.1.0 (Redis)

La version V.1.1.0 est la nouvelle référence pour la production.

### Nouveautés majeures :
*   **Persistance Redis** : Les états (lumières, volets, etc.) sont sauvegardés même en cas de redémarrage du backend.
*   **Historique des Actions** : La file d'attente globale est gérée par Redis, assurant qu'aucun ordre n'est perdu.
*   **Performance** : Traitement asynchrone amélioré grâce à la structure de données Redis.

> [!NOTE]
> Cette version nécessite `redis-server` installé sur le Raspberry Pi. Les scripts d'installation gèrent cela automatiquement.
