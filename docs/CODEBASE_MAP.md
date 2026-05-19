# VOID — Codebase Map

Technical ownership reference for **Neon Catacombs / VOID** (Godot 4.6). Use with [PROTOTYPE.md](PROTOTYPE.md), [TECHNICAL_AUDIT.md](TECHNICAL_AUDIT.md), [VOID_DESIGN_PHILOSOPHY.md](VOID_DESIGN_PHILOSOPHY.md), and `.cursor/rules/void-code-safety.mdc`.

**Entry:** `res://scenes/chamber/gladiator_chamber.tscn` · **Arena duel:** `res://scenes/arena/arena_match.tscn` · **Autoloads:** `VoidAudio`, `CombatVfxDirector`, `GladiatorLoadout`, `GameFlow` · **Win:** first to **5** rounds (`GameManager.WIN_SCORE`) · **Legacy arena scene:** `scenes/main.tscn`

---

## 1. System ownership table

| System | Owner script(s) | Inputs | Outputs | Dependencies | Notes |
|--------|-------------------|--------|---------|--------------|-------|
| **Player** | `scripts/player.gd` | Input actions, `GameManager` state, floor collisions | `velocity`, transform, movement signals, void/death hooks | `GladiatorLocomotion`, `CombatDodge`, `CombatStats`, groups `player` | `CharacterBody3D`; reparents camera at runtime if needed |
| **Aim** | `scripts/player.gd` (`AimPivot`) | Mouse motion, `LOOK_PITCH_*` clamps | `get_aim_global_transform()`, `get_aim_forward()` | `WeaponManager` reads aim; group `player_aim` | Yaw on body, pitch on `AimPivot` only |
| **Camera feel** | `scripts/movement/gladiator_camera_feel.gd` | `GladiatorLocomotion.StepResult`, input, dodge state | Roll + offset on `CameraFeelPivot` | Called from `player._physics_process` / `_process` | Does **not** own pitch or FOV |
| **FOV** | `scripts/movement/gladiator_fov.gd` | Speed, land impact, void fall, weapon pulse | `camera.fov` via `player._process` | `GameBalance.VOID_FALL_FOV_MAX_ADD`, player exports | **Single writer** to `Camera3D.fov` |
| **Weapons** | `weapon_manager.gd`, `weapon_firing.gd`, `weapon_defs.gd`, `push_hit_resolver.gd` | Aim transform, `GameManager.is_fighting()`, scene root | Projectiles, beams, damage, knockback, audio/VFX hooks | `CombatStats`, `CombatAudio`, `CombatVfxDirector` | Shared player + enemy via `WeaponFiring` |
| **Enemy AI** | `arena_opponent.gd`, `enemy_gladiator_locomotion.gd`, `arena_opponent_movement.gd` | Player ref, arena bounds, walls LOS, `CombatStats` | Parity velocity on `RigidBody3D`, fire, states | `EnemyWeaponManager`, `EnemyLookAtController`, `ArenaGenerator` | Human-like: reaction/aim error/skill exports |
| **Arena generation** | `arena_generator.gd`, `arena_templates.gd`, `arena_maze_generator.gd`, `arena_wall_set_generator.gd`, `arena_route_validator.gd`, `arena_structure_builder.gd` | Template id, RNG seed | `ActiveArena` geometry, spawns, bounds dict | `GameManager._generate_round_arena` | Maze → cover → validate → build |
| **Destructible walls** | `destructible_wall.gd`, `wall_destruction.gd` | `damage_cover()` from resolver | HP, fracture, rubble | `WeaponDefs` wall damage; group `destructible_wall` | Railgun does not deal wall HP |
| **Audio** | `environment/void_audio.gd` (autoload), `audio/combat_audio.gd`, `audio/combat_feedback.gd`, `audio_stream_factory.gd` | 3D positions, weapon/hit events | `AudioStreamPlayer` / `AudioStreamPlayer3D` | `WeaponDefs`, `CombatStats` transitions | No `class_name` on autoload; Master bus only |
| **VFX** | `effects/combat_vfx_director.gd` (autoload), beam/flash/mark scripts | Hit positions, weapon id, edge tension | Particles, lights, UI flash via `ArenaUI` | `VoidGasController`, `CombatFeedback` | Procedural; group `combat_vfx` |
| **Shield** | `scripts/combat_stats.gd` | `apply_damage` amount | `shield` int, `shield_broken` signal | `CombatFeedback` on break | Absorbs damage before health |
| **Health** | `scripts/combat_stats.gd` | Overflow after shield | `health` int, `died` signal | `GameManager.on_health_death` | Death at `health <= 0` |
| **Death** | `player.gd`, `arena_opponent.gd`, `game_manager.gd`, spawners | `CombatStats.died`, void reports | Corpses/gibs, UI messages, scoring | `GameBalance`, `CorpseSpawner`, `DismembermentSpawner`, `VoidGoreSequence` | Multiple presentation paths by damage type |
| **UI** | `scripts/arena_ui.gd`, `scripts/ui/crosshair.gd` | `GameManager` signals, `CombatStats`, weapons | Labels, overlays, crosshair draw | Groups `arena_ui`, `crosshair` | Edge overlays created in code |
| **Round system** | `scripts/game_manager.gd` | Void/health death callbacks | Scores, `RoundState`, countdown signals | `ArenaGenerator`, fighter groups | `_handling_round_end` anti double-score |
| **Void systems** | `void_gas_controller.gd`, `void_atmosphere.gd`, `void_distant_architecture.gd`, `void_gore_sequence.gd`, `void_death_effect.gd` | Player Y, fall flag, depth_t | Fog, vignette, particles, gore timeline | `VoidAudio`, `GameBalance`, `ArenaUI` | Ring-out Y ≈ -20; death Y -32 |

---

## 2. Full round flow

### Match bootstrap

```
GameManager._ready → _begin_match()
  → scores = 0, state = COUNTDOWN
  → score_changed
  → _run_countdown()  // first round
```

### Countdown (each round)

```
state = COUNTDOWN
await ArenaGenerator.generate_round_arena_async()
  → pick ArenaTemplates id (max 6 attempts)
  → ArenaMazeGenerator.apply (structural walls)
  → ArenaWallSetGenerator.apply (destructible cover)
  → ArenaRouteValidator (≥2 routes, spawn clearance)
  → ArenaStructureBuilder.build (incl. ArenaChamberPass) → ActiveArena
  → spawn raycast validation
_clear: projectiles, corpses, void_effect, gib_chunk, dismember, railgun VFX, debris
_spawn_round_debris (DebrisSpawner)
death_message_hidden, void_overlay off
_respawn_fighters (transforms + CombatStats.reset)
UI: "3" → "2" → "1" → "FIGHT!"
countdown_hidden
state = FIGHTING
```

### Spawn

| Fighter | Source | Extra |
|---------|--------|-------|
| Player | `ArenaGenerator.get_player_spawn_transform()` | `player.arena_respawn()`, capsule offset |
| Enemy | `ArenaGenerator.get_enemy_spawn_transform()` | `apply_arena_bounds_from_dict`, aim refresh |
| Pads | `SpawnPads` children | Floor-aligned via raycast |

### Fight (active combat)

- `GameManager.is_fighting() == true`
- Player: input → locomotion → `WeaponManager.try_fire` (gated)
- Enemy: `_physics_process` → AI → `_try_shot` → `EnemyWeaponManager.try_fire`
- Void edge: `VoidGasController` + `CombatVfxDirector.apply_edge_tension` when on deck perimeter

### Combat (hit pipeline)

```
WeaponFiring / projectile collision
  → PushHitResolver.apply_*_hit
  → apply_damage_to_target OR knockback-only
       → CombatStats.record_hit
       → CombatStats.apply_damage
       → CombatAudio.play_hit_confirm
       → CombatVfxDirector.spawn_fighter_hit
       → Crosshair.notify_player_damage_to (if player hit enemy)
```

**Note:** `apply_damage_to_target` does not currently call `is_fighting()` (see P0 in §5).

### Shield damage

```
apply_damage with shield > 0
  → shield reduced (health unchanged if fully absorbed)
  → stats_changed
  → hit_confirm shield sound (unless break frame)
  → small shield hit VFX (not on same frame as break)
```

### Shield break (once per transition)

```
shield_before > 0 AND shield_after <= 0
  → CombatStats.shield_broken.emit(source)
  → CombatFeedback.on_shield_broken
       → CombatVfxDirector.play_shield_break_event
       → CombatAudio.play_shield_break (hit_confirm skipped)
       → player.notify_shield_broken (if player)
       → crosshair.notify_enemy_shield_broken (if player broke enemy)
  → ArenaUI stats label flash (shield_broken signal)
```

### Death

**Health zero:**

```
CombatStats.apply_damage → health <= 0
  → died.emit(attacker)
  → fighter._on_combat_died
       → corpse / dismember / hide meshes
       → GameManager.on_health_death(player_died, ...)
       → wait KILL_DEATH_VIEW_SEC / dismember timing
       → score += 1
       → _finish_round_after_score
```

**Void ring-out:**

```
fighter Y < threshold while fighting
  → _report_void_fall (once)
  → GameManager._run_*_void_death_sequence
       → void overlay, begin_void_dying, VoidGoreSequence or VoidDeathEffect
       → finish_*_void_death → score → _finish_round_after_score
```

### Score

```
_finish_round_after_score
  → score_changed
  → if score >= 5: MATCH_OVER, match_over
  → else: state = ROUND_OVER → await _run_countdown() again
  → _handling_round_end = false
```

### Reset (between rounds)

- Geometry: full regen (not incremental)
- Stats: `reset_combat_stats()` on both fighters
- World entities: group-based `queue_free` (see `GameManager._clear_*`)

---

## 3. File map (major scripts)

Legend: **Writes** = authoritative mutations. **Reads** = primary consumers.

### Core / round

#### `scripts/game_manager.gd`

| | |
|--|--|
| **Purpose** | Match flow, scoring, countdown orchestration, round cleanup |
| **Public API** | `is_fighting()`, `is_round_active()`, `get_*_spawn()`, `report_*_void_fall`, `finish_*_void_death`, `on_health_death`, `get_arena_generator()` |
| **Signals** | `score_changed`, `match_over`, `countdown_*`, `death_message_*`, `void_overlay_changed` |
| **Writes** | `player_score`, `enemy_score`, `state`, `_handling_round_end` |
| **Reads** | Groups `arena_generator`, `player`, `arena_opponent`, `debris_spawner` |
| **Risks** | Async arena gen during countdown; void finish scoring depends on flags |

#### `scripts/game_balance.gd`

| | |
|--|--|
| **Purpose** | Central tuning constants (void, death timing, gib, fog Y) |
| **Public API** | `class_name GameBalance` — const accessors, `void_fog_*`, `uses_void_gore_cinematic()` |
| **Signals** | None |
| **Writes** | None (const) |
| **Reads** | Most death/void/fog systems |
| **Risks** | Not all balance lives here (weapon stats in `WeaponDefs`, player exports) |

#### `scripts/combat_stats.gd`

| | |
|--|--|
| **Purpose** | Shield/health pool, hit memory, death classification |
| **Public API** | `apply_damage`, `record_hit`, `reset_combat_stats`, `is_dead`, `is_heavy_death`, `is_dismemberment_death` |
| **Signals** | `stats_changed`, `shield_broken`, `died` |
| **Writes** | `shield`, `health`, `last_*` hit fields |
| **Reads** | `PushHitResolver`, UI, `CombatFeedback` |
| **Risks** | No `is_fighting` guard inside `apply_damage`; prints every change |

### Player / movement

#### `scripts/player.gd`

| | |
|--|--|
| **Purpose** | Input, locomotion step, camera hierarchy, knockback, void fall, death handoff |
| **Public API** | `get_aim_global_transform`, `arena_respawn`, `take_damage`, `notify_shield_broken`, void/damage hooks |
| **Signals** | `movement_*` (dodged, landed, high_speed, …) |
| **Writes** | `velocity`, `transform`, aim pivot rotation, collision layers when dead |
| **Reads** | `GameManager`, `CombatStats`, `GladiatorFov`, `GladiatorCameraFeel` |
| **Risks** | Runtime camera reparent; monolithic file |

#### `scripts/movement/gladiator_locomotion.gd`

| | |
|--|--|
| **Purpose** | Quake-style accel/friction step |
| **Public API** | `static step(body, delta, input, basis, gravity, config, dodge_boost) → StepResult` |
| **Signals** | None |
| **Writes** | `CharacterBody3D.velocity` (via caller) |
| **Reads** | Player export dictionary |
| **Risks** | Enemy does not use |

#### `scripts/movement/combat_dodge.gd`

| | |
|--|--|
| **Purpose** | Dodge burst + double-tap detection |
| **Public API** | `try_player_dodge`, `tick`, `get_active_velocity_boost`, `register_move_input` |
| **Signals** | None |
| **Writes** | Internal timers |
| **Reads** | Player input (`sprint` action = dodge) |
| **Risks** | Input named `sprint` but not sprint speed |

#### `scripts/movement/gladiator_camera_feel.gd`

| | |
|--|--|
| **Purpose** | Roll and positional kick on feel pivot |
| **Public API** | `update`, `apply_impulse_shake`, `reset` |
| **Signals** | None |
| **Writes** | `CameraFeelPivot` rotation/position |
| **Reads** | Locomotion step, dodge state |
| **Risks** | Must not write pitch |

#### `scripts/movement/gladiator_fov.gd`

| | |
|--|--|
| **Purpose** | Combined FOV offsets with smooth apply |
| **Public API** | `configure_base`, `set_movement_from_speed`, `add_impact`, `set_void_offset`, `trigger_weapon_pulse`, `apply` |
| **Signals** | None |
| **Writes** | `camera.fov` (through `apply`) |
| **Reads** | Player `_process`, void fall state |
| **Risks** | Multiple offset sources; must clear on countdown |

### Weapons

#### `scripts/weapons/weapon_defs.gd`

| | |
|--|--|
| **Purpose** | Weapon enum, stat dictionaries, knockback helpers |
| **Public API** | `class_name WeaponDefs` — `get_data`, damage helpers, wall damage constants |
| **Signals** | None |
| **Writes** | None |
| **Reads** | `WeaponFiring`, UI, audio factory |
| **Risks** | Balance scattered vs `GameBalance` |

#### `scripts/weapons/weapon_firing.gd`

| | |
|--|--|
| **Purpose** | Spawn projectiles / railgun ray pierce loop |
| **Public API** | `static fire(...) → cooldown` |
| **Signals** | None |
| **Writes** | Scene tree (projectiles, beam tracers) |
| **Reads** | `WeaponDefs`, `PushHitResolver`, physics space |
| **Risks** | Complex rail loop; pierce vs wall rules |

#### `scripts/weapons/weapon_manager.gd`

| | |
|--|--|
| **Purpose** | Player weapon switch + fire input |
| **Public API** | `try_fire`, `switch_weapon`, `get_weapon_name`, `can_fire` |
| **Signals** | `weapon_changed`, `weapon_switched`, `shot_fired` |
| **Writes** | `_cooldown_remaining`, view visibility |
| **Reads** | `get_aim_global_transform`, `GameManager`, autoloads |
| **Risks** | Fire origin = camera position, not muzzle |

#### `scripts/weapons/push_hit_resolver.gd`

| | |
|--|--|
| **Purpose** | All combat hits: damage, knockback, walls, explosions |
| **Public API** | `apply_damage_to_target`, `apply_projectile_hit`, `apply_railgun_hit`, `apply_explosion_hit`, `resolve_hit_body`, static helpers |
| **Signals** | None |
| **Writes** | `CombatStats` shield/health; rigidbody velocity; wall HP via `damage_cover` |
| **Reads** | `WeaponDefs`, `GameManager` (indirect), groups |
| **Risks** | God file; **P0** no fight-phase guard; triggers audio/VFX |

#### `scripts/weapons/push_projectile.gd` / `bazooka_projectile.gd`

| | |
|--|--|
| **Purpose** | Moving hitboxes; bazooka explodes via `PushExplosion` |
| **Public API** | `launch`, `configure` |
| **Signals** | None (group `projectile`) |
| **Writes** | Self position; despawn |
| **Reads** | `PushHitResolver` |
| **Risks** | Cleared each countdown |

### Enemy

#### `scripts/enemies/arena_opponent.gd`

| | |
|--|--|
| **Purpose** | Full AI + physics + combat + void + death |
| **Public API** | `take_damage`, `arena_respawn`, `apply_arena_bounds_from_dict`, aim helpers, void hooks |
| **Signals** | None (uses `CombatStats` signals) |
| **Writes** | `linear_velocity`, AI state, weapon choice timers |
| **Reads** | Player, `ArenaGenerator`, `arena_wall` group, `CombatStats` |
| **Risks** | Size; debug flags; LOS mask = layer 1 |

#### `scripts/enemies/enemy_weapon_manager.gd`

| | |
|--|--|
| **Purpose** | Enemy weapon visuals + fire from muzzle |
| **Public API** | `try_fire`, `get_muzzle_global_position`, `get_weapon_forward`, `switch_weapon` |
| **Signals** | `shot_fired` |
| **Writes** | Cooldown, view visibility |
| **Reads** | `WeaponFiring`, mount forward |
| **Risks** | Duplicates post-fire audio/VFX pattern with player |

#### `scripts/enemies/enemy_weapon_mount.gd`

| | |
|--|--|
| **Purpose** | Weapon mount aim alignment |
| **Public API** | `align_to_target`, `get_weapon_forward`, `notify_weapon_synced` |
| **Signals** | None |
| **Writes** | Mount transform |
| **Reads** | Arena opponent aim cache |
| **Risks** | `-basis.z` = forward convention |

#### `scripts/animation/enemy_look_at_controller.gd`

| | |
|--|--|
| **Purpose** | Head/torso/arms look-at; muzzle aim |
| **Signals** | None |
| **Writes** | Bone/mount rotations |
| **Reads** | Aim world positions from opponent |
| **Risks** | Must stay synced with fire direction |

### Arena

#### `scripts/arena/arena_generator.gd`

| | |
|--|--|
| **Purpose** | Round arena build + spawn validation + debug viz |
| **Public API** | `generate_round_arena_async`, spawn transforms, `raycast_floor_at`, `get_current_arena_bounds`, `is_near_main_route` |
| **Signals** | None |
| **Writes** | `ActiveArena` children, spawn positions, `_route_path_world` |
| **Reads** | Template + maze + wall generators |
| **Risks** | 6-attempt loop; console prints |

#### `scripts/arena/arena_templates.gd`

| | |
|--|--|
| **Purpose** | Five deck templates + signature cover pieces |
| **Public API** | `get_template(id)`, `get_playable_ids()` |
| **Writes** | New `ArenaTemplate` instances (data only) |
| **Reads** | `ArenaGenerator` |
| **Risks** | Template `wall_pieces` partially kept by wall gen |

#### `scripts/arena/arena_maze_generator.gd`

| | |
|--|--|
| **Purpose** | Indestructible structural maze layouts |
| **Public API** | `static apply(template, template_id) → Dictionary` |
| **Writes** | `template.structural_wall_pieces` |
| **Reads** | `ArenaRouteValidator._*` (private API) |
| **Risks** | Coupling to validator internals |

#### `scripts/arena/arena_wall_set_generator.gd`

| | |
|--|--|
| **Purpose** | Procedural destructible cover |
| **Public API** | `static apply(template, template_id) → Dictionary` |
| **Writes** | `template.wall_pieces` |
| **Reads** | `ArenaRouteValidator` |
| **Risks** | Rollback placement on route fail |

#### `scripts/arena/arena_route_validator.gd`

| | |
|--|--|
| **Purpose** | Grid BFS routes spawn-to-spawn, detour count |
| **Public API** | `validate_template`, `path_to_world_points`, `GridData` |
| **Writes** | None (pure) |
| **Reads** | `ArenaTemplate` floor + walls |
| **Risks** | Not NavMesh; used externally via `_` methods |

#### `scripts/arena/arena_structure_builder.gd`

| | |
|--|--|
| **Purpose** | Instantiate floors, structural walls, destructible walls |
| **Public API** | `static build(parent, template)` |
| **Writes** | Scene tree under `ActiveArena` |
| **Reads** | `ArenaTemplate`, materials |
| **Risks** | Order: floor → structural → destructible → modules → perimeter → fall zones → **chamber pass** |

#### `scripts/arena/arena_chamber_pass.gd`

| | |
|--|--|
| **Purpose** | Suspended gladiator chamber read: void abyss, deck zones, landmark, megastructures, particles, lights |
| **Public API** | `static build(parent, template)` |
| **Writes** | `ArenaChamberPass` subtree (groups `arena_chamber_decor`, `arena_chamber_light`) |
| **Reads** | `ArenaTemplate` bounds / perimeter config |
| **Calls** | `ArenaMegastructurePass.build` |
| **Risks** | Visual-only — must not add collision that blocks routes or spawns |

#### `scripts/arena/arena_megastructure_pass.gd`

| | |
|--|--|
| **Purpose** | Layered distant megastructures, sparse beacons, void ambient events |
| **Public API** | `static build(parent, template, rng)` |
| **Writes** | `ArenaMegastructurePass` subtree; `ArenaMegastructureVoidEvents` controller |
| **Helpers** | `arena_megastructure_beacon.gd`, `arena_megastructure_void_events.gd` |
| **Risks** | Keep outside play radius; rare lights/events only — no gameplay hooks |

#### `scripts/arena/destructible_wall.gd`

| | |
|--|--|
| **Purpose** | HP walls + fracture pipeline |
| **Public API** | `damage_cover`, `setup_wall`, `infer_kind_from_size` |
| **Signals** | None |
| **Writes** | HP, collision layers when broken |
| **Reads** | `WeaponDefs` via resolver |
| **Risks** | Group `destructible_wall` required for AI LOS |

#### `scripts/arena/structural_wall.gd`

| | |
|--|--|
| **Purpose** | Permanent maze collision |
| **Public API** | `setup_structural_wall` |
| **Writes** | None after build |
| **Reads** | `PushHitResolver.is_structural_geometry` path |
| **Risks** | Same layer 1 as destructible |

### Audio / VFX

#### `scripts/environment/void_audio.gd`

| | |
|--|--|
| **Purpose** | Autoload audio director |
| **Public API** | Static: `play_weapon_fire`, `play_hit_confirm`, `play_shield_break`, `play_wall_hit`, void gore API, `update_void_proximity`, `compute_edge_proximity` |
| **Signals** | None |
| **Writes** | Player volumes, pool index |
| **Reads** | `AudioStreamFactory` |
| **Risks** | 45ms hit cooldown; no buses |

#### `scripts/audio/combat_feedback.gd`

| | |
|--|--|
| **Purpose** | Single entry for shield-break A/V |
| **Public API** | `static on_shield_broken(stats)` |
| **Writes** | None (delegates) |
| **Reads** | `CombatStats`, autoloads, crosshair |
| **Risks** | Must remain only break entry point |

#### `scripts/effects/combat_vfx_director.gd`

| | |
|--|--|
| **Purpose** | Autoload combat particles/lights/screen hooks |
| **Public API** | `spawn_muzzle_fire`, `spawn_fighter_hit`, `play_shield_break_event`, `spawn_wall_hit`, `apply_edge_tension` |
| **Writes** | Temporary nodes in scene |
| **Reads** | `arena_ui` group for overlays |
| **Risks** | Not cleared on round start; null if autoload disabled |

#### `scripts/environment/void_gas_controller.gd`

| | |
|--|--|
| **Purpose** | Fog, screen tint, fall DOF, edge pulse |
| **Public API** | `set_fall_tracking`, static `notify_fall_started/ended` |
| **Writes** | `WorldEnvironment` fog/adjustment (when active) |
| **Reads** | `GameBalance`, player Y, `VoidAudio` |
| **Risks** | Mutates environment resource at runtime |

### UI

#### `scripts/arena_ui.gd`

| | |
|--|--|
| **Purpose** | HUD labels, void overlays, edge tension rects |
| **Public API** | `apply_void_gas_screen`, `apply_edge_tension`, `trigger_combat_view_flash` |
| **Signals** | Listens to `GameManager`, `CombatStats` |
| **Writes** | Label text, ColorRect visibility/colors |
| **Reads** | `GameManager`, weapon manager group |
| **Risks** | `shield_broken` connects without disconnect guard |

#### `scripts/ui/crosshair.gd`

| | |
|--|--|
| **Purpose** | Crosshair draw + hit feedback |
| **Public API** | `notify_hit_on_target`, `notify_enemy_shield_broken`, static `get_instance` |
| **Signals** | `shot_fired` |
| **Writes** | Internal flash state → `_draw` |
| **Reads** | `WeaponManager` signals |
| **Risks** | Static group lookup |

### Secondary / legacy (know but avoid)

| File | Note |
|------|------|
| `scripts/push_enemy.gd` | Legacy prototype; not in `main.tscn` |
| `scripts/environment/arena_zone.gd`, `scenes/arenas/*` | Hand-authored arenas; not round flow |
| `scripts/arena/perforable_wall_grid.gd` | Not wired in builder |
| `scripts/arena/arena_floor_builder.gd` | Superseded by `arena_structure_builder` |

---

## 4. State ownership

### Single-writer rules

| State | Sole writer | Readers |
|-------|-------------|---------|
| `player_score` / `enemy_score` | `GameManager` | `ArenaUI` via signal |
| `GameManager.state` | `GameManager` | Weapons (query), AI (query) |
| `CombatStats.shield` / `health` | `CombatStats.apply_damage`, `reset_combat_stats` | UI, AI (`_is_low_combat`) |
| `Camera3D.fov` | `GladiatorFov.apply` (from `player`) | None else |
| `AimPivot.rotation.x` (pitch) | `player` input handler | `get_aim_global_transform` |
| `CameraFeelPivot` transform | `GladiatorCameraFeel` | None |
| Arena geometry | `ArenaStructureBuilder` / generators | Physics, AI, raycasts |
| Active arena template data | Generators write `ArenaTemplate` fields once per attempt | `ArenaStructureBuilder` |

### Forbidden duplicate ownership (do not add second writers)

- Shield break feedback: **only** `CombatFeedback.on_shield_broken` (not also in resolver hit VFX on break frame).
- Round score: **only** `GameManager` finish paths.
- Final FOV: **only** `GladiatorFov` — do not set `camera.fov` elsewhere.
- Structural vs destructible: **never** call `damage_cover` on `StructuralWall`.

### Coordinated systems (multiple readers, one orchestrator)

| Orchestrator | Coordinators |
|--------------|--------------|
| `PushHitResolver.apply_damage_to_target` | `CombatStats`, `CombatAudio`, `CombatVfxDirector`, `Crosshair` |
| `CombatFeedback.on_shield_broken` | `CombatVfxDirector`, `VoidAudio`, `player`, `Crosshair`, `ArenaUI` (label only) |
| `GameManager._run_countdown` | `ArenaGenerator`, cleanup groups, `DebrisSpawner`, fighters |
| `VoidGasController._process` | `VoidAudio`, `ArenaUI`, `CombatVfxDirector`, environment |

---

## 5. Technical risks

Consolidated from [TECHNICAL_AUDIT.md](TECHNICAL_AUDIT.md). IDs reference audit entries.

### P0

| ID | Problem | Files |
|----|---------|-------|
| **T-001** | `PushHitResolver` applies damage without `GameManager.is_fighting()` guard | `push_hit_resolver.gd`, `combat_stats.gd` |

### P1

| ID | Problem | Files |
|----|---------|-------|
| T-002 | `arena_opponent.gd` god object | `arena_opponent.gd` |
| T-003 | `push_hit_resolver.gd` god module | `push_hit_resolver.gd` |
| T-004 | `player.gd` monolith | `player.gd` |
| T-005 | Group / `has_method` coupling | Many |
| T-006 | Validator private API used externally | `arena_route_validator.gd`, maze/wall gen |
| T-007 | Arena gen failure only logged | `arena_generator.gd` |
| T-008 | `CombatStats` no round-state gate | `combat_stats.gd` |
| T-009 | Dual damage paths (`take_damage` vs resolver) | `combat_stats.gd`, `push_hit_resolver.gd` |
| T-010 | Runtime camera hierarchy mutation | `player.gd`, `main.tscn` |
| T-011 | Unused perforable wall grid | `perforable_wall_grid.gd` |
| T-012 | Legacy arena scenes | `scenes/arenas/*` |
| T-013 | Orphan `push_enemy.gd` | `push_enemy.gd` |

### P2

| ID | Problem | Files |
|----|---------|-------|
| T-014 | Input `sprint` = dodge only | `project.godot`, `player.gd` |
| T-015 | No audio buses | `project.godot`, `void_audio.gd` |
| T-016 | Global 45ms hit sound cooldown | `void_audio.gd` |
| T-017 | Combat VFX not cleared on round | `combat_vfx_director.gd`, `game_manager.gd` |
| T-018 | VFX/audio perf not profiled | autoloads |
| T-019 | Verbose `print()` in hot paths | multiple |
| T-020 | UI signal double-connect on reload | `arena_ui.gd` |
| T-021 | Player fire from camera not muzzle | `weapon_manager.gd` |
| T-022 | Collision layers undocumented in project | `project.godot` |
| T-023 | Autoload without `class_name` | `void_audio.gd` |
| T-024 | Async countdown from `_ready` | `game_manager.gd` |
| T-025 | Tuning split across files | many |
| T-026 | `ARCHITECTURE.md` drift | docs |
| T-027 | AI LOS uses blanket layer 1 | `arena_opponent.gd` |

---

## 6. Debug commands / tools

All toggles are **editor exports** on nodes in `main.tscn` unless noted. Run game (F5), enable flag, observe scene.

### Arena

| Goal | How |
|------|-----|
| **Route grid** | Select `ArenaGenerator` → `debug_show_route = true` → green = primary path, blue = walkable, red = blocked |
| **Spawn points** | `debug_show_spawn_markers = true` → green sphere = player, red = enemy |
| **Danger bounds** | `debug_show_markers = true` → blue corner spheres |
| **Console** | Watch generation logs: maze name, route count, wall set, attempt failures |
| **Regen stress** | Play multiple rounds; confirm no `push_error` on arena fail |

### Routes / navigation data

| Goal | How |
|------|-----|
| **Stored path** | `ArenaGenerator.get_route_path_points()` after gen (script debugger or temporary print) |
| **Near route** | `is_near_main_route(world_pos)` used by debris spawner — enable debris debug via placement failures in log |

### Audio

| Goal | How |
|------|-----|
| **Mix levels** | Inspector → autoload `VoidAudio` root: `master_volume_db`, `combat_volume_db`, `enemy_combat_volume_db`, `void_ambience_volume_db` |
| **Missing assets** | Drop OGG in `res://audio/combat/` / `res://audio/void/` — factory auto-loads (see `audio/README_REPLACE_ASSETS.md`) |
| **Shield break** | Break enemy shield — distinct rupture vs shield tick |
| **Hit throttle** | Rapid shotgun/rail pierce — listen for dropped ticks (`HIT_SOUND_COOLDOWN_SEC`) |

### AI

| Goal | How |
|------|-----|
| **Movement** | `ArenaOpponent` → `debug_ai_movement = true` → console state/force logs |
| **Fire blocks** | `debug_ai_fire = true` → prints `_fire_block_reason` when shot denied |
| **Aim rays** | `EnemyLookAtController` → `debug_show_aim_ray`, `debug_show_enemy_forward` |
| **Weapon forward** | `EnemyWeaponMount` → `debug_show_weapon_forward`, `debug_show_muzzle` |
| **Anim state** | `ProceduralEnemyAnimator` → `debug_show_anim_state` → Label3D over enemy |

### FOV

| Goal | How |
|------|-----|
| **Live tuning** | Select `Player` → `base_fov`, `speed_fov_boost`, `weapon_fov_pulse`, `shield_break_fov_pulse` |
| **Void widen** | Fall off arena edge — FOV should rise via `GladiatorFov.set_void_offset` |
| **Reset check** | After countdown, FOV should return to base (listen `countdown_hidden` → `_on_round_countdown_hidden`) |

### Combat / stats

| Goal | How |
|------|-----|
| **Shield/health** | `CombatStats.debug_name` — prints on each `apply_damage` |
| **Resolver** | `PushHitResolver` prints impulse lines (noisy) — filter console |
| **Shield break once** | Break shield — one burst + `shield_broken` (watch duplicate VFX/audio) |
| **Fight gate** | Try firing during countdown (should not); note P0 if damage applies |

### Spawns

| Goal | How |
|------|-----|
| **Markers** | `ArenaGenerator.debug_show_spawn_markers` |
| **Floor snap** | `SpawnPads` visible after countdown; console `Spawn validation passed` |
| **Ray failure** | If spawn invalid, generator retries — read `Spawn or route invalid, regenerating` |

### VFX

| Goal | How |
|------|-----|
| **Autoload tuning** | `CombatVfxDirector`: `vfx_intensity`, `shield_break_scale`, `void_edge_strength`, flash alphas |
| **Edge tension** | Walk to arena perimeter — vignette via `ArenaUI.apply_edge_tension` |
| **Muzzle/hit** | Fire weapons / take hits — watch `combat_vfx` group in remote scene tree |
| **Round carryover** | Start new round — check for leftover VFX nodes (known P2) |

### Godot editor / project

| Goal | How |
|------|-----|
| **Groups** | Remote tree: filter `player`, `game_manager`, `arena_generator`, `projectile` |
| **Physics layers** | Project → Layer names (currently unnamed); code uses layer **1** gameplay, **8** corpses/gibs |
| **Headless** | `godot --headless --path . --quit-after 3` (CI smoke; Godot on PATH) |

---

## Quick reference

### Autoloads

| Name | Script |
|------|--------|
| `VoidAudio` | `scripts/environment/void_audio.gd` |
| `CombatVfxDirector` | `scripts/effects/combat_vfx_director.gd` |
| `GladiatorLoadout` | `scripts/chamber/gladiator_loadout.gd` — `user://gladiator_loadout.cfg` |
| `GameFlow` | `scripts/chamber/game_flow.gd` — chamber ↔ `arena_match` |

### Gladiator Chamber (MVP hub)

| | |
|--|--|
| **Scene** | `scenes/chamber/gladiator_chamber.tscn` |
| **Builder** | `scripts/chamber/gladiator_chamber.gd` — ~32×26 m brutalist shell + interactables |
| **Player** | `scripts/chamber/chamber_player.gd` — walk + E interact |
| **Arena handoff** | `scripts/chamber/arena_match_bridge.gd` on `arena_match.tscn` |
| **Return mood** | Victory/defeat fog + lights in `gladiator_chamber.gd` |


### Groups (round cleanup)

`projectile`, `corpse`, `void_effect`, `void_fragment`, `gore_chunk`, `gib_chunk`, `dismembered_body_part`, `combat_vfx` (timer free only)

### Related docs

- [TECHNICAL_AUDIT.md](TECHNICAL_AUDIT.md) — issue register + fix guidance  
- [VOID_PROTOTYPE_AUDIT.md](VOID_PROTOTYPE_AUDIT.md) — design gaps  
- `.cursor/rules/void-code-safety.mdc` — AI change discipline  

---

*Documentation only — no gameplay code changed. Regenerate this map when adding autoloads, arena pipeline stages, or combat entry points.*
