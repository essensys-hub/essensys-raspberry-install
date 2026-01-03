# Installation

Cette section couvre toutes les étapes d'installation, de la préparation du matériel à l'installation complète d'Essensys.

## Étapes d'installation

1. **[Préparation du matériel](preparation.md)** - Matériel nécessaire et préparation
2. **[Installation de l'OS](os-installation.md)** - Installation de Raspberry Pi OS sur le SSD
3. **[Installation Essensys](essensys-installation.md)** - Déploiement du backend et frontend

## Vue d'ensemble

```mermaid
flowchart TD
    A[Préparation matériel] --> B[Installation OS]
    B --> C[Configuration réseau]
    C --> D[Installation Essensys]
    D --> E[Configuration Nginx]
    E --> F[Configuration Traefik optionnel]
    F --> G[Services démarrés]
    
    style A fill:#e1f5ff
    style B fill:#fff4e1
    style C fill:#e8f5e9
    style D fill:#f3e5f5
    style E fill:#e3f2fd
    style F fill:#e3f2fd
    style G fill:#c8e6c9
```

