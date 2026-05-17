## Destructible outer perimeter panel — blocks shots until broken.
class_name ArenaPerimeterPanel
extends StaticBody3D

const MAX_HEALTH: int = 120

var _health: int = MAX_HEALTH
var _broken: bool = false
var _mesh: MeshInstance3D


func _ready() -> void:
	add_to_group("arena_wall")
	add_to_group("arena_perimeter")
	collision_layer = 1
	collision_mask = 1


func setup_panel(mesh: MeshInstance3D) -> void:
	_mesh = mesh
	_health = MAX_HEALTH
	_broken = false


func damage_cover(
	amount: int,
	_attacker: Node = null,
	direction: Vector3 = Vector3.ZERO,
	_force: float = 0.0,
	source: String = ""
) -> void:
	if _broken or amount <= 0:
		return
	var mult: float = 1.0
	match source:
		"bazooka_explosion":
			mult = 1.7
		"bazooka_direct":
			mult = 1.35
		"shotgun":
			mult = 0.8
	_health = maxi(0, _health - int(round(float(amount) * mult)))
	if _health <= 0:
		_break_apart()


func _break_apart() -> void:
	if _broken:
		return
	_broken = true
	var parent: Node = get_parent()
	if parent == null:
		parent = get_tree().current_scene
	var mat: StandardMaterial3D = null
	if _mesh and _mesh.material_override is StandardMaterial3D:
		mat = _mesh.material_override as StandardMaterial3D
	DebrisFragment.spawn_burst(parent, global_position, randi_range(5, 9), mat)
	print("Perimeter panel destroyed")
	queue_free()
