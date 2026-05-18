## First-person walker for Gladiator Chamber (no combat).
extends CharacterBody3D

const WALK_SPEED: float = 5.2
const MOUSE_SENS: float = 0.002
const LOOK_PITCH_MIN: float = -1.2
const LOOK_PITCH_MAX: float = 1.2

@onready var camera: Camera3D = $Camera3D
@onready var _pitch_pivot: Node3D = $Camera3D

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	add_to_group("chamber_player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		_pitch_pivot.rotation.x = clampf(
			_pitch_pivot.rotation.x - event.relative.y * MOUSE_SENS,
			LOOK_PITCH_MIN,
			LOOK_PITCH_MAX
		)
	if event.is_action_pressed("interact"):
		_try_interact_nearby()
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	if wish.length_squared() > 0.01:
		velocity.x = wish.x * WALK_SPEED
		velocity.z = wish.z * WALK_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * 4.0 * delta)
	move_and_slide()


func _try_interact_nearby() -> void:
	for node in get_tree().get_nodes_in_group("chamber_interactable"):
		if node is ChamberInteractable:
			var interact: ChamberInteractable = node as ChamberInteractable
			if interact.try_interact(self):
				return
