# Préparation du matériel

## Matériel nécessaire

### Composants requis

1. **Raspberry Pi 4** (4 Go minimum recommandé)
   - [Acheter sur Amazon](https://www.amazon.fr/Raspberry-Pi-4595-modèles-Go/dp/B09TTNF8BT)
   - Modèle 4 Go ou 8 Go recommandé

2. **SSD SATA** (minimum 64 Go recommandé)
   - [Lexar SSD SATA 240 Go](https://www.amazon.fr/Lexar-Lecture-Ordinateur-Portable-LNQ100X240G-RNNNG/dp/B0BJKPZGQK)
   - Un SSD améliore considérablement les performances par rapport à une carte SD

3. **Adaptateur USB vers SATA**
   - [Adaptateur USB 3.0 vers SATA](https://www.amazon.fr/dp/B07F7WDZGT)
   - Nécessaire pour connecter le SSD au Raspberry Pi

4. **Alimentation**
   - Alimentation officielle Raspberry Pi 4 (5V, 3A minimum)
   - Important pour la stabilité du système

5. **Câble Ethernet**
   - Pour la connexion réseau (recommandé pour la stabilité)

6. **Carte microSD** (optionnelle, pour l'installation initiale)
   - Minimum 8 Go, classe 10

## Préparation du SSD

### Étape 1 : Brancher le SSD à l'adaptateur USB

1. Connecter le SSD SATA à l'adaptateur USB-SATA
2. Brancher l'adaptateur à votre ordinateur via USB

### Étape 2 : Vérifier la détection

Sur Windows :
- Ouvrir le Gestionnaire de disques
- Vérifier que le SSD est détecté

Sur Linux/Mac :
```bash
lsblk  # Linux
diskutil list  # Mac
```

## Logiciel nécessaire

### Raspberry Pi Imager

Télécharger et installer **Raspberry Pi Imager** depuis le site officiel :

- **Site officiel** : [https://www.raspberrypi.com/software/](https://www.raspberrypi.com/software/)
- **Documentation française** : Disponible sur le site officiel

#### Installation

**Windows :**
- Télécharger l'installateur `.exe`
- Exécuter l'installateur et suivre les instructions

**macOS :**
- Télécharger le fichier `.dmg`
- Ouvrir le fichier et glisser l'application dans Applications

**Linux :**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install rpi-imager

# Ou télécharger depuis le site officiel
```

## Vérification avant installation

Avant de procéder à l'installation de l'OS, vérifier :

- [ ] SSD correctement connecté et détecté
- [ ] Raspberry Pi Imager installé
- [ ] Alimentation Raspberry Pi disponible
- [ ] Câble Ethernet disponible
- [ ] Carte microSD (si nécessaire pour l'installation initiale)

## Prochaines étapes

Une fois le matériel préparé, passer à l'[installation de l'OS](os-installation.md).

