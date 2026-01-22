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
!!!WARNING "L'adresse IP `192.168.1.101` utilisée dans cet exemple est fictive"
    Vous devez impérativement identifier l'adresse IP réelle de votre Raspberry Pi sur votre réseau local pour configurer les redirections de port correctement.

---

## Option 2 : IP Statique sur le Raspberry Pi

Si vous ne pouvez pas configurer votre routeur, vous pouvez configurer l'IP directement sur le Raspberry Pi.

> **Attention** : Assurez-vous de choisir une IP qui n'est **pas** déjà utilisée par un autre appareil et qui est **en dehors** de la plage DHCP de votre routeur (pour éviter les conflits).


!!!WARNING "L'adresse IP `192.168.1.101` utilisée dans cet exemple est fictive"
    Vous devez impérativement identifier l'adresse IP réelle de votre Raspberry Pi sur votre réseau local pour configurer les redirections de port correctement.

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
### Pré-requis : Identifier votre interface et votre réseau

Avant de commencer, identifiez le nom de votre interface réseau (souvent `eth0` ou `end0`) et votre plage d'adresse IP actuelle.

```bash
ip -c addr show
```
*   Noter le nom de l'interface (ex: `eth0`, `end0`...).
*   Noter votre IP actuelle (ex: `192.168.1.45`).

!!!WARNING "IMPORTANT : Choix de l'Adresse IP"
    L'adresse IP fixe que vous choisissez **DOIT correspondre à votre réseau local**.
    
    *   Si votre Box est en `192.168.1.1` (Orange, SFR...), votre IP fixe doit commencer par `192.168.1.xxx`.
    *   Si votre Box est en `192.168.0.254` (Freebox...), votre IP fixe doit commencer par `192.168.0.xxx`.
    
    **Ne copiez pas aveuglément `192.168.1.101` si votre réseau est en `192.168.0.x` !** Vous perdriez la connexion.

### Configuration via nmtui (Recommandé sur Raspberry Pi OS récents)

Sur les versions récentes de Raspberry Pi OS (Bookworm et ultérieur), la configuration se fait via NetworkManager.

1.  Lancez l'outil de configuration réseau :
    ```bash
    sudo nmtui
    ```

2.  Sélectionnez **"Edit a connection"** (Modifier une connexion).
3.  Sélectionnez votre connexion (ex: "Wired connection 1") et validez sur **<Edit...>** (Modifier).
4.  Dans **IPv4 CONFIGURATION**, changez `<Automatic>` en **<Manual>**.
5.  Cliquez sur **<Show>** (Afficher) pour déplier les options.
6.  Remplissez les champs :
    *   **Addresses** : `192.168.1.101/24` (Ajoutez le `/24` à la fin !)
    *   **Gateway** : `192.168.1.1` (IP de votre Box)
    *   **DNS servers** : `1.1.1.1` (ou l'IP de votre Box)
7.  Descendez tout en bas et validez sur **<OK>**.
8.  Faites **<Back>** (Retour) puis **<Quit>** (Quitter).
9.  Appliquez les changements en reconnectant l'interface :
    ```bash
    sudo nmcli connection down "Wired connection 1" && sudo nmcli connection up "Wired connection 1"
    ```

### Configuration 

*À utiliser uniquement si vous êtes sur Raspberry Pi OS Bullseye ou antérieur.*

1.  Éditez le fichier de configuration :
    ```bash
    sudo nano /etc/dhcpcd.conf
    ```

2.  Ajoutez les lignes suivantes à la fin du fichier (remplacez `eth0` par votre interface si différent, ex: `end0`) :

    ```ini
    interface eth0
    static ip_address=192.168.1.101/24
    static routers=192.168.1.1
    static domain_name_servers=1.1.1.1 8.8.8.8
    ```

3.  Sauvegardez (`Ctrl+X`, `Y`, `Entrée`) et redémarrez :
    ```bash
    sudo systemctl restart dhcpcd
    ```

