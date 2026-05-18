# VOID — Prototype Audit (Neon Catacombs)

Audit date: prototype state with arena 1v1, `GladiatorLocomotion`, `WeaponMount` enemy aim, procedural void atmosphere.

**Gate for every fix:** Does it increase physical presence, oppressive atmosphere, existential scale, and perceptual tension?

**Philosophy:** [VOID_DESIGN_PHILOSOPHY.md](VOID_DESIGN_PHILOSOPHY.md)

---

## 1. Movement

| | |
|---|---|
| **Current state** | Player: `GladiatorLocomotion` (~**7.6** ground / **9.0** air). Enemy: **parity locomotion** via `EnemyGladiatorLocomotion` + human-like states (HUNTING…REPOSITIONING), reaction delay, aim error, weapon-range strafe. No player stat changes. |
| **Gap** | RigidBody vs CharacterBody integration still differs under heavy knockback stacks; `enemy_skill_level` needs playtest bands; optional jump parity not implemented (player jump unused in duel). |
| **Concrete fix** | Playtest `enemy_skill_level` 0.55–0.85; tune `enemy_strafe_aggression` per weapon; add enemy jump only if vertical arenas ship. |
| **Priority** | **P2** (tuning) |
| **Files** | `scripts/enemies/enemy_gladiator_locomotion.gd`, `arena_opponent_movement.gd`, `arena_opponent.gd`, `PROTOTYPE.md` parity table |

---

## 2. Mouse / camera feel

| | |
|---|---|
| **Current state** | Raw mouse on body yaw + **`AimPivot` pitch** (stable aim). **`CameraFeelPivot`**: roll, FOV, positional landing/dodge kick (no aim-axis tilt). Fire ray + crosshair use aim pivot; viewmodel bob visual-only. Crosshair movement spread off when `crosshair_stabilized`. |
| **Gap** | Optional sensitivity menu; shot pulse on crosshair only (no hit direction marker). FOV unified via `GladiatorFov` (smooth round start). |
| **Concrete fix** | Settings UI for sensitivity; tune `landing_shake_strength` / feel offset exports. |
| **Priority** | **P2** |
| **Files** | `scripts/movement/gladiator_camera_feel.gd`, `scripts/player.gd`, `scripts/ui/crosshair.gd`, `scripts/weapons/weapon_manager.gd` |

---

## 3. Enemy readability

| | |
|---|---|
| **Current state** | Low-poly humanoid: dark armor, orange emissive eyes/core, `WeaponMount` + distinct weapon meshes, body yaw via `EnemyLookAtController`, head/torso twist, arms follow mount. Aim cached on `ArenaOpponent` every physics frame. |
| **Gap** | Placeholder primitives — silhouette readable at mid range but not “gladiator” at distance; bright orange emission can **flatten** depth in dark arenas. Procedural torso/head motion can overlap mount aim if tuning drifts. |
| **Concrete fix** | Stronger shoulder/head asymmetry; dim eye emissive with distance falloff; idle “ready” pose bias (weapon high). Debug flags off by default in shipping scenes. Playtest silhouette at 15–25 m. |
| **Priority** | **P1** |
| **Files** | `scenes/enemies/arena_opponent.tscn`, `scripts/animation/enemy_look_at_controller.gd`, materials in scene subresources |

---

## 4. Weapon aiming visuals

| | |
|---|---|
| **Current state** | `EnemyWeaponMount` — **-Z** forward; per-weapon `Muzzle`; fire uses `get_weapon_forward()` + muzzle position; `_try_shot()` aligns before fire. Railgun / shotgun / bazooka distinct boxes + emissive tints. |
| **Gap** | Weapon meshes still basic; muzzle debug optional. Player viewmodel animated; enemy has no muzzle flash / beam line at fire — shot origin correct but **impact moment** weak at distance. |
| **Concrete fix** | Brief muzzle light + tracer/beam stub on enemy fire; verify mount reset on respawn in all death paths. Add silhouette contrast (darker stock, brighter barrel tip). |
| **Priority** | **P1** |
| **Files** | `scripts/enemies/enemy_weapon_manager.gd`, `scripts/enemies/enemy_weapon_mount.gd`, `scenes/enemies/enemy_weapon_manager.tscn`, `scripts/enemies/arena_opponent.gd` |

---

## 5. Lighting

| | |
|---|---|
| **Current state** | `main.tscn`: low ambient (**0.16**), fog density **0.042**, directional + rim + edge omni lights. Deck stays relatively readable; void layers darken below **Y -18**. |
| **Gap** | Arena deck can read **even-lit** vs philosophy (“isolate, obscure”); combat zone lacks strong shadow pools and single dominant key. Emissive enemies/weapons compete as light sources. |
| **Concrete fix** | Lower fill on deck; one stronger key + colder void rim; light cookies or blocker shadows on cover; reduce enemy emission energy in dark zones. Per-arena light profiles optional. |
| **Priority** | **P1** |
| **Files** | `scenes/main.tscn`, `scripts/environment/void_gas_controller.gd`, arena builder materials (`scripts/arena/arena_structure_builder.gd`, templates) |

---

## 6. Arena generation

| | |
|---|---|
| **Current state** | **Continuous monolith decks** (~**21×18** to **23×22** danger half-extents); **no interior floor holes**. Void ring-out via exterior `danger_half_*` only. **Indestructible maze** (`ArenaMazeGenerator` + `StructuralWall`) — 4 layout profiles, lane/gate validation (≥2 routes, min corridor width, spawn clearance). Destructible cover secondary (`ArenaWallSetGenerator`, reduced density when maze present). `ArenaBrutalistModules` corner pylons (visual). Spawn/debris raycasts on solid deck. |
| **Gap** | Still a single horizontal slab (no vertical shafts/cathedrals); rare maze regen retries on dense layouts; corner pylons visual-only. |
| **Concrete fix** | Vertical void vistas (visual), template-specific distant arch scale-up, stronger deck-edge crack read at sprint speed; optional rare elevated catwalk with route validation. |
| **Priority** | **P2** (vertical megastructure); **P1** (edge read at speed) |
| **Files** | `scripts/arena/arena_maze_generator.gd`, `scripts/arena/structural_wall.gd`, `scripts/arena/arena_templates.gd`, `scripts/arena/arena_structure_builder.gd`, `scripts/arena/arena_route_validator.gd`, `scripts/arena/arena_wall_set_generator.gd`, `scripts/arena/arena_generator.gd` |

---

## 7. Void / falling perception

| | |
|---|---|
| **Current state** | Ring-out **Y -20**; death **Y -32**; `VoidGasController` fog/vignette/DOF; layered `VoidAtmosphere`; observers; void fall cinematic (`VOID_GORE`), instability, FOV widen; distant flashes. **P0 audio:** `VoidAudio` autoload — drone loop, proximity bed (depth + arena edge), danger pulses, fall rush, void one-shots (procedural or `res://audio/void/*`). |
| **Gap** | Placeholder tones/noise — replace with designed assets ([audio/README_REPLACE_ASSETS.md](../audio/README_REPLACE_ASSETS.md)). Edge tension now has subtle vignette/desaturation/fog pulse (`CombatVfxDirector` + `VoidGasController`) but optional particle drift not added. Bottom still partially “layered fog” not always “infinite.” |
| **Concrete fix** | Swap procedural void assets; optional dedicated `Void` audio bus; boost downward particle density in fall; optional edge drift particles. Keep intentional silence beats in `VOID_GORE`. |
| **Priority** | **P1** (asset quality); ~~edge visual tension~~ **partial (P1 screen/fog)** |
| **Files** | `audio/void/*`, `scripts/environment/void_audio.gd`, `scripts/audio/audio_stream_factory.gd`, `scripts/effects/combat_vfx_director.gd`, `scripts/arena_ui.gd` |

---

## 8. VFX / audio feedback

| | |
|---|---|
| **Current state** | **P0 audio wired:** `CombatAudio` — weapon fire, shield/health hit, wall thud, hurt layer. **Shield break (dedicated):** `CombatFeedback` on `CombatStats` when shield **>0 → ≤0** (all weapons, once per break) — `AudioStreamFactory.shield_break()` / `res://audio/combat/shield_break.ogg`, expanding ring VFX, player screen pulse + camera impulse + FOV micro-pulse, enemy world burst + crosshair. Generic shield *hit* SFX suppressed on the break frame. **P1 combat VFX:** muzzle, shield/health/wall hits, arena-edge tension. Procedural placeholders until authored assets. |
| **Gap** | No dedicated audio buses. Landing/dodge mostly visual-only. Rail multi-hit may feel busy at high pierce (cooldown **45 ms**). Edge particle drift optional / not yet added. |
| **Concrete fix** | `Void` / `Combat` buses; tune `VoidAudio` export volumes; optional rail hit throttle; swap procedural VFX for authored one-shots. |
| **Priority** | **P1** (mix buses + asset polish); ~~hit VFX~~ **Done (procedural P1)** |
| **Files** | `scripts/audio/combat_feedback.gd`, `scripts/combat_stats.gd`, `scripts/effects/combat_vfx_director.gd`, `scripts/environment/void_audio.gd`, `scripts/audio/audio_stream_factory.gd`, `scripts/player.gd`, `scripts/ui/crosshair.gd`, `audio/combat/shield_break.ogg` |

---

## Priority summary

| Priority | Items |
|----------|--------|
| **P0** | ~~Real void + combat audio~~ **Done (procedural P0)** — replace with authored OGG |
| **P1** | Movement snap tune, camera shake discipline, enemy silhouette/emissive, deck lighting contrast, ~~hit/muzzle VFX~~ **Done (procedural)**, audio buses, void asset swap |
| **P2** | Megastructure-scale arena variants, vertical void vistas, template-specific distant arch |

---

## Alignment (what already matches VOID)

- Quake-inspired locomotion module and raw mouse look
- Void-as-system: fog collapse, fall tracking, ring-out, cinematic void death
- Enemy aim sync: mount forward = combat direction
- Art docs (`docs/art/ART_DIRECTION.md`) already encode perceptual horror
- Fast 1v1 kinetic loop — not cover-based
- Continuous arena floor + perimeter-only void fall (fairness + combat readability)
- Indestructible maze defines traversal; destructible cover adds tactical variation
- Combat VFX: readable muzzle direction, shield vs health hit language, **shield break state transition**, perimeter edge tension

---

## Out of scope (would violate gate)

- Military ADS / lean / stamina systems
- Realistic ballistics drop at arena ranges
- Cover-centric AI that stalls behind props
- Bright hero lighting or clean sci-fi materials on arenas
