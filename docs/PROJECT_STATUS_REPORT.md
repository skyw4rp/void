# Neon Catacombs — Project Status Report

**Generated from implementation snapshot (Godot 4.6).**  
This document reflects what exists in the repository today, not planned features unless noted as TODO.

---

## 1. EXECUTIVE SUMMARY

| Field | Detail |
|-------|--------|
| **Game name** | Neon Catacombs |
| **Genre** | First-person arena duel / knock-off combat prototype |
| **Engine** | Godot 4.6 (Forward Plus), main scene `res://scenes/main.tscn` |
| **Core concept** | 1v1 fights on suspended platforms over a lethal void. Win by knocking the opponent off (ring-out) or depleting shield + health (kill). |
| **Prototype status** | Playable vertical slice: five large procedural arenas, perimeter walls, fall-zone warnings, deep toxic gas, void/kill deaths, match to 5 points. |
| **Elevator pitch** | A brutalist pit-fighter duel in a fog-choked void — fight on spacious suspended ruins, knock foes through intentional openings into gas that swallows visibility below. |
| **Target experience** | Tension at the edge, readable knockback, satisfying kills and void falls, short explosive rounds, growing dread from the abyss. |
| **Current loop** | Match → random arena build → countdown → fight → point (void or kill) → respawn → repeat until 5 points → win/lose screen. |

---

## 2. GAME LOOP

### Match flow

1. **Match start** — Scores reset to 0. First round countdown begins.
2. **Round setup** (`GameManager._run_countdown`):
   - `ArenaGenerator.generate_round_arena_async()` — pick template, build floor, validate spawns.
   - Clear projectiles, corpses, void FX, gib chunks, round debris.
   - Spawn 3–6 destructible cover pieces on validated floor.
   - Respawn player and enemy at validated transforms; AI receives arena bounds.
3. **Countdown** — HUD shows `3` → `2` → `1` → `FIGHT!` (1.0 s per number, 0.7 s for FIGHT). Fighters cannot move or shoot (`RoundState.COUNTDOWN`).
4. **Combat** — `RoundState.FIGHTING`. Void fall and damage apply only while fighting.
5. **Point scored** — Combat stops (`ROUND_OVER`), spectacle plays, then next round or match end.

### Win conditions

| Condition | Rule | Scoring |
|-----------|------|---------|
| **Ring-out (void)** | Fighter `global_position.y < void_y` (default **-32**) | Opponent gets +1 |
| **Kill** | Health reaches 0 (after shield) | Attacker’s side gets +1 |

### First to X

- **`WIN_SCORE = 5`** (`game_manager.gd`).
- Player win → `match_over(true)`; enemy win → `match_over(false)`.
- HUD: `Player: N | Enemy: N`.

### Void fall sequence

1. Fighter crosses void threshold → `report_player_void_fall` / `report_enemy_void_fall`.
2. Enter `void_dying` — controls off; body/camera may keep falling.
3. **Default style: `VOID_GORE`** (`GameBalance.VOID_DEATH_STYLE`):
   - Full cinematic ~**3.2 s** (`VoidGoreSequence`) then score.
4. **Other styles** (if switched in `game_balance.gd`):
   - **2.0 s** fall delay + **1.2 s** effect at pit position, then score.

### Health kill sequence

1. `CombatStats.died` → fighter hides, death FX.
2. **Normal death** — physics corpse, score after **2.5 s** (`KILL_DEATH_VIEW_SEC`).
3. **Heavy death** — collapse flash, gib chunks, score after **1.8–2.2 s** (`gib_collapse_score_sec()`).

### Respawn / next round

- After point: new arena generation, cover spawn, full combat stat reset, countdown again.
- No mid-round respawn.

---

## 3. CURRENT MECHANICS

### Movement (player — `scripts/player.gd`)

| Feature | Implementation |
|---------|----------------|
| Walk | **5.0** u/s |
| Sprint | **9.0** u/s (hold sprint) |
| Jump | **4.5** velocity |
| Mouse look | Sensitivity **0.002**, pitch clamp ±**1.4** rad |
| Gravity | Project default gravity |
| Combat lock | No move/shoot when not `FIGHTING` or when dead/void-dying |

### Knockback (player)

- Horizontal impulse from weapons; **grounded** vs **airborne** upward factors from `WeaponDefs`.
- Clamps: upward **22**, downward **-30**, horizontal **45** grounded / **32** airborne.
- Shotgun: only first pellet in **0.1 s** window adds vertical lift.
- Explosion knockback via `apply_explosion_knockback` with separate vertical clamp (**-25** to **22**).

### Combat (`scripts/combat_stats.gd`)

| System | Behavior |
|--------|----------|
| Shield | **100** max; damage absorbed first |
| Health | **100** max; damage after shield depleted |
| Death | `health <= 0` → `died` signal |
| Overkill | If health goes negative, `overkill_amount = abs(health)` before clamp to 0 |
| Heavy death | `bazooka_direct`, `bazooka_explosion`, overkill ≥ **25**, or last hit ≥ **40** damage |
| Low state | Shield ≤ **30** or health ≤ **40** (AI uses for evasion) |

### Scoring

- Void and kills both award **1 point**.
- Debug prints: `Player scored!`, `Enemy scored!`, `Death sequence finished, scoring`.

---

## 4. WEAPONS SYSTEM

Shared stack: `WeaponDefs` → `WeaponFiring` → `PushHitResolver` → `CombatStats` / `damage_cover` / RigidBody impulses.

Player: `WeaponManager` on camera. Enemy: `EnemyWeaponManager` on weapon pivot.

### Railgun (slot 1)

| Property | Value |
|----------|-------|
| **Role** | High-impact precision weapon — shield break + kill threat |
| **Damage** | **100** per hit (shield absorbs first; no overflow on first hit at full shield) |
| **TTK** | Hit 1: shield **100 → 0**, health stays **100**; hit 2: health **100 → 0** (kill) |
| **Knockback** | **68** (`apply_railgun_hit`, mostly horizontal, low vertical via `RAILGUN_VERTICAL_FACTOR`) |
| **Cooldown** | **1.6 s** (deliberate heavy precision cadence) |
| **Range** | **120** units; iterative pierce ray (**8** max hits, **0.05** offset) |
| **Delivery** | Instant ray; pierces walls/cover; stops on first fighter per shot |
| **Wall interaction** | **0** wall damage; mechanical pierce; **entry-only** portal marks (parented, 8–12 s fade) |
| **Feedback** | `Shield broken by Railgun`; `Railgun pierced:` / `Railgun hole spawned at position` debug logs |
| **Visual** | `BeamTracer` through pierced surfaces to max range (impact flash on fighter hit only) |
| **AI** | Long range with LOS; aim error (~**0.65** m); slower fire cadence; not every long-range tick picks railgun |

### Shotgun (slot 2)

| Property | Value |
|----------|-------|
| **Role** | Close-range spread pressure — punishing but not instant 200 HP delete |
| **Damage** | **10** per pellet × **7** pellets (**70** max if all connect) |
| **Knockback** | **30** per pellet (strong at point-blank; vertical caps preserved) |
| **Cooldown** | **0.75 s** |
| **Spread** | **0.14** |
| **Projectile** | `push_projectile.tscn`, speed **38**, lifetime **1.8 s** |
| **Visual** | Larger pellets: `mesh_scale` **0.12**, `hit_radius` **0.115**, brighter emission |
| **AI** | Preferred when `distance < close_range` or LOS blocked |

### Bazooka (slot 3)

| Property | Value |
|----------|-------|
| **Role** | Direct heavy punishment + explosion ring-out (splash not instant lethal) |
| **Damage** | **100** direct (shield break / 2-hit kill); up to **60** explosion (radius falloff) |
| **Knockback** | **58** direct; **82** explosion force |
| **Cooldown** | **1.4 s** |
| **Projectile** | `bazooka_projectile.tscn`, speed **22**, lifetime **4 s** (slower than railgun beam) |
| **Explosion** | Radius **5.0** — `PushExplosion.detonate` |
| **Rocket jump** | Self-blast only: **0.35×** knockback, **+6** upward boost, caps **12** Y / **22** horizontal; **0** self-damage; enemy splash unchanged |
| **AI** | Medium / ring-out only (~**26–40%** pick); longer fire interval; not spammed at 100 direct dmg |

### Destructible walls

| Component | Script | Notes |
|-----------|--------|-------|
| Inner template walls | `destructible_wall.gd` | All `wall_pieces`; named `DestructibleWall_*` |
| Perimeter | `destructible_wall.gd` | All collision panels; OUTER_HEAVY **200** HP |
| Round cover | `debris_chunk.gd` | Same damage resolver; avoids main route |
| Floors | `StructuralFloor_*` / `StructuralConnector_*` | `structural_geometry` group; unique names (no duplicate `StructuralFloor`) |
| Walls | `DestructibleWall_<Type>_<index>` | `destructible_wall` group; crumble to local rubble |

**Route validation:** `arena_route_validator.gd` BFS on floor grid; connector fallback; spawn clearance **3** cells (~3 m). `debug_show_route` on `ArenaGenerator`.

| Wall kind | HP |
|-----------|-----|
| Half | 80 |
| Full | 140 |
| Pillar | 120 |
| Thin slab | 70 |
| Outer heavy | 200 |

| Weapon | Wall damage |
|--------|-------------|
| Railgun | 0 (marks only; pierces) |
| Shotgun pellet | 8 |
| Bazooka direct | 120 |
| Bazooka explosion | 90 max (falloff) |

Break → staged fracture (`wall_destruction.gd`): crack visual → brief hold → **8–40** volume-placed chunks → fade/remove host. Impact-aware local collapse; fragment protection **0.25 s**; lifetime **6–10 s**.

### Shared systems

| File | Purpose |
|------|---------|
| `weapon_defs.gd` | Stats, knockback constants, weapon enum |
| `weapon_manager.gd` / `enemy_weapon_manager.gd` | Switching, cooldown, fire |
| `weapon_firing.gd` | Ray, pellets, bazooka spawn |
| `push_hit_resolver.gd` | Damage routing, knockback, explosions, railgun, cover `damage_cover` |
| `push_explosion.gd` | Sphere query explosion + shooter rocket jump |
| `destructible_wall.gd` | Wall HP, damage stages, `damage_cover` |
| `wall_destruction.gd` | Staged fracture, chunk count/placement, impact impulses |
| `beam_tracer.gd` | Primary railgun beam VFX (bright cyan/blue, short-lived) |
| `railgun_pierce_mark.gd` | Entry-only energy rings on pierced walls (exit marks removed) |
| `railgun_impact_flash.gd` | Brief hit flash on fighters / fallback |
| `railgun_impact_hole.gd` | **Deprecated** |
| `perforable_wall_grid.gd` / `railgun_wall_perforation.gd` | **Deprecated** (no geometry removal) |

---

## 5. KNOCKBACK / PHYSICS

### Global tuning (`weapon_defs.gd`)

| Constant | Value |
|----------|-------|
| `PLAYER_KNOCKBACK_MULTIPLIER` | **1.6** |
| `RIGIDBODY_KNOCKBACK_MULTIPLIER` | **0.6** |
| `GROUNDED_UPWARD_KNOCKBACK_FACTOR` | **0.10** |
| `AIRBORNE_UPWARD_KNOCKBACK_FACTOR` | **0.025** |
| `RAILGUN_VERTICAL_FACTOR` | **0.06** |
| `SELF_EXPLOSION_KNOCKBACK_MULTIPLIER` | **0.35** (self only) |
| `SELF_EXPLOSION_DAMAGE_MULTIPLIER` | **0.0** |
| `ROCKET_JUMP_UPWARD_BOOST` | **6** |
| `MAX_ROCKET_JUMP_UPWARD_VELOCITY` | **12** |
| `MAX_ROCKET_JUMP_HORIZONTAL_VELOCITY` | **22** |
| `PROJECTILE_HIT_VERTICAL_FACTOR` | **0.22** (bazooka direct) |
| `EXPLOSION_VERTICAL_FACTOR` | **0.18** |
| `EXPLOSION_MAX_UPWARD_FORCE` | **18** |
| `EXPLOSION_MAX_DOWNWARD_FORCE` | **8** |

### Enemy (`arena_opponent.gd`)

- `RigidBody3D`, mass **5**, linear damp **0.6**, axis-locked rotation.
- Knockback via impulses; recovery state after heavy hits / near edge.

### Corpse launch (`physics_corpse.gd`)

| Source scale | Multiplier |
|--------------|------------|
| railgun | **0.55** |
| shotgun | **0.65** |
| bazooka_direct | **1.0** |
| bazooka_explosion | **1.1** |

- `launch_force_multiplier` **0.7**, `max_launch_speed` **35**, `max_upward_speed` **16**.
- Despawn **4–6 s**; collision layer **8** (ignored by weapons).

### Gib collapse (`game_balance.gd` + `gib_chunk.gd`)

| Parameter | Value |
|-----------|-------|
| Horizontal impulse | **1.5–5.0** |
| Upward (few chunks) | **1.0–4.0** |
| Linear / angular damp | **1.8** / **2.2** |
| Lifetime | **3–4 s** |
| Count | **10–18** chunks |

---

## 6. AI SYSTEM

**Script:** `scripts/enemies/arena_opponent.gd`  
**Scene:** `scenes/enemies/arena_opponent.tscn`

### States

| State | Behavior |
|-------|----------|
| **ATTACKING** | Move, strafe, shoot, edge logic |
| **RECOVERING** | **0.8–1.2 s** after heavy knockback or near rim; moves toward center; no shooting |

### Movement

- Forces: move **10**, strafe **8**, retreat **12**, max speed **5**.
- Ideal distance **4–11**; close **5**, medium **12**.
- Never stands still (idle strafe if overlapping).

### Edge avoidance

- Rectangular bounds from active arena (`apply_arena_bounds_from_dict`).
- **Safe** half-extents vs **danger** half-extents — stronger push when past safe.
- Pushes player toward nearest open edge (not only “away from center”).

### Weapon AI

- Random weapon shuffle every **4–6 s**.
- Fire attempts every **0.4–0.9 s** when preferred weapon selected.
- Tactical weapon choice (see Weapons section).

### Arena awareness

- `arena_center` and per-arena safe/danger X/Z from `ArenaGenerator` each round.

---

## 7. DEATH SYSTEMS

### Normal health death

1. Spawn `physics_corpse.tscn` at fighter position.
2. Launch from last hit direction/force.
3. Hide live fighter.
4. Score after **2.5 s**.

### Heavy health death

Triggers: rocket direct/explosion, overkill ≥ **25**, single hit ≥ **40**.

1. `VoidDeathEffect.play_collapse_flash` (also used for gib intro).
2. **0.1 s** delay (`GIB_COLLAPSE_SPAWN_DELAY_SEC`).
3. **10–18** `gib_chunk` collapse pieces (local, low impulse).
4. Player: screen shake + **"YOU WERE OBLITERATED"**.
5. Score after **1.8–2.2 s**.

### Gibbing vs void gore chunks

| System | Group | Use |
|--------|-------|-----|
| Combat gib | `gib_chunk` | Heavy kills |
| Void pit gore | `gore_chunk` | VOID_GORE breakup at 2.2 s |
| Cover break | `round_debris_fragment` | Destroyed cover |

### Corpse

- Capsule mesh rigid body; not full ragdoll skeleton.
- Player corpse: cyan tint; enemy: red tint.

---

## 8. VOID SYSTEM

### Void fall detection

- `void_y = -32` (`GameBalance.VOID_DEATH_Y`); dense gas from **Y ≈ -18**; arena deck stays clear at **Y ≥ 0**.
- Player/enemy report once per round when Y drops below threshold while fighting.

### Default: `VOID_GORE` timeline (`void_gore_sequence.gd`)

| Time | Event |
|------|--------|
| **0.0 s** | Fall begins; instability |
| **0.35 s** | Instability phase |
| **0.7 s** | Ambient motes; void wind (audio placeholder) |
| **1.5 s** | Corruption cloud |
| **2.2 s** | Body breakup; gib chunks + blood mist |
| **3.2 s** | Final burst; **score** |

Post-score: delayed absorption audio / distant flash (chance-based placeholders).

### Player void UX

- Red void overlay (`arena_ui.gd`).
- Camera FOV **90 → 102** during fall.
- Shake ramps while falling.
- `begin_void_dying` / `end_void_dying` on player.

### Alternate void styles (`GameBalance.VoidDeathStyle`)

| Style | Behavior when active |
|-------|----------------------|
| **DISINTEGRATE** | Energy flash + ring expand + cosmetic fragments |
| **EXPLODE** | Orange burst + **~10** `void_fragment` physics pieces |
| **GORE_PLACEHOLDER** | Red fragments only |
| **VOID_GORE** | Full cinematic (default); `VoidDeathEffect.play_at` skipped |

**Current default:** `VOID_GORE` in `game_balance.gd`.

### Non-VOID_GORE void scoring

- **2.0 s** fall (`VOID_FALL_DELAY_SEC`) + **1.2 s** effect (`VOID_EFFECT_VIEW_SEC`), then score.

---

## 9. ARENA SYSTEM

### Active system: `ArenaGenerator`

| Component | Path |
|-----------|------|
| Generator | `scripts/arena/arena_generator.gd` |
| Scene | `scenes/arena/arena_generator.tscn` |
| Templates | `scripts/arena/arena_templates.gd` |
| Template data | `scripts/arena/arena_template.gd` |
| Structure build | `scripts/arena/arena_structure_builder.gd` |
| Perimeter | `scripts/arena/arena_perimeter_builder.gd` (~60–80% walls) |
| Fall warnings | `scripts/arena/arena_fall_zone_builder.gd` |

### Round pipeline

1. Clear `ActiveArena` children.
2. Pick random template (no back-to-back same `arena_name`).
3. Build floors, inner walls, perimeter, fall-zone markers.
4. Validate spawns inside `spawn_safe_half` (away from pit edges).
5. Up to **6** attempts; fallback **Toxic Bridge**.

### Arena template status (all playable)

| ID | Scale | Fall zones |
|----|-------|--------------|
| `TOXIC_BRIDGE` | 14×14 twins + 6×10 bridge | Outer deck edges (+Z/-Z openings) |
| `SPLIT_PLATFORMS` | 13×20 decks + 6×4 catwalks | Outer deck extremes |
| `BROKEN_REACTOR` | C-walkway, 12×12 center pit | Pit rim only |
| `RUINED_COURTYARD` | 28×28 ring, 14×14 pit | Inner courtyard rim |
| `HANGING_CORRIDORS` | 6×28 lanes + end bridges | Corridor ends |

### Legacy / unused in main flow

These exist on disk but **`main.tscn` does not use them** for gameplay:

- `scenes/world/arena_zones.tscn` + `ArenaSelector`
- `scenes/arenas/*.tscn` (hand-authored arena scenes)
- `scripts/environment/arena_zone.gd`

### Debug

- **Spawn pads** (`spawn_pad.gd`): Quake-inspired platforms at spawns; hidden debug spheres by default.
- `debug_show_spawn_markers` (default **false**): green/red spawn debug only when enabled.
- `debug_show_markers` (default **false**): danger bounds / route overlays.

### API for game systems

- `get_player_spawn_transform()` / `get_enemy_spawn_transform()`
- `get_current_arena_bounds()` → AI
- `pick_valid_debris_position()` → cover spawns

---

## 10. DESTRUCTIBLE ENVIRONMENT

### Cover pieces (`debris_chunk.gd`)

| Type | HP |
|------|-----|
| BLOCK | **60** |
| WALL_SLAB | **100** |
| BROKEN_PILLAR | **80** |
| FALLEN_BEAM | **70** |

### Destruction

- Weapons call `damage_cover()` via `PushHitResolver`.
- Bazooka explosion: **×1.65** damage mult; direct **×1.3**; shotgun **×0.85**.
- At 0 HP: **4–8** `debris_fragment` pieces, then remove cover.

### Spawning (`debris_spawner.gd`)

- **3–6** pieces per round.
- Positions from template debris rect + **downward raycast** (must hit floor).
- Skips invalid points; avoids spawn exclusion radius **3.8**.
- Groups: `round_debris`, `round_debris_fragment`.

### Physics

- Layer **1** — blocks shots and fighters.
- Can be pushed into void; despawn below void.

---

## 11. VISUAL LANGUAGE

Documented in depth in `docs/art/ART_DIRECTION.md`, `docs/ART_DIRECTION_VOID.md`, `docs/art/VISUAL_RULES.md`.

### Implemented in prototype

| Element | Current look |
|---------|----------------|
| **Arena floors** | Dark stone/metal slabs; procedural |
| **Void** | Deep blue-gray sky, fog, no visible floor in pit |
| **VoidAtmosphere** | Fog layers, drift particles, depth pulse light |
| **VoidDistantArchitecture** | Silhouette ruins/platforms/pillars in fog |
| **Lighting** | Cold directional sun, rim/edge omni lights |
| **Gore** | Stylized chunks (not anatomical); void corruption colors (green/blue/purple) for pit |
| **Combat gib** | Dark red/black collapse chunks |
| **UI** | Score, HP/shield, countdown, death messages, void overlay |

### Bridge pit identity (Pit Bridge template)

- Long narrow deck, side rails, end pillars (when using legacy scene; generator version is deck-only slab).

---

## 12. FILE STRUCTURE

```
neon-catacombs/
├── project.godot
├── icon.svg
├── scenes/
│   ├── main.tscn                 # Entry point
│   ├── arena/
│   │   └── arena_generator.tscn
│   ├── arenas/                   # Legacy hand-built (not main flow)
│   ├── effects/                  # Corpse, gib, void VFX
│   ├── enemies/
│   │   ├── arena_opponent.tscn
│   │   └── enemy_weapon_manager.tscn
│   ├── environment/
│   │   ├── void_atmosphere.tscn
│   │   └── void_observer.tscn
│   ├── props/
│   │   ├── debris_chunk.tscn
│   │   └── debris_fragment.tscn
│   ├── weapons/
│   │   ├── weapon_manager.tscn
│   │   ├── push_projectile.tscn
│   │   └── bazooka_projectile.tscn
│   └── world/                    # Legacy arena_zones (not main flow)
├── scripts/
│   ├── arena/                    # Generator, templates, floor builder
│   ├── combat_stats.gd
│   ├── game_manager.gd
│   ├── game_balance.gd
│   ├── player.gd
│   ├── arena_ui.gd
│   ├── enemies/
│   │   ├── arena_opponent.gd
│   │   └── enemy_weapon_manager.gd
│   ├── weapons/
│   ├── effects/
│   ├── props/
│   └── environment/
└── docs/
    ├── PROJECT_STATUS_REPORT.md  # This file
    ├── PROTOTYPE.md
    ├── README.md
    ├── art/
    ├── gameplay/
    ├── tech/
    ├── roadmap/
    └── ...
```

**Note:** No `assets/` folder; meshes/materials are mostly procedural or inline in scenes.

### Critical scripts

| File | Role |
|------|------|
| `game_manager.gd` | Match state, scoring, countdown |
| `game_balance.gd` | Void style, death timings, gib tuning |
| `player.gd` | FPS controller |
| `arena_generator.gd` | Procedural arenas + spawn validation |
| `arena_templates.gd` | Arena definitions |
| `combat_stats.gd` | Shield/health/overkill |
| `weapon_defs.gd` | Weapon balance |
| `push_hit_resolver.gd` | Hit resolution |
| `void_gore_sequence.gd` | Pit death cinematic |

---

## 13. IMPLEMENTED FEATURES CHECKLIST

| Feature | Status | Notes |
|---------|--------|-------|
| FPS movement (walk/sprint/jump) | Done | `player.gd` |
| Mouse look | Done | |
| Weapon switching (3 weapons) | Done | Keys 1–3 |
| Railgun raycast | Done | Beam tracer |
| Shotgun pellets | Done | 7 pellets |
| Bazooka + explosion | Done | Radius 5 |
| Shield + health | Done | `combat_stats.gd` |
| Knockback (player + AI) | Done | Clamped, airborne rules |
| AI opponent | Done | States, edge, weapons |
| Void ring-out scoring | Done | Y < -20 |
| Kill scoring | Done | |
| Match to 5 | Done | |
| Round countdown | Done | |
| VOID_GORE void death | Done | Default |
| Alt void death styles | Done | Config switch |
| Normal death corpse | Done | 2.5 s delay |
| Heavy death gibbing | Done | 1.8–2.2 s delay |
| ArenaGenerator | Done | 2 playable templates |
| Spawn validation | Done | Raycast floor |
| Destructible cover | Done | 4 types, HP |
| Cover floor validation | Done | Raycast |
| HUD (score, HP, weapon) | Done | `arena_ui.gd` |
| Void atmosphere | Done | Scene + script |
| Distant architecture | Done | Silhouettes |
| Spawn pads + optional debug markers | Done | Pads default; `debug_show_spawn_markers` |
| Real audio | Partial | `void_audio.gd` prints placeholders |
| Multiplayer | Not started | |
| Main menu / pause | Not started | Esc frees mouse only |
| 3+ arena templates | Partial | 3 TODO placeholders |
| True ragdoll | Not started | Capsule corpse only |
| Steam build | Not started | |
| Legacy arena scenes | Deprecated | Still in repo |

---

## 14. CURRENT BALANCE VALUES

### Combat

| Stat | Value |
|------|-------|
| Max shield | **100** |
| Max health | **100** |
| Win score | **5** |
| Void death Y | **-32** |
| Fall warning Y | **-18** |
| Arena fog (on deck) | **0.042** density |

### Weapons

| Weapon | Damage | Force / notes | Cooldown |
|--------|--------|---------------|----------|
| Railgun | 100 (2-hit kill) | push 68 | 1.6 s |
| Shotgun | 10×7 pellets (mesh 0.12) | push 30/pellet | 0.75 s |
| Bazooka direct | 100 (2-hit kill) | push 58 | 1.4 s |
| Bazooka explosion | 60 max | force 82, radius 5 | — |

### Death timings

| Event | Seconds |
|-------|---------|
| Normal kill → score | **2.5** |
| Heavy kill → score | **1.8–2.2** |
| VOID_GORE → score | **3.2** |
| Non-gore void fall | **2.0** + effect **1.2** |

### Heavy death thresholds

| Condition | Value |
|-----------|-------|
| Overkill | ≥ **25** |
| Single hit | ≥ **40** damage |

---

## 15. KNOWN ISSUES

### Bugs / risks

- **Legacy arena content** in repo can confuse which system is authoritative; only `ArenaGenerator` drives `main.tscn`.
- **Placeholder templates** (Pillar Ring, Twin Lanes, Central Ruins) warn and clone Pit Bridge if ever added to playable list.
- **All arenas at origin** — only one active floor at a time; correct by design but legacy scenes suggest multi-offset world.
- **`void_audio.gd`** — debug print placeholders only, no real SFX.
- **PROTOTYPE.md** may drift from code on minor details (always verify `game_balance.gd`).

### Physics / gameplay

- Enemy is `RigidBody3D`; player is `CharacterBody3D` — different knockback feel by design.
- Cover on layer **1** can block movement heavily in dense spawns.
- No networking prediction or lag compensation.

### Prototype limitations

- Single AI only.
- No progression, unlocks, or meta.
- No save/load.
- Minimal UI polish (win/lose label exists).
- `push_enemy.tscn` / old push demo enemy — not used in main loop.

### TODO (from code comments)

- Implement `PILLAR_RING`, `TWIN_LANES`, `CENTRAL_RUINS` in `arena_templates.gd`.
- Real audio implementation (`docs/roadmap/ROADMAP.md`).
- Playtest balance pass.

---

## 16. ROADMAP

### Short term

- Implement remaining **3 arena templates** with unique floor layouts.
- **Audio** — weapons, void, impacts, countdown.
- Remove or archive **legacy** `ArenaSelector` / `scenes/arenas` to reduce confusion.
- Balance pass on knockback and AI edge aggression.
- **Pause menu** and mouse sensitivity options.

### Mid term

- **2–3 polished arenas** with unique props (per `docs/roadmap/ROADMAP.md`).
- Main menu, match series UX.
- Controller support.
- Performance profiling (stable framerate target).
- Environmental storytelling beats.

### Long term

- **Multiplayer** (1v1).
- **Steam** release / demo.
- Animation on fighters (not just capsules).
- Expanded gore / void horror direction.
- Fully **procedural** arena generation beyond fixed templates.
- Progression, cosmetics, ranked mode (design-dependent).

---

## 17. PROJECT IDENTITY

### What the player should feel

| Emotion | Source |
|---------|--------|
| **Danger** | Small platforms, no guard rails on generated decks |
| **Void dread** | Fog, depth, falling, delayed void payoffs |
| **Ring-out tension** | Knockback tuned for horizontal displacement |
| **Fatality** | Heavy kills, gib collapse, void absorption |
| **Arena brutality** | Industrial stone, cold light, impersonal ruins |
| **Readable chaos** | Clear weapons roles, short rounds |

### Design pillars (from art docs)

- Brutalist + cosmic machinery + void-corrupted research aesthetic.
- Knock-off readability over simulation realism.
- Perceptual horror over explicit gore.

---

## 18. FINAL PROTOTYPE SCORECARD

| Category | Rating (1–10) | Rationale |
|----------|---------------|-----------|
| **Gameplay** | **7** | Solid 1v1 loop, two win conditions, three distinct weapons; limited content and single opponent. |
| **Physics** | **7** | Knockback is central and tunable; corpse/gib/cover interact well; not full ragdoll, some edge cases. |
| **Visual identity** | **6** | Strong void mood and docs; in-engine art is still placeholder geometry. |
| **Combat** | **7** | Shield layer, heavy vs normal deaths, weapon variety; needs audio and hit feedback polish. |
| **AI** | **6** | Competent edge/weapon logic; predictable at times; no difficulty tiers. |
| **Replayability** | **6** | Random arena + cover help; only 2 real layouts; same AI every match. |
| **Steam readiness** | **3** | Early prototype — no menu, audio, content breadth, or polish for commercial release. |

### Overall

**Neon Catacombs** is a **feature-rich internal prototype** with a clear identity (void pit fighter) and several systems that already work together: procedural validated arenas, destructible cover, cinematic void deaths, and knockback-first combat. The largest gaps for external players are **content volume** (arenas, modes), **presentation** (audio, UI, assets), and **production** infrastructure — not the absence of a core game loop.

---

*End of report. For day-to-day tuning, see `docs/PROTOTYPE.md`. For art canon, see `docs/art/ART_DIRECTION.md`.*
