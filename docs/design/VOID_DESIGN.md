# VOID — System Design (Reverse SDD)

Architecture and module ownership derived from the current Godot 4.6 codebase.

**Companion:** [VOID_SPEC.md](../specs/VOID_SPEC.md) · [CODEBASE_MAP.md](../CODEBASE_MAP.md) · [TECHNICAL_AUDIT.md](../TECHNICAL_AUDIT.md)

---

## High-level architecture

```
project.godot
├── Autoloads: VoidAudio, CombatVfxDirector, GladiatorLoadout, GameFlow
├── Main: gladiator_chamber.tscn
│     └── gladiator_chamber.gd (procedural hub)
└── arena_match.tscn
      ├── GameManager (round/match)
      ├── ArenaGenerator (procedural arena)
      ├── Player + ArenaOpponent
      └── VoidAtmosphere / VoidGasController / shared void backdrop
```

**Physics:** Jolt 3D. **Entry flow:** chamber → `GameFlow` → arena → `arena_match_bridge` → chamber.

---

## Main systems

| System | Role | Primary files |
|--------|------|----------------|
| **GameFlow** | Chamber ↔ arena scene change, return mood flag | `scripts/chamber/game_flow.gd` |
| **GameManager** | Scores, round states, countdown, void/kill death sequences | `scripts/game_manager.gd` |
| **GladiatorLoadout** | Weapon/armor/helmet persistence | `scripts/chamber/gladiator_loadout.gd` |
| **ArenaGenerator** | Per-round procedural arena | `scripts/arena/arena_generator.gd` |
| **Gladiator Chamber** | Hub geometry + interact placement | `scripts/chamber/gladiator_chamber.gd` |
| **CombatStats** | Shield/health single source of truth | `scripts/combat_stats.gd` |
| **PushHitResolver** | Damage, knockback, walls, explosions | `scripts/weapons/push_hit_resolver.gd` |
| **WeaponFiring** | Shared fire pipeline (player + enemy) | `scripts/weapons/weapon_firing.gd` |
| **ArenaOpponent** | AI, movement, combat, void fall | `scripts/enemies/arena_opponent.gd` |
| **Void gas / atmosphere** | Fall dread, fog, vignette | `void_gas_controller.gd`, `void_atmosphere.gd` |
| **Combat feedback** | Shield break, hit confirm, VFX hooks | `combat_feedback.gd`, `combat_vfx_director.gd`, `combat_audio.gd` |

---

## GameManager flow

```
_ready → _begin_match() → scores=0, COUNTDOWN
  → _run_countdown() [each round]
       → ArenaGenerator.generate_round_arena_async()
       → _clear_round_entities()
       → _respawn_fighters()
       → UI countdown 3-2-1-FIGHT
       → FIGHTING
  → [combat]
  → point scored:
       → void: report_*_void_fall → VoidGoreSequence / VoidDeathEffect → finish_*_void_death
       → kill: on_health_death → corpse/gib/dismember → _finish_round_after_score
  → score >= 5 → MATCH_OVER → match_over(player_won)
```

**States:** `COUNTDOWN`, `FIGHTING`, `ROUND_OVER`, `MATCH_OVER`.

**Anti double-score:** `_handling_round_end` flag during death sequences.

---

## Arena generation

**Pipeline** (`arena_generator.gd`):

1. Pick template (`arena_templates.gd`) — 5 playable layouts.
2. `ArenaMazeGenerator` — indestructible `StructuralWall` maze (4 profiles).
3. `ArenaWallSetGenerator` — destructible tactical cover.
4. `ArenaRouteValidator` — ≥2 routes, spawn clearance, corridor width.
5. `ArenaStructureBuilder` — floor, perimeter, fall zones, chamber pass.
6. Spawn raycast validation (up to 6 retries → Toxic Bridge fallback).

**Layers (inside → out):** continuous floor → structural maze → destructible cover → perimeter shell → fall markers.

**Visual passes (no gameplay collision):**

| Pass | File | Output |
|------|------|--------|
| Chamber pass | `arena_chamber_pass.gd` | Zones, void abyss, landmark, particles, lights |
| Megastructure | `arena_megastructure_pass.gd` | Distant ruin clusters in fog |

**Bounds exported to AI:** `safe_half_*`, `danger_half_*`, `arena_center`.

---

## Gladiator Chamber

**Scene:** `scenes/chamber/gladiator_chamber.tscn` (player + HUD; geometry procedural).

**Builder graph:**

```
ChamberRoot
  Architecture      — floor, ceiling, walls
  LoadoutBay        — alcoves + interact pedestals
  CommandArea       — map table, terminal decor
  ProgressionWall   — upgrade placeholders
  VoidWindow        — frame, glass, observatory decor
  Lighting          — zone spots
  Atmosphere        — dust particles
  DistantArchitecture — void_distant_architecture.tscn (sanitized: no HangingSpan)
```

**Chamber-only distant arch filter:** `_sanitize_chamber_distant_architecture()` removes `HangingSpan` and wide extras.

**Interact scripts:** `chamber_weapon_rack.gd`, `chamber_armor_pedestal.gd`, `chamber_helmet_stand.gd`, `chamber_arena_terminal.gd`, `chamber_player.gd`, `chamber_hud.gd`.

**Cleanup:** `_cleanup_chamber_visual_clutter()` — removes mid-height decor spans > 6 m (shell exempt).

---

## CombatStats

**Single owner** for shield and health on each fighter.

| API | Behavior |
|-----|----------|
| `apply_damage(amount, attacker)` | Shield first, then health; shield break once; `died` at health ≤ 0 |
| `record_hit(...)` | Stores last hit direction, force, source for corpse/gib |
| `reset_combat_stats()` | Full pool restore on round start |
| `is_heavy_death()` / `is_dismemberment_death()` | Death presentation selection |

**Signals:** `stats_changed`, `died`, `shield_broken`.

**Listeners:** `CombatFeedback`, `ArenaUI`, fighter death handlers, `GameManager.on_health_death`.

---

## Weapons

| Module | Responsibility |
|--------|----------------|
| `weapon_defs.gd` | IDs, damage, cooldowns, knockback, wall damage |
| `weapon_manager.gd` | Player fire, switch, aim integration |
| `enemy_weapon_manager.gd` | Enemy fire parity |
| `weapon_firing.gd` | Pellets, railgun ray, bazooka scene |
| `push_hit_resolver.gd` | All hit resolution + feedback hooks |
| `perforable_wall_grid.gd` | Railgun wall marking |

**Aim contract:** `Player.get_aim_global_transform()` — yaw on body, pitch on `AimPivot`. Enemy: `WeaponMount` forward.

---

## Destruction

| Type | Class / group | Behavior |
|------|---------------|----------|
| **StructuralWall** | `structural_wall.gd` | Indestructible; defines routes |
| **DestructibleWall** | `destructible_wall.gd` | HP, fracture via `wall_destruction.gd` |
| **Debris** | `debris_spawner.gd`, `debris_chunk.gd` | Round-spawned cover pieces |

Railgun: perforation grid, 0 wall HP. Shotgun/bazooka: HP damage per `WeaponDefs`.

---

## Gore / dismemberment

| Path | Trigger | Handler |
|------|---------|---------|
| Void ring-out | Y < void_y | `VoidGoreSequence`, `void_gore_sequence.gd` |
| Normal kill | health ≤ 0, not heavy | `CorpseSpawner` / `physics_corpse.gd` |
| Gib kill | heavy thresholds | `GibSpawner` |
| Dismemberment | `is_dismemberment_death()` | `DismembermentSpawner` |

**Tuning hub:** `GameBalance` — timelines, forces, lifetimes, silent absorption chance.

---

## AI

```
ArenaOpponent._physics_process
  → state machine (HUNTING … REPOSITIONING)
  → ArenaOpponentMovement (forces, edge, cover)
  → EnemyGladiatorLocomotion integration
  → _try_shot → EnemyWeaponManager
  → void Y check → report_enemy_void_fall
```

**Perception:** player ref, arena bounds, LOS raycasts, ring-out angle heuristics.

**Tuning exports:** `enemy_skill_level`, `enemy_reaction_time`, `enemy_aim_error_degrees`, weapon fire intervals.

---

## Animation / look-at

| Component | Role |
|-----------|------|
| `EnemyLookAtController` | Head/torso twist toward aim target; combat recovering state |
| `ProceduralEnemyAnimator` | Visual state from movement (idle, run, strafe, shoot, recovering, death) |
| `EnemyWeaponMount` | Weapon forward = fire direction |

**Player:** viewmodel bob visual-only; camera feel on `CameraFeelPivot`; FOV via `GladiatorFov` (single writer).

**Known gap:** enemy procedural layers can overlap mount aim; needs polish pass.

---

## UI / HUD

| Surface | File | Data source |
|---------|------|-------------|
| Arena HUD | `arena_ui.gd` | `GameManager` signals, countdown, death messages, void overlay |
| Crosshair | `crosshair.gd` | Stabilized aim; shield-break flash |
| Chamber HUD | `chamber_hud.gd` | `GladiatorLoadout` line + interact prompt |

Edge tension: `CombatVfxDirector.apply_edge_tension` → `ArenaUI.apply_edge_tension`.

---

## Audio hooks

| Autoload / module | Hooks |
|-------------------|-------|
| `VoidAudio` | Ambience, fall rush, danger pulse, gore timeline |
| `CombatAudio` | Weapon fire, hit confirm, shield break |
| `CombatFeedback` | Coordinates shield-break SFX + VFX once |
| `AudioStreamFactory` | Procedural fallbacks when `.ogg` missing |

No dedicated mix buses yet — Master only.

---

## File / module ownership (quick reference)

| Domain | Owner | Do not duplicate |
|--------|-------|------------------|
| Aim / pitch | `Player` → `AimPivot` | Camera feel must not drive pitch |
| FOV final | `GladiatorFov` → `player._process` | No second FOV writers |
| Combat damage | `PushHitResolver` → `CombatStats` | Score only via `GameManager` |
| Round / score | `GameManager` | |
| Arena layout | `ArenaTemplate` + generators | `ArenaStructureBuilder` builds only |
| Shield break FX | `CombatFeedback` | Once per shield transition |
| Chamber geometry | `gladiator_chamber.gd` | Interact scripts separate |
| Loadout save | `GladiatorLoadout` | Weapon applies in `arena_match_bridge` |

---

## Autoloads

| Name | Script | Notes |
|------|--------|-------|
| `VoidAudio` | `environment/void_audio.gd` | No `class_name` |
| `CombatVfxDirector` | `effects/combat_vfx_director.gd` | Procedural VFX |
| `GladiatorLoadout` | `chamber/gladiator_loadout.gd` | ConfigFile save |
| `GameFlow` | `chamber/game_flow.gd` | Scene transitions |

`GameManager` is **not** an autoload — lives in `arena_match.tscn`, group `game_manager`.

---

## Design guardrails (from workspace rules)

- Preserve Quake-style movement — no input smoothing on look.
- One camera pipeline: body yaw → AimPivot pitch → CameraFeelPivot → Camera3D.
- Visual-only chamber/arena passes must not alter combat tuning without explicit request.
- Modular scripts over growing god files (debt: `arena_opponent.gd`, `push_hit_resolver.gd` still large).

---

## Related docs

- [VOID_DESIGN_PHILOSOPHY.md](../VOID_DESIGN_PHILOSOPHY.md) — feel gate
- [GLADIATOR_CHAMBER.md](../GLADIATOR_CHAMBER.md) — chamber implementation
- [PROTOTYPE.md](../PROTOTYPE.md) — arena templates detail
