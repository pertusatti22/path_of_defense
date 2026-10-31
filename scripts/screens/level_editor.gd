extends ScreenBase
## Editor de Fases: posiciona a rota e os pontos de construcao sobre o fundo.
## - Clique esquerdo adiciona/arrasta pontos; clique direito remove o mais proximo.
## - Teclas: G = grid, S = snap, Tab = alterna Rota/Torre.
## Salva em user://levels/level_<id>.json (a fase carrega esses ajustes na hora).

const EditorCanvas := preload("res://scripts/tools/editor_canvas.gd")
const LEVELS_DIR := "user://levels"
const GRID_SIZES := [32, 48, 64, 96, 128]

var _level_id := 1
var _bg := 1
var _path: Array[Vector2] = []
var _spots: Array[Vector2] = []
var _mode := "path"
var _grid_on := true
var _snap_on := true
var _grid_size := 64

var _canvas
var _bg_rect: TextureRect
var _status: Label
var _hint: Label
var _btn_path: Button
var _btn_spot: Button
var _btn_grid: Button
var _btn_snap: Button
var _btn_gridsize: Button
var _bar: Control
var _toggle_btn: Button
var _ui_visible := true

var _dragging := false
var _drag_list: Array = []
var _drag_index := -1


func _build() -> void:
	_bg_rect = TextureRect.new()
	_bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_rect)

	_canvas = EditorCanvas.new()
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.gui_input.connect(_on_canvas_input)
	add_child(_canvas)

	_build_toolbar()
	_build_hint()
	_load_level(_level_id)


func _build_toolbar() -> void:
	_bar = UiUtil.panel()
	_bar.position = Vector2(16, 16)
	add_child(_bar)

	var v := UiUtil.vbox(10)
	_bar.add_child(v)

	var r1 := UiUtil.hbox(8)
	v.add_child(r1)
	r1.add_child(UiUtil.label("Editor de Fases", 34, UiUtil.GOLD))
	r1.add_child(UiUtil.spacer(10))
	r1.add_child(UiUtil.small_button("<", func() -> void: _load_level(_level_id - 1), Vector2(60, 48)))
	r1.add_child(_lvl_chip())
	r1.add_child(UiUtil.small_button(">", func() -> void: _load_level(_level_id + 1), Vector2(60, 48)))
	r1.add_child(UiUtil.spacer(16))
	for i in range(1, 5):
		var bg_n: int = i
		var b := UiUtil.small_button("Fundo %d" % bg_n, func() -> void: _set_bg(bg_n), Vector2(140, 48))
		r1.add_child(b)
	r1.add_child(UiUtil.spacer(16))
	r1.add_child(UiUtil.small_button("< Menu", func() -> void: nav("main_menu"), Vector2(160, 48)))
	_toggle_btn = UiUtil.small_button("Ocultar Menu (H)", func() -> void: _toggle_ui(), Vector2(280, 48))
	r1.add_child(_toggle_btn)

	var r2 := UiUtil.hbox(8)
	v.add_child(r2)
	_btn_path = _toggle("Rota", true, func() -> void: _set_mode("path"))
	_btn_spot = _toggle("Pontos", false, func() -> void: _set_mode("spot"))
	r2.add_child(_btn_path)
	r2.add_child(_btn_spot)
	r2.add_child(UiUtil.spacer(16))
	_btn_grid = _toggle("Grid", true, func() -> void: _toggle_grid())
	r2.add_child(_btn_grid)
	_btn_snap = _toggle("Snap", true, func() -> void: _toggle_snap())
	r2.add_child(_btn_snap)
	_btn_gridsize = UiUtil.small_button("Grid 64", func() -> void: _cycle_grid(), Vector2(150, 48))
	r2.add_child(_btn_gridsize)
	r2.add_child(UiUtil.spacer(16))
	r2.add_child(UiUtil.small_button("Desfazer", func() -> void: _undo(), Vector2(160, 48)))
	r2.add_child(UiUtil.small_button("Limpar Rota", func() -> void: _clear("path"), Vector2(190, 48)))
	r2.add_child(UiUtil.small_button("Limpar Pontos", func() -> void: _clear("spot"), Vector2(220, 48)))
	r2.add_child(UiUtil.small_button("Salvar", _save, Vector2(160, 48)))


func _lvl_chip() -> Label:
	var l := UiUtil.label("", 30, UiUtil.PARCHMENT)
	l.custom_minimum_size = Vector2(170, 48)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.name = "LvlChip"
	return l


func _toggle(text: String, on: bool, cb: Callable) -> Button:
	var b := UiUtil.small_button(text, cb, Vector2(150, 48))
	b.toggle_mode = true
	b.button_pressed = on
	return b


func _build_hint() -> void:
	_hint = UiUtil.label(
		"Esquerdo: adicionar/arrastar  |  Direito: remover ponto  |  G: grid  |  S: snap  |  Tab: alternar modo",
		22, UiUtil.MUTED)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_left = 20
	_hint.offset_top = -48
	_hint.offset_bottom = -12
	add_child(_hint)

	_status = UiUtil.label("", 24, UiUtil.GOLD)
	_status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_status.offset_left = 20
	_status.offset_top = -92
	_status.offset_bottom = -52
	_status.offset_right = 900
	add_child(_status)


# --------------------------------------------------------------------------- #
#  Estado / carregamento
# --------------------------------------------------------------------------- #
func _load_level(id: int) -> void:
	_level_id = clampi(id, 1, Data.levels.size())
	_dragging = false
	_drag_index = -1

	var path := "%s/level_%d.json" % [LEVELS_DIR, _level_id]
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(d) == TYPE_DICTIONARY:
			_bg = int(d.get("background", _default_bg()))
			_path = _to_points(d.get("path", []))
			_spots = _to_points(d.get("spots", []))
			_apply_bg()
			_refresh()
			return

	var lv: Dictionary = Data.level(_level_id)
	_bg = _default_bg()
	_path = _copy_points(lv.get("path", []))
	_spots = _copy_points(lv.get("spots", []))
	_apply_bg()
	_refresh()


func _default_bg() -> int:
	return int(Data.level(_level_id).get("background", 1))


func _set_bg(n: int) -> void:
	_bg = clampi(n, 1, 4)
	_apply_bg()
	_refresh()


func _apply_bg() -> void:
	var p := Data.BACKGROUND_BASE % [_bg, _bg]
	_bg_rect.texture = load(p) if ResourceLoader.exists(p) else null


func _set_mode(m: String) -> void:
	_mode = m
	_btn_path.button_pressed = (m == "path")
	_btn_spot.button_pressed = (m == "spot")
	_refresh()


func _toggle_grid() -> void:
	_grid_on = _btn_grid.button_pressed
	_refresh()


func _toggle_snap() -> void:
	_snap_on = _btn_snap.button_pressed
	_refresh()


func _cycle_grid() -> void:
	var i := GRID_SIZES.find(_grid_size)
	_grid_size = GRID_SIZES[(i + 1) % GRID_SIZES.size()]
	_btn_gridsize.text = "Grid %d" % _grid_size
	_refresh()


# --------------------------------------------------------------------------- #
#  Entrada
# --------------------------------------------------------------------------- #
func _on_canvas_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		_canvas.hover = _snap_point(ev.position)
		_canvas.has_hover = true
		if _dragging and _drag_index >= 0:
			_drag_list[_drag_index] = _snap_point(ev.position)
		_canvas.queue_redraw()
		_update_status(ev.position)
	elif ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				_on_left_press(ev.position)
			else:
				_dragging = false
				_drag_index = -1
		elif ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
			_remove_nearest(ev.position)


func _on_left_press(pos: Vector2) -> void:
	var p := _snap_point(pos)
	var hit = _find_nearest(pos, 40.0)
	if hit != null:
		_drag_list = hit[0]
		_drag_index = hit[1]
		_dragging = true
		return
	if _mode == "path":
		_path.append(p)
		_drag_list = _path
		_drag_index = _path.size() - 1
	else:
		_spots.append(p)
		_drag_list = _spots
		_drag_index = _spots.size() - 1
	_dragging = true
	_refresh()


func _snap_point(pos: Vector2) -> Vector2:
	if not _snap_on:
		return pos
	var step := float(_grid_size)
	return Vector2(roundf(pos.x / step) * step, roundf(pos.y / step) * step)


## Retorna [lista, indice] do ponto mais proximo dentro do raio, ou null.
func _find_nearest(pos: Vector2, radius: float):
	var best = null
	var best_d := radius
	for i in _path.size():
		var d := pos.distance_to(_path[i])
		if d < best_d:
			best_d = d
			best = [_path, i]
	for i in _spots.size():
		var d := pos.distance_to(_spots[i])
		if d < best_d:
			best_d = d
			best = [_spots, i]
	return best


func _remove_nearest(pos: Vector2) -> void:
	var hit = _find_nearest(pos, 44.0)
	if hit == null:
		return
	hit[0].remove_at(hit[1])
	_refresh()


func _undo() -> void:
	if _mode == "path" and _path.size() > 0:
		_path.remove_at(_path.size() - 1)
	elif _mode == "spot" and _spots.size() > 0:
		_spots.remove_at(_spots.size() - 1)
	_refresh()


func _clear(which: String) -> void:
	if which == "path":
		_path.clear()
	else:
		_spots.clear()
	_refresh()


func _toggle_ui() -> void:
	_ui_visible = not _ui_visible
	if is_instance_valid(_bar):
		_bar.visible = _ui_visible
	if is_instance_valid(_hint):
		_hint.visible = _ui_visible
	if is_instance_valid(_status):
		_status.visible = _ui_visible
	if is_instance_valid(_toggle_btn):
		_toggle_btn.text = "Mostrar Menu (H)" if not _ui_visible else "Ocultar Menu (H)"


func _unhandled_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	if ev.keycode == KEY_H:
		_toggle_ui()
		return
	match ev.keycode:
		KEY_G:
			_btn_grid.button_pressed = not _btn_grid.button_pressed
			_toggle_grid()
		KEY_S:
			_btn_snap.button_pressed = not _btn_snap.button_pressed
			_toggle_snap()
		KEY_TAB:
			_set_mode("spot" if _mode == "path" else "path")


# --------------------------------------------------------------------------- #
#  Salvamento
# --------------------------------------------------------------------------- #
func _save() -> void:
	DirAccess.make_dir_recursive_absolute(LEVELS_DIR)
	var path := "%s/level_%d.json" % [LEVELS_DIR, _level_id]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_status.text = "ERRO ao salvar: %s" % path
		return
	var data := {
		"background": _bg,
		"path": _to_raw(_path),
		"spots": _to_raw(_spots),
	}
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	Data._load_level_overrides()
	_status.text = "Salvo! Fase %d usa estes dados. Arquivo: %s" % [_level_id, path]
	print("=== level_%d.json ===\n%s" % [_level_id, JSON.stringify(data, "  ")])


# --------------------------------------------------------------------------- #
#  Utilidades
# --------------------------------------------------------------------------- #
func _refresh(redraw := true) -> void:
	_canvas.path_points = _path
	_canvas.spots = _spots
	_canvas.show_grid = _grid_on
	_canvas.grid_size = _grid_size
	_canvas.bg_size = Vector2(1920, 1080)
	if redraw:
		_canvas.queue_redraw()
	var chip := _find_lvl_chip()
	if chip != null:
		chip.text = "Fase %d" % _level_id
	_update_status(_canvas.hover)


func _find_lvl_chip() -> Label:
	for c in get_children():
		if c is Control:
			var l := _dig_chip(c)
			if l != null:
				return l
	return null


func _dig_chip(node: Node) -> Label:
	for c in node.get_children():
		if c is Label and c.name == "LvlChip":
			return c
		var l := _dig_chip(c)
		if l != null:
			return l
	return null


func _update_status(pos: Vector2) -> void:
	_status.text = "Rota: %d pt  |  Pontos: %d  |  Fundo: %d  |  %s  |  Mouse: %d, %d" % [
		_path.size(), _spots.size(), _bg, ("SNAP" if _snap_on else "livre"), int(pos.x), int(pos.y)]


func _to_raw(arr: Array) -> Array:
	var out := []
	for v in arr:
		out.append([int(round(v.x)), int(round(v.y))])
	return out


func _to_points(raw: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for v in raw:
		if typeof(v) == TYPE_ARRAY and v.size() >= 2:
			out.append(Vector2(float(v[0]), float(v[1])))
	return out


func _copy_points(src: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for v in src:
		out.append(v)
	return out
