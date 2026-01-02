# Compatibilité Client Legacy BP_MQX_ETH avec Traefik

## Problème

Le client Essensys legacy (BP_MQX_ETH) ne respecte pas complètement le protocole HTTP standard. Il nécessite :
- Des réponses en **un seul paquet TCP** (pas de fragmentation)
- Des headers préservés exactement comme le backend les envoie
- Pas de compression (évite la fragmentation)
- Connection: close après chaque requête
- Tolérance aux requêtes HTTP non-standard

## Configuration Traefik

### Avantages de Traefik vs Nginx

Traefik est généralement **plus permissif** que nginx avec les requêtes HTTP non-standard :
- Traefik accepte plus facilement les requêtes malformées
- Moins de validation stricte du protocole HTTP
- Meilleure tolérance aux headers non-standard

### Configuration appliquée

1. **Middlewares pour préserver les headers** :
   - `preserve-headers` : Préserve les headers originaux du backend
   - Connection: close dans les réponses

2. **Services backend** :
   - Pas de compression (Traefik ne compresse pas par défaut pour les API)
   - Timeouts augmentés
   - PassHostHeader pour préserver le Host original

3. **Entrypoints** :
   - Configuration permissive sur le port 80
   - Pas de validation HTTP stricte

## Comparaison avec Nginx

| Aspect | Nginx | Traefik |
|--------|-------|---------|
| Validation HTTP stricte | Oui (peut bloquer) | Non (plus permissif) |
| Compression | Doit être désactivée explicitement | Désactivée par défaut pour API |
| Buffering | Configuré explicitement | Automatique |
| Headers | Doit être préservés explicitement | Préservés par défaut |

## Dépannage

### Si le client legacy ne fonctionne toujours pas

1. **Vérifier les logs Traefik** :
   ```bash
   sudo tail -f /var/log/traefik/traefik.log
   sudo tail -f /var/log/traefik/access.log
   ```

2. **Vérifier que le backend répond correctement** :
   ```bash
   curl -v http://127.0.0.1:8080/api/serverinfos
   ```

3. **Tester avec Traefik** :
   ```bash
   curl -v http://mon.essensys.fr/api/serverinfos
   ```

4. **Comparer avec nginx** :
   Si nginx fonctionne mais pas Traefik, vérifier :
   - Les middlewares sont-ils appliqués ?
   - Les headers sont-ils préservés ?
   - Y a-t-il des erreurs dans les logs Traefik ?

### Fallback vers Nginx

Si Traefik bloque toujours le client legacy, vous pouvez :
1. Utiliser nginx directement (configuration existante dans `nginx-config/`)
2. Ou configurer Traefik pour proxy vers nginx qui lui-même proxy vers le backend

## Notes techniques

- Traefik v2.x bufferise automatiquement les réponses, ce qui est bon pour single-packet TCP
- Traefik ne compresse pas par défaut les réponses API (contrairement à nginx)
- Traefik est plus tolérant avec les requêtes HTTP malformées
- Les middlewares Traefik permettent de personnaliser le comportement

## Configuration recommandée

Pour une compatibilité maximale avec le client legacy :
1. Utiliser les middlewares `preserve-headers` sur toutes les routes API
2. Ne pas activer la compression sur les routes API
3. Configurer des timeouts appropriés
4. Surveiller les logs pour détecter les problèmes

