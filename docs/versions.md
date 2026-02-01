# Versions du Système

Cette page répertorie les versions du système Essensys.

## Versions

| Version | Statut | Date de sortie | Description |
| :--- | :--- | :--- | :--- |
| V.1.2.2 | ** Dev version ** | 30 Janvier 2026 | **Version Actuelle.** Intégration UniFi Protect. |
| V.1.2.1 | ** Dev version ** | 25 Janvier 2026 | Intégration Home Assistant via MQTT. |
| V.1.2.0 | ** Dev version ** | 25 Janvier 2026 | Intégration Home Assistant. |
| V.1.1.0 | **Production (Stable) Legacy** | 11 Janvier 2026 | Intégration complète de Redis pour la persistance et la fiabilité. |
| **V.1.0.0** | **Production (Stable) Legacy ** | 11 Janvier 2026 | Ancienne version stable sans Redis. Support limité. |

## Détails de la Version V.1.2.2 (UniFi Protect)

La version V.1.2.2 ajoute l'intégration UniFi Protect pour l'affichage des caméras.

### Nouveautés majeures :
*   **Intégration UniFi Protect** : Affichage des caméras UniFi (notamment Sonnet) sur le dashboard principal et page dédiée.
*   **Proxy API UniFi** : Le backend fait office de proxy sécurisé vers l'API UniFi Protect.
*   **Snapshots en temps réel** : Rafraîchissement automatique des images des caméras toutes les 10-15 secondes.
*   **Interface utilisateur** : Nouvelle page "UniFi Protect" avec filtres et grille responsive.

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
