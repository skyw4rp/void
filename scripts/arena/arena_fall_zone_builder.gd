## Broken edges, cracked trim, and void glow at intentional ring-out openings.
class_name ArenaFallZoneBuilder
extends RefCounted

const GROUP: String = "arena_fall_zone"


static func build(parent: Node3D, template: ArenaTemplate) -> void:
	for marker in template.fall_zones:
		_place_marker(parent, template.center_position, marker)


static func _place_marker(parent: Node3D, arena_center: Vector3, marker: ArenaTemplate.FallZoneMarker) -> void:
	var root := Node3D.new()
	root.name = "FallZone"
	root.add_to_group(GROUP)
	parent.add_child(root)
	root.global_position = arena_center + marker.position
	root.rotation.y = marker.rotation_y

	var crack := MeshInstance3D.new()
	var crack_mesh := BoxMesh.new()
	crack_mesh.size = marker.size
	crack.mesh = crack_mesh
	var crack_mat := StandardMaterial3D.new()
	crack_mat.albedo_color = Color(0.08, 0.12, 0.1)
	crack_mat.emission_enabled = true
	crack_mat.emission = Color(0.15, 0.35, 0.22)
	crack_mat.emission_energy_multiplier = 0.45
	crack.material_override = crack_mat
	crack.position = Vector3(0.0, 0.06, 0.0)
	root.add_child(crack)

	var broken_rail := MeshInstance3D.new()
	var rail_mesh := BoxMesh.new()
	rail_mesh.size = Vector3(marker.size.x * 0.7, 0.55, 0.12)
	broken_rail.mesh = rail_mesh
	var rail_mat := StandardMaterial3D.new()
	rail_mat.albedo_color = Color(0.06, 0.065, 0.07)
	broken_rail.material_override = rail_mat
	broken_rail.position = Vector3(marker.size.x * 0.22, 0.35, 0.0)
	broken_rail.rotation.z = -0.35
	root.add_child(broken_rail)

	var glow := MeshInstance3D.new()
	var glow_mesh := BoxMesh.new()
	glow_mesh.size = Vector3(marker.size.x * 1.2, 0.05, marker.size.z * 4.0)
	glow.mesh = glow_mesh
	var glow_mat := StandardMaterial3D.new()
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.albedo_color = Color(0.12, 0.45, 0.28, 0.35)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.2, 0.55, 0.35)
	glow_mat.emission_energy_multiplier = 0.8
	glow.material_override = glow_mat
	glow.position = Vector3(0.0, -1.8, 0.0)
	root.add_child(glow)

	var light := OmniLight3D.new()
	light.light_color = Color(0.25, 0.7, 0.4)
	light.light_energy = 0.55
	light.omni_range = 5.5
	light.position = Vector3(0.0, -2.5, 0.0)
	root.add_child(light)
