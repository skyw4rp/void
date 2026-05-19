## Sparse megastructure beacon — slow blink, no gameplay.
extends Node3D

var _period: float = 2.5
var _phase: float = 0.0
var _omni: OmniLight3D
var _bulb: MeshInstance3D


func _ready() -> void:
	_period = float(get_meta("blink_period", 2.5))
	_phase = float(get_meta("blink_phase", 0.0))
	for child in get_children():
		if child is OmniLight3D:
			_omni = child
		elif child is MeshInstance3D:
			_bulb = child


func _process(delta: float) -> void:
	_phase += delta
	var pulse: float = 0.5 + 0.5 * sin((_phase / _period) * TAU)
	if _omni != null:
		_omni.light_energy = lerpf(0.04, 0.38, pulse)
	if _bulb != null and _bulb.material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = _bulb.material_override as StandardMaterial3D
		mat.emission_energy_multiplier = lerpf(0.25, 1.2, pulse)
