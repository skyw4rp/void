# Art Direction — VOID Perceptual Horror

**Goal:** Reinforce identity around **fear of emptiness, falling, and loss of control**. The void itself is the antagonist. Horror emerges from **space, depth, and perception** before enemies appear.

---

## Core Inspirations

- **Quake** — dark industrial mood
- **Unreal / liminal spaces**
- **Infinite abyss** concepts
- **Acrophobia / void anxiety**
- **Cosmic loneliness**
- **Perceptual horror**

---

## Player Emotion Targets

| Share | Emotion |
|-------|---------|
| **40%** | Tension |
| **30%** | Isolation |
| **20%** | Curiosity |
| **10%** | Terror |

**Not:** constant action horror  
**Yes:** psychological spatial horror

**Main fantasy:** *“I survived a place humans should not enter.”*

---

## Psychological Targets

### 1. Fear of falling

Spaces must trigger instability and height anxiety:

- Floating platforms
- Narrow bridges
- Broken catwalks
- Suspended structures
- Long vertical shafts
- Open pits **without visible bottom**
- Hanging debris

Player thought: **“If I fall, I disappear.”**

**Rule:** Do **not** always show ground.

**Prototype:** Bridge arena, hidden pit plane, `VoidAtmosphere` hanging debris.

---

### 2. The void as an entity

Void is **not** black paint.

The void should feel:

- Infinite
- Alive
- Observing
- Bottomless
- Impossible to understand

**Rules:**

- Sometimes hide floor entirely
- Darkness **gradients** instead of flat black
- Moving fog layers below maps
- Faint motion in the abyss
- Floating particles
- Distant silhouettes
- Very subtle movement inside darkness

Player doubt: **“Did something move down there?”**

**Prototype:** `void_atmosphere.tscn` — fog layers, drift particles, depth pulse, observers; rare distant flash after falls.

---

### 3. Kenophobia / empty space fear

- Massive chambers
- Giant halls with almost nothing
- Huge vertical emptiness
- Long silent corridors

**Avoid** filling everything with props. **Empty space is content.**

**Contrast:** tiny player vs gigantic environment.

**Prototype:** Open pit beside narrow deck; sparse pillars/cracks only.

---

### 4. Fall cinematics

When fighters fall into the void — **do not** instantly remove the body.

**Sequence:**

1. Loss of balance
2. Body sliding
3. Desperate movement
4. Delayed fall
5. Short freefall
6. Disappearance into darkness
7. Delayed impact sound **OR no impact at all**

Occasionally: **no sound** (unknown destination = stronger fear).

Optional: tiny distant particle flash after several seconds.

**Prototype:** `VOID_GORE` timeline in `void_gore_sequence.gd` — instability → fall → corruption → breakup → burst → score; silent absorption + distant flash chances in `game_balance.gd`.

---

### 5. Uncanny silhouettes

Inside darkness:

- Static humanoid shapes
- Motionless observers
- Figures below platforms
- Shapes **disappearing when looked at directly**

**Never fully reveal.** Silhouette > monster.

**Prototype:** `void_observer.tscn` — fades when player camera aligns.

---

### 6. Perception distortion

Impossible or wrong geometry:

- Platforms ending in void
- Floating architecture
- Broken gravity (future)
- Objects suspended without support
- Non-euclidean layouts (future levels)

World should feel **wrong**.

**Prototype:** Broken columns, hanging debris, bridge ends open to abyss.

---

### 7. Sound design

Void audio:

- Deep distant drones
- Wind without visible source
- Metallic resonance
- Long reverbs
- Low frequency rumbles
- Rare echoes

**Silence is allowed.** Never overfill audio.

**Prototype:** `void_audio.gd` placeholders — wire real assets in Phase 1.

---

### 8. Visual rules

**Palette:** dark greys · cold blues · muted steel · black voids · minimal warm colors

**Avoid:** bright saturation · cartoon effects · colorful particles

**Lighting:** directional · hard shadows · sparse highlights

**Rule:** darkness must **hide information**.

See [Visual Rules](VISUAL_RULES.md) for checklist.

---

### 9. Gameplay feeling

Combat serves the horror frame — readable knockback and scoring inside hostile space.

Void deaths and pit presence are **core mechanics**, not garnish.

---

## Visual Identity (summary)

Industrial catacomb meets infinite abyss: cold steel walkways, brutal shadows, living darkness below.

---

## Color Palette

| Role | Direction |
|------|-----------|
| Structure | Dark greys, muted steel |
| Void | Cold blue-black gradients |
| Light | Cool highlights, minimal warm |
| Gore | Stylized dark red / corruption energy |

---

## Lighting

- Directional key — Quake-like hard shadows on deck
- Sparse fill — pit never fully lit
- Abyss pulse — subtle, suggests life below

---

## Void Treatment

Layered fog, particles, no visible floor, gradient depth, corruption on death — see §2 and §4.

---

## Enemy Silhouettes

- Combat: readable humanoid on bridge
- Pit: observers only — peripheral, never full reveal in v1

---

## UI Visual Tone

Cold, minimal, stark void death copy. See [Gameplay](../gameplay/GAMEPLAY.md).

---

## WORLD LANGUAGE

VOID world identity is defined by **oppressive scale**, **abandoned purpose**, and architecture that feels **older than explanation**.

The player must never feel like the world was made for humans.

**The world dominates.**

**The player survives inside it.**

---

### 1. Architectural philosophy

#### Canonical identity

VOID architecture is a fusion of:

- **Brutalist megastructures**
- **Cosmic machinery**
- **Abandoned research architecture**
- **Void-corrupted constructions**

The world should feel as if an **impossible civilization** built structures to observe, contain, or communicate with the Void.

Their purpose is **lost**.

Only the **remains** exist.

#### Construction methods

Structures are:

- assembled from enormous modular masses
- layered vertically
- partially embedded into cliffs and abyss walls
- connected through suspended bridges and industrial systems
- interrupted by impossible openings and void fractures

Architecture should feel **manufactured** but **no longer understandable**.

#### Scale

Scale is intentionally **hostile**.

**Rules:**

- ceilings frequently disappear into darkness
- rooms exceed visibility distance
- bridges extend beyond visual confirmation
- towers dominate entire zones
- structures dwarf player scale

**Player must feel insignificant.**

#### Repetition language

World repetition language:

- repeated pillars
- endless support beams
- stacked slabs
- identical openings
- recurring void cuts
- repeating vertical masses

Repetition should create **unease**.

The environment feels constructed by **systems** rather than individuals.

#### Silhouette profile

Silhouettes favor:

- verticality
- monolithic blocks
- bridges
- hanging structures
- fractures
- suspended masses
- interrupted geometry

**Avoid soft outlines.**

Everything should **read from distance**.

#### Environmental rhythm

World cadence:

**compression → release → exposure → descent**

**Example:**

1. tight corridor
2. massive open abyss
3. bridge traversal
4. vertical fall
5. enclosed chamber
6. void interruption

The Void must **repeatedly break** architectural flow.

**Void openings interrupt structure.**

---

### 2. Material library

#### Primary materials

**Cold steel**

Used for: platforms, bridges, machinery, elevators, structural skeletons.

Visual traits: dark metallic finish, scratches, humidity, oil stains.

**Oxidized metal**

Used to imply age and abandonment.

Traits: rust, layered corrosion, surface pitting, color variation.

**Dark concrete**

Primary architectural mass material.

Traits: heavy, brutalist, cracked, water damaged, monolithic.

**Wet stone**

Used in ancient or exposed zones.

Traits: erosion, dark moisture, mineral streaks, cold reflections.

**Corroded surfaces**

Present everywhere.

**No surface should feel maintained.**

#### Secondary atmospherics

- Fog
- Dust
- Ash
- Black residue

Environmental particles should imply **decay** and **movement**.

#### Forbidden materials

**Never use:**

- clean surfaces
- bright colors
- cartoon materials
- perfect geometry
- polished futurism
- pristine environments

**VOID rejects cleanliness.**

---

### 3. World symbolism

History is communicated through recurring shapes.

**No text required.**

#### Triangles

**Meaning:** direction · warning · ascension · ritual geometry

#### Vertical fractures

**Meaning:** rupture · collapse · Void intrusion · world instability

#### Void circles

**Meaning:** observation · containment · portals · unknown intelligence

#### Broken halos

**Meaning:** fallen transcendence · failed protection · dead divinity

#### Observer shapes

Forms resembling: eyes · lenses · watching cavities · circular apertures.

**Purpose:** player should feel **watched**.

#### Massive openings

Large holes and impossible void cuts imply: absence · loss · consumption.

**The Void removed something.**

---

### 4. Visual landmarks

#### The Endless Bridge

- **Purpose:** ancient transit structure crossing abyss sectors
- **Visual identity:** extreme distance, fog disappearance, missing sections, support pillars vanishing into darkness
- **Emotional target:** exposure · insignificance · fear of crossing

#### The Observation Pit

- **Purpose:** unknown observation chamber
- **Visual identity:** perfect vertical shaft, layered platforms, void center, observer motifs
- **Emotional target:** being studied · paranoia · depth terror

#### The Hanging Monolith

- **Purpose:** unknown cosmic machine or relic
- **Visual identity:** massive suspended stone-metal body, chains, gravity-defying placement, void corruption
- **Emotional target:** awe · confusion · cosmic dread

#### The Broken Elevator

- **Purpose:** ancient vertical transport system
- **Visual identity:** collapsed shaft, moving debris, partial mechanisms, infinite descent feeling
- **Emotional target:** fall anxiety · mechanical death · loss of safety

#### The Abyss Chamber

- **Purpose:** containment site
- **Visual identity:** circular chamber, central void opening, layered rings, dark depth
- **Emotional target:** void attraction · kenophobia · existential fear

#### The Silent Tower

- **Purpose:** observation / transmission structure
- **Visual identity:** isolated vertical mass, visible from multiple levels, black silhouette, minimal detail
- **Emotional target:** destination uncertainty · loneliness · oppression

---

### 5. Environment storytelling

**History must be inferred.**

**Avoid exposition.**

Player discovers civilization **visually**.

**Methods:**

- collapsed pathways
- abandoned machinery
- ruptured chambers
- interrupted architecture
- unfinished construction
- corruption spread
- environmental scars

**Nothing explicitly explains what happened.**

The player **reconstructs history through space**.

---

### References

Quake · industrial decay · cosmic emptiness · brutalist horror · liminal spaces · perceptual horror · architectural insignificance · void psychology

---

## Related

- [Visual Rules](VISUAL_RULES.md)
- [Moodboard](MOODBOARD.md)
- [Audio](../audio/AUDIO.md)
- [Level Design](../levels/LEVEL_DESIGN.md)
- [Prototype](../PROTOTYPE.md) — numeric tuning
