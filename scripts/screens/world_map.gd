extends ScreenBase
## Mapa-mundi: selecao de fases. Nos posicionados manualmente sobre o fundo.

const NODE_POS := {
	1: Vector2(300, 720),
	2: Vector2(560, 520),
	3: Vector2(870, 690),
	4: Vector2(1180, 480),
	5: Vector2(1420, 700),
	6: Vector2(1660, 470),
}


func _build() -> void:
	add_child(UiUtil.background("res://gamekit/td-gui/PNG/levels/bg.png"))
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.25)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_build_topbar()

	# Caminho tracejado entre os nos.
	var path := Line2D.new()
	var pts: PackedVector2Array = []
	for id in range(1, Data.levels.size() + 1):
		pts.append(NODE_POS.get(id, Vector2.ZERO))
	path.points = pts
	path.width = 6.0
	path.default_color = Color(0.9, 0.8, 0.4, 0.5)
	path.z_index = -1
	add_child(path)

	for id in range(1, Data.levels.size() + 1):
		_add_level_node(id)

	add_back()


func _build_topbar() -> void:
	var bar := UiUtil.hbox(16)
	bar.position = Vector2(1180, 24)
	add_child(bar)

	bar.add_child(UiUtil.texture_icon("res://gamekit/td-gui/PNG/upgrade/star.png", 56.0))
	var star_lbl := UiUtil.header("x %d" % GameState.stars_available(), 36)
	star_lbl.custom_minimum_size = Vector2(120, 56)
	bar.add_child(star_lbl)
	bar.add_child(UiUtil.small_button("Bestiario", func() -> void: nav("bestiary"), Vector2(190, 60)))
	bar.add_child(UiUtil.small_button("Pesquisa", func() -> void: nav("research"), Vector2(190, 60)))
	bar.add_child(UiUtil.small_button("Config.", func() -> void: nav("settings"), Vector2(160, 60)))


func _add_level_node(id: int) -> void:
	var lvl := Data.level(id)
	if lvl.is_empty():
		return
	var unlocked := GameState.is_level_unlocked(id)
	var stars := GameState.stars_for(id)

	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 150)
	b.size = Vector2(150, 150)
	b.position = NODE_POS.get(id, Vector2.ZERO) - Vector2(75, 75)
	b.theme = UiUtil.theme()
	b.disabled = not unlocked
	b.text = "%d\n%s\n%s" % [id, lvl.get("name", "?"), _star_str(stars, unlocked)]
	b.add_theme_font_size_override("font_size", 22)
	if stars > 0:
		b.add_theme_color_override("font_color", UiUtil.GOLD)
	if unlocked:
		b.pressed.connect(func() -> void: nav("briefing", {"level_id": id}))
	add_child(b)


func _star_str(stars: int, unlocked: bool) -> String:
	if not unlocked:
		return "bloqueado"
	var s := ""
	for i in range(3):
		s += "*" if i < stars else "-"
	return s
