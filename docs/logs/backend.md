# Logs Backend

Les logs du backend Go sont écrits dans `/var/logs/Essensys/backend/console.out.log`.

## Consultation des logs

### Voir les logs en temps réel

```bash
sudo tail -f /var/logs/Essensys/backend/console.out.log
```

### Voir les dernières lignes

```bash
# 50 dernières lignes
sudo tail -n 50 /var/logs/Essensys/backend/console.out.log

# 100 dernières lignes
sudo tail -n 100 /var/logs/Essensys/backend/console.out.log
```

### Voir tout le fichier

```bash
sudo cat /var/logs/Essensys/backend/console.out.log
```

### Rechercher dans les logs

```bash
# Rechercher une erreur
sudo grep -i "error" /var/logs/Essensys/backend/console.out.log

# Rechercher une IP
sudo grep "192.168.1.151" /var/logs/Essensys/backend/console.out.log
```

## Logs via journalctl

Les logs sont également disponibles via `journalctl` :

```bash
# Voir les logs en temps réel
sudo journalctl -u essensys-backend -f

# Voir les dernières lignes
sudo journalctl -u essensys-backend -n 50

# Voir les logs depuis une date
sudo journalctl -u essensys-backend --since "2024-01-01"
```

## Vider les logs

Si nécessaire, vous pouvez vider les logs :

```bash
sudo truncate -s 0 /var/logs/Essensys/backend/console.out.log
```

!!! warning "Attention"
    Vider les logs supprime toutes les informations. Assurez-vous d'avoir sauvegardé les logs importants avant de les vider.

## Format des logs

Les logs du backend incluent :
- Timestamp (date et heure)
- Niveau de log (INFO, WARN, ERROR, DEBUG)
- Message de log
- Informations sur les requêtes (IP source, endpoint, etc.)

Exemple :
```
2024/01/02 17:19:30 [INFO] Server started on port 7070
2024/01/02 17:19:35 [INFO] Received request from 192.168.1.151: /api/serverinfos
2024/01/02 17:19:35 [ERROR] Failed to process request: invalid format
```

## Dépannage

### Les logs ne sont pas créés

1. Vérifier que le service est démarré :
```bash
sudo systemctl status essensys-backend
```

2. Vérifier les permissions :
```bash
ls -la /var/logs/Essensys/backend/
```

3. Vérifier que le répertoire existe :
```bash
sudo mkdir -p /var/logs/Essensys/backend
sudo chown essensys:essensys /var/logs/Essensys/backend
```

### Les logs sont vides

- Vérifier que le backend reçoit des requêtes
- Vérifier la configuration du backend dans `/opt/essensys/backend/config.yaml`

