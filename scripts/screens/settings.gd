extends ScreenBase
## Configuracoes: volumes de musica e efeitos.


func _build() -> void:
	add_child(UiUtil.background("res://gamekit/td-gui/PNG/menu/bg.png"))
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := UiUtil.panel()
	panel.custom_minimum_size = Vector2(720, 0)
	center.add_child(panel)

	var v := UiUtil.vbox(22)
	panel.add_child(v)

	v.add_child(UiUtil.title("Configuracoes", 48))
	v.add_child(UiUtil.spacer(10))

	v.add_child(UiUtil.header("Volume da Musica", 30))
	v.add_child(_slider(GameState.music_volume, func(val: float) -> void: _set_music(val)))

	v.add_child(UiUtil.header("Volume dos Efeitos", 30))
	v.add_child(_slider(GameState.sfx_volume, func(val: float) -> void: _set_sfx(val)))

	v.add_child(UiUtil.spacer(14))
	v.add_child(UiUtil.button("Voltar", func() -> void: nav("main_menu"), Vector2(300, 76)))


func _slider(value: float, cb: Callable) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(600, 40)
	s.value_changed.connect(cb)
	return s


func _set_music(val: float) -> void:
	GameState.music_volume = val
	GameState.save_settings()
	_apply_audio()


func _set_sfx(val: float) -> void:
	GameState.sfx_volume = val
	GameState.save_settings()
	_apply_audio()


func _apply_audio() -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(max(GameState.music_volume, 0.0001)))
	var idx2 := AudioServer.get_bus_index("SFX")
	if idx2 >= 0:
		AudioServer.set_bus_volume_db(idx2, linear_to_db(max(GameState.sfx_volume, 0.0001)))
