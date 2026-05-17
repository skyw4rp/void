## Shared weapon ids, names, and combat stats for player and enemy.
## Tune push_force / explosion_force here — all fighters use these values.
class_name WeaponDefs
extends RefCounted

enum Id { RAILGUN, SHOTGUN, BAZOOKA }

const NAMES: Array[String] = ["Railgun", "Shotgun", "Bazooka"]

## Shared knockback tuning — player velocity vs RigidBody3D impulse.
const PLAYER_KNOCKBACK_MULTIPLIER: float = 1.6
const RIGIDBODY_KNOCKBACK_MULTIPLIER: float = 0.6
const GROUNDED_UPWARD_KNOCKBACK_FACTOR: float = 0.10
const AIRBORNE_UPWARD_KNOCKBACK_FACTOR: float = 0.025
const PLAYER_MAX_UPWARD_VELOCITY: float = 22.0
const PLAYER_MAX_DOWNWARD_VELOCITY: float = -30.0
const PLAYER_MAX_HORIZONTAL_KNOCKBACK_GROUNDED: float = 45.0
const PLAYER_MAX_HORIZONTAL_KNOCKBACK_AIRBORNE: float = 32.0
## Only the first pellet in a burst adds vertical lift within this window (seconds).
const SHOTGUN_VERTICAL_LIFT_WINDOW_SEC: float = 0.1
## Legacy alias
const UPWARD_KNOCKBACK_FACTOR: float = GROUNDED_UPWARD_KNOCKBACK_FACTOR
const PLAYER_MAX_KNOCKBACK_SPEED: float = PLAYER_MAX_HORIZONTAL_KNOCKBACK_GROUNDED

## Bazooka explosion — mostly horizontal ring-out, capped vertical lift.
const EXPLOSION_VERTICAL_FACTOR: float = 0.18
const EXPLOSION_MAX_UPWARD_FORCE: float = 18.0
const EXPLOSION_MAX_DOWNWARD_FORCE: float = 8.0
const PLAYER_EXPLOSION_MIN_VERTICAL_VELOCITY: float = -25.0
const PLAYER_EXPLOSION_MAX_VERTICAL_VELOCITY: float = 22.0
## Direct bazooka hit — some lift, not a sky launch.
const PROJECTILE_HIT_VERTICAL_FACTOR: float = 0.22
## Railgun — precision knockback, minimal lift.
const RAILGUN_VERTICAL_FACTOR: float = 0.06

const DEFAULT_MAX_HEALTH: int = 100
const DEFAULT_MAX_SHIELD: int = 100

const STATS: Dictionary = {
	Id.RAILGUN: {
		"cooldown": 0.95,
		"use_railgun_ray": true,
		"railgun": {
			"range": 120.0,
			"damage": 100,
			"push_force": 68.0,
			"damage_source": "railgun",
			"beam_color": Color(0.72, 0.55, 1.0, 0.95),
			"beam_emission": Color(0.45, 0.25, 0.95, 1.0),
		},
	},
	Id.SHOTGUN: {
		"cooldown": 0.75,
		"pellets": 7,
		"spread": 0.14,
		"projectile": {
			"speed": 38.0,
			"push_force": 30.0,
			"damage": 10,
			"damage_source": "shotgun",
			"lifetime": 1.8,
			"mesh_scale": 0.12,
			"hit_radius": 0.115,
			"emission_energy": 0.9,
			"color": Color(1.0, 0.75, 0.35),
		},
	},
	Id.BAZOOKA: {
		"cooldown": 1.4,
		"pellets": 1,
		"spread": 0.0,
		"use_bazooka_scene": true,
		"bazooka": {
			"speed": 22.0,
			"lifetime": 4.0,
			"push_force": 58.0,
			"direct_damage": 100,
			"explosion_damage": 60,
			"explosion_radius": 5.0,
			"explosion_force": 82.0,
		},
	},
}


static func get_data(weapon: Id) -> Dictionary:
	return STATS[weapon]


static func get_weapon_name(weapon: Id) -> String:
	return NAMES[weapon]


static func explosion_damage_at_distance(
	max_damage: int, origin: Vector3, target_position: Vector3, radius: float
) -> int:
	var distance: float = origin.distance_to(target_position)
	var falloff: float = 1.0 - clampf(distance / radius, 0.0, 1.0)
	return int(round(float(max_damage) * falloff))
