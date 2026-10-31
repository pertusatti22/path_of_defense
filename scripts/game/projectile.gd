class_name Projectile
extends Node2D
## Projetil de torre. Persegue o alvo; artilharia explode em area.

var kind := "arrow"
var speed := 900.0
var radius := 8.0
var color := Color.WHITE
var damage := 10.0
var is_magic := false
var splash := 0.0
var target: Node = null
var last_pos := Vector2.ZERO


func setup(pid: String, target_enemy: Node, dmg: float, magic: bool, splash_radius: float) -> void:
	kind = pid
	var pdef: Dictionary = Data.projectiles.get(pid, Data.projectiles["arrow"])
	speed = pdef.speed
	radius = pdef.radius
	color = pdef.color
	damage = dmg
	is_magic = magic
	splash = splash_radius
	target = target_enemy
	if is_instance_valid(target):
		last_pos = target.global_position
	z_index = 20
	queue_redraw()


func _process(delta: float) -> void:
	if is_instance_valid(target):
		last_pos = target.global_position
	var to := last_pos - position
	var dist := to.length()
	var step := speed * delta
	if dist <= step or dist < 1.0:
		position = last_pos
		_impact()
		return
	position += to / dist * step
	rotation = to.angle()


func _impact() -> void:
	if splash > 0.0:
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and e.alive and e.global_position.distance_to(position) <= splash:
				e.take_damage(damage, is_magic)
	else:
		if is_instance_valid(target) and target.alive:
			target.take_damage(damage, is_magic)
	queue_free()


func _draw() -> void:
	match kind:
		"arrow":
			draw_line(Vector2(-radius * 2, 0), Vector2(radius, 0), color, 3.0)
			draw_circle(Vector2(radius, 0), radius * 0.5, color)
		"stone":
			draw_circle(Vector2.ZERO, radius, color)
			draw_circle(Vector2.ZERO, radius * 0.6, color.darkened(0.3))
		"magic":
			draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, 0.4))
			draw_circle(Vector2.ZERO, radius * 0.55, color)
		_:
			draw_circle(Vector2.ZERO, radius, color)
