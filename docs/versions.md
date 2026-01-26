# Versions du Système

Cette page répertorie les versions du système Essensys.

## Versions

| Version | Statut | Date de sortie | Description |
| :--- | :--- | :--- | :--- |
| V.1.2.0 | ** Dev version ** | 25 Janvier 2026 | **Version Actuelle.** Intégration Home Assistant. |
| V.1.1.0 | **Production (Stable) Legacy** | 11 Janvier 2026 | Intégration complète de Redis pour la persistance et la fiabilité. |
| **V.1.0.0** | **Production (Stable) Legacy ** | 11 Janvier 2026 | Ancienne version stable sans Redis. Support limité. |

## Détails de la Version V.1.1.0 (Redis)

La version V.1.1.0 est la nouvelle référence pour la production.

### Nouveautés majeures :
*   **Persistance Redis** : Les états (lumières, volets, etc.) sont sauvegardés même en cas de redémarrage du backend.
*   **Historique des Actions** : La file d'attente globale est gérée par Redis, assurant qu'aucun ordre n'est perdu.
*   **Performance** : Traitement asynchrone amélioré grâce à la structure de données Redis.

> [!NOTE]
> Cette version nécessite `redis-server` installé sur le Raspberry Pi. Les scripts d'installation gèrent cela automatiquement.
