## Base interact prompt (Area3D) — press interact while in range.
class_name ChamberInteractable
extends Area3D

@export var prompt_text: String = "Interact"
@export var enabled: bool = true

var _player_inside: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	monitorable = false
	monitoring = true


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("chamber_player"):
		_player_inside = true
		_notify_hud()


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("chamber_player"):
		_player_inside = false
		_clear_hud()


func try_interact(_player: Node3D) -> bool:
	if not enabled or not _player_inside:
		return false
	return _on_interact(_player)


func _on_interact(_player: Node3D) -> bool:
	return false


func is_player_inside() -> bool:
	return _player_inside and enabled


func _notify_hud() -> void:
	var hud: Node = get_tree().get_first_node_in_group("chamber_hud")
	if hud and hud.has_method("set_prompt"):
		hud.call("set_prompt", prompt_text)


func _clear_hud() -> void:
	var hud: Node = get_tree().get_first_node_in_group("chamber_hud")
	if hud and hud.has_method("clear_prompt"):
		hud.call("clear_prompt")
