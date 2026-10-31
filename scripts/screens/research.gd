extends ScreenBase
## Pesquisa: melhorias permanentes compradas com estrelas ganhas nas fases.

const TRACK_NAMES := {
	"archer": "Arqueiros",
	"barracks": "Quartel",
	"mage": "Magos",
	"artillery": "Artilharia",
	"economy": "Economia",
}


func _build() -> void:
	add_child(UiUtil.background("res://gamekit/td-gui/PNG/upgrade/bg.png"))
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var top := UiUtil.vbox(6)
	top.position = Vector2(0, 80)
	top.size = Vector2(1920, 0)
	add_child(top)
	top.add_child(UiUtil.title("Pesquisa", 56))
	var stars := UiUtil.label("Estrelas disponiveis: %d" % GameState.stars_available(), 30, UiUtil.GOLD)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(stars)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(220, 250)
	scroll.size = Vector2(1480, 720)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 26)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	for track in ["archer", "barracks", "mage", "artillery", "economy"]:
		grid.add_child(_track_panel(track))

	add_back()

	var reset := UiUtil.small_button("Resetar Pesquisas", func() -> void: _reset(), Vector2(260, 60))
	reset.position = Vector2(1600, 24)
	add_child(reset)


func _track_panel(track: String) -> Control:
	var panel := UiUtil.panel()
	panel.custom_minimum_size = Vector2(700, 0)
	var v := UiUtil.vbox(10)
	panel.add_child(v)
	v.add_child(UiUtil.header(TRACK_NAMES.get(track, track), 34))

	for r in Data.research:
		if r.track != track:
			continue
		v.add_child(_research_row(r))
	return panel


func _research_row(r: Dictionary) -> Control:
	var researched := GameState.is_researched(r.id)
	var can := GameState.can_research(r)

	var h := UiUtil.hbox(12)
	var icon := UiUtil.texture_icon("res://gamekit/td-gui/PNG/upgrade/ico_%d.png" % (r.tier + 1), 60.0)
	h.add_child(icon)

	var info := UiUtil.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_col := UiUtil.GOLD if researched else UiUtil.PARCHMENT
	info.add_child(UiUtil.label("%s (Nivel %d)" % [r.name, r.tier], 26, name_col))
	info.add_child(UiUtil.label(r.description, 20, UiUtil.MUTED))
	h.add_child(info)

	if researched:
		h.add_child(UiUtil.label("OK", 30, UiUtil.GREEN))
	else:
		var b := UiUtil.small_button("%d*" % int(r.cost), func() -> void: _buy(r.id), Vector2(110, 60))
		b.disabled = not can
		h.add_child(b)
	return h


func _buy(id: String) -> void:
	GameState.buy_research(id)
	nav("research")


func _reset() -> void:
	GameState.reset_research()
	nav("research")
