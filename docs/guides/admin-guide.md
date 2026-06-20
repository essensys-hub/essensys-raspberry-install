# Guide Administrateur — Gateway Essensys

Ce guide couvre l'exploitation technique de la **Gateway CM5** : accès, services,
supervision, sauvegarde et mises à jour.

!!! info "Public visé"
    Administrateur / installateur. Pour l'usage domotique de l'interface, voir le
    [Guide Utilisateur](user-guide.md).

---

## 1. Architecture en bref

La gateway sépare physiquement deux réseaux sur **deux ports RJ45** :

- **eth0** (LAN, DHCP) — frontend HTTPS utilisateurs, SSH, mises à jour.
- **eth1** (`10.0.1.1/24`, statique, isolé) — armoire Essensys (HTTP legacy + DHCP/DNS).

Détails complets : [Installation Gateway CM5](../installation/gateway-cm5.md).

---

## 2. Accès administrateur

### SSH

```bash
ssh essensys@<ip-eth0>      # ex. ssh essensys@192.168.0.14
```

### Interfaces web d'administration

| Service | URL | Réseau | Usage |
|---------|-----|--------|-------|
| Console AdGuard Home | `http://<ip-eth0>:3000/` | eth0 | DNS, filtrage, clients |
| Dashboard Traefik | `http://<ip-eth0>:8080/` | eth0 | Routeurs, services, TLS |
| Prometheus | `http://<ip-eth0>:9092/` | eth0 | Métriques |
| Alertmanager | `http://<ip-eth0>:9093/` | eth0 | Alertes |

<!-- SCREENSHOT: console AdGuard Home (:3000) -->
![Console AdGuard Home](../img/guide/admin-adguard.png)

<!-- SCREENSHOT: dashboard Traefik (:8080) -->
![Dashboard Traefik](../img/guide/admin-traefik.png)

---

## 3. Services (stack Docker)

Tous les services tournent en conteneurs avec `network_mode: host`, décrits dans
`/opt/data/docker-compose.yml`.

| Conteneur | Image | Rôle |
|-----------|-------|------|
| `essensys-backend` | `essensyshub/essensys-backend` | API Go (:7070) |
| `essensys-nginx` | `essensyshub/essensys-nginx` | Reverse proxy / frontend (:80) |
| `essensys-traefik` | `essensyshub/essensys-traefik` | Frontend HTTPS WAN/LAN (:443) |
| `essensys-mosquitto` | `essensyshub/essensys-mosquitto` | Bus MQTT (:1883) |
| `essensys-redis` | `essensyshub/essensys-redis` | File d'ordres |
| `essensys-adguard` | `adguard/adguardhome` | DNS + filtrage (eth0) |
| `essensys-mcp` | `essensyshub/essensys-backend` | Serveur MCP (:8083) |
| `essensys-control-plane` | `essensyshub/essensys-control-plane` | Supervision (:9100) |
| `essensys-prometheus` | `prom/prometheus` | Métriques (:9092) |
| `essensys-alertmanager` | `prom/alertmanager` | Alertes (:9093/:9094) |
| `essensys-node-exporter` | `prom/node-exporter` | Métriques hôte (:9101) |
| `essensys-openclaw` | `coollabsio/openclaw` | Automatisation |

### Commandes courantes

```bash
# État de la stack
docker ps

# Logs d'un service
docker logs -f essensys-backend

# Redémarrer un service
docker restart essensys-nginx

# Recharger toute la stack
cd /opt/data && docker compose up -d
```

Voir aussi les pages [Logs Backend](../logs/backend.md), [Logs Nginx](../logs/nginx.md),
[Logs Traefik](../logs/traefik.md).

---

## 4. Réseau armoire (eth1)

```bash
# Baux DHCP attribués aux équipements de l'armoire
sudo cat /var/lib/misc/dnsmasq.leases

# Vérifier la résolution split-DNS côté armoire
dig @10.0.1.1 mon.essensys.fr +short      # -> 10.0.1.1

# Journaux DHCP/DNS
journalctl -u dnsmasq -f
```

Configuration : `/etc/dnsmasq.conf` (plage `10.0.1.100-200`, upstream Quad9).

!!! danger "Isolement armoire"
    Ne **jamais** ajouter de route par défaut sur eth1 ni exposer de service
    supplémentaire sur `10.0.1.1` : cela romprait le cloisonnement de sécurité.

---

## 5. Supervision

- **Prometheus** (`:9092`) collecte les métriques (`node-exporter`, control-plane).
- **Alertmanager** (`:9093`) gère les alertes.
- **Control-plane** (`:9100`) expose l'état des services Essensys.

```bash
# Santé rapide
curl -s http://localhost:7070/health
curl -s http://localhost:9100/        # control-plane
```

<!-- SCREENSHOT: Prometheus ou control-plane -->
![Supervision](../img/guide/admin-supervision.png)

---

## 6. Stockage NVMe

Les données à forte écriture résident sur le NVMe (`/mnt/nvme`) pour préserver l'eMMC.

```bash
# Occupation
df -h /mnt/nvme/data /mnt/nvme/logs

# Vérifier le montage persistant
findmnt /mnt/nvme
```

| Chemin NVMe | Contenu |
|-------------|---------|
| `/mnt/nvme/data` | `data_dir`, Redis, TSDB Prometheus |
| `/mnt/nvme/logs` | Journaux applicatifs |

---

## 7. Accès WAN et authentification

L'accès depuis Internet passe par Traefik (HTTPS + authentification). Seul
`/api/admin/inject` est exposé en WAN ; les autres API sont bloquées (403).
Détails : [Accès WAN](../acces/wan.md), [Architecture Traefik](../architecture/traefik.md).

---

## 8. Mises à jour

```bash
# Mise à jour de la stack Essensys
sudo /opt/.../update.sh        # script update.sh du dépôt

# Tirer une version d'image précise (ex. V.1.3.0)
cd /opt/data && docker compose pull && docker compose up -d
```

Voir [Maintenance — Mise à jour](../maintenance/update.md).

---

## 9. Dépannage rapide

| Symptôme | Vérification |
|----------|--------------|
| Frontend HTTPS inaccessible | `docker ps | grep traefik` ; `ss -tlnp | grep :443` |
| Armoire ne joint plus la gateway | `journalctl -u dnsmasq` ; `ip -br addr show eth1` |
| API legacy KO | conf Nginx armoire (`proxy_buffering`, `gzip off`) — [Architecture Nginx](../architecture/nginx.md) |
| NVMe absent | `lsblk` ; firmware PCIe ; `findmnt /mnt/nvme` |
| eth0/eth1 inversés | `Match` par MAC dans `/etc/systemd/network/*.network` |

Voir aussi [Dépannage](../maintenance/troubleshooting.md) et [Interface de Débogage](../maintenance/debug.md).
</content>
