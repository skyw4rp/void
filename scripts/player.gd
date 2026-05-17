## First-person CharacterBody3D controller for the 1v1 arena prototype.
extends CharacterBody3D

const WALK_SPEED: float = 5.0
const SPRINT_SPEED: float = 9.0
const JUMP_VELOCITY: float = 4.5
const MOUSE_SENSITIVITY: float = 0.002

const LOOK_PITCH_MIN: float = -1.4
const LOOK_PITCH_MAX: float = 1.4

@onready var camera: Camera3D = $Camera3D

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _spawn_position: Vector3 = Vector3.ZERO
var _void_y: float = -20.0
var _void_reported: bool = false
var _game_manager: Node


func _ready() -> void:
	add_to_group("player")
	_game_manager = get_tree().get_first_node_in_group("game_manager")
	if _game_manager:
		_void_y = _game_manager.get_void_y()
		_spawn_position = _game_manager.get_player_spawn()
	else:
		_spawn_position = global_position
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func arena_respawn(spawn_position: Vector3) -> void:
	_spawn_position = spawn_position
	global_position = spawn_position
	velocity = Vector3.ZERO
	_void_reported = false
	# TODO: camera shake or screen flash on respawn.


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	if event.is_action_pressed("shoot") and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			return
		var motion := event as InputEventMouseMotion
		rotate_y(-motion.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-motion.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clampf(camera.rotation.x, LOOK_PITCH_MIN, LOOK_PITCH_MAX)


func _physics_process(delta: float) -> void:
	if _game_manager and not _game_manager.is_round_active():
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	if direction.is_zero_approx():
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)
	else:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

	move_and_slide()

	if global_position.y < _void_y:
		_report_void_fall()


func _report_void_fall() -> void:
	if _void_reported:
		return
	_void_reported = true
	if _game_manager and _game_manager.has_method("report_player_fell"):
		_game_manager.report_player_fell()
