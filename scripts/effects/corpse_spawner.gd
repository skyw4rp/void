## Spawns physics corpses into the world on kill deaths.
class_name CorpseSpawner
extends RefCounted

const CORPSE_SCENE: PackedScene = preload("res://scenes/effects/physics_corpse.tscn")


static func spawn(
	world_root: Node,
	position: Vector3,
	direction: Vector3,
	force: float,
	upward_boost: float,
	albedo: Color,
	emission: Color,
	debug_label: String,
	damage_source: String = ""
) -> RigidBody3D:
	var corpse: RigidBody3D = CORPSE_SCENE.instantiate() as RigidBody3D
	world_root.add_child(corpse)
	if corpse.has_method("configure_appearance"):
		corpse.call("configure_appearance", albedo, emission)
	if corpse.has_method("launch"):
		corpse.call("launch", position, direction, force, upward_boost, damage_source)
	print("Spawned %s" % debug_label)
	return corpse
