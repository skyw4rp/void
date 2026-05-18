# VOID — Gladiator Chamber

**What this is:** The player’s **physical home** inside the Arena system — a small brutalist volume suspended over the void. You walk it in first person. It is **not** a menu screen.

**What this is not:** A town, a ship bridge, or an economy hub. MVP stays **four spaces**, one loop, no extra systems.

**Related:** [VOID_GLADIATOR_LOOP.md](VOID_GLADIATOR_LOOP.md) (progression + resources) · [VOID_DESIGN_PHILOSOPHY.md](VOID_DESIGN_PHILOSOPHY.md) · [art/ART_DIRECTION.md](art/ART_DIRECTION.md)

**Status:** Design spec — **not implemented** (prototype loads arena directly).

---

## 1. Purpose

The Gladiator Chamber is where the player **lives between duels** — the only place that is safe, familiar, and theirs within an indifferent megastructure.

**You always return here after a match.** Rewards are acknowledged (brief UI or terminal readout), then the player is **back in the room** — not dumped into a abstract flow chart.

### Chamber loop (MVP)

```
Spawn ──► Prepare ──► Queue ──► [Arena PvP] ──► Return ──► Spawn
```

| Phase | Where | What happens |
|-------|--------|----------------|
| **Spawn** | Chamber center / arrival slab | Fade in after match load or first session. Foot on metal. Void audible. |
| **Prepare** | Armory + Inventory | Weapon, module, consumable — physical stations, not a loadout grid. |
| **Queue** | Arena Terminal | Confirm loadout lock-in. Ranked or unranked 1v1. Wait in chamber (no separate lobby scene). |
| **Return** | Same chamber | Win or loss: re-enter at spawn. Terminal may flash last result; world unchanged except player state. |

**Design intent:** Short prep, long memory. The chamber should feel **smaller** than the arenas it serves — claustrophobic safety before open combat.

---

## 2. Physical layout

### Scale (MVP)

- **One room** (~25–40 m walkable footprint). No corridors maze, no second floor, no shops street.
- **Ceiling** low enough to feel crushed; **one** tall fracture or bay for scale contrast only.
- **Floor** continuous poured slab with drain channels — no interior pits (void is **outside** the shell).

### Placement (suggested plan)

```
                    [ OBSERVATORY ]
                    void glass / rail
                          │
    [ INVENTORY ] ── central slab ── [ ARMORY ]
         alcove          spawn          racks
                          │
                  [ ARENA TERMINAL ]
                    sunken dais
                          │
                    ▼ void drop ▼
              (not walkable — visual only)
```

- **Spawn:** Center — player faces Terminal or void slit on return.
- **Armory:** One wall — weapon racks, module bench (tactile).
- **Inventory:** Opposite alcove — sealed lockers / fragment crate (interact to manage consumables).
- **Arena Terminal:** Sunken dais toward void side — implies “step toward the drop to fight.”
- **Observatory:** Void-facing edge — railing or fractured viewport; largest negative space in the room.

### Material & light

| Element | Read |
|---------|------|
| Structure | Brutalist concrete, oxidized steel ribs, weld seams, water stains |
| Light | One cold key (terminal + armory), deep shadow elsewhere, **no** even fill |
| Void | Black-green gradient below; distant fog; optional far geometry |
| Audio | Low structural hum, void wind at Observatory, terminal chirp idle |

**Suspended:** Visible cables, anchor bolts, or cantilever ribs — the chamber **hangs**. No ground planet, no “floor of the world.”

---

## 3. Armory

**Role:** Loadout identity before queue. **Physical interaction preferred** — reach, grab, socket, holster.

### Functions (MVP)

| Function | Physical read | Interaction |
|----------|---------------|-------------|
| **Weapon select** | Three wall racks or cradle mounts (railgun / shotgun / bazooka silhouettes) | Take weapon → carries to body / preview mount |
| **Module slot** | Bench with **one** open socket + dim Resonance-lit slots (locked = unpurchased) | Insert module chip / slab into socket; audible click |
| **Consumable slot** | Small tray beside bench (links to Inventory stock) | Place **one** consumable into belt case or hip slot |

**Not in Armory MVP:** stat trees, crafting, more than one module socket, weapon skins shop.

### UX rules

- Silhouette and sound sell choice; numbers are secondary labels on racks.
- Last loadout persists on racks (weapon returned to mount when unequipped).
- Changing loadout after Terminal lock-in is **blocked** (terminal light red until match ends).

---

## 4. Arena Terminal

**Role:** The only door to PvP. A fixed machine — altar to the Arena system, not a floating UI.

### Queue (MVP)

- **1v1 ranked** or **1v1 unranked** (same combat; ranked affects Prestige only — see [VOID_GLADIATOR_LOOP.md](VOID_GLADIATOR_LOOP.md)).
- Confirm → loadout lock → queue timer / match found → fade to arena (no separate lobby level).

### Terminal view (diegetic screen or projected slab)

| Panel | Content |
|-------|---------|
| **Rank** | Current tier / division (ranked) or “Unranked” |
| **Recent matches** | Last **5**: W/L, void vs kill icon, opponent tag |
| **Prestige** | Slow reputation bar or title crest — cosmetic signal only |

**While queued:** Player remains in chamber — can walk Observatory or recheck Armory read-only. Cancel queue at Terminal only.

**No gameplay in Terminal:** No shop, no chat, no mission board in MVP.

---

## 5. Observatory

**Role:** Pure atmosphere. **No gameplay function in MVP.**

### What the player sees

| Layer | Description |
|-------|-------------|
| **Void** | Infinite drop, toxic haze bands (align with arena void read) |
| **Distant arenas** | Far suspended decks — faint lights, occasional muzzle flash or void burst |
| **Colossal structures** | Towers, broken rings, chains — reuse distant-arch language from combat arenas |
| **Other chambers** | Sparse lit windows or sibling pods on cables — implies many gladiators, not alone in universe |

### Player experience

- Wind, metal groan, sub-bass void tone.
- Optional: static counter “**N** duels active” (flavor only; not spectating).
- No interactables except lean rail / look — no telescopes, no bets, no quests.

**Why it exists:** Remind the player the void and the system are larger than one room. Pressure before queue, humility after return.

---

## 6. Environmental storytelling

**No NPCs. No exposition dumps. No quest giver.**

History and dread come from **place**:

| Channel | Examples (MVP) |
|---------|----------------|
| **Architecture** | Repaired blast scarring on slab; older bolt pattern under newer plates; Arena System stencil worn off wall |
| **Audio** | Distant impact thuds; cable stress; periodic void inhale under Observatory |
| **Objects** | Empty weapon cradles, scratched tally marks near Terminal, sealed maintenance hatch, frozen condensation |
| **Scale** | Low ceiling vs void yawning outside — body small, structure indifferent |

**Tone:** The chamber was here before the player and will remain after. The player is a **tenant** of the Arena system, not its master.

**Avoid:** Lore tablets, voice-over tours, friendly robots, bright signage, clean sci-fi panels ([VOID_DESIGN_PHILOSOPHY.md](VOID_DESIGN_PHILOSOPHY.md)).

---

## 7. Future hooks

**Do not implement in MVP.** Physical or systemic placeholders only — chamber layout must not depend on them.

| Hook | Chamber impact | Deferred because |
|------|----------------|------------------|
| **Market** | Vendor alcove off Inventory | Economy expansion |
| **Social hub** | Seating / other players visible | Networking + space |
| **Factions** | Banners, locked doors | Meta progression |
| **Spectating** | Observatory screens live-feed duels | Streaming + UI |
| **Expeditions** | Second Terminal mode — PvE drop | Different pillar (roguelite) |

**MVP guardrail:** If a feature needs a new room, NPC, or currency sink, it waits. Expand **Terminal** or **Armory** diegetically before adding a fifth zone.

---

## MVP build checklist (content)

- [ ] Walkable single chamber scene, FPS controller, no combat
- [ ] Four labeled zones (Armory, Terminal, Inventory, Observatory)
- [ ] Armory: weapon + module + consumable physical flow
- [ ] Terminal: queue + rank / recent / prestige readout
- [ ] Return spawn after match hooks to same scene
- [ ] Void vista + distant props (low cost, fogged)
- [ ] No market, social, factions, spectate, expeditions

---

## Related docs

- [VOID_GLADIATOR_LOOP.md](VOID_GLADIATOR_LOOP.md) — resources, prep lock-in, rewards
- [PROTOTYPE.md](PROTOTYPE.md) — arena combat (downstream of queue)
- [art/MOODBOARD.md](art/MOODBOARD.md) — chamber opens to void on one side

*Documentation only.*
