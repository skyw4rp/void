## Standard push projectile — flies forward and pushes RigidBody3D or knockback targets.
extends Area3D

@export var speed: float = 35.0
@export var lifetime: float = 3.0
@export var push_force: float = 18.0

var _direction: Vector3 = Vector3.FORWARD
var _spent: bool = false
var _launched: bool = false
var _shooter: Node = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(_despawn)


func launch(from: Vector3, direction: Vector3, shooter: Node = null) -> void:
	global_position = from
	_direction = direction.normalized()
	_shooter = shooter
	_launched = true


func configure(stats: Dictionary) -> void:
	speed = stats.get("speed", speed)
	push_force = stats.get("push_force", push_force)
	lifetime = stats.get("lifetime", lifetime)
	var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh and stats.has("mesh_scale"):
		var s := float(stats.mesh_scale)
		mesh.scale = Vector3.ONE * s
	if mesh and stats.has("color"):
		var mat: StandardMaterial3D = mesh.material_override.duplicate() as StandardMaterial3D
		mat.albedo_color = stats.color
		mesh.material_override = mat


func _physics_process(delta: float) -> void:
	if _spent or not _launched:
		return
	global_position += _direction * speed * delta


func _on_body_entered(body: Node3D) -> void:
	if _spent:
		return
	if PushHitResolver.is_shooter(body, _shooter):
		return

	if PushHitResolver.apply_projectile_hit(body, _direction, push_force, global_position):
		_despawn()
		return

	print("Projectile: hit '%s' — destroyed" % body.name)
	_despawn()


func _despawn() -> void:
	if _spent:
		return
	_spent = true
	queue_free()
