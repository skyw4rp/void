# VOID — Arena Transitions (MVP)

**Goal:** Define how players move between the [Gladiator Chamber](VOID_GLADIATOR_CHAMBER.md) and arena combat — **ritualistic and physical**, never “menu teleport” or loading-screen fantasy.

**Not in scope:** Balance, matchmaking logic, networking implementation.

**Related:** [VOID_GLADIATOR_CHAMBER_LAYOUT.md](VOID_GLADIATOR_CHAMBER_LAYOUT.md) (Terminal placement) · [VOID_RETURN_LOOP.md](VOID_RETURN_LOOP.md) (win/loss mood) · [VOID_GLADIATOR_LOOP.md](VOID_GLADIATOR_LOOP.md) (queue + rewards) · [PROTOTYPE.md](PROTOTYPE.md) (current arena spawn / countdown)

**Status:** Design spec — **not implemented**. Prototype uses scene load / fade only.

---

## Principles (MVP)

| Do | Don’t |
|----|-------|
| Short in-world travel (**3–8 s**) | Full-screen “LOADING ARENA” art |
| Body stays continuous (walk, stand, ride) | Pop to black → instant arena coords |
| Diegetic cause (Terminal, shaft, platform) | Abstract UI teleport button |
| Same chamber while **queued** | Separate lobby level |
| Audio + light tell the story | Modal popups on transition |

**One MVP departure type** for the whole game (pick below and commit). Arrival may pair with it symmetrically.

---

## 1. Entering combat

### Before match found

Player path ([VOID_GLADIATOR_CHAMBER_LAYOUT.md](VOID_GLADIATOR_CHAMBER_LAYOUT.md)):

```
Return → Prepare (Armory / Armor) → Arena Terminal → Queue (wait in chamber)
```

- Loadout **locked** at Terminal confirm ([VOID_GLADIATOR_LOADOUT.md](VOID_GLADIATOR_LOADOUT.md)).
- Player **walks freely** while queued — Observatory, racks read-only.

### When match found — environment reacts

The chamber answers **before** the player moves. They are **called**, not clicked.

| Channel | MVP reaction (0.5–2 s) |
|---------|-------------------------|
| **Lights** | Terminal key flares; Armory racks dim; Observatory rim pulse once |
| **Distant sound** | Far impact — muzzle thud or void crack from **distant arenas** |
| **Void resonance** | Sub-bass swell under floor; cables sing 1–2 s |
| **Terminal** | Console unlocks departure — glyph scroll, palm plate **active** |

**Player prompt (diegetic only):** Terminal slab text `MATCH READY` + physical interact (no fullscreen modal).

**Emotional read:** The system noticed you. The void already knows.

---

## 2. Arena departure (chamber → transit)

**Do not instantly teleport.** Player commits at Terminal → **short physical departure** (**3–8 s** total including handoff).

### MVP options (choose **one**)

| Type | Read | Duration | Notes |
|------|------|----------|-------|
| **Void corridor** *(recommended)* | Walk into light shaft south of Terminal; walls are ribs + fog | 4–6 s | Matches void mythology; camera forward drift |
| **Platform / lift** | Dais descends along cable into haze | 5–7 s | Strong “suspended” read |
| **Gate** | Bulkhead splits; beyond is white void noise | 3–5 s | Fastest; less travel, more threshold |
| **Light shaft** | Vertical column pull — player rises then flung outward | 6–8 s | Dramatic; use if arena spawn is “drop” |

**Recommended MVP pair:** **Void corridor** (departure) → **Arrival bridge / drop platform** (arena) — both void-adjacent, no separate tech fantasy.

### Departure beat (timeline)

```
0.0s  Terminal accept departure (player on dais)
0.5s  Lights narrow to shaft; chamber audio ducks
1.0s  Player moves into corridor / lift engages (input optional: forward only)
3.0s  Void hum peaks; distant arena wind forward
4.0s  Geometry handoff — chamber ends, transit ends
5.0s  Arrival begins (§3)
```

**Hard cut forbidden:** No 0-frame position snap from dais to arena. Minimum **1 s** of transitional space (corridor mesh or fog tube) even if reused asset.

**While in transit:** No loadout UI. Optional faint opponent silhouette (weapon + armor class) as shadow through fog — readable, not nameplate spam.

---

## 3. Arrival in arena

Spawn must feel **physical** — you **arrived**, you were **placed**.

### MVP arrival types (pair with §2)

| Arrival | Read | Tie to prototype |
|---------|------|------------------|
| **Drop platform** | Plate decelerates onto deck; clamp hiss | Matches `SpawnPads` raycast snap |
| **Elevator** | Side cage opens to arena edge | Good for perimeter spawns |
| **Arrival chamber** | 2 m airlock, door opens to deck | Extra 2 s; use if countdown needs enclosure |
| **Bridge** | Walk off short span onto pad | Best with void-corridor departure |

**Recommended MVP:** **Drop platform** or **bridge** → player feet on pad → **then** round countdown ([PROTOTYPE.md](PROTOTYPE.md): 3, 2, 1, FIGHT!) — countdown is arena-local, not chamber UI.

### Arrival beat

```
0.0s  Transit ends — wind, wide space
0.5s  Platform docks / bridge end
1.0s  Player control fully live (still frozen if pre-countdown)
1.0s  Opponent visible at far pad (silhouette)
2.0s  Countdown begins (diegetic horn or slab, not popup)
```

**No UI teleport:** Crosshair may fade in; no “YOU ARE HERE” banner.

**Arena gen:** Procedural layout already built during countdown — arrival platform exists first; deck may still assemble visually during 3-2-1 (acceptable if subtle).

---

## 4. Victory return (arena → chamber)

**Transition back:** **stable · clear · calm**

| Phase | Read |
|-------|------|
| **Exit arena** | Match win — brief hold on deck (1 s), not instant extract |
| **Transit** | Same void corridor **in reverse** — shorter (**3–5 s**) |
| **Chamber in** | Lights rise to **victory palette** ([VOID_RETURN_LOOP.md](VOID_RETURN_LOOP.md)) |
| **Observatory** | Visibility **increases** — more distant arenas lit, fog thinner |

**Spawn:** Return platform center — upright, not staggered.

**Rewards:** Terminal scroll + crate shimmer **after** feet on slab — no chest popup.

**Duration:** Victory transit may linger **+1–2 s** vs defeat (clarity moment) — still under **8 s** total.

---

## 5. Defeat return (arena → chamber)

**Transition:** **heavier · darker · shorter**

| Phase | Read |
|-------|------|
| **Exit arena** | Loss — void nearby or body collapse beat (0.5–1 s) |
| **Transit** | Corridor darker, void hum **louder**, less forward light |
| **Chamber in** | **Defeat palette** — dim key, heavy Observatory fog |
| **Recovery** | **Fast** — defeat mood **20–40 s** then neutral; no lockout |

**Spawn:** Return platform — optional slight stagger (cosmetic); **no** stat debuff.

**Observatory:** Reduced visibility vs victory — fog thick at glass.

**Design intent:** Acknowledge pain, return to agency quickly — [VOID_RETURN_LOOP.md](VOID_RETURN_LOOP.md).

---

## 6. Audio language

Single vocabulary across all transitions. Implement as layers, not one-shots only.

### Departure (chamber → arena)

| Layer | Character |
|-------|-----------|
| **Ritual** | Low choral tone or system chord — 1 per match, not spam |
| **Metal** | Dais clank, gate servo, cable tension |
| **Void hum** | Rising sub-bass; peaks at handoff |

### Arrival (transit → arena)

| Layer | Character |
|-------|-----------|
| **Impact** | Platform lock, boot on deck |
| **Space** | Open wind, far void — wider reverb than chamber |
| **Silence** | 0.3 s near-silent beat before countdown horn |

### Return — victory

| Layer | Character |
|-------|-----------|
| **Clarity** | High band filtered up; void wind **down**; Terminal soft chime |

### Return — defeat

| Layer | Character |
|-------|-----------|
| **Weight** | Low band holds; metal groan; shorter tail than victory |

**MVP rule:** No voiced announcer. Horn / slab clicks only.

**Chamber vs arena:** Chamber reverb **small** (2–4 s tail); arena **large** (6–10 s). Crossfade during transit.

---

## 7. Future hooks

**Do not implement in MVP.** Transit geometry must not depend on them.

| Hook | Idea | Why deferred |
|------|------|--------------|
| **Multiplayer hub** | Shared departure shaft with other players | Networking + social |
| **Spectator systems** | Branch transit to viewing rail | Extra mode + sync |
| **Factions** | Different corridor skins per faction | Meta + content pipeline |

**Socket (layout):** `TRANSIT_BRANCH_E` / `W` — sealed bulkhead in corridor mesh; inactive in MVP.

---

## MVP recommendation (single pipeline)

```
CHAMBER                          TRANSIT (4–6s)              ARENA
────────                         ─────────────               ─────
Terminal MATCH READY    →    Void corridor forward    →    Bridge to spawn pad
     ↓                              ↓                           ↓
Lights + void resonance        Hum + metal + ritual          Impact + silence
     ↓                              ↓                           ↓
Return (win/defeat)        ←    Reverse corridor        ←    Exit slab / void edge
```

| Transition | Duration | Mood |
|------------|----------|------|
| Departure | 4–6 s | Called, committed |
| Arrival | 2–3 s after transit | Physical placement |
| Victory return | 3–5 s transit + calm chamber | Clear, Observatory open |
| Defeat return | 3–4 s transit + dim chamber | Heavy, fast recovery |

---

## Implementation checklist (content)

- [ ] One departure type + one arrival type (paired)
- [ ] Match-found chamber reaction (light + audio + Terminal)
- [ ] No fullscreen loading art; max 8 s total handoff
- [ ] Countdown starts **on arena pad**, not in chamber
- [ ] Victory / defeat return differ in light, fog, audio length
- [ ] No hub, spectator, faction transit branches

---

## Related docs

- [VOID_GLADIATOR_CHAMBER_LAYOUT.md](VOID_GLADIATOR_CHAMBER_LAYOUT.md) — Terminal sunken dais, south void lip
- [VOID_RETURN_LOOP.md](VOID_RETURN_LOOP.md) — chamber mood after return
- [VOID_GLADIATOR_LOOP.md](VOID_GLADIATOR_LOOP.md) — queue and rewards timing
- [PROTOTYPE.md](PROTOTYPE.md) — spawn pads, countdown, arena generation

*Documentation only.*
