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
