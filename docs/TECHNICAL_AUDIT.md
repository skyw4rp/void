# VOID — Technical Audit

Maintainability, coupling, duplication, and architectural risk review for the Godot 4.6 prototype (**Neon Catacombs**). Complements [CODEBASE_MAP.md](CODEBASE_MAP.md) (navigation) and [VOID_PROTOTYPE_AUDIT.md](VOID_PROTOTYPE_AUDIT.md) (design gaps).

**Scope reviewed:** `player.gd`, movement, weapons, enemy AI, arena generation, audio/VFX, shield/health/death, autoloads, `project.godot`.  
**No gameplay code was changed** for this document.

**Audit date:** Prototype with procedural maze arenas, `CombatFeedback` shield-break pipeline, `GladiatorFov` aim stack, Jolt physics.

---

## Executive summary

The prototype is **playable and coherent** for a 1v1 loop, with clear central hubs (`GameManager`, `PushHitResolver`, `WeaponFiring`, `ArenaGenerator`). Main technical debt is **concentration of responsibility** in a few large scripts, **group/`has_method` coupling**, and **inconsistent combat gates** (some paths check `is_fighting()`, others do not). Audio/VFX autoloads work but lack mix buses and round cleanup parity with projectiles/corpses.

| Severity | Count (approx.) | Themes |
|----------|-----------------|--------|
| **P0** | 1 | Combat damage bypasses round-state guard on direct `CombatStats` path |
| **P1** | 12 | God object scripts, resolver coupling, private API leakage, stale legacy assets |
| **P2** | 14 | Logging, naming, docs drift, missing tests, perf unknowns |

---

## Issue register

Each entry: **Area** · **Problem** · **Why it matters** · **Risk** · **Suggested fix** · **Files** · **Gameplay change?**

---

### P0 — Combat / round state

#### T-001 — Damage applies outside `FIGHTING` via `PushHitResolver`

| Field | Detail |
|-------|--------|
| **Area** | Shield/health / weapons |
| **Problem** | `PushHitResolver.apply_damage_to_target` calls `CombatStats.apply_damage` directly. Fighter `take_damage()` checks `GameManager.is_fighting()`, but the resolver path does not. Lingering projectiles, explosions, or rail traces can theoretically apply damage during `COUNTDOWN` / `ROUND_OVER` if anything is not cleared in time. |
| **Why it matters** | Double scoring, shield-break VFX during countdown, or deaths after round end undermine match integrity. |
| **Risk** | **P0** |
| **Suggested fix** | Add a single guard at the top of `apply_damage_to_target` (and optionally `apply_damage`) via `GameManager.is_fighting()` or `CombatStats` policy helper. Centralize in `CombatGate` static util. |
| **Files** | `scripts/weapons/push_hit_resolver.gd`, optionally `scripts/combat_stats.gd` |
| **Gameplay change?** | **Yes** — suppresses edge-case damage outside active fight; intended behavior. |

---

### P1 — Architecture & maintainability

#### T-002 — `arena_opponent.gd` is a god object (~1090 lines)

| Field | Detail |
|-------|--------|
| **Area** | Enemy systems |
| **Problem** | Single file owns AI state machine, movement forces, edge safety, cover, weapon AI, LOS, void fall, death, and arena bounds. |
| **Why it matters** | Any AI or combat tweak risks regressions; hard to review, test, or onboard. |
| **Risk** | **P1** |
| **Suggested fix** | Extract: `ArenaOpponentMovement`, `ArenaOpponentCombat`, `ArenaOpponentEdgeSafety` (composition or child nodes). Keep public API on root. |
| **Files** | `scripts/enemies/arena_opponent.gd` (+ new modules) |
| **Gameplay change?** | **No** if behavior-preserving refactor. |

#### T-003 — `push_hit_resolver.gd` is a universal combat hub (~625 lines)

| Field | Detail |
|-------|--------|
| **Area** | Weapons / damage |
| **Problem** | Static class handles knockback, damage, walls, fighters, explosions, rocket jump, VFX spawn, audio, crosshair — all cross-cutting concerns. |
| **Why it matters** | Every weapon or damage feature touches this file; high merge conflict and regression risk. |
| **Risk** | **P1** |
| **Suggested fix** | Split: `CombatDamage`, `CombatKnockback`, `CombatCoverDamage`; keep thin `PushHitResolver` facade. Move VFX/audio triggers to listeners on `CombatStats` signals where possible. |
| **Files** | `scripts/weapons/push_hit_resolver.gd`, `scripts/audio/combat_feedback.gd` |
| **Gameplay change?** | **No** if facade preserves order of operations. |

#### T-004 — `player.gd` mixes locomotion, camera, death, void (~635 lines)

| Field | Detail |
|-------|--------|
| **Area** | Player |
| **Problem** | One script: input, dodge, locomotion config, camera hierarchy mutation, FOV, knockback, void proxy, death/gib/corpse, game flow hooks. |
| **Why it matters** | Player feel changes require editing a large, easy-to-break file (e.g. `_setup_aim_camera_hierarchy`). |
| **Risk** | **P1** |
| **Suggested fix** | Extract `PlayerVoidController`, `PlayerDeathHandler`; keep movement/input on `player.gd`. |
| **Files** | `scripts/player.gd` |
| **Gameplay change?** | **No** if refactors are mechanical. |

#### T-005 — Widespread `get_first_node_in_group` + `has_method` / `call`

| Field | Detail |
|-------|--------|
| **Area** | Cross-cutting |
| **Problem** | 30+ scripts resolve `game_manager`, `player`, `arena_ui`, `arena_generator` by group string; many `has_method`/`call` chains (e.g. `GameManager`, `Crosshair`, `ArenaOpponent` hooks). |
| **Why it matters** | Renames fail at runtime; no static typing; duplicate lookup cost; unclear contracts. |
| **Risk** | **P1** |
| **Suggested fix** | Introduce typed facades: `GameServices` autoload with `@onready` refs set once, or export `NodePath`s on `main.tscn`. Prefer signals over `call()`. |
| **Files** | `game_manager.gd`, `player.gd`, `arena_opponent.gd`, `void_gas_controller.gd`, `combat_vfx_director.gd`, `arena_ui.gd`, `crosshair.gd`, … |
| **Gameplay change?** | **No** |

#### T-006 — Arena route validator “private” API used externally

| Field | Detail |
|-------|--------|
| **Area** | Arena generation |
| **Problem** | `ArenaMazeGenerator` and `ArenaWallSetGenerator` call `ArenaRouteValidator._build_grid`, `_bfs`, `_is_traversable`, `_local_to_cell`, `_cell_to_local`. |
| **Why it matters** | Underscore convention is meaningless in GDScript but signals unintended coupling; refactors to validator internals break maze/cover gen silently. |
| **Risk** | **P1** |
| **Suggested fix** | Expose public `ArenaRouteValidator.build_grid()`, `is_traversable()`, `find_path()`; keep internals private by convention in one file. |
| **Files** | `scripts/arena/arena_route_validator.gd`, `arena_maze_generator.gd`, `arena_wall_set_generator.gd` |
| **Gameplay change?** | **No** |

#### T-007 — Arena generation can fail silently after 6 attempts

| Field | Detail |
|-------|--------|
| **Area** | Arena generation |
| **Problem** | `ArenaGenerator.generate_round_arena_async` retries then falls back to Toxic Bridge; on total failure only `push_error` — no user-facing error UI. |
| **Why it matters** | Rare layouts or bugs could leave broken spawns/routes in production builds with only console noise. |
| **Risk** | **P1** |
| **Suggested fix** | Assert in debug; log structured reason (maze fail vs spawn fail); optional HUD toast; metric counter. |
| **Files** | `scripts/arena/arena_generator.gd` |
| **Gameplay change?** | **No** (telemetry/UI only); fallback behavior unchanged unless you add hard fail. |

#### T-008 — `CombatStats.apply_damage` does not gate round state

| Field | Detail |
|-------|--------|
| **Area** | Shield/health |
| **Problem** | Related to T-001: `apply_damage` always runs if amount > 0 and not dead; emits `died` / `shield_broken` regardless of `GameManager` state. |
| **Why it matters** | Feedback and signals can fire when design expects “inactive” combat. |
| **Risk** | **P1** |
| **Suggested fix** | Policy flag on `CombatStats` (`combat_active`) set by `GameManager` on state transitions, or guard in `apply_damage`. |
| **Files** | `scripts/combat_stats.gd`, `scripts/game_manager.gd` |
| **Gameplay change?** | **Yes** — same as T-001. |

#### T-009 — Dual damage entry points with different side effects

| Field | Detail |
|-------|--------|
| **Area** | Shield/health |
| **Problem** | Fighters: `take_damage()` → `record_hit` + `apply_damage` (no `hit_world`). Resolver: `record_hit` + `apply_damage` + audio/VFX/crosshair. Order and fields differ. |
| **Why it matters** | Shield-break position may fall back to torso; inconsistent flinch/animator triggers if something calls `take_damage` only. |
| **Risk** | **P1** |
| **Suggested fix** | One path: `CombatStats.receive_hit(amount, context: HitContext)` with world pos, source, attacker; deprecate duplicate wrappers. |
| **Files** | `combat_stats.gd`, `push_hit_resolver.gd`, `player.gd`, `arena_opponent.gd` |
| **Gameplay change?** | **No** if context populated consistently; **maybe** if fixing missing `hit_world`. |

#### T-010 — Runtime camera hierarchy mutation

| Field | Detail |
|-------|--------|
| **Area** | Player / camera |
| **Problem** | `_setup_aim_camera_hierarchy()` reparents `Camera3D` under new `AimPivot` / `CameraFeelPivot` at runtime if not in scene. |
| **Why it matters** | Scene file shows flat `Player/Camera3D`; editor paths ≠ runtime paths; easy to break `WeaponManager` parent assumptions. |
| **Risk** | **P1** |
| **Suggested fix** | Commit final hierarchy in `main.tscn` / player scene; make setup idempotent one-time migration only. |
| **Files** | `scenes/main.tscn`, `scripts/player.gd` |
| **Gameplay change?** | **No** |

#### T-011 — `PerforableWallGrid` / modular perforation unused in build pipeline

| Field | Detail |
|-------|--------|
| **Area** | Arena / weapons |
| **Problem** | `perforable_wall_grid.gd`, `wall_perforation_cell.gd`, `WeaponDefs` comments reference modular holes; builder uses `DestructibleWall` + pierce marks only. |
| **Why it matters** | Dead code paths confuse contributors; railgun behavior documented inconsistently across docs. |
| **Risk** | **P1** |
| **Suggested fix** | Archive or wire into `ArenaStructureBuilder`; update docs to “pierce marks only” until wired. |
| **Files** | `scripts/arena/perforable_wall_grid.gd`, `docs/PROTOTYPE.md`, `PROJECT_STATUS_REPORT.md` |
| **Gameplay change?** | **Yes** if wiring grid (new behavior); **No** if delete/archive docs only. |

#### T-012 — Legacy arena scenes not in round flow

| Field | Detail |
|-------|--------|
| **Area** | Arena generation |
| **Problem** | `scenes/arenas/*.tscn` + `arena_zone.gd` + `arena_selector.gd` exist; live flow uses `ArenaGenerator` only. |
| **Why it matters** | Contributors may edit wrong assets; duplicate tuning surfaces. |
| **Risk** | **P1** |
| **Suggested fix** | Move to `archive/` or delete; add README in `scenes/arenas/`. |
| **Files** | `scenes/arenas/*`, `scripts/environment/arena_zone.gd`, `arena_selector.gd` |
| **Gameplay change?** | **No** if unused. |

#### T-013 — `push_enemy.gd` orphan prototype enemy

| Field | Detail |
|-------|--------|
| **Area** | Enemy systems |
| **Problem** | Simple chase `RigidBody3D` script unrelated to `ArenaOpponent`; not referenced in `main.tscn`. |
| **Why it matters** | Name collision with “enemy”; risk of accidental use. |
| **Risk** | **P1** |
| **Suggested fix** | Rename to `prototype_push_enemy.gd` or remove. |
| **Files** | `scripts/push_enemy.gd` |
| **Gameplay change?** | **No** |

---

### P2 — Quality, config, polish

#### T-014 — Input action `sprint` triggers dodge, not sprint

| Field | Detail |
|-------|--------|
| **Area** | Player / movement / `project.godot` |
| **Problem** | `sprint` action is only used in `player.gd` as `try_player_dodge(..., true)` — not a speed modifier. |
| **Why it matters** | Misleading for tuning docs and new contributors; Shift may confuse players expecting sprint. |
| **Risk** | **P2** |
| **Suggested fix** | Rename input to `dodge` or add real sprint modifier in `GladiatorLocomotion`. |
| **Files** | `project.godot`, `scripts/player.gd` |
| **Gameplay change?** | **Yes** if adding sprint; **No** if rename only. |

#### T-015 — No audio buses in `project.godot`

| Field | Detail |
|-------|--------|
| **Area** | Audio / autoloads |
| **Problem** | All `VoidAudio` players use `Master` bus; no `Void` / `Combat` / `UI` separation. |
| **Why it matters** | Cannot rebalance mix without code; void drone competes with hit confirm. |
| **Risk** | **P2** |
| **Suggested fix** | Add buses in project settings; assign in `void_audio.gd` / UI players. |
| **Files** | `project.godot`, `scripts/environment/void_audio.gd` |
| **Gameplay change?** | **No** (mix only). |

#### T-016 — `HIT_SOUND_COOLDOWN_SEC` (45 ms) global throttle

| Field | Detail |
|-------|--------|
| **Area** | Audio |
| **Problem** | One timestamp gates all hit-confirm sounds; railgun pierce multi-hit may drop shield ticks; shield break uses separate path (good). |
| **Why it matters** | Rapid shotgun pellets or pierce may sound understuffed. |
| **Risk** | **P2** |
| **Suggested fix** | Per-source cooldown or priority queue; exempt shield-break. |
| **Files** | `scripts/environment/void_audio.gd` |
| **Gameplay change?** | **No** (audio clarity). |

#### T-017 — Combat VFX nodes not cleared on round start

| Field | Detail |
|-------|--------|
| **Area** | VFX / autoloads |
| **Problem** | `GameManager` clears projectiles, corpses, rail marks; does not clear `combat_vfx` group. Nodes self-free via timers (up to ~0.45s). |
| **Why it matters** | Visual clutter possible at round start; autoload tweens may reference freed nodes if arena reload is fast. |
| **Risk** | **P2** |
| **Suggested fix** | `CombatVfxDirector.clear_active()` in round cleanup; kill tweens. |
| **Files** | `scripts/effects/combat_vfx_director.gd`, `scripts/game_manager.gd` |
| **Gameplay change?** | **No** |

#### T-018 — Procedural VFX/audio not performance-profiled

| Field | Detail |
|-------|--------|
| **Area** | VFX / audio |
| **Problem** | Many `CPUParticles3D` + one-shots per shot/hit; 10-slot 3D audio pool. |
| **Why it matters** | Unknown headroom on low-end hardware; pierce + shotgun could spike. |
| **Risk** | **P2** |
| **Suggested fix** | Profiler markers; caps per frame; object pool for particles. |
| **Files** | `combat_vfx_director.gd`, `void_audio.gd` |
| **Gameplay change?** | **No** unless caps drop effects. |

#### T-019 — Excessive `print()` in hot paths

| Field | Detail |
|-------|--------|
| **Area** | Cross-cutting |
| **Problem** | `arena_generator.gd` (~22 prints per gen), `push_hit_resolver` impulse logs, `combat_stats._log_stats`, AI edge logs. |
| **Why it matters** | Console spam in production; minor perf cost. |
| **Risk** | **P2** |
| **Suggested fix** | `GameBalance.DEBUG_COMBAT` flag or Godot logging categories. |
| **Files** | Multiple |
| **Gameplay change?** | **No** |

#### T-020 — `arena_ui` signal connections without disconnect

| Field | Detail |
|-------|--------|
| **Area** | UI |
| **Problem** | `_bind_combat_stats` connects `shield_broken` / `stats_changed` once via `call_deferred`; hot reload or scene reinstantiation could duplicate connections. |
| **Why it matters** | Double HUD flashes or duplicate handlers in editor iteration. |
| **Risk** | **P2** |
| **Suggested fix** | Connect in `_ready` with `CONNECT_ONE_SHOT` or guard `if not stats.shield_broken.is_connected(...)`. |
| **Files** | `scripts/arena_ui.gd` |
| **Gameplay change?** | **No** |

#### T-021 — Player fire origin at camera, not muzzle

| Field | Detail |
|-------|--------|
| **Area** | Weapons |
| **Problem** | `WeaponManager.try_fire` uses `_camera.global_position` for ray/projectile origin; enemy uses muzzle. |
| **Why it matters** | Near-wall shots can originate inside geometry; slight parity mismatch vs enemy. |
| **Risk** | **P2** |
| **Suggested fix** | Muzzle offset node on viewmodel; document as intentional for prototype. |
| **Files** | `scripts/weapons/weapon_manager.gd` |
| **Gameplay change?** | **Yes** — trace start moves slightly. |

#### T-022 — Collision layers undocumented in project settings

| Field | Detail |
|-------|--------|
| **Area** | `project.godot` / physics |
| **Problem** | No named layer map in `project.godot`; code uses layer `1` for gameplay, `8` for corpses/gibs per scripts. `ARCHITECTURE.md` may drift. |
| **Why it matters** | Wrong mask breaks floor rays, LOS, or projectile hits. |
| **Risk** | **P2** |
| **Suggested fix** | Document layers 1–8 in `project.godot` comments + `docs/tech/ARCHITECTURE.md`. |
| **Files** | `project.godot`, docs |
| **Gameplay change?** | **No** |

#### T-023 — `VoidAudio` autoload has no `class_name` (intentional) but splits discovery

| Field | Detail |
|-------|--------|
| **Area** | Autoloads |
| **Problem** | Must use `VoidAudio` autoload name or `CombatAudio` wrapper; cannot type-hint `VoidAudio` class. |
| **Why it matters** | Slightly harder static analysis; duplicate static `_instance` pattern in two autoloads. |
| **Risk** | **P2** |
| **Suggested fix** | Keep as-is; document pattern in `CODEBASE_MAP.md` (done). Optional `ICombatAudio` interface. |
| **Files** | `void_audio.gd`, `combat_vfx_director.gd` |
| **Gameplay change?** | **No** |

#### T-024 — `GameManager._ready` → `await` countdown chain

| Field | Detail |
|-------|--------|
| **Area** | Scoring/rounds |
| **Problem** | Match starts via deferred async countdown from `_ready`; errors in generation await inside UI flow. |
| **Why it matters** | If `ArenaGenerator` missing, warning only — fighters may spawn at default transforms. |
| **Risk** | **P2** |
| **Suggested fix** | Validate scene in editor plugin or boot check scene. |
| **Files** | `scripts/game_manager.gd`, `scenes/main.tscn` |
| **Gameplay change?** | **No** |

#### T-025 — Tuning split across `player.gd`, `GameBalance`, `WeaponDefs`, AI exports

| Field | Detail |
|-------|--------|
| **Area** | Movement / weapons / enemy |
| **Problem** | No single table for “knockback vs dodge vs weapon”; enemy `max_speed` ≠ player locomotion caps. |
| **Why it matters** | Balance passes require many files; easy to create PvE feel mismatch. |
| **Risk** | **P2** |
| **Suggested fix** | Expand `game_balance.gd` or CSV import for designers; keep exports as overrides. |
| **Files** | `game_balance.gd`, `weapon_defs.gd`, `player.gd`, `arena_opponent.gd` |
| **Gameplay change?** | **No** unless retuning. |

#### T-026 — `docs/tech/ARCHITECTURE.md` partially stale

| Field | Detail |
|-------|--------|
| **Area** | Docs |
| **Problem** | Architecture doc predates maze gen, `CombatVfxDirector`, `CombatFeedback`, aim hierarchy. |
| **Why it matters** | Wrong mental model for audits and agents. |
| **Risk** | **P2** |
| **Suggested fix** | Sync with `CODEBASE_MAP.md` or merge sections. |
| **Files** | `docs/tech/ARCHITECTURE.md` |
| **Gameplay change?** | **No** |

#### T-027 — `arena_opponent` AI raycasts share mask with all layer-1 geometry

| Field | Detail |
|-------|--------|
| **Area** | Enemy |
| **Problem** | LOS uses `collision_mask = 1`; cannot distinguish structural vs destructible vs fighters without filtering in code. |
| **Why it matters** | Cover logic may treat indestructible maze as “wall” correctly but fragile if layers split later. |
| **Risk** | **P2** |
| **Suggested fix** | When adding layers, update LOS + floor probes together. |
| **Files** | `scripts/enemies/arena_opponent.gd`, `scripts/arena/arena_generator.gd` |
| **Gameplay change?** | **Maybe** if masks change. |

---

## Area summaries (by review scope)

### `scripts/player.gd`

- **Strengths:** Clear locomotion integration; stable aim pivot API; void/death hooks for `GameManager`.
- **Weaknesses:** Monolith; runtime camera surgery; `sprint` = dodge; TODO on respawn feedback (line ~386).
- **Key deps:** `GladiatorLocomotion`, `CombatDodge`, `GladiatorFov`, `GladiatorCameraFeel`, `CombatStats`, groups.

### Movement (`scripts/movement/*`)

- **Strengths:** Pure `RefCounted` logic — testable in isolation; FOV separated from camera roll.
- **Weaknesses:** Not reused by enemy; config duplicated via `player._locomotion_config()` dictionary.
- **Files:** `gladiator_locomotion.gd`, `combat_dodge.gd`, `gladiator_camera_feel.gd`, `gladiator_fov.gd`.

### Weapon systems

- **Strengths:** `WeaponDefs` + `WeaponFiring` shared by player/enemy; consistent cooldown pattern.
- **Weaknesses:** `PushHitResolver` god module; railgun loop complexity in `weapon_firing.gd`; explosion uses full `collision_mask` (`0xFFFFFFFF`) — may hit unexpected layers as project grows.
- **Files:** `weapon_defs.gd`, `weapon_firing.gd`, `weapon_manager.gd`, `enemy_weapon_manager.gd`, `push_projectile.gd`, `bazooka_projectile.gd`, `push_explosion.gd`, `beam_tracer.gd`.

### Enemy systems

- **Strengths:** Aim cache every physics frame before AI branches; weapon mount sync; rich arena-aware behavior.
- **Weaknesses:** File size; physics-tuned forces hard to regression-test; debug flags scattered.
- **Files:** `arena_opponent.gd`, `enemy_weapon_mount.gd`, `enemy_weapon_manager.gd`, `enemy_look_at_controller.gd`, `procedural_enemy_animator.gd`.

### Arena generation

- **Strengths:** Layered pipeline (template → maze → cover → validate → build); route detour requirement; continuous deck invariant.
- **Weaknesses:** Private validator coupling; generation logs only; fallback masks failures; `PerimeterConfig.destructible_ratio` unused.
- **Files:** `arena_generator.gd`, `arena_templates.gd`, `arena_maze_generator.gd`, `arena_wall_set_generator.gd`, `arena_route_validator.gd`, `arena_structure_builder.gd`, builders.

### Audio / VFX

- **Strengths:** `AudioStreamFactory` asset override pattern; `CombatFeedback` single shield-break entry; autoload tunable exports.
- **Weaknesses:** No buses; pool size fixed; VFX procedural only; `CombatVfxDirector` uses `create_tween` on autoload (OK but no central clear).
- **Files:** `void_audio.gd`, `audio_stream_factory.gd`, `combat_audio.gd`, `combat_feedback.gd`, `combat_vfx_director.gd`, effect scripts.

### Shield / health / death flow

- **Strengths:** Shield-first damage; `shield_broken` once per transition; `CombatFeedback` avoids duplicate break VFX; death types (gib/dismember/void) centralized in `GameBalance`.
- **Weaknesses:** Round-state guard gap (T-001/T-008); `died` → `GameManager.on_health_death` relies on `_handling_round_end` flag set inside handler (works for first death); void finish methods score only if flag set.
- **Files:** `combat_stats.gd`, `combat_feedback.gd`, `game_manager.gd`, `player.gd`, `arena_opponent.gd`.

### Autoloads

| Autoload | Role | Risks |
|----------|------|-------|
| `VoidAudio` | Void + combat 3D audio | No `class_name`; Master bus only; static API + `_instance` |
| `CombatVfxDirector` | Combat particles/lights | Null `_instance` if disabled; no round clear |

### `project.godot`

- Jolt physics, D3D12 on Windows, Forward+.
- Inputs: move, jump, **sprint (dodge)**, shoot, weapon_1–3.
- **No** layer names, **no** audio buses, **no** dedicated test scene entries.
- Only two autoloads — rest is scene-singleton via groups.

---

## Safe refactors

Low risk, **no intended gameplay change** if done carefully:

| Refactor | Rationale |
|----------|-----------|
| Extract `ArenaRouteValidator` public API | Removes cross-file `_` calls |
| Add `CombatVfxDirector.clear_active()` on round cleanup | Prevents visual carryover |
| Consolidate debug `print` behind `DEBUG_*` flags | Cleaner console |
| Rename input `sprint` → `dodge` | Honest naming |
| Document collision layers in project + ARCHITECTURE | Safer physics edits |
| Sync `docs/tech/ARCHITECTURE.md` with CODEBASE_MAP | Doc accuracy |
| Archive `scenes/arenas/*` + `push_enemy.gd` | Less confusion |
| `arena_ui` one-shot signal connections | Hot reload safety |
| Split `CombatAudio` / thin wrappers only | Already mostly thin |

---

## Do not touch yet

High blast radius without test harness:

| Area | Reason |
|------|--------|
| **`PushHitResolver` damage order** | Shield/audio/VFX/crosshair ordering is implicit |
| **`WeaponFiring` railgun pierce loop** | Gameplay + VFX + damage intertwined |
| **`arena_opponent.gd` AI state machine** | Fragile emergent behavior; no automated regression |
| **`player._setup_aim_camera_hierarchy`** | Breaks weapons/aim if scene paths wrong |
| **`GameManager` async round loop** | Race with void sequences and scoring flags |
| **Maze + cover generation parameters** | Directly affects fairness and routes |
| **Wire `PerforableWallGrid`** | Would change railgun wall behavior vs marks-only design |
| **Retune `VoidGasController` fog/FOV** | Strong design gate; couples to feel docs |

---

## Needs tests / debug tools

| System | Recommended tool / test |
|--------|------------------------|
| Arena route + spawn | Headless or scene test: every template generates ≥2 routes, valid spawns (property test over seeds) |
| Combat damage | Unit test: shield break fires once; `apply_damage` respects combat gate after T-001 fix |
| Weapons | Scene test: each weapon hits fighter, wall, structural wall — expect no damage on structural |
| Shield break | Scene test: break triggers `CombatFeedback` + skips hit-confirm on same frame |
| AI | Debug overlay: state, LOS, fire block reason (partially exists via `debug_ai_fire`) |
| Audio | Bus meter scene; pool exhaustion logging |
| VFX | Counter for active `combat_vfx` nodes per frame |
| Round flow | Integration test: countdown → fight → kill → score → regen without duplicate signals |
| Void fall | Y-threshold test with mocked `GameManager` states |

**Existing debug hooks to use:**

- `ArenaGenerator.debug_show_route`, `debug_show_spawn_markers`
- `ArenaOpponent.debug_ai_movement`, `debug_ai_fire`
- `EnemyWeaponMount.debug_show_weapon_forward`, `debug_show_muzzle`
- Autoload export tunables (`VoidAudio`, `CombatVfxDirector`)

---

## Positive findings (maintain)

- **Shared weapon pipeline** (`WeaponFiring`) keeps PvP parity manageable.
- **`CombatFeedback`** is the right direction for one-shot shield break (extend pattern for other global combat events).
- **Arena layer cake** (structural maze + destructible cover) separates fairness from variation.
- **`GameBalance`** centralizes void/death timing — good single knob file.
- **Group-based round cleanup** for projectiles/corpses/gibs is systematic.
- **Structural vs destructible** distinction in `PushHitResolver` + groups is clear.

---

## Suggested priority order

1. **T-001 / T-008** — Combat gate (small change, high integrity).
2. **T-006** — Public route validator API (maintainability).
3. **T-017** — VFX round clear (polish).
4. **T-002 / T-003 / T-004** — Split god files (schedule when adding features).
5. **T-011 / T-012 / T-013** — Legacy cleanup (docs + deletions).
6. **T-015** — Audio buses (mix quality).

---

## Related documents

- [CODEBASE_MAP.md](CODEBASE_MAP.md) — Navigation and flows
- [VOID_PROTOTYPE_AUDIT.md](VOID_PROTOTYPE_AUDIT.md) — Design/feel gaps
- [PROTOTYPE.md](PROTOTYPE.md) — Implementation reference
- [.cursor/rules/void-design.mdc](../.cursor/rules/void-design.mdc) — Agent design gate

---

*This audit is descriptive of the repository at audit time. Re-run after major feature branches (arena, audio, AI).*
