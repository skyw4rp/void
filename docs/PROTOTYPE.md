# Neon Catacombs — 1v1 Arena Prototype

Godot 4.6 first-person **knock-off duel** across **large suspended arenas** over an **infinite toxic void**. Each round picks a spacious layout with protected perimeters, intentional fall openings, and central cover. Win by **ring-out** or by **breaking shield and killing** your opponent.

**Art direction:** [art/ART_DIRECTION.md](art/ART_DIRECTION.md) (canonical) · [ART_DIRECTION_VOID.md](ART_DIRECTION_VOID.md) (prototype implementation index) · [VOID design philosophy](VOID_DESIGN_PHILOSOPHY.md) · [VOID prototype audit](VOID_PROTOTYPE_AUDIT.md) · [docs index](README.md)

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
| After point | Pick new arena → clear FX/debris → spawn cover → respawn on spawn pads → countdown |
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
| Ring-out | **Y < -20** — fall only from **exterior deck edges** (continuous floor, no interior pits) |

### Audio (P0)

**Autoload:** `VoidAudio` (`scripts/environment/void_audio.gd`) + `AudioStreamFactory` procedural placeholders.  
**Combat hooks:** `CombatAudio` → weapon fire (player/enemy 3D), shield/health hit confirm, cover/wall thud, hurt layer on health damage.

| Layer | Behavior |
|-------|----------|
| Void ambience | Looping drone on round start |
| Proximity | Volume scales with fall depth + arena edge distance (`VoidGasController`) |
| Danger pulse | One-shots when depth bands or edge tension increase |
| Fall rush | Bed while `_falling` in void gas |
| Gore timeline | Wind, rupture, burst, delayed absorption (silence chance unchanged) |

Replace placeholders: [audio/README_REPLACE_ASSETS.md](../audio/README_REPLACE_ASSETS.md).

## ArenaGenerator (`scripts/arena/arena_generator.gd`)

Each countdown:

1. **Clear** previous floor (`ActiveArena` children), debris, projectiles, corpses, gibs.
2. **Pick** a template from `ArenaTemplates` (won’t repeat the same name back-to-back).
3. **Wall set** — `ArenaWallSetGenerator` replaces/varies inner `wall_pieces` (zones, archetypes, cover density); route must include a detour.
4. **Build** one **continuous deck** + signature brutalist modules + procedural cover + **outer perimeter** (~70–80% protected) + **perimeter fall markers** (cracked edge, void glow).
5. **Validate spawns** — floor raycast; per-body spawn height (player feet at floor, enemy capsule center +0.8); low-profile spawn pads.
6. If invalid → regenerate (up to 6 attempts, then Toxic Bridge fallback).
7. Spawn **5–9** destructible cover pieces on **raycast-validated** floor points.
8. Respawn fighters at validated transforms; pass `get_current_arena_bounds()` to AI.

### Arena templates (`scripts/arena/arena_templates.gd`)

**Continuous brutalist decks** (~**46×40** to **50×50** world units) — **one solid floor slab** per arena. **No interior void holes**; ring-out only past `danger_half_*` at the **outer rim** (perimeter openings + fog/audio/scale).

| ID | Name | Deck (half X × half Z) | Signature modules |
|----|------|------------------------|-------------------|
| `TOXIC_BRIDGE` | Toxic Bridge | **24 × 20** | Columns, massive slabs, flank half-walls |
| `SPLIT_PLATFORMS` | Split Platforms | **26 × 22** | Four corner columns, center slab, broken walls |
| `BROKEN_REACTOR` | Broken Reactor | **25 × 23** | Reactor columns, north/south slabs |
| `RUINED_COURTYARD` | Ruined Courtyard | **25 × 25** | Corner columns, lateral slabs (spawn on Z axis) |
| `HANGING_CORRIDORS` | Hanging Corridors | **23 × 27** | Side monoliths, end broken walls |

`ArenaBrutalistModules` adds **visual-only corner pylons** for scale (no collision). Procedural `ArenaWallSetGenerator` adds flank cover (pillars, slabs, clusters) without carving floor holes.

Each template: `spawn_safe_half`, perimeter `fall_zones[]`, `perimeter.ringout_open_sides`, `void_y` (**-32**).

### Outer perimeter (`scripts/arena/arena_perimeter_builder.gd`)

- Procedural **partial shell** around danger bounds + margin
- Piece types: full ruined wall, half wall, collapsed, cracked pillar, hanging panel
- **Decor-only** corner towers and distant breakwall silhouettes (no collision)
- All walls/barriers/pillars/slabs/perimeter pieces use **`DestructibleWall`** (`destructible_wall` group) — named `DestructibleWall_Full`, `_Half`, `_Outer`, `_Pillar`, `_ThinSlab`. Anonymous `@StaticBody3D@*` names are **not allowed** for wall-like geometry.
- Only **`StructuralFloor_*`** and **`StructuralConnector_*`** (`structural_geometry` group) are non-destructible floors/bridges.
- Groups: `arena_wall`, `arena_perimeter` (AI cover), `arena_perimeter_decor` (visual only, no collision)

### Destructible arena walls (`scripts/arena/destructible_wall.gd`)

- **Inner walls** from `arena_structure_builder.gd` — every `wall_pieces` slab is destructible (floors stay static).
- **Perimeter walls** — all collision panels destructible; full ruined segments use **OUTER_HEAVY** (**200** HP).
- **Round debris cover** — `debris_chunk.gd` shares the same damage table via `DestructibleWall.resolve_weapon_damage()`.

| Wall kind | HP |
|-----------|-----|
| Half wall | **80** |
| Full wall | **140** |
| Pillar | **120** |
| Thin slab | **70** |
| Outer heavy | **200** |

**Weapon vs walls** (`weapon_defs.gd`):

| Source | Wall damage |
|--------|-------------|
| Railgun | **0** (mechanical pierce + **entry** energy marks, no wall HP) |
| Shotgun pellet | **8** |
| Bazooka direct | **120** |
| Bazooka explosion | up to **90** (radius falloff) |

**Staged destruction** (`wall_destruction.gd`): shotgun/bazooka break walls; **railgun does not** deal wall HP damage. **Railgun pierce marks** (`railgun_pierce_mark.gd`): **entry-only** cyan/purple burn rings on pierced surfaces (**8–12 s** fade, parented to host); exit marks removed (unreliable thickness). No mesh cut. **Beam** shows penetration; brief **impact flash** at each pierce. Real geometry holes postponed. (1) wall damage → crack visual, (2) hold **0.08–0.15 s**, (3) **8–40** chunks, (4) fade host. Floors stay `StructuralFloor_*` only.

**Route validation** (`arena_route_validator.gd`): floor-grid **BFS** on the continuous deck; requires primary path **and** at least one detour. `arena_connector_builder.gd` bridge fallback is **rare** (legacy safety for disconnected layouts). Optional `debug_show_route` on `ArenaGenerator`.

**Adding a template:** implement a builder in `arena_templates.gd`, add to `get_playable_ids()`, deck top at **local y = 0** (`slab` helper: center y = `-thickness/2`). Every template must have a valid floor route (or accept auto-connector).

### Debug markers

**Procedural wall sets** (`arena_wall_set_generator.gd`): each round mutates inner `wall_pieces` on top of the selected template — zone-based placement (center, lanes, flanks, spawn approaches), nine destructible archetypes, randomized cover density (**0.4–1.0**), and layout profiles (open center, center blocker, side-heavy, diagonal, long sight, close quarters). Route validator requires a primary path **plus** at least one detour. Signature template walls may be kept (~35%) so arenas stay recognizable.

**Spawn pads** (`spawn_pad.tscn`): low-profile Quake-style spawn markers (small octagonal disk, thin glow ring, dark metal) flush with the floor. Player/enemy transforms raycast to floor height with per-body offsets (player feet at origin, enemy capsule center +0.8) — no stacked pad/stand clearance. Regenerated each round.

`ArenaGenerator.debug_show_spawn_markers` (default **false**): green/red debug spheres above spawns when enabled. `debug_show_markers` (default **false**): blue danger-bound corners / route debug.

### AI integration

`ArenaOpponent.apply_arena_bounds_from_dict()` ← bounds each respawn. AI uses **cover** (`arena_wall` LOS breaks), **hole raycasts** (`has_floor_at` / `is_floor_ahead`), railgun at range, shotgun when blocked or close.

## Destructible cover (`DebrisSpawner`)

Each countdown (including match start):

1. Clear **`round_debris`** and **`round_debris_fragment`** from the previous round.
2. Spawn **5–9** large `debris_chunk.tscn` cover pieces in the **active arena’s** debris zone (per-arena local X/Z rect), spread apart.
3. Cover types (random): **BLOCK**, **WALL_SLAB** (tall LOS blocker), **BROKEN_PILLAR**, **FALLEN_BEAM** — each with its own scale, mass, material, and rotation.
4. Spawn avoids player/enemy spawns (~**3.8** u) and limits pieces in the narrow center lane so at least one route around stays open.
5. **Health** uses shared wall kinds: Block → half **80**, Wall slab → thin **70**, Pillar **120**, Beam → thin **70**.
6. At **0 HP**: same staged fracture as arena walls (crack → hold → proportional chunks → fade).
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

**Visual hierarchy** (`HumanoidVisual`):

```
Torso, Head (EyeLeft, EyeRight), LeftArm, RightArm, LeftLeg, RightLeg
WeaponMount (EnemyWeaponMount)
  EnemyWeaponManager
    RailgunView / ShotgunView / BazookaView (+ Barrel mesh, Muzzle at barrel tip)
```

**WeaponMount** is the single visual aim pivot: local **-Z** is firing direction. `EnemyLookAtController` rotates body/head/arms; mount tracks the same cached aim point. **Physics:** unchanged capsule `RigidBody3D`.

**Procedural animation (no skeletal rig):** `ProceduralEnemyAnimator` — locomotion states + `GroundCheck` grounded ray; shoot recoil kicks `WeaponMount` only (not barrel meshes).

**Hard-synced aim:** `ArenaOpponent` owns `_current_aim_target`, `_last_valid_weapon_aim_position` (`+1.2` Y), `_last_valid_head_aim_position` (`+1.45` Y); updated and pushed to `EnemyLookAtController` **every physics frame before any AI early return** (including countdown). `_try_shot()` calls `align_weapon_to_target()` then fires from **Muzzle** along `get_weapon_forward()` (`-WeaponMount.basis.z`). `force_visual_aim_refresh()` after respawn (GameManager). Debug: `debug_show_weapon_forward` / `debug_show_muzzle` on mount. **Limitation:** placeholder meshes, not a skeletal rig.

### States
- **HUNTING** — default predatory arena movement
- **PRESSURING** — player near edge or ring-out angle; burst pushes
- **EVADING** — AI low shield/health; micro-strafes + dodge bursts
- **EXECUTING** — player low health; aggressive closes
- **RECOVERING** (0.8–1.2s) — after heavy knockback or near rim; no shooting
- **IN_COVER** — breaks LOS, peeks to fire

Debug: `Enemy state: HUNTING` / `PRESSURING` / …, optional `debug_ai_movement`

### Gladiator locomotion (VOID arena mastery)

**Philosophy:** Quake III / UT / DOOM Eternal–inspired — fast, physics-driven, skill-rewarding. Retuned for **heavier, more readable** arena combat: still elite gladiators, not slow military movement.

**Player** (`player.gd` + `scripts/movement/`):
- Quake-style accel/friction/air control — ~**7.6** ground / **9.0** air max speed (down from 9.8 / 11)
- **Shift + direction** or **double-tap WASD** → short dodge (~**2.05** u, **1.4 s** cooldown)
- Camera: `GladiatorFov` — base **78°**, smooth blend; movement +0–4°, weapon pulse ~+1.25°, void fall up to +24°; gameplay clamp **base−2 … base+6**; aim on `AimPivot`, roll/kick on `CameraFeelPivot`
- Rocket jump force unchanged; knockback flow preserved
- **Viewmodel motion:** `WeaponManager/WeaponViewmodelAnimator` (`scripts/animation/weapon_viewmodel_animator.gd`) — sway, walk bob, per-weapon recoil (railgun snap / shotgun kick / bazooka heavy), switch dip on 1–3. Visual only on view meshes.

**Enemy:** Controlled speed (~**12.5** move force, **6.5** max speed). **Soft edge** (past safe): inward steer while still strafing/shooting. **Hard edge** (past danger): short **RECOVERING** burst (**0.55–0.9 s**) with **1.5 s** re-entry cooldown — no fire only in hard zone. Stale aim (**3 s** no shot) forces reposition. States: HUNTING / PRESSURING / EVADING / EXECUTING / IN_COVER stay active fighters.

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
- Tracks **`last_damage_amount`**, **`overkill_amount`**, **`last_damage_source`**, **`last_hit_direction`**, **`last_hit_force`**, **`last_explosion_origin`** (explosions), **`last_hit_world_position`**
- `is_heavy_death()` — rocket direct/explosion, overkill ≥ **25**, or last hit ≥ **40** damage
- `is_dismemberment_death()` — heavy kills + strong shotgun (**≥28** dmg) + railgun overkill
- `get_dismemberment_profile()` — `shotgun`, `rocket_direct`, `explosion`, `railgun`, `heavy`
- `reset_combat_stats()` — full restore at round start
- `is_dead()` — health ≤ 0 triggers a point for the attacker
- Debug: `Player shield: X health: Y` / `Enemy shield: X health: Y`

HUD (`arena_ui.gd`): `Player HP: … | Shield: …` and `Enemy HP: … | Shield: …`

### Health death (kill, not void)

After the death spectacle, the point is awarded and **3-2-1-FIGHT** runs: **2.5 s** normal (`KILL_DEATH_VIEW_SEC`), **2.4 s** dismemberment (`DISMEMBER_VIEW_SEC`). Debug: `Death sequence finished, scoring`.

#### Normal death (light hits)

1. Spawn `physics_corpse.tscn` — launched from last hit direction/force (per-weapon corpse scaling).
2. Hide live fighter; group **`corpse`**, layer **8**; cleared at round start.

#### Dismemberment death (`dismemberment_spawner.gd` + `body_part_chunk.tscn`)

Triggered when `CombatStats.is_dismemberment_death()` is true. **No full corpse** — body breaks into directional parts.

| Profile | Trigger | Physics |
|---------|---------|---------|
| **shotgun** | Source shotgun, damage ≥ **28** | Partial — parts along pellet/attacker direction, tighter spread |
| **rocket_direct** | Bazooka direct | Full — parts along rocket travel + light radial scatter |
| **explosion** | Bazooka splash | Radial from blast origin; falloff by distance |
| **railgun** | Railgun + overkill | Beam line — torso/limbs along beam, low lateral spread |
| **heavy** | Other heavy kills | Directed burst |

Spawns **4–7** large parts (torso, head, arms, legs, armor shards) + **8–18** small gibs + blood mist. Stylized dark red/black gore + metallic armor tints — no organ realism.

**Direction rules:** projectile deaths use `last_hit_direction`; explosions use vector from `last_explosion_origin` to body; forces scaled by `last_hit_force`.

Tuning: `game_balance.gd` — `DISMEMBER_HORIZONTAL_FORCE_*` (**8–22**), upward **2–8**, torque **5–16**, max speed **28**, lifetime **5–8 s**. Groups: **`dismembered_body_part`**, **`gib_chunk`** (small parts). Cap **72** active pieces.

**Player HUD:** `YOU WERE TORN APART` (shotgun / railgun shred) or `YOU WERE OBLITERATED` (rocket/explosion/heavy). Stronger camera shake on rocket/shotgun dismemberment.

**Enemy debug:** `Enemy dismembered by bazooka` / `shotgun` / `railgun`.

Debug: `Dismemberment spawned: profile=… parts=… gibs=…`, `Dismemberment sequence finished`.

Gore cleared at round start via `DismembermentSpawner.clear_all()`.

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

Debug: `Void death style: …` (void SFX play via `VoidAudio`, no console prints).

#### VOID_GORE cinematic timeline

Fall → freefall → corruption → breakup → burst → **score** → countdown.

| Time | Event |
|------|--------|
| **0.0s** | Fall begins; loss of balance / slide; controls off |
| **0.35s** | Instability / freefall — FOV ramps toward **base+24°** max, shake ramps |
| **0.7s** | Ambient void motes; audio: void wind gust |
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

**Railgun** — piercing ray (**120** range, **1.6 s** cooldown, **8** pierce steps). **100** damage / **68** knockback on fighters; **0** wall HP. **Entry mark** per pierced wall + beam through trajectory. Shotgun/bazooka destroy cover.

Shotgun and bazooka still use projectiles. Fighter weapons do not self-damage on direct hits; **bazooka explosions can rocket-jump the shooter** (see below). Crates still take push only.

### Rocket jump (bazooka)

Fire at the floor or a nearby wall to blast yourself upward/backward:

- Shooter receives explosion knockback if inside blast radius (projectile direct hit on self still ignored).
- Tuning (`weapon_defs.gd`): `SELF_EXPLOSION_KNOCKBACK_MULTIPLIER` **0.35**, `SELF_EXPLOSION_DAMAGE_MULTIPLIER` **0.0**, `ROCKET_JUMP_UPWARD_BOOST` **6**, caps **Y ≤ 12**, horizontal **≤ 22**. Enemy/cover explosion force is unchanged — only self-blast is reduced.
- Controlled mobility (hop/backstep), not a arena-wide launch — **optional**; route validation guarantees reaching the enemy on foot without rocket jump.
- AI: no intentional rocket jumps; may accidentally self-launch from own rockets (RigidBody impulse).

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
- Player vertical velocity clamped to **-30 … 22** after normal knockback/explosions
- Rocket jump uses separate caps (**Y ≤ 12**, horizontal **≤ 22**); typical hop ~**6–12** vertical, **10–22** horizontal
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

### Crosshair & aim (`scripts/player.gd`, `scripts/ui/crosshair.gd`)

**Stable aim:** mouse yaw on `Player`, pitch on `AimPivot`. `WeaponManager` fires using `get_aim_global_transform()` (not visual roll/bob). `CameraFeelPivot` child handles roll, FOV, and positional kick only.

| Export (Player) | Default | Role |
|-----------------|---------|------|
| `crosshair_stabilized` | `true` | Fixed screen reticle gap while moving |
| `camera_bob_affects_aim` | `false` | Camera feel does not tilt aim pivot |
| `weapon_bob_affects_aim` | `false` | Viewmodel bob does not change fire ray |

Center-screen reticle on the UI layer — drawn with `_draw()` (no textures).

| State | Behavior |
|-------|----------|
| **Idle** | Compact cyan/white dot + four short lines (~88% alpha) |
| **Moving / jumping** | Reticle stays centered (no movement spread when stabilized) |
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
