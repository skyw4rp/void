## Drifting void motes during VOID_GORE freefall.
extends Node3D

const LIFETIME_SEC: float = 2.5


func _ready() -> void:
	add_to_group("void_effect")


func activate() -> void:
	visible = true
	for child in get_children():
		if child is CPUParticles3D:
			(child as CPUParticles3D).emitting = true
	get_tree().create_timer(LIFETIME_SEC).timeout.connect(queue_free)
