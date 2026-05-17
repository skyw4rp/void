## Shared weapon ids, names, and combat stats for player and enemy.
class_name WeaponDefs
extends RefCounted

enum Id { PISTOL, SHOTGUN, BAZOOKA }

const NAMES: Array[String] = ["Pistol", "Shotgun", "Bazooka"]

const STATS: Dictionary = {
	Id.PISTOL: {
		"cooldown": 0.15,
		"pellets": 1,
		"spread": 0.0,
		"projectile": {
			"speed": 50.0,
			"push_force": 8.0,
			"lifetime": 2.5,
			"mesh_scale": 0.08,
			"color": Color(0.75, 0.85, 1.0),
		},
	},
	Id.SHOTGUN: {
		"cooldown": 0.75,
		"pellets": 7,
		"spread": 0.14,
		"projectile": {
			"speed": 38.0,
			"push_force": 14.0,
			"lifetime": 1.8,
			"mesh_scale": 0.07,
			"color": Color(1.0, 0.75, 0.35),
		},
	},
	Id.BAZOOKA: {
		"cooldown": 1.25,
		"pellets": 1,
		"spread": 0.0,
		"use_bazooka_scene": true,
	},
}


static func get_data(weapon: Id) -> Dictionary:
	return STATS[weapon]


static func get_name(weapon: Id) -> String:
	return NAMES[weapon]
