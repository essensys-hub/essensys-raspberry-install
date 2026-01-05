# Configuration DuckDNS (Dynamic DNS)

Pour accéder à votre serveur Essensys depuis l'extérieur (WAN) sans adresse IP fixe, nous utilisons **DuckDNS**. C'est un service gratuit qui associe un nom de domaine (ex: `ma-maison.duckdns.org`) à l'adresse IP de votre box internet, même si celle-ci change.

## Prérequis

1.  Avoir un compte sur [DuckDNS.org](https://www.duckdns.org) (connexion via Google/GitHub...).
    *   **[> Voir le guide détaillé : Créer son compte et son domaine](duckdns-guide.md)**
2.  Avoir récupéré votre **Token** (affiché en haut de la page une fois connecté).
3.  Avoir choisi un nom de sous-domaine (mais ne pas nécessairement l'avoir créé avec une IP, le script va le mettre à jour).

## Installation Automatisée

Un script interactif a été conçu pour simplifier cette configuration.

Sur votre Raspberry Pi, exécutez :

```bash
cd essensys-raspberry-install
sudo ./setup_duckdns.sh
```

### Étapes du script
1.  Il vous demande votre **Token DuckDNS**.
2.  Il vous demande le **Sous-domaine** désiré (ex: `essensys-demo`).
3.  Il teste immédiatement la connexion avec DuckDNS.
4.  Si le test est réussi :
    *   Il crée une tâche planifiée (Cron) qui met à jour l'IP toutes les 5 minutes.
    *   Il met à jour la configuration d'Essensys (`domain.txt`).
    *   Il redémarre Traefik pour générer les certificats HTTPS.

## Vérification

Une fois le script terminé :
1.  Attendez quelques instants (1-2 minutes).
2.  Accédez à `https://<votre-domaine>.duckdns.org` depuis votre navigateur.
3.  La page de connexion Essensys devrait apparaître (sécurisée par HTTPS).

## Maintenance

### Changer de domaine
Si vous souhaitez changer de domaine ou de compte, relancez simplement le script `sudo ./setup_duckdns.sh`.

### Logs
Le script de mise à jour enregistre sa dernière exécution dans :
`/opt/essensys/duckdns/duck.log`

Vous pouvez vérifier que la mise à jour se fait bien :
```bash
cat /opt/essensys/duckdns/duck.log
```
Vous devriez voir `OK`.
