## First-person push weapon — spawns visible push projectiles on shoot.
extends MeshInstance3D

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/weapons/push_projectile.tscn")

## Seconds between shots.
@export var fire_cooldown: float = 0.25
## Spawn offset from the camera along the look axis (avoids clipping the player).
@export var spawn_forward_offset: float = 0.6

@onready var _camera: Camera3D = get_parent() as Camera3D

var _cooldown_remaining: float = 0.0


func _physics_process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("shoot"):
		return
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	if _cooldown_remaining > 0.0:
		return
	_fire_projectile()
	_cooldown_remaining = fire_cooldown


func _fire_projectile() -> void:
	var direction := -_camera.global_transform.basis.z.normalized()
	# Camera-center spawn, nudged forward so the projectile clears the player.
	var spawn_pos := _camera.global_position + direction * spawn_forward_offset

	var projectile: Area3D = PROJECTILE_SCENE.instantiate() as Area3D
	get_tree().current_scene.add_child(projectile)
	projectile.launch(spawn_pos, direction)
