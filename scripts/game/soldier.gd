class_name Soldier
extends Node2D
## Soldado da milicia: bloqueia inimigos no caminho e luta corpo a corpo.

signal died(soldier: Soldier)

var max_hp := 90.0
var hp := 90.0
var damage := 7.0
var attack_interval := 1.0
var rally := Vector2.ZERO
var barracks: Node = null

var engaged: Node = null
var _cd := 0.0
var _alive := true

const MOVE_SPEED := 140.0
const ENGAGE_RANGE := 190.0


func setup(home: Vector2, b: Node, dmg: float, hp_val: float) -> void:
	rally = home
	barracks = b
	damage = dmg
	max_hp = hp_val
	hp = hp_val
	position = home
	z_index = 8


func _process(delta: float) -> void:
	if not _alive:
		return
	if engaged == null or not is_instance_valid(engaged) or not engaged.alive:
		engaged = null
		_find_target()

	if engaged != null and is_instance_valid(engaged):
		_combat(delta)
	else:
		_return_home(delta)


func _return_home(delta: float) -> void:
	if position.distance_to(rally) > 4.0:
		position = position.move_toward(rally, MOVE_SPEED * delta)


func _find_target() -> void:
	var best: Node = null
	var best_d := ENGAGE_RANGE
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e.alive:
			continue
		var d: float = e.global_position.distance_to(rally)
		if d <= best_d:
			best_d = d
			best = e
	if best != null:
		engaged = best
		best.engage(self)


func _combat(delta: float) -> void:
	var target_pos: Vector2 = engaged.global_position
	if position.distance_to(target_pos) > 34.0:
		position = position.move_toward(target_pos, MOVE_SPEED * delta)
		return
	_cd -= delta
	if _cd <= 0.0:
		_cd = attack_interval
		engaged.take_damage(damage, false)


func take_damage(amount: float) -> void:
	if not _alive:
		return
	hp -= amount
	queue_redraw()
	if hp <= 0.0:
		_die()


func _die() -> void:
	if not _alive:
		return
	_alive = false
	if engaged != null and is_instance_valid(engaged):
		engaged.release()
	died.emit(self)
	queue_free()


func _draw() -> void:
	# Corpo
	draw_circle(Vector2.ZERO, 16.0, Color(0.30, 0.45, 0.75))
	draw_circle(Vector2(0, -6), 10.0, Color(0.85, 0.75, 0.6))
	# Barra de vida
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(-22, -34, 44, 7), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(-21, -33, 42 * ratio, 5), Color(0.3, 0.85, 0.4))
