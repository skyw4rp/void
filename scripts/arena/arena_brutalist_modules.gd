## Non-gameplay scale landmarks + optional safe elevated lip (visual only).
class_name ArenaBrutalistModules
extends RefCounted

const CORNER_PYLON_SIZE: Vector3 = Vector3(2.4, 8.5, 2.4)


static func build(parent: Node3D, template: ArenaTemplate) -> void:
	if parent == null or template == null:
		return
	_build_corner_pylons(parent, template)


static func _build_corner_pylons(parent: Node3D, template: ArenaTemplate) -> void:
	if template.floor_pieces.is_empty():
		return
	var deck: ArenaTemplate.FloorPiece = template.floor_pieces[0]
	var hx: float = deck.size.x * 0.5 - 1.1
	var hz: float = deck.size.z * 0.5 - 1.1
	var mat := StandardMaterial3D.new()
	mat.albedo_color = template.wall_albedo.darkened(0.12)
	mat.emission_enabled = true
	mat.emission = Color(0.04, 0.07, 0.06)
	mat.emission_energy_multiplier = 0.18
	mat.roughness = 0.94
	mat.metallic = 0.2

	var offsets: Array[Vector3] = [
		Vector3(hx, 0.0, hz),
		Vector3(-hx, 0.0, hz),
		Vector3(hx, 0.0, -hz),
		Vector3(-hx, 0.0, -hz),
	]
	for i in offsets.size():
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "BrutalistPylon_%02d" % (i + 1)
		var box := BoxMesh.new()
		box.size = CORNER_PYLON_SIZE
		mesh_inst.mesh = box
		mesh_inst.material_override = mat
		parent.add_child(mesh_inst)
		var local: Vector3 = offsets[i]
		local.y = CORNER_PYLON_SIZE.y * 0.5 - deck.size.y * 0.5
		mesh_inst.global_position = template.center_position + local
