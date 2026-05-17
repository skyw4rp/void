# Gameplay

## Core loop

1. **Countdown** — 3, 2, 1, FIGHT (frozen)
2. **Fight** — knock opponent into toxic void or deplete shield + health
3. **Point scored** — void cinematic or kill delay, then respawn on a **new compact arena**
4. **Repeat** until one side reaches **5 points**
5. **Match over** — win/lose screen

Win conditions:

- Opponent falls below **void Y** (ring-out into infinite gas)
- Opponent **health** reaches 0 after shield break

---

## Movement

- First-person **WASD**, mouse look, jump, sprint
- CharacterBody3D on arena slabs
- Movement disabled during countdown and void death sequences
- Void fall: camera continues; instability phase before freefall (VOID_GORE)

---

## Combat

| Weapon | Role in compact arenas |
|--------|------------------------|
| **Railgun** | Long lanes when line of sight is clear |
| **Shotgun** | Corners, close gaps, broken LOS |
| **Bazooka** | Ring-out through gaps, splash behind cover |

- Damage hits **shield first**, then health
- Knockback separate from damage; airborne caps prevent sky launches
- Inner walls + **outer perimeter** (`arena_wall` / `arena_perimeter`) and destructible cover block shots
- ~32% of outer panels can be **destroyed** to open new lanes

---

## Void mechanics

- **Void Y threshold** — crossing starts void death (VOID_GORE default)
- Below arenas: **toxic gas abyss** — not a visible floor
- Layered fog, animated gas layers, drift particles
- Post-death: delayed impact sound or silence; rare distant flash

---

## Enemy behavior

- Single **AI opponent** with same weapon kit
- **Cover state** — repositions behind walls when LOS blocked
- **Hole avoidance** — raycasts for floor before chasing; pulls back over gaps
- Edge awareness and ring-out tactics on compact bounds
- Railgun at distance with LOS; shotgun when flanking or cornered

---

## Death states

| Type | Flow |
|------|------|
| **Void death** | Fall → VOID_GORE cinematic (~3.2s) → score |
| **Health death** | Corpse or gib → delay → score |
| **Void fall (player)** | FOV widen, shake, toxic overlay |

---

## Design goals

- **Faster, denser** rounds than legacy open-bridge layout
- **Tactical** movement — cover, peek, gap control
- **Intentional** ring-outs — gaps are lethal by design
- **Quake 3 void** mood — industrial ruins over endless corrupted gas
