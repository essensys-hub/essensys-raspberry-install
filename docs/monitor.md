# Console de Monitoring (HMI)

Le système Essensys inclut désormais une interface de monitoring en console (HMI) développée en Python, permettant de suivre l'état du serveur directement depuis l'écran connecté au Raspberry Pi (ou via SSH).

![Console Monitor](img/console.jpg)

## Fonctionnalités

Cette interface permet de :

*   **Visualiser l'état des services** :
    *   **Backend** (`essensys-backend`)
    *   **Frontend** (`nginx` - port interne 9090)
    *   **Traefik** (`traefik` - port 80/443)
    *   **AdGuard** (`AdGuardHome` - DNS port 53, UI port 3000)
*   **Contrôler les services** : Redémarrage facile des services via des raccourcis clavier.
*   **Monitoring système** :
    *   Utilisation CPU
    *   Utilisation Mémoire
    *   **Utilisation Disque** : Affichage de l'espace utilisé sur la racine (`/`) et `/var/logs`.
    *   **Nombre de clients** : Connexions actives sur les ports 80, 443, 7070.
*   **Réseau** : Affichage des adresses MAC pour `eth0` et `wlan0` (utile pour DHCP).
*   **Logs en temps réel** : Affichage des logs du backend (`/var/logs/Essensys/backend/console.out.log`) via `tail -f`.

## Démarrage automatique

L'installation (`install.sh`) configure automatiquement le Raspberry Pi pour :
1.  Se connecter automatiquement sur `tty1` (écran physique) avec l'utilisateur `essensys`.
2.  Lancer le moniteur au démarrage de la session.

Si vous avez besoin de reconfigurer cela manuellement, vous pouvez utiliser le script :
```bash
sudo ./setup_monitor.sh
```

## Utilisation

| Touche | Action |
| :--- | :--- |
| **B** | Redémarrer le service **Backend** |
| **F** | Redémarrer le service **Frontend** (Nginx) |
| **T** | Redémarrer le service **Traefik** |
| **A** | Redémarrer le service **AdGuard Home** |
| **R** | **Reboot** (Redémarrer le Raspberry Pi) |
| **C** | **Config** (Lancer `raspi-config`) |
| **L** | **Login** (Quitter et se connecter au shell) |
| **Q** | Quitter le moniteur |

## Dépannage

Si le moniteur ne se lance pas :
1.  Vérifiez que vous êtes sur `tty1` (écran physique) ou lancez-le manuellement : `sudo /opt/essensys/monitor.py`
2.  Assurez-vous que l'utilisateur a les droits `sudo` sans mot de passe pour le script (configuré par `setup_monitor.sh`).
