# VOID — Task Backlog (Reverse SDD)

Prioritized work derived from code state, `TECHNICAL_AUDIT.md`, `VOID_PROTOTYPE_AUDIT.md`, and known open issues.

**Legend:** ✅ done in prototype · 🟡 partial · 🔴 open · 📋 planned

---

## P0 — Critical bugs

| ID | Task | Status | Notes |
|----|------|--------|-------|
| T-001 | Gate `PushHitResolver.apply_damage_to_target` on `GameManager.is_fighting()` | 🔴 | Lingering projectiles can damage outside FIGHTING (audit P0) |
| T-001b | Optional guard in `CombatStats.apply_damage` | 🔴 | Defense in depth |
| — | Verify no double-scoring on simultaneous void + health death | 🟡 | `_handling_round_end` exists; needs regression test |
| — | Chamber `DistantArchitecture`: confirm `HangingSpan` never re-enters playable volume | ✅ | Sanitized in `gladiator_chamber.gd` |

---

## P1 — Chamber polish

| Task | Status | Notes |
|------|--------|-------|
| Visual composition pass (zone readability from spawn) | 🟡 | Alcoves/command/void/progression added; **still needs final polish** |
| Procedural clutter / slab prevention | 🟡 | Cleanup pass + span clamp; history of crossing beams |
| Reduce debug mesh logging noise | ✅ | `CHAMBER_MESH_DEBUG = false` default |
| Authoritative chamber art pass (materials/meshes) | 📋 | Still primitive boxes |
| Progression wall → real unlock hooks | 📋 | Placeholders only |
| Armor/helmet apply to arena visuals or stats | 📋 | Save only today |
| Return mood tuning vs void window | 🟡 | Works; needs playtest |

---

## P1 — Enemy visual polish

| Task | Status | Notes |
|------|--------|-------|
| **Enemy aim/animation final polish** | 🔴 | `EnemyLookAtController` + procedural animator vs `WeaponMount` |
| Silhouette read at 15–25 m | 🟡 | Primitive humanoid; orange emissive flattens depth |
| Enemy muzzle flash / tracer at fire | 🔴 | Player has VFX; enemy impact moment weak at distance |
| Dim eye emissive with distance | 📋 | Prototype audit |
| Mount reset on all death/respawn paths | 🟡 | Verify all paths |
| Debug AI flags off in shipping scenes | 🟡 | `debug_enemy_*` exports exist |

---

## P1 — Combat feel

| Task | Status | Notes |
|------|--------|-------|
| `enemy_skill_level` playtest bands (0.55–0.85) | 🟡 | Export exists; needs tuning |
| Arena deck lighting — stronger key, less even fill | 🟡 | Philosophy vs current even-lit deck |
| Edge read at sprint speed | 🟡 | Fall-zone markers exist |
| Sensitivity / settings menu | 📋 | No UI |
| Shot direction feedback on crosshair | 📋 | Stabilized crosshair only |

---

## P2 — Audio

| Task | Status | Notes |
|------|--------|-------|
| Replace procedural placeholders with authored `.ogg` | 🟡 | See `audio/README_REPLACE_ASSETS.md` |
| Dedicated audio buses (combat / void / UI) | 📋 | Master only |
| Round-start void ambience reliability | 🟡 | `VoidAudio` autoload |
| Chamber-specific ambience bed | 📋 | Minimal dust/atmosphere only |
| Gore timeline mix polish | 🟡 | VOID_GORE hooks exist |

---

## P2 — Art / model pipeline

| Task | Status | Notes |
|------|--------|-------|
| Author player/enemy meshes (replace boxes) | 📋 | |
| Author weapon viewmodels + enemy weapon meshes | 🟡 | Distinct boxes + tints |
| Chamber procedural → scene-authored modules | 📋 | |
| Arena landmark / megastructure authored assets | 🟡 | Box silhouettes |
| Material library (concrete, steel, void glass) | 🟡 | Code-generated StandardMaterial3D |
| Align with [art/ART_DIRECTION.md](../art/ART_DIRECTION.md) | 🟡 | Ongoing |

---

## P3 — Multiplayer / future

| Task | Status | Notes |
|------|--------|-------|
| Netcode / 1v1 sync | 📋 | Not started |
| Backend loadout / accounts | 📋 | Local `ConfigFile` only |
| Multiple AI opponents / horde | 📋 | |
| Campaign / catacomb progression | 📋 | Progression wall foreshadow only |
| Vertical arena shafts (gameplay) | 📋 | Visual ramps only in chamber pass |
| Spectator / replay | 📋 | |

---

## P2 — Engineering debt (from technical audit)

| ID | Task | Priority |
|----|------|----------|
| T-002 | Split `arena_opponent.gd` god object | P2 |
| T-003 | Split `push_hit_resolver.gd` | P2 |
| T-004 | Extract player void/death from `player.gd` | P2 |
| T-005 | Reduce `get_first_node_in_group` + `has_method` coupling | P2 |
| T-006 | Public `ArenaRouteValidator` API | P2 |
| T-007 | User-visible arena gen failure feedback | P2 |

---

## Recommended next milestone

**Milestone: "Readable Ritual Slice"**

1. Close **T-001** combat gate (P0).
2. Chamber **composition lock** — one art pass, no new procedural systems (P1).
3. Enemy **aim + fire read** pass — mount alignment, muzzle/tracer (P1).
4. One **playtest tuning** session for AI skill + arena lighting (P1).

**Exit criteria:** F5 chamber → terminal → full match to 5 → return mood; no crossing geometry; enemy readable at mid range; no damage during countdown.

---

## Related docs

- [PROJECT_STATUS.md](../PROJECT_STATUS.md)
- [TECHNICAL_AUDIT.md](../TECHNICAL_AUDIT.md)
- [VOID_PROTOTYPE_AUDIT.md](../VOID_PROTOTYPE_AUDIT.md)
