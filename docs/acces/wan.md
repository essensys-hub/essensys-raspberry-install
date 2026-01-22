# Accès WAN

Accès aux services Essensys depuis Internet (WAN) avec HTTPS et authentification.

## Prérequis

1. **[Configuration DuckDNS](duckdns.md)** : Si vous n'avez pas d'IP fixe (recommandé)
2. **Domaine WAN configuré** : Votre domaine doit pointer vers votre IP publique
3. **NAT/Port forwarding** : Ports 80 et 443 redirigés vers le Raspberry Pi
4. **Fichier domain.txt** : Contient le domaine WAN (`/home/essensys/domain.txt`)

## Configuration

### 1. Créer le fichier domain.txt

```bash
echo "essensys.acme.com" > /home/essensys/domain.txt
```

Remplacez `essensys.acme.com` par votre domaine réel.

### 2. Configurer l'authentification

```bash
sudo /etc/traefik/generate-htpasswd.sh
```

Entrer un nom d'utilisateur et un mot de passe.

### 3. Configurer le NAT/Port forwarding

Configurer votre routeur pour rediriger :
- Port 80 → 192.168.1.101:80
- Port 443 → 192.168.1.101:443

Voir [Configuration Routeur](../router/index.md) pour plus de détails.

## URLs WAN

- **Frontend** : `https://essensys.acme.com/` (HTTPS + authentification)
- **API /api/admin/inject** : `https://essensys.acme.com/api/admin/inject` (HTTPS + authentification)
- **Autres API** : BLOQUÉES (403 Forbidden)

## Sécurité WAN

### Règles de sécurité

- **Frontend** : Accessible uniquement en HTTPS avec authentification basique
- **/api/admin/inject** : Accessible uniquement en HTTPS avec authentification basique
- **Autres API** : BLOQUÉES (ni HTTP ni HTTPS)

### Authentification

L'authentification utilise HTTP Basic Auth. Lors de l'accès, le navigateur demandera :
- Nom d'utilisateur
- Mot de passe

## Test de l'accès

### Test frontend

```bash
# Depuis un navigateur
https://essensys.acme.com/

# Via curl (avec authentification)
curl -u username:password https://essensys.acme.com/
```

### Test API

```bash
# /api/admin/inject (avec authentification)
curl -u username:password -X POST https://essensys.acme.com/api/admin/inject \
  -H "Content-Type: application/json" \
  -d '{"k": 1, "v": "test"}'

# Autres API (doivent être bloquées)
curl https://essensys.acme.com/api/serverinfos
# Devrait retourner 403 Forbidden
```

## Certificats SSL

Traefik génère automatiquement les certificats Let's Encrypt pour votre domaine.

Les certificats sont stockés dans `/etc/traefik/acme.json`.

## Dépannage

### Erreur "DNS problem: NXDOMAIN"

Le domaine WAN n'est pas correctement configuré :

1. Vérifier le fichier domain.txt :
```bash
cat /home/essensys/domain.txt
```

2. Vérifier que le domaine pointe vers votre IP publique :
```bash
dig essensys.acme.com
```

### Erreur de certificat SSL

1. Vérifier que le port 443 est ouvert et redirigé
2. Vérifier que le domaine pointe vers votre IP publique
3. Vérifier les logs Traefik :
```bash
sudo tail -f /var/log/traefik/traefik.log
```

#### Forcer le renouvellement
Si le certificat est invalide ou expiré et ne se renouvelle pas :

1. Arrêter Traefik :
```bash
sudo systemctl stop traefik
```

2. Supprimer (ou renommer) le fichier de stockage des certificats :
```bash
sudo mv /etc/traefik/acme.json /etc/traefik/acme.json.bak
```

3. Redémarrer Traefik :
```bash
sudo systemctl start traefik
```

Traefik va automatiquement régénérer le fichier et demander un nouveau certificat à Let's Encrypt. Vérifiez les logs pour confirmer le succès.

#### Erreur 429 (Rate Limit)
Si vous voyez `acme: error: 429 :: POST ... :: too many certificates`, vous avez demandé trop de certificats récemment.
**Solution** :
1. Relancer l'installation avec l'option Staging (pour valider la config sans utiliser le quota PROD) :
   ```bash
   sudo ./install.sh --staging
   ```
2. *Note : Le certificat sera "Non sécurisé" mais cela validera la config.*

### Impossible de se connecter

1. Vérifier le NAT/port forwarding sur le routeur
2. Vérifier que Traefik est démarré :
```bash
sudo systemctl status traefik
```

3. Vérifier que les ports sont ouverts :
```bash
sudo netstat -tlnp | grep -E ':(80|443)'
```




