# Configuration NAT / Port Forwarding pour Essensys

## Ports à ouvrir

Pour que Traefik fonctionne correctement avec l'accès WAN, vous devez configurer le NAT (port forwarding) sur votre routeur pour rediriger les ports suivants vers le Raspberry Pi :

### Ports requis

| Port | Protocole | Destination | Usage |
|------|-----------|-------------|-------|
| **80** | TCP | 192.168.1.101 | HTTP (accès local + challenge Let's Encrypt) |
| **443** | TCP | 192.168.1.101 | HTTPS (accès WAN sécurisé) |

## Configuration sur le routeur

### Étape 1 : Accéder à l'interface du routeur

1. Connectez-vous à l'interface d'administration de votre routeur
   - Adresse généralement : `http://192.168.1.1` ou `http://192.168.0.1`
   - Identifiants : consultez la documentation de votre routeur

### Étape 2 : Configurer le Port Forwarding / NAT

Cherchez la section :
- **"Port Forwarding"**
- **"NAT"**
- **"Virtual Server"**
- **"Port Mapping"**
- **"Règles de redirection de port"**

### Étape 3 : Ajouter les règles

#### Règle 1 : Port 80 (HTTP)

```
Nom de la règle : Essensys HTTP
Port externe : 80
Port interne : 80
Protocole : TCP
Adresse IP interne : 192.168.1.101
Activer : Oui
```

#### Règle 2 : Port 443 (HTTPS)

```
Nom de la règle : Essensys HTTPS
Port externe : 443
Port interne : 443
Protocole : TCP
Adresse IP interne : 192.168.1.101
Activer : Oui
```

### Étape 4 : Sauvegarder et redémarrer

1. Sauvegardez la configuration
2. Redémarrez le routeur si nécessaire

## Vérification

### Vérifier que les ports sont ouverts

Depuis un ordinateur externe (ou en utilisant un service en ligne) :

```bash
# Vérifier le port 80
telnet votre-ip-publique 80

# Vérifier le port 443
telnet votre-ip-publique 443
```

Ou utilisez un service en ligne :
- https://www.yougetsignal.com/tools/open-ports/
- https://canyouseeme.org/

### Vérifier depuis le Raspberry Pi

```bash
# Vérifier que Traefik écoute sur les ports
sudo netstat -tlnp | grep -E ':(80|443)'

# Ou avec ss
sudo ss -tlnp | grep -E ':(80|443)'
```

Vous devriez voir :
```
tcp  0  0 0.0.0.0:80   0.0.0.0:*  LISTEN  traefik
tcp  0  0 0.0.0.0:443  0.0.0.0:*  LISTEN  traefik
```

## Configuration du firewall sur le Raspberry Pi

Assurez-vous que le firewall autorise les connexions entrantes :

```bash
# Si vous utilisez ufw
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload

# Vérifier le statut
sudo ufw status
```

## Configuration DNS

### Pour l'accès local (mon.essensys.fr)

1. **Option 1 : Fichier hosts** (sur chaque machine locale)
   ```
   192.168.1.101  mon.essensys.fr
   ```

2. **Option 2 : DNS local** (recommandé)
   - Configurer votre routeur/DNS local pour résoudre `mon.essensys.fr` vers `192.168.1.101`

### Pour l'accès WAN (essensys.rhinosys.io)

1. **Chez votre fournisseur DNS (OVH)** :
   - Créer un enregistrement A :
     ```
     essensys.rhinosys.io  →  VOTRE_IP_PUBLIQUE
     ```

2. **Vérifier la propagation DNS** :
   ```bash
   dig essensys.rhinosys.io
   nslookup essensys.rhinosys.io
   ```

## Schéma de connexion

```
Internet
    ↓
Routeur (IP publique)
    ↓ (NAT: port 80, 443)
Raspberry Pi (192.168.1.101)
    ↓
Traefik (ports 80, 443)
    ↓
- Frontend (nginx port 8081)
- Backend (Go port 8080)
- Block Service (Python port 8082)
```

## Dépannage

### Les ports ne sont pas accessibles depuis l'extérieur

1. **Vérifier le NAT** :
   - Les règles de port forwarding sont-elles correctement configurées ?
   - L'IP du Raspberry Pi est-elle toujours 192.168.1.101 ? (vérifier avec `ip addr`)

2. **Vérifier le firewall du routeur** :
   - Certains routeurs ont un firewall qui bloque les connexions entrantes
   - Vérifier les règles de firewall dans l'interface du routeur

3. **Vérifier le firewall du Raspberry Pi** :
   ```bash
   sudo ufw status verbose
   ```

4. **Vérifier que Traefik écoute** :
   ```bash
   sudo systemctl status traefik
   sudo netstat -tlnp | grep traefik
   ```

### Let's Encrypt ne peut pas valider le domaine

1. **Vérifier que le port 80 est accessible** :
   - Let's Encrypt utilise le port 80 pour le challenge HTTP
   - Le port 80 doit être accessible depuis Internet

2. **Vérifier le DNS** :
   ```bash
   dig essensys.rhinosys.io
   # Doit retourner votre IP publique
   ```

3. **Vérifier les logs Traefik** :
   ```bash
   sudo tail -f /var/log/traefik/traefik.log | grep -i acme
   ```

## Sécurité

### Recommandations

1. **Ne pas exposer d'autres ports** :
   - Seuls les ports 80 et 443 doivent être ouverts
   - Fermer tous les autres ports inutiles

2. **Utiliser un firewall** :
   - Activer le firewall sur le Raspberry Pi
   - Configurer des règles restrictives

3. **Mettre à jour régulièrement** :
   - Mettre à jour le système et les services
   - Surveiller les logs pour les tentatives d'intrusion

4. **Authentification forte** :
   - Utiliser des mots de passe forts pour l'authentification basique
   - Changer régulièrement les mots de passe

## Exemple de configuration selon le routeur

### Routeur TP-Link

1. Accéder à : `http://192.168.1.1`
2. Aller dans : **Advanced** → **NAT Forwarding** → **Virtual Servers**
3. Ajouter :
   - Service Name: `Essensys HTTP`, External Port: `80`, Internal Port: `80`, Internal IP: `192.168.1.101`, Protocol: `TCP`
   - Service Name: `Essensys HTTPS`, External Port: `443`, Internal Port: `443`, Internal IP: `192.168.1.101`, Protocol: `TCP`

### Routeur Netgear

1. Accéder à : `http://192.168.1.1` ou `http://routerlogin.net`
2. Aller dans : **Advanced** → **Port Forwarding / Port Triggering**
3. Ajouter les règles similaires

### Routeur Asus

1. Accéder à : `http://192.168.1.1`
2. Aller dans : **Advanced Settings** → **WAN** → **Virtual Server / Port Forwarding**
3. Ajouter les règles

### Routeur Linksys

1. Accéder à : `http://192.168.1.1`
2. Aller dans : **Connectivity** → **Router Settings** → **Port Forwarding**
3. Ajouter les règles

## Notes importantes

- **IP fixe recommandée** : Configurez une IP fixe (192.168.1.101) pour le Raspberry Pi dans les paramètres DHCP du routeur, ou configurez une réservation DHCP
- **IP publique dynamique** : Si votre IP publique change, vous devrez mettre à jour l'enregistrement DNS A chez OVH
- **Double NAT** : Si vous êtes derrière un double NAT (box + routeur), configurez le port forwarding sur les deux équipements

