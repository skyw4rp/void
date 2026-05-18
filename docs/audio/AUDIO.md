# Audio

## Audio Identity

VOID sound is **sparse, deep, and sourceless**. The abyss should feel like it has acoustics that do not match the visible geometry — long tail, rare events, uncomfortable silence.

---

## Void Ambience

- Low **drone** (continuous but subtle)
- **Wind** without visible cause
- Metallic **resonance** from bridge structure
- Rare **rumbles** from below
- Implementation: `VoidAudio` autoload (`scripts/environment/void_audio.gd`) — procedural loop + one-shots; optional OGG override paths in [../audio/README_REPLACE_ASSETS.md](../audio/README_REPLACE_ASSETS.md)

---

## Combat Audio

- Weapon shots: industrial, punchy, not sci-fi arcade
- Explosion: heavy thump + decay into void reverb
- Shield hit vs health hit distinction (future)
- Knockback: light impact cues optional

---

## Enemy Audio

- Footsteps on metal (when moving)
- AI weapon same family as player
- Void death: rupture, burst — never comedic

---

## Music Direction

- **Minimal** score; long stretches without melody
- Tension through **texture** not busy orchestration
- Combat rounds may add low pulse; void falls may drop music entirely
- Avoid heroic triumph loops during pit deaths

---

## Silence Rules

- Silence is **allowed** and often stronger than SFX
- **Never overfill** the mix — void horror needs space
- After void absorption: **~38% chance of no impact sound** (`VOID_SILENT_ABSORPTION_CHANCE`)
- Unknown destination (no impact) = stronger fear than a cartoon splash
- Countdown can be nearly dry except tick/FIGHT
- Distant flash may have **no** paired loud SFX — doubt is the point

---

## Implementation Notes (P0)

| System | Detail |
|--------|--------|
| `VoidAudio` autoload | Ambience + proximity loops, danger pulses, void one-shots, 3D combat pool |
| `CombatAudio` | `weapon_manager`, `enemy_weapon_manager`, `push_hit_resolver` hooks |
| `AudioStreamFactory` | Runtime WAV placeholders; auto-loads `res://audio/**` if present |
| Proximity | `VoidGasController` → depth + arena edge distance each frame |

**Next step:** Author OGG assets (see [README_REPLACE_ASSETS.md](../../audio/README_REPLACE_ASSETS.md)); add `Void` / `Combat` audio buses; footstep metal (P1).

---

## Related

- [Art Direction — moodboard audio/visual](../art/MOODBOARD.md)
- [Gameplay — void mechanics](GAMEPLAY.md)
