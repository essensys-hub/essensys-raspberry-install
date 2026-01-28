# Release Notes - Mon Essensys V.1.2.0

**Date de sortie** : 28 janvier 2026

## Nouveautés principales

### Refonte complète de l'interface utilisateur

La V.1.2.0 apporte une refonte majeure de l'interface web avec une navigation moderne et responsive.

#### Nouveau design
- **Tableau de bord** : Page d'accueil avec 8 cartes récapitulatives (Sécurité, Chauffage, Éclairage, Volets, Cumulus, Arrosage, Notifications, Paramètres)
- **Navigation responsive** :
  - Desktop (≥1024px) : Barre latérale fixe à gauche
  - Mobile : Menu hamburger + barre d'onglets en bas de l'écran
- **Design moderne** : Utilisation de Tailwind CSS v4 et Heroicons

#### Pages dédiées par catégorie
Chaque catégorie dispose maintenant de sa propre page avec des contrôles adaptés :

| Page | Description |
|------|-------------|
| `/dashboard` | Tableau de bord avec vue d'ensemble |
| `/security` | Contrôle de l'alarme (activation/désactivation avec code) |
| `/heating` | Gestion des 4 zones de chauffage |
| `/lighting` | Contrôle des éclairages principaux et indirects |
| `/shutters` | Gestion des volets roulants et stores |
| `/water-heater` | Modes du chauffe-eau (cumulus) |
| `/sprinkler` | Programmation de l'arrosage |
| `/notifications` | Configuration des alertes (non disponible) |
| `/settings` | Paramètres du système |

#### Boutons d'action au lieu de toggles
L'interface utilise désormais des **boutons d'action** ("Allumer", "Éteindre", "Ouvrir", "Fermer") au lieu d'interrupteurs à bascule. Ce choix reflète le fonctionnement en **boucle ouverte** du système : aucun retour d'état en temps réel n'est disponible.

### Nouvelle API Backend

#### Endpoint historique des actions
- `GET /api/web/history/latest` : Récupère la dernière action envoyée pour la machine de l'utilisateur
- Permet d'afficher la dernière commande sur le tableau de bord

## Composants techniques

### Frontend (essensys-server-frontend)

**Nouveaux composants** :
- `MainLayout` : Layout responsive avec sidebar/bottom tabs
- `SidebarMenu` : Menu latéral desktop
- `BottomTabs` : Barre d'onglets mobile
- `MobileDrawer` : Menu hamburger complet
- `CardSummary` : Cartes récapitulatives du dashboard
- `ActionButton` : Boutons d'action stylisés
- `ControlCard` : Conteneur pour les contrôles
- `PageHeader` : En-tête de page avec navigation

**Stack technique** :
- React 19 + TypeScript
- Tailwind CSS v4 avec `@tailwindcss/postcss`
- Heroicons pour les icônes
- React Router v7 pour la navigation

### Backend (essensys-server-backend)

**Modifications** :
- Nouveau repository method `GetLastActionByMachineID()`
- Nouveau handler `GetHistoryLatest()`
- Nouvelle route `/api/web/history/latest`

### Installation (essensys-raspberry-install)

**Améliorations** :
- Variable centralisée `ESSENSYS_VERSION` pour aligner toutes les versions
- Clone automatique sur la branche spécifiée (V.1.2.0)
- Affichage des versions au démarrage du script d'installation

## Migration depuis V.1.1.0

### Mise à jour automatique

```bash
cd /home/essensys/essensys-raspberry-install
git pull origin V.1.2.0
sudo ./update.sh
```

### Compatibilité

- **Client legacy (BP_MQX_ETH)** : Entièrement compatible, aucune modification requise
- **API existantes** : Toutes les APIs V.1.1.0 restent fonctionnelles
- **Base de données** : Aucune migration requise

## Commits inclus

### essensys-server-frontend
- `d5a8e44` fix: Supprimer le paramètre title inutilisé dans MobileHeader
- `fe3dfab` fix: Supprimer le texte 'Essensys' dupliqué dans le header
- `0c33f87` fix: Corriger les noms des lumières et volets (alignement V.1.0.0)
- `1d3f55f` feat: Refonte UX avec navigation responsive et dashboard

### essensys-server-backend
- `f6cd9c6` fix: Corriger le type de MachineID (*int vers int) dans GetHistoryLatest
- `e567a9c` feat: Ajouter endpoint GET /api/web/history/latest

### essensys-raspberry-install
- `db2e9d6` feat: Ajouter variable ESSENSYS_VERSION pour aligner les versions

## Captures d'écran

L'interface modernisée comprend :
- Un dashboard avec des cartes cliquables
- Des pages dédiées avec des contrôles par pièce
- Une navigation fluide entre les sections

## Problèmes connus

- **Notifications** : La page notifications est désactivée (fonctionnalité non disponible côté backend)
- **Historique par catégorie** : L'API actuelle retourne uniquement la dernière action globale, pas par catégorie

## Contributeurs

- Nicolas Rineau (@nrineau)

---

**Licence** : MIT
