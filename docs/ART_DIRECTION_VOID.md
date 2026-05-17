# VOID — Perceptual Horror Art Direction

The void is the enemy. Horror emerges from **space, depth, and perception** before any opponent appears.

## Core fantasy

> “I survived a place humans should not enter.”

Target emotion mix: **40% tension**, **30% isolation**, **20% curiosity**, **10% terror** — not constant action horror.

## Inspirations

Quake (industrial darkness), Unreal/liminal spaces, infinite abyss, acrophobia, cosmic loneliness, perceptual horror.

---

## 1. Fear of falling

- Narrow bridge, open sides, no visible bottom
- Hanging debris (`VoidAtmosphere/HangingDebris`)
- Pit floor **hidden** — abyss uses fog layers + particles, not flat black plane
- Player thought: *“If I fall, I disappear.”*

## 2. The void as entity

Implemented in `scenes/environment/void_atmosphere.tscn`:

- Moving fog layers below the arena
- Drifting abyss particles
- Pulsing depth light
- Distant silhouettes (`void_observer.tscn`) that fade when stared at
- Rare distant flashes after void deaths

Rules: darkness gradients, not flat black; subtle motion in the abyss.

## 3. Kenophobia (empty space)

- Large fog volume, sparse props
- Tiny player vs wide industrial bridge
- Empty space is content — avoid clutter

## 4. Fall cinematics (`VOID_GORE`)

| Time | Beat |
|------|------|
| 0.0s | Loss of balance / slide |
| 0.35s | Desperate movement ends → freefall |
| 0.5s | Void wind, ambient motes |
| 1.2s | Corruption gas |
| 1.6s | Body breakup |
| 2.0s | Burst → **score** |
| 3.5–6s | Delayed impact **or silence** (38% silent) |
| 4–7s | Optional distant abyss flash |

Audio placeholders: `scripts/environment/void_audio.gd`

## 5. Uncanny silhouettes

- Static humanoid capsules in the pit
- Hide when player looks directly (`void_observer.gd`)
- Never fully reveal

## 6. Perception distortion

- Floating / broken architecture (debris, broken columns)
- Platform ends in void
- Suspended structures with no visible support

## 7. Sound design

Sparse. Silence is allowed.

- Deep drones, wind without source, metallic resonance
- Long reverb on rupture/burst (placeholder prints)
- **No impact** sometimes — unknown destination

## 8. Visual palette

| Use | Colors |
|-----|--------|
| Structure | Dark grey, muted steel |
| Void | Cold blue-black gradients |
| Light | Cool directional + sparse rim |
| Gore | Dark red / black (stylized) |

**Avoid:** bright saturation, cartoon particles, warm orange fills.

## 9. Implementation map

| Asset / script | Role |
|----------------|------|
| `void_atmosphere.tscn` | Living abyss |
| `void_observer.tscn` | Periphery silhouettes |
| `void_audio.gd` | Audio placeholders |
| `void_gore_sequence.gd` | Pit death timeline |
| `game_balance.gd` | Style + timing constants |
| `main.tscn` | Cold lighting, hidden pit plane |

## Tuning

- Void death style: `GameBalance.VOID_DEATH_STYLE`
- Silent absorption chance: `VOID_SILENT_ABSORPTION_CHANCE`
- Distant flash chance: `VOID_DISTANT_FLASH_CHANCE`
