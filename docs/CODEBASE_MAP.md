# VOID — Codebase Map

Navigation guide for the **Neon Catacombs / VOID** Godot 4.6 prototype. Use this with [PROTOTYPE.md](PROTOTYPE.md) (implementation detail) and [VOID_PROTOTYPE_AUDIT.md](VOID_PROTOTYPE_AUDIT.md) (gaps and priorities).

---

## 1. Project overview

### Identity

- **Engine:** Godot 4.6, Forward+, **Jolt Physics**
- **Mode:** 1v1 arena FPS — ring-out or shield-break + kill
- **Win condition:** First to **5** round wins (`GameManager.WIN_SCORE`)
- **Design gate:** [VOID_DESIGN_PHILOSOPHY.md](VOID_DESIGN_PHILOSOPHY.md), enforced in editor via `.cursor/rules/void-design.mdc`

### Main scene

| Item | Path |
|------|------|
| Entry | `res://scenes/main.tscn` (`project.godot` → `run/main_scene`) |
| Root | `Main` (`Node3D`) |

**Main scene hierarchy (runtime):**

```
Main
├── WorldEnvironment, SunLight, RimLightCold, EdgeLightNorth/South
├── VoidAtmosphere (instance)
├── VoidGasController
├── VoidDistantArchitecture (instance)
├── ArenaGenerator (instance) → ActiveArena, SpawnPads, DebugMarkers, DebrisSpawner
├── PitVoid (visual)
├── GameManager
├── ArenaOpponent (instance)
├── Player (CharacterBody3D) → [AimPivot → CameraFeelPivot → Camera3D + WeaponManager]
└── UI (CanvasLayer) → Crosshair, labels, void overlays
```

Player camera hierarchy is **built at runtime** in `player._setup_aim_camera_hierarchy()` if `AimPivot` is not already in the scene.

### Autoloads

| Name | Script | Role |
|------|--------|------|
| `VoidAudio` | `scripts/environment/void_audio.gd` | Void ambience, proximity, combat 3D SFX pool (no `class_name` — avoids name clash) |
| `CombatVfxDirector` | `scripts/effects/combat_vfx_director.gd` | Procedural combat VFX one-shots, edge screen tension hooks |

### Core gameplay loop

1. **Match start** → `GameManager._begin_match()` → countdown round 1  
2. **Countdown** → generate arena → clear round entities → spawn debris → respawn fighters → `3, 2, 1, FIGHT!`  
3. **Fighting** → player input + enemy AI + weapons → damage / knockback / void fall  
4. **Round end** → score + death/void presentation → countdown next round  
5. **Match over** at 5 points → `match_over` signal → UI win/lose

### Round lifecycle (`GameManager.RoundState`)

| State | Meaning |
|-------|---------|
| `COUNTDOWN` | Arena gen, cleanup, respawn, numeric countdown |
| `FIGHTING` | Weapons, AI, void checks active |
| `ROUND_OVER` | Brief window during death/void sequences |
| `MATCH_OVER` | Match ended |

**Guards:** `_handling_round_end` blocks double scoring; `is_fighting()` gates weapons and damage.

---

## 2. System map

### 2.1 Player

| | |
|---|---|
| **Purpose** | First-person fighter: Quake-style locomotion, stable aim, knockback, void fall reporting, death presentation |
| **Main files** | `scripts/player.gd`, `scenes/main.tscn` (Player node) |
| **Key types** | `CharacterBody3D` + child `CombatStats` |
| **Group** | `player`, `player_aim` (on AimPivot) |

**Public API (selected):**

| Function | Role |
|----------|------|
| `take_damage(...)` | Records hit → `CombatStats.apply_damage` |
| `get_aim_global_transform()` / `get_aim_forward()` | Stable fire/aim basis |
| `apply_knockback` / `apply_explosion_knockback` / `apply_rocket_jump_knockback` | Weapon impulse |
| `arena_respawn(pos)` | Round reset position, void flags |
| `notify_weapon_fov_pulse()` / `notify_shield_broken()` | Feel hooks |
| `begin_void_dying()` / `end_void_dying()` | Void sequence cooperation |
| `begin_void_instability()` | Gore timeline hook |

**Signals:** `movement_dodged`, `movement_landed`, `movement_high_speed`, `movement_heavy_impact`, `movement_air_accel`

**Dependencies:** `GladiatorLocomotion`, `CombatDodge`, `GladiatorCameraFeel`, `GladiatorFov`, `GameManager`, `CombatStats`, `Crosshair`

**Risks / fragile areas:**

- Runtime camera reparenting must stay in sync with `WeaponManager` parent path  
- `_death_handled` / `_void_reported` must reset on `arena_respawn`  
- Large monolithic script (~630 lines) mixing locomotion, death, void, camera setup

---

### 2.2 Movement

| | |
|---|---|
| **Purpose** | Ground/air accel, friction, strafe boost, dodge burst — no animation root motion |
| **Main files** | `scripts/movement/gladiator_locomotion.gd`, `scripts/movement/combat_dodge.gd` |
| **Key types** | `GladiatorLocomotion` (`RefCounted`), `CombatDodge` (`RefCounted`) |

**Public API:**

| Class | Functions |
|-------|-----------|
| `GladiatorLocomotion` | `step(body, delta, input_dir, config)` → `StepResult` (speed, landed, airborne, …) |
| `CombatDodge` | `try_dodge(...)`, `is_active()`, `get_velocity_contribution()` |

**Dependencies:** `player.gd` exports (`ground_acceleration`, `friction`, `max_ground_speed`, dodge exports)

**Risks:** Tuning split between `player.gd` exports and `GameBalance`; enemy does **not** use this module (separate RigidBody forces).

---

### 2.3 Camera / FOV

| | |
|---|---|
| **Purpose** | Mouse yaw on body, pitch on `AimPivot`; roll/offset on `CameraFeelPivot`; combined FOV offsets |
| **Main files** | `scripts/movement/gladiator_camera_feel.gd`, `scripts/movement/gladiator_fov.gd`, `player.gd` input + `_process` |
| **Key types** | `GladiatorCameraFeel`, `GladiatorFov` |

**Public API:**

| Class | Functions |
|-------|-----------|
| `GladiatorCameraFeel` | `update(...)`, `apply_impulse_shake(feel_pivot, intensity)`, `reset(...)` |
| `GladiatorFov` | `configure_base`, `set_movement_from_speed`, `add_impact`, `set_void_offset`, `trigger_weapon_pulse`, `apply(camera, delta, void_fall)` |

**Dependencies:** `GameBalance.VOID_FALL_FOV_MAX_ADD`, `VoidGasController` (void fall widens FOV via player void state)

**Risks:** FOV sources stack (`movement`, `impact`, `void`, `weapon`); must clear on `countdown_hidden` to avoid carryover.

---

### 2.4 Weapons

| | |
|---|---|
| **Purpose** | Shared weapon stats, firing, projectiles, beam, explosions, hit resolution |
| **Main files** | `scripts/weapons/weapon_defs.gd`, `weapon_firing.gd`, `weapon_manager.gd`, `push_hit_resolver.gd`, `push_projectile.gd`, `bazooka_projectile.gd`, `push_explosion.gd`, `beam_tracer.gd` |
| **Scenes** | `scenes/weapons/push_projectile.tscn`, `bazooka_projectile.tscn`, `weapon_manager.tscn`, `enemy_weapon_manager.tscn` |

**Key classes:**

| Class | Role |
|-------|------|
| `WeaponDefs` | Enum `Id`, stat dictionaries, knockback/ explosion helpers |
| `WeaponFiring` | `fire(weapon, origin, dir, basis, scene, offset, shooter)` |
| `WeaponManager` | Player input, cooldown, aim transform |
| `EnemyWeaponManager` | Enemy fire from muzzle, `get_weapon_forward()` |
| `PushHitResolver` | All damage/knockback routing (static) |

**Signals:** `WeaponManager.weapon_changed`, `weapon_switched`, `shot_fired`; `EnemyWeaponManager.shot_fired`

**Groups:** `weapon_manager`, `projectile`

**Dependencies:** `CombatAudio`, `CombatVfxDirector`, `PushHitResolver`, `CombatStats`, `GameManager.is_fighting()`

**Risks:**

- `push_hit_resolver.gd` is large (~625 lines) — central choke point for any combat change  
- Railgun pierce + wall rules spread across `weapon_firing`, `railgun_pierce_mark`, `destructible_wall`  
- Hit sound cooldown in `VoidAudio` can mask rapid hits

---

### 2.5 Enemy AI

| | |
|---|---|
| **Purpose** | RigidBody gladiator: hunt, pressure, evade, cover, edge safety, weapon choice, LOS fire |
| **Main files** | `scripts/enemies/arena_opponent.gd` (~1090 lines), `enemy_weapon_mount.gd`, `enemy_weapon_manager.gd`, `enemy_look_at_controller.gd`, `procedural_enemy_animator.gd` |
| **Scene** | `scenes/enemies/arena_opponent.tscn` |

**State machine:** `AiState` — `HUNTING`, `PRESSURING`, `EVADING`, `RECOVERING`, `EXECUTING`, `IN_COVER`

**Public API (selected):**

| Function | Role |
|----------|------|
| `arena_respawn`, `apply_arena_bounds_from_dict` | Per-round setup |
| `align_weapon_to_target`, `get_muzzle_global_position`, `get_weapon_forward` | Combat aim |
| `force_visual_aim_refresh`, `refresh_target_references` | Post-gen sync |
| `take_damage` | Same pattern as player |

**Dependencies:** `ArenaGenerator` bounds, `arena_wall` group for LOS, `WeaponFiring`, `CombatStats`, `GameManager`

**Risks:**

- **Largest gameplay script** — hard to test in isolation  
- Aim cache updated every physics frame; early returns in AI can desync aim if not careful  
- Physics AI ≠ player locomotion feel (intentional but easy to forget when tuning)

---

### 2.6 Shield / health / damage

| | |
|---|---|
| **Purpose** | Shield-first damage pool, death classification, shield-break event |
| **Main files** | `scripts/combat_stats.gd`, `scripts/weapons/push_hit_resolver.gd`, `scripts/audio/combat_feedback.gd` |
| **Key class** | `CombatStats` on each fighter |

**Signals:**

| Signal | When |
|--------|------|
| `stats_changed(shield, health)` | After damage or reset |
| `shield_broken(source)` | Shield transitions **>0 → ≤0** (once per `apply_damage`) |
| `died(attacker)` | Health reaches 0 |

**Public API (`CombatStats`):**

| Function | Role |
|----------|------|
| `apply_damage(amount, attacker)` | Shield then health; triggers break feedback |
| `record_hit(...)` | Last hit dir, source, world pos for VFX/audio |
| `reset_combat_stats()` | Round reset |
| `is_heavy_death()`, `is_dismemberment_death()`, `get_player_death_message()` | Death presentation |

**Shield break pipeline:** `apply_damage` → `shield_broken` + `CombatFeedback.on_shield_broken` → VFX + audio + player/crosshair local feedback.

**Dependencies:** `PushHitResolver.apply_damage_to_target`, `CombatAudio`, `CombatVfxDirector`, `ArenaUI` (label flash on `shield_broken`)

**Risks:** Any damage path bypassing `PushHitResolver`/`take_damage` skips audio/VFX; `died` connected in fighter `_ready` — order matters.

---

### 2.7 Arena generation

| | |
|---|---|
| **Purpose** | Procedural round arena: continuous deck, indestructible maze, destructible cover, perimeter, spawns |
| **Main files** | `scripts/arena/arena_generator.gd`, `arena_templates.gd`, `arena_maze_generator.gd`, `arena_wall_set_generator.gd`, `arena_structure_builder.gd`, `arena_route_validator.gd`, `arena_perimeter_builder.gd`, `arena_brutalist_modules.gd`, `arena_fall_zone_builder.gd`, `arena_connector_builder.gd` |
| **Scene** | `scenes/arena/arena_generator.tscn` |

**Generation order (each attempt):**

1. `ArenaTemplates.get_template(id)`  
2. `ArenaMazeGenerator.apply` → structural walls + route validation  
3. `ArenaWallSetGenerator.apply` → destructible cover  
4. `ArenaRouteValidator` + optional `ArenaConnectorBuilder`  
5. `ArenaStructureBuilder.build`  
6. Physics frame → spawn raycasts + route store  

**Public API (`ArenaGenerator`):**

| Function | Role |
|----------|------|
| `generate_round_arena_async()` | Main entry (awaitable) |
| `get_player_spawn_transform` / `get_enemy_spawn_transform` | Round spawns |
| `get_current_arena_bounds()` | AI danger/safe half extents |
| `raycast_floor_at`, `has_floor_at`, `is_floor_ahead` | Floor probes (mask bit 1) |
| `pick_valid_debris_position` | Round debris placement |
| `is_near_main_route` | Optional debris bias |

**Group:** `arena_generator`

**Dependencies:** `GameManager._generate_round_arena`, `ArenaOpponent.apply_arena_bounds_from_dict`

**Risks:**

- Up to **6** generation attempts; silent fallback to Toxic Bridge  
- Grid validator ≠ NavMesh (AI uses physics/raycasts separately)  
- `structural_wall` vs `destructible_wall` must stay in sync in route grid + `PushHitResolver`

---

### 2.8 Destructible walls

| | |
|---|---|
| **Purpose** | Breakable cover and perimeter; staged fracture; railgun pierce marks (no wall HP from rail) |
| **Main files** | `scripts/arena/destructible_wall.gd`, `wall_destruction.gd`, `scripts/effects/railgun_pierce_mark.gd`, `scripts/props/debris_chunk.gd` |
| **Structural (non-destructible)** | `structural_floor.gd`, `structural_wall.gd` |

**Groups:** `destructible_wall`, `arena_wall`, `arena_perimeter`, `structural_geometry`, `structural_wall`

**Public API (`DestructibleWall`):**

| Function | Role |
|----------|------|
| `setup_wall(kind, mesh, size, ...)` | HP from `WallKind` |
| `damage_cover(...)` | Shotgun/bazooka damage entry |
| `is_destructible_wall()` | Static check |

**Dependencies:** `PushHitResolver`, `WeaponDefs` wall damage constants, `ArenaStructureBuilder`

**Risks:** `PerforableWallGrid` exists but is not wired in builder; anonymous `@StaticBody3D` warnings if generator misnames nodes.

---

### 2.9 Void / falling

| | |
|---|---|
| **Purpose** | Exterior ring-out only; toxic gas fall; cinematic death; atmosphere |
| **Main files** | `scripts/environment/void_gas_controller.gd`, `void_atmosphere.gd`, `void_distant_architecture.gd`, `void_gore_sequence.gd`, `void_death_effect.gd`, `scripts/game_balance.gd` |
| **Player/enemy** | `_report_void_fall()` → `GameManager.report_*_void_fall` |

**Key constants (`GameBalance`):** `VOID_DEATH_Y` (-32), `VOID_FALL_WARNING_Y` (-18), `VOID_DEATH_STYLE`, fog Y bands

**Public API (`VoidGasController`):**

| Function | Role |
|----------|------|
| `set_fall_tracking(node, active)` | Start/end fall FX sample target |
| `notify_fall_started` / `notify_fall_ended` | Static helpers |

**Groups:** `void_gas_controller`, `void_atmosphere`, `void_distant_architecture`, `void_effect`

**Dependencies:** `VoidAudio.update_void_proximity`, `CombatVfxDirector.apply_edge_tension`, `ArenaUI.apply_void_gas_screen`

**Risks:** Fall detection is Y-threshold + arena bounds on fighters; must stay consistent with `ArenaGenerator.get_void_y()`.

---

### 2.10 Audio

| | |
|---|---|
| **Purpose** | Autoload director: void loops, combat 3D one-shots, procedural fallbacks |
| **Main files** | `scripts/environment/void_audio.gd`, `scripts/audio/audio_stream_factory.gd`, `scripts/audio/combat_audio.gd`, `scripts/audio/combat_feedback.gd` |
| **Assets** | `res://audio/void/*`, `res://audio/combat/*` (see [audio/README_REPLACE_ASSETS.md](../audio/README_REPLACE_ASSETS.md)) |

**Public API (`CombatAudio` — thin wrappers):**

| Function | Delegates to |
|----------|----------------|
| `play_weapon_fire` | `VoidAudio` |
| `play_hit_confirm` | `VoidAudio` (skips shield-hit sound on break frame) |
| `play_wall_hit` | `VoidAudio` |
| `play_shield_break` | `VoidAudio` |

**Public API (`VoidAudio` static):** `play_weapon_fire`, `play_hit_confirm`, `play_shield_break`, `play_wall_hit`, `update_void_proximity`, void gore one-shots, `compute_edge_proximity`

**Risks:** Single `HIT_SOUND_COOLDOWN_SEC` (45 ms); all buses on `Master` (no mix buses yet).

---

### 2.11 VFX

| | |
|---|---|
| **Purpose** | Combat one-shots (autoload), void death/gore, railgun pierce visuals |
| **Main files** | `scripts/effects/combat_vfx_director.gd`, `railgun_impact_flash.gd`, `railgun_pierce_mark.gd`, `beam_tracer.gd`, `void_death_effect.gd`, `void_gore_sequence.gd`, `dismemberment_spawner.gd`, `gib_spawner.gd`, `corpse_spawner.gd` |

**Public API (`CombatVfxDirector` static):**

| Function | Role |
|----------|------|
| `spawn_muzzle_fire` | Per-weapon discharge |
| `spawn_fighter_hit` | Shield/health impacts (not full break) |
| `play_shield_break_event` | Dedicated break burst |
| `spawn_wall_hit` | Dust/sparks |
| `apply_edge_tension` | Arena edge screen (via `ArenaUI`) |

**Dependencies:** `ArenaUI.trigger_combat_view_flash`, `VoidGasController`

**Risks:** Procedural CPUParticles — performance not profiled; `combat_vfx` group cleanup relies on timers not round clear.

---

### 2.12 UI / crosshair

| | |
|---|---|
| **Purpose** | HUD, countdown, death text, void overlays, crosshair feedback |
| **Main files** | `scripts/arena_ui.gd`, `scripts/ui/crosshair.gd` |
| **Scene nodes** | Under `Main/UI` in `main.tscn` |

**GameManager → UI signals:** `score_changed`, `countdown_text_changed`, `countdown_hidden`, `death_message_changed`, `death_message_hidden`, `void_overlay_changed`, `match_over`

**Crosshair API:** `notify_hit_on_target`, `notify_enemy_shield_broken`, `notify_hit_cover`, `configure_aim_stability`

**Group:** `arena_ui`, `crosshair`

**Risks:** `ArenaUI` binds `CombatStats.shield_broken` deferred — duplicate listeners if scene reloaded; edge overlays created in `_ensure_combat_overlays` at runtime.

---

### 2.13 Scoring / rounds

| | |
|---|---|
| **Purpose** | Match flow, round cleanup, fighter respawn, win at 5 |
| **Main file** | `scripts/game_manager.gd` |
| **Group** | `game_manager` |

**Scoring paths:**

| Event | Points |
|-------|--------|
| Player void death / player health death | Enemy +1 |
| Enemy void death / enemy health death | Player +1 |

**Round cleanup:** projectiles, corpses, void effects, gibs, dismember parts, railgun VFX, round debris — then regen arena on next countdown.

**Risks:** Async `generate_round_arena_async` during countdown — timing assumes await completes before `FIGHT!`.

---

### 2.14 Docs / rules

| Resource | Purpose |
|----------|---------|
| [VOID_DESIGN_PHILOSOPHY.md](VOID_DESIGN_PHILOSOPHY.md) | Canonical feel gate |
| [VOID_PROTOTYPE_AUDIT.md](VOID_PROTOTYPE_AUDIT.md) | Gaps, P0–P2 |
| [PROTOTYPE.md](PROTOTYPE.md) | File-level behavior |
| [art/ART_DIRECTION.md](art/ART_DIRECTION.md), [art/VISUAL_RULES.md](art/VISUAL_RULES.md) | Visual targets |
| [gameplay/GAMEPLAY.md](gameplay/GAMEPLAY.md) | Loop summary |
| [tech/ARCHITECTURE.md](tech/ARCHITECTURE.md) | High-level structure |
| [audio/AUDIO.md](audio/AUDIO.md) | Audio design |
| `.cursor/rules/void-design.mdc` | Agent/editor guardrails (always apply) |

---

## 3. Flow diagrams (text)

### 3.1 Round start

```
GameManager._ready
  → _begin_match (scores = 0)
  → _run_countdown
       → state = COUNTDOWN
       → _generate_round_arena
            → ArenaGenerator.generate_round_arena_async
                 → pick template → maze → wall set → validate route
                 → ArenaStructureBuilder.build
                 → validate spawns / route
       → _clear_projectiles / corpses / void FX / gibs / rail VFX / debris
       → _spawn_round_debris
       → _respawn_fighters (transforms + CombatStats.reset)
       → emit countdown 3,2,1,FIGHT!
       → state = FIGHTING
```

### 3.2 Player spawn

```
_respawn_fighters
  → player.global_transform = ArenaGenerator.get_player_spawn_transform()
  → player.arena_respawn(spawn_pos)  // velocity, void flags, death state
  → CombatStats.reset_combat_stats()
  → enemy: same + apply_arena_bounds_from_dict + aim refresh
Spawn pads placed after floor raycast (_place_spawn_pads)
```

### 3.3 Enemy spawn

Same as player branch in `_respawn_fighters`; opponent is `RigidBody3D` with locked axes until death. AI `_player` reference refreshed via `refresh_target_references()`.

### 3.4 Player fire

```
Input shoot + WeaponManager.try_fire
  → GameManager.is_fighting?
  → WeaponFiring.fire(weapon, camera origin, aim dir, basis, scene, shooter)
       → railgun: ray loop + BeamTracer + PushHitResolver hits
       → shotgun: N × push_projectile
       → bazooka: bazooka_projectile
  → CombatAudio.play_weapon_fire
  → CombatVfxDirector.spawn_muzzle_fire
  → player.notify_weapon_fov_pulse
  → shot_fired signal → crosshair pulse
```

### 3.5 Enemy fire

```
ArenaOpponent._try_shot (timers + LOS + state)
  → align_weapon_to_target
  → EnemyWeaponManager.try_fire(muzzle pos, dir, basis)
       → WeaponFiring.fire(..., shooter = arena_opponent)
  → CombatAudio + CombatVfxDirector (enemy scale)
```

### 3.6 Shield damage

```
Projectile/beam/explosion → PushHitResolver.apply_*_hit
  → apply_damage_to_target
       → stats.record_hit(...)
       → shield_before / health_before captured
       → stats.apply_damage
       → CombatAudio.play_hit_confirm (shield tick sound if shield ↓, not break)
       → CombatVfxDirector.spawn_fighter_hit (small shield ring if shield ↓ only)
       → Crosshair.notify_player_damage_to (if player hit enemy)
```

### 3.7 Shield break

```
CombatStats.apply_damage (shield_before > 0, shield <= 0)
  → shield_broken.emit(source)
  → CombatFeedback.on_shield_broken
       → CombatVfxDirector.play_shield_break_event (rings + burst)
       → CombatAudio.play_shield_break (hit_confirm skipped same frame)
       → if player: player.notify_shield_broken (FOV + camera shake)
       → if enemy + player caused: crosshair.notify_enemy_shield_broken
  → ArenaUI._on_*_shield_broken (stats label flash only)
```

### 3.8 Health damage

```
apply_damage with shield == 0
  → health reduced
  → hit_confirm health sound + hurt layer
  → spawn_fighter_hit (red burst)
  → if health == 0: died.emit → fighter _on_combat_died
```

### 3.9 Death / scoring

```
CombatStats.died
  → Player or ArenaOpponent._on_combat_died
       → corpse / gib / dismember spawn
       → hide live meshes
       → GameManager.on_health_death(player_died, ...)
            → death message + wait (view_sec by death type)
            → increment score
            → _finish_round_after_score
                 → win? → MATCH_OVER
                 → else → _run_countdown (new arena…)
```

**Void fall path:**

```
Fighter Y < void threshold (fighting)
  → _report_void_fall (once)
  → GameManager._run_*_void_death_sequence
       → void overlay + begin_void_dying
       → VoidGoreSequence or VoidDeathEffect
       → finish_*_void_death → score → _finish_round_after_score
```

### 3.10 Arena generation

See §2.7 and `ArenaGenerator.generate_round_arena_async` (up to 6 attempts, fallback template).

### 3.11 Void fall (atmospheric)

```
VoidGasController._process
  → sample Y → depth_t, edge_t
  → if on deck: edge fog + CombatVfxDirector.apply_edge_tension
  → if falling: fog/DOF/void atmosphere + VoidAudio proximity
Player below VOID_FALL_WARNING_Y while fighting → instability + FOV widen
Below VOID_DEATH_Y → ring-out score path (not health death)
```

---

## 4. Architecture risks

### Duplicated logic

| Area | Issue |
|------|--------|
| Damage entry | `take_damage` on fighters vs `PushHitResolver.apply_damage_to_target` — must stay aligned |
| Shield break | Was historically split across UI, hit VFX, crosshair; now centralized in `CombatFeedback` (keep it that way) |
| Floor probes | `ArenaGenerator` raycasts vs enemy `is_floor_ahead` / `is_over_gap` |
| Weapon fire | Player `WeaponManager` vs `EnemyWeaponManager` duplicate post-fire audio/VFX calls |

### Unclear ownership

| Question | Where it lives today |
|----------|---------------------|
| Who scores? | `GameManager` only |
| Who validates arena? | `ArenaGenerator` + `ArenaRouteValidator` |
| Who plays combat SFX? | `VoidAudio` autoload via `CombatAudio` |
| Who spawns break VFX? | `CombatVfxDirector` via `CombatFeedback` |
| Round state? | `GameManager.state` — weapons/AI query `is_fighting()` |

### Tight coupling

- `PushHitResolver` → `CombatStats`, `CombatAudio`, `CombatVfxDirector`, `Crosshair` (static calls)  
- `GameManager` → concrete groups (`player`, `arena_opponent`, `arena_generator`)  
- `ArenaOpponent` → `ArenaGenerator` bounds dict shape (string keys)  
- `VoidGasController` → `ArenaUI`, `VoidAudio`, `CombatVfxDirector` by group/method name  

### Hidden dependencies

- Group lookups (`get_first_node_in_group`) — no compile-time checks  
- `has_method` / `call()` for `GameManager`, `damage_cover`, arena respawn hooks  
- `WeaponFiring` expects `scene_root.get_world_3d()` for rails  
- Player camera hierarchy mutation at runtime  

### Large files (candidates to split)

| File | ~Lines | Note |
|------|--------|------|
| `scripts/enemies/arena_opponent.gd` | 1090 | AI + void + death + combat |
| `scripts/weapons/push_hit_resolver.gd` | 625 | All hit types |
| `scripts/player.gd` | 635 | Locomotion + camera + death + void |
| `scripts/arena/arena_wall_set_generator.gd` | 360 | Cover placement |
| `scripts/effects/combat_vfx_director.gd` | 450 | All combat VFX |
| `scripts/environment/void_audio.gd` | 380 | Void + combat audio |

### Systems needing tests / debug tools

| System | Existing debug | Gap |
|--------|----------------|-----|
| Arena route | `ArenaGenerator.debug_show_route` | No automated test scenes |
| AI | `debug_ai_movement`, `debug_ai_fire`, weapon forward rays | No AI unit tests |
| Combat | `CombatStats.debug_name` prints | No damage table regression tests |
| Audio/VFX | Autoload export tunables | No bus/profile matrix |
| Spawns | `debug_show_spawn_markers` | Failed gen only logged to console |

### Other technical debt (from audit)

- No dedicated **audio buses** (`Void` / `Combat` / `UI`)  
- **NavMesh** not used — grid BFS only for arena validity  
- Legacy `scenes/arenas/*` + `arena_zone.gd` not used by round flow  
- `PerforableWallGrid` unused in build pipeline  
- Collision: most gameplay on **layer 1** (see [tech/ARCHITECTURE.md](tech/ARCHITECTURE.md) for corpse layer 8 note — verify against current `project.godot`)

---

## 5. Quick reference — groups

| Group | Used for |
|-------|----------|
| `game_manager` | Round flow |
| `player` / `arena_opponent` | Fighters |
| `arena_generator` | Floor raycasts, bounds |
| `weapon_manager` | Player weapon HUD |
| `projectile` | Round cleanup |
| `destructible_wall` / `arena_wall` / `structural_wall` | Combat + AI LOS |
| `structural_geometry` | Non-damage floors/walls |
| `arena_ui` / `crosshair` | HUD |
| `void_gas_controller` | Fall/edge atmosphere |
| `combat_vfx` | Short-lived combat nodes (timer free) |
| `corpse` / `void_effect` / `gib_chunk` | Round cleanup |

---

## 6. Directory index (`scripts/`)

| Folder | Contents |
|--------|----------|
| `arena/` | Templates, generator, maze, walls, route validation, builders |
| `weapons/` | Defs, firing, projectiles, hit resolver |
| `enemies/` | AI, enemy weapons, mount |
| `movement/` | Locomotion, camera feel, FOV, dodge |
| `effects/` | Combat VFX, void/gore/death, corpses, gibs |
| `environment/` | Void gas, atmosphere, audio autoload, legacy arena_zone |
| `audio/` | `CombatAudio`, `CombatFeedback`, `AudioStreamFactory` |
| `animation/` | Enemy look-at, weapon viewmodel bob |
| `props/` | Debris spawner/chunks, spawn pads |
| `ui/` | Crosshair |
| Root | `player.gd`, `game_manager.gd`, `combat_stats.gd`, `game_balance.gd`, `arena_ui.gd`, `push_enemy.gd` (legacy?) |

---

*Last mapped: prototype state with procedural arena maze, combat VFX autoload, shield-break feedback pipeline, and GladiatorFov aim stack.*
