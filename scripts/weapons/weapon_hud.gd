## Minimal HUD label for the active weapon.
extends Label


func _ready() -> void:
	var manager := get_tree().get_first_node_in_group("weapon_manager")
	if manager and manager.has_signal("weapon_changed"):
		manager.weapon_changed.connect(_on_weapon_changed)
		_on_weapon_changed(manager.get_weapon_name())


func _on_weapon_changed(weapon_name: String) -> void:
	text = "Weapon: %s" % weapon_name
