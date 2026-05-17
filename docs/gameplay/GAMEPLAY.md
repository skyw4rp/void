# Gameplay

## Core Loop

1. **Countdown** — 3, 2, 1, FIGHT (frozen)
2. **Fight** — knock opponent into void or deplete health through shield
3. **Point scored** — void cinematic or kill delay, then respawn
4. **Repeat** until one side reaches **5 points**
5. **Match over** — win/lose screen

Win conditions:

- Opponent falls below **void Y** (ring-out)
- Opponent **health** reaches 0 after shield break

---

## Movement

- First-person **WASD**, mouse look, jump, sprint
- CharacterBody3D on bridge deck
- Movement disabled during countdown and void death sequences
- Void fall: camera continues with body; instability phase before freefall (VOID_GORE)

---

## Combat

| Weapon | Role |
|--------|------|
| **Pistol** | Fast, moderate push and damage |
| **Shotgun** | Spread pellets, strong close knockback |
| **Bazooka** | Direct hit + explosion; ring-out tool |

- Damage hits **shield first**, then health
- Knockback separate from damage; airborne caps prevent sky launches
- No self-damage from own projectiles

---

## Void Mechanics

- **Void Y threshold** — crossing it starts void death (not instant score in VOID_GORE)
- Pit has **no visible floor** in current art pass
- Void atmosphere: fog, particles, observers
- Post-death: delayed impact sound **or silence**; rare distant abyss flash

---

## Enemy Behavior

- Single **AI opponent** on bridge
- Weapon kit mirrors player
- Edge awareness and ring-out tactics
- More evasive when own shield/health low
- States: attacking, recovering near rim

---

## Death States

| Type | Flow |
|------|------|
| **Void death** | Fall → cinematic (VOID_GORE) → score → countdown |
| **Health death** | Corpse launch → delay → score → countdown |
| **Void fall (player)** | FOV widen, shake, cold overlay |

Void death styles configurable: DISINTEGRATE, EXPLODE, GORE_PLACEHOLDER, VOID_GORE.

---

## Player Feedback

- HUD: score, HP, shield, weapon
- Void messages: `PLAYER LOST TO THE VOID` / `ENEMY LOST TO THE VOID`
- Debug prints for knockback, void audio placeholders
- Death corpuses and gore chunks (stylized)

---

## Balance Notes

- Tune in `scripts/game_balance.gd` and `scripts/weapons/weapon_defs.gd`
- First to **5** wins
- Shield/health default **100 / 100**
- See legacy `docs/PROTOTYPE.md` for current numeric tables
