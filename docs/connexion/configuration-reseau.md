# Configuration Réseau (IP Fixe)

Pour que le serveur Essensys soit accessible de manière fiable (notamment pour les redirections de ports), il **DOIT avoir une adresse IP fixe** sur votre réseau local.

Il existe deux méthodes pour cela :

1.  **Via le Routeur (Recommandé)** : On dit au routeur de toujours donner la même IP au Raspberry Pi.
2.  **Sur le Raspberry Pi** : On force le Raspberry Pi à utiliser une IP spécifique.

!!!WARNING "L'adresse IP `192.168.1.101` utilisée dans ces exemples est fictive"
    Vous devez choisir une adresse IP adaptée à votre propre réseau local (souvent `192.168.1.x` ou `192.168.0.x`). Vérifiez l'IP de votre box internet pour connaître votre plage réseau.

---

## Option 1 : Réservation DHCP via le Routeur (Recommandé)

C'est la méthode la plus propre. Le Raspberry Pi reste en mode "Automatique" (DHCP), mais votre Box internet le reconnaît et lui attribue toujours la même adresse.

### Étapes générales

1.  Connectez-vous à l'interface d'administration de votre Box / Routeur.
2.  Cherchez la section **DHCP**, **Réseau Local**, ou **Baux Statiques**.
3.  Identifiez votre Raspberry Pi dans la liste des appareils connectés (souvent nommé `raspberrypi` ou par son adresse MAC).
4.  Ajoutez une **Réservation** (ou "Bail statique") :
    *   **Adresse MAC** : Celle du Raspberry Pi e(ex: `b8:27:eb:xx:xx:xx`).
    *   **Adresse IP** : Choisissez l'IP fixe (ex: `192.168.1.101`).
5.  Validez et redémarrez le Raspberry Pi.

Pour connaître l'adresse MAC de votre Raspberry Pi :
```bash
cat /sys/class/net/eth0/address
```

---

## Option 2 : IP Statique sur le Raspberry Pi

Si vous ne pouvez pas configurer votre routeur, vous pouvez configurer l'IP directement sur le Raspberry Pi.

> **Attention** : Assurez-vous de choisir une IP qui n'est **pas** déjà utilisée par un autre appareil et qui est **en dehors** de la plage DHCP de votre routeur (pour éviter les conflits).

### Configuration via dhcpcd.conf

1.  Éditez le fichier de configuration :
    ```bash
    sudo nano /etc/dhcpcd.conf
    ```

2.  Ajoutez les lignes suivantes à la fin du fichier (adaptez les IPs selon votre réseau) :

    ```ini
    # Exemple pour une box en 192.168.1.1 (Orange, SFR...)
    interface eth0
    static ip_address=192.168.1.101/24    # L'IP fixe désirée
    static routers=192.168.1.1            # L'IP de votre Box
    static domain_name_servers=1.1.1.1 8.8.8.8  # DNS (Cloudflare / Google)
    ```

    *Si votre box est en `192.168.0.1` (Freebox par défaut), remplacez les `1.1` et `1.101` par `0.1` et `0.101`.*

3.  Sauvegardez (`Ctrl+X`, puis `Y`, puis `Entrée`).

4.  Appliquez les changements :
    ```bash
    sudo systemctl restart dhcpcd
    ```

### Vérification

Vérifiez que le Raspberry Pi a bien pris la nouvelle IP :
```bash
ip addr show eth0
```

---

## Dépannage rapide

Si vous perdez la connexion après avoir changé l'IP fixe sur le Raspberry Pi :

1.  Connectez un écran et un clavier directement au Raspberry Pi.
2.  Annulez la modification dans `/etc/dhcpcd.conf` (supprimez les lignes ajoutées) pour repasser en mode automatique.
3.  Redémarrez avec `sudo reboot`.
