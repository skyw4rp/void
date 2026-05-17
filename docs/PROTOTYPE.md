# Neon Catacombs — 1v1 Arena Prototype

Godot 4.6 first-person **knock-off duel** across **large suspended arenas** over an **infinite toxic void**. Each round picks a spacious layout with protected perimeters, intentional fall openings, and central cover. Win by **ring-out** or by **breaking shield and killing** your opponent.

**Art direction:** [art/ART_DIRECTION.md](art/ART_DIRECTION.md) (canonical) · [ART_DIRECTION_VOID.md](ART_DIRECTION_VOID.md) (prototype implementation index) · [docs index](README.md)

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
| After point | Pick new arena → clear FX/debris → spawn cover → respawn at arena markers → countdown |
| Arena pick | **Random** each round (won’t repeat the same arena name back-to-back) |
| Void score | Ring-out below **Y = -20** — **VOID_GORE** cinematic (~**3.2 s**) or legacy fall + burst, then +1 |
| Kill score | You kill AI → player +1; AI kills you → enemy +1 |

Spawns are **generated and validated** each round (not hand-placed in the scene). Debug: `Round arena selected: …`, `Spawn validation passed` / `Spawn invalid, regenerating arena`.

## Toxic void world

Shared backdrop (`VoidAtmosphere`, `VoidDistantArchitecture`) with **one procedurally built arena** per round from `ArenaGenerator` (`scenes/arena/arena_generator.tscn`).

| Environment | Detail |
|-------------|--------|
| Sky / fog | Light haze on deck; **dense gas starts ~Y -18** (below arena); collapse on fall |
| Void death | **Y < -32** (`GameBalance.VOID_DEATH_Y`); warning band from **-18** |
| `VoidAtmosphere` | Layered gas (upper / deep / corruption haze), ash particles, depth-driven density |
| `VoidGasController` | World fog + vignette + desaturation + DOF blur by fall depth |
| `VoidDistantArchitecture` | Distant ruins, towers, chains in fog |
| Ring-out | **Y < -20** — intentional gaps between platforms, not accidental wide edges |

## ArenaGenerator (`scripts/arena/arena_generator.gd`)

Each countdown:

1. **Clear** previous floor (`ActiveArena` children), debris, projectiles, corpses, gibs.
2. **Pick** a template from `ArenaTemplates` (won’t repeat the same name back-to-back).
3. **Build** floors + walls + **outer perimeter** (~60–80% protected) + **fall zone markers** (cracked edge, void glow).
4. **Validate spawns** — raycast down from player/enemy template XZ; require floor hit on layer **1**; place fighters at `floor_y + 1.0`, facing each other.
5. If invalid → `Spawn invalid, regenerating arena` (up to 6 attempts, then Toxic Bridge fallback).
6. Spawn **5–9** destructible cover pieces on **raycast-validated** floor points.
7. Respawn fighters at validated transforms; pass `get_current_arena_bounds()` to AI.

### Arena templates (`scripts/arena/arena_templates.gd`)

**24×24 – 32×32** main decks, **6+ unit** bridges/corridors — intentional holes only (no random micro-gaps).

| ID | Name | Layout |
|----|------|--------|
| `BROKEN_REACTOR` | Broken Reactor | C-walkway around **12×12** central pit |
| `TOXIC_BRIDGE` | Toxic Bridge | **14×14** twins + **6×10** bridge |
| `SPLIT_PLATFORMS` | Split Platforms | **13×20** decks + **6×4** catwalks |
| `RUINED_COURTYARD` | Ruined Courtyard | Ring around **14×14** pit + corner pads |
| `HANGING_CORRIDORS` | Hanging Corridors | **6×28** parallel lanes + end bridges |

Each template: `spawn_safe_half`, `fall_zones[]`, `perimeter.ringout_open_sides`, `void_y` (**-32**).

### Outer perimeter (`scripts/arena/arena_perimeter_builder.gd`)

- Procedural **partial shell** around danger bounds + margin
- Piece types: full ruined wall, half wall, collapsed, cracked pillar, hanging panel
- **Decor-only** corner towers and distant breakwall silhouettes (no collision)
- Destructible panels: `arena_perimeter_panel.gd` — `damage_cover()`, fragments on break
- Groups: `arena_wall`, `arena_perimeter` (AI cover), `arena_perimeter_decor` (visual only)

**Adding a template:** implement a builder in `arena_templates.gd`, add to `get_playable_ids()`, deck top at **local y = 0** (`slab` helper: center y = `-thickness/2`).

### Debug markers

`ArenaGenerator.debug_show_markers` (default **true**): green sphere = player spawn, red = enemy, blue = danger bounds corners.

### AI integration

`ArenaOpponent.apply_arena_bounds_from_dict()` ← bounds each respawn. AI uses **cover** (`arena_wall` LOS breaks), **hole raycasts** (`has_floor_at` / `is_floor_ahead`), railgun at range, shotgun when blocked or close.

## Destructible cover (`DebrisSpawner`)

Each countdown (including match start):

1. Clear **`round_debris`** and **`round_debris_fragment`** from the previous round.
2. Spawn **5–9** large `debris_chunk.tscn` cover pieces in the **active arena’s** debris zone (per-arena local X/Z rect), spread apart.
3. Cover types (random): **BLOCK**, **WALL_SLAB** (tall LOS blocker), **BROKEN_PILLAR**, **FALLEN_BEAM** — each with its own scale, mass, material, and rotation.
4. Spawn avoids player/enemy spawns (~**3.8** u) and limits pieces in the narrow center lane so at least one route around stays open.
5. **Health** per type: Block **60**, Wall slab **100**, Pillar **80**, Beam **70**. Railgun, shotgun, and bazooka apply damage via `damage_cover()`; bazooka explosions deal extra damage.
6. At **0 HP**: piece breaks into **4–8** small fragments (`round_debris_fragment`, **4–6 s** lifetime) then the cover is removed.
7. Cover blocks physical shots and line of sight; weapons still apply knockback. Pieces can be pushed and knocked into the void.

Debug: `Cover health: …`, `Cover destroyed: …`, `Spawned N destructible cover pieces…`

`scenes/props/debris_chunk.tscn` · `scenes/props/debris_fragment.tscn` · `scripts/props/debris_spawner.gd` · layer **1**, not used for scoring.

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
├── VoidAtmosphere / VoidDistantArchitecture
├── ArenaGenerator       — procedural floor + spawn validation + DebrisSpawner
├── GameManager
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
- Rectangular bounds from `ArenaGenerator.get_current_arena_bounds()`
- Counter-force if velocity drifts toward an open edge
- No forward chase while near sides/ends (anti-suicide)

### Combat movement
- Too close → retreat + light strafe
- Too far → advance (if safe) + strafe
- Mid range → circle-strafe with direction flips every **1–2 s**
- Never stands still (idle strafe if overlapping)

### Weapons (same stats as player)
- **Shotgun** — close range spread pressure (large readable pellets)
- **Bazooka** — medium / ring-out (~26–40% pick); slower cadence; direct hit is lethal but not spammed
- **Railgun** — long range; one hit breaks shield, second hit kills; strong edge knockback
- Random weapon swap every **4–6 s** between tactical picks

### Ring-out tactics
- Prefers shots that push the player **away from arena center** (toward the void)
- More aggressive when the player is near the platform edge

### Low shield / health
- When its own shield ≤ **30** or health ≤ **40**, retreats and strafes more (slightly evasive)

## Combat stats

`scripts/combat_stats.gd` — child node on **Player** and **ArenaOpponent**:

- `apply_damage(amount, attacker)` — shield first, then health
- Tracks **`last_damage_amount`**, **`overkill_amount`** (abs health when health goes negative), **`last_damage_source`**, last hit direction/force
- `is_heavy_death()` — rocket direct/explosion, overkill ≥ **25**, or last hit ≥ **40** damage
- `reset_combat_stats()` — full restore at round start
- `is_dead()` — health ≤ 0 triggers a point for the attacker
- Debug: `Player shield: X health: Y` / `Enemy shield: X health: Y`

HUD (`arena_ui.gd`): `Player HP: … | Shield: …` and `Enemy HP: … | Shield: …`

### Health death (kill, not void)

After the death spectacle, the point is awarded and the normal **3-2-1-FIGHT** countdown runs: **2.5 s** for normal kills (`KILL_DEATH_VIEW_SEC`), **1.8–2.2 s** for heavy collapse (`gib_collapse_score_sec()`). Debug: `Death sequence finished, scoring`.

#### Normal death (railgun / shotgun / light hits)

1. Spawn `scenes/effects/physics_corpse.tscn` — **RigidBody3D** capsule (mass **5**, damped spin).
2. Launch using last hit **direction** and **force** from `CombatStats`, with per-weapon scaling (`railgun` 0.55, `shotgun` 0.65, `bazooka_direct` 1.0, `bazooka_explosion` 1.1). Horizontal push is strong; upward speed is capped.
3. Hide the live fighter until respawn.
4. Corpses: group **`corpse`**, layer **8** — weapons/scoring ignore them; cleared at round start.

Debug: `Spawned player corpse` / `Spawned enemy corpse`, `Enemy corpse spawned`.

#### Heavy death (rocket / overkill) — fast collapse

Triggered when `CombatStats.is_heavy_death()` is true:

- `last_damage_source` is **`bazooka_direct`** or **`bazooka_explosion`**
- **`overkill_amount` ≥ 25** (health went far below zero on the killing blow)
- **`last_damage_amount` ≥ 40** on the killing hit

1. Brief red flash + shock ring (`VoidDeathEffect.play_collapse_flash`).
2. **0.1 s** pause, then **10–18** `gib_chunk.tscn` pieces spawn **clustered** at the death point (offset radius ≤ **0.45**).
3. Chunks use **low horizontal/upward impulse**, strong **linear/angular damp**, and mostly **fall downward** — a fast body collapse, not a far-flinging explosion. Only ~18% pop slightly upward.
4. Dark blood mist at center; chunks tumble nearby, then despawn after **3–4 s**.
5. Hide live fighter; **no full corpse**. Score after **1.8–2.2 s** (`GameBalance.gib_collapse_score_sec()`); normal kills still use **2.5 s**.
6. Gibs: group **`gib_chunk`**, layer **8** — weapons ignore them; cleared at round start.
7. **Player** heavy kill: screen shake, camera stays active, HUD **`YOU WERE OBLITERATED`**.
8. **Enemy** heavy kill: debug `Enemy gibbed by rocket`.

Tuning lives in `game_balance.gd` (`GIB_HORIZONTAL_FORCE_*`, `GIB_UPWARD_FORCE_*`, `GIB_LINEAR_DAMP`, etc.).

Debug: `Gib collapse spawned X chunks`, `Gib collapse finished`, `Death sequence finished, scoring`.

Gib chunks and corpses are cleared at round start with projectiles/void effects.

### Void death spectacle

When a fighter crosses **void_y** (**-32**):

1. Enter **`void_dying`** — controls/AI off, body keeps falling.
2. Player: camera falls with body; red void overlay + HUD (`PLAYER LOST TO THE VOID` / `ENEMY LOST TO THE VOID`).
3. Play void death VFX at pit position (style from `GameBalance.VOID_DEATH_STYLE` in `scripts/game_balance.gd`).
4. **VOID_GORE**: score only after the full **~3.2 s** cinematic; other styles use **2.0 s** fall + **1.2 s** effect.
5. Hide the fighter, then normal **3-2-1-FIGHT** countdown.
6. Void effects, fragments, **`gore_chunk`**, and combat **`gib_chunk`** cleared at round start (with corpses/projectiles).

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
| **0.35s** | Instability / freefall — camera FOV **90→102**, shake ramps |
| **0.7s** | Ambient void motes; audio: `Void wind` |
| **1.5s** | Corruption gas cloud (`void_corruption_cloud.tscn`) — green/blue/purple fog, pulsing light |
| **2.2s** | Body hidden; **8–14** `gib_chunk` physics pieces + blood mist; debug: `Body rupture` |
| **3.2s** | Final disintegration burst; **point awarded**; debug: `Death sequence finished, scoring` / `Disintegration burst` |

Gore is stylized sci-fi corruption (dark red/black chunks), not anatomical. Chunks/effects cleared at round start.

## Weapons (player)

| Key | Weapon | Role |
|-----|--------|------|
| **1** | **Railgun** — instant beam, precision execution | One hit breaks shield; second hit kills |
| **2** | **Shotgun** — 7 large pellets, spread | Close-range pressure (~70 dmg if all connect) |
| **3** | **Bazooka** — slow rocket + explosion | Direct shield break; splash for ring-out |
| **Left click** | Fire | |

**Railgun** uses an instant ray (no spread, **120** unit range, **0.95 s** cooldown). **100** damage: first clean hit strips a full **100** shield; a second hit deals **100** health damage and kills. Strong mostly-horizontal knockback (**68** push) threatens ring-outs near edges. Shield break prints `Shield broken by Railgun` and triggers a cyan HUD/crosshair flash. A blue/purple/white **beam tracer** (~0.08–0.15 s) and a small impact flash show the hit.

Shotgun and bazooka still use projectiles. All weapons apply **knockback and damage** (no self-damage). Crates still take push only.

### Weapon damage & force (`weapon_defs.gd`)

| Weapon | Damage | Knockback `push_force` |
|--------|--------|------------------------|
| Railgun | **100** per hit (shield first, then health) | **68** (strong horizontal, low vertical) |
| Shotgun | **10** × **7** pellets (max **70** per full burst) | **30** per pellet (scary close range) |
| Bazooka direct | **100** (shield break / 2-hit kill like railgun) | **58** (strong, controlled) |
| Bazooka explosion | up to **60** (radius falloff) | **82** explosion force (ring-out focus) |

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
| → Railgun `push_force` | Default **68** (weaker than bazooka blast, stronger than shotgun pellets) |
| → Shotgun pellet `push_force` / `mesh_scale` / `hit_radius` | **30** × 7 / **0.12** visual / **0.115** collision |
| → Bazooka direct `push_force` / `explosion_force` | **58** / **82**; cooldown **1.4 s** |
| `scripts/player.gd` (Inspector) | Optional overrides for player multipliers / max speed |
| `scripts/combat_stats.gd` | `max_health`, `max_shield` per fighter |

Raise `push_force` for more danger; adjust multipliers to keep player vs enemy knockback **fair**.

Projectiles store a **shooter** and ignore self-hits. Layer 2 projectiles, mask 1 (player + world).

## HUD

- Top: `Player: 0 | Enemy: 0`
- Bottom: `Weapon: …`
- Center (on win): `You Win!` or `You Lose!`

### Crosshair (`scenes/ui/crosshair.tscn`, `scripts/ui/crosshair.gd`)

Center-screen reticle on the UI layer — drawn with `_draw()` (no textures).

| State | Behavior |
|-------|----------|
| **Idle** | Compact cyan/white dot + four short lines (~88% alpha) |
| **Moving / jumping** | Lines spread slightly (weapon-dependent) |
| **Shooting** | Quick pulse (gap widens briefly) |
| **Hit enemy (shield)** | Cyan flash |
| **Hit enemy (health)** | Red/white flash |
| **Kill** | Stronger flash + small center **X** marker |
| **Cover hit** | Subtle cyan flash |

**Weapon styles:**

| Weapon | Crosshair |
|--------|-----------|
| Railgun | Tight gap, thin lines |
| Shotgun | Wider gap (spread hint) |
| Bazooka | Thicker, longer lines |

**Integration:**

- `WeaponManager` → `weapon_switched` + `shot_fired`
- `PushHitResolver` → hit/kill feedback when the player damages the opponent or cover
- Hidden during countdown, match over, and when the mouse is not captured

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
scripts/ui/crosshair.gd
scripts/enemies/arena_opponent.gd
scripts/enemies/enemy_weapon_manager.gd
scripts/arena_ui.gd
scripts/player.gd
scripts/weapons/weapon_defs.gd
scripts/weapons/weapon_firing.gd
scripts/weapons/weapon_manager.gd
```
