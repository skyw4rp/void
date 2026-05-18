# VOID — Return Loop

**What this is:** The **emotional bridge** between arena combat and the next queue — atmosphere and player identity, not balance spreadsheets.

**What this is not:** Penalties, streak shaming, energy timers, or mandatory menu friction. Rewards still exist ([VOID_GLADIATOR_LOOP.md](VOID_GLADIATOR_LOOP.md)) but are **felt** in the room, not shouted by popups.

**Where it happens:** [VOID_GLADIATOR_CHAMBER.md](VOID_GLADIATOR_CHAMBER.md) — same space, different mood.

**Status:** Design spec — **not implemented**.

---

## Loop (MVP)

```
Combat ──► Return ──► Recovery ──► Preparation ──► Queue
              │            │
              └────────────┴── outcome shapes chamber (diegetic only)
```

| Phase | Duration (target) | Player feeling |
|-------|-------------------|----------------|
| **Combat** | Match length | Adrenaline, exposure, void threat |
| **Return** | 3–8 s | Landing — body remembers the duel |
| **Recovery** | 15–45 s | Breath back; room answers win/loss |
| **Preparation** | 30–90 s | Choice without rush |
| **Queue** | Variable | Commitment at Terminal |

**Gate:** [VOID_DESIGN_PHILOSOPHY.md](VOID_DESIGN_PHILOSOPHY.md) — void still matters in chamber; victory is not celebration carnival; defeat is not humiliation.

---

## 1. Return after defeat

The player **comes back damaged** — not stat-debuffed, **psychologically** marked by the last match.

### Chamber mood

| Axis | Defeat read |
|------|-------------|
| **Light** | Darker — key light dims ~20–30%, fill near black |
| **Sound** | Quieter combat residue; **heavier** void inhale at Observatory |
| **Weight** | Slower footfall suggestion (optional subtle FOV narrow, not movement debuff) |
| **Void audio** | Stronger — low band + cable creak; distant arena impacts feel farther away |

### Player state (identity, not systems)

- **Recovery feeling** — “I survived the system again.”
- **Regroup** — natural pull toward Armory / Inventory before Terminal.
- **Reflection** — Observatory reads as accusation and perspective, not punishment.

### Hard rules (MVP)

- **No punishment systems:** no lockout, no tax, no broken gear, no shame text.
- **No loss streak UI** beyond Terminal’s factual recent list.
- Resources from [VOID_GLADIATOR_LOOP.md](VOID_GLADIATOR_LOOP.md) still apply on loss — chamber does not withhold them.

### Return beat (defeat)

1. Fade in on center slab — slight stagger animation optional (cosmetic).
2. One breath of silence before ambient returns.
3. Terminal panel: single dim **L** line on recent matches (diegetic, not modal).
4. Room stays in defeat palette until player **interacts** with Armory, Inventory, or Observatory (starts Recovery).

---

## 2. Return after victory

Victory is **relief and readiness**, not a party.

### Chamber mood

| Axis | Victory read |
|------|--------------|
| **Light** | Calmer — stable key; slightly warmer edge on Armory rack |
| **Sound** | Steady structural hum; void wind **muted** vs defeat |
| **Stability** | Less cable groan; Terminal idle pulse even |
| **Reward atmosphere** | Subtle only — Resonance hum at module bench, fragment crate latch clicks once |

### Player state

- **Prepare again** — confidence without arrogance.
- **Collect reward** — diegetic: crate glow, terminal crest tick (numbers on slab, not fullscreen loot).
- **Continue loop** — path to queue feels **open**, not forced.

### Hard rules (MVP)

- No victory fanfare sting, no confetti, no announcer.
- Prestige/rank updates on Terminal only — no parade.

### Return beat (victory)

1. Fade in — upright, same spawn.
2. Terminal: single **W** on recent strip; prestige bar nudges if ranked.
3. Inventory crate: brief material shimmer (if Fragments earned).
4. Room holds victory palette until Terminal queue **or** 60 s idle (soft decay to neutral).

---

## 3. Environmental feedback

**The room tells the outcome.** Player reads place before reading UI.

### No UI popups (MVP)

Forbidden on return:

- Fullscreen win/loss splash
- Modal reward chest
- Streak banners
- Tutorial toasts

Allowed (diegetic, minimal):

- Terminal slab text / LEDs
- Physical object state
- Audio/light/fog shifts

### Feedback channels

| Channel | Defeat | Victory |
|---------|--------|---------|
| **Audio** | Void up, combat bed down, heartbeat tail optional | Hum stable, void down, single terminal chime |
| **Lights** | Cooler, fewer pools | Warmer key on Armory, Terminal steady |
| **Fog** | Slightly denser at Observatory glass (interior haze) | Clearer sight into void — “air settled” |
| **Objects** | Weapon rack askew if player died to void; scorch decal fresh on slab | Racks aligned; module bench lit |
| **Observatory** | Distant arena flash then dark; other chambers fewer lights | Same vista, one distant duel still lit — world continues |

### Neutral baseline

After Recovery, chamber drifts to **neutral** — same layout, default light/audio. Player should not feel trapped in defeat or victory mood forever.

### Match-type nuance (optional MVP)

| Last round end | Extra object read |
|----------------|-------------------|
| Void ring-out (you fell) | Observatory rail cold; wind gust |
| Void ring-out (you scored) | Far void pulse once |
| Shield break kill (you died) | Armory rack spark dead |
| Shield break kill (you won) | Bench resonance flicker |

All cosmetic — **no stat linkage**.

---

## 4. Recovery ritual

A **short pause** between Return and Queue. Not a timer gate — player-paced.

**Purpose:** Let identity catch up to body. Separate “I lost/won” from “I choose what’s next.”

### Ritual stations (any order, MVP)

| Station | Defeat tendency | Victory tendency |
|---------|-----------------|------------------|
| **Armory** | Touch weapon, re-seat module — re-ground skill | Confirm loadout, swap module if unlocked |
| **Inventory** | Check consumables — plan comfort | Restock from earned Fragments |
| **Observatory** | Stare into void — scale puts loss in context | Brief look — “there’s more” without hubris |

**Queue only when ready:** Terminal accept is intentional. No forced walk through all three — but environment **invites** them via lighting paths (defeat: dim path to Observatory; victory: open path to Terminal).

### Recovery length

| Player behavior | Target |
|-----------------|--------|
| Rushes Terminal | Allowed — room still conveyed return beat on fade-in |
| Uses 1–2 stations | Ideal — 15–45 s |
| AFK in Observatory | Neutral mood after 90 s — no penalty |

### Link to Preparation

Recovery **blends into** Preparation ([VOID_GLADIATOR_LOOP.md](VOID_GLADIATOR_LOOP.md)) — same loadout slots, same lock-in at Terminal. Recovery is emotional; Preparation is functional.

---

## 5. Future hooks

**Do not implement in MVP.** Documented so return logic stays extensible without popup creep.

| Hook | Idea | Why deferred |
|------|------|--------------|
| **Void exposure** | Cumulative void “scars” — Observatory shows personal depth meter in fog | Meta progression + balance risk |
| **Global events** | All chambers darken — system-wide anomaly | Live ops + networking |
| **Memory echoes** | Ghost audio of last kill / fall replay in room | Content cost, horror tone drift |

**Extension rule:** New return feedback must use **audio / lights / fog / objects / Observatory** — never add mandatory UI steps to the return beat.

---

## MVP checklist

- [ ] Distinct defeat vs victory return palettes (light + audio + fog)
- [ ] Spawn fade-in beat — no fullscreen popup
- [ ] Terminal recent match strip (diegetic W/L)
- [ ] Object states (rack, crate, slab) react once per return
- [ ] Recovery invitation via lighting paths, not forced tour
- [ ] Neutral state after interaction or timeout
- [ ] No punishment, debuff, or lockout on loss

---

## Related docs

- [VOID_GLADIATOR_CHAMBER.md](VOID_GLADIATOR_CHAMBER.md) — physical layout and stations
- [VOID_GLADIATOR_LOOP.md](VOID_GLADIATOR_LOOP.md) — rewards and queue
- [VOID_DESIGN_PHILOSOPHY.md](VOID_DESIGN_PHILOSOPHY.md) — tone gate
- [art/MOODBOARD.md](art/MOODBOARD.md) — void-forward chamber read

*Documentation only.*
