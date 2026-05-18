# VOID — Gladiator Loop (MVP PvP)

**Scope:** Base **PvP only** — hub → prep → duel → reward → hub. No campaign, roguelite, or guild systems.

**Status:** Design spec (**not implemented**). Today’s build jumps straight into arena vs AI ([PROTOTYPE.md](PROTOTYPE.md)).

**Loop:** Gladiator Chamber (Nexus) → Preparation → Arena PvP → Reward → Return

---

## Loop overview

```
Gladiator Chamber (Nexus)
        │
        ▼
   Preparation          weapon · 1 module · optional consumable
        │
        ▼
    Arena PvP            1v1 · first to 5 rounds · void or kill
        │
        ▼
      Reward             Resonance · Fragments · Prestige (ranked)
        │
        ▼
   Return to Chamber
```

**Session target:** ~3–8 minutes per cycle. Prep stays short; the arena is the core.

**Arena rules (MVP):** Same as prototype — procedural round arenas, shield then health, ring-out below deck edge. Full combat detail: [PROTOTYPE.md](PROTOTYPE.md). PvP = human opponent instead of AI; round flow unchanged.

---

## 1. Gladiator Chamber (Nexus)

One safe megastructure hub. **Four stations only** in MVP.

| Station | Purpose |
|---------|---------|
| **Armory** | Pick **one** weapon (railgun / shotgun / bazooka). Equip **one** module. Silhouette-first UI. |
| **Arena Terminal** | Queue **1v1** (ranked or unranked — same rules; ranked moves **Prestige** only). Shows loadout + queue status. |
| **Inventory** | Hold **Fragments**, owned consumables (max **3** in stock; bring **0–1** into a match). Simple list, no gear grid. |
| **Observatory** | View the void / distant ruins. Optional: count of live duels. **No gameplay power.** |

**Chamber rules:**

- No combat, no void fall.
- Loadout editable in chamber; **locked** when Terminal match is accepted.
- After every match, spawn at chamber center — never straight into arena.

---

## 2. Resources

| Resource | Job | Earn | Spend |
|----------|-----|------|-------|
| **Resonance** | Breadth | Every finished match (win or loss) | Unlock modules (Armory) |
| **Fragments** | Intensity | Wins (more), losses (less), void-kill bonus | Consumables (Inventory) |
| **Prestige** | Reputation | Ranked wins / streaks | Cosmetics only (titles, banners) — **never stats** |

No fourth currency, no loot boxes, no paid combat upgrades in MVP.

---

## 3. Preparation phase

One screen between Terminal accept and arena load.

| Slot | Rule |
|------|------|
| **Weapon** | Required — one of three families |
| **Module** | Required — one slot, mild readable perk |
| **Consumable** | Optional — zero or one, single-use in match |

- **Lock-in** at confirm; no mid-match changes.
- Opponent sees **weapon + module type** at countdown (not consumable).
- **15–30 s** timer; default to last loadout if idle.

---

## 4. Match reward loop

**One reward screen** per completed duel (disconnect/forfeit = no payout).

| Result | Resonance | Fragments | Prestige |
|--------|-----------|-----------|----------|
| Win | Base + small bonus | Base + win bonus | + if ranked |
| Loss | Reduced base | Consolation | − if ranked (floor) |
| Forfeit | — | — | Ranked penalty |

**Optional bonuses (max one each):** void ring-out round · fast match (≤8 rounds total) · no consumable used.

**Flow:** Scoreboard → tally Resonance / Fragments / Prestige → **Continue** → Chamber (Inventory/Armory reflect new totals).

**Anti-farm (ranked):** Diminishing Resonance vs same opponent after 5 matches / 24 h. Unranked uncapped for practice.

---

## 5. Future expansion hooks

**Not in MVP.** Entry points for later work without redesigning the chamber.

| Hook | Notes |
|------|-------|
| 2v2 / FFA | New Terminal queue |
| Second module slot | Armory unlock tier |
| Weapon mastery | Per-weapon Resonance track |
| Crafting bench | Fragment sinks beyond consumables |
| Chamber NPCs | Vendors / lore |
| Observatory replays | Spectator VOD |
| Seasons | Prestige reset cadence |
| AI practice queue | Bot duel (prototype already has AI; separate from PvP loop) |
| PvE descent | Roguelite floors — different pillar |
| Shared clan nexus | Social hub |

**Rule:** New features use **Terminal** (modes) or **Armory / Inventory** (loadout). No fifth station without merging two MVP stations.

---

## Related

- [VOID_DESIGN_PHILOSOPHY.md](VOID_DESIGN_PHILOSOPHY.md) — feel gate  
- [PROTOTYPE.md](PROTOTYPE.md) — current arena implementation  
- [CODEBASE_QUICK_REFERENCE.md](CODEBASE_QUICK_REFERENCE.md) — combat technical owners  

*Documentation only.*
