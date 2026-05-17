# Tech Architecture

Godot **4.6** project. This document describes intended structure; see `docs/PROTOTYPE.md` for file-level prototype detail.

---

## Godot Project Structure

```
neon-catacombs/
├── scenes/           # Main scene, arena, weapons, effects, environment
├── scripts/          # Gameplay, weapons, enemies, effects, environment
├── docs/             # Design documentation (this tree)
└── project.godot
```

---

## Scene Organization

| Area | Scenes |
|------|--------|
| **Main** | `scenes/main.tscn` — arena, player, UI, game manager |
| **Enemy** | `scenes/enemies/arena_opponent.tscn` |
| **Weapons** | `scenes/weapons/*` projectiles, weapon manager |
| **Effects** | `scenes/effects/*` corpse, void death, gore, corruption |
| **Environment** | `scenes/environment/void_atmosphere.tscn`, observers |

---

## Script Organization

| Folder | Purpose |
|--------|---------|
| `scripts/` | Player, game manager, arena UI, combat stats |
| `scripts/weapons/` | Weapon defs, firing, hit resolver, projectiles |
| `scripts/enemies/` | Arena opponent AI, enemy weapons |
| `scripts/effects/` | Corpse, void death, gore sequence |
| `scripts/environment/` | Atmosphere, observers, audio placeholders |
| `scripts/game_balance.gd` | Void style, cinematic timing constants |

---

## Managers

- **GameManager** — scoring, round state, countdown, void death sequences, cleanup
- **WeaponManager** (player) / **EnemyWeaponManager** — firing via shared `WeaponFiring`
- **CombatStats** — shield/health node on fighters

---

## Signals

GameManager signals (examples):

- `score_changed`
- `countdown_text_changed` / `countdown_hidden`
- `death_message_changed` / `death_message_hidden`
- `void_overlay_changed`
- `match_over`

---

## Naming Conventions

- **snake_case** for scripts, files, and groups (`arena_opponent`, `void_effect`)
- **PascalCase** for class_name (`CombatStats`, `VoidGoreSequence`)
- Groups: `player`, `game_manager`, `arena_opponent`, `projectile`, `corpse`, `void_effect`, `gore_chunk`
- Collision: corpses/effects on layer **8**, weapons ignore via masks

---

## Performance Notes

- Prefer CPUParticles for prototype VFX; batch review for GPU particles later
- Clear groups at round start (projectiles, corpses, void effects, gore chunks)
- Avoid unbounded spawned nodes — lifetimes on chunks and effects
- RigidBody enemies: axis lock while alive; corpses free-rotate

---

## Future Systems

- [ ] Real audio bus (replace `void_audio.gd` prints)
- [ ] Save / meta progression
- [ ] Multiple arenas / level streaming
- [ ] Online multiplayer
- [ ] Narrative triggers and environmental lore volumes
- [ ] Player-facing settings for void death style and accessibility
