## Short-lived railgun beam line — primary shot visual.
class_name BeamTracer
extends Node3D

const DURATION_MIN_SEC: float = 0.12
const DURATION_MAX_SEC: float = 0.22
const BEAM_THICKNESS: float = 0.065


static func spawn(
	parent: Node,
	from: Vector3,
	to: Vector3,
	beam_color: Color = Color(0.55, 0.88, 1.0, 0.98),
	emission: Color = Color(0.35, 0.65, 1.0, 1.0),
	_show_impact: bool = false
) -> void:
	var tracer: BeamTracer = BeamTracer.new()
	parent.add_child(tracer)
	tracer._build(from, to, beam_color, emission)


func _build(from: Vector3, to: Vector3, beam_color: Color, emission: Color) -> void:
	var delta: Vector3 = to - from
	var length: float = delta.length()
	if length < 0.05:
		queue_free()
		return

	var mesh_inst := MeshInstance3D.new()
	add_child(mesh_inst)
	var box := BoxMesh.new()
	box.size = Vector3(BEAM_THICKNESS, BEAM_THICKNESS, length)
	mesh_inst.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = beam_color
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = 3.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat

	global_position = from + delta * 0.5
	look_at(to, Vector3.UP)

	var lifetime: float = randf_range(DURATION_MIN_SEC, DURATION_MAX_SEC)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
