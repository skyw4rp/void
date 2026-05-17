## Large slow projectile — direct hit plus radial explosion push on impact.
extends Area3D

@export var speed: float = 22.0
@export var lifetime: float = 4.0
@export var push_force: float = 28.0
@export var explosion_radius: float = 5.0
@export var explosion_force: float = 35.0

var _direction: Vector3 = Vector3.FORWARD
var _spent: bool = false
var _launched: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(_despawn)


func launch(from: Vector3, direction: Vector3) -> void:
	global_position = from
	_direction = direction.normalized()
	_launched = true


func _physics_process(delta: float) -> void:
	if _spent or not _launched:
		return
	global_position += _direction * speed * delta


func _on_body_entered(body: Node3D) -> void:
	if _spent:
		return
	if body is RigidBody3D:
		var rigid := body as RigidBody3D
		var offset := global_position - rigid.global_position
		rigid.apply_impulse(_direction * push_force, offset)
		print("Bazooka: direct hit on '%s'" % rigid.name)
	else:
		print("Bazooka: hit '%s' — exploding" % body.name)
	_explode()
	_despawn()


func _explode() -> void:
	PushExplosion.detonate(global_position, explosion_radius, explosion_force, get_world_3d())


func _despawn() -> void:
	if _spent:
		return
	_spent = true
	queue_free()
