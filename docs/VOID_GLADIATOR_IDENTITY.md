# VOID — Gladiator Identity (MVP)

**What this is:** How the player **exists inside the Arena system** — symbolic identity and progression, not class design or RPG trees.

**What this is not:** Hero fantasy, skill trees, origin stories, faction politics, or stat classes.

**Related:** [VOID_GLADIATOR_LOADOUT.md](VOID_GLADIATOR_LOADOUT.md) (slots) · [VOID_GLADIATOR_CHAMBER.md](VOID_GLADIATOR_CHAMBER.md) · [VOID_GLADIATOR_CHAMBER_LAYOUT.md](VOID_GLADIATOR_CHAMBER_LAYOUT.md) (room archive) · [VOID_GLADIATOR_LOOP.md](VOID_GLADIATOR_LOOP.md) (Prestige) · [VOID_RETURN_LOOP.md](VOID_RETURN_LOOP.md) · [VOID_DESIGN_PHILOSOPHY.md](VOID_DESIGN_PHILOSOPHY.md)

**Status:** Design spec — **not implemented**.

---

## 1. Philosophy

The player is **not a hero** chosen to save anything. They are a **gladiator extracted into the Arena system** — a tenant of brutalist infrastructure above an indifferent void.

**Identity comes from:**

| Source | What it says |
|--------|----------------|
| **Helmet** | Who you are remembered as |
| **Armor** | How you fight in the open |
| **History** | What the system has done to you and through you |
| **Chamber** | What you have accumulated when alone |
| **Victories** | Proof you endured another cycle |

**Not from:** lore tablets, NPC monologues, class names, or +1% spreadsheets.

**Design gate:** Identity must be **readable at arena speed** — silhouette, helmet read, chamber objects. Opponent should think “that’s the broken faceless with heavy plates,” not “that’s a Level 12 Assault.”

---

## 2. Helmet identity

**Helmet = recognition.** The face you show the system when you have no face.

### MVP examples

| Helmet | Symbolic read | Unlock skew |
|--------|---------------|-------------|
| **Custodian** | Servant of the Arena; worn crest, compliance | Starter / Resonance |
| **Observer** | Analytical, distant; glass or visor slit | Resonance |
| **Faceless** | Anonymous dread; smooth plate | Default |
| **Broken** | Survived impact; crack, missing segment | Fragments / milestone |
| **Corrupted** | Void-touched edge; unhealthy glow | Prestige |

### Purpose

| Function | MVP |
|----------|-----|
| **Recognition** | Opponent recalls you between queues |
| **Prestige** | Rare helmets = status, not power |
| **Visual memory** | Marketing stills, spectator read, self-mirror on stand |

**Combat (MVP):** No helmet stats. Optional distinct hit audio — cosmetic only.

**Avoid:** Helmet that changes abilities, “legendary helmet +damage.”

---

## 3. Armor identity

**Armor expresses role** — not a class name, a **physical contract** with the duel.

| Armor | Role read | Silhouette |
|-------|-----------|------------|
| **Light** | Duelist, flanker, exposure for speed | Thin plates, gaps, agile outline |
| **Medium** | Default gladiator; balanced threat | Standard bulk, readable humanoid |
| **Heavy** | Anchor, brawler, absorbs pressure | Wide shoulders, sealed joints |

**Visible silhouette matters** at **15–25 m** — opponent chooses engagement before UI.

**Meaningful difference:** One clear tradeoff per tier ([VOID_GLADIATOR_LOADOUT.md](VOID_GLADIATOR_LOADOUT.md)) — mobility vs protection — not ten derived stats.

**Avoid:** Armor labeled “Paladin” or “Assassin”; armor that hides weapon read.

---

## 4. Chamber identity

The [Gladiator Chamber](VOID_GLADIATOR_CHAMBER.md) is a **private archive** — the room **is** part of your identity when others never see it.

### History in the room (MVP examples)

| Object | What it records |
|--------|-----------------|
| **Weapon trophies** | Wins with a family — rack mount, scarred barrel |
| **Etchings** | Tally marks on slab near Terminal — rounds, void kills |
| **Memory fragments** | Resonance unlock — glass shard or void-crystal in Observatory rail |
| **Weapon displays** | Beyond active rack — retired or favored piece on wall |

**Room becomes archive:** Empty pegs and blank etchings still tell a story — **new** gladiator. Filled wall tells **veteran**.

**Progression rule:** Unlocks place **objects in space** ([VOID_GLADIATOR_CHAMBER_LAYOUT.md](VOID_GLADIATOR_CHAMBER_LAYOUT.md) sockets) — chamber does not grow in footprint.

**Emotional tie:** [VOID_RETURN_LOOP.md](VOID_RETURN_LOOP.md) — win/loss mood; room reflects state before player fixes loadout.

**Avoid:** NPC commentary on your wall; infinite collectible clutter.

---

## 5. Match identity

Identity must survive **into the arena** and **across rematches** — rivals are people, not bots.

### What carries into a match

| Signal | Readable by |
|--------|-------------|
| **Loadout** | Weapon + armor silhouette + helmet |
| **Appearance** | Materials, void-scar trim, prestige emissive |
| **Prestige** | Terminal crest, rare helmet — optional tiny arena banner at spawn (cosmetic) |
| **Recent history** | Terminal recent list; opponent name/tag if PvP |

### Recognition loop

```
See silhouette at countdown
    → Fight
    → Remember helmet + armor + weapon
    → Return to chamber
    → Opponent may appear again — rivalry without lore speech
```

**Recent wins** (Terminal **last 5**) reinforce **match identity** — “I beat that tag twice” — factual, not bragging UI.

**Player should recognize rivals** by **look and rhythm**, not chat. MVP PvP: stable opponent tag + consistent visual loadout.

**Avoid:** Full character creator sliders; nameplates larger than silhouette.

---

## 6. Future hooks

**Do not implement in MVP.** Identity stays symbolic; these add narrative/social RPG surface.

| Hook | Why deferred |
|------|--------------|
| **Factions** | Rep, colors, politics — not classless identity |
| **Origins** | Backstory selection — exposition creep |
| **Backstories** | Text lore — violates “not lore exposition” |
| **Titles** | Earned strings stacked on UI — menu feeling |
| **Social clans** | Shared identity layer — hub scope |

**Extension rule:** New identity channels must be **visible in silhouette or chamber object** — not biography panels.

---

## MVP identity stack (summary)

```
         ┌─────────────┐
         │   HELMET    │  recognition · prestige
         ├─────────────┤
         │   ARMOR     │  role · silhouette
         ├─────────────┤
         │   WEAPON    │  combat style (loadout doc)
         └──────┬──────┘
                │
    ┌───────────▼───────────┐
    │      CHAMBER          │  archive · trophies · etchings
    │      (history)        │
    └───────────┬───────────┘
                │
    ┌───────────▼───────────┐
    │   MATCH / RIVAL READ  │  appearance · recent wins · prestige
    └───────────────────────┘
```

| Layer | MVP deliverable |
|-------|-----------------|
| Helmet | 5 symbolic types; cosmetic unlocks |
| Armor | 3 silhouettes; role read |
| Chamber | 2–3 unlock object types on walls |
| Match | Countdown silhouette + optional spawn banner |
| Progression | Resonance / Fragments / Prestige → identity only |

---

## Hard rules

- **No classes** — no Warrior/Mage framing.
- **No hero abilities** — identity does not grant unique mechanics in MVP.
- **No RPG systems** — no levels, talent points, gear score.
- **Keep MVP symbolic** — few strong reads, not many weak ones.

---

## Related docs

- [VOID_GLADIATOR_LOADOUT.md](VOID_GLADIATOR_LOADOUT.md) — weapon / armor / helmet slots
- [VOID_GLADIATOR_LOOP.md](VOID_GLADIATOR_LOOP.md) — Prestige and resources
- [VOID_GLADIATOR_CHAMBER_LAYOUT.md](VOID_GLADIATOR_CHAMBER_LAYOUT.md) — trophy and etching sockets
- [VOID_ARENA_TRANSITIONS.md](VOID_ARENA_TRANSITIONS.md) — arrival as physical placement, not menu

*Documentation only.*
