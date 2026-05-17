# Neon Catacombs — 1v1 Arena Prototype

Godot 4.6 first-person **knock-off duel** on a floating platform. No health — knock your opponent into the void to score.

## Game rules

| Rule | Detail |
|------|--------|
| Mode | Player vs **one AI opponent** |
| Win | First to **5 points** |
| Point | Opponent falls below **Y = -20** |
| After point | Both respawn at spawn points, velocities cleared (~0.35s delay) |
| Loss | You fall → enemy +1 (`Enemy scored!`) |
| Score | You knock AI off → player +1 (`Player scored!`) |

Spawns: **Player** south `(0, 1.1, 7)`, **Enemy** north `(0, 1, -7)`.

## Scene hierarchy

```
Main
├── GameManager          — scoring, respawns, match end
│   └── SpawnPoints (PlayerSpawn, EnemySpawn)
├── Floor + PlatformBorder
├── PushBox1             — optional center cover crate
├── ArenaOpponent        — AI duelist
├── Player
│   └── Camera3D / WeaponManager
└── UI                   — weapon, score, win/lose
```

## AI opponent

`scenes/enemies/arena_opponent.tscn` + `scripts/enemies/arena_opponent.gd`

- **Same weapons as the player** (Pistol / Shotgun / Bazooka) via shared `WeaponDefs` + `WeaponFiring`
- Visible enemy weapon models on `WeaponPivot` (`enemy_weapon_manager.tscn`)
- Movement: approach, retreat when too close, strafe at mid range
- **Range picks:** shotgun close (&lt; 5 m), bazooka medium (&lt; 12 m), pistol long
- Random weapon swap every **4–6 s** (debug: `Enemy switched to …`)
- Fires on cooldown with debug: `Enemy fired …`
- Pushed into void → player scores; respawns with you

## Weapons (player)

| Key | Weapon |
|-----|--------|
| **1** | Pistol — fast, light push |
| **2** | Shotgun — pellet spread |
| **3** | Bazooka — slow rocket + explosion push |
| **Left click** | Fire |

Push projectiles affect the AI, crates, and physics objects. No damage.

## HUD

- Top: `Player: 0 | Enemy: 0`
- Bottom: `Weapon: …`
- Center (on win): `You Win!` or `You Lose!`

## Controls

| Input | Action |
|-------|--------|
| WASD | Move |
| Mouse | Look |
| Space | Jump |
| Shift | Sprint |
| 1 / 2 / 3 | Weapons |
| Left click | Fire |
| Esc | Release mouse |
| Left click (cursor free) | Re-capture mouse |

## Run

Godot 4.6+ → **F5** → `res://scenes/main.tscn`

## Key scripts

```
scripts/game_manager.gd
scripts/enemies/arena_opponent.gd
scripts/enemies/enemy_weapon_manager.gd
scripts/arena_ui.gd
scripts/player.gd
scripts/weapons/weapon_defs.gd
scripts/weapons/weapon_firing.gd
scripts/weapons/weapon_manager.gd
```
