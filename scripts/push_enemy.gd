## Simple pushable enemy — chases the player and is removed when it falls into the void.
extends RigidBody3D

@export var move_force: float = 8.0
@export var max_speed: float = 4.0
@export var void_y: float = -20.0
## Reserved for future wave spawns; when false, void fall removes the enemy.
@export var respawn_on_void: bool = false

var _player: Node3D


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node3D


func _physics_process(_delta: float) -> void:
	if global_position.y < void_y:
		print("Enemy fell into the void")
		queue_free()
		return

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
		return

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.05:
		return

	apply_central_force(to_player.normalized() * move_force)

	var vel := linear_velocity
	var horizontal := Vector3(vel.x, 0.0, vel.z)
	if horizontal.length() > max_speed:
		horizontal = horizontal.normalized() * max_speed
		linear_velocity = Vector3(horizontal.x, vel.y, horizontal.z)
