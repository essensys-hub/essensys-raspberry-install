# Interface de Débogage

L'interface de débogage (`/debug`) est un outil intégré au backend pour tester les communications avec les clients Essensys et diagnostiquer les problèmes de scénarios.

## Accès

L'interface est accessible à l'adresse suivante :
`http://mon.essensys.fr/debug`

## Fonctionnalités

![Interface de debug](../img/debug-interface.png)

### 1. Injection d'Actions (Inject Action)
Cette section permet d'envoyer manuellement des commandes au client (injecter des actions dans la file d'attente du backend).

*   **Key (Clé)** : L'indice de la variable à modifier (ex: `590` pour déclencher un scénario, `619` pour une lumière).
*   **Value (Valeur)** : La valeur à affecter.

**Exemple "Allumer Couloir" :**
*   Key: `619`
*   Value: `4`

**Exemple "Déclencher Scénario 2 (Je sors)" :**
*   Key: `590`
*   Value: `1` (Confirmation)

### 2. Logs Temps Réel (Logs / Response)
Cette section affiche les traces de communication backend/client en temps réel.

*   **Injected action** : Indique que votre commande manuelle a été reçue par le backend et mise en file d'attente (avec un GUID unique).
*   **Client retrieved ... actions** : Indique que le client (le boîtier Essensys) a fait une requête `GET /api/myactions` et a récupéré la commande. C'est la preuve que le "polling" fonctionne.
*   **Client CONFIRMED action** : Indique que le client a envoyé une requête `POST /api/done/{guid}` pour confirmer qu'il a bien reçu et traité l'action.

## Diagnostic

*   **Si vous voyez "Injected" mais jamais "Retrieved"** : Le client n'est probablement pas connecté ou ne poll pas l'API correctement. Vérifiez la connectivité réseau du boîtier.
*   **Si vous voyez "Retrieved" mais jamais "Confirmed"** : Le client reçoit la commande mais échoue à la traiter (bug firmware) ou à envoyer la confirmation.
## Référence des Commandes (Basé sur Scenario 1)

Voici la liste des constantes pour l'injection manuelle, basées sur les indices du **Scenario 1** (Zone de test recommandée).

**Pour exécuter une commande :**
1.  Injectez les valeurs dans les clés ci-dessous (ex: `611:1` pour allumer entrée).
2.  (Optionnel) Si nécessaire, déclenchez le scénario 1 en injectant `590:1` (Index `Scenario`).

### Éclairage - ALLUMER

| Constante | Clé | Valeur | Description |
| :--- | :--- | :--- | :--- |
| **Sce_Allumer_PDV_LSB** | **611** | `1` | Lampe Entrée |
| | | `2` | Lampe Salon 1 |
| | | `4` | Lampe Salon 2 |
| | | `8` | Lampe Dressing 1 |
| | | `16` | Lampe Dressing 2 |
| **Sce_Allumer_PDV_MSB** | **612** | `32` | Variateur Bureau |
| | | `64` | Variateur Salle à Manger |
| | | `128` | Variateur Salon |
| **Sce_Allumer_CHB_LSB** | **613** | `1` | Lampe Escalier |
| | | `2` | Lampe Grande Chambre 1 |
| | | `4` | Lampe Grande Chambre 2 |
| | | `8` | Lampe Petite Chambre 1 (1) |
| | | `16` | Lampe Petite Chambre 1 (2) |
| | | `32` | Lampe Petite Chambre 2 |
| | | `64` | Lampe Petite Chambre 3 |
| **Sce_Allumer_CHB_MSB** | **614** | `16` | Variateur Petite Chambre 3 |
| | | `32` | Variateur Petite Chambre 2 |
| | | `64` | Variateur Petite Chambre 1 |
| | | `128` | Variateur Grande Chambre |
| **Sce_Allumer_PDE_LSB** | **615** | `1` | Lampe Cuisine 1 |
| | | `2` | Lampe Cuisine 2 |
| | | `4` | Lampe SDB 1 |
| | | `8` | Lampe SDB 2 (1) |
| | | `16` | Lampe SDB 2 (2) |
| | | `32` | Lampe WC 1 |
| | | `64` | Lampe WC 2 |
| | | `128` | Lampe Service |
| **Sce_Allumer_PDE_MSB** | **616** | `1` | Lampe Dégagement 1 |
| | | `2` | Lampe Dégagement 2 |
| | | `4` | Lampe Terrasse |
| | | `8` | Lampe Annexe 1 |
| | | `16` | Lampe Annexe 2 |
| | | `128` | Variateur SDB 1 |

### Éclairage - ÉTEINDRE

| Constante | Clé | Valeur | Description |
| :--- | :--- | :--- | :--- |
| **Sc_Eteindre_PDV_LSB** | **605** | `1...255` | Entrée, Salon, Dressing (Mêmes bits que Allumer) |
| **Sc_Eteindre_PDV_MSB** | **606** | `32...128` | Variateurs PDV |
| **Sc_Eteindre_CHB_LSB** | **607** | `1...64` | Lampes Chambres |
| **Sc_Eteindre_CHB_MSB** | **608** | `16...128` | Variateurs Chambres |
| **Sce_Eteindre_PDE_LSB** | **609** | `1...128` | Lampes Pièces d'Eau |
| **Sce_Eteindre_PDE_MSB** | **610** | `1...128` | Lampes/Var Pièces d'Eau |

### Volets & Stores - OUVRIR

| Constante | Clé | Valeur | Description |
| :--- | :--- | :--- | :--- |
| **Sce_OuvrirVolets_PDV** | **617** | `1` | Volet Salon 1 |
| | | `2` | Volet Salon 2 |
| | | `4` | Volet Salon 3 |
| | | `8` | Volet SAM 1 |
| | | `16` | Volet SAM 2 |
| | | `32` | Volet Bureau |
| **Sce_OuvrirVolets_CHB** | **618** | `1` | Volet Grande Chambre 1 |
| | | `2` | Volet Grande Chambre 2 |
| | | `4` | Volet Petite Chambre 1 |
| | | `8` | Volet Petite Chambre 2 |
| | | `16` | Volet Petite Chambre 3 |
| **Sce_OuvrirVolets_PDE** | **619** | `1` | Volet Cuisine 1 |
| | | `2` | Volet Cuisine 2 |
| | | `4` | Volet SDB 1 |
| | | `8` | Remonter Store Terrasse |

### Volets & Stores - FERMER

| Constante | Clé | Valeur | Description |
| :--- | :--- | :--- | :--- |
| **Sce_FermerVolets_PDV** | **620** | `1...32` | Volets PDV (Mêmes bits que Ouvrir) |
| **Sce_FermerVolets_CHB** | **621** | `1...16` | Volets Chambres |
| **Sce_FermerVolets_PDE** | **622** | `1...8` | Volets PDE / Sortir Store |

### Scénarios & Sécurité

| Constante | Clé | Valeur | Description |
| :--- | :--- | :--- | :--- |
| **Sc_Alarme_ON** | **593** | `1` | Mettre l'alarme |
| | | `2` | Enlever l'alarme |
| **Sce_Securite** | **623** | `1` | Couper prises sécurité |
| | | `2` | Remettre prises sécurité |
| **Sce_Machines** | **624** | `1` | Couper machines à laver |
| | | `2` | Remettre machines à laver |
| **Scenario** | **590** | `1...8` | **DÉCLENCHER UN SCÉNARIO** (1=Scen1) |

## Description des Scénarios (Table de Vérité)

Voici le comportement par défaut des scénarios (basé sur `table_ref.txt` et `TableEchange.h`).
Pour déclencher un scénario, injectez son numéro (1-8) dans la clé **590**.

| # | Nom | Base | Comportement par défaut |
| :--- | :--- | :--- | :--- |
| **1** | **Réservé Internet** | 592 | *Vide par défaut*. Utilisé pour les commandes manuelles via le debug (Zone de test). |
| **2** | **Je sors** | 633 | **Alarme** : Active (ON).<br>**Volets** : Ferme TOUT.<br>**Sécurité** : Coupe les prises.<br>**Confirmation** : Requise sur l'écran. |
| **3** | **Je pars en vacances** | 674 | **Alarme** : Active (ON).<br>**Volets** : Ferme TOUT.<br>**Chauffage** : Force HORS GEL (toutes zones).<br>**Eau/Machines** : Coupe l'eau (Securite) et les machines.<br>**Cumulus** : OFF. |
| **4** | **Je rentre** | 715 | **Alarme** : Désactive (OFF).<br>**Volets** : Ouvre TOUT.<br>**Sécurité** : Rétablit les prises.<br>**Chauffage** : Reprend le dernier mode mémorisé.<br>**Machines** : Rétablit l'alimentation. |
| **5** | **Je vais me coucher** | 756 | **Alarme** : Active (ON).<br>**Volets** : Ferme TOUT.<br>**Réveil** : Arme la fonction réveil.<br>**Sécurité** : Coupe les prises.<br>**Chauffage** : Continue le fonctionnement actuel. |
| **6** | **Je me lève** | 797 | **Alarme** : Désactive (OFF).<br>**Volets** : Ouvre TOUT.<br>**Sécurité** : Rétablit les prises.<br>**Réveil** : Désactivé. |
| **7** | **Personnalisé 1** | 838 | *Vide par défaut*. Configurable par l'utilisateur. |
| **8** | **Personnalisé 2** | 879 | *Vide par défaut*. Configurable par l'utilisateur. |

## Personnalisation (Scénarios 7 et 8)

D'après le code C (`TableEchange.h`), tous les scénarios partagent la même structure de données (définie par `enum enumScenario`).
Pour configurer un scénario "Personnalisé", il suffit d'écrire les valeurs souhaitées aux adresses mémoire correspondantes.

**Formule :** `Clé = Base_Scénario + Offset_Fonction`

### Bases des Scénarios
*   **Scénario 7** : `838`
*   **Scénario 8** : `879`

### Offsets des Fonctions (à ajouter à la Base)

| Fonction | Offset | Description |
| :--- | :--- | :--- |
| **Alarme** | `+1` | `1`=Activer, `2`=Désactiver |
| **Éteindre PDV (LSB)** | `+13` | Voir tableau "Éclairage" pour les valeurs (bits) |
| **Allumer PDV (LSB)** | `+19` | Voir tableau "Éclairage" pour les valeurs |
| **Ouvrir Volets PDV** | `+25` | Voir tableau "Volets - Ouvrir" |
| **Fermer Volets PDV** | `+28` | Voir tableau "Volets - Fermer" |
| **Sécurité** | `+31` | `1`=Couper, `2`=Rétablir |

*(Note : Les offsets continuent séquentiellement pour MSB, CHB, PDE... Voir `TableEchange.h` pour la liste complète : +19=Allumer PDV LSB, +20=PDV MSB, +21=CHB LSB...)*

### Exemple Concret
**Objectif :** Configurer le **Scénario 7** pour qu'il **allume la lampe de l'Entrée** (`Valeur 1`).

1.  **Base Scénario 7** = `838`
2.  **Offset Allumer PDV LSB** = `+19`
3.  **Clé à injecter** = 838 + 19 = **857**
4.  **Valeur** = `1` (Entrée)

**Commande à injecter :** `857:1`
Ensuite, déclencher le scénario 7 en injectant `590:7`.

### Exemples de Configuration pour le Scénario 7 (Base 838)

Voici deux exemples complets pour illustrer la logique.

#### Exemple A : "Soirée TV" (Fermer Salon + Lumière Tamisée)
**Objectif :**
1.  Fermer les 3 volets du Salon.
2.  Allumer le variateur du Salon.
3.  Éteindre les lumières de la Cuisine (pour éviter les reflets).

**Calculs & Injections :**

| Action | Offset | Clé (838 + Offset) | Valeur (Bitmask) | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Fermer Volets Salon** | `+28` | **866** | `7` | `1` (Volet 1) + `2` (Volet 2) + `4` (Volet 3) = **7** |
| **Allumer Var. Salon** | `+20` | **858** | `128` | `128` (Variateur Salon) cf. Table Allumer MSB |
| **Eteindre Cuisine** | `+17` | **855** | `3` | `1` (Cuisine 1) + `2` (Cuisine 2) = **3** |

**Résumé :** Injectez `866:7`, `858:128`, `855:3` -> Puis lancez `590:7`.

#### Exemple B : "Sécurité Totale" (Départ Vacances Personnalisé)
**Objectif :**
1.  Mettre l'alarme.
2.  Fermer TOUS les volets de la maison (PDV, CHB, PDE).
3.  Couper l'arrivée d'eau (Sécurité).

**Calculs & Injections :**

| Action | Offset | Clé (838 + Offset) | Valeur | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Alarme ON** | `+1` | **839** | `1` | `1` = Mettre l'alarme |
| **Fermer Volets PDV** | `+28` | **866** | `255` | `255` = Tous les bits à 1 (Salon, SAM, Bureau...) |
| **Fermer Volets CHB** | `+29` | **867** | `255` | `255` = Toutes les chambres |
| **Fermer Volets PDE** | `+30` | **868** | `255` | `255` = Cuisine, SDB, Store |
| **Couper Eau** | `+31` | **869** | `1` | `1` = Couper prises/eau (Sécurité) |

**Résumé :** Injectez `839:1`, `866:255`, `867:255`, `868:255`, `869:1` -> Puis lancez `590:7`.

### Table Complète des Offsets (Programmation C)

Utilisez ce tableau pour calculer n'importe quelle clé de configuration.
**Clé Finale = Base Scénario + Offset**

*Exemple de calcul pour la colonne "Ex: Clé Scén 7" : Base 838 + Offset.*

| Offset | Ex: Clé Scén 7 | Variable C | Fonction / Description | Valeurs (Bitmask) |
| :--- | :--- | :--- | :--- | :--- |
| **+0** | **838** | `Scenario_Confirme_Scenario` | Demande Confirmation | `1`=Oui (Géré par écran) |
| **+1** | **839** | `Scenario_Alarme_ON` | Activation Alarme | `1`=ON, `2`=OFF |
| **+2** | **840** | `AlarmeConfig_Code` | Config : Code Requis | `1`=Oui, `0`=Non |
| **+3** | **841** | `AlarmeConfig_Detect1` | Config : Détecteur Présence 1 | `1`=Utilisé, `0`=Désactivé |
| **+4** | **842** | `AlarmeConfig_Detect2` | Config : Détecteur Présence 2 | `1`=Utilisé, `0`=Désactivé |
| **+5** | **843** | `AlarmeConfig_DetectOuv` | Config : Détecteur Ouverture | `1`=Utilisé, `0`=Désactivé |
| **+6** | **844** | `AlarmeConfig_Detect1SurVoie` | Config : Présence 1 sur Voie | `1`=Oui, `0`=Non |
| **+7** | **845** | `AlarmeConfig_Detect2SurVoie` | Config : Présence 2 sur Voie | `1`=Oui, `0`=Non |
| **+8** | **846** | `AlarmeConfig_DetectOuvSurVoie`| Config : Ouverture sur Voie | `1`=Oui, `0`=Non |
| **+9** | **847** | `AlarmeConfig_SireneInt` | Config : Sirène Intérieure | `1`=Activée, `0`=Non |
| **+10** | **848** | `AlarmeConfig_SireneExt` | Config : Sirène Extérieure | `1`=Activée, `0`=Non |
| **+11** | **849** | `AlarmeConfig_BloqueVolets` | Config : Bloquer Volets si Alarme| `1`=Oui, `0`=Non |
| **+12** | **850** | `AlarmeConfig_ForcerEclairage` | Config : Forcer Lumières si Alarme| `1`=Oui, `0`=Non |
| **+13** | **851** | `Scenario_Eteindre_PDV_LSB` | **Éteindre** PDV (Lampes) | Bits 0-7 (Entrée, Salon...) |
| **+14** | **852** | `Scenario_Eteindre_PDV_MSB` | **Éteindre** PDV (Variateurs) | Bits 5-7 (Var Salon/Bureau...) |
| **+15** | **853** | `Scenario_Eteindre_CHB_LSB` | **Éteindre** CHB (Lampes) | Bits 0-6 (Chambres...) |
| **+16** | **854** | `Scenario_Eteindre_CHB_MSB` | **Éteindre** CHB (Variateurs) | Bits 4-7 (Var Chambres...) |
| **+17** | **855** | `Scenario_Eteindre_PDE_LSB` | **Éteindre** PDE (Lampes) | Bits 0-7 (Cuis., SDB, WC...) |
| **+18** | **856** | `Scenario_Eteindre_PDE_MSB` | **Éteindre** PDE (Lampes/Var) | Bits 0-4 + 7 |
| **+19** | **857** | `Scenario_Allumer_PDV_LSB` | **Allumer** PDV (Lampes) | Bits 0-7 (Entrée, Salon...) |
| **+20** | **858** | `Scenario_Allumer_PDV_MSB` | **Allumer** PDV (Variateurs) | Bits 5-7 (Var Salon/Bureau...) |
| **+21** | **859** | `Scenario_Allumer_CHB_LSB` | **Allumer** CHB (Lampes) | Bits 0-6 (Chambres...) |
| **+22** | **860** | `Scenario_Allumer_CHB_MSB` | **Allumer** CHB (Variateurs) | Bits 4-7 (Var Chambres...) |
| **+23** | **861** | `Scenario_Allumer_PDE_LSB` | **Allumer** PDE (Lampes) | Bits 0-7 (Cuis., SDB, WC...) |
| **+24** | **862** | `Scenario_Allumer_PDE_MSB` | **Allumer** PDE (Lampes/Var) | Bits 0-4 + 7 |
| **+25** | **863** | `Scenario_OuvrirVolets_PDV` | **Ouvrir** Volets PDV | Bits 0-5 (Salon, SAM, Bur.) |
| **+26** | **864** | `Scenario_OuvrirVolets_CHB` | **Ouvrir** Volets CHB | Bits 0-4 (Chambres) |
| **+27** | **865** | `Scenario_OuvrirVolets_PDE` | **Ouvrir** Volets PDE | Bits 0-3 (Cuis., SDB, Store) |
| **+28** | **866** | `Scenario_FermerVolets_PDV` | **Fermer** Volets PDV | Bits 0-5 (Salon, SAM, Bur.) |
| **+29** | **867** | `Scenario_FermerVolets_CHB` | **Fermer** Volets CHB | Bits 0-4 (Chambres) |
| **+30** | **868** | `Scenario_FermerVolets_PDE` | **Fermer** Volets PDE | Bits 0-3 (Cuis., SDB, Store) |
| **+31** | **869** | `Scenario_Securite` | Prises Commandées | `1`=Couper, `2`=Rétablir |
| **+32** | **870** | `Scenario_Machines` | Machines à Laver | `1`=Couper, `2`=Rétablir |
| **+33** | **871** | `Scenario_Chauf_zj` | Chauffage Jour | `0x00...` |
| **+34** | **872** | `Scenario_Chauf_zn` | Chauffage Nuit | Idem |
| **+35** | **873** | `Scenario_Chauf_zsb1` | Chauffage SDB 1 | Idem |
| **+36** | **874** | `Scenario_Chauf_zsb2` | Chauffage SDB 2 | Idem |
| **+37** | **875** | `Scenario_Cumulus` | Cumulus | `0`=Auto, `1`=HC, `2`=OFF |
| **+38** | **876** | `Scenario_Reveil_Reglage` | Réveil : Procédure Réglage | `1`=Lancer réglage |
| **+39** | **877** | `Scenario_Reveil_ON` | Réveil : Activation | `1`=Armer, `2`=Désactiver |
| **+40** | **878** | `Scenario_Efface` | Effacer Scénario | `1`=Reset Paramètres |

## Configuration des Temps (Volets & Lampes)

Vous pouvez régler la durée de course des volets ou le temps d'extinction automatique des lampes.

### Temps de Course des Volets (en Secondes)
*Valeur : 1 à 255 secondes.*

| Zone | Clé de Base | Description | Détail des Indices |
| :--- | :--- | :--- | :--- |
| **Volets PDV** | **566** | Salon, SAM, Bureau | `566`=Volet 1, `567`=Volet 2 ... `573`=Volet 8 |
| **Volets CHB** | **574** | Chambres | `574`=Volet 1 ... `581`=Volet 8 |
| **Volets PDE** | **582** | Cuis., SDB, Store | `582`=Volet 1 ... `589`=Volet 8 |

**Exemple :** Régler le Volet 1 du Salon (Index 0 de PDV) à 20 secondes.
*   Clé : `566`
*   Valeur : `20`

### Temps d'Extinction Automatique des Lampes (en Minutes)
*Valeur : 1 à 255 minutes (0 = Pas d'extinction).*

| Zone | Clé de Base | Description | Détail des Indices |
| :--- | :--- | :--- | :--- |
| **Lampes PDV** | **518** | Entrée, Salon... | `518`=Lampe 1 ... `533`=Lampe 16 |
| **Lampes CHB** | **534** | Chambres | `534`=Lampe 1 ... `549`=Lampe 16 |
| **Lampes PDE** | **550** | SDB, WC, Couloir | `550`=Lampe 1 ... `565`=Lampe 16 |








