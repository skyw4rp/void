## Distant silhouettes — ruins, towers, and chains fading into toxic void fog.
extends Node3D


func _ready() -> void:
	add_to_group("void_distant_architecture")
	_apply_silhouette_materials()
	_add_extra_silhouettes()
	_silhouette_meshes.clear()
	for child in get_children():
		if child is MeshInstance3D:
			_silhouette_meshes.append(child as MeshInstance3D)


var _silhouette_meshes: Array[MeshInstance3D] = []


func apply_depth_fade(depth_t: float, world_y: float) -> void:
	var show_far: bool = world_y > GameBalance.VOID_FOG_Y_LIGHT and depth_t < 0.35
	for mesh_inst in _silhouette_meshes:
		if not is_instance_valid(mesh_inst):
			continue
		mesh_inst.visible = show_far
		if show_far and mesh_inst.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = mesh_inst.material_override as StandardMaterial3D
			mat.albedo_color.a = 1.0
			mat.emission_energy_multiplier = lerpf(0.22, 0.05, depth_t)


func _apply_silhouette_materials() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.04, 0.055, 0.07, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.06, 0.14, 0.1, 1.0)
	mat.emission_energy_multiplier = 0.22
	mat.roughness = 0.96
	mat.metallic = 0.18
	for child in get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = mat


func _add_extra_silhouettes() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.035, 0.05, 0.065, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.08, 0.12, 0.18, 1.0)
	mat.emission_energy_multiplier = 0.18

	var extras: Array[Dictionary] = [
		{"pos": Vector3(-38, -3, 45), "scale": Vector3(0.15, 18, 0.15)},
		{"pos": Vector3(32, -5, 38), "scale": Vector3(0.12, 14, 0.12)},
		{"pos": Vector3(-50, -8, -22), "scale": Vector3(10, 0.25, 3)},
		{"pos": Vector3(44, -12, -48), "scale": Vector3(6, 8, 6)},
		{"pos": Vector3(0, 6, 52), "scale": Vector3(28, 0.18, 2.5)},
		{"pos": Vector3(-22, -14, 68), "scale": Vector3(4, 4, 4)},
		{"pos": Vector3(-28, 1, 32), "scale": Vector3(16, 0.35, 5)},
		{"pos": Vector3(36, -2, -42), "scale": Vector3(12, 0.3, 4)},
		{"pos": Vector3(0, -10, 58), "scale": Vector3(8, 8, 8)},
		{"pos": Vector3(-18, 4, 48), "scale": Vector3(0.1, 9, 0.1)},
		{"pos": Vector3(22, 3, 44), "scale": Vector3(0.12, 11, 0.12)},
	]
	for data in extras:
		var inst := MeshInstance3D.new()
		inst.mesh = mesh
		inst.material_override = mat
		inst.position = data.pos
		inst.scale = data.scale
		add_child(inst)
