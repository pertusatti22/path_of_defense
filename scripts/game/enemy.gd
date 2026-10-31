class_name Enemy
extends Node2D
## Inimigo que percorre o caminho. Pode ser bloqueado por soldados.

signal died(enemy: Enemy)
signal leaked(enemy: Enemy)

var type_id := ""
var display_name := ""
var max_hp := 100.0
var hp := 100.0
var speed := 60.0
var bounty := 5
var leak_damage := 1
var armor := 0.0
var magic_resist := 0.0
var is_boss := false

var path: PackedVector2Array = PackedVector2Array()
var _seg := 1
var _finished := false

var blocker: Node = null
var _attack_cd := 0.0
const ATTACK_INTERVAL := 1.0

var sprite: AnimatedSprite2D = null
var _hp_bar: Node2D = null
var _hp_fill: ColorRect = null
var _walk_anim := "walk"
var _attack_anim := "attack"

var alive := true


func setup(id: String, data: Dictionary, path_pts: PackedVector2Array, hp_mult: float) -> void:
	type_id = id
	display_name = data.get("name", id)
	max_hp = float(data.get("hp", 100)) * hp_mult
	hp = max_hp
	speed = float(data.get("speed", 60))
	bounty = int(data.get("bounty", 5))
	leak_damage = int(data.get("leak", 1))
	armor = float(data.get("armor", 0))
	magic_resist = float(data.get("magic_resist", 0.0))
	is_boss = bool(data.get("is_boss", false))
	path = path_pts
	if path.size() > 0:
		position = path[0]

	_build_visual(data)
	if is_boss:
		scale = Vector2(1.0, 1.0)
		z_index = 5


func _build_visual(data: Dictionary) -> void:
	var height := float(data.get("height", 120))
	var frames := SpriteLoader.load_frames(data.get("sprite", ""))
	if frames != null:
		sprite = AnimatedSprite2D.new()
		sprite.sprite_frames = frames
		_walk_anim = SpriteLoader.locomotion_anim(frames)
		_attack_anim = SpriteLoader.attack_anim(frames)
		sprite.animation = _walk_anim
		sprite.play()
		sprite.centered = true
		var frame_tex := frames.get_frame_texture(_walk_anim, 0)
		if frame_tex != null and frame_tex.get_height() > 0:
			var s := height / float(frame_tex.get_height())
			sprite.scale = Vector2(s, s)
		add_child(sprite)

	_build_hp_bar(height)


func _build_hp_bar(height: float) -> void:
	_hp_bar = Node2D.new()
	_hp_bar.position = Vector2(0, -height - 16)
	add_child(_hp_bar)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.size = Vector2(66, 10)
	bg.position = Vector2(-33, -5)
	_hp_bar.add_child(bg)

	_hp_fill = ColorRect.new()
	_hp_fill.color = Color(0.85, 0.25, 0.25)
	_hp_fill.size = Vector2(62, 6)
	_hp_fill.position = Vector2(-31, -3)
	_hp_bar.add_child(_hp_fill)


func _process(delta: float) -> void:
	if not alive or _finished:
		return

	if blocker != null and is_instance_valid(blocker):
		_do_attack(delta)
		return

	if sprite and sprite.animation != _walk_anim:
		sprite.play(_walk_anim)

	_advance(delta)
	_update_hp_bar()


func _advance(delta: float) -> void:
	if _seg >= path.size():
		_reach_end()
		return
	var target := path[_seg]
	var to := target - position
	var dist := to.length()
	var step := speed * delta
	if dist <= step:
		position = target
		_seg += 1
		if _seg >= path.size():
			_reach_end()
	else:
		position += to / dist * step
	# vira o sprite conforme a direcao horizontal
	if sprite:
		if to.x < -1.0:
			sprite.flip_h = true
		elif to.x > 1.0:
			sprite.flip_h = false


func _do_attack(delta: float) -> void:
	if sprite and _attack_anim != _walk_anim and sprite.animation != _attack_anim:
		sprite.play(_attack_anim)
	_attack_cd -= delta
	if _attack_cd <= 0.0:
		_attack_cd = ATTACK_INTERVAL
		if blocker.has_method("take_damage"):
			blocker.take_damage(_damage_to_blocker())
	_update_hp_bar()


func _damage_to_blocker() -> float:
	return 6.0 + max_hp * 0.03


func engage(soldier: Node) -> void:
	blocker = soldier


func release() -> void:
	blocker = null


func take_damage(amount: float, is_magic := false) -> void:
	if not alive:
		return
	var dmg := amount
	if is_magic:
		dmg *= (1.0 - magic_resist)
	else:
		dmg = max(1.0, amount - armor)
	hp -= dmg
	_update_hp_bar()
	if hp <= 0.0:
		_die()


func _die() -> void:
	if not alive:
		return
	alive = false
	release()
	died.emit(self)
	queue_free()


func _reach_end() -> void:
	if _finished:
		return
	_finished = true
	alive = false
	leaked.emit(self)
	queue_free()


func _update_hp_bar() -> void:
	if _hp_fill == null:
		return
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	_hp_fill.size.x = 62.0 * ratio


## Progresso ao longo do caminho, para priorizar alvos.
func path_progress() -> float:
	if path.size() == 0:
		return 0.0
	var base := 0.0
	for i in range(1, min(_seg, path.size())):
		base += path[i - 1].distance_to(path[i])
	base += (path[_seg - 1].distance_to(position) if _seg >= 1 and _seg <= path.size() else 0.0)
	return base
