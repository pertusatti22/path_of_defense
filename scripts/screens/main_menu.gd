extends ScreenBase
## Menu principal: Nova Campanha, Carregar, Bestiario, Pesquisa, Configuracoes.


func _build() -> void:
	add_child(UiUtil.background("res://gamekit/td-gui/PNG/menu/bg.png"))

	var bg_dim := ColorRect.new()
	bg_dim.color = Color(0, 0, 0, 0.35)
	bg_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var menu := UiUtil.vbox(14)
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(menu)

	var logo := UiUtil.texture_icon("res://gamekit/td-gui/PNG/menu/logo.png", 520.0)
	logo.custom_minimum_size = Vector2(560, 180)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.add_child(logo)
	menu.add_child(UiUtil.title("PATH OF DEFENSE", 70))
	var sub := UiUtil.label("A Kingdom Rush inspired Tower Defense", 28, UiUtil.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(sub)
	menu.add_child(UiUtil.spacer(24))

	menu.add_child(_menu_button("Nova Campanha", _on_new_game, true))
	menu.add_child(_menu_button("Carregar Jogo", func() -> void: nav("load_game")))
	menu.add_child(_menu_button("Bestiario", func() -> void: nav("bestiary")))
	menu.add_child(_menu_button("Pesquisa", func() -> void: nav("research")))
	menu.add_child(_menu_button("Configuracoes", func() -> void: nav("settings")))
	if OS.is_debug_build():
		menu.add_child(_menu_button("Editor de Fases", func() -> void: nav("editor")))
	menu.add_child(_menu_button("Sair", func() -> void: get_tree().quit()))

	menu.add_child(UiUtil.spacer(16))
	var disc := UiUtil.label("Inimigos descobertos: %d/%d" % [GameState.discovered_count(), Data.enemies.size()], 26, UiUtil.MUTED)
	disc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(disc)


func _menu_button(text: String, cb: Callable, primary := false) -> Button:
	var b := UiUtil.button(text, cb, Vector2(520, 82))
	if primary:
		b.add_theme_color_override("font_color", UiUtil.GOLD)
	return b


func _on_new_game() -> void:
	_show_difficulty_overlay()


func _show_difficulty_overlay() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var box := UiUtil.panel()
	center.add_child(box)

	var v := UiUtil.vbox(16)
	box.add_child(v)

	v.add_child(UiUtil.title("Escolha a Dificuldade", 46))
	var desc := UiUtil.label("A dificuldade altera a vida dos inimigos e as recompensas.", 26, UiUtil.MUTED)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(desc)
	v.add_child(UiUtil.spacer(8))

	for diff in ["casual", "normal", "veteran"]:
		var label := "%s  (HP x%.2f)" % [GameState.DIFFICULTY[diff]["label"], GameState.DIFFICULTY[diff]["hp"]]
		var b := UiUtil.button(label, func() -> void: _start_new_game(diff), Vector2(560, 82))
		if diff == "normal":
			b.add_theme_color_override("font_color", UiUtil.GOLD)
		v.add_child(b)

	v.add_child(UiUtil.spacer(8))
	v.add_child(UiUtil.button("Cancelar", func() -> void: _close_overlay(dim, center), Vector2(260, 60)))


func _close_overlay(dim: Control, center: Control) -> void:
	dim.queue_free()
	center.queue_free()


func _start_new_game(diff: String) -> void:
	var slot := 0
	for i in range(GameState.SLOT_COUNT):
		if not GameState.slot_exists(i):
			slot = i
			break
	GameState.new_game(slot, diff)
	nav("world_map")
