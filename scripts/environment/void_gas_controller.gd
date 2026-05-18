## Drives world fog, screen FX, and void atmosphere from fall depth (toxic gas ocean).
class_name VoidGasController
extends Node

@export var world_environment_path: NodePath = ^"../WorldEnvironment"

var _world_env: WorldEnvironment
var _saved_env: Environment
var _track_node: Node3D
var _falling: bool = false
var _last_depth_t: float = 0.0
var _ui: CanvasLayer
var _atmosphere: Node
var _distant_arch: Node3D
var _player_camera: Camera3D
var _base_cam_attrs: CameraAttributes


func _ready() -> void:
	add_to_group("void_gas_controller")
	_world_env = get_node_or_null(world_environment_path) as WorldEnvironment
	if _world_env and _world_env.environment:
		_saved_env = _world_env.environment.duplicate()
	call_deferred("_bind_scene_refs")


func _bind_scene_refs() -> void:
	_ui = get_tree().get_first_node_in_group("arena_ui") as CanvasLayer
	_atmosphere = get_tree().get_first_node_in_group("void_atmosphere")
	_distant_arch = get_tree().get_first_node_in_group("void_distant_architecture") as Node3D
	var player: Node = get_tree().get_first_node_in_group("player")
	if player and player.has_node("Camera3D"):
		_player_camera = player.get_node("Camera3D") as Camera3D


func set_fall_tracking(node: Node3D, active: bool) -> void:
	_track_node = node
	_falling = active
	if not active:
		_restore_arena_atmosphere()


func _process(_delta: float) -> void:
	var sample_y: float = _get_sample_y()
	var depth_t: float = GameBalance.void_fog_depth_t(sample_y)
	_last_depth_t = depth_t

	var edge_t: float = 0.0
	if _player_camera:
		edge_t = VoidAudio.compute_edge_proximity(_player_camera.global_position)

	if not _falling and sample_y >= GameBalance.VOID_FOG_ARENA_CLEAR_Y:
		if _last_depth_t > 0.001:
			_restore_arena_atmosphere()
		_last_depth_t = 0.0
		VoidAudio.update_void_proximity(0.0, sample_y, false, edge_t)
		CombatVfxDirector.apply_edge_tension(edge_t, false)
		if edge_t > 0.02:
			_apply_edge_fog_pulse(edge_t)
		else:
			_clear_edge_fog_pulse()
		return

	_apply_environment_sample(depth_t, sample_y)
	_apply_screen_fx(depth_t)
	_apply_camera_fx(depth_t)

	if _atmosphere and _atmosphere.has_method("apply_depth_sample"):
		_atmosphere.call("apply_depth_sample", depth_t, sample_y, _get_anchor_position())

	if _distant_arch and _distant_arch.has_method("apply_depth_fade"):
		_distant_arch.call("apply_depth_fade", depth_t, sample_y)

	VoidAudio.update_void_proximity(depth_t, sample_y, _falling, edge_t)
	CombatVfxDirector.apply_edge_tension(edge_t, _falling)
	if not _falling and edge_t > 0.02:
		_apply_edge_fog_pulse(edge_t)
	elif not _falling:
		_clear_edge_fog_pulse()


func get_last_depth_t() -> float:
	return _last_depth_t


func _get_sample_y() -> float:
	if _falling and _track_node and is_instance_valid(_track_node):
		if _player_camera and is_instance_valid(_player_camera):
			return _player_camera.global_position.y
		return (_track_node as Node3D).global_position.y
	if _player_camera and is_instance_valid(_player_camera):
		return _player_camera.global_position.y
	return 4.0


func _get_anchor_position() -> Vector3:
	if _track_node and is_instance_valid(_track_node):
		return (_track_node as Node3D).global_position
	if _player_camera:
		return _player_camera.global_position
	return Vector3.ZERO


func _apply_environment_sample(depth_t: float, world_y: float) -> void:
	if _world_env == null or _saved_env == null:
		return
	var env: Environment = _world_env.environment
	if env == null:
		return

	env.fog_enabled = true
	env.fog_light_color = GameBalance.void_fog_color(world_y)
	env.fog_density = GameBalance.void_fog_density(world_y)

	if depth_t > 0.35:
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_depth_begin = lerpf(0.0, 0.2, depth_t)
		env.fog_depth_end = GameBalance.void_fog_depth_end(world_y)
	else:
		env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
		env.fog_depth_end = GameBalance.VOID_FOG_DEPTH_END_ARENA

	env.adjustment_enabled = depth_t > 0.25
	env.adjustment_saturation = lerpf(1.0, 0.22, depth_t)
	env.adjustment_brightness = lerpf(1.0, 0.72, depth_t * 0.85)
	env.ambient_light_energy = lerpf(_saved_env.ambient_light_energy, 0.06, depth_t)
	env.ambient_light_color = _saved_env.ambient_light_color.lerp(
		Color(0.04, 0.08, 0.06), depth_t
	)


func _apply_screen_fx(depth_t: float) -> void:
	if _ui and _ui.has_method("apply_void_gas_screen"):
		_ui.call("apply_void_gas_screen", depth_t, _falling)


func _apply_camera_fx(depth_t: float) -> void:
	if _player_camera == null or not _falling:
		return
	if _player_camera.attributes == null:
		var attrs := CameraAttributesPractical.new()
		_player_camera.attributes = attrs
	var practical: CameraAttributesPractical = _player_camera.attributes as CameraAttributesPractical
	if practical == null:
		return
	practical.dof_blur_far_enabled = depth_t > 0.2
	practical.dof_blur_far_distance = lerpf(48.0, 1.6, depth_t)
	practical.dof_blur_amount = lerpf(0.0, 0.72, depth_t)


func _clear_edge_fog_pulse() -> void:
	if _world_env == null or _saved_env == null:
		return
	var env: Environment = _world_env.environment
	if env == null:
		return
	env.fog_density = _saved_env.fog_density
	env.adjustment_enabled = _saved_env.adjustment_enabled
	env.adjustment_saturation = _saved_env.adjustment_saturation


func _apply_edge_fog_pulse(edge_t: float) -> void:
	if _world_env == null or _saved_env == null:
		return
	var env: Environment = _world_env.environment
	if env == null:
		return
	var director: Node = get_tree().get_first_node_in_group("combat_vfx_director")
	var strength: float = 0.85
	if director and "void_edge_strength" in director:
		strength = float(director.void_edge_strength)
	if director and "vfx_intensity" in director:
		strength *= float(director.vfx_intensity)
	env.fog_density = _saved_env.fog_density + edge_t * 0.0035 * strength
	env.adjustment_enabled = edge_t > 0.08
	env.adjustment_saturation = lerpf(_saved_env.adjustment_saturation, 0.78, edge_t * strength)


func _restore_arena_atmosphere() -> void:
	if _world_env and _saved_env and _world_env.environment:
		var env: Environment = _world_env.environment
		env.fog_enabled = _saved_env.fog_enabled
		env.fog_mode = _saved_env.fog_mode
		env.fog_light_color = _saved_env.fog_light_color
		env.fog_density = _saved_env.fog_density
		env.fog_depth_begin = _saved_env.fog_depth_begin
		env.fog_depth_end = _saved_env.fog_depth_end
		env.adjustment_enabled = _saved_env.adjustment_enabled
		env.adjustment_saturation = _saved_env.adjustment_saturation
		env.adjustment_brightness = _saved_env.adjustment_brightness
		env.ambient_light_energy = _saved_env.ambient_light_energy
		env.ambient_light_color = _saved_env.ambient_light_color
	if _ui and _ui.has_method("apply_void_gas_screen"):
		_ui.call("apply_void_gas_screen", 0.0, false)
	if _player_camera and _base_cam_attrs:
		_player_camera.attributes = _base_cam_attrs
	elif _player_camera and _player_camera.attributes is CameraAttributesPractical:
		var p: CameraAttributesPractical = _player_camera.attributes as CameraAttributesPractical
		p.dof_blur_far_enabled = false
		p.dof_blur_amount = 0.0
	if _atmosphere and _atmosphere.has_method("apply_depth_sample"):
		_atmosphere.call("apply_depth_sample", 0.0, 4.0, Vector3.ZERO)
	if _distant_arch and _distant_arch.has_method("apply_depth_fade"):
		_distant_arch.call("apply_depth_fade", 0.0, 4.0)


static func notify_fall_started(fighter: Node3D) -> void:
	var ctrl: VoidGasController = fighter.get_tree().get_first_node_in_group(
		"void_gas_controller"
	) as VoidGasController
	if ctrl:
		ctrl.set_fall_tracking(fighter, true)


static func notify_fall_ended() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var ctrl: VoidGasController = tree.get_first_node_in_group("void_gas_controller") as VoidGasController
	if ctrl:
		ctrl.set_fall_tracking(null, false)
