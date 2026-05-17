## Low-profile Quake-style spawn marker — floor-flush ring, team accent.
class_name SpawnPad
extends Node3D

enum Team { PLAYER, ENEMY }

const PAD_HEIGHT: float = 0.08
const PAD_RADIUS: float = 0.55
const FLOOR_LIFT: float = 0.02


func setup(team: Team, floor_position: Vector3, face_target: Vector3) -> void:
	global_position = floor_position
	var flat_dir: Vector3 = Vector3(face_target.x - floor_position.x, 0.0, face_target.z - floor_position.z)
	if flat_dir.length_squared() > 0.001:
		look_at(floor_position + flat_dir.normalized(), Vector3.UP)
	_apply_team_visuals(team)


func _apply_team_visuals(team: Team) -> void:
	var ring: MeshInstance3D = get_node_or_null("Ring") as MeshInstance3D
	var center: MeshInstance3D = get_node_or_null("CenterMark") as MeshInstance3D
	var glow_color: Color
	var ring_emission: Color
	match team:
		Team.PLAYER:
			glow_color = Color(0.22, 0.62, 0.82)
			ring_emission = Color(0.18, 0.7, 0.9)
		Team.ENEMY:
			glow_color = Color(0.82, 0.32, 0.14)
			ring_emission = Color(0.9, 0.28, 0.1)
		_:
			glow_color = Color(0.5, 0.5, 0.55)
			ring_emission = Color(0.5, 0.5, 0.55)

	if ring and ring.material_override is StandardMaterial3D:
		var rmat: StandardMaterial3D = (ring.material_override as StandardMaterial3D).duplicate()
		rmat.emission = ring_emission
		rmat.emission_energy_multiplier = 0.75
		ring.material_override = rmat
	if center and center.material_override is StandardMaterial3D:
		var cmat: StandardMaterial3D = (center.material_override as StandardMaterial3D).duplicate()
		cmat.emission = glow_color
		cmat.emission_energy_multiplier = 0.55
		center.material_override = cmat
