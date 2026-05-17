## Spawns destructible cover on validated floor in the active arena.
extends Node3D

const COVER_SCENE: PackedScene = preload("res://scenes/props/debris_chunk.tscn")

const COUNT_MIN: int = 5
const COUNT_MAX: int = 9
const MAX_CENTER_LANE_PIECES: int = 1
const CENTER_LANE_HALF_WIDTH: float = 1.2

const COVER_TYPES: Array = [
	DebrisChunk.CoverType.BLOCK,
	DebrisChunk.CoverType.WALL_SLAB,
	DebrisChunk.CoverType.BROKEN_PILLAR,
	DebrisChunk.CoverType.FALLEN_BEAM,
]


func _ready() -> void:
	add_to_group("debris_spawner")


func clear_debris() -> void:
	for node in get_tree().get_nodes_in_group("round_debris"):
		if node is Node:
			(node as Node).queue_free()
	for node in get_tree().get_nodes_in_group("round_debris_fragment"):
		if node is Node:
			(node as Node).queue_free()


func spawn_round_debris_for_generator(generator: ArenaGenerator) -> void:
	if generator == null:
		return
	clear_debris()

	var player_spawn: Vector3 = generator.get_player_spawn_position()
	var enemy_spawn: Vector3 = generator.get_enemy_spawn_position()
	var arena_center: Vector3 = generator.get_current_arena_center()
	var count: int = randi_range(COUNT_MIN, COUNT_MAX)
	var placed_xz: Array[Vector2] = []
	var center_lane_count: int = 0
	var spawned: int = 0

	for _i in count:
		var cover_type: DebrisChunk.CoverType = COVER_TYPES.pick_random()
		var pos: Vector3 = generator.pick_valid_debris_position(
			player_spawn, enemy_spawn, placed_xz
		)
		if pos == Vector3.INF:
			continue

		if generator.has_method("is_near_main_route") and generator.is_near_main_route(pos, 2.4):
			continue

		var local_x: float = pos.x - arena_center.x
		var xz := Vector2(pos.x, pos.z)
		placed_xz.append(xz)
		if absf(local_x) < CENTER_LANE_HALF_WIDTH:
			center_lane_count += 1

		var cover: RigidBody3D = COVER_SCENE.instantiate() as RigidBody3D
		add_child(cover)
		cover.global_position = pos
		if cover.has_method("setup_cover"):
			cover.call("setup_cover", cover_type)
		spawned += 1

	print(
		"Spawned %d destructible cover pieces in %s"
		% [spawned, generator.get_arena_name()]
	)
