# VOID — Prototype Audit (Neon Catacombs)

Audit date: prototype state with arena 1v1, `GladiatorLocomotion`, `WeaponMount` enemy aim, procedural void atmosphere.

**Gate for every fix:** Does it increase physical presence, oppressive atmosphere, existential scale, and perceptual tension?

**Philosophy:** [VOID_DESIGN_PHILOSOPHY.md](VOID_DESIGN_PHILOSOPHY.md)

---

## 1. Movement

| | |
|---|---|
| **Current state** | Quake-style `GladiatorLocomotion` on player (`ground_acceleration` 46, friction 5.5, max ground **7.6** / air **9.0**, strafe boost, dodge burst). Enemy `RigidBody3D` forces (~12.5) capped ~**6.5** — slower than player, readable duel pace. No root-motion lock on player. |
| **Gap** | Top speed was retuned down for “readable combat” — can read **slightly heavy/safe** vs classic Q3A aggression; dodge is short (**2.05 u**) and long cooldown (**1.4 s**). Enemy physics movement does not share the same accel/friction model (different feel family). |
| **Concrete fix** | A/B tune `max_ground_speed` / `ground_acceleration` toward snappier strafe-stop without float; optional “VOID sprint” only on long straights. Document target speeds in `GameBalance`. Align enemy **feel** via force curves, not player slowdown alone. |
| **Priority** | **P1** |
| **Files** | `scripts/player.gd`, `scripts/movement/gladiator_locomotion.gd`, `scripts/movement/combat_dodge.gd`, `scripts/game_balance.gd`, `scripts/enemies/arena_opponent.gd` |

---

## 2. Mouse / camera feel

| | |
|---|---|
| **Current state** | Raw mouse on body yaw + camera pitch (`MOUSE_SENSITIVITY` 0.002, no smoothing). `GladiatorCameraFeel`: roll tilt, speed FOV, landing shake, air sway, dodge pitch. Void fall widens FOV (**90→102**). Obliteration / void instability add procedural shake. |
| **Gap** | Landing shake applies **random pitch jitter** on `camera.rotation.x` — can fight precision during recovery. Air sway + void shake stack may feel “cinematic” under heavy knockback. No forward/accel-based view punch (only speed FOV). |
| **Concrete fix** | Clamp landing shake to roll-only or decay before next shot; cap stacked shake amplitudes. Add tiny forward impulse on land/dodge (position offset, not rotation). Expose sensitivity in settings. Keep void fall FOV but avoid shake during aim-critical windows. |
| **Priority** | **P1** |
| **Files** | `scripts/movement/gladiator_camera_feel.gd`, `scripts/player.gd`, `scripts/game_balance.gd` |

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
| **Current state** | **Continuous monolith decks** (~**21×18** to **23×22** danger half-extents); **no interior floor holes**. Void ring-out via exterior `danger_half_*`, perimeter openings, fall-zone VFX, void fog/audio. Signature columns/slabs + `ArenaBrutalistModules` corner pylons + procedural flank cover. Spawn/debris raycasts on solid deck. |
| **Gap** | Still a single horizontal slab (no vertical shafts/cathedrals); procedural wall regen can still log retries on dense layouts; corner pylons are visual-only. |
| **Concrete fix** | Vertical void vistas (visual), template-specific distant arch scale-up, stronger deck-edge crack read at sprint speed; optional rare elevated catwalk only with route validation. |
| **Priority** | **P2** (vertical megastructure); **P1** (edge read at speed) |
| **Files** | `scripts/arena/arena_templates.gd`, `scripts/arena/arena_brutalist_modules.gd`, `scripts/arena/arena_structure_builder.gd`, `scripts/arena/arena_wall_set_generator.gd`, `scripts/arena/arena_perimeter_builder.gd` |

---

## 7. Void / falling perception

| | |
|---|---|
| **Current state** | Ring-out **Y -20**; death **Y -32**; `VoidGasController` fog/vignette/DOF; layered `VoidAtmosphere`; observers; void fall cinematic (`VOID_GORE`), instability, FOV widen; distant flashes. **P0 audio:** `VoidAudio` autoload — drone loop, proximity bed (depth + arena edge), danger pulses, fall rush, void one-shots (procedural or `res://audio/void/*`). |
| **Gap** | Placeholder tones/noise — replace with designed assets ([audio/README_REPLACE_ASSETS.md](../audio/README_REPLACE_ASSETS.md)). Pre-fall edge warning could be stronger visually (peripheral desaturate). Bottom still partially “layered fog” not always “infinite.” |
| **Concrete fix** | Swap procedural void assets; optional dedicated `Void` audio bus; boost downward particle density in fall. Keep intentional silence beats in `VOID_GORE`. |
| **Priority** | **P1** (asset quality + edge visual tension) |
| **Files** | `audio/void/*`, `scripts/environment/void_audio.gd`, `scripts/audio/audio_stream_factory.gd` |

---

## 8. VFX / audio feedback

| | |
|---|---|
| **Current state** | **P0 wired:** `CombatAudio` hooks — per-weapon fire (player + enemy 3D), shield/health hit confirm, wall/cover thud, fighter hurt layer on health damage. Void gore timeline still uses `VoidAudio` static API. Procedural placeholders until OGG drops in `res://audio/combat/`. |
| **Gap** | Hit confirm still light on **VFX** (flash/tracer). No dedicated audio buses. Landing/dodge mostly visual. Rail multi-hit may feel busy at high pierce (cooldown **45 ms**). |
| **Concrete fix** | Brief muzzle/impact VFX; `Void` / `Combat` buses; tune `VoidAudio` export volumes; optional rail hit throttle. |
| **Priority** | **P1** (hit VFX + mix buses) |
| **Files** | `scripts/audio/combat_audio.gd`, `scripts/weapons/push_hit_resolver.gd`, `scripts/weapons/weapon_manager.gd`, `scripts/enemies/enemy_weapon_manager.gd`, `audio/combat/*` |

---

## Priority summary

| Priority | Items |
|----------|--------|
| **P0** | ~~Real void + combat audio~~ **Done (procedural P0)** — replace with authored OGG |
| **P1** | Movement snap tune, camera shake discipline, enemy silhouette/emissive, enemy fire VFX, deck lighting contrast, hit VFX, audio buses, void asset swap |
| **P2** | Megastructure-scale arena variants, vertical void vistas, template-specific distant arch |

---

## Alignment (what already matches VOID)

- Quake-inspired locomotion module and raw mouse look
- Void-as-system: fog collapse, fall tracking, ring-out, cinematic void death
- Enemy aim sync: mount forward = combat direction
- Art docs (`docs/art/ART_DIRECTION.md`) already encode perceptual horror
- Fast 1v1 kinetic loop — not cover-based
- Continuous arena floor + perimeter-only void fall (fairness + combat readability)

---

## Out of scope (would violate gate)

- Military ADS / lean / stamina systems
- Realistic ballistics drop at arena ranges
- Cover-centric AI that stalls behind props
- Bright hero lighting or clean sci-fi materials on arenas
