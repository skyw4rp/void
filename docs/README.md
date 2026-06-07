# VOID — Documentation Index

Design and production docs for **Neon Catacombs / VOID** (Godot 4.6 prototype).

---

## Reverse SDD (source of truth — start here)

Aligned to **implemented code** as of the latest reverse SDD pass.

| Document | Purpose |
|----------|---------|
| [specs/VOID_SPEC.md](specs/VOID_SPEC.md) | **What the game is today** — loops, rules, weapons, AI, chamber |
| [design/VOID_DESIGN.md](design/VOID_DESIGN.md) | **How systems connect** — ownership, flows, modules |
| [tasks/VOID_TASKS.md](tasks/VOID_TASKS.md) | **Prioritized backlog** — P0–P3 |
| [PROJECT_STATUS.md](PROJECT_STATUS.md) | **Truthful implementation state** — done / partial / unstable |

---

## Core references

| Document | Purpose |
|----------|---------|
| [VOID Design Philosophy](VOID_DESIGN_PHILOSOPHY.md) | **Canonical game-feel gate** (movement, void, combat) |
| [PROTOTYPE.md](PROTOTYPE.md) | Deep implementation detail (arenas, weapons, passes) |
| [CODEBASE_MAP.md](CODEBASE_MAP.md) | Systems, flows, dependencies, file ownership |
| [TECHNICAL_AUDIT.md](TECHNICAL_AUDIT.md) | Maintainability, bugs, coupling (T-001…) |
| [VOID Prototype Audit](VOID_PROTOTYPE_AUDIT.md) | Design-gap audit (movement, lighting, enemies) |

---

## Gladiator Chamber

| Document | Purpose |
|----------|---------|
| [GLADIATOR_CHAMBER.md](GLADIATOR_CHAMBER.md) | Chamber implementation (zones, interact, test) |
| [VOID_GLADIATOR_CHAMBER.md](VOID_GLADIATOR_CHAMBER.md) | Design spec |
| [VOID_GLADIATOR_CHAMBER_LAYOUT.md](VOID_GLADIATOR_CHAMBER_LAYOUT.md) | Layout reference |
| [VOID_GLADIATOR_LOADOUT.md](VOID_GLADIATOR_LOADOUT.md) | Loadout design |
| [VOID_RETURN_LOOP.md](VOID_RETURN_LOOP.md) | Return mood |
| [VOID_GLADIATOR_LOOP.md](VOID_GLADIATOR_LOOP.md) | Macro loop |

---

## Art & mood

- [Art Direction](art/ART_DIRECTION.md) — perceptual horror targets
- [Visual Rules](art/VISUAL_RULES.md) — do / don't quick reference
- [Moodboard](art/MOODBOARD.md)
- [ART_DIRECTION_VOID.md](ART_DIRECTION_VOID.md) — prototype art index

---

## Production & legacy

| Document | Purpose |
|----------|---------|
| [Project Bible](project_bible/PROJECT_BIBLE.md) | Vision, pillars |
| [Tech Architecture](tech/ARCHITECTURE.md) | Legacy architecture notes |
| [Gameplay](gameplay/GAMEPLAY.md) | Loop summary |
| [Audio](audio/AUDIO.md) | Audio design |
| [Level Design](levels/LEVEL_DESIGN.md) | Arena design notes |
| [Roadmap](roadmap/ROADMAP.md) | Long-term roadmap |
| [PROJECT_STATUS_REPORT.md](PROJECT_STATUS_REPORT.md) | Extended historical status (may drift — prefer [PROJECT_STATUS.md](PROJECT_STATUS.md)) |

---

## Core identity (summary)

**The void is the enemy.** Horror comes from space, depth, and perception — not only from opponents.

> “I survived a place humans should not enter.”

**Current loop:** Gladiator Chamber prep → Terminal → arena match to 5 → return chamber (win/loss mood).

**Known open issues:** chamber visual composition polish; enemy aim/animation polish; chamber generation clutter history (mitigated).
