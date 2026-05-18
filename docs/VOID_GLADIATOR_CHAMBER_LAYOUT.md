# VOID — Gladiator Chamber Layout (MVP)

**Purpose:** First **physical** player chamber — walkable prep space between arena matches. **Not a menu.**

**Related:** [VOID_GLADIATOR_CHAMBER.md](VOID_GLADIATOR_CHAMBER.md) (stations + tone) · [VOID_GLADIATOR_LOADOUT.md](VOID_GLADIATOR_LOADOUT.md) (slots) · [VOID_RETURN_LOOP.md](VOID_RETURN_LOOP.md) (win/loss mood) · [VOID_GLADIATOR_LOOP.md](VOID_GLADIATOR_LOOP.md) (queue + rewards)

**Status:** Layout spec — **not implemented**. No code.

---

## 1. Chamber philosophy

The player **returns here after every match.** This is their **living / preparation** cell inside the Arena system — not a lobby UI.

| Must feel | Means |
|-----------|--------|
| **Safe** | No combat, no fall, sealed slab underfoot |
| **Silent** | Low bed; void louder than crowd — there is no crowd |
| **Brutalist** | Raw concrete, steel ribs, function-only forms |
| **Isolated** | One pod on cables; horizon is void, not city |
| **Ritualistic** | Same path: return → observe → prepare → queue → leave |

**Constraints (MVP):**

- Suspended over void — visible drop beyond shell
- **No NPCs**, no vendors, no chat hub
- **Intimate** — target **25–40 m** walkable footprint
- Player **prepares** here; arena is elsewhere

---

## 2. Physical layout

### Footprint (MVP target)

| Measure | Value | Note |
|---------|-------|------|
| Walkable floor | **32 m × 26 m** (~832 m²) | Inside 25–40 m guideline |
| Ceiling (main) | **4.5 m** | Low, oppressive |
| Observatory bay | **12 m** tall fracture | One scale shock |
| Void drop (visual) | **∞** below north edge | Not traversable |

### ASCII plan (top-down, north = void / Observatory)

```
                        NORTH — VOID EXPOSURE
    ┌────────────────────────────────────────────────────────────┐
    │▓▓▓▓▓▓▓▓▓▓▓▓▓ OBSERVATORY (12m bay) ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│  ~26m wide
    │▓  rail ─────────────────────────────────────────────  ▓│
    │▓     distant: bridges · arenas · chambers · megastructure ▓│
    ├────────────────────────────────────────────────────────────┤
    │                                                            │
    │   [ARMORY]  8m×6m              [ARMOR ZONE]  7m×5m       │
    │   RAILGUN │ SHOTGUN │ BAZOOKA    armor pedestal            │
    │   ────────┴─────────┴───         helmet stand             │
    │   west wall                      east alcove               │
    │                                                            │
    │              ┌─────────────────────┐                       │
    │              │  RETURN PLATFORM    │                       │
    │              │  (entry) 6m × 6m    │                       │
    │              │       ★ spawn       │                       │
    │              └──────────┬──────────┘                       │
    │                         │                                  │
    │              ┌──────────▼──────────┐                       │
    │              │   ARENA TERMINAL    │                       │
    │              │   sunken 5m × 4m    │                       │
    │              │   [QUEUE CONSOLE]   │                       │
    │              └──────────┬──────────┘                       │
    │                         │ catwalk to void lip (visual)     │
    └─────────────────────────┼────────────────────────────────┘
                              ▼ void (not walkable)

    SOUTH: sealed bulkhead + cable anchors (no exit door in MVP)
```

### Elevation (side slice, west → east)

```
                    ┌── Observatory fracture (glass / broken rib)
    ceiling 4.5m ───┤
                    │    · · · void · · ·
    floor 0m ───────┼───────────────────────────────
                    │  racks    platform   terminal ▼
    terminal -0.4m ─┴──────── spawn slab ──── sunken dais
```

### Zone list (required)

| Zone | Position | Size (approx) |
|------|----------|----------------|
| **Entry / Return platform** | Center | 6 m × 6 m slab |
| **Armory** | West | 8 m × 6 m along wall |
| **Armor + helmet pedestals** | East alcove | 7 m × 5 m |
| **Arena Terminal** | South-center, sunken | 5 m × 4 m dais |
| **Observatory** | North edge | Full width × 4 m depth + 12 m vertical bay |

**Inventory (MVP):** Fragment crate + consumable locker inside **Armor zone** rear niche (2 m × 2 m) — not a sixth zone; keeps layout readable.

---

## 3. Armory zone

**West wall.** Three physical racks — player **walks** to equip ([VOID_GLADIATOR_LOADOUT.md](VOID_GLADIATOR_LOADOUT.md)).

```
    WALL
    ┌──────┬──────┬──────┐
    │RAIL  │SHOT  │BAZOO │
    │ GUN  │ GUN  │ KA   │
    └──┬───┴──┬───┴──┬───┘
       │      │      │
     cradle cradles (1.2m wide each)
```

| Rack | Silhouette read | Interact |
|------|-----------------|----------|
| **Railgun** | Long barrel, cool emissive | Pull → equip to shoulder preview |
| **Shotgun** | Wide mouth | Same |
| **Bazooka** | Mass tube | Same |

- **No menu-first:** interact = grab; holster returns weapon to rack glow.
- Locked rack: draped cloth + dim lock light (Resonance unlock).
- **Future socket:** `TROPHY_WEST_01` — wall mount for weapon trophy (§8).

**Emotional note:** Armory is **choice** — brightest work light in neutral mood; dims on defeat, steadies on victory.

---

## 4. Armor zone

**East alcove.** Pedestal system — player **sees** equipped suit and helmet on stands / mannequin.

```
    ┌─────────────────┐
    │   HELMET STAND  │  ← post, eye height
    ├─────────────────┤
    │  ARMOR PEDESTAL │  ← torso mannequin or floating rig
    ├─────────────────┤
    │ [crate] consum. │  ← optional belt case
    └─────────────────┘
```

| Piece | MVP | Visual |
|-------|-----|--------|
| **Armor stand** | Light / Medium / Heavy | Full silhouette on mannequin |
| **Helmet stand** | Faceless default + unlocks | Rotates slowly when idle |
| **Equipped read** | Mirror: player mesh matches stands | |

**Room progression (later):** Extra stands along east wall — `STAND_E_02`, `STAND_E_03` (empty in MVP, bolt holes visible).

**Emotional note:** Armor zone is **identity** — quieter light than Armory; player touches metal after a loss.

---

## 5. Arena Terminal

**South-center, sunken 0.4 m.** Single brutalist console — altar to the system.

```
        ┌─────────────────┐
        │  PRESTIGE crest │
        │  RECENT ×5      │
        │  [QUEUE]        │
        │  ranked/unrank  │
        └────────┬────────┘
                 │ cable to ceiling
    ═════════════╧════════════  dais edge
```

| Function | Diegetic read |
|----------|----------------|
| **Queue PvP** | Physical lever or palm plate — lock loadout |
| **Prestige** | Slow crest animation — cosmetics only |
| **Recent matches** | Five LED/slab lines W/L |
| **Rewards** | Post-match tally scroll once, then idle |

**Player stays in chamber while queued** — can walk Observatory; Terminal pulses “searching.”

**Leave:** Match found → fade from dais (not from menu teleport).

**Future socket:** `TERMINAL_SIDE_L` / `R` — flank panels (market hook **not wired in MVP**).

---

## 6. Observatory

**North edge — most important emotional zone.** **No gameplay** in MVP.

### Vista layers (back to front)

| Layer | Content |
|-------|---------|
| Far | Colossal structures, ring ruins, chains |
| Mid | **Distant arenas** — lit decks, muzzle flashes, void bursts |
| Near | **Bridges** + **other chambers** — sibling pods on cables, sparse windows |
| Fore | Rail, fractured glass, interior fog |

### Outcome states ([VOID_RETURN_LOOP.md](VOID_RETURN_LOOP.md))

| State | Visibility | Fog | Audio |
|-------|------------|-----|-------|
| **Victory** | Clearer sight lines, +1 lit distant arena | Thinner at glass | Calmer void wind |
| **Defeat** | Reduced — haze closes | **Heavier** interior fog | Stronger void inhale |
| **Neutral** | Default | Medium | Balanced hum |

**Duration:** Defeat mood **20–40 s** decay to neutral; victory mood **45–90 s** — victory lingers longer than defeat.

**Future socket:** `OBS_SCOPE_01` — telescope mesh (spectate hook, inactive).

---

## 7. Emotional loop

Tied to player route and [VOID_RETURN_LOOP.md](VOID_RETURN_LOOP.md). **No UI popups** — room carries mood.

### Victory

| Channel | Change |
|---------|--------|
| Light | Room **brighter** (+15–25% key); Armory racks warm edge |
| Observatory | **Clearer** — see more chambers / arenas |
| Audio | Calmer hum; void **muted** |
| Duration | **Longer** hold (45–90 s) before neutral |

### Defeat

| Channel | Change |
|---------|--------|
| Light | **Deeper shadows**; Terminal dim |
| Observatory | **Heavier fog**; void audio **stronger** |
| Audio | Quieter bed, weight on low band |
| Duration | **Shorter** (20–40 s) — not punishing, not sticky |

### Player route (emotional beats)

```
RETURN (platform) ──feel outcome pulse──►
    │
    ├─► OBSERVE (Observatory) ──scale, void, humility──►
    │
    ├─► PREPARE (Armory + Armor zone) ──identity, touch gear──►
    │
    └─► QUEUE (Terminal) ──commitment──► LEAVE (fade to arena)
```

| Step | Distance (approx) | Time (player-paced) |
|------|-------------------|---------------------|
| Return → Observatory | 8–12 m | 5–15 s |
| Observatory → Armory | 14–18 m | 10–30 s |
| Armory → Armor | 12 m cross | 10–20 s |
| Armor → Terminal | 6–8 m | 5–10 s |

**Total walk loop:** ~40–55 m path — fits intimate 25–40 m **area** without maze (zones overlap hub).

---

## 8. Chamber progression

**Room evolves = player history** ([VOID_GLADIATOR_LOADOUT.md](VOID_GLADIATOR_LOADOUT.md)). Unlocks place **objects in space**, not stats.

| Unlock type | Example placement | Resource |
|-------------|-------------------|----------|
| **Weapon trophies** | Armory west `TROPHY_W_01` | Fragments / win streak |
| **Helmets** | Helmet stand rotation + wall peg | Prestige |
| **Artifacts** | *(future)* sealed niche south bulkhead | — |
| **Memory fragments** | Observatory etching on rail | Resonance |
| **Architecture** | East wall second stand, slab tally marks | Milestone Prestige |

**MVP:** 2–3 visible unlock hooks only (one trophy peg, one helmet, Terminal crest). Rest are **empty sockets** in mesh.

**Rule:** Progression adds **display**, not room size — chamber stays 25–40 m.

---

## 9. Future hooks

**Do not implement in MVP.** Marked on layout as dead sockets only.

| Hook | Socket ID (layout) | Why deferred |
|------|-------------------|--------------|
| **Market** | `TERMINAL_SIDE_L` | Economy expansion |
| **Social hub** | `SOUTH_BULK_SEATS` | Other players / networking |
| **Factions** | `BANNER_NW` | Rep systems |
| **Spectating** | `OBS_SCOPE_01` | Live feed infra |
| **Economy expansion** | `VENDOR_ALCOVE` | Breaks MVP resource trio |

**MVP guardrail:** No new walkable wings — only props on existing walls.

---

## Output summary

### ASCII (compact player-readable)

```
         [ OBSERVATORY — void ]
    [ARMORY]    [RETURN★]    [ARMOR+HELMET]
                  [TERMINAL↓]
```

### Dimensions

- **32 × 26 m** floor, **4.5 m** ceiling, **12 m** north bay
- Walk loop ~40–55 m; zone count **5** (+ consumable niche)

### Player route

`Return → Observe → Prepare → Queue → Leave`

### Emotional notes

- Observatory = emotional anchor; win clearer / loss foggier
- Victory mood lasts longer than defeat; neither uses popups
- Armory = agency; Terminal = commitment

### Future expansion sockets

`TROPHY_W_01` · `STAND_E_02/03` · `TERMINAL_SIDE_L/R` · `OBS_SCOPE_01` · `SOUTH_BULK_SEATS` · `BANNER_NW` · `VENDOR_ALCOVE` — **empty in MVP**

---

## MVP build checklist

- [ ] Single scene, 32×26 m walkable, no maze
- [ ] Five zones + spawn platform as specified
- [ ] Physical weapon racks (3) + armor/helmet pedestals
- [ ] Sunken Terminal — queue without leaving space
- [ ] Observatory void vista + win/loss fog/light hook
- [ ] Outcome mood from [VOID_RETURN_LOOP.md](VOID_RETURN_LOOP.md)
- [ ] No market, social, factions, spectate, economy wing

*Documentation only.*
