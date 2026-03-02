# 🕹️ ICOBS Pac-Man — FPGA Implementation

> Reproduction du jeu classique "Pac-Man" sur architecture FPGA, avec un processeur RISC-V (IBEX) et un contrôleur VGA personnalisé en VHDL.

**Polytech Montpellier — Synthèse des Systèmes Numériques | Tom Penfornis | SE 2024-2027**

---

## 📋 Table des matières

- [Présentation](#présentation)
- [Architecture Matérielle](#architecture-matérielle)
- [Architecture Logicielle](#architecture-logicielle)
- [Lien Logiciel / Matériel](#lien-logiciel--matériel)
- [Structure du repo](#structure-du-repo)
- [Utilisation](#utilisation)

---

## Présentation

Ce projet est le livrable final du cours **Synthèse des Systèmes Numériques** à Polytech Montpellier. L'objectif était de concevoir et implémenter un système embarqué complet sur FPGA :

- Un processeur **RISC-V IBEX** soft-core
- Un périphérique **contrôleur VGA** personnalisé (esclave AHB-Lite)
- Un jeu **Pac-Man** écrit en C, exécuté sur le soft-core

Le jeu s'affiche sur un écran VGA 640×480 et supporte :
- Déplacement du Pac-Man via boutons poussoirs
- 3 fantômes ennemis autonomes avec navigation dans le labyrinthe
- Collecte de gommes avec affichage du score sur les 7-segments
- Détection des collisions (murs, fantômes)
- Écran de victoire et Game Over

---

## Architecture Matérielle

Le matériel est implémenté sur FPGA avec Vivado. Voici l'architecture globale :
```
┌──────────────────────────────────────────────────────────────────┐
│                            FPGA (Basys3)                         │
│                                                                  │
│   ┌─────────────┐     Bus OBI      ┌──────────────────────────┐  │
│   │  IBEX Core  │◄────────────────►│     MCU Interconnect     │  │
│   │  (RISC-V)   │                  │    Crossbar (OBI→AHB)    │  │
│   └─────────────┘                  └───────────┬──────────────┘  │
│                                                │                 │
│                         ┌──────────────────────┼──────────────┐  │
│                   Bus AHB-Lite                 │              │  │
│            ┌────────────┴──────┐   ┌───────────┴──────┐       │  │
│            │   GPIO (A/B/C)    │   │   AHBlite VGA    │       │  │
│            │  ┌─────────────┐  │   │ (ahblite_vga.vhd)│       │  │
│            │  │  Boutons P0 │  │   └───────────┬──────┘       │  │
│            │  │  Boutons P1 │  │               │              │  │
│            │  │  Boutons P2 │  │   ┌───────────▼──────────┐   │  │
│            │  │  Boutons P3 │  │   │    VGA Controller    │   │  │
│            │  └─────────────┘  │   │    640x480 @ 60Hz    │   │  │
│            └───────────────────┘   │                      │   │  │
│                                    │  ┌────────────────┐  │   │  │
│   ┌───────────────────────────┐    │  │  Sprite ROMs   │  │   │  │
│   │     7-Seg Display (x4)    │    │  │  (x6 PROMs)    │  │   │  │
│   │  Score BCD sur 4 chiffres │    │  │  Pac-Man       │  │   │  │
│   └───────────────────────────┘    │  │  Fantômes x3   │  │   │  │
│                                    │  │  Win / GameOver│  │   │  │
│                                    │  └────────────────┘  │   │  │
│                                    └───────────┬──────────┘   │  │
└────────────────────────────────────────────────┼──────────────┘  │
                                                 │
                                      ┌──────────▼──────────┐
                                      │    Moniteur VGA     │
                                      │    640 × 480 px     │
                                      └─────────────────────┘```

### Modifications apportées à l'architecture de base

1. **Gestion Multi-Sprites** : 6 sprites gérés simultanément (Pac-Man, 3 fantômes, éléments de décor) via des PROMs et registres de coordonnées dédiés.
2. **Moteur de Rendu (`VGA_Basic_ROM`)** : Priorité d'affichage `Sprite > Mur > Gomme > Fond`
3. **Accélération Matérielle** : Les murs et les gommes sont générés directement par le matériel via une grille logique interne, sans surcharger le processeur.
4. **Reset Hybride** : Le bit 31 du registre `background_color` déclenche un reset matériel des gommes depuis le logiciel.

### Registres VGA (base : 0x11024000)

| Registre           | Offset  | Description                      |
|--------------------|---------|----------------------------------|
| `background_color` | 0x00    | Couleur de fond / reset gommes   |
| `X1_pos`, `Y1_pos` | 0x01/02 | Position Pac-Man                 |
| `X2_pos`, `Y2_pos` | 0x03/04 | Position Fantôme 1               |
| `X3_pos`, `Y3_pos` | 0x05/06 | Position Fantôme 2               |
| `X4_pos`, `Y4_pos` | 0x07/08 | Sprite écran victoire            |
| `X5_pos`, `Y5_pos` | 0x09/0A | Sprite Game Over                 |
| `X6_pos`, `Y6_pos` | 0x0B/0C | Position Fantôme 3               |

---

## Architecture Logicielle

Le logiciel est écrit en C et s'exécute sur le processeur IBEX. Il est structuré autour d'une **boucle de jeu infinie** :

1. **Vérification de l'état** : victoire (toutes les gommes mangées) ou défaite (collision fantôme)
2. **Physique du joueur** : lecture des boutons via GPIOC, calcul position, validation via `check_collision()`
3. **Gestion des gommes** : incrémentation du score, désactivation de la gomme, affichage sur 7-segments
4. **IA des fantômes** : à chaque intersection, scan des directions valides, choix aléatoire sans demi-tour
5. **Rendu** : mise à jour des registres VGA

### Contrôles (boutons poussoirs)

| Bouton | Action    |
|--------|-----------|
| P0     | Monter    |
| P3     | Descendre |
| P1     | Gauche    |
| P2     | Droite    |

### Règles du jeu

- Naviguer dans un labyrinthe de 20×15 tuiles
- Collecter toutes les gommes pour **gagner**
- Éviter les 3 fantômes — une collision déclenche le **Game Over** (flash rouge + restart)
- Le tunnel à la ligne 7 permet le téléportation gauche ↔ droite

---

## Lien Logiciel / Matériel

La communication entre C et VHDL repose sur la **mémoire mappée** via le bus AHB-Lite.

### Exemple : Déplacement du fantôme n°2

**1. Côté logiciel (C) :**
```c
VGA_PTR->X2_pos = ghost2.x;
// VGA_PTR pointe sur 0x11024000
// X2_pos = offset 0x03
// → écriture de ghost2.x à l'adresse 0x11024003
```

**2. Bus AHB :** `HADDR=0x11024003`, `HWDATA=ghost2.x`, `HWRITE=1`

**3. Côté matériel (`ahblite_vga.vhd`) :**
```vhdl
when x"03" => X2_pos <= SlaveIn.HWDATA;
```
Le registre `X2_pos` est lu par `VGA_Basic_ROM` à chaque rafraîchissement pour positionner le sprite.
```
Calcul C → Écriture Bus AHB → Registre VHDL → Affichage (60 Hz)
```

---

## Structure du repo
```
ICOBS-PacMan/
│
├── README.md
│
├── hardware/
│   └── vhdl/
│       ├── VGA/                 # Contrôleur VGA (640x480, sprites, ROM)
│       ├── AHBLITE/             # Périphériques AHB (VGA, GPIO, UART, Timer, 7SEG)
│       ├── IBEX/                # Cœur processeur RISC-V IBEX + fichiers SHARED
│       ├── MCU/                 # Interconnexion MCU (crossbar OBI→AHB)
│       ├── OBI/                 # Bus OBI (arbitre, décodeur, ponts)
│       ├── 7SEG/                # Afficheur 7 segments (score)
│       ├── LIB/                 # Librairies VHDL (AMBA3, constantes)
│       ├── ICOBS_light_TOP.vhd  # Top level du design
│       └── Basys3-Master.xdc    # Contraintes FPGA (Basys3)
│
├── software/
│   ├── src/
│   │   ├── main.c               # Logique du jeu Pac-Man
│   │   └── system.h             # Configuration système
│   ├── lib/
│   │   ├── arch/                # Headers architecture (GPIO, VGA, UART...)
│   │   ├── libarch/             # Drivers Timer et UART
│   │   └── misc/                # Utilitaires (print, types)
│   ├── output/                  # Fichiers compilés (.hex, .elf, .bin)
│   ├── makefile                 # Système de build (cross-compiler RISC-V)
│   ├── link.ld                  # Script linker
│   └── crt0.S                   # Fichier de démarrage assembleur
│
└── docs/
    └── rapport.pdf              # Rapport du projet
```

---

## Utilisation

### Prérequis

- **Vivado** (synthèse et génération du bitstream)
- **RISC-V GCC toolchain** (`riscv32-unknown-elf-gcc`)
- Carte FPGA **Basys3**
- Moniteur VGA

### 1. Programmer le FPGA
```bash
# Via Vivado Hardware Manager
# Open hardware manager → Auto Connect → Program Device
# Sélectionner : hardware/output/ICOBS_light_TOP.bit
```

### 2. Compiler le logiciel
```bash
cd software
make all
# Sortie : output/demo-icobs-light.hex
```

> Pour installer la toolchain RISC-V : `source install_riscv_toolchain.sh`

### 3. Charger le jeu

Utiliser le bootloader (UART) pour envoyer `output/demo-icobs-light.hex` sur la carte.

---

## Auteur

**Tom Penfornis** — Polytech Montpellier  
Synthèse des Systèmes Numériques — SE 2024-2027  
Encadrant : Pascal Benoit
