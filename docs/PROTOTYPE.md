# Neon Catacombs — 1v1 Arena Prototype

Godot 4.6 first-person **knock-off duel** on a deadly **suspended bridge** over a **perceptual horror void**. Win by **ring-out** or by **breaking shield and killing** your opponent.

**Art direction:** see [ART_DIRECTION_VOID.md](ART_DIRECTION_VOID.md) — fear of falling, living abyss, kenophobia, void-as-entity.

## Game rules

| Rule | Detail |
|------|--------|
| Mode | Player vs **one AI opponent** |
| Win | First to **5 points** |
| Point | Opponent falls below **Y = -20** **or** opponent **health reaches 0** |
| Shield / Health | Both fighters start each round with **100 shield** and **100 health** |
| Damage order | Damage hits **shield first**; overflow reduces **health** |
| Round start | **3 → 2 → 1 → FIGHT!** countdown (1s per number, 0.7s for FIGHT!) |
| During countdown | Player and AI **frozen** — no move, no shoot |
| After point | Respawn both, reset shield/health, clear projectiles → new countdown |
| Void score | Ring-out below **Y = -20** — **2 s** fall, void burst effect, then +1 |
| Kill score | You kill AI → player +1; AI kills you → enemy +1 |

Spawns: **Player** south end `(0, 1.1, 10)`, **Enemy** north end `(0, 1, -10)` — face each other at round start.

## Bridge arena layout

Classic **pit-stage** bridge over a deep void (`scenes/main.tscn`):

| Feature | Detail |
|---------|--------|
| Walkable deck | **8 × 28** units (long narrow bridge) |
| Visuals | Dark stone/metal deck, raised trims, low side rails (no walls) |
| Props | End pillars, broken columns, surface cracks — decorative only |
| Pit | **No visible floor** — `VoidAtmosphere` fog layers, drift particles, abyss observers |
| Lighting | Cold directional sun, sparse steel rim lights (Quake-like industrial) |
| Ring-out | Fall below **Y = -20** on any side or end |

Gameplay stays readable: rails warn danger but do **not** block falls.

### AI bridge bounds (rectangular)

| Export | Value | Meaning |
|--------|-------|---------|
| `safe_half_x` | 3.2 | Steer inward from left/right |
| `danger_half_x` | 3.8 | Strong recovery near side edge |
| `safe_half_z` | 12.0 | Steer inward from bridge ends |
| `danger_half_z` | 13.5 | Strong recovery near bridge ends |

AI pushes you toward the **nearest** open edge (side or end), not only “away from center” on a circle.

## Round countdown

`GameManager` states: **COUNTDOWN** → **FIGHTING** → (point scored) **ROUND_OVER** → **COUNTDOWN** → … → **MATCH_OVER** at 5 points.

- Match start and after each point: respawn, clear stray projectiles, then countdown HUD (`3`, `2`, `1`, `FIGHT!`).
- After **FIGHT!** hides, combat runs until someone scores (void or kill).
- No countdown after match ends (win/lose screen only).
- Debug: `Round countdown started`, `FIGHT!`

## Scene hierarchy

```
Main
├── WorldEnvironment / SunLight / accent lights
├── PitVoid              — deep darkness below bridge
├── BridgeArena          — deck, trims, rails, cracks, pillars
├── GameManager + spawns
├── PushBox1             — center cover crate
├── ArenaOpponent / Player
└── UI
```

## AI opponent

`scenes/enemies/arena_opponent.tscn` + `scripts/enemies/arena_opponent.gd`

### States
- **ATTACKING** — normal arena fighter behavior
- **RECOVERING** (0.8–1.2s) — after heavy knockback or getting near the rim; moves to center, does not shoot

Debug: `Enemy state: ATTACKING` / `RECOVERING`, `Enemy avoiding edge`

### Arena awareness
- Rectangular bridge bounds (see table above)
- Counter-force if velocity drifts toward an open edge
- No forward chase while near sides/ends (anti-suicide)

### Combat movement
- Too close → retreat + light strafe
- Too far → advance (if safe) + strafe
- Mid range → circle-strafe with direction flips every **1–2 s**
- Never stands still (idle strafe if overlapping)

### Weapons (same stats as player)
- **Shotgun** — close range
- **Bazooka** — player near edge, ring-out angle, or medium range (not constant spam; ~38–55% roll)
- **Pistol** — long range
- Random weapon swap every **4–6 s** between tactical picks

### Ring-out tactics
- Prefers shots that push the player **away from arena center** (toward the void)
- More aggressive when the player is near the platform edge

### Low shield / health
- When its own shield ≤ **30** or health ≤ **40**, retreats and strafes more (slightly evasive)

## Combat stats

`scripts/combat_stats.gd` — child node on **Player** and **ArenaOpponent**:

- `apply_damage(amount, attacker)` — shield first, then health
- `reset_combat_stats()` — full restore at round start
- `is_dead()` — health ≤ 0 triggers a point for the attacker
- Debug: `Player shield: X health: Y` / `Enemy shield: X health: Y`

HUD (`arena_ui.gd`): `Player HP: … | Shield: …` and `Enemy HP: … | Shield: …`

### Death corpse feedback

On **health death** (not void ring-out):

1. Spawn `scenes/effects/physics_corpse.tscn` — a simple **RigidBody3D** capsule (mass **5**, damped spin).
2. Launch using the last hit’s **direction** and **force** from `CombatStats`, with per-weapon scaling on the corpse (`pistol` 0.45, `shotgun` 0.65, `bazooka_direct` 1.0, `bazooka_explosion` 1.1). Horizontal push is strong; upward speed is capped for plausible tumbling.
3. Hide the live fighter until the round respawns; **no instant respawn** on kill.
4. After **1.2 s**, award the point and run the normal **3-2-1-FIGHT** countdown.
5. Corpses are in group **`corpse`** (layer **8**, weapons ignore them); cleared at round start.

Debug: `Spawned player corpse` / `Spawned enemy corpse`, `Corpse final launch velocity: …`.

### Void death spectacle

When a fighter crosses **void_y** (`-20`):

1. Enter **`void_dying`** — controls/AI off, body keeps falling (**2 s**).
2. Player: camera falls with body; red void overlay + HUD (`PLAYER LOST TO THE VOID` / `ENEMY LOST TO THE VOID`).
3. Play void death VFX at pit position (style from `GameBalance.VOID_DEATH_STYLE` in `scripts/game_balance.gd`).
4. Award the point, hide the fighter, then normal **3-2-1-FIGHT** countdown.
5. Void effects and fragments cleared at round start (with corpses/projectiles).

`GameManager`: `report_player_void_fall()` / `report_enemy_void_fall()` → `finish_player_void_death()` / `finish_enemy_void_death()`.

#### Void death styles (`GameBalance.VoidDeathStyle`)

Change the active style in **`scripts/game_balance.gd`** → `VOID_DEATH_STYLE` (default **VOID_GORE**).

| Style | Effect |
|-------|--------|
| **DISINTEGRATE** | Blue/green/purple energy burst, expanding ring/sphere, cosmetic shards — no physics chunks |
| **EXPLODE** | Orange flash + **~10 physics fragments** (`void_fragment.tscn`) that tumble into the void |
| **GORE_PLACEHOLDER** | Stylized red/dark fragments only (placeholder, not anatomical) |
| **VOID_GORE** | Full cinematic pit sequence (see below) |

Debug: `Void death style: …`, `Void wind`, `Body rupture`, `Disintegration burst`.

#### VOID_GORE cinematic timeline

Fall → freefall → corruption → breakup → burst → **score** → countdown.

| Time | Event |
|------|--------|
| **0.0s** | Fall begins; loss of balance / slide; controls off |
| **0.35s** | Freefall — camera FOV **90→102**, shake ramps |
| **0.5s** | Ambient void motes; audio: `Void wind` |
| **1.2s** | Corruption gas cloud (`void_corruption_cloud.tscn`) — green/blue/purple fog, pulsing light |
| **1.6s** | Body hidden; **6–12** `gore_chunk.tscn` physics chunks + blood mist; debug: `Body rupture` |
| **2.0s** | Final disintegration burst; **point awarded**; debug: `Disintegration burst` |

Gore is stylized sci-fi corruption (dark red/black chunks), not anatomical. Chunks/effects cleared at round start.

## Weapons (player)

| Key | Weapon |
|-----|--------|
| **1** | Pistol — fast, light push |
| **2** | Shotgun — pellet spread |
| **3** | Bazooka — slow rocket + explosion push |
| **Left click** | Fire |

Projectiles apply **knockback and damage** (no self-damage from your own shots). Crates still take push only.

### Weapon damage (`weapon_defs.gd`)

| Weapon | Damage |
|--------|--------|
| Pistol | **12** per hit |
| Shotgun | **8** per pellet |
| Bazooka direct | **35** |
| Bazooka explosion | up to **45** (radius falloff) |

## Knockback (player + AI)

Same weapon **force** values for everyone, but delivery differs by body type:

| Target | Formula | Default multiplier |
|--------|---------|-------------------|
| **Player** | Horizontal `dir.xz * force * multiplier` + capped upward lift; velocity clamped after hit | **1.6** |
| **RigidBody3D** | `impulse = dir * force * mass * rigidbody_knockback_multiplier` | **0.6** |

Tuning lives in `scripts/weapons/weapon_defs.gd`:

- `PLAYER_KNOCKBACK_MULTIPLIER` — raise if the player still feels too light
- `RIGIDBODY_KNOCKBACK_MULTIPLIER` — lower if enemies/crates still launch too far
- `GROUNDED_UPWARD_KNOCKBACK_FACTOR` — default **0.10**; `AIRBORNE_UPWARD_KNOCKBACK_FACTOR` — **0.025**
- Horizontal speed caps: **45** grounded, **32** airborne
- Vertical velocity clamp after knockback: **-30 … 22**
- Shotgun: only the first pellet in a **0.1s** window adds vertical lift; other pellets still push horizontally

**Airborne knockback** is capped so repeated mid-air hits cannot stack unrealistic launch speed (Y velocity was reaching 49+ in debug). Debug log: `Player knockback clamped: velocity=... (grounded|airborne)`.

Enemy `ArenaOpponent`: mass **5.0**, `linear_damp` **0.6** (less floaty). Debug: compare clamped player velocity vs `RigidBody impulse applied`.

### Bazooka explosion vertical cap

Explosions use **mostly horizontal** push (ring-outs off the platform, not sky launches):

- `EXPLOSION_VERTICAL_FACTOR` (0.18), `EXPLOSION_MAX_UPWARD_FORCE` (18), `EXPLOSION_MAX_DOWNWARD_FORCE` (8)
- Horizontal blast uses full scaled force; vertical is computed separately and clamped
- Player vertical velocity clamped to **-30 … 22** after any knockback (including explosions)
- Direct bazooka rocket hits use a smaller vertical factor (`PROJECTILE_HIT_VERTICAL_FACTOR`)

## Balance tuning

| Location | What to tune |
|----------|----------------|
| `scripts/weapons/weapon_defs.gd` | Weapon `push_force` / `explosion_force` **and** knockback multipliers |
| → Pistol `push_force` | Default **22** |
| → Shotgun pellet `push_force` | Default **24** × 7 |
| → Bazooka `push_force` / `explosion_force` | Defaults **42** / **82** |
| `scripts/player.gd` (Inspector) | Optional overrides for player multipliers / max speed |
| `scripts/combat_stats.gd` | `max_health`, `max_shield` per fighter |

Raise `push_force` for more danger; adjust multipliers to keep player vs enemy knockback **fair**.

Projectiles store a **shooter** and ignore self-hits. Layer 2 projectiles, mask 1 (player + world).

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
