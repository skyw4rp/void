# Retro FPS Prototype

Godot 4 first-person prototype with WASD movement, mouse look, jump, sprint, gravity, and a **multi-weapon push system** on a dark floating platform.

## Scene hierarchy

```
Main (Node3D)
├── WorldEnvironment / SunLight
├── Floor + PlatformBorder
├── TestCube
├── PushBox1–3
├── Enemy1–3
├── UI / WeaponLabel          — current weapon HUD
└── Player (group: player)
    ├── Camera3D
    │   └── WeaponManager     — `scenes/weapons/weapon_manager.tscn`
    └── CollisionShape3D
```

## Weapons

Managed by `scripts/weapons/weapon_manager.gd` on the camera. Three viewmodels (only one visible at a time): gray **Pistol**, brown **Shotgun**, orange **Bazooka**.

| Key | Weapon | Fire rate | Behavior |
|-----|--------|-----------|----------|
| **1** | Pistol | Fast (0.15s) | Single small fast projectile, low push (8) |
| **2** | Shotgun | Slow (0.75s) | 7 pellets with spread, medium push (14) |
| **3** | Bazooka | Slowest (1.25s) | Large slow rocket; direct hit + **explosion** (radius 5, force 35) |

**Left click** fires the active weapon (mouse must be captured). Switching weapons prints `Weapon: <name>` to the Output. HUD label shows `Weapon: Pistol` etc.

### Projectiles

- `scenes/weapons/push_projectile.tscn` — pistol & shotgun pellets (`scripts/weapons/push_projectile.gd`)
- `scenes/weapons/bazooka_projectile.tscn` — large red sphere (`scripts/weapons/bazooka_projectile.gd`)
- `scripts/weapons/push_explosion.gd` — sphere overlap query, outward impulse on `RigidBody3D`, debug prints

All weapons push **PushBox** crates and **PushEnemy** capsules (no damage). Enemies chase the player; void fall removes them.

## Push enemies

Scene: `scenes/enemies/push_enemy.tscn`. Chase via group `player`. Removed at Y &lt; -20 with `Enemy fell into the void`.

## Void death and respawn

Player respawns at start position below Y = -20. Message: `Player fell into the void. Respawning.`

## Controls

| Input | Action |
|-------|--------|
| W / A / S / D | Move |
| Mouse | Look (when captured) |
| Space | Jump |
| Shift | Sprint |
| **1 / 2 / 3** | Pistol / Shotgun / Bazooka |
| **Left click** | Fire weapon (when mouse captured) |
| Esc | Release mouse |
| Left click | Re-capture mouse (when cursor visible) |

## Run

Open in Godot 4.6+ and press **F5**. Main scene: `res://scenes/main.tscn`.

## File layout

```
scripts/weapons/   weapon_manager, push_projectile, bazooka_projectile, push_explosion, weapon_hud
scenes/weapons/    weapon_manager, push_projectile, bazooka_projectile
```

## Tuning tips

- Weapon stats live in `weapon_manager.gd` `_stats` dictionary.
- Bazooka explosion: `explosion_radius` / `explosion_force` on `bazooka_projectile.tscn`.
- Adjust `fog_density` or `SunLight` energy for atmosphere.
