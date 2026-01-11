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
*   **Si vous voyez "Confirmed" mais rien ne se passe** : La communication fonctionne parfaitement. Le problème est probablement dans la logique du scénario (conflit de variables, initialisation par défaut écrasant la commande, etc.).

## Référence des Commandes

Voici la liste des constantes extraites de `TableEchange.h` pour injecter des commandes manuellement.
L'index (Clé) est calculé sur une base de **600 + Enum**.

### Éclairage - ALLUMER

| Constante | Clé | Valeur | Description |
| :--- | :--- | :--- | :--- |
| **Scenario_Allumer_PDV_LSB** | **619** | `1` | Lampe Entrée |
| | | `2` | Lampe Salon 1 |
| | | `4` | Lampe Salon 2 |
| | | `8` | Lampe Dressing 1 |
| | | `16` | Lampe Dressing 2 |
| **Scenario_Allumer_PDV_MSB** | **620** | `32` | Variateur Bureau |
| | | `64` | Variateur Salle à Manger |
| | | `128` | Variateur Salon |
| **Scenario_Allumer_CHB_LSB** | **621** | `1` | Lampe Escalier |
| | | `2` | Lampe Grande Chambre 1 |
| | | `4` | Lampe Grande Chambre 2 |
| | | `8` | Lampe Petite Chambre 1 (1) |
| | | `16` | Lampe Petite Chambre 1 (2) |
| | | `32` | Lampe Petite Chambre 2 |
| | | `64` | Lampe Petite Chambre 3 |
| **Scenario_Allumer_CHB_MSB** | **622** | `16` | Variateur Petite Chambre 3 |
| | | `32` | Variateur Petite Chambre 2 |
| | | `64` | Variateur Petite Chambre 1 |
| | | `128` | Variateur Grande Chambre |
| **Scenario_Allumer_PDE_LSB** | **623** | `1` | Lampe Cuisine 1 |
| | | `2` | Lampe Cuisine 2 |
| | | `4` | Lampe SDB 1 |
| | | `8` | Lampe SDB 2 (1) |
| | | `16` | Lampe SDB 2 (2) |
| | | `32` | Lampe WC 1 |
| | | `64` | Lampe WC 2 |
| | | `128` | Lampe Service |
| **Scenario_Allumer_PDE_MSB** | **624** | `1` | Lampe Dégagement 1 |
| | | `2` | Lampe Dégagement 2 |
| | | `4` | Lampe Terrasse |
| | | `8` | Lampe Annexe 1 |
| | | `16` | Lampe Annexe 2 |
| | | `128` | Variateur SDB 1 |

*Note : Pour éteindre, utilisez les constantes `Scenario_Eteindre_...` (Indices 613 à 618) avec les mêmes valeurs binaires.*

### Volets & Stores - OUVRIR

| Constante | Clé | Valeur | Description |
| :--- | :--- | :--- | :--- |
| **Scenario_OuvrirVolets_PDV** | **625** | `1` | Volet Salon 1 |
| | | `2` | Volet Salon 2 |
| | | `4` | Volet Salon 3 |
| | | `8` | Volet SAM 1 |
| | | `16` | Volet SAM 2 |
| | | `32` | Volet Bureau |
| **Scenario_OuvrirVolets_CHB** | **626** | `1` | Volet Grande Chambre 1 |
| | | `2` | Volet Grande Chambre 2 |
| | | `4` | Volet Petite Chambre 1 |
| | | `8` | Volet Petite Chambre 2 |
| | | `16` | Volet Petite Chambre 3 |
| **Scenario_OuvrirVolets_PDE** | **627** | `1` | Volet Cuisine 1 |
| | | `2` | Volet Cuisine 2 |
| | | `4` | Volet SDB 1 |
| | | `8` | Remonter Store Terrasse |

### Volets & Stores - FERMER

| Constante | Clé | Valeur | Description |
| :--- | :--- | :--- | :--- |
| **Scenario_FermerVolets_PDV** | **628** | `1` | Volet Salon 1 |
| | | `2` | Volet Salon 2 |
| | | `4` | Volet Salon 3 |
| | | `8` | Volet SAM 1 |
| | | `16` | Volet SAM 2 |
| | | `32` | Volet Bureau |
| **Scenario_FermerVolets_CHB** | **629** | `1` | Volet Grande Chambre 1 |
| | | `2` | Volet Grande Chambre 2 |
| | | `4` | Volet Petite Chambre 1 |
| | | `8` | Volet Petite Chambre 2 |
| | | `16` | Volet Petite Chambre 3 |
| **Scenario_FermerVolets_PDE** | **630** | `1` | Volet Cuisine 1 |
| | | `2` | Volet Cuisine 2 |
| | | `4` | Volet SDB 1 |
| | | `8` | Sortir Store Terrasse |

### Scénarios & Sécurité

| Constante | Clé | Valeur | Description |
| :--- | :--- | :--- | :--- |
| **Scenario_Alarme_ON** | **601** | `1` | Mettre l'alarme |
| | | `2` | Enlever l'alarme |
| **Scenario_Securite** | **631** | `1` | Couper prises sécurité |
| | | `2` | Remettre prises sécurité |
| **Scenario_Machines** | **632** | `1` | Couper machines à laver |
| | | `2` | Remettre machines à laver |

