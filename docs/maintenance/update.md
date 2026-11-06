# Mise à jour

Guide pour mettre à jour Essensys sur le Raspberry Pi.

## Mise à jour automatique

### Script update.sh

Le script `update.sh` automatise la mise à jour complète :

```bash
cd ~/essensys-raspberry-install
sudo ./update.sh
```

Le script va :
1. Mettre à jour les dépôts backend et frontend depuis GitHub
2. Recompiler le backend Go
3. Rebuild le frontend React
4. Mettre à jour la configuration Nginx
5. Mettre à jour la configuration Traefik (lit `/home/essensys/domain.txt`)
6. Redémarrer tous les services
7. Vérifier que tous les services sont actifs

## Mise à jour manuelle

### Backend

```bash
cd /home/essensys/essensys-server-backend
git pull
go mod tidy
go build -o server ./cmd/server
sudo cp server /opt/essensys/backend/
sudo systemctl restart essensys-backend
```

### Frontend

```bash
cd /home/essensys/essensys-server-frontend
git pull
npm install
npm run build
sudo cp -r dist/* /opt/essensys/frontend/dist/
sudo systemctl reload nginx
```

## Vérification après mise à jour

```bash
# Vérifier les services
sudo systemctl status essensys-backend
sudo systemctl status nginx
sudo systemctl status traefik

# Tester l'accès
curl http://mon.essensys.fr/health
```

## Temporisations des lumières (routes ajoutées au backend)

La fonction « Temporisations » des lumières (menu et fiche lumière des applications et portails) ajoute des routes au backend gateway :

- `GET /api/admin/lights/timers` : lit les six délais d'extinction (clés 521, 555, 556, 557, 561, 562) ;
- `PUT /api/admin/lights/timers/{id}` : règle une lumière (`{"minutes": 0 à 255}`), réservé à l'administrateur.

**Rien à changer dans l'installation du Raspberry Pi.** Le script `install.sh` ne fait que le bootstrap : il clone `essensys-ansible` (référence `V.1.3.0`) et lance `install.raspberrypi.yml`, qui récupère et compile le dépôt `essensys-server-backend`. Les routes et la lecture des six clés font partie du binaire du backend : une mise à jour du backend (`update.sh` ou la procédure manuelle ci-dessus, ou le playbook Ansible) suffit. Aucune variable de configuration, aucun service et aucune règle Nginx ou Traefik n'est à ajouter (les routes passent par le préfixe `/api` existant). Redis (file d'ordres) est déjà utilisé par le backend ; aucune base PostgreSQL n'est requise pour ces routes.

Limite de cette vérification : le contenu du rôle Ansible n'est pas dans ce dépôt et n'a pas été relu ici ; l'absence de changement se déduit de ce que ce dépôt ne contient aucun code ni configuration propre au backend. La vérification des routes sur une installation réelle reste à faire au déploiement.
