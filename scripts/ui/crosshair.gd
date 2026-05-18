## Minimal FPS crosshair — weapon styles, movement spread, hit feedback.
class_name Crosshair
extends Control

signal shot_fired

const GROUP: String = "crosshair"

const COLOR_IDLE: Color = Color(0.88, 0.96, 1.0, 0.88)
const COLOR_SHIELD_HIT: Color = Color(0.45, 0.92, 1.0, 1.0)
const COLOR_HEALTH_HIT: Color = Color(0.98, 0.42, 0.38, 1.0)
const COLOR_KILL: Color = Color(1.0, 0.35, 0.32, 0.95)

const WEAPON_STYLES: Dictionary = {
	WeaponDefs.Id.RAILGUN: {
		"gap": 4.0, "length": 5.0, "thickness": 1.5, "dot": 2.0, "move_add": 1.0,
	},
	WeaponDefs.Id.SHOTGUN: {
		"gap": 7.5, "length": 4.0, "thickness": 2.0, "dot": 2.5, "move_add": 2.8,
	},
	WeaponDefs.Id.BAZOOKA: {
		"gap": 6.0, "length": 6.5, "thickness": 2.5, "dot": 3.0, "move_add": 2.0,
	},
}


@export var hide_when_mouse_visible: bool = true
@export var crosshair_stabilized: bool = true
@export var movement_spread_affects_crosshair: bool = false

var _weapon: WeaponDefs.Id = WeaponDefs.Id.RAILGUN
var _move_spread: float = 0.0
var _shot_pulse: float = 0.0
var _hit_flash: float = 0.0
var _hit_color: Color = COLOR_IDLE
var _kill_marker: float = 0.0
var _visible_combat: bool = true


func _ready() -> void:
	add_to_group(GROUP)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(64, 64)
	size = custom_minimum_size
	call_deferred("_bind_weapon_manager")
	call_deferred("_bind_game_flow")


func _bind_weapon_manager() -> void:
	var wm: Node = get_tree().get_first_node_in_group("weapon_manager")
	if wm == null:
		return
	if wm.has_signal("weapon_switched"):
		wm.weapon_switched.connect(_on_weapon_id_changed)
	if wm.has_signal("shot_fired"):
		wm.shot_fired.connect(_on_weapon_shot)
	if wm.has_method("get_weapon_name"):
		var id: int = wm._current if "_current" in wm else WeaponDefs.Id.RAILGUN
		_on_weapon_id_changed(id as WeaponDefs.Id)


func _bind_game_flow() -> void:
	var gm: Node = get_tree().get_first_node_in_group("game_manager")
	if gm == null:
		return
	if gm.has_signal("countdown_text_changed"):
		gm.countdown_text_changed.connect(_on_countdown_text)
	if gm.has_signal("countdown_hidden"):
		gm.countdown_hidden.connect(_on_countdown_hidden)
	if gm.has_signal("match_over"):
		gm.match_over.connect(_on_match_over)


func _process(delta: float) -> void:
	_update_movement_spread()
	_shot_pulse = maxf(0.0, _shot_pulse - delta * 5.5)
	_hit_flash = maxf(0.0, _hit_flash - delta * 4.0)
	_kill_marker = maxf(0.0, _kill_marker - delta * 2.2)
	_update_visibility()
	queue_redraw()


func _draw() -> void:
	if not _should_draw():
		return

	var style: Dictionary = WEAPON_STYLES.get(_weapon, WEAPON_STYLES[WeaponDefs.Id.RAILGUN])
	var center: Vector2 = size * 0.5
	var gap: float = style.gap + _move_spread + _shot_pulse * 2.5
	var line_len: float = style.length
	var thick: float = maxf(1.0, style.thickness)
	var dot_sz: float = style.dot + _shot_pulse * 0.8

	var col: Color = COLOR_IDLE
	if _hit_flash > 0.0:
		col = _hit_color.lerp(COLOR_IDLE, 1.0 - _hit_flash)
	col.a = lerpf(0.72, 0.98, _hit_flash)

	var half_t: float = thick * 0.5
	var half_d: float = dot_sz * 0.5

	draw_rect(Rect2(center.x - half_d, center.y - half_d, dot_sz, dot_sz), col)

	draw_rect(Rect2(center.x - half_t, center.y - gap - line_len, thick, line_len), col)
	draw_rect(Rect2(center.x - half_t, center.y + gap, thick, line_len), col)
	draw_rect(Rect2(center.x - gap - line_len, center.y - half_t, line_len, thick), col)
	draw_rect(Rect2(center.x + gap, center.y - half_t, line_len, thick), col)

	if _kill_marker > 0.0:
		_draw_kill_marker(center, style, col)


func _draw_kill_marker(center: Vector2, style: Dictionary, base_col: Color) -> void:
	var col: Color = COLOR_KILL
	col.a = base_col.a * _kill_marker
	var arm: float = style.gap + style.length * 0.55
	var t: float = maxf(1.5, style.thickness)
	var half: float = t * 0.5
	# Small X at center
	draw_rect(Rect2(center.x - arm - half, center.y - arm - half, t, t), col)
	draw_rect(Rect2(center.x + arm - half, center.y + arm - half, t, t), col)
	draw_rect(Rect2(center.x + arm - half, center.y - arm - half, t, t), col)
	draw_rect(Rect2(center.x - arm - half, center.y + arm - half, t, t), col)


func configure_aim_stability(stabilized: bool, disable_movement_spread: bool) -> void:
	crosshair_stabilized = stabilized
	movement_spread_affects_crosshair = not disable_movement_spread
	if crosshair_stabilized:
		_move_spread = 0.0


func set_weapon(weapon: WeaponDefs.Id) -> void:
	_weapon = weapon
	queue_redraw()


func notify_shot() -> void:
	_shot_pulse = 1.0
	shot_fired.emit()
	queue_redraw()


func notify_hit_on_target(shield_damage: int, health_damage: int, killed: bool) -> void:
	if shield_damage <= 0 and health_damage <= 0:
		return
	_hit_flash = 1.0
	if killed:
		_kill_marker = 1.0
		_hit_color = COLOR_KILL
	elif health_damage > 0:
		_hit_color = COLOR_HEALTH_HIT
	else:
		_hit_color = COLOR_SHIELD_HIT
		if shield_damage >= 50:
			_hit_flash = 1.25
	queue_redraw()


func notify_enemy_shield_broken() -> void:
	_hit_flash = 1.35
	_hit_color = COLOR_SHIELD_HIT
	queue_redraw()


func notify_hit_cover() -> void:
	_hit_flash = 0.65
	_hit_color = COLOR_IDLE.lerp(COLOR_SHIELD_HIT, 0.5)
	queue_redraw()


static func get_instance(tree: SceneTree) -> Control:
	return tree.get_first_node_in_group(GROUP) as Control


static func notify_player_damage_to(
	tree: SceneTree,
	target: Node,
	shield_before: int,
	health_before: int
) -> void:
	var cross: Control = get_instance(tree)
	if cross == null or not cross.has_method("notify_hit_on_target"):
		return
	var stats: CombatStats = target.get_node_or_null("CombatStats") as CombatStats
	if stats == null:
		return
	var shield_dmg: int = maxi(0, shield_before - stats.shield)
	var health_dmg: int = maxi(0, health_before - stats.health)
	if shield_before > 0 and stats.shield <= 0:
		var src: String = stats.last_damage_source
		if src == "railgun" or src == "bazooka_direct":
			if cross.has_method("notify_enemy_shield_broken"):
				cross.call("notify_enemy_shield_broken")
	cross.call("notify_hit_on_target", shield_dmg, health_dmg, stats.is_dead())


static func notify_player_hit_cover(tree: SceneTree) -> void:
	var cross: Control = get_instance(tree)
	if cross and cross.has_method("notify_hit_cover"):
		cross.call("notify_hit_cover")


func _on_weapon_id_changed(weapon: WeaponDefs.Id) -> void:
	set_weapon(weapon)


func _on_weapon_shot() -> void:
	notify_shot()


func _on_countdown_text(_text: String) -> void:
	_visible_combat = false


func _on_countdown_hidden() -> void:
	_visible_combat = true


func _on_match_over(_player_won: bool) -> void:
	_visible_combat = false


func _update_movement_spread() -> void:
	if crosshair_stabilized or not movement_spread_affects_crosshair:
		_move_spread = move_toward(_move_spread, 0.0, 0.22)
		return

	var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if player == null:
		_move_spread = move_toward(_move_spread, 0.0, 0.2)
		return

	var style: Dictionary = WEAPON_STYLES.get(_weapon, WEAPON_STYLES[WeaponDefs.Id.RAILGUN])
	var horiz: float = Vector2(player.velocity.x, player.velocity.z).length()
	var factor: float = clampf(horiz / 9.0, 0.0, 1.0)
	if not player.is_on_floor():
		factor = maxf(factor, 0.55)
	var target: float = style.move_add * factor
	_move_spread = lerpf(_move_spread, target, 0.18)


func _update_visibility() -> void:
	var show: bool = _visible_combat
	if hide_when_mouse_visible and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		show = false
	var gm: Node = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("is_fighting") and not gm.is_fighting():
		show = false
	visible = show


func _should_draw() -> bool:
	return visible and size.x > 1.0
