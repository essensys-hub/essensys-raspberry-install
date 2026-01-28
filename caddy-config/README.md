# Configuration Caddy pour Essensys

Ce répertoire contient les templates de configuration Caddy pour l'authentification Essensys.

## Templates disponibles

| Fichier | Description |
|---------|-------------|
| `Caddyfile.auth` | Authentification obligatoire partout (LAN + WAN) |
| `Caddyfile.lan-noauth` | Auth WAN obligatoire, LAN sans auth |
| `Caddyfile.noauth` | Aucune authentification (développement uniquement) |
| `Caddyfile.wan` | Configuration avec domaine public (Let's Encrypt) |

## Variables de template

- `{{HTPASSWD_FILE}}` : Chemin vers le fichier users.htpasswd
- `{{AUTH_REALM}}` : Nom du realm d'authentification

## Plages IP privées (RFC1918)

Les réseaux suivants sont considérés comme "LAN" :
- `127.0.0.0/8` (loopback)
- `10.0.0.0/8` (Class A private)
- `172.16.0.0/12` (Class B private)
- `192.168.0.0/16` (Class C private)
- `::1` (IPv6 loopback)
- `fd00::/8` (IPv6 private)

## Gestion avec essensys-auth

```bash
# Voir le statut
sudo essensys-auth status

# Ajouter un utilisateur
sudo essensys-auth add-user admin

# Activer LAN sans auth
sudo essensys-auth lan-noauth on

# Désactiver l'auth (dev uniquement)
sudo essensys-auth auth off
```

## Sécurité

⚠️ **Recommandations importantes** :

1. **Ne jamais exposer directement** le Raspberry Pi sur Internet
2. **Utiliser un VPN** ou un reverse-proxy externe pour l'accès WAN
3. **LAN sans auth** = tous les appareils du réseau local peuvent contrôler la maison
4. **Mots de passe forts** obligatoires pour les comptes

## Logs

Les logs Caddy sont disponibles dans :
```
/var/log/caddy/access.log
```

Consulter les logs :
```bash
sudo tail -f /var/log/caddy/access.log
```
