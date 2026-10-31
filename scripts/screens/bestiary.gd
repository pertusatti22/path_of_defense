extends ScreenBase
## Bestiario: enciclopedia de inimigos. Entradas sao reveladas ao encontra-los.


func _build() -> void:
	add_child(UiUtil.background("res://gamekit/td-gui/PNG/levels/bg.png"))
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var top := UiUtil.vbox(6)
	top.position = Vector2(0, 90)
	top.size = Vector2(1920, 0)
	add_child(top)
	var t := UiUtil.title("Bestiario", 56)
	top.add_child(t)
	var c := UiUtil.label("Descobertos: %d / %d" % [GameState.discovered_count(), Data.enemies.size()], 28, UiUtil.MUTED)
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(c)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(160, 260)
	scroll.size = Vector2(1600, 720)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 28)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	for id in Data.enemies.keys():
		grid.add_child(_entry(id))

	add_back()


func _entry(id: String) -> Control:
	var e: Dictionary = Data.enemies[id]
	var discovered := GameState.is_discovered(id)

	var panel := UiUtil.panel()
	panel.custom_minimum_size = Vector2(500, 300)

	var h := UiUtil.hbox(16)
	panel.add_child(h)

	# Retrato
	var portrait := Control.new()
	portrait.custom_minimum_size = Vector2(140, 200)
	h.add_child(portrait)
	var rect := UiUtil.texture_icon("res://gamekit/td-gui/PNG/interface_game/frame.png", 140.0)
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.add_child(rect)
	if discovered:
		var spr := _idle_texture(e.get("sprite", ""))
		if spr:
			var spr_rect := TextureRect.new()
			spr_rect.texture = spr
			spr_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			spr_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			spr_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			portrait.add_child(spr_rect)
	else:
		var q := UiUtil.title("?", 80)
		q.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		portrait.add_child(q)

	var info := UiUtil.vbox(6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)

	if not discovered:
		info.add_child(UiUtil.header("???", 34))
		info.add_child(UiUtil.label("Enfrente este inimigo em batalha para revela-lo.", 22, UiUtil.MUTED))
		return panel

	info.add_child(UiUtil.header(e.get("name", id), 34))
	var desc := UiUtil.label(e.get("description", ""), 21, UiUtil.MUTED)
	desc.custom_minimum_size = Vector2(300, 0)
	info.add_child(desc)

	var stats := "HP: %d   Vel: %d\nOuro: %d   Dano a base: %d\nArmadura: %d   Resist. magica: %d%%" % [
		int(e.get("hp", 0)), int(e.get("speed", 0)),
		int(e.get("bounty", 0)), int(e.get("leak", 0)),
		int(e.get("armor", 0)), int(e.get("magic_resist", 0.0) * 100.0)
	]
	var sl := UiUtil.label(stats, 22, UiUtil.GOLD)
	info.add_child(sl)
	if e.get("is_boss", false):
		var bl := UiUtil.label("CHEFE", 22, UiUtil.RED)
		info.add_child(bl)

	return panel


## Pega o primeiro frame "idle/walk/run" de um inimigo para o retrato.
func _idle_texture(dir_path: String) -> Texture2D:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return null
	var best := ""
	for f in dir.get_files():
		var lower := f.to_lower()
		if not lower.ends_with(".png"):
			continue
		if lower.contains("idle") or lower.contains("walk") or lower.contains("run"):
			if best == "" or f < best:
				best = f
	return load(dir_path.path_join(best)) if best != "" else null
