# FNAF World TCG

![Godot](https://img.shields.io/badge/Godot-4.7.1-blue?logo=godotengine&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey)
![License](https://img.shields.io/badge/license-MIT%20(code%20only)-green)

A trading card game built with Godot Engine, inspired by FNAF World. Play against a simple AI or challenge another player over your local network.

> Developed as an undergraduate thesis project (TCC) for the Computer Science program at Universidade Federal de Alagoas.

---

## About

FNAF World TCG is a non-commercial, non-profit fangame inspired by FNAF World, created by Scott Cawthon. It was built as the practical component of an undergraduate thesis documenting the full game development process, from requirements gathering to implementation.

The game features 42 unique cards: 36 entity cards split across four color groups, and 6 skill cards. Matches are quick and aggressive by design, usually resolving within a handful of turns.

---

## How to Play

1. Download the latest `.exe` from the [Releases](../../releases) page
2. Run it. No installation required.

**Requirements:** Windows, ~152 MB of disk space.

---

## Game Modes

### AI Mode
Play solo against a simple AI opponent. The AI draws cards, places entities prioritizing higher attack values, uses one skill per turn, and attacks whenever it has cards on the field.

### PvP Mode
Play against another person over a local network using a peer-to-peer connection.

- One player hosts, the other joins
- Host discovery is automatic. No IP address needed
- Both machines must be on the same local network
- Works through LAN-simulating VPNs (tested with Radmin VPN)

You can also run two instances on the same machine to test PvP, though only one instance per machine can host.

---

## Rules

**Setup.** Both players draw 7 cards. A coin flip decides who goes first.

**Placing cards.** Each side of the field has four colored slots, one per color group. A card can only be placed in a slot matching its own color, limiting the field to four entities per player. Skill cards go into a separate slot.

**Drawing.** Each player can draw up to 3 cards per turn, with a maximum hand size of 7.

**Combat.** Pressing Attack resolves all your entities at once. Each card looks for an enemy card of the same color:
- **Match found** → both cards deal damage to each other. Any card reduced to 0 health is destroyed and sent to the graveyard.
- **No match** → the attack goes straight to the opponent's life points.

**Skills.** Six skills, adapted from attacks in FNAF World:

| Skill | Effect |
|---|---|
| Pizza Wheel | 1 damage to all enemy cards |
| Pizza Wheel 2 | 2 damage to all enemy cards |
| 4th Wall | 3 damage to all enemy cards |
| Mega Bite | 3 damage to a random enemy card |
| Jack-O-Bomb | 1–3 damage, twice, to a random enemy card |
| Slasher | 10% chance to instantly end the match |

**Winning.** Reduce your opponent's life from 20 to 0. If both players run out of cards, the player with more life wins; equal life is a draw.

---

## Running the Project

### Assets are not included

This repository contains **source code only**. The `Assets/` folder is excluded, since the project uses third-party and ripped assets that are not mine to redistribute.

To run the project from source, you will need to recreate `Assets/` using the sources listed under [Credits](#credits). Without it, the project will open in Godot but fail to load textures, audio, and fonts.

If you just want to play, grab the executable from [Releases](../../releases) instead.

### Steps

1. Install [Godot Engine 4.7.1](https://godotengine.org/download)
2. Clone this repository
3. Recreate the `Assets/` folder from the credited sources
4. Open `project.godot` in Godot

---

## Project Structure

```
├── Config/              # Autoloads (game state, audio, input handling)
├── Game/
│   ├── Scripts/         # Gameplay logic
│   │   └── Skills/      # One script per skill
│   ├── Card.tscn        # Card scene
│   ├── CardPlacement.tscn
│   ├── FieldSkills.tscn # Full-field skill animations
│   ├── PlayerSide.tscn  # Player's half of the board
│   ├── OppSide.tscn     # Opponent's half
│   ├── Duel.tscn        # AI match scene
│   └── DuelPVP.tscn     # PvP match scene
├── UI/                  # Menus and interface scenes
└── Assets/              # NOT INCLUDED (see above)
```

### Key Scripts

| Script | Responsibility |
|---|---|
| `card_database.gd` | Dictionary defining all 42 cards |
| `card_factory.gd` | Instantiates cards from database entries |
| `deck.gd` | Deck, drawing, and draw synchronization |
| `hand.gd` | Hand layout and fan effect |
| `field_manager.gd` | Card placement and skill result relaying |
| `duel_manager_ai.gd` | Turn flow, combat, and AI behavior |
| `duel_manager_pvp.gd` | Turn flow and combat with RPC synchronization |
| `pvp_mode_selection.gd` | Host discovery and P2P connection setup |

---

## Credits

**Character and skill sprites** ripped from FNAF World (originally created by Scott Cawthon), obtained via [The Spriters Resource](https://www.spriters-resource.com/pc_computer/fnafworld/).

**Sound effects** ripped from FNAF World, obtained via [The Sounds Resource](https://sounds.spriters-resource.com/pc_computer/fnafworld/asset/541312/).

**Original soundtrack** composed by Leon Riskin, obtained via [KHInsider](https://downloads.khinsider.com/game-soundtracks/album/five-nights-at-freddy-s-world-fnaf-world-soundtrack).

**Smoke effect** by BDragon1727, from [Free Smoke Fx Pixel 2](https://bdragon1727.itch.io/free-smoke-fx-pixel-2).

**Card assets** (background, color, border, icons) by cafeDraw, from [Fantasy Card Assets](https://cafedraw.itch.io/fantasy-card-assets).

**UI icons** by [Kenney](https://kenney.nl) — [Game Icons](https://kenney.nl/assets/game-icons) and [Board Game Icons](https://kenney.nl/assets/board-game-icons).

**Font:** Orbitron by Matt McInerney, via [Google Fonts](https://fonts.google.com/specimen/Orbitron).

Built with [Godot Engine](https://godotengine.org).

---

## Disclaimer

This is a non-commercial, non-profit fangame inspired by FNAF World, created by Scott Cawthon. All Five Nights at Freddy's characters, names, and related media are property of Scott Cawthon. This project is not affiliated with, endorsed by, or sponsored by Scott Cawthon or Steel Wool Studios.
