# Logs Traefik

Traefik génère des logs détaillés pour le diagnostic et le monitoring.

## Fichiers de logs

- **Logs généraux** : `/var/log/traefik/traefik.log`
- **Logs d'accès** : `/var/log/traefik/access.log`

## Consultation des logs

### Logs généraux

```bash
# Voir en temps réel
sudo tail -f /var/log/traefik/traefik.log

# Dernières lignes
sudo tail -n 100 /var/log/traefik/traefik.log
```

### Logs d'accès

```bash
# Voir en temps réel
sudo tail -f /var/log/traefik/access.log

# Dernières lignes
sudo tail -n 100 /var/log/traefik/access.log
```

## Scripts de visualisation

Des scripts sont fournis pour faciliter la consultation :

```bash
# Voir les logs Traefik
./traefik-config/view-traefik-logs.sh

# Voir les logs en mode debug profond
./traefik-config/view-deep-logs.sh

# Capturer le trafic réseau
./traefik-config/capture-network-traffic.sh
```

## Format des logs

### Logs généraux

Format : `common` (lisible) ou `json` (structuré)

Exemple (format common) :
```
2024-01-02T17:19:35Z [INFO] Starting Traefik
2024-01-02T17:19:35Z [DEBUG] Configuration loaded
```

### Logs d'accès

Format : `json` (par défaut)

Inclut :
- Timestamp
- Méthode HTTP
- URL
- Status code
- Durée de la requête
- Headers (si configuré)
- Informations sur le routeur et le service

## Niveaux de log

Traefik supporte plusieurs niveaux de log :

- `ERROR` : Erreurs critiques
- `WARN` : Avertissements
- `INFO` : Informations générales
- `DEBUG` : Informations de débogage
- `TRACE` : Toutes les traces (niveau le plus détaillé)

Le niveau est configuré dans `/etc/traefik/traefik.yml` :

```yaml
log:
  level: TRACE  # Pour voir toutes les connexions
```

## Analyse des logs

### Compter les requêtes par status code

```bash
sudo jq -r '.statusCode' /var/log/traefik/access.log | sort | uniq -c | sort -rn
```

### Voir les requêtes d'une IP spécifique

```bash
sudo jq -r 'select(.clientIP == "192.168.1.151")' /var/log/traefik/access.log
```

### Voir les erreurs

```bash
sudo jq -r 'select(.statusCode >= 400)' /var/log/traefik/access.log
```

## Dépannage

### Les logs ne sont pas créés

1. Vérifier que Traefik est démarré :
```bash
sudo systemctl status traefik
```

2. Vérifier les permissions :
```bash
ls -la /var/log/traefik/
```

3. Vérifier la configuration :
```bash
sudo cat /etc/traefik/traefik.yml | grep -A 5 "log:"
```

### Les logs sont vides

- Vérifier que Traefik reçoit des requêtes
- Vérifier le niveau de log (doit être au moins `INFO`)
- Vérifier que les entrypoints sont correctement configurés

