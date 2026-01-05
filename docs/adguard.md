# AdGuard Home

AdGuard Home est installé sur le Raspberry Pi pour fournir la résolution DNS locale et bloquer les publicités/trackers.

## Configuration

*   **Interface Web** : [http://mon.essensys.fr:3000](http://mon.essensys.fr:3000) (ou via l'IP : `http://<IP>:3000`)
*   **DNS** : Port 53 (UDP/TCP)

## Résolution DNS Locale

Une règle de réécriture DNS est configurée automatiquement lors de l'installation pour que le domaine `mon.essensys.fr` pointe vers l'adresse IP locale du Raspberry Pi.

Cela permet aux appareils du réseau local d'accéder aux services Essensys via le nom de domaine, même sans connexion internet active.

## Utilisation

Pour utiliser ce serveur DNS sur vos appareils (ou votre routeur) afin que `mon.essensys.fr` soit résolu pour tout le monde :
1.  Configurez le DHCP de votre routeur pour distribuer l'IP du Raspberry Pi (`192.168.1.101`) comme serveur DNS primaire.
2.  L'accès à `mon.essensys.fr` résoudra directement sur le Pi.

**Guides de configuration par routeur :**
*   [Ubiquiti UDM Pro](router/ubiquiti-udm-pro.md#configuration-dns-local-avec-adguard-home)
*   [Freebox](router/freebox.md#via-linterface-freebox-dhcp)
*   [SFR Box](router/sfr.md#via-linterface-sfr-dhcp)
*   [Orange Livebox](router/orange-livebox.md#via-linterface-livebox)

## Monitoring

Le service AdGuard Home est surveillé par le moniteur console.
*   **Statut** : Visible sur l'écran d'accueil du moniteur.
*   **Redémarrage** : Touche **A** dans le moniteur.

## Fichiers

*   **Binaire** : `/opt/AdGuardHome/AdGuardHome`
*   **Configuration** : `/opt/AdGuardHome/AdGuardHome.yaml`
*   **Logs** : Gérés par systemd (`journalctl -u AdGuardHome`)
