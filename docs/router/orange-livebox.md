# Configuration Orange Livebox

Configuration du NAT/port forwarding sur Orange Livebox.

## Schéma de connexion réseau

```mermaid
graph TB
    Internet[Internet]
    Livebox[Orange Livebox]
    Switch[Switch / Hub]
    
    Port2[Port 2]
    Port3[Port 3]
    
    RPi[Raspberry Pi 4<br/>192.168.1.101<br/>mon.essensys.fr]
    Client[Client Essensys<br/>Armoire<br/>192.168.1.151]
    
    Internet -->|WAN| Livebox
    Livebox -->|LAN| Switch
    Switch -->|Port 2| Port2
    Switch -->|Port 3| Port3
    Port2 --> RPi
    Port3 --> Client
    
    RPi -.->|API /api/*| Client
    
    style Internet fill:#e1f5ff
    style Livebox fill:#e3f2fd
    style Switch fill:#e8f5e9
    style RPi fill:#fff4e1
    style Client fill:#f3e5f5
    style Port2 fill:#c8e6c9
    style Port3 fill:#c8e6c9
```

**Connexions :**
- **Port 2** : Raspberry Pi 4 (192.168.1.101)
- **Port 3** : Client Essensys / Armoire (192.168.1.151)
- Le client Essensys communique avec le Raspberry Pi via les API `/api/*`

## NAT/Port Forwarding

### Via l'interface Livebox

1. Se connecter à l'interface Livebox (http://192.168.1.1)
2. Aller dans **Paramètres avancés** → **NAT/PAT** ou **Redirection de ports**
3. Ajouter les règles :

**Règle 1 : Port 80**
- **Nom** : Essensys HTTP
- **Protocole** : TCP
- **Port externe** : 80
- **Port interne** : 80
- **IP interne** : 192.168.1.101

**Règle 2 : Port 443**
- **Nom** : Essensys HTTPS
- **Protocole** : TCP
- **Port externe** : 443
- **Port interne** : 443
- **IP interne** : 192.168.1.101

## Configuration DNS local

Configurer le DNS local via l'interface Livebox ou utiliser `/etc/hosts` sur les machines clientes.

## Vérification

Vérifier que les règles sont actives dans l'interface Livebox.
