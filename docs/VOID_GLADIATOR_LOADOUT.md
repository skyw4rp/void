# VOID — Gladiator Loadout (MVP)

**What this is:** The **preparation ritual** before arena combat — who you are when you step onto the deck.

**Loop:**

```
Return to Chamber → Preparation → Loadout → Queue → Combat → Reward → Return
```

**Where it happens:** [VOID_GLADIATOR_CHAMBER.md](VOID_GLADIATOR_CHAMBER.md) (Armory + Inventory). **Rewards** that fuel unlocks: [VOID_GLADIATOR_LOOP.md](VOID_GLADIATOR_LOOP.md). **Emotional return:** [VOID_RETURN_LOOP.md](VOID_RETURN_LOOP.md). **Risk/reward tone:** [VOID_RISK_REWARD.md](VOID_RISK_REWARD.md) *(planned — link when authored)*.

**Status:** Design spec — **not implemented**. Prototype arena uses weapon swap only ([PROTOTYPE.md](PROTOTYPE.md)).

---

## 1. Philosophy

**Loadout is identity.** The player does not grind endless stat levels. They **prepare**, **choose**, and **express** who they are this queue.

| Do | Don’t |
|----|-------|
| Few choices | +1% stat spam |
| High impact per slot | Huge RPG trees |
| Visible silhouette changes | Complex inventory grids |
| Readable opponent reads | Hidden build soup |

**Player fantasy:** “I am a heavy railgun custodian” — not “I have +7% reload.”

**Preparation** is part of [VOID_RETURN_LOOP.md](VOID_RETURN_LOOP.md) — walk the chamber, touch gear, then Terminal lock-in.

---

## 2. Weapon slot

**One primary weapon.** Defines combat style, reward fantasy, and silhouette at range.

| Weapon | Identity | Combat read |
|--------|----------|-------------|
| **Railgun** | Precision, distance, control | Patient lines, punishes exposure, void-edge picks |
| **Shotgun** | Aggression, pressure, close combat | Rush, corner crack, shield break tempo |
| **Bazooka** | Area control, risk, explosive combat | Splash discipline, self-danger, lane denial |

**Weapon affects:**

- How you fight (range band, pacing)
- How a win *feels* (clean pick vs brutal collapse vs risky boom)
- How others read you at countdown (silhouette + audio)

**MVP:** All three available from first session **or** Railgun + Shotgun starter, Bazooka via Resonance unlock — pick one policy in implementation; doc assumes **three families**, same tuning family as prototype.

**Unlock:** Resonance (breadth) — new weapon family access if gated; variants stay cosmetic-only in MVP.

---

## 3. Armor slot

**Armor changes silhouette and combat role.** One suit active. Meaningful tradeoffs — **no micro-stat spam.**

| Armor | Silhouette | Role | Mobility | Protection |
|-------|------------|------|----------|------------|
| **Light** | Thin plates, exposed limbs | Flanker / duelist | **+** mobility (faster dodge recovery feel, slightly higher effective strafe) | **−** protection (shield max −15% or damage taken +10% — **one** clear rule, not ten) |
| **Medium** | Standard gladiator bulk | Default arena fighter | Balanced | Balanced |
| **Heavy** | Wide shoulders, sealed joints | Anchor / brawler | **−** mobility | **+** protection |

**Design rule:** Opponent recognizes armor class at **15 m** by silhouette, not UI.

**MVP implementation note:** Map to existing shield/health **only if** a single tunable offset is approved later; until then, treat armor as **prep identity + movement feel hooks** documented here for PvP MVP scope. Do not ship fifteen derived stats.

**Unlock:** Fragments (intensity) or Resonance — second armor type mid-MVP, third later.

**Optional tie-in** ([VOID_GLADIATOR_LOOP.md](VOID_GLADIATOR_LOOP.md)): one **module** perk may attach to armor chest slot in implementation — still **one** readable modifier (e.g. “Stabilized dodge” on Light only). Not a second progression tree.

---

## 4. Helmet slot

**Helmet = identity.** Recognition, prestige, history — **mostly cosmetic / symbolic** in MVP.

| Example | Read |
|---------|------|
| **Custodian** | System servant, worn crest |
| **Observer** | Glass visor, analytical |
| **Faceless** | Smooth plate, anonymous dread |
| **Broken** | Cracked, survived something |
| **Corrupted** | Void-touched edge glow |

**Purpose:**

- Opponent and spectator read **who you are**
- Prestige unlocks rarer helmets ([VOID_GLADIATOR_LOOP.md](VOID_GLADIATOR_LOOP.md))
- Chamber helmet stand shows **your** history

**Combat (MVP):** No helmet-specific stats. Optional: distinct pain audio / hit VFX — cosmetic only.

**Unlock:** Prestige (primary), milestone Fragments (alternate). Starter: **Faceless** or **Custodian**.

---

## 5. Progression

Victory and defeat both feed **gladiator history** — not endless power.

### Earned from combat

| Resource | From | Loadout use |
|----------|------|-------------|
| **Resonance** | Every completed match | Unlock weapons, armor tiers, chamber objects |
| **Fragments** | Wins (more), losses (less) | Armor unlocks, optional consumables ([loop doc](VOID_GLADIATOR_LOOP.md)) |
| **Prestige** | Ranked wins / streaks | Helmets, banners, Terminal crest — **never combat stats** |

### Unlock categories

| Category | Examples |
|----------|----------|
| Weapons | Bazooka access, weapon rack finish |
| Armor | Light / Heavy suits |
| Helmets | Observer, Broken, Corrupted |
| Chamber objects | Stand banner, slab tally, Observatory etching |
| Visual identity | Emissive trim, void-scar material on stand |

**Player progression = gladiator history** — what hangs on your rack, not a level number.

**Avoid in MVP:** artifact power creep, market sinks, faction rep grinds.

---

## 6. Chamber interaction

**No menu-first loadout.** Player **walks** the [Gladiator Chamber](VOID_GLADIATOR_CHAMBER.md).

| Station | Physical interact | Slot |
|---------|-------------------|------|
| **Weapon rack** | Pull weapon from cradle → shoulder / preview mount | Weapon |
| **Armor pedestal** | Step into alcove or lift chest piece onto mannequin self | Armor |
| **Helmet stand** | Take helmet from post → equip | Helmet |
| **Inventory alcove** | Optional: one consumable into belt case ([loop](VOID_GLADIATOR_LOOP.md)) | Consumable |

**Flow:**

1. Return spawn (mood per [VOID_RETURN_LOOP.md](VOID_RETURN_LOOP.md)).
2. Visit stations in any order.
3. **Terminal** confirms lock-in → Queue.

**Read-only while queued:** Racks dim; interact disabled until match ends.

**Diegetic feedback:** Selected gear lit on rack; unowned slots sealed or draped.

---

## 7. Unlock flow

```
Combat → Reward (Resonance / Fragments / Prestige)
              ↓
         Unlock (Armory / stand / Terminal crest)
              ↓
         Prepare (physical loadout)
              ↓
         Combat
```

**Every victory should feel:**

- **Emotional reward** — chamber mood, [return loop](VOID_RETURN_LOOP.md), void scale
- **Real progression** — something new to wear, mount, or show (even if small)

**Defeat still progresses** — reduced Resonance/Fragments, no Prestige loss of unlocked gear. History accumulates; identity deepens.

**Lock-in rule:** Loadout frozen at Terminal accept. Opponent sees **weapon + armor class + helmet silhouette** at arena countdown (not consumable).

---

## 8. Future hooks

**Do not implement in MVP.** Mention only for scope control.

| System | Why deferred |
|--------|--------------|
| **Artifacts** | Extra power slot + balance surface |
| **Markets** | Economy expansion |
| **Factions** | Rep gear, chamber politics |
| **Social economy** | Trading, gifting |
| **Expeditions** | PvE loadout layer |

**Extension rule:** New slots must replace or merge an existing **visible** slot — never add a fourth combat stat pillar without cutting two +1% knobs.

---

## MVP loadout summary

| Slot | Required | Combat impact | Primary unlock |
|------|----------|---------------|----------------|
| **Weapon** | Yes | High | Resonance |
| **Armor** | Yes | Medium (role) | Fragments / Resonance |
| **Helmet** | Yes (default equipped) | Low (identity) | Prestige |
| **Consumable** | No (0–1) | Situational | Fragments |

**Slots in MVP:** **3** combat-identity slots + **0–1** consumable. No module tree unless folded into armor as **one** perk.

---

## Alignment notes (other docs)

| Doc | Relationship |
|-----|----------------|
| [VOID_GLADIATOR_LOOP.md](VOID_GLADIATOR_LOOP.md) | Economy + queue; optional module/consumable — armor/helmet **extend** prep here |
| [VOID_GLADIATOR_CHAMBER.md](VOID_GLADIATOR_CHAMBER.md) | Physical layout for rack / pedestal / stand |
| [VOID_RETURN_LOOP.md](VOID_RETURN_LOOP.md) | Recovery ritual before loadout choices |
| [VOID_RISK_REWARD.md](VOID_RISK_REWARD.md) | Planned — emotional stakes of queue vs void |

When [VOID_GLADIATOR_LOOP.md](VOID_GLADIATOR_LOOP.md) §3 is updated for armor/helmet, this doc is **authoritative** for loadout slots; loop doc stays authoritative for currencies and match rewards.

---

## MVP checklist

- [ ] Three slots: weapon, armor, helmet — visible on body in chamber and arena
- [ ] Physical interact at rack, pedestal, stand
- [ ] Terminal lock-in + opponent read at countdown
- [ ] Unlocks from Resonance / Fragments / Prestige only
- [ ] No stat spreadsheet UI, no +1% grid
- [ ] No artifacts, market, factions, expeditions

*Documentation only.*
