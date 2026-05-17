# Void atmosphere — toxic abyss (prototype)

> **Canonical design:** [art/ART_DIRECTION.md](art/ART_DIRECTION.md)  
> **Level philosophy:** [levels/LEVEL_DESIGN.md](levels/LEVEL_DESIGN.md)

The void is **no longer pure darkness**. It reads as an **infinite toxic/corrupted gas ocean** beneath compact arenas — inspired by **Quake 3 void maps**, industrial abyss, and dimensional corruption.

**Fall collapse:** as fighters drop, visibility **ramps down with depth** (world Y). Above the arena stays clear; below **Y ≈ -10** gas thickens; by **Y ≈ -40** only **~1–2 m** remains visible (fog + depth fog + screen vignette).

---

## Visual language

| Element | Treatment |
|---------|-----------|
| **Gas colors** | Dark green, blue, purple — layered and semi-transparent |
| **Fog** | WorldEnvironment fog tinted green-teal; density ~0.078 |
| **Particles** | Drifting motes rising through gas; slow movement |
| **Lighting** | Cold sun + toxic omni pulse under decks |
| **Distance** | Silhouette ruins, towers, chains fading into fog |

---

## In-game systems

| Feature | Location |
|---------|----------|
| Depth fog + screen FX driver | `scripts/environment/void_gas_controller.gd` |
| Toxic gas layers + animation | `scenes/environment/void_atmosphere.tscn` |
| Fog thresholds / densities | `scripts/game_balance.gd` (`VOID_FOG_Y_*`, `void_fog_depth_t`) |
| Void observers | `scenes/environment/void_observer.tscn` |
| Distant architecture + chains | `scenes/world/void_distant_architecture.tscn` |
| VOID_GORE fall timeline | `scripts/effects/void_gore_sequence.gd` |
| Void death styles | `scripts/game_balance.gd` → `VOID_DEATH_STYLE` |
| Audio placeholders | `scripts/environment/void_audio.gd` |
| Arena void fall | `void_y = -20` per template |

---

## VOID_GORE timeline (seconds)

| Time | Beat |
|------|------|
| 0.0 | Loss of balance |
| 0.35 | Instability |
| 0.7 | Ambient motes |
| 1.5 | Corruption cloud |
| 2.2 | Body breakup |
| 3.2 | Burst → score |

---

## Arena relationship

- Combat happens on **small suspended ruins**
- **Gaps** between slabs expose gas — ring-outs are deliberate
- Static walls + debris create **lanes** and **broken sightlines**
- Gore and corruption VFX remain **cinematic** at death, not constant clutter

---

## Not yet in build

- Real audio assets (gas rumble, toxic hiss, reverb)
- Volumetric fog / shaders (using mesh layers + CPUParticles)
- Fully procedural wall generation (templates are hand-authored in code)

See [roadmap/ROADMAP.md](roadmap/ROADMAP.md).
