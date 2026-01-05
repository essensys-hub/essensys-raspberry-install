# Documentation Essensys Raspberry Pi

Bienvenue dans la documentation complète pour l'installation et la configuration d'Essensys sur Raspberry Pi 4.

## 🚀 Démarrage rapide

1. **[Préparation du matériel](installation/preparation.md)** - SSD, adaptateur USB-SATA, Raspberry Pi 4
2. **[Installation de l'OS](installation/os-installation.md)** - Installation de Raspberry Pi OS sur le SSD

### 2.1 Pré-requis système & Clonage
Ouvrez un terminal sur votre Raspberry Pi et lancez cette commande pour installer Git et télécharger les sources :
```bash
sudo curl -sL https://raw.githubusercontent.com/essensys-hub/essensys-raspberry-install/main/requirements.sh | sudo bash
```

### 2.2 Choix du Domaine WAN
Pour accéder à Essensys depuis l'extérieur, vous devez choisir une méthode de nom de domaine :
*   **Option Recommandée (Gratuit)** : **[DuckDNS](acces/duckdns.md)** (Configuration automatique incluse)
*   **Option Avancée** : Domaine personnalisé (OVH, etc.) - voir [Accès WAN](acces/wan.md)

### 3. Installation Essensys
Une fois le dépôt cloné (étape 2.1), suivre le guide détaillé ou lancer directement :
**[Voir le guide complet d'installation](installation/essensys-installation.md)**

```bash
cd essensys-raspberry-install
sudo ./install.sh
```

4. **[Configuration réseau](connexion/configuration-reseau.md)** - Configuration SSH et réseau
5. **[Accès aux services](acces/index.md)** - URLs locales et WAN

## 📚 Sections principales

### Installation
- [Préparation du matériel](installation/preparation.md)
- [Installation de l'OS](installation/os-installation.md)
- [Installation Essensys](installation/essensys-installation.md)

### Connexion
- [Connexion SSH](connexion/ssh.md)
- [Configuration réseau](connexion/configuration-reseau.md)

### Logs
- [Logs backend](logs/backend.md)
- [Logs Nginx](logs/nginx.md)
- [Logs Traefik](logs/traefik.md)

### Accès
- [Accès local](acces/local.md)
- [Accès WAN](acces/wan.md)

### Configuration Routeur
- [Ubiquiti Dream Machine Pro](router/ubiquiti-udm-pro.md)
- [Freebox](router/freebox.md)
- [SFR](router/sfr.md)
- [Orange Livebox](router/orange-livebox.md)

### Architecture
- [Vue d'ensemble](architecture/index.md)
- [Backend](architecture/backend.md)
- [Frontend](architecture/frontend.md)
- [Nginx](architecture/nginx.md)
- [Traefik](architecture/traefik.md)
- [Ports utilisés](architecture/ports.md)

### Maintenance
- [Mise à jour](maintenance/update.md)
- [Désinstallation](maintenance/uninstall.md)
- [Dépannage](maintenance/troubleshooting.md)

## 🏗️ Architecture

```mermaid
graph TB
    Client[Client Essensys<br/>192.168.1.151]
    BrowserLocal[Navigateur Local<br/>mon.essensys.fr]
    BrowserWAN[Navigateur WAN<br/>essensys.acme.com]
    
    AdGuard[AdGuard Home<br/>Port 53: DNS]
    Nginx[Nginx<br/>Port 80: API locales<br/>Port 9090: Frontend interne]
    Traefik[Traefik<br/>Port 443: Frontend WAN HTTPS]
    Backend[Backend Go<br/>Port 7070]
    Frontend[Frontend React<br/>Fichiers statiques]
    
    Client -->|DNS| AdGuard
    BrowserLocal -->|DNS| AdGuard
    AdGuard -->|mon.essensys.fr = 192.168.x.x| Client
    
    Client -->|mon.essensys.fr/api/*| Nginx
    BrowserLocal -->|mon.essensys.fr/| Nginx
    BrowserWAN -->|essensys.acme.com/| Traefik
    
    Nginx -->|/api/*| Backend
    Nginx -->|/| Frontend
    Traefik -->|Frontend| Nginx
    
    style AdGuard fill:#dcedc8
    style Client fill:#e1f5ff
    style BrowserLocal fill:#fff4e1
    style BrowserWAN fill:#fff4e1
    style Nginx fill:#e8f5e9
    style Traefik fill:#e3f2fd
    style Backend fill:#f3e5f5
    style Frontend fill:#fff4e1
```

## 📦 Composants

- **Backend Go** : API REST et communication avec les clients Essensys legacy
- **Frontend React** : Interface web moderne
- **Nginx** : Reverse proxy pour les API locales et le frontend local
- **Traefik** : Reverse proxy avancé pour l'accès WAN avec HTTPS et authentification
- **AdGuard Home** : Serveur DNS local et bloqueur de publicités

## 🔒 Sécurité

- **Local** : Accès HTTP sans authentification
- **WAN** : Accès HTTPS avec authentification basique
- **API WAN** : Seul `/api/admin/inject` est accessible en WAN (HTTPS + auth)
- **Autres API WAN** : Bloquées (403 Forbidden)

## 📝 Notes importantes

- Le client Essensys legacy (BP_MQX_ETH) nécessite des réponses HTTP en un seul paquet TCP
- Nginx est configuré spécifiquement pour cette compatibilité
- Traefik gère uniquement le frontend WAN, les API locales restent sur Nginx


