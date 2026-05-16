# Retro FPS Prototype

Godot 4 first-person prototype with WASD movement, mouse look, jump, sprint, and gravity. The main scene is tuned for a **dark, Quake-like floating platform** above a void.

## Scene hierarchy

```
Main (Node3D)
├── WorldEnvironment     — void sky, low ambient, subtle fog
├── SunLight             — DirectionalLight3D (key sun)
├── Floor                — walkable platform (dark material)
│   └── StaticBody3D / CollisionShape3D
├── PlatformBorder       — thin rim meshes on four sides
├── TestCube             — shadow / lighting reference prop
├── PushBox1 / PushBox2 / PushBox3 — pushable `RigidBody3D` cubes
└── Player               — `scripts/player.gd`
    ├── Camera3D
    │   └── PushWeapon   — `scripts/push_weapon.gd` (spawns push projectile)
    └── CollisionShape3D
```

## Lighting setup

### SunLight (`DirectionalLight3D`)

Single harsh key light, similar to outdoor Quake maps:

| Property | Value | Notes |
|----------|-------|--------|
| `light_energy` | `3.0` | Strong enough to read the platform; rest of the scene stays dark |
| `light_negative` | `false` | Normal additive lighting (default) |
| `shadow_enabled` | `true` | Platform, TestCube, and player cast readable shadows |
| Rotation (degrees) | X `-60`, Y `0`, Z `0` | Angled sun; shallow shadows across the floor |

The light is placed high above the play area so its direction matches a late-afternoon sun.

### WorldEnvironment

Configured on the `Environment` resource attached to `WorldEnvironment`:

| Setting | Purpose |
|---------|---------|
| `background_mode = Color` | Solid void instead of a skybox |
| `background_color` | Near-black blue `(0.015, 0.02, 0.045)` — reads as empty space below the platform |
| `ambient_light_source = Color` | Low fill so unlit faces are not pure black |
| `ambient_light_energy = 0.25` | Subtle; does not flatten the sun contrast |
| `fog_enabled` | `true` |
| `fog_mode = Exponential` | Simple distance fade into the void |
| `fog_density = 0.018` | Gentle; distant edges soften without hiding the platform |

Together, dark background + fog + low ambient make the **20×20 floor** feel like a slab floating over nothing. Look over the **PlatformBorder** rim or jump off the edge to sell the void.

### Platform materials

- **Floor** — dark gray-brown `StandardMaterial3D`, high roughness (stone-like top).
- **PlatformBorder** — four thin box strips along the perimeter, darker than the floor, slightly raised for a visible edge. No walls.

### TestCube

`MeshInstance3D` at `(0, 1, -5)`, scale `(1, 2, 1)`, neutral tan material. Use it to check sun angle, shadow direction, and fog falloff when tuning the scene.

## Push weapon

`PushWeapon` is a small viewmodel mesh parented to `Camera3D` (lower-right of the view). `scripts/push_weapon.gd` spawns `scenes/weapons/push_projectile.tscn` on **shoot**:

| Setting | Default | Description |
|---------|---------|-------------|
| `fire_cooldown` | `0.25` | Minimum seconds between shots |
| `spawn_forward_offset` | `0.6` | Spawn distance in front of the camera |

Projectile scene: `scenes/weapons/push_projectile.tscn` (`Area3D` + sphere mesh). Script `scripts/push_projectile.gd`:

| Setting | Default | Description |
|---------|---------|-------------|
| `speed` | `35` | Forward travel speed |
| `lifetime` | `3` | Auto-despawn after seconds |
| `push_force` | `18` | Impulse on `RigidBody3D` hit |

The projectile moves along the camera look direction. On **RigidBody3D** contact it applies an impulse in its travel direction, prints debug info, and is destroyed. Any other body destroys it without pushing. No damage.

**PushBox1–3** are colored 1 m cubes on the platform ahead of spawn for testing pushes.

## Controls

| Input | Action |
|-------|--------|
| W / A / S / D | Move |
| Mouse | Look (when captured) |
| Space | Jump |
| Shift | Sprint |
| Left click | Fire push projectile (when mouse captured) |
| Esc | Release mouse |
| Left click | Re-capture mouse (when cursor visible) |

## Run

Open the project in Godot 4.6+ and press **F5**. Main scene: `res://scenes/main.tscn`.

## Tuning tips

- Increase `fog_density` slightly if the void still feels too “empty room.”
- Lower `ambient_light_energy` for more contrast; raise it if gameplay areas are too hard to read.
- Adjust `SunLight` `light_energy` or rotation in small steps — large changes quickly break the retro look.
