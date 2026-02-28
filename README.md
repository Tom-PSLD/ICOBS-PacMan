# 🕹️ ICOBS Pac-Man — FPGA Implementation

> A Pac-Man game running on a RISC-V soft-core processor (IBEX) on FPGA, with a custom VGA controller written in VHDL and the game logic written in C.

**ENSIBS — ICOBS Project | Tom Penfornis**

---

## 📋 Table of Contents

- [Overview](#overview)
- [Hardware Architecture](#hardware-architecture)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
- [Game Description](#game-description)
- [Software / Hardware Interface](#software--hardware-interface)
- [Deliverables](#deliverables)

---

## Overview

This project is the final deliverable of the **ICOBS** (Intégration de Composants et Objets sur Silicium) lab course. The goal was to design and implement a complete embedded system from scratch on an FPGA board, featuring:

- A **RISC-V IBEX** soft-core processor
- A custom **VGA controller** peripheral (AHB-Lite bus slave)
- A **Pac-Man** video game written in C, running on the soft-core

The game displays on a 640×480 VGA screen and supports:
- Player-controlled Pac-Man (via push buttons)
- 3 autonomous ghost enemies with maze navigation logic
- Dot collection and score display on 7-segment displays
- Collision detection (walls, ghosts)
- Win/Game Over screen management

---

## Hardware Architecture

The hardware is implemented on the FPGA using Vivado. Key components:

```
┌──────────────────────────────────────────────────────┐
│                     FPGA                            │
│                                                      │
│  ┌──────────┐   AHB-Lite Bus   ┌──────────────────┐ │
│  │  IBEX    │◄────────────────►│  AHBlite VGA     │ │
│  │ RISC-V   │                  │  Peripheral      │ │
│  │ Core     │◄────────────────►│  (ahblite_vga)   │ │
│  └──────────┘   AHB-Lite Bus   └────────┬─────────┘ │
│       │                                 │            │
│  ┌────┴──────┐                ┌─────────▼─────────┐ │
│  │  GPIO     │                │  VGA Controller   │ │
│  │ (Buttons/ │                │  640x480 @60Hz    │ │
│  │ Switches) │                │  + Sprite ROMs    │ │
│  └───────────┘                └─────────┬─────────┘ │
│                                         │            │
│                               ┌─────────▼─────────┐ │
│                               │  7-Seg Display    │ │
│                               │  (Score)          │ │
│                               └───────────────────┘ │
└──────────────────────────────────────────────────────┘
                                         │
                                    VGA Monitor
```

### VGA Peripheral Registers

The VGA peripheral is memory-mapped and controlled via these registers (accessible from C via the `VGA_t` struct):

| Register           | Description                          |
|--------------------|--------------------------------------|
| `background_color` | Background / flash color control     |
| `X1_pos`, `Y1_pos` | Pac-Man position                     |
| `X2_pos`, `Y2_pos` | Ghost 1 (Blinky) position            |
| `X3_pos`, `Y3_pos` | Ghost 2 (Pinky) position             |
| `X4_pos`, `Y4_pos` | Win screen sprite position           |
| `X5_pos`, `Y5_pos` | Game Over sprite position            |
| `X6_pos`, `Y6_pos` | Ghost 3 (Clyde) position             |

---

## Repository Structure

```
ICOBS-PacMan/
│
├── README.md
│
├── hardware/
│   └── vhdl/
│       ├── ahblite_vga.vhd          # AHB-Lite VGA peripheral (main custom IP)
│       ├── VGA_640_x_480.vhd        # VGA timing controller (640x480 @ 60Hz)
│       ├── VGA_Basic_ROM.vhd        # Sprite ROM (Pac-Man, ghosts, etc.)
│       ├── VGA_Generic_Package.vhd  # Constants and types package
│       └── ICOBS_light_PROJECT_DIR.xpr  # Vivado project file
│
├── software/
│   └── demo-icobs-light-project/
│       ├── src/
│       │   ├── main.c               # Game logic (Pac-Man)
│       │   └── system.h             # System configuration header
│       ├── lib/
│       │   ├── arch/                # Architecture-specific headers (GPIO, VGA, UART...)
│       │   ├── libarch/             # Timer and UART drivers
│       │   └── misc/                # Print, types utilities
│       ├── makefile                 # Build system (RISC-V cross-compiler)
│       ├── link.ld                  # Linker script
│       └── crt0.S                   # Startup assembly
│
├── output/
│   ├── ICOBS_light_TOP.bit          # FPGA bitstream (includes bootloader)
│   └── demo-icobs-light.hex         # Compiled game executable
│
└── docs/
    └── rapport.pdf                  # Project report (hardware diagram, flowchart)
```

---

## Getting Started

### Prerequisites

- **Vivado** (for FPGA synthesis and bitstream generation)
- **RISC-V GCC toolchain** (`riscv32-unknown-elf-gcc`)
- Compatible FPGA board (Nexys A7 / Basys 3 or equivalent)
- VGA monitor

### 1. Program the FPGA

Load the bitstream onto the FPGA using Vivado or `openFPGALoader`:

```bash
# Via Vivado Hardware Manager
# Open hardware manager → Auto Connect → Program Device
# Select: output/ICOBS_light_TOP.bit
```

### 2. Build the Software

```bash
cd software/demo-icobs-light-project
make
# Output: output/demo-icobs-light.hex
```

> To install the RISC-V toolchain: `bash install_riscv_toolchain.sh`

### 3. Load the Game

Use the bootloader (UART) to upload the `.hex` file to the board, then start the game.

---

## Game Description

The game is a Pac-Man clone adapted to the hardware constraints of the FPGA system.

### Controls (Push Buttons)

| Button | Action      |
|--------|-------------|
| P0     | Move Up     |
| P3     | Move Down   |
| P1     | Move Left   |
| P2     | Move Right  |

### Rules

- Navigate Pac-Man through a 20×15 tile maze
- Collect all dots to **win**
- Avoid 3 ghosts — touching one triggers **Game Over** (red flash + restart)
- Score is displayed in real-time on the **7-segment displays**
- The tunnel at row 7 wraps around (left ↔ right teleport)

### Ghost AI

Each ghost navigates the maze autonomously using a grid-aligned movement system:
- At each tile intersection, valid directions are computed (no walls)
- A random direction is chosen, **avoiding U-turns** when alternatives exist
- Fallback to U-turn only in dead ends

---

## Software / Hardware Interface

The link between software and hardware is done through **memory-mapped I/O** on the AHB-Lite bus.

For example, to move Pac-Man to position (x=128, y=96):

```c
#define VGA_BASE 0x...          // Base address of VGA peripheral
#define VGA_PTR  ((VGA_t *) VGA_BASE)

VGA_PTR->X1_pos = 128;
VGA_PTR->Y1_pos = 96;
```

The VHDL peripheral (`ahblite_vga.vhd`) exposes these registers on the AHB-Lite bus. A write to `X1_pos` from the C code triggers a bus transaction that updates the sprite position register in the FPGA, which is then read by the VGA controller on every frame to render the sprite at the correct pixel coordinates.

---

## Deliverables

| File | Description |
|------|-------------|
| `output/ICOBS_light_TOP.bit` | FPGA bitstream with bootloader |
| `output/demo-icobs-light.hex` | Game executable |
| `hardware/vhdl/*.vhd` | All custom/modified VHDL sources |
| `software/demo-icobs-light-project/src/` | C source code |
| `docs/rapport.pdf` | Project report |

---

## Author

**Tom Penfornis** — ENSIBS  
ICOBS Project — 2025/2026
