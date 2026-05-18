# VOID — Quick Reference

One-page onboarding cheat sheet. Full detail: [CODEBASE_MAP.md](CODEBASE_MAP.md) · Audit: [TECHNICAL_AUDIT.md](TECHNICAL_AUDIT.md) · Safety: `.cursor/rules/void-code-safety.mdc`

**Entry** `scenes/main.tscn` · **Autoloads** `VoidAudio`, `CombatVfxDirector` · **Win** first to **5** rounds

---

## 1. Project identity

**What VOID is** — Godot 4.6, Jolt physics, 1v1 arena FPS (*Neon Catacombs*). Psychological brutalist feel: Quake-style movement in megastructures over an indifferent void. Win by **ring-out** or **shield break + kill**.

**Core loop** — Match → rounds → **countdown** (regen arena, cleanup, respawn) → **fight** (weapons, AI, void edge) → **round end** (death/void) → **score** → repeat until 5 → match over.

**Design pillars** (gate all feel changes)

| Pillar | Do | Don’t |
|--------|----|-------|
| Movement | Immediate, accel/friction, momentum | Floaty, input delay, anim-locked |
| Camera / aim | Body-attached, raw mouse, stable pitch stack | Extra smooth on look, FOV fights aim |
| Combat | Spatial rhythm, readable hits | Static cover loops, realism clutter |
| Void | Threat as important as enemy | Interior holes, casual fall zones |
| Arena | Continuous floor, routes, structural maze + destructible cover | Break layout validation for “cool” pieces |

---

## 2. Critical owners

| System | Owner | Do not touch | Notes |
|--------|-------|--------------|-------|
| **Player** | `player.gd` | Locomotion math in `GladiatorLocomotion` from player hacks | `CharacterBody3D`; group `player` |
| **Aim** | `player.gd` → `AimPivot` | Pitch on body or `CameraFeelPivot` | Yaw body, pitch pivot; `get_aim_global_transform()` |
| **Camera feel** | `gladiator_camera_feel.gd` | Pitch, FOV, aim | Roll/offset on `CameraFeelPivot` only |
| **FOV** | `gladiator_fov.gd` | Direct `camera.fov` elsewhere | Applied in `player._process` |
| **Weapons** | `weapon_manager.gd` / `enemy_weapon_manager.gd` → `weapon_firing.gd` → `push_hit_resolver.gd` | Damage numbers in managers | Stats in `weapon_defs.gd` |
| **Enemy AI** | `arena_opponent.gd` + `enemy_gladiator_locomotion.gd` | Player `GladiatorLocomotion` on enemy | Parity speed; reaction/aim error exports |
| **Arena** | `arena_generator.gd` + maze/wall/route/builder | Skip validator or spawn raycast | Maze → cover → validate → build |
| **Audio** | `void_audio.gd` (autoload) + `combat_audio.gd` / `combat_feedback.gd` | Ad-hoc `AudioStreamPlayer` in random scripts | No `class_name` on autoload |
| **VFX** | `combat_vfx_director.gd` (autoload) | Duplicate shield-break bursts | Group `combat_vfx` |
| **Shield** | `combat_stats.gd` | Second break SFX/VFX path | Absorbs before health |
| **Health** | `combat_stats.gd` | Score on `died` outside `GameManager` | `died` → fighter → `on_health_death` |
| **Round** | `game_manager.gd` | Score/state from UI or resolver | `is_fighting()` gates weapons |
| **Void** | `void_gas_controller.gd` + gore/death effects | Ring-out logic in UI | Y thresholds in `GameBalance` |

---

## 3. Round lifecycle

```
COUNTDOWN → SPAWN → FIGHT → COMBAT → DEATH → SCORE → RESET
```

| Phase | Owner | Key actions |
|-------|-------|-------------|
| **Countdown** | `GameManager` | `COUNTDOWN` → `ArenaGenerator.generate_round_arena_async()` → clear groups → debris → respawn → `3,2,1,FIGHT!` → `FIGHTING` |
| **Spawn** | `ArenaGenerator` | Player/enemy transforms + `CombatStats.reset` |
| **Fight** | Player + `ArenaOpponent` | Input/AI; weapons check `is_fighting()` |
| **Combat** | `PushHitResolver` | Hit → `CombatStats.apply_damage` → audio/VFX/crosshair |
| **Death** | `CombatStats` → fighters → `GameManager` | Health `died` or void sequence → presentation |
| **Score** | `GameManager` | +1 → `score_changed` → match at 5 or next countdown |
| **Reset** | `GameManager` | Full arena regen; not incremental geometry |

**Shield break** (inside combat): `shield > 0 → ≤ 0` → `shield_broken` → **`CombatFeedback.on_shield_broken` only** (VFX/audio/player/crosshair).

---

## 4. Single-writer rules

| State / behavior | Only writer | Others |
|------------------|-------------|--------|
| Aim pitch | `AimPivot` (`player.gd`) | Read `get_aim_global_transform()` |
| Camera roll/offset | `GladiatorCameraFeel` | Never pitch/FOV here |
| Final FOV | `GladiatorFov.apply` | Offsets via its API only |
| Shield / health values | `CombatStats.apply_damage` / `reset` | UI listens |
| Shield break feedback | `CombatFeedback.on_shield_broken` | No parallel break VFX in resolver |
| Combat damage application | `PushHitResolver` → `CombatStats` | No raw `apply_damage` from weapons |
| Round score & `RoundState` | `GameManager` | UI signals only |
| Arena layout per round | Generators → `ArenaTemplate` → `ArenaStructureBuilder` | Don’t hand-place in `main` for rounds |
| Structural walls | `StructuralWall` | Never `damage_cover()` |
| Destructible walls | `destructible_wall.gd` | HP via resolver only |

---

## 5. Dangerous areas (P0 only)

| Risk | Where | Symptom |
|------|-------|---------|
| **Damage outside `FIGHTING`** | `push_hit_resolver.gd` → `CombatStats.apply_damage` (no `is_fighting()` guard) | Hits during countdown/round-over; stray projectiles score |
| **Same root cause** | `combat_stats.gd` `apply_damage` | `shield_broken` / `died` during wrong phase |

**Fix direction** (when approved): guard `apply_damage_to_target` and/or `apply_damage` with `GameManager.is_fighting()`. See T-001 / T-008 in [TECHNICAL_AUDIT.md](TECHNICAL_AUDIT.md).

**Do not “fix” casually** — gameplay change; needs explicit request.

---

## 6. Debug checklist

Enable exports on `main.tscn` nodes, run F5, verify behavior.

| Area | Node | Flag / action |
|------|------|----------------|
| **Player move** | `Player` | `debug_movement` → console locomotion |
| **Aim** | `EnemyLookAtController` | `debug_show_aim_ray`, `debug_show_enemy_forward` |
| **Enemy** | `ArenaOpponent` | `debug_ai_movement`, `debug_ai_fire` |
| **Arena** | `ArenaGenerator` | `debug_show_route`, `debug_show_spawn_markers`, `debug_show_markers` |
| **Shield** | `CombatStats` | `debug_name` → prints shield/health on damage |
| **Audio** | Autoload `VoidAudio` | Inspector volumes; break shield → rupture vs tick |
| **VFX** | Autoload `CombatVfxDirector` | `vfx_intensity`, `shield_break_scale`; edge walk → vignette |
| **Void** | Fall off deck | Overlay + FOV widen; console arena gen logs |

**Quick sanity:** Remote scene tree → groups `player`, `game_manager`, `arena_generator`, `projectile`. After round start, projectiles/corpses should be empty.

---

## 7. Before commit checklist

- [ ] **Scope** — Only files needed for the task; no drive-by refactors
- [ ] **Owners** — No second writer for aim, FOV, shield break, score, arena validation
- [ ] **Gameplay** — If touching damage/movement/weapons/AI/arena: user asked explicitly
- [ ] **Round flow** — Fire/damage respects `is_fighting()` (know P0 if touching resolver)
- [ ] **Feedback** — Shield break still single path via `CombatFeedback`
- [ ] **Arena** — Routes + spawn raycast still pass; structural ≠ destructible
- [ ] **Run** — F5 one full round: countdown → fight → kill or void → next round
- [ ] **Docs** — New subsystem? Update [CODEBASE_MAP.md](CODEBASE_MAP.md) (this sheet if owner table changes)

---

*Documentation only. ~2 pages. Expand in CODEBASE_MAP.md.*
