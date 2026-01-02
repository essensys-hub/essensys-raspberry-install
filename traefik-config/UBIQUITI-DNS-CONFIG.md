# Configuration DNS sur Ubiquiti UDM Pro

## Problème avec `/run/dnsmasq.dns.conf.d/main.conf`

Le fichier `/run/dnsmasq.dns.conf.d/main.conf` est dans `/run` qui est un système de fichiers temporaire (tmpfs). Ce fichier est **recréé à chaque redémarrage** et les modifications manuelles sont perdues.

## Solution : Configuration via l'interface Unifi

### Méthode 1 : Interface Web Unifi (Recommandé)

1. **Accéder à l'interface Unifi** :
   - Ouvrez votre navigateur et allez sur l'IP de votre UDM Pro (généralement `https://192.168.1.1` ou l'IP de votre UDM Pro)

2. **Aller dans les paramètres DNS** :
   - **Settings** → **Networks** → Sélectionnez votre réseau (généralement "LAN" ou "Default")
   - Allez dans l'onglet **DHCP** ou **Advanced**

3. **Configurer les DNS Host Overrides** :
   - Cherchez la section **"DHCP Name Server"** ou **"DNS"**
   - Ajoutez les **"DHCP DNS Options"** ou **"Static DNS Entries"** :
     ```
     mon.essensys.fr → 192.168.1.101
     traefik.essensys.fr → 192.168.1.101
     ```

4. **Appliquer les changements** :
   - Cliquez sur **"Apply Changes"** ou **"Save"**

### Méthode 2 : Configuration via SSH (Persistante)

Si vous devez configurer via SSH, utilisez la configuration Unifi qui persiste :

```bash
# Se connecter en SSH à l'UDM Pro
ssh root@192.168.1.1  # ou l'IP de votre UDM Pro

# Éditer la configuration Unifi (cette configuration persiste)
vi /mnt/data/unifi/data/sites/default/config.gateway.json
```

Ajoutez dans la section `dhcp` :

```json
{
  "dhcp": {
    "dnsmasq": {
      "host-record": [
        "mon.essensys.fr,192.168.1.101",
        "traefik.essensys.fr,192.168.1.101"
      ]
    }
  }
}
```

Puis redémarrer le service DNS :
```bash
systemctl restart dnsmasq
# ou
unifi-os restart dnsmasq
```

### Méthode 3 : Configuration via l'API Unifi (Avancé)

Vous pouvez aussi utiliser l'API Unifi pour configurer les DNS, mais c'est plus complexe.

## Vérification

Après configuration, vérifiez que le DNS fonctionne :

```bash
# Depuis une machine du réseau local
nslookup mon.essensys.fr
nslookup traefik.essensys.fr

# Ou avec dig
dig mon.essensys.fr
dig traefik.essensys.fr
```

Les deux devraient retourner `192.168.1.101`.

## Note importante

**Ne modifiez PAS directement `/run/dnsmasq.dns.conf.d/main.conf`** car :
- Les modifications sont perdues au redémarrage
- La configuration Unifi peut écraser vos modifications
- Utilisez toujours l'interface Unifi ou la configuration Unifi officielle

## Alternative : Fichier hosts local

En attendant la configuration DNS, vous pouvez utiliser le fichier hosts sur votre machine :

**Linux/Mac** : `/etc/hosts`
```
192.168.1.101  mon.essensys.fr
192.168.1.101  traefik.essensys.fr
```

**Windows** : `C:\Windows\System32\drivers\etc\hosts`
```
192.168.1.101  mon.essensys.fr
192.168.1.101  traefik.essensys.fr
```

## Redémarrage du service DNS

Si vous avez modifié la configuration, redémarrez le service DNS :

```bash
# Sur l'UDM Pro via SSH
systemctl restart dnsmasq
# ou
unifi-os restart dnsmasq
```

## Dépannage

Si le DNS ne fonctionne toujours pas :

1. **Vérifier que dnsmasq écoute** :
   ```bash
   netstat -tuln | grep 53
   ```

2. **Vérifier les logs dnsmasq** :
   ```bash
   tail -f /var/log/dnsmasq.log
   ```

3. **Vider le cache DNS** :
   - Sur votre machine : `sudo systemd-resolve --flush-caches` (Linux)
   - Ou redémarrer votre navigateur

4. **Tester avec dig directement sur l'UDM Pro** :
   ```bash
   dig @127.0.0.1 mon.essensys.fr
   ```

