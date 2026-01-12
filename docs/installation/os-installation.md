# Installation de l'OS sur le SSD

Cette section explique comment installer Raspberry Pi OS sur le SSD connecté via l'adaptateur USB-SATA.

## Prérequis

- Matériel préparé (voir [Préparation du matériel](preparation.md))
- Raspberry Pi Imager installé
- SSD connecté à l'ordinateur via l'adaptateur USB-SATA

## Étapes d'installation

### Étape 1 : Lancer Raspberry Pi Imager

- [ ] Lancer **Raspberry Pi Imager** sur votre ordinateur.
#### Étape 1.1 : Sélection de board (Raspberry Pi 4)
- [ ] Cliquer sur **"DEVICE"** et sélectionner **"Raspberry Pi 4"**.
- ![Étape 1.1](../img/install_001.png) 
#### Étape 1.2 :  Sélection de l'OS (Raspberry Pi OS (OTHER))
- [ ] Cliquer sur **"OS"** et sélectionner **"Raspberry Pi OS (OTHER)"**.
- ![Étape 1.2.1](../img/install_002.png)
- [ ] Cliquer sur **"OS"** et sélectionner **"Raspberry Pi OS Lite (64-bit)"**.
- ![Étape 1.2.2](../img/install_003.png)
#### Étape 1.3 : Configuration Storage (SSD)
- [ ] Cliquer sur **"STORAGE"** et sélectionner **"SSD"**.
- ![Étape 1.3.1](../img/install_004.png)
#### Étape 1.4 : Configuration hostname
- [ ] Cliquer sur **"Customisation: Choose Hostname"** et sélectionner **"essensys-server"**.
- ![Étape 1.4.1](../img/install_005.png)
#### Étape 1.5 : Configuration localisation
- [ ] Cliquer sur **"Customisation: Localization"** et sélectionner **"Europe/Paris"**.
- ![Étape 1.5.1](../img/install_006.png)
#### Étape 1.6 : Configuration création utilisateur
- [ ] Cliquer sur **"Customisation: Choose Username "** et modifier le nom d'utilisateur par **"essensys"**.
- [ ] Cliquer sur **"Customisation: Choose Password "** et modifier le mot de passe par **"essensys"**.
!!! warning "Important : Choix de l'utilisateur"
    Par défaut, l'installation d'Essensys utilise l'utilisateur `essensys`. 
    **Si vous choisissez un autre nom d'utilisateur** (par exemple `pi` ou un nom personnalisé), **vous DEVEZ Ampérativement l'indiquer** lors de l'exécution du script d'installation via l'option `--user`.
    Exemple : `./install.sh --user <votre_user>`

- ![Étape 1.6.1](../img/install_007.png)

#### Étape 1.7 : Configuration Wi-Fi
- [ ] Cliquer sur **"Customisation: Wi-Fi"** et modifier le SSID.
- [ ] Cliquer sur **"Customisation: Wi-Fi"** et modifier le mot de passe.
- ![Étape 1.7.1](../img/install_008.png)
#### Étape 1.8 : Options SSH
- [ ] Cliquer sur **"Customisation: SSH"** et cocher "Enable SSH".
- ![Étape 1.8.1](../img/install_009.png)
#### Étape 1.9 : RPI connect optionnel (non recommandé)
- [ ] Cliquer sur **"Customisation: RPI connect"** et cocher "Enable RPI connect".
- ![Étape 1.9.1](../img/install_010.png)
#### Étape 1.10 : Écriture terminée
- [ ] Cliquer sur **"WRITE"**.
- ![Étape 1.10.1](../img/install_012.png)
- [ ] Cliquer sur **"I understand, Erase and write"**.
- ![Étape 1.10.2](../img/install_013.png)
- [ ] Cliquer sur **"remplir avec le username et passeword admin de la workstation"**.
- ![Étape 1.10.3](../img/install_014.png)
- [ ] Cliquer sur **"Attendre la fin de l'écriture"**.
- ![Étape 1.10.4](../img/install_015.png)
- [ ] Cliquer sur **"Cliquer sur Finish"**.
- ![Étape 1.10.5](../img/install_017.png)


    
## Installation sur le Raspberry Pi

### Étape 5 : Brancher le matériel

![Raspberry Pi 4](../img/raspberry_pi_4.jpg)

1. Connecter le **SSD au Raspberry Pi** via l'adaptateur USB-SATA (Port bleu USB 3.0).
2. Connecter le **câble Ethernet**.
3. Connecter l'**alimentation** USB-C.

### Étape 6 : Premier démarrage et IP

1. Allumer le Raspberry Pi et attendre 2 minutes.
2. Depuis votre ordinateur, trouver l'adresse IP du Raspberry Pi :

**Sur le même réseau local :**

```bash
# Linux/Mac
arp -a | grep -i "b8:27:eb\|dc:a6:32\|e4:5f:01"
```

**Via le routeur :**
- Identifier le Raspberry Pi dans la liste des appareils connectés.



---
[:material-arrow-right-circle: **Étape suivante : Choix du Domaine WAN**](wan.md){ .md-button .md-button--primary }

## Dépannage

### Le Raspberry Pi ne démarre pas

- Vérifier que l'alimentation est suffisante (5V, 3A minimum)
- Vérifier que le SSD est correctement connecté
- Vérifier les LEDs du Raspberry Pi

### Impossible de se connecter en SSH

- Vérifier que SSH est activé dans les options de Raspberry Pi Imager
- Vérifier que le Raspberry Pi est sur le même réseau
- Vérifier le pare-feu du routeur

### Le SSD n'est pas détecté

- Vérifier que l'adaptateur USB-SATA est compatible USB 3.0
- Essayer un autre port USB sur le Raspberry Pi
- Vérifier que le SSD est correctement formaté

