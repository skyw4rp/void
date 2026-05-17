## Combat zone marker — spawns, AI bounds, and debris area for one mini-arena.
class_name ArenaZone
extends Node3D

@export var display_name: String = "Pit Bridge Arena"
@export var arena_id: String = "pit_bridge"

@export_group("AI bounds")
@export var safe_half_x: float = 3.2
@export var danger_half_x: float = 3.8
@export var safe_half_z: float = 12.0
@export var danger_half_z: float = 13.5

@export_group("Debris spawn (local offset from arena root)")
@export var debris_x_min: float = -2.6
@export var debris_x_max: float = 2.6
@export var debris_z_min: float = -5.5
@export var debris_z_max: float = 5.5

@onready var _geometry: Node3D = $ArenaGeometry
@onready var _player_spawn: Marker3D = $PlayerSpawn
@onready var _enemy_spawn: Marker3D = $EnemySpawn


func _ready() -> void:
	add_to_group("arena_zone")


func get_center() -> Vector3:
	return global_position


func get_player_spawn_transform() -> Transform3D:
	return _player_spawn.global_transform


func get_enemy_spawn_transform() -> Transform3D:
	return _enemy_spawn.global_transform


func get_player_spawn_position() -> Vector3:
	return _player_spawn.global_position


func get_enemy_spawn_position() -> Vector3:
	return _enemy_spawn.global_position


func set_arena_visible(show_geometry: bool) -> void:
	if _geometry:
		_geometry.visible = show_geometry
		_set_arena_physics_active(show_geometry)


func _set_arena_physics_active(active: bool) -> void:
	if _geometry == null:
		return
	var layer: int = 1 if active else 0
	for body in _geometry.find_children("*", "StaticBody3D", true, false):
		if body is StaticBody3D:
			(body as StaticBody3D).collision_layer = layer
			(body as StaticBody3D).collision_mask = layer


func apply_bounds_to(opponent: Node) -> void:
	if opponent.has_method("apply_arena_bounds"):
		opponent.call("apply_arena_bounds", self)


func get_debris_local_rect() -> Dictionary:
	return {
		"x_min": debris_x_min,
		"x_max": debris_x_max,
		"z_min": debris_z_min,
		"z_max": debris_z_max,
	}
