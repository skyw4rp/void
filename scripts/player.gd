## First-person CharacterBody3D controller for the retro FPS prototype.
## Handles WASD movement, mouse look, jump, sprint, gravity, and mouse capture.
extends CharacterBody3D

# --- Movement tuning ---
const WALK_SPEED: float = 5.0
const SPRINT_SPEED: float = 9.0
const JUMP_VELOCITY: float = 4.5
const MOUSE_SENSITIVITY: float = 0.002

# Vertical look clamp (radians)
const LOOK_PITCH_MIN: float = -1.4
const LOOK_PITCH_MAX: float = 1.4

@onready var camera: Camera3D = $Camera3D

## Uses the project default gravity unless overridden in Project Settings.
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	# Start with the mouse captured for FPS controls.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	# ESC releases the mouse so menus or the OS cursor are usable.
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	# Click again to re-capture (common FPS quality-of-life).
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			return
		var motion := event as InputEventMouseMotion
		# Yaw on the body; pitch on the camera only.
		rotate_y(-motion.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-motion.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clampf(camera.rotation.x, LOOK_PITCH_MIN, LOOK_PITCH_MAX)


func _physics_process(delta: float) -> void:
	# Apply gravity when airborne.
	if not is_on_floor():
		velocity.y -= _gravity * delta

	# Jump on Space while grounded.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Build a horizontal move vector from WASD (camera-relative).
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
