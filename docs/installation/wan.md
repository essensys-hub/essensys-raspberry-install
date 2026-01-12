# Étape 3 : Choix du Domaine WAN (Optionnel)

Pour accéder à votre serveur Essensys depuis n'importe où dans le monde (accès WAN), vous avez besoin d'un nom de domaine. 

!!! note "Optionnel"
    Cette étape est **facultative**. Si vous souhaitez uniquement utiliser Essensys sur votre réseau local (chez vous), vous pouvez passer cette étape et continuer l'installation. Vous pourrez configurer un accès extérieur plus tard.

## Pourquoi un nom de domaine ?

Un nom de domaine (ex: `ma-maison.duckdns.org`) permet à vos services d'être identifiables sur Internet. Couplé à un certificat SSL, il garantit également une connexion sécurisée (HTTPS) entre votre téléphone/ordinateur et votre Raspberry Pi.

## Les options disponibles

Nous recommandons deux approches principales :

### 1. DuckDNS (Gratuit & Simple)
**DuckDNS** est un service de DNS dynamique gratuit. Il est idéal pour commencer car le script d'installation d'Essensys peut le configurer automatiquement pour vous.
- [ ] Créer un compte sur [duckdns.org](https://www.duckdns.org)
- [ ] Choisir un sous-domaine (ex: `votre-nom`)
- [ ] Noter votre **Token** DuckDNS (nécessaire pour l'installation)

!!! info "Guides DuckDNS"
    Pour plus d'informations, consultez le [guide de configuration DuckDNS](../acces/duckdns.md) et la [procédure détaillée](../acces/duckdns-guide.md).

### 2. Domaine Personnalisé (Avancé)
Si vous possédez déjà un nom de domaine (chez OVH, Gandi, etc.), vous pouvez l'utiliser en créant un enregistrement CNAME ou A pointant vers votre adresse IP publique.
- [ ] Configurer la redirection DNS chez votre registraire.

---

!!! tip "Conseil"
    Si vous n'êtes pas sûr, commencez sans domaine ou avec DuckDNS. C'est le plus simple pour valider que tout fonctionne.

---
[:material-arrow-right-circle: **Étape suivante : Installation d'Essensys**](essensys-installation.md){ .md-button .md-button--primary }
