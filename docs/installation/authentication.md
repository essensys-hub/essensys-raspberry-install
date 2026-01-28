# Authentification Essensys

Cette page décrit le système d'authentification de Mon Essensys, introduit dans la version V.1.2.1.

## Vue d'ensemble

L'authentification est gérée au niveau du **reverse-proxy Caddy**, pas dans le code applicatif. Cela offre plusieurs avantages :

- Simple à maintenir et mettre à jour
- Compatible Raspberry Pi (faible consommation de ressources)
- Sécurisé par défaut
- Pas de dépendance à un service externe

## Modes d'authentification

### Mode "Auth partout" (par défaut)

Toutes les connexions (LAN et WAN) nécessitent une authentification.

```bash
sudo essensys-auth auth on
sudo essensys-auth lan-noauth off
```

### Mode "LAN sans auth"

- **WAN** : Authentification TOUJOURS obligatoire
- **LAN** : Accès sans mot de passe pour les appareils du réseau local

```bash
sudo essensys-auth lan-noauth on
```

Les réseaux suivants sont considérés comme "LAN" (RFC1918) :

- `127.0.0.0/8` (loopback)
- `10.0.0.0/8` (Class A privé)
- `172.16.0.0/12` (Class B privé)
- `192.168.0.0/16` (Class C privé)
- `::1` (IPv6 loopback)
- `fd00::/8` (IPv6 privé)

### Mode "Sans auth" (développement uniquement)

⚠️ **ATTENTION** : Ce mode désactive complètement l'authentification.

```bash
sudo essensys-auth auth off
```

## Gestion des utilisateurs

### Commandes essensys-auth

| Commande | Description |
|----------|-------------|
| `sudo essensys-auth add-user <user>` | Ajouter un utilisateur |
| `sudo essensys-auth del-user <user>` | Supprimer un utilisateur |
| `sudo essensys-auth passwd <user>` | Changer le mot de passe |
| `sudo essensys-auth list-users` | Lister les utilisateurs |
| `sudo essensys-auth status` | Afficher le statut actuel |

### Exemple : Ajouter un utilisateur

```bash
$ sudo essensys-auth add-user marie
Mot de passe pour marie: ********
Confirmer le mot de passe: ********
[INFO] Utilisateur 'marie' ajouté
[INFO] Configuration Caddy générée
[INFO] Caddy rechargé
```

### Exemple : Voir le statut

```bash
$ sudo essensys-auth status
╔══════════════════════════════════════════╗
║     Statut Authentification Essensys     ║
╚══════════════════════════════════════════╝

  Auth:          ✓ Activée
  LAN sans auth: ✗ Désactivé (auth partout)
  Realm:         Essensys

  Utilisateurs:  2

  Caddy:         ● Actif

Fichiers:
  Config:   /etc/essensys/auth/config.env
  Htpasswd: /etc/essensys/auth/users.htpasswd
  Caddy:    /etc/caddy/Caddyfile
```

## Fichiers de configuration

| Fichier | Description | Permissions |
|---------|-------------|-------------|
| `/etc/essensys/auth/config.env` | Configuration auth | `root:root 600` |
| `/etc/essensys/auth/users.htpasswd` | Utilisateurs et mots de passe hashés | `root:root 600` |
| `/etc/caddy/Caddyfile` | Configuration reverse-proxy | `root:root 644` |

## Sécurité

### Méthode de hash

Les mots de passe sont hashés avec **bcrypt** via Caddy. Aucun mot de passe en clair n'est stocké.

### Recommandations

1. **Ne jamais exposer directement** le Raspberry Pi sur Internet sans VPN ou reverse-proxy externe
2. **Utiliser des mots de passe forts** (au moins 12 caractères, avec majuscules, chiffres, symboles)
3. **Le mode "LAN sans auth"** signifie que tous les appareils du réseau local peuvent contrôler la maison
4. **Changer le mot de passe par défaut** immédiatement après l'installation

### Tests de sécurité

Pour vérifier que l'authentification fonctionne correctement :

```bash
# Depuis le LAN (devrait retourner 200 si lan-noauth activé, 401 sinon)
curl -I https://192.168.1.x/

# Depuis le WAN (devrait toujours retourner 401 sans identifiants)
curl -I https://mon-domaine.duckdns.org/

# Avec identifiants (devrait retourner 200)
curl -I -u admin:monmotdepasse https://mon-domaine.duckdns.org/
```

## Logs

Les logs d'accès Caddy sont disponibles dans :

```bash
sudo tail -f /var/log/caddy/access.log
```

## Dépannage

### Mot de passe oublié

```bash
sudo essensys-auth passwd admin
```

### Erreur 401 permanente

Vérifiez que l'utilisateur existe :

```bash
sudo essensys-auth list-users
```

### Caddy ne démarre pas

Vérifiez la configuration :

```bash
sudo caddy validate --config /etc/caddy/Caddyfile
sudo journalctl -u caddy -f
```
