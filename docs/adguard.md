# AdGuard Home

AdGuard Home est installé sur le Raspberry Pi pour fournir la résolution DNS locale et bloquer les publicités/trackers.

## Configuration

*   **Interface Web** : [http://mon.essensys.fr:3000](http://mon.essensys.fr:3000) (ou via l'IP : `http://<IP>:3000`)
*   **DNS** : Port 53 (UDP/TCP)

## Résolution DNS Locale

Une règle de réécriture DNS est configurée automatiquement lors de l'installation pour que le domaine `mon.essensys.fr` pointe vers l'adresse IP locale du Raspberry Pi.

Cela permet aux appareils du réseau local d'accéder aux services Essensys via le nom de domaine, même sans connexion internet active.

## Utilisation

Pour utiliser ce serveur DNS sur vos appareils (ou votre routeur) :
1.  Configurez le DNS de votre appareil/routeur pour utiliser l'IP du Raspberry Pi.
2.  L'accès à `mon.essensys.fr` résoudra directement sur le Pi.

## Monitoring

Le service AdGuard Home est surveillé par le moniteur console.
*   **Statut** : Visible sur l'écran d'accueil du moniteur.
*   **Redémarrage** : Touche **A** dans le moniteur.

## Fichiers

*   **Binaire** : `/opt/AdGuardHome/AdGuardHome`
*   **Configuration** : `/opt/AdGuardHome/AdGuardHome.yaml`
*   **Logs** : Gérés par systemd (`journalctl -u AdGuardHome`)
