# VOID / Neon Catacombs — Project Status

**Reverse SDD snapshot** — code is source of truth.  
**Engine:** Godot 4.6 · **Physics:** Jolt · **Date:** May 2026

Canonical spec/design: [specs/VOID_SPEC.md](specs/VOID_SPEC.md) · [design/VOID_DESIGN.md](design/VOID_DESIGN.md) · [tasks/VOID_TASKS.md](tasks/VOID_TASKS.md)

---

## Executive summary

Playable **vertical slice**: Gladiator Chamber hub → 1v1 arena duel to **5 points** → return with mood. Procedural arenas (5 templates + maze + destructible cover), full weapon trio, shield/health combat, void ring-out with **VOID_GORE** cinematic, AI opponent with cover/edge tactics.

**Not production-ready:** chamber visuals, enemy animation polish, combat round-state edge case, authored art/audio.

---

## Implemented ✅

| Area | Detail |
|------|--------|
| **Game loop** | Chamber → terminal → `arena_match.tscn` → return (~2.8 s) via `GameFlow` |
| **Loadout** | Weapon/armor/helmet save (`GladiatorLoadout`); weapon applies in arena |
| **Match rules** | First to 5; countdown; round reset; random arena (no back-to-back repeat) |
| **Combat** | 100 shield + 100 health; shield-first damage; 3 weapons with shared defs |
| **Shield break** | Single pipeline via `CombatFeedback` + VFX + SFX |
| **Void deaths** | Ring-out at Y < -20; VOID_GORE ~3.2 s; void gas/fog/audio |
| **Health deaths** | Corpse, gib, dismemberment by damage profile |
| **Arena gen** | Maze, destructible cover, route validation, 5 templates, chamber/megastructure passes |
| **AI** | 7-state machine, parity locomotion, cover, edge, weapon shuffle |
| **Player feel** | GladiatorLocomotion, raw mouse look, camera feel, FOV, dodge |
| **Destruction** | Destructible cover + railgun perforation |
| **HUD** | Arena UI, crosshair, chamber HUD |
| **Audio/VFX autoloads** | `VoidAudio`, `CombatVfxDirector` with procedural fallbacks |
| **Chamber hub** | Procedural zones, 9 interact pedestals, terminal, return mood |
| **Distant arch fix** | `HangingSpan` removed from chamber instance |

---

## Partially implemented 🟡

| Area | Gap |
|------|-----|
| **Gladiator Chamber** | Functional zones + alcoves exist; **visual composition still needs polish**; procedural box art |
| **Chamber generation** | Cleanup/clamp passes added after **slab/clutter incidents** — monitor regressions |
| **Enemy visuals** | Readable primitives; **aim/animation needs final polish** |
| **Armor / helmet** | Saved in chamber; no arena gameplay effect |
| **Progression wall** | Placeholder silhouettes/slots only |
| **Audio** | Hooked; mostly procedural placeholders |
| **VFX** | Procedural meshes/particles; swap-ready hooks |
| **Lighting** | Zone lights in chamber + arena; deck can read even-lit |
| **Docs** | Legacy docs (`PROTOTYPE.md`, `PROJECT_STATUS_REPORT.md`) coexist with SDD set |

---

## Unstable ⚠️

| Issue | Risk |
|-------|------|
| **T-001** Damage outside `FIGHTING` via resolver path | Rare countdown/round-over damage |
| **Arena gen fallback** | After 6 failures → Toxic Bridge; errors console-only |
| **`arena_opponent.gd` size** | High regression risk on AI edits |
| **`push_hit_resolver.gd` size** | High regression risk on weapon edits |
| **Group/`has_method` lookups** | Runtime failures on renames |
| **Chamber distant arch** | Arena/main still use full `void_distant_architecture.tscn` (chamber sanitized only) |

---

## Known bugs / issues

| Issue | Status |
|-------|--------|
| Gladiator Chamber visual composition polish | Open (P1) |
| Enemy visual aim/animation final polish | Open (P1) |
| Chamber procedural clutter / horizontal slab history | Mitigated; watch for new spans |
| `HangingSpan` crossing chamber | Fixed in chamber build |
| Combat damage during non-FIGHTING states | Open (T-001, P0) |
| Armor/helmet selection cosmetic only | By design (MVP) |

---

## Not implemented 📋

- Multiplayer / netcode
- Backend / cloud save
- Armor/helmet stat modifiers
- Progression unlock gameplay
- Settings menu
- Authored character/weapon models
- Campaign structure

---

## Milestone map

| Milestone | State |
|-----------|-------|
| Core 1v1 arena prototype | ✅ Done |
| Procedural maze arenas | ✅ Done |
| VOID_GORE void deaths | ✅ Done |
| Gladiator Chamber hub | 🟡 Functional; polish open |
| SDD documentation set | ✅ This pass |
| Readable ritual slice (next) | 🔴 See [VOID_TASKS.md](tasks/VOID_TASKS.md) |
| Production art/audio | 📋 Future |

---

## Next recommended milestone

**"Readable Ritual Slice"** (2–3 weeks focus):

1. Fix **T-001** combat round gate.
2. Lock chamber layout — composition polish only, no new prop systems.
3. Enemy mount aim + fire feedback pass.
4. One AI/lighting playtest pass.

---

## Key paths

| What | Path |
|------|------|
| Main scene | `scenes/chamber/gladiator_chamber.tscn` |
| Arena duel | `scenes/arena/arena_match.tscn` |
| Chamber builder | `scripts/chamber/gladiator_chamber.gd` |
| Match logic | `scripts/game_manager.gd` |
| Arena gen | `scripts/arena/arena_generator.gd` |
| Balance | `scripts/game_balance.gd` |

---

## Related legacy docs

- [PROJECT_STATUS_REPORT.md](PROJECT_STATUS_REPORT.md) — longer historical report (may drift)
- [PROTOTYPE.md](PROTOTYPE.md) — deep implementation reference
- [TECHNICAL_AUDIT.md](TECHNICAL_AUDIT.md) — engineering debt register
