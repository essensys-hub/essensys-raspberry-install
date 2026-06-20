# Guide Utilisateur — Interface Mon Essensys

Ce guide présente l'utilisation quotidienne de l'interface web **Mon Essensys**,
le tableau de bord domotique accessible depuis votre navigateur.

!!! info "Public visé"
    Utilisateur final (occupant, gestionnaire du logement). Pour l'exploitation
    technique (services, monitoring, mises à jour), voir le
    [Guide Administrateur](admin-guide.md).

---

## 1. Accéder à l'interface

Sur la [Gateway CM5](../installation/gateway-cm5.md), l'interface est disponible
depuis n'importe quel poste du réseau local :

```
https://mon.essensys.local/
```

!!! warning "Avertissement de sécurité du navigateur"
    Le certificat local est **auto-signé** pour le nom `mon.essensys.local`. Le
    navigateur affiche donc « Votre connexion n'est pas privée » la première fois.
    C'est normal sur un réseau local privé : cliquez **Paramètres avancés →
    Continuer vers mon.essensys.local**. L'avertissement ne réapparaît plus ensuite.

<!-- SCREENSHOT: page de connexion / premier accès -->
![Accès à Mon Essensys](../img/guide/connexion.png)

---

## 2. Tableau de bord

Le **Tableau de bord** est la page d'accueil. Il regroupe l'accès rapide à chaque
domaine (caméras, sécurité, chauffage…) et un aperçu de l'état du système.

<!-- SCREENSHOT: dashboard complet -->
![Tableau de bord](../img/guide/dashboard.png)

!!! note "Système en boucle ouverte"
    Un rappel peut s'afficher : *« Le système fonctionne en boucle ouverte. Les états
    affichés ne reflètent pas toujours l'état réel des équipements. »* Cela signifie
    que l'interface envoie des commandes mais ne reçoit pas systématiquement de retour
    d'état des équipements de l'armoire. Si le message *« Impossible de récupérer
    l'historique »* apparaît, l'historique n'est temporairement pas disponible —
    le pilotage reste fonctionnel.

La barre latérale gauche donne accès aux sections suivantes.

---

## 3. UniFi Protect — Caméras de surveillance

Visualisation des **caméras de surveillance** UniFi Protect connectées.

<!-- SCREENSHOT: section UniFi Protect -->
![UniFi Protect](../img/guide/unifi-protect.png)

- Flux vidéo des caméras.
- Aucune action récente n'est affichée tant qu'aucun événement n'est remonté.

---

## 4. Sécurité — Alarme et protection

Pilotage de l'**alarme** et des dispositifs de protection.

<!-- SCREENSHOT: section Sécurité -->
![Sécurité](../img/guide/securite.png)

- Armement / désarmement de l'alarme.
- État des zones et capteurs.

---

## 5. Chauffage

Réglage du **chauffage** par zone.

<!-- SCREENSHOT: section Chauffage -->
![Chauffage](../img/guide/chauffage.png)

- Consigne de température.
- Modes (confort / éco / hors-gel selon installation).

---

## 6. Éclairage

Commande des **éclairages**.

<!-- SCREENSHOT: section Éclairage -->
![Éclairage](../img/guide/eclairage.png)

- Allumer / éteindre par pièce ou par circuit.
- Variation (dimmer) si l'équipement le permet.

---

## 7. Volets & Stores

Pilotage des **volets roulants et stores**.

<!-- SCREENSHOT: section Volets & Stores -->
![Volets & Stores](../img/guide/volets.png)

- Ouverture / fermeture / arrêt.
- Commande groupée par pièce ou globale.

---

## 8. Cumulus

Gestion du **chauffe-eau (cumulus)**.

<!-- SCREENSHOT: section Cumulus -->
![Cumulus](../img/guide/cumulus.png)

- Marche / arrêt.
- Mode heures creuses selon configuration.

---

## 9. Arrosage

Commande de l'**arrosage**.

<!-- SCREENSHOT: section Arrosage -->
![Arrosage](../img/guide/arrosage.png)

- Démarrage / arrêt manuel.
- Programmes selon configuration.

---

## 10. Conseils d'utilisation

- **Délai d'application** : en boucle ouverte, laissez quelques secondes à la
  commande pour atteindre l'équipement avant de réémettre.
- **Plusieurs utilisateurs** : l'interface est multi-postes ; l'état affiché peut
  varier d'un poste à l'autre tant que l'équipement n'a pas confirmé.
- **Accès à distance** : l'accès depuis Internet (WAN) passe par un nom de domaine
  dédié protégé par authentification — voir [Accès WAN](../acces/wan.md).

---

## Voir aussi

- [Guide Administrateur](admin-guide.md)
- [Accès local](../acces/local.md)
- [Application iOS](../client-ios.md) · [Application Android](../client-android.md)
</content>
