class_name Tower
extends Node2D
## Torre construida em um ponto do mapa. Cuida de alvos, tiros e soldados.

var tower_id := ""
var kind := ""
var level_index := 0          # 0 = nivel 1
var pos := Vector2.ZERO
var rally := Vector2.ZERO     # ponto de encontro dos soldados (barracks)

var damage := 10.0
var range_radius := 220.0
var cooldown := 1.0
var projectile_kind := "arrow"
var splash := 0.0
var soldier_count := 0
var soldier_hp := 90.0
var soldier_damage := 7.0
var soldier_respawn := 9.0

var _cd := 0.0
var _soldiers: Array = []
var _respawn_timer := 0.0
var _selected := false

var sprite: Sprite2D = null


func setup(id: String, lvl_index: int, at: Vector2) -> void:
	tower_id = id
	level_index = lvl_index
	pos = at
	position = at
	rally = at
	var t: Dictionary = Data.towers[id]
	kind = t.kind
	var ld: Dictionary = t.levels[lvl_index]
	damage = float(ld.damage)
	range_radius = float(ld.range)
	cooldown = float(ld.cooldown)
	projectile_kind = ld.get("projectile", "arrow")
	splash = float(ld.get("splash", 0.0))
	soldier_count = int(ld.get("soldiers", 0))
	soldier_hp = float(ld.get("soldier_hp", 90))
	soldier_respawn = float(ld.get("respawn", 9.0))
	soldier_damage = damage
	_apply_research()
	z_index = 6

	sprite = Sprite2D.new()
	var tex_path: String = t.get("texture", "")
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
		sprite.centered = true
		if sprite.texture.get_height() > 0:
			var s := 150.0 / float(sprite.texture.get_height())
			sprite.scale = Vector2(s, s)
		sprite.position = Vector2(0, -10)
	add_child(sprite)


func _ready() -> void:
	# Soldados so podem ser criados depois de a torre entrar na arvore.
	if kind == "barracks":
		_spawn_all_soldiers()


func _apply_research() -> void:
	match kind:
		"archer":
			damage *= 1.0 + GameState.research_bonus("archer_damage")
			range_radius *= 1.0 + GameState.research_bonus("archer_range")
		"mage":
			damage *= 1.0 + GameState.research_bonus("mage_damage")
			range_radius *= 1.0 + GameState.research_bonus("mage_range")
		"artillery":
			damage *= 1.0 + GameState.research_bonus("artillery_damage")
			splash *= 1.0 + GameState.research_bonus("artillery_splash")
		"barracks":
			soldier_hp *= 1.0 + GameState.research_bonus("barracks_soldier_hp")
			soldier_damage *= 1.0 + GameState.research_bonus("barracks_damage")


func set_selected(v: bool) -> void:
	_selected = v
	queue_redraw()


func is_max_level() -> bool:
	return level_index >= Data.towers[tower_id].levels.size() - 1


func upgrade_cost() -> int:
	if is_max_level():
		return 0
	return int(Data.towers[tower_id].levels[level_index + 1].cost)


func sell_value() -> int:
	var total := 0
	for i in range(level_index + 1):
		total += int(Data.towers[tower_id].levels[i].cost)
	return int(total * 0.7)


func _process(delta: float) -> void:
	if kind == "barracks":
		_process_barracks(delta)
		return
	_cd -= delta
	if _cd > 0.0:
		return
	var target := _acquire()
	if target == null:
		return
	_cd = cooldown
	_fire(target)


func _acquire() -> Node:
	var best: Node = null
	var best_prog := -1.0
	var origin := global_position
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e.alive:
			continue
		if e.global_position.distance_to(origin) > range_radius:
			continue
		var prog: float = e.path_progress() if e.has_method("path_progress") else 0.0
		if prog > best_prog:
			best_prog = prog
			best = e
	return best


func _fire(target: Node) -> void:
	var p := Projectile.new()
	p.setup(projectile_kind, target, damage, kind == "mage", splash)
	p.global_position = global_position + Vector2(0, -20)
	get_parent().add_child(p)


# --------------------------------------------------------------------------- #
#  Barracks
# --------------------------------------------------------------------------- #
func _process_barracks(delta: float) -> void:
	_soldiers = _soldiers.filter(func(s): return is_instance_valid(s))
	if _soldiers.size() < soldier_count:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_spawn_soldier()
			_respawn_timer = soldier_respawn


func _spawn_all_soldiers() -> void:
	for i in range(soldier_count):
		_spawn_soldier()


func _spawn_soldier() -> void:
	var s := Soldier.new()
	var offset := Vector2(cos(_soldiers.size() * 1.5) * 30.0, 20.0)
	s.setup(rally + offset, self, soldier_damage, soldier_hp)
	s.died.connect(_on_soldier_died)
	get_parent().add_child(s)
	_soldiers.append(s)


func _on_soldier_died(_s: Soldier) -> void:
	_respawn_timer = soldier_respawn


func _draw() -> void:
	if _selected:
		draw_arc(Vector2.ZERO, range_radius, 0.0, TAU, 64, Color(0.95, 0.85, 0.4, 0.5), 3.0)
