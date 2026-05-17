## Quake-style arena spawn platform — team accent ring, floor-aligned, low profile.
class_name SpawnPad
extends Node3D

enum Team { PLAYER, ENEMY }

const PAD_HEIGHT: float = 0.2
const PAD_RADIUS: float = 1.0
const STAND_CLEARANCE: float = 1.0


func setup(team: Team, floor_position: Vector3, face_target: Vector3) -> void:
	global_position = floor_position
	var flat_dir: Vector3 = Vector3(face_target.x - floor_position.x, 0.0, face_target.z - floor_position.z)
	if flat_dir.length_squared() > 0.001:
		look_at(floor_position + flat_dir.normalized(), Vector3.UP)
	_apply_team_visuals(team)


func get_stand_position() -> Vector3:
	return global_position + Vector3(0.0, PAD_HEIGHT + STAND_CLEARANCE, 0.0)


func _apply_team_visuals(team: Team) -> void:
	var ring: MeshInstance3D = get_node_or_null("Ring") as MeshInstance3D
	var center: MeshInstance3D = get_node_or_null("CenterMark") as MeshInstance3D
	var glow_color: Color
	var ring_emission: Color
	match team:
		Team.PLAYER:
			glow_color = Color(0.25, 0.75, 0.95)
			ring_emission = Color(0.2, 0.85, 1.0)
		Team.ENEMY:
			glow_color = Color(0.95, 0.42, 0.18)
			ring_emission = Color(1.0, 0.35, 0.12)
		_:
			glow_color = Color(0.5, 0.5, 0.55)
			ring_emission = Color(0.5, 0.5, 0.55)

	if ring and ring.material_override is StandardMaterial3D:
		var rmat: StandardMaterial3D = (ring.material_override as StandardMaterial3D).duplicate()
		rmat.emission = ring_emission
		rmat.emission_energy_multiplier = 1.4
		ring.material_override = rmat
	if center and center.material_override is StandardMaterial3D:
		var cmat: StandardMaterial3D = (center.material_override as StandardMaterial3D).duplicate()
		cmat.emission = glow_color
		cmat.emission_energy_multiplier = 0.9
		center.material_override = cmat
