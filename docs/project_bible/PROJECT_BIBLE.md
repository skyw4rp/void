# VOID — Project Bible

## Vision

VOID is a dark psychological first-person experience set in hostile industrial ruins suspended over an infinite abyss. The player survives arenas where **the void itself** is the true antagonist — not only the enemies on the bridge.

The game sells **fear of falling**, **loss of control**, and **cosmic loneliness** before it sells action.

---

## Core Pillars

1. **The void is the enemy** — depth, darkness, and disappearance matter as much as combat.
2. **Perceptual horror** — doubt, silhouettes, impossible space; not constant monster reveals.
3. **Industrial isolation** — Quake-like mood: steel, shadow, sparse light, long silence.
4. **Knock-off danger** — ring-outs and pit deaths are core fantasy, not side gimmicks.
5. **Readable combat** — shield/health, knockback, and weapons stay fair inside horror framing.

---

## Player Fantasy

> “I survived a place humans should not enter.”

The player should feel:

- Small against enormous emptiness
- One misstep from erasure
- Watched by something in the dark below
- Competent in combat but never safe in space

---

## Design Rules

- Darkness **hides** information; do not flood scenes with light.
- **Empty space is content** — kenophobia is intentional.
- **Silhouette > fully revealed monster** — peripheral dread beats jumpscares.
- **Isolation > jumpscares** — tension and curiosity over shock spam.
- **Falling must feel dangerous** — delay, silence, and unknown destination.
- The world feels **hostile, ancient, and impossible**.
- Score and respawn are clean; horror lives in **presentation**, not unfair rules.

---

## Inspirations

- **Quake** — dark industrial mood
- **Unreal / liminal spaces**
- **Infinite abyss** concepts
- **Acrophobia / void anxiety**
- **Cosmic loneliness**
- **Perceptual horror**

| Source | What we take |
|--------|----------------|
| **Quake** | Industrial darkness, hard shadows, arena clarity |
| **Unreal / liminal** | Wrong scale, floating architecture |
| **Infinite abyss** | No visible floor, vertical anxiety |
| **Cosmic loneliness** | Isolation, sparse audio |
| **Perceptual horror** | Silhouettes, doubt, withheld answers |
| **Arena pit stages** | Ring-out stakes, readable 1v1 |

Full perceptual targets: [Art Direction](../art/ART_DIRECTION.md#psychological-targets)

---

## Forbidden Directions

- Bright, saturated arcade palettes
- Cartoon gore or comedy horror
- Constant loud music and SFX (no silence)
- Fully lit arenas that remove pit threat
- Over-cluttered props that kill emptiness
- Jumpscare-only design without spatial dread
- Explaining the void completely in lore UI

---

## Current Status

| Area | State |
|------|--------|
| **Engine** | Godot 4.6 |
| **Mode** | 1v1 arena prototype (Neon Catacombs bridge) |
| **Combat** | Pistol / shotgun / bazooka; shield + health |
| **Scoring** | Void ring-out or kill; first to 5 |
| **Void deaths** | VOID_GORE cinematic pipeline (fall → corruption → breakup → burst) |
| **Atmosphere** | Void atmosphere, observers, fog layers |
| **Docs** | Structured design folder (this tree) |
| **Legacy** | `docs/PROTOTYPE.md` — implementation notes for current build |

---

## Related Documents

- [Documentation index](../README.md)
- [Art Direction — psychological targets](../art/ART_DIRECTION.md)
- [Visual Rules](../art/VISUAL_RULES.md)
- [Gameplay](../gameplay/GAMEPLAY.md)
- [Audio](../audio/AUDIO.md)
- [Tech Architecture](../tech/ARCHITECTURE.md)
- [Void implementation index](../ART_DIRECTION_VOID.md)
- [Roadmap](../roadmap/ROADMAP.md)
