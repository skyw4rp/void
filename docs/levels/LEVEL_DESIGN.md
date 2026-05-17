# Level Design

## Arena philosophy (current build)

Combat arenas are **compact**, **tactical**, and **Quake-void inspired** — not giant open bridges.

| Principle | Implementation |
|-----------|----------------|
| **Large footprint** | ~24×24 to ~32×32 main decks; 6+ unit bridges |
| **Interconnected platforms** | Multiple floor slabs with intentional gaps |
| **Cover** | Static `arena_wall` pieces + destructible debris |
| **Deadly gaps** | Missing floor = infinite toxic void below |
| **Ring-out on purpose** | Knock enemies through gaps; edges are tighter than old 8×28 bridge |
| **Suspended fortress** | Outer perimeter ruins frame the fight (~40–70% enclosure, never sealed) |

---

## Outer perimeter (ruined enclosure)

Each round builds a **partial outer shell** via `ArenaPerimeterBuilder`:

| Element | Role |
|---------|------|
| **Broken outer walls** | 2.5–3.8 m, block shots, frame sightlines |
| **Half walls / collapsed sections** | 0.9–1.8 m, corridor cover |
| **Cracked pillars** | Corner breaks, vertical cover |
| **Hanging panels** | Elevated slabs, peek lanes |
| **Decor silhouettes** | 4–6 m towers & breakwalls — **no collision**, void backdrop only |

- **60–80% protected** — `ringout_open_sides` leave tactical openings; fall markers at edges
- **Gas below deck** — dense layers at **Y -18** and lower; clear footing at **Y = 0**
- All perimeter collision panels are **destructible** (`DestructibleWall`, **70–200** HP by piece type)
- Materials: dark concrete, oxidized metal, black stone
- Inner `arena_wall` pieces + outer perimeter + destructible debris = layered cover

**Player read:** *inside a ruined structure hanging over an endless gas pit*, not a lone platform in space.

---

## Level pillars

Every arena should reinforce:

1. **Fall anxiety** — visible toxic gas below, no safe ground
2. **Tactical density** — walls break railgun lanes; corners favor shotgun
3. **Readable combat** — fair footing on slabs; obvious void gaps
4. **Mystery** — silhouettes and drift in fog, never fully explained

---

## Void spaces

- **Not** pure black — thick **toxic/corrupted gas** (green / blue / purple)
- Layered fog in `WorldEnvironment` + `VoidAtmosphere` gas sea
- Drifting particles with slow animation
- Ring-out still uses **VOID_GORE** cinematic before score
- **Dense gas ocean** — combat deck stays readable; falls collapse to **near-zero visibility** (~1–2 m) in the deep gas
- Arena above is **swallowed by fog** behind the falling fighter; distant silhouettes fade out

---

## Navigation

- Procedural templates in `scripts/arena/arena_templates.gd`
- Spawn validation via downward raycast on floor layer **1**
- AI avoids holes with floor probes and recenters on platforms

---

## Combat flow goals

- Strafe around **static walls** and **destructible cover**
- **Railgun** peek at long lanes when LOS is clear
- **Shotgun** around corners when LOS blocked
- **Bazooka** through gaps and for ring-out setups
- Knock opponents into **intentional pits**, not random wide rim slips

---

## Arena roster

| Arena | Character |
|-------|-----------|
| **Broken Reactor** | Central void pit, C-walkway, reactor walls |
| **Toxic Bridge** | Narrow connector, side drops |
| **Split Platforms** | Twin islands, catwalk bridges |
| **Ruined Courtyard** | Ring path around open courtyard |
| **Hanging Corridors** | Parallel lanes, cross bridges |

---

## Player flow

```
Spawn → Countdown → Fight → (Void kill | Health kill) → Cinematic → Score → New arena → Repeat
```

See `docs/PROTOTYPE.md` for systems detail.
