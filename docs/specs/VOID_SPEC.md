# VOID — Product Specification (Reverse SDD)

**Source of truth:** implemented code in `c:\neon-catacombs` (Godot 4.6).  
**Last aligned:** May 2026 · prototype vertical slice.

This document describes **what the game is today**, not the full long-term vision.

---

## What the game is

**Neon Catacombs (VOID)** is a first-person **1v1 knock-off duel** over procedural suspended arenas above an infinite toxic void. Movement is Quake-influenced (immediate input, momentum, strafe). Horror comes from **scale, depth, fog, and fall dread** — not cover-shooter pacing.

**Current entry:** `res://scenes/chamber/gladiator_chamber.tscn` (`project.godot` main scene).

---

## Core fantasy

| Pillar | In build |
|--------|----------|
| **The void is the enemy** | Ring-out deaths, dense gas below deck, VOID_GORE cinematic, distant ruins |
| **Brutalist megastructure** | Procedural arenas, chamber shell, void window, distant architecture |
| **Gladiator ritual** | Prep in chamber → terminal starts match → return with mood |
| **Kinetic combat** | Knockback, shield break, destructible cover, spatial rhythm |

**Emotion target (design intent):** tension · isolation · curiosity · dread. Not fully authored in all zones yet.

---

## Player loop (macro)

```
Launch → Gladiator Chamber
  → [E] equip loadout (west bay)
  → [E] Arena Terminal → START MATCH
  → arena_match.tscn (full 1v1 to 5 points)
  → ~2.8 s delay → return to chamber (win/loss mood)
  → repeat
```

| System | Owner |
|--------|--------|
| Scene flow | Autoload `GameFlow` (`scripts/chamber/game_flow.gd`) |
| Loadout persistence | Autoload `GladiatorLoadout` → `user://gladiator_loadout.cfg` |
| Arena bridge | `scripts/chamber/arena_match_bridge.gd` |

---

## Chamber loop

**Purpose:** Safe prep hub — equip weapon, select armor/helmet (saved), start match, absorb return mood. No combat.

| Zone | Location | Function |
|------|----------|----------|
| **LoadoutBay** | West (`x ≈ -8` to `-11`) | 3 weapon + 3 armor + 3 helmet interact pedestals |
| **CommandArea** | South (`z ≈ 6–9`) | Map table (visual), Arena Terminal |
| **VoidWindow** | North | Framed void observation |
| **ProgressionWall** | East (`x ≈ 14`) | Upgrade placeholders (visual only) |
| **Architecture** | Shell | Floor, walls, ceiling |

**Builder:** `scripts/chamber/gladiator_chamber.gd` — procedural `ChamberRoot` with zone nodes.

**Interact (E):**

| Object | Effect |
|--------|--------|
| Weapon pedestals | Sets weapon in `GladiatorLoadout`; applies in arena via `WeaponManager.switch_weapon` |
| Armor pedestals | Saves armor choice — **no combat stat change in MVP** |
| Helmet stands | Saves helmet choice — **no combat stat change in MVP** |
| Arena Terminal | `GameFlow.start_arena_match()` |

**Return mood:** victory → lighter fog / brighter key (~55 s); defeat → heavier fog (~28 s). See `VOID_RETURN_LOOP.md`.

**Known issues:** visual composition still needs polish; procedural generation had slab/clutter cleanup issues (`HangingSpan` from distant arch removed in chamber only).

---

## Arena loop (match)

**Scene:** `res://scenes/arena/arena_match.tscn` (legacy `main.tscn` equivalent + bridge).

**Mode:** Player vs **one AI** (`ArenaOpponent`).

| Rule | Value |
|------|-------|
| Win condition | First to **5** points (`GameManager.WIN_SCORE`) |
| Round start | Countdown `3 → 2 → 1 → FIGHT!` (1.0 s / step, 0.7 s FIGHT) |
| During countdown | Fighters frozen — no move, no shoot |
| After point | New arena, clear FX/debris, respawn, countdown |
| Arena pick | Random template; won't repeat same name back-to-back |

Each round:

1. `ArenaGenerator.generate_round_arena_async()` — maze, cover, build, validate spawns (up to 6 attempts, Toxic Bridge fallback).
2. Clear projectiles, corpses, void FX, gibs, debris.
3. Spawn destructible cover on validated floor points.
4. Respawn player + enemy; AI receives arena bounds.
5. Fight until point scored → repeat or match end.

---

## Combat loop (round)

While `GameManager.state == FIGHTING`:

1. **Player:** input → `GladiatorLocomotion` → `WeaponManager.try_fire` (aim from `AimPivot`).
2. **Enemy:** AI state machine → movement forces → `EnemyWeaponManager.try_fire`.
3. **Hits:** `WeaponFiring` / projectiles → `PushHitResolver` → `CombatStats.apply_damage`.
4. **Shield break:** transition shield > 0 → ≤ 0 once → `CombatFeedback` (VFX + SFX + camera/crosshair).
5. **Death:** health ≤ 0 or void ring-out → spectacle → score → next round.

**Damage order:** shield absorbs first; overflow reduces health.

**Round-state guard (known gap):** `PushHitResolver.apply_damage_to_target` does not always gate on `is_fighting()` — see T-001 in `TECHNICAL_AUDIT.md`.

---

## Win / loss rules

| Outcome | Condition | Scoring |
|---------|-----------|---------|
| **Ring-out** | Fighter `global_position.y < void_y` while fighting (`void_y` default **-20**) | Opponent +1 |
| **Kill** | Health ≤ 0 after shield depleted | Attacker's side +1 |
| **Match win** | Either score ≥ 5 | `match_over` signal → bridge returns to chamber |

**Void layers:**

| Y threshold | Role |
|-------------|------|
| **-18** | Fall warning / light gas (`GameBalance.VOID_FALL_WARNING_Y`) |
| **-20** | Ring-out score trigger (fighter / generator default) |
| **-32** | Deep void death Y (`GameBalance.VOID_DEATH_Y`) |

Ring-out presentation uses **VOID_GORE** cinematic (~**3.2 s** burst) when `GameBalance.VOID_DEATH_STYLE == VOID_GORE`.

---

## Current weapons

Defined in `scripts/weapons/weapon_defs.gd`. Player and enemy share stats.

| Weapon | Cooldown | Fighter damage | Notes |
|--------|----------|----------------|-------|
| **Railgun** | 1.6 s | 100 (beam) | Pierce up to 8 hits; minimal wall HP damage; precision knockback |
| **Shotgun** | 0.75 s | 10 × 7 pellets | Spread 0.14; destructible cover damage 8/pellet |
| **Bazooka** | 1.4 s | 100 direct / 60 explosion | Radius 5.0; rocket jump self-blast tuning; heavy knockback |

**Wall damage:** railgun marks/perforates (grid); shotgun/bazooka break `DestructibleWall`.

**Loadout:** chamber weapon choice maps to `WeaponDefs.Id` in arena only.

---

## Current health / shield

**Owner:** `scripts/combat_stats.gd` on player and `ArenaOpponent`.

| Stat | Default | Behavior |
|------|---------|----------|
| Shield | 100 | Absorbs damage first |
| Health | 100 | Damage after shield exhausted |
| Reset | Each round | `reset_combat_stats()` on respawn |

**Shield break:** single trigger per `apply_damage` when shield crosses to ≤ 0 → `shield_broken` signal → `CombatFeedback.on_shield_broken`.

**Armor / helmet (chamber):** persisted in save file; **not applied to CombatStats in MVP**.

---

## Current gore / void death

**Tuning:** `scripts/game_balance.gd` · `VOID_DEATH_STYLE = VOID_GORE`.

| Death type | Presentation |
|------------|----------------|
| **Void ring-out** | `VoidGoreSequence` timeline: instability → ambient → corruption → breakup → burst (~3.2 s); void audio layers; optional silent absorption |
| **Health kill (normal)** | Corpse tumble ~2.5 s (`KILL_DEATH_VIEW_SEC`) |
| **Heavy kill** | Gib cluster or dismemberment (bazooka, overkill thresholds) |
| **Dismemberment triggers** | Heavy death; shotgun ≥28 dmg; railgun overkill ≥8 |

**Spawners:** `CorpseSpawner`, `GibSpawner`, `DismembermentSpawner`, `VoidDeathEffect` (legacy styles still in enum).

---

## Current AI behavior

**Owner:** `scripts/enemies/arena_opponent.gd` (~1200 lines) + `arena_opponent_movement.gd`, `enemy_gladiator_locomotion.gd`.

**States:** `HUNTING`, `PRESSURING`, `EVADING`, `RECOVERING`, `EXECUTING`, `IN_COVER`, `REPOSITIONING`.

| Behavior | Implemented |
|----------|-------------|
| Player parity movement | RigidBody + locomotion-equivalent forces |
| Human-like tuning | Reaction time, aim error, skill level, strafe aggression |
| Cover / edge | Cover seek, hole avoid, ring-out shot angles, arena bounds from generator |
| Weapons | AI weapon shuffle (railgun / shotgun / bazooka intervals) |
| LOS | Raycasts vs `arena_wall` / structural walls |
| Look-at | `EnemyLookAtController` + `ProceduralEnemyAnimator` on `WeaponMount` |

**Known issues:** enemy visual aim/animation needs final polish; placeholder primitives; procedural motion can drift from mount aim.

---

## Chamber purpose (summary)

The Gladiator Chamber is the **ritual prep space** between matches: orient player (loadout flow west), commit to fight (terminal south), glimpse void (north), foreshadow progression (east). It is **not** a combat space. Geometry is procedural; interact positions are fixed constants in `gladiator_chamber.gd`.

---

## Planned / not implemented

| Feature | Status |
|---------|--------|
| Armor/helmet gameplay stats | Planned — save only |
| Progression wall unlocks | Planned — placeholders only |
| Multiplayer | Planned |
| Backend / accounts | Not in scope |
| Full authored chamber art | Partial — procedural boxes |
| Settings menu (sensitivity) | Planned |

---

## Related docs

- [VOID_DESIGN.md](../design/VOID_DESIGN.md) — system architecture
- [VOID_TASKS.md](../tasks/VOID_TASKS.md) — prioritized work
- [PROJECT_STATUS.md](../PROJECT_STATUS.md) — implementation state
- [PROTOTYPE.md](../PROTOTYPE.md) — detailed build reference
- [CODEBASE_MAP.md](../CODEBASE_MAP.md) — file ownership
