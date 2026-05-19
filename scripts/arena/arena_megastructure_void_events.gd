## Rare ambient void events — flash, lightning, debris, resonance (visual only).
class_name ArenaMegastructureVoidEvents
extends Node

enum EventKind { DISTANT_FLASH, VOID_LIGHTNING, FALLING_DEBRIS, METALLIC_RESONANCE }

var _rng: RandomNumberGenerator
var _play_radius: float = 40.0
var _timer: Timer


func setup(rng: RandomNumberGenerator, play_radius: float) -> void:
	_rng = rng
	_play_radius = play_radius


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_event_timer)
	add_child(_timer)
	_schedule_next()


func _schedule_next() -> void:
	if _rng == null:
		return
	_timer.start(_rng.randf_range(9.0, 22.0))


func _on_event_timer() -> void:
	_trigger_random_event()
	_schedule_next()


func _trigger_random_event() -> void:
	var kind: EventKind = _rng.randi_range(0, 3) as EventKind
	var origin: Vector3 = _random_distant_point()
	match kind:
		EventKind.DISTANT_FLASH:
			_event_distant_flash(origin)
		EventKind.VOID_LIGHTNING:
			_event_void_lightning(origin)
		EventKind.FALLING_DEBRIS:
			_event_falling_debris(origin)
		EventKind.METALLIC_RESONANCE:
			_event_metallic_resonance(origin)


func _random_distant_point() -> Vector3:
	var angle: float = _rng.randf() * TAU
	var dist: float = _rng.randf_range(_play_radius + 55.0, _play_radius + 140.0)
	return Vector3(cos(angle) * dist, _rng.randf_range(8.0, 55.0), sin(angle) * dist)


func _event_distant_flash(origin: Vector3) -> void:
	var flash := OmniLight3D.new()
	flash.light_color = Color(0.55, 0.7, 0.85) if _rng.randf() > 0.5 else Color(0.85, 0.35, 0.3)
	flash.light_energy = _rng.randf_range(0.8, 1.6)
	flash.omni_range = _rng.randf_range(28.0, 55.0)
	flash.position = origin
	flash.shadow_enabled = false
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "light_energy", 0.0, _rng.randf_range(0.12, 0.28))
	tween.tween_callback(flash.queue_free)


func _event_void_lightning(origin: Vector3) -> void:
	var bolt := CPUParticles3D.new()
	bolt.emitting = true
	bolt.one_shot = true
	bolt.amount = 12
	bolt.lifetime = 0.35
	bolt.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	bolt.emission_box_extents = Vector3(0.2, 8.0, 0.2)
	bolt.direction = Vector3(0.0, -1.0, 0.0)
	bolt.spread = 6.0
	bolt.initial_velocity_min = 18.0
	bolt.initial_velocity_max = 32.0
	bolt.gravity = Vector3.ZERO
	bolt.color = Color(0.35, 0.75, 0.95, 0.85)
	bolt.position = origin
	add_child(bolt)
	_event_distant_flash(origin + Vector3(0.0, 4.0, 0.0))
	var cleanup := get_tree().create_timer(0.6)
	cleanup.timeout.connect(bolt.queue_free)


func _event_falling_debris(origin: Vector3) -> void:
	var debris := CPUParticles3D.new()
	debris.emitting = true
	debris.one_shot = true
	debris.amount = 8
	debris.lifetime = 1.8
	debris.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	debris.emission_box_extents = Vector3(1.5, 0.3, 1.5)
	debris.direction = Vector3(0.0, -1.0, 0.0)
	debris.spread = 22.0
	debris.initial_velocity_min = 2.0
	debris.initial_velocity_max = 6.0
	debris.gravity = Vector3(0.0, -4.0, 0.0)
	debris.scale_amount_min = 0.2
	debris.scale_amount_max = 0.7
	debris.color = Color(0.3, 0.32, 0.35, 0.6)
	debris.position = origin + Vector3(0.0, 12.0, 0.0)
	add_child(debris)
	var cleanup := get_tree().create_timer(2.2)
	cleanup.timeout.connect(debris.queue_free)


func _event_metallic_resonance(origin: Vector3) -> void:
	var pulse := OmniLight3D.new()
	pulse.light_color = Color(0.45, 0.5, 0.55)
	pulse.light_energy = 0.15
	pulse.omni_range = _rng.randf_range(35.0, 60.0)
	pulse.position = origin
	pulse.shadow_enabled = false
	add_child(pulse)
	var tween := create_tween()
	tween.tween_property(pulse, "light_energy", 0.45, 0.08)
	tween.tween_property(pulse, "light_energy", 0.05, 0.55)
	tween.tween_property(pulse, "light_energy", 0.0, 0.4)
	tween.tween_callback(pulse.queue_free)
