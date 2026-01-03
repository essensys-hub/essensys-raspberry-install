# Logs Nginx

Nginx génère plusieurs fichiers de logs pour différents types d'informations.

## Fichiers de logs

### Logs généraux

- **Accès** : `/var/log/nginx/essensys-access.log`
- **Erreurs** : `/var/log/nginx/essensys-error.log`

### Logs API détaillés (diagnostic client legacy)

- **Détaillé** : `/var/log/nginx/essensys-api-detailed.log`
- **Trace** : `/var/log/nginx/essensys-api-trace.log`
- **Erreurs API** : `/var/log/nginx/essensys-api-error.log`

## Consultation des logs

### Logs d'accès généraux

```bash
# Voir en temps réel
sudo tail -f /var/log/nginx/essensys-access.log

# Dernières lignes
sudo tail -n 100 /var/log/nginx/essensys-access.log
```

### Logs d'erreur

```bash
# Voir en temps réel
sudo tail -f /var/log/nginx/essensys-error.log

# Rechercher les erreurs
sudo grep -i "error" /var/log/nginx/essensys-error.log
```

### Logs API détaillés

```bash
# Voir en temps réel
sudo tail -f /var/log/nginx/essensys-api-detailed.log

# Voir les traces
sudo tail -f /var/log/nginx/essensys-api-trace.log
```

## Script de visualisation

Un script est fourni pour faciliter la consultation des logs API :

```bash
# Suivre tous les logs API en temps réel
./view-api-logs.sh -f

# Afficher les 100 dernières requêtes mystatus
./view-api-logs.sh -m -n 100

# Afficher les erreurs
./view-api-logs.sh -e

# Suivre les requêtes serverinfos en temps réel
./view-api-logs.sh -s -f

# Filtrer les requêtes myactions
./view-api-logs.sh -a

# Filtrer les requêtes done
./view-api-logs.sh -d

# Filtrer les requêtes admin/inject
./view-api-logs.sh -i
```

## Format des logs

### Logs d'accès standard

Format : `combined` (par défaut)

```
192.168.1.151 - - [02/Jan/2024:17:19:35 +0000] "GET /api/serverinfos HTTP/1.0" 200 1234 "-" "-"
```

### Logs API détaillés

Format : `essensys_api_detailed`

Inclut :
- Adresse IP source
- Méthode HTTP et URI complète
- Temps de réponse (request_time, upstream_connect_time, upstream_response_time)
- Headers HTTP (Content-Type, Content-Length, Connection)
- Informations upstream (adresse, statut, taille de réponse)

## Analyse des logs

### Compter les requêtes par IP

```bash
sudo awk '{print $1}' /var/log/nginx/essensys-access.log | sort | uniq -c | sort -rn
```

### Compter les requêtes par endpoint

```bash
sudo awk '{print $7}' /var/log/nginx/essensys-access.log | sort | uniq -c | sort -rn
```

### Voir les erreurs 4xx et 5xx

```bash
sudo awk '$9 ~ /^[45]/ {print}' /var/log/nginx/essensys-access.log
```

## Rotation des logs

Les logs Nginx sont automatiquement rotatés par `logrotate`. La configuration se trouve dans `/etc/logrotate.d/nginx`.

Pour forcer une rotation manuelle :

```bash
sudo logrotate -f /etc/logrotate.d/nginx
```

## Dépannage

### Les logs ne sont pas créés

1. Vérifier que Nginx est démarré :
```bash
sudo systemctl status nginx
```

2. Vérifier les permissions :
```bash
ls -la /var/log/nginx/
```

3. Vérifier la configuration Nginx :
```bash
sudo nginx -t
```

### Les logs sont vides

- Vérifier que Nginx reçoit des requêtes
- Vérifier la configuration des logs dans `/etc/nginx/sites-available/essensys`

