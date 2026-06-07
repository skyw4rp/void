# Gladiator Chamber — Implementation

**Scene:** `scenes/chamber/gladiator_chamber.tscn`  
**Builder:** `scripts/chamber/gladiator_chamber.gd`  
**Design spec:** [VOID_GLADIATOR_CHAMBER.md](VOID_GLADIATOR_CHAMBER.md) · layout [VOID_GLADIATOR_CHAMBER_LAYOUT.md](VOID_GLADIATOR_CHAMBER_LAYOUT.md)

**Entry point:** `project.godot` → `run/main_scene` = chamber. Arena duel via Terminal → `arena_match.tscn` → return with win/loss mood.

---

## Chamber cleanup pass (current)

**Goal:** Regain control — functional zones only. No new decorative systems, props, or room expansion.

| Zone node | Contents |
|-----------|----------|
| **Architecture** | Floor, ceiling, perimeter walls, north lintel |
| **LoadoutBay** | West back wall, nine interact pedestals (weapon / armor / helmet) |
| **CommandArea** | Map table + hologram, Arena Terminal |
| **ProgressionWall** | East wall + single placeholder plaque |
| **VoidWindow** | Framed opening + glass + void lights |
| **Lighting** | Key directional + four zone spots |
| **Atmosphere** | Light dust particles + height fog |

### Scene graph

```
ChamberRoot
  Architecture
  LoadoutBay
  CommandArea
  ProgressionWall
  VoidWindow
  Lighting
  Atmosphere
  DistantArchitecture
```

### Cleanup pass

After build, `_cleanup_chamber_visual_clutter()` removes any **visual-only** mesh at player height (`y` 0.4–2.5) with `size.x` or `size.z` > 4 m unless it is floor, wall, ceiling, loadout pedestal, map table, progression wall, or void frame/glass.

**Removed (no longer built):** ceiling/floor decor passes, columns, beams, cables, trims, panels, rest capsule, observation deck/benches, trophies/relics, emissive strips, shared loadout accents, ash/ember/vent particles, duplicate lighting rigs.

**Unchanged:** E-interact scripts, `GladiatorLoadout` positions, `GameFlow`, Terminal, return mood.

### Build summary (Output on F5)

```
Chamber build summary:
- architecture pieces: X
- loadout pieces: X
- command pieces: X
- visual clutter removed: X
```

---

## Intended flow

```
Spawn (center)
  → west: Loadout bay (equip all)
  → south: Command area (map table + Terminal START MATCH)
Return from arena
  → spawn → loadout → command
```

---

## Layout (32 × 26 m)

```
              [ VOID WINDOW — north ]
                          │
    [ LOADOUT BAY ]              [ PROGRESSION WALL ]
    weapons | armor | helmets         east
         west                          │
                spawn
            [ COMMAND AREA ]
              map table + Terminal
```

| Interact | Position (approx) |
|----------|-------------------|
| Spawn | `(0, 0, 2)` |
| Weapons | `(-11, 0, 5 / 0 / -5)` |
| Armor | `(-9.5, 0, 4 / 0 / -4)` |
| Helmets | `(-8, 0, 4.5 / 0 / -4.5)` |
| Terminal | `(0, 0.35, 9)` |

---

## Scripts

| File | Role |
|------|------|
| `gladiator_chamber.gd` | Procedural geometry, zone grouping, cleanup pass, mood |
| `chamber_player.gd` | FPS walk, interact ray |
| `chamber_interactable.gd` | Base E prompt |
| `chamber_weapon_rack.gd` | Weapon select + highlight |
| `chamber_armor_pedestal.gd` | Armor select + mannequin/highlight |
| `chamber_helmet_stand.gd` | Helmet select + emissive mesh |
| `chamber_arena_terminal.gd` | `GameFlow.start_arena_match()` |
| `chamber_hud.gd` | Loadout line + interact prompt |
| `game_flow.gd` | Chamber ↔ arena scene change, return mood |
| `gladiator_loadout.gd` | Persist `user://gladiator_loadout.cfg` |
| `arena_match_bridge.gd` | Apply weapon in arena, return after match |

---

## Return mood

| Result | Effect | Duration |
|--------|--------|----------|
| Victory | Lighter fog, brighter key + void window light | ~55 s |
| Defeat | Heavier fog, dim key, stronger void glow | ~28 s |
| Neutral | Base values | — |

---

## How to test

1. F5 — check Output for `Chamber build summary:`; `visual clutter removed` should be **0** on a clean build.
2. Walk loadout bay — no horizontal slab at chest height; three isolated pedestal groups only.
3. South — map table + Terminal [E] starts arena.
4. North — void visible through framed glass only (no crossing platforms/rails).
5. East — progression wall + placeholder plaque only.
6. After match, return mood on fog/key/void lights; no combat/arena changes.

---

## Related docs

- [PROTOTYPE.md](PROTOTYPE.md) — game flow summary  
- [VOID_RETURN_LOOP.md](VOID_RETURN_LOOP.md) — return mood design  
- [CODEBASE_MAP.md](CODEBASE_MAP.md) — autoloads and scene graph  
