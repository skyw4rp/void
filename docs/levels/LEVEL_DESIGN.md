# Level Design

## Level Pillars

Every VOID arena should reinforce:

1. **Fall anxiety** — visible drop, no safe ground below
2. **Isolation** — empty volume beside or under combat space
3. **Readable combat** — fair footing, clear ring-out edges
4. **Mystery** — something in the dark, never fully explained

---

## Verticality

- Bridge and catwalks over void
- Long vertical shafts (future levels)
- Player often **above** the threat plane
- Falling is a **long** experience before score (cinematic time)

---

## Void Spaces

- Pit must not read as “low floor”
- Fog layers, particles, moving depth
- Optional observers at periphery
- Corruption VFX at death point only — not constant clutter

---

## Navigation

- Current prototype: **linear bridge** 8×28 units
- Clear spawn ends; face opponent at round start
- No maze required in 1v1 arena; complexity comes from **space** not layout

---

## Combat Arenas

- Narrow deck encourages knock-off
- Center crate for cover (optional obstruction)
- Low rails = warning, not wall
- AI bounds rectangular — steers from sides and ends

---

## Isolation Sections

- Future: transition halls with **nothing** in them
- Long walk before arena door
- Single light source, long reverb
- Current build: isolation via **open pit** beside all combat

---

## Secrets

- Environmental storytelling only (no loot required for core loop)
- Broken columns, cracks, hanging debris
- Distant silhouettes (not interactable)
- _Define collectible/lore pickups per level later_

---

## Player Flow

```
Spawn → Countdown → Fight → (Void kill | Health kill) → Cinematic → Score → Respawn → Repeat
```

- Void death: do not respawn until cinematic + score complete
- Match end: stop combat, show result

---

## Current Reference Level

**Neon Catacombs bridge** — see `docs/PROTOTYPE.md` for dimensions and spawn coordinates.
