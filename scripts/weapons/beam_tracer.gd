## Short-lived railgun beam line + optional impact flash.
class_name BeamTracer
extends Node3D

const DURATION_MIN_SEC: float = 0.08
const DURATION_MAX_SEC: float = 0.15


static func spawn(
	parent: Node,
	from: Vector3,
	to: Vector3,
	beam_color: Color = Color(0.72, 0.55, 1.0, 0.95),
	emission: Color = Color(0.45, 0.25, 0.95, 1.0),
	show_impact: bool = true
) -> void:
	var tracer: BeamTracer = BeamTracer.new()
	parent.add_child(tracer)
	tracer._build(from, to, beam_color, emission, show_impact)


func _build(
	from: Vector3, to: Vector3, beam_color: Color, emission: Color, show_impact: bool
) -> void:
	var delta: Vector3 = to - from
	var length: float = delta.length()
	if length < 0.05:
		queue_free()
		return

	var mesh_inst := MeshInstance3D.new()
	add_child(mesh_inst)
	var box := BoxMesh.new()
	box.size = Vector3(0.04, 0.04, length)
	mesh_inst.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = beam_color
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = 1.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat

	global_position = from + delta * 0.5
	look_at(to, Vector3.UP)

	if show_impact:
		_spawn_impact_flash(get_parent(), to, emission)

	var lifetime: float = randf_range(DURATION_MIN_SEC, DURATION_MAX_SEC)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


static func _spawn_impact_flash(parent: Node, position: Vector3, emission: Color) -> void:
	if parent == null:
		return
	var flash := MeshInstance3D.new()
	parent.add_child(flash)
	flash.global_position = position
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	flash.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.75, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.material_override = mat
	flash.add_to_group("void_effect")
	parent.get_tree().create_timer(0.12).timeout.connect(flash.queue_free)
