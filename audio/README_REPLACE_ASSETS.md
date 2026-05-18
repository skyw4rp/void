# VOID — Audio asset replacement guide

The game ships with **procedural placeholder** sounds generated at runtime by `scripts/audio/audio_stream_factory.gd`.  
Drop real `.ogg` files at the paths below to override placeholders automatically (no code change).

## Void

| File | Purpose |
|------|---------|
| `res://audio/void/void_drone_loop.ogg` | Continuous abyss ambience |
| `res://audio/void/void_proximity_loop.ogg` | Edge / fall proximity bed |
| `res://audio/void/void_wind.ogg` | Random gust one-shot |
| `res://audio/void/void_rumble.ogg` | Rare abyss rumble |
| `res://audio/void/void_danger_pulse.ogg` | Depth / edge danger pulse |
| `res://audio/void/void_fall_rush.ogg` | Falling into gas |
| `res://audio/void/body_rupture.ogg` | Void gore breakup |
| `res://audio/void/disintegration_burst.ogg` | Final void burst |
| `res://audio/void/distant_impact.ogg` | Delayed absorption echo |
| `res://audio/void/metallic_resonance.ogg` | Bridge / structure tremor |

## Combat

| File | Purpose |
|------|---------|
| `res://audio/combat/railgun_fire.ogg` | Railgun shot |
| `res://audio/combat/shotgun_fire.ogg` | Shotgun blast |
| `res://audio/combat/bazooka_fire.ogg` | Bazooka launch |
| `res://audio/combat/hit_shield.ogg` | Shield hit confirm |
| `res://audio/combat/hit_health.ogg` | Health hit confirm |
| `res://audio/combat/hit_wall.ogg` | Cover / wall impact |
| `res://audio/combat/fighter_hurt.ogg` | Fighter hurt layer |

## Mix

Director autoload: `VoidAudio` (`scripts/environment/void_audio.gd`).  
Tune `master_volume_db`, `void_ambience_volume_db`, `combat_volume_db` on the autoload root in the editor.

Recommended: route buses `Void`, `Combat`, `UI` in a later pass (not required for P0).
