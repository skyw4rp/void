# Retro FPS Prototype

Godot 4 first-person prototype with WASD movement, mouse look, jump, sprint, and gravity.

## Scene hierarchy

```
Main (Node3D)
├── Floor (MeshInstance3D) — BoxMesh, scale 20 × 0.2 × 20
│   └── StaticBody3D / CollisionShape3D (required for walkable physics)
└── Player (CharacterBody3D) — `scripts/player.gd`
    ├── Camera3D — eye height 1.6 m
    └── CollisionShape3D — capsule
```

Add a **DirectionalLight3D** under `Main` in the editor if the play scene looks too dark.

## Controls

| Input | Action |
|-------|--------|
| W / A / S / D | Move |
| Mouse | Look (when captured) |
| Space | Jump |
| Shift | Sprint |
| Esc | Release mouse |
| Left click | Re-capture mouse |

## Run

Open the project in Godot 4.6+ and press **F5**, or set `scenes/main.tscn` as the main scene (already configured in `project.godot`).
