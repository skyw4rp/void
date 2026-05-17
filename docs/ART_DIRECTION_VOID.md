# Void perceptual horror — implementation index

> **Canonical design doc:** [art/ART_DIRECTION.md](art/ART_DIRECTION.md)  
> **Project overview:** [project_bible/PROJECT_BIBLE.md](project_bible/PROJECT_BIBLE.md)

This file tracks **what exists in the current prototype** for the perceptual horror pass. Design rules live in `art/ART_DIRECTION.md`.

---

## In-game systems

| Feature | Location |
|---------|----------|
| Living abyss (fog, particles, pulse) | `scenes/environment/void_atmosphere.tscn` |
| Void observers (hide when stared at) | `scenes/environment/void_observer.tscn` |
| VOID_GORE fall timeline | `scripts/effects/void_gore_sequence.gd` |
| Void death styles | `scripts/game_balance.gd` → `VOID_DEATH_STYLE` |
| Audio placeholders | `scripts/environment/void_audio.gd` |
| Hidden pit floor | `main.tscn` — `PitVoid` invisible; atmosphere handles abyss |
| Cold industrial lighting | `main.tscn` |

---

## VOID_GORE timeline (seconds)

| Time | Beat |
|------|------|
| 0.0 | Loss of balance |
| 0.35 | Freefall |
| 0.5 | Ambient motes / void wind |
| 1.2 | Corruption cloud |
| 1.6 | Body breakup |
| 2.0 | Burst → score |
| 3.5–6 | Impact echo or **silence** |
| 4–7 | Optional distant abyss flash |

---

## Tuning constants

`scripts/game_balance.gd`:

- `VOID_SILENT_ABSORPTION_CHANCE`
- `VOID_DISTANT_FLASH_CHANCE`
- `VOID_DEATH_STYLE` (default `VOID_GORE`)

---

## Not yet in build

- Real audio assets (drones, reverb tails)
- Additional levels (vertical shafts, massive halls)
- Non-euclidean layouts
- Broken gravity zones

See [roadmap/ROADMAP.md](roadmap/ROADMAP.md).
