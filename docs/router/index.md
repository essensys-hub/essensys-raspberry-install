# Configuration Routeur

Cette section explique comment configurer le NAT/port forwarding sur différents routeurs pour permettre l'accès WAN.

## Schéma de connexion réseau général

```mermaid
graph TB
    Internet[Internet]
    Router[Routeur / Box]
    Switch[Switch / Hub]
    
    Port2[Port 2]
    Port3[Port 3]
    
    RPi[Raspberry Pi 4<br/>192.168.1.101<br/>mon.essensys.fr]
    Client[Client Essensys<br/>Armoire<br/>192.168.1.151]
    
    Internet -->|WAN| Router
    Router -->|LAN| Switch
    Switch -->|Port 2| Port2
    Switch -->|Port 3| Port3
    Port2 --> RPi
    Port3 --> Client
    
    RPi -.->|API /api/*| Client
    
    style Internet fill:#e1f5ff
    style Router fill:#e3f2fd
    style Switch fill:#e8f5e9
    style RPi fill:#fff4e1
    style Client fill:#f3e5f5
    style Port2 fill:#c8e6c9
    style Port3 fill:#c8e6c9
```

**Configuration standard :**
- **Port 2 du Switch** : Raspberry Pi 4 (192.168.1.101)
- **Port 3 du Switch** : Client Essensys / Armoire (192.168.1.151)
- Le client Essensys communique avec le Raspberry Pi via les API `/api/*` sur le réseau local

## Sections

1. **[Ubiquiti Dream Machine Pro](ubiquiti-udm-pro.md)** - Configuration sur UDM Pro
2. **[Freebox](freebox.md)** - Configuration sur Freebox
3. **[SFR](sfr.md)** - Configuration sur routeur SFR
4. **[Orange Livebox](orange-livebox.md)** - Configuration sur Orange Livebox

## Vue d'ensemble

Pour permettre l'accès WAN, vous devez configurer :

1. **NAT/Port forwarding** :
   - Port 80 → 192.168.1.101:80
   - Port 443 → 192.168.1.101:443

2. **DNS local** (optionnel) :
   - `mon.essensys.fr` → 192.168.1.101

3. **DNS public** (pour WAN) :
   - `essensys.acme.com` → Votre IP publique

## Ports à rediriger

| Port externe | Port interne | Service |
|--------------|--------------|----------|
| 80 | 80 | Nginx (API locales) |
| 443 | 443 | Traefik (Frontend WAN HTTPS) |

## Test de la configuration

### Test local

```bash
# Depuis le réseau local
curl http://mon.essensys.fr/health
```

### Test WAN

```bash
# Depuis Internet
curl https://essensys.acme.com/
```

