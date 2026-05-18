# VOID — Design Philosophy

**VOID** is a psychological brutalist FPS: Quake-era physical responsiveness inside oppressive megastructures and an indifferent void. It is **not** a military sim, **not** tactical cover combat, and **not** realism-first.

**Related:** [Art Direction](art/ART_DIRECTION.md) · [Prototype Audit](VOID_PROTOTYPE_AUDIT.md) · [Prototype](PROTOTYPE.md)

---

## North star

The player should feel **grounded, heavy, fast, and mechanically connected** — while the world feels **ancient, impossible, hostile, and larger than comprehension**.

The void is often more important than any enemy.

---

## Core game feel

### Movement (Quake spirit)

- Immediate input response
- Acceleration-based motion with controlled friction
- Momentum preservation and responsive strafing
- Aggressive but controllable speed

**Reject:** floaty motion, input delay, animation-locked movement, over-smoothing, cinematic control loss.

**Player control always wins over realism.**

### Camera

The camera is attached to a body, not a floating spectator.

- Subtle head motion, landing impact, directional sway, controlled weapon bob
- Kinetic feedback without disconnecting aim

**Reject:** excessive smoothing, artificial look lag, unstable rotation stacks.

**Mouse look:** precise, raw, trustworthy — never trade aiming clarity for effects.

### Combat

Combat is **spatial rhythm**: movement defends, positioning survives, momentum creates tension.

- Aggressive, dangerous, pressuring, kinetic encounters
- Readable weapons and hit feedback at arena speed

**Reject:** static cover loops, passive pacing, heavy realism layers that slow reads.

### Enemies

Readability over realism. The player must instantly know:

- where the enemy faces and aims
- which weapon is active
- threat direction and attack intent

Strong silhouettes, forward-projecting weapons, clear torso orientation.

**Reject:** noisy silhouettes, ambiguous aim, overcomplicated rigs.

### World & void

Architecture **dominates** the player: brutalist scale, fractured repetition, vertical shafts, endless bridges, negative space.

Procedural arenas use a **continuous deck** with **indestructible maze walls** that define lanes, pockets, and flank routes; **destructible cover** only adds temporary combat variation around that skeleton — never the whole layout.

The void is **infinite, silent, indifferent, hungry** — large emptiness and distance are intentional.

**Reject:** clean surfaces, saturated palette, decorative darkness without depth.

---

## Visual language

**Prioritize:** silhouette, contrast, scale, fog, shadow depth, oxidized metal, wet concrete, corrosion, ash.

**Forbidden:** clean sci-fi panels, bright saturation, cartoon styling, visual noise that breaks reads.

Lighting should **isolate, obscure, imply scale, and guide attention** — darkness must read as volume.

---

## Technical direction

- Modular systems, maintainable code, simple robust logic
- Gameplay feel > simulation accuracy
- Central tuning (`GameBalance`, movement exports) over scattered one-offs

---

## Reference DNA (not imitation)

Quake · Quake III Arena · Dusk · NaissanceE · Scorn · brutalist / industrial cosmic horror.

**VOID identity:** *psychological brutalist void horror FPS* — perceptual tension and existential insignificance, with arena-grade responsiveness.

---

## Decision gate

Before shipping any gameplay, visual, audio, movement, combat, or level change, ask:

> **Does this increase physical presence, oppressive atmosphere, existential scale, and perceptual tension?**

If not → remove or redesign.

Implementation gaps and fix priorities: **[VOID_PROTOTYPE_AUDIT.md](VOID_PROTOTYPE_AUDIT.md)**.
