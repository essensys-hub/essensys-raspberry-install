# Noms personnalisés des lumières

Les administrateurs peuvent renommer une lumière dans les applications. Sur le Raspberry Pi 4 (sans PostgreSQL), la gateway conserve ces noms dans un fichier JSON local, `light-names.json`.

## Où est le fichier

| Installation | Fichier | Configuration |
|---|---|---|
| Docker Compose (installation par `install.sh` / Ansible) | hôte : `/opt/data/light-names/light-names.json`, dans le conteneur : `/var/lib/essensys/names/light-names.json` | bloc `light_names.path` géré par Ansible dans `config.yaml` |
| Service systemd (mise à jour par `update.sh`) | `/opt/essensys/names/light-names.json` | clé `light_names.path` posée par `scripts/setup-light-names.sh` |

Le répertoire appartient à l'utilisateur du service (`essensys`), mode `0750`. Dans le conteneur, c'est le seul montage en écriture du backend : `config.yaml` reste en lecture seule.

```yaml
light_names:
  path: "/var/lib/essensys/names/light-names.json"
```

`update.sh` appelle `scripts/setup-light-names.sh`, qui est idempotent : il crée le répertoire, règle les droits et ajoute la clé seulement si elle est absente. Test : `scripts/test-setup-light-names.sh`.

!!! warning "Docker Compose : recréer le conteneur"
    Un nouveau montage n'est pris en compte qu'à la **recréation** du conteneur. Un simple `docker restart essensys-backend` ne suffit pas. Au premier déploiement après cette fonctionnalité :

    ```bash
    docker compose -f /opt/data/docker-compose.yml up -d --force-recreate essensys-backend
    ```

    Le playbook `install.gateway.yml` le fait déjà.

## Sauvegarde

Le fichier est sauvegardé avec `/opt/data` (installation Docker Compose) ou `/opt/essensys` (installation systemd). Pour une copie manuelle :

```bash
sudo cp -a /opt/data/light-names/light-names.json ~/light-names.$(date +%F).json
```

Pour restaurer, remettre le fichier au même endroit avec le propriétaire `essensys` puis recréer le conteneur. Le fichier contient un numéro de version par lumière : une restauration ancienne est ensuite réconciliée avec le cloud.

## Dépannage : 503 `names_unavailable`

Les routes de noms de la gateway répondent `503` avec l'erreur `names_unavailable` quand le fichier ne peut pas être lu ou écrit. Les applications reviennent alors aux noms d'origine, sans bloquer le pilotage des lumières.

1. La clé `light_names.path` est-elle présente dans `config.yaml` ?
2. Le répertoire existe-t-il, avec l'utilisateur `essensys` et le mode `0750` ?
3. Docker Compose : le conteneur a-t-il été recréé (et non redémarré) ? Vérifier le montage : `docker inspect essensys-backend --format '{{ range .Mounts }}{{ .Source }} -> {{ .Destination }} {{ .RW }}{{ "\n" }}{{ end }}'` doit montrer `/opt/data/light-names -> /var/lib/essensys/names true`.
4. Le disque est-il plein ou le fichier corrompu ? Le sauvegarder, puis le déplacer : il est recréé vide au premier renommage.
