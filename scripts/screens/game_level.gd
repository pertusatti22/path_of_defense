extends ScreenBase
## Cena de jogo: ondas, torres, economia, vitoria/derrota.

var level_id := 1

var _field: Node2D
var _path: PackedVector2Array = PackedVector2Array()
var _paths: Array[PackedVector2Array] = []
var _spots: Array = []                 # Vector2
var _spot_buttons: Array = []          # Button
var _towers: Dictionary = {}           # spot_index -> Tower

var _gold := 0
var _lives := 20
var _max_lives := 20

var _wave_index := 0                   # proxima onda (0-based) a iniciar
var _total_waves := 0
var _state := "prep"                   # prep | active | over
var _wave_elapsed := 0.0
var _schedule: Array = []              # {t, type}
var _spawn_ptr := 0
var _live_enemies := 0

var _selected_spot := -1

# HUD
var _lbl_gold: Label
var _lbl_lives: Label
var _lbl_wave: Label
var _btn_next: Button
var _bottom_bar: PanelContainer
var _bottom_content: HBoxContainer
var _toast: Label


func _build() -> void:
	var lvl := Data.level(level_id)
	_paths = Data.get_paths(level_id)
	if _paths.size() == 0:
		var old = lvl.get("path", PackedVector2Array())
		if old is Array and old.size() > 0:
			_paths.append(Data._to_packed(old))
	_path = _paths[0] if _paths.size() > 0 else PackedVector2Array()
	_spots = lvl.get("spots", [])
	_total_waves = Data.wave_count(level_id)

	_max_lives = int(lvl.get("lives", 20) + GameState.research_bonus("bonus_lives"))
	_lives = _max_lives
	_gold = int(int(lvl.get("gold", 200)) * GameState.difficulty_mult("gold") + GameState.research_bonus("bonus_gold"))

	# fundo
	add_child(UiUtil.background(Data.background_path(level_id)))
	var tint := ColorRect.new()
	tint.color = Color(0.9, 0.95, 1.0, 0.05)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tint)

	# campo (mundo)
	_field = Node2D.new()
	add_child(_field)
	_draw_path()

	# marcadores de construcao
	for i in range(_spots.size()):
		_add_spot(i, _spots[i])

	_build_hud()
	_build_bottom_bar()
	_refresh_hud()
	_show_toast("Toque nos circulos dourados para construir torres.")
	_show_tutorial()


func _show_tutorial() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			_close_overlay(dim, center))
	add_child(dim)
	add_child(center)

	var panel := UiUtil.panel()
	panel.custom_minimum_size = Vector2(880, 0)
	center.add_child(panel)

	var v := UiUtil.vbox(14)
	panel.add_child(v)
	v.add_child(UiUtil.title("Como Jogar", 48))
	v.add_child(UiUtil.label("1. Toque nos circulos dourados do mapa para abrir o menu de construcao.", 28))
	v.add_child(UiUtil.label("2. Escolha entre Arqueiro, Mago, Artilharia ou Quartel (soldados).", 28))
	v.add_child(UiUtil.label("3. Toque numa torre construida para Melhorar ou Vender.", 28))
	v.add_child(UiUtil.label("4. Clique em 'Iniciar Onda'. Nao deixe os inimigos chegarem ao fim!", 28, UiUtil.GOLD))
	v.add_child(UiUtil.spacer(10))
	v.add_child(UiUtil.button("Entendi!", func() -> void: _close_overlay(dim, center), Vector2(300, 72)))


func _close_overlay(dim: Node, center: Node) -> void:
	dim.queue_free()
	center.queue_free()


# --------------------------------------------------------------------------- #
#  Caminho
# --------------------------------------------------------------------------- #
func _draw_path() -> void:
	if _path.size() < 2:
		return
	var outline := Line2D.new()
	outline.points = _path
	outline.width = 46.0
	outline.default_color = Color(0.25, 0.17, 0.09)
	outline.joint_mode = Line2D.LINE_JOINT_ROUND
	outline.begin_cap_mode = Line2D.LINE_CAP_ROUND
	outline.end_cap_mode = Line2D.LINE_CAP_ROUND
	outline.z_index = -8
	_field.add_child(outline)

	var inner := Line2D.new()
	inner.points = _path
	inner.width = 34.0
	inner.default_color = Color(0.45, 0.33, 0.18)
	inner.joint_mode = Line2D.LINE_JOINT_ROUND
	inner.begin_cap_mode = Line2D.LINE_CAP_ROUND
	inner.end_cap_mode = Line2D.LINE_CAP_ROUND
	inner.z_index = -7
	_field.add_child(inner)


# --------------------------------------------------------------------------- #
#  HUD
# --------------------------------------------------------------------------- #
func _build_hud() -> void:
	var top := UiUtil.hbox(20)
	top.position = Vector2(28, 22)
	add_child(top)

	top.add_child(_stat_icon("res://gamekit/td-gui/PNG/interface_game/heart.png"))
	top.add_child(_stat_icon("res://gamekit/td-gui/PNG/interface_game/coin.png"))
	top.add_child(_stat_icon("res://gamekit/td-gui/PNG/interface_game/flag.png"))

	_btn_next = UiUtil.button("Iniciar Onda 1", _start_next_wave, Vector2(320, 76))
	_btn_next.position = Vector2(1480, 26)
	_btn_next.add_theme_color_override("font_color", UiUtil.GOLD)
	add_child(_btn_next)

	_lbl_wave = UiUtil.label("", 30, UiUtil.GOLD)

	var back := UiUtil.small_button("< Menu", func() -> void: nav("world_map"), Vector2(180, 60))
	back.position = Vector2(28, 150)
	add_child(back)

	_toast = UiUtil.label("", 32)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -700
	_toast.offset_right = 700
	_toast.offset_top = 170
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_color_override("font_color", UiUtil.GOLD)
	_toast.add_theme_constant_override("outline_size", 6)
	_toast.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	add_child(_toast)


var _stat_labels: Array[Label] = []

func _stat_icon(icon_path: String) -> Control:
	var box := UiUtil.hbox(6)
	var icon := UiUtil.texture_icon(icon_path, 56.0)
	box.add_child(icon)
	var lbl := UiUtil.label("0", 40, UiUtil.PARCHMENT)
	lbl.custom_minimum_size = Vector2(120, 56)
	box.add_child(lbl)
	_stat_labels.append(lbl)
	return box


func _refresh_hud() -> void:
	if _stat_labels.size() >= 3:
		_stat_labels[0].text = str(_lives)
		_stat_labels[1].text = str(_gold)
		_stat_labels[2].text = str(min(_wave_index, _total_waves))


func _show_toast(msg: String) -> void:
	_toast.text = msg


# --------------------------------------------------------------------------- #
#  Marcadores / construcao
# --------------------------------------------------------------------------- #
func _add_spot(index: int, at: Vector2) -> void:
	var b := Button.new()
	b.size = Vector2(96, 96)
	b.custom_minimum_size = b.size
	b.position = at - Vector2(48, 48)
	b.focus_mode = Control.FOCUS_NONE
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.9, 0.85, 0.5, 0.18)
	normal.set_corner_radius_all(48)
	normal.set_border_width_all(4)
	normal.border_color = Color(0.9, 0.8, 0.4, 0.7)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.95, 0.9, 0.5, 0.4)
	for st in [["normal", normal], ["hover", hover], ["pressed", hover], ["focus", hover]]:
		b.add_theme_stylebox_override(st[0], st[1])
	b.pressed.connect(func() -> void: _on_spot_pressed(index))
	var plus := UiUtil.title("+", 52)
	plus.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(plus)
	add_child(b)
	_spot_buttons.append(b)


func _on_spot_pressed(index: int) -> void:
	_selected_spot = index
	for i in range(_spot_buttons.size()):
		(_spot_buttons[i] as Button).button_pressed = false
	if _towers.has(index):
		_show_tower_panel(_towers[index])
	else:
		_show_build_bar()


func _build_bottom_bar() -> void:
	_bottom_bar = UiUtil.panel()
	_bottom_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_bottom_bar.offset_left = -580
	_bottom_bar.offset_right = 580
	_bottom_bar.offset_top = -230
	_bottom_bar.offset_bottom = -14
	_bottom_bar.visible = false
	add_child(_bottom_bar)

	_bottom_content = UiUtil.hbox(16)
	_bottom_bar.add_child(_bottom_content)


func _rebuild_bottom(children: Array) -> void:
	for c in _bottom_content.get_children():
		c.visible = false
		c.queue_free()
	for c in children:
		_bottom_content.add_child(c)
	_bottom_bar.visible = true


func _hide_bottom() -> void:
	_bottom_bar.visible = false
	for c in _bottom_content.get_children():
		c.visible = false
		c.queue_free()
	if _selected_spot >= 0 and _towers.has(_selected_spot):
		_towers[_selected_spot].set_selected(false)
	_selected_spot = -1


func _show_build_bar() -> void:
	var kids: Array = []
	var title := UiUtil.label("Construir:", 28, UiUtil.GOLD)
	title.custom_minimum_size = Vector2(180, 0)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kids.append(title)

	for tid in Data.tower_order:
		kids.append(_build_option(tid))

	kids.append(UiUtil.small_button("X", func() -> void: _hide_bottom(), Vector2(70, 80)))
	_rebuild_bottom(kids)


func _build_option(tid: String) -> Control:
	var t: Dictionary = Data.towers[tid]
	var cost := int(t.levels[0].cost)
	var afford := _gold >= cost

	var v := UiUtil.vbox(2)
	v.custom_minimum_size = Vector2(150, 0)

	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 120)
	var icon := UiUtil.texture_icon(t.get("icon", ""), 96.0)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.2, 0.14, 0.09, 0.95)
	normal.set_corner_radius_all(12)
	normal.set_border_width_all(3)
	normal.border_color = UiUtil.GOLD_DARK if afford else Color(0.4, 0.35, 0.3)
	b.add_theme_stylebox_override("normal", normal)
	b.disabled = not afford
	b.pressed.connect(func() -> void: _build_tower(tid))
	b.add_child(icon)
	v.add_child(b)

	var info := UiUtil.label("%s (%d)" % [t.name, cost], 20, UiUtil.GOLD if afford else UiUtil.MUTED)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(info)
	return v


func _build_tower(tid: String) -> void:
	if _selected_spot < 0 or _towers.has(_selected_spot):
		return
	var cost := int(Data.towers[tid].levels[0].cost)
	if _gold < cost:
		return
	_gold -= cost
	var tower := Tower.new()
	tower.setup(tid, 0, _spots[_selected_spot])
	tower.rally = _nearest_path_point(_spots[_selected_spot])
	_field.add_child(tower)
	# reposiciona o soldado inicial caso seja barracks
	if tower.kind == "barracks":
		pass
	_towers[_selected_spot] = tower
	_refresh_hud()
	_hide_bottom()


func _show_tower_panel(tower: Tower) -> void:
	tower.set_selected(true)
	var kids: Array = []
	var t: Dictionary = Data.towers[tower.tower_id]
	var header := UiUtil.label("%s  Nv %d" % [t.name, tower.level_index + 1], 30, UiUtil.GOLD)
	header.custom_minimum_size = Vector2(240, 0)
	header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kids.append(header)

	if not tower.is_max_level():
		var cost := tower.upgrade_cost()
		var b := UiUtil.button("Melhorar (%d)" % cost, func() -> void: _upgrade_tower(), Vector2(260, 80))
		b.disabled = _gold < cost
		kids.append(b)
	else:
		kids.append(UiUtil.label("Nivel maximo", 26, UiUtil.GREEN))

	kids.append(UiUtil.button("Vender (%d)" % tower.sell_value(), func() -> void: _sell_tower(), Vector2(240, 80)))
	kids.append(UiUtil.small_button("X", func() -> void: _hide_bottom(), Vector2(70, 80)))
	_rebuild_bottom(kids)


func _upgrade_tower() -> void:
	if _selected_spot < 0 or not _towers.has(_selected_spot):
		return
	var tower: Tower = _towers[_selected_spot]
	if tower.is_max_level():
		return
	var cost := tower.upgrade_cost()
	if _gold < cost:
		return
	_gold -= cost
	var new_lvl := tower.level_index + 1
	var spot_pos: Vector2 = _spots[_selected_spot]
	tower.queue_free()
	var nt := Tower.new()
	nt.setup(tower.tower_id, new_lvl, spot_pos)
	nt.rally = _nearest_path_point(spot_pos)
	_field.add_child(nt)
	_towers[_selected_spot] = nt
	_refresh_hud()
	_show_tower_panel(nt)


func _sell_tower() -> void:
	if _selected_spot < 0 or not _towers.has(_selected_spot):
		return
	var tower: Tower = _towers[_selected_spot]
	_gold += tower.sell_value()
	tower.queue_free()
	_towers.erase(_selected_spot)
	_refresh_hud()
	_hide_bottom()


func _nearest_path_point(p: Vector2) -> Vector2:
	var best := p
	var best_d := INF
	var i := 0
	while i < _path.size() - 1:
		var a := _path[i]
		var b := _path[i + 1]
		var closest := Geometry2D.get_closest_point_to_segment(p, a, b)
		var d := p.distance_to(closest)
		if d < best_d:
			best_d = d
			best = closest
		i += 1
	return best


# --------------------------------------------------------------------------- #
#  Ondas
# --------------------------------------------------------------------------- #
func _start_next_wave() -> void:
	if _state != "prep":
		return
	if _wave_index >= _total_waves:
		return
	_build_schedule(_wave_index)
	_state = "active"
	_wave_elapsed = 0.0
	_spawn_ptr = 0
	_btn_next.visible = false
	_show_toast("Onda %d de %d!" % [_wave_index + 1, _total_waves])


func _build_schedule(wave_idx: int) -> void:
	_schedule.clear()
	var wave: Array = Data.level(level_id).waves[wave_idx]
	for group in wave:
		var t0 := float(group.get("delay", 0.0))
		var spacing := float(group.get("spacing", 1.0))
		var pidx := int(group.get("path", 0))
		for i in range(int(group.get("count", 1))):
			_schedule.append({"t": t0 + i * spacing, "type": group.get("type", "bandit"), "path": pidx})
	_schedule.sort_custom(func(a, b): return a.t < b.t)


func _process(delta: float) -> void:
	if _state != "active":
		return
	_wave_elapsed += delta
	while _spawn_ptr < _schedule.size() and _schedule[_spawn_ptr].t <= _wave_elapsed:
		var s: Dictionary = _schedule[_spawn_ptr]
		_spawn_enemy_group(s)
		_spawn_ptr += 1
	if _spawn_ptr >= _schedule.size() and _live_enemies <= 0:
		_wave_complete()


func _spawn_enemy(type_id: String) -> void:
	var e := Enemy.new()
	var data: Dictionary = Data.enemies[type_id]
	var ed: Variant = data.get("path", -1)
	var p: PackedVector2Array = _path
	if typeof(ed) == TYPE_INT:
		var ei := int(ed)
		if ei >= 0 and ei < _paths.size():
			p = _paths[ei]
	e.setup(type_id, data, p, GameState.difficulty_mult("hp"))
	e.add_to_group("enemies")
	e.died.connect(_on_enemy_died)
	e.leaked.connect(_on_enemy_leaked)
	_field.add_child(e)
	_live_enemies += 1
	GameState.discover_enemy(type_id)


func _spawn_enemy_group(s: Dictionary) -> void:
	var e := Enemy.new()
	var type_id: String = s["type"]
	var data: Dictionary = Data.enemies[type_id]
	var p: PackedVector2Array = _path
	if s.has("path"):
		var pid_val: Variant = s["path"]
		if typeof(pid_val) == TYPE_INT:
			var pid := int(pid_val)
			if pid >= 0 and pid < _paths.size():
				p = _paths[pid]
	e.setup(type_id, data, p, GameState.difficulty_mult("hp"))
	e.add_to_group("enemies")
	e.died.connect(_on_enemy_died)
	e.leaked.connect(_on_enemy_leaked)
	_field.add_child(e)
	_live_enemies += 1
	GameState.discover_enemy(type_id)


func _on_enemy_died(e: Enemy) -> void:
	_live_enemies = max(0, _live_enemies - 1)
	_gold += e.bounty
	_refresh_hud()


func _on_enemy_leaked(e: Enemy) -> void:
	_live_enemies = max(0, _live_enemies - 1)
	_lives -= e.leak_damage
	_refresh_hud()
	if _lives <= 0:
		_lives = 0
		_game_over(false)


func _wave_complete() -> void:
	_wave_index += 1
	_refresh_hud()
	if _wave_index >= _total_waves:
		_game_over(true)
		return
	_state = "prep"
	_btn_next.text = "Iniciar Onda %d" % (_wave_index + 1)
	_btn_next.visible = true
	_show_toast("Onda concluida! Ouro: %d" % _gold)


# --------------------------------------------------------------------------- #
#  Fim de jogo
# --------------------------------------------------------------------------- #
func _game_over(victory: bool) -> void:
	if _state == "over":
		return
	_state = "over"
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	_live_enemies = 0

	var stars := 0
	if victory:
		stars = 3 if _lives >= int(_max_lives * 0.9) else (2 if _lives >= int(_max_lives * 0.5) else 1)
		GameState.complete_level(level_id, stars)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := UiUtil.panel()
	panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(panel)
	var v := UiUtil.vbox(18)
	panel.add_child(v)

	if victory:
		v.add_child(UiUtil.title("Vitoria!", 64))
		v.add_child(UiUtil.title(_star_str(stars), 72))
		v.add_child(UiUtil.label("Southport esta a salvo! Vidas restantes: %d" % _lives, 30))
	else:
		v.add_child(UiUtil.title("Derrota", 64))
		v.add_child(UiUtil.label("As defesas cairam. Tente novamente!", 30, UiUtil.RED))

	v.add_child(UiUtil.spacer(14))
	var hb := UiUtil.hbox(20)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(hb)
	hb.add_child(UiUtil.button("Mapa", func() -> void: nav("world_map"), Vector2(240, 76)))
	hb.add_child(UiUtil.button("Tentar de Novo", func() -> void: nav("level", {"level_id": level_id}), Vector2(300, 76)))


func _star_str(stars: int) -> String:
	var s := ""
	for i in range(3):
		s += "* " if i < stars else "- "
	return s
