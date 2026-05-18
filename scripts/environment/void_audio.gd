## VOID audio director — void ambience, proximity, danger pulses, combat feedback.
## Autoload: plays procedural placeholders until real assets exist (see audio/README_REPLACE_ASSETS.md).
class_name VoidAudio
extends Node

const SFX_3D_POOL_SIZE: int = 10
const HIT_SOUND_COOLDOWN_SEC: float = 0.045

@export var master_volume_db: float = 0.0
@export var void_ambience_volume_db: float = -16.0
@export var void_proximity_volume_db: float = -22.0
@export var combat_volume_db: float = -4.0
@export var enemy_combat_volume_db: float = -7.0

static var _instance: VoidAudio

var _ambience_player: AudioStreamPlayer
var _proximity_player: AudioStreamPlayer
var _fall_player: AudioStreamPlayer
var _sfx_3d_pool: Array[AudioStreamPlayer3D] = []
var _pool_index: int = 0

var _streams_ready: bool = false
var _proximity_depth: float = 0.0
var _edge_proximity: float = 0.0
var _falling: bool = false
var _danger_band: int = -1
var _danger_pulse_cooldown: float = 0.0
var _last_hit_sound_time: float = -1.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_instance = self
	_rng.randomize()
	_build_players()
	_cache_streams()
	_start_void_ambience()


func _process(delta: float) -> void:
	_danger_pulse_cooldown = maxf(_danger_pulse_cooldown - delta, 0.0)
	_update_proximity_loop()


# --- Static void API (backward compatible) ---


static func play_void_wind() -> void:
	_play_static_stream(AudioStreamFactory.void_wind_gust(), -6.0)


static func play_void_drone() -> void:
	if _instance:
		_instance._start_void_ambience()


static func play_body_rupture() -> void:
	_play_static_stream(AudioStreamFactory.void_body_rupture(), 2.0)


static func play_disintegration_burst() -> void:
	_play_static_stream(AudioStreamFactory.void_disintegration_burst(), 0.0)


static func play_void_absorption(silent: bool) -> void:
	if silent:
		return
	_play_static_stream(AudioStreamFactory.void_distant_impact(), -8.0)


static func play_metallic_resonance() -> void:
	_play_static_stream(AudioStreamFactory.void_metallic_resonance(), -10.0)


static func maybe_play_random_abyss_ambience() -> void:
	if _instance == null:
		return
	if _instance._rng.randf() > 0.72:
		return
	match _instance._rng.randi() % 3:
		0:
			play_void_drone()
		1:
			play_void_wind()
		2:
			play_metallic_resonance()


static func update_void_proximity(
	depth_t: float,
	world_y: float,
	falling: bool,
	edge_proximity_t: float = 0.0
) -> void:
	if _instance == null:
		return
	_instance._proximity_depth = clampf(depth_t, 0.0, 1.0)
	_instance._edge_proximity = clampf(edge_proximity_t, 0.0, 1.0)
	_instance._falling = falling
	_instance._update_danger_bands(depth_t, world_y, falling)


# --- Static combat API ---


static func play_weapon_fire(
	weapon: WeaponDefs.Id, world_position: Vector3, from_enemy: bool = false
) -> void:
	if _instance == null:
		return
	_instance._play_weapon_fire_impl(weapon, world_position, from_enemy)


static func play_hit_confirm(
	world_position: Vector3,
	shield_before: int,
	shield_after: int,
	health_before: int,
	health_after: int,
	attacker_is_player: bool
) -> void:
	if _instance == null:
		return
	_instance._play_hit_confirm_impl(
		world_position,
		shield_before,
		shield_after,
		health_before,
		health_after,
		attacker_is_player
	)


static func play_wall_hit(world_position: Vector3, attacker_is_player: bool) -> void:
	if _instance == null:
		return
	_instance._play_at_3d(
		AudioStreamFactory.hit_confirm_wall(),
		world_position,
		-10.0 if attacker_is_player else -14.0,
		_instance._rng.randf_range(0.92, 1.05)
	)


static func compute_edge_proximity(player_world: Vector3) -> float:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return 0.0
	var gen: Node = tree.get_first_node_in_group("arena_generator")
	if gen == null or not gen.has_method("get_current_arena_bounds"):
		return 0.0
	var bounds: Dictionary = gen.call("get_current_arena_bounds")
	if bounds.is_empty():
		return 0.0
	var center: Vector3 = bounds.get("center", Vector3.ZERO)
	var danger_hx: float = float(bounds.get("danger_half_x", 8.0))
	var danger_hz: float = float(bounds.get("danger_half_z", 8.0))
	var margin: float = 2.4
	var dx: float = danger_hx - absf(player_world.x - center.x)
	var dz: float = danger_hz - absf(player_world.z - center.z)
	var edge_dist: float = minf(dx, dz)
	return 1.0 - clampf(edge_dist / margin, 0.0, 1.0)


# --- Internal ---


func _build_players() -> void:
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "VoidAmbience"
	_ambience_player.bus = &"Master"
	add_child(_ambience_player)

	_proximity_player = AudioStreamPlayer.new()
	_proximity_player.name = "VoidProximity"
	_proximity_player.bus = &"Master"
	add_child(_proximity_player)

	_fall_player = AudioStreamPlayer.new()
	_fall_player.name = "VoidFallRush"
	_fall_player.bus = &"Master"
	add_child(_fall_player)

	var pool_root := Node3D.new()
	pool_root.name = "CombatSfx3D"
	add_child(pool_root)
	for i in SFX_3D_POOL_SIZE:
		var p := AudioStreamPlayer3D.new()
		p.name = "Sfx3D_%d" % i
		p.bus = &"Master"
		p.max_distance = 64.0
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p.unit_size = 4.0
		pool_root.add_child(p)
		_sfx_3d_pool.append(p)


func _cache_streams() -> void:
	_streams_ready = true


func _start_void_ambience() -> void:
	if not _streams_ready or _ambience_player == null:
		return
	var stream: AudioStream = AudioStreamFactory.void_drone_loop()
	if stream == null:
		return
	_ambience_player.stream = stream
	_ambience_player.volume_db = void_ambience_volume_db + master_volume_db
	if not _ambience_player.playing:
		_ambience_player.play()


func _update_proximity_loop() -> void:
	if _proximity_player == null:
		return
	var stream: AudioStream = AudioStreamFactory.void_proximity_loop()
	if _proximity_player.stream != stream:
		_proximity_player.stream = stream

	var depth_mix: float = maxf(_proximity_depth, _edge_proximity * 0.65)
	if _falling:
		depth_mix = maxf(depth_mix, 0.55)

	if depth_mix < 0.04 and not _falling:
		if _proximity_player.playing:
			_proximity_player.volume_db = -80.0
		return

	if not _proximity_player.playing and stream != null:
		_proximity_player.play()

	var target_db: float = lerpf(-42.0, void_proximity_volume_db, depth_mix) + master_volume_db
	_proximity_player.volume_db = lerpf(_proximity_player.volume_db, target_db, 0.12)

	if _falling and _fall_player and not _fall_player.playing:
		var rush: AudioStream = AudioStreamFactory.void_fall_rush()
		if rush:
			_fall_player.stream = rush
			_fall_player.volume_db = -10.0 + master_volume_db
			_fall_player.play()
	elif not _falling and _fall_player and _fall_player.playing:
		_fall_player.stop()


func _update_danger_bands(depth_t: float, world_y: float, falling: bool) -> void:
	var band: int = -1
	if falling or world_y < GameBalance.VOID_FALL_WARNING_Y:
		if depth_t >= 0.75:
			band = 3
		elif depth_t >= 0.45:
			band = 2
		elif depth_t >= 0.2 or world_y < GameBalance.VOID_FALL_WARNING_Y:
			band = 1
	elif _edge_proximity > 0.55:
		band = 0

	if band > _danger_band and _danger_pulse_cooldown <= 0.0:
		_play_danger_pulse(band)
	_danger_band = band


func _play_danger_pulse(band: int) -> void:
	_danger_pulse_cooldown = 0.85 - float(band) * 0.12
	var stream: AudioStream = AudioStreamFactory.void_danger_pulse()
	if stream == null:
		return
	_play_at_3d(stream, _listener_position(), -6.0 - float(band) * 2.0, 0.85 + float(band) * 0.06)


func _play_weapon_fire_impl(
	weapon: WeaponDefs.Id, world_position: Vector3, from_enemy: bool
) -> void:
	var stream: AudioStream = AudioStreamFactory.weapon_fire(weapon)
	if stream == null:
		return
	var vol: float = enemy_combat_volume_db if from_enemy else combat_volume_db
	var pitch: float = _rng.randf_range(0.94, 1.06)
	if from_enemy:
		pitch *= _rng.randf_range(0.92, 0.98)
	_play_at_3d(stream, world_position, vol + master_volume_db, pitch)


func _play_hit_confirm_impl(
	world_position: Vector3,
	shield_before: int,
	shield_after: int,
	health_before: int,
	health_after: int,
	attacker_is_player: bool
) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_hit_sound_time < HIT_SOUND_COOLDOWN_SEC:
		return
	_last_hit_sound_time = now

	var stream: AudioStream = null
	var vol_offset: float = 0.0
	if shield_after < shield_before:
		stream = AudioStreamFactory.hit_confirm_shield()
		vol_offset = -4.0
	elif health_after < health_before:
		stream = AudioStreamFactory.hit_confirm_health()
		vol_offset = 0.0
		_play_fighter_hurt_at(world_position)
	else:
		return

	if stream == null:
		return
	var vol: float = combat_volume_db + vol_offset
	if not attacker_is_player:
		vol = enemy_combat_volume_db + vol_offset
	_play_at_3d(stream, world_position, vol + master_volume_db, _rng.randf_range(0.95, 1.08))


func _play_fighter_hurt_at(world_position: Vector3) -> void:
	var stream: AudioStream = AudioStreamFactory.fighter_hurt()
	if stream == null:
		return
	_play_at_3d(stream, world_position, -8.0 + master_volume_db, _rng.randf_range(0.9, 1.05))


func _play_at_3d(
	stream: AudioStream, world_position: Vector3, volume_db: float, pitch_scale: float
) -> void:
	if stream == null or _sfx_3d_pool.is_empty():
		return
	var player: AudioStreamPlayer3D = _sfx_3d_pool[_pool_index]
	_pool_index = (_pool_index + 1) % _sfx_3d_pool.size()
	player.global_position = world_position
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func _listener_position() -> Vector3:
	var tree: SceneTree = get_tree()
	if tree == null:
		return Vector3.ZERO
	var cam: Camera3D = tree.root.get_viewport().get_camera_3d()
	if cam:
		return cam.global_position
	var player: Node3D = tree.get_first_node_in_group("player") as Node3D
	if player:
		return player.global_position
	return Vector3.ZERO


static func _play_static_stream(stream: AudioStream, volume_db: float) -> void:
	if _instance == null or stream == null:
		return
	_instance._play_at_3d(stream, _instance._listener_position(), volume_db + _instance.master_volume_db, 1.0)
