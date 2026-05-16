## Visible push projectile — flies forward, impulses RigidBody3D targets, then despawns.
extends Area3D

@export var speed: float = 35.0
@export var lifetime: float = 3.0
@export var push_force: float = 18.0

var _direction: Vector3 = Vector3.FORWARD
var _spent: bool = false
var _launched: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(_despawn)


## Call immediately after spawning to set origin and travel direction.
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
		print(
			"Projectile: pushed RigidBody3D '%s' (force=%.1f, dir=%s)"
			% [rigid.name, push_force, _direction]
		)
	else:
		print("Projectile: hit '%s' — destroyed" % body.name)
	_despawn()


func _despawn() -> void:
	if _spent:
		return
	_spent = true
	queue_free()
