extends ScreenBase
## Tela de carregar jogo: lista os 3 slots de save.


func _build() -> void:
	add_child(UiUtil.background("res://gamekit/td-gui/PNG/levels/bg.png"))
	add_back()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var v := UiUtil.vbox(18)
	center.add_child(v)
	v.add_child(UiUtil.title("Carregar Jogo", 56))
	v.add_child(UiUtil.spacer(12))

	for slot in range(GameState.SLOT_COUNT):
		v.add_child(_slot_row(slot))


func _slot_row(slot: int) -> Control:
	var summary := GameState.slot_summary(slot)
	var panel := UiUtil.panel()
	panel.custom_minimum_size = Vector2(720, 0)

	var h := UiUtil.hbox(20)
	panel.add_child(h)

	var info := UiUtil.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)

	info.add_child(UiUtil.header("Slot %d" % (slot + 1), 34))

	if summary.get("empty", true):
		info.add_child(UiUtil.label("-- vazio --", 26, UiUtil.MUTED))
		var newb := UiUtil.button("Nova Campanha", func() -> void: _create_here(slot), Vector2(220, 70))
		h.add_child(newb)
	else:
		var dl: String = GameState.DIFFICULTY.get(summary.difficulty, GameState.DIFFICULTY["normal"])["label"]
		info.add_child(UiUtil.label("%s - %s - Fases: %d - Estrelas: %d" % [
			summary.name, dl, summary.levels, summary.stars
		], 24, UiUtil.MUTED))

		var loadb := UiUtil.button("Carregar", func() -> void: _load_slot(slot), Vector2(220, 70))
		var delb := UiUtil.button("Apagar", func() -> void: _delete_slot(slot), Vector2(180, 70))
		delb.add_theme_color_override("font_color", UiUtil.RED)
		h.add_child(loadb)
		h.add_child(delb)

	return panel


func _create_here(slot: int) -> void:
	GameState.new_game(slot, "normal")
	nav("world_map")


func _load_slot(slot: int) -> void:
	if GameState.load_profile(slot):
		nav("world_map")


func _delete_slot(slot: int) -> void:
	GameState.delete_profile(slot)
	nav("load_game")
