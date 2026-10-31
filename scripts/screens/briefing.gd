extends ScreenBase
## Briefing da fase: nome, descricao, inimigos previstos e botao de iniciar.

var level_id := 1


func _build() -> void:
	add_child(UiUtil.background("res://gamekit/td-gui/PNG/difficulty/bg.png"))
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.4)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var lvl := Data.level(level_id)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := UiUtil.panel()
	panel.custom_minimum_size = Vector2(900, 0)
	center.add_child(panel)

	var v := UiUtil.vbox(16)
	panel.add_child(v)

	v.add_child(UiUtil.title("Fase %d - %s" % [level_id, lvl.get("name", "?")], 52))
	var sub := UiUtil.label(lvl.get("subtitle", ""), 28, UiUtil.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	v.add_child(UiUtil.spacer(10))

	var brief := UiUtil.label(lvl.get("briefing", ""), 30)
	brief.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(brief)
	v.add_child(UiUtil.spacer(10))

	var dl: String = GameState.DIFFICULTY.get(GameState.difficulty, GameState.DIFFICULTY["normal"])["label"]
	var info := UiUtil.label("Dificuldade: %s    |    Ondas: %d    |    Ouro inicial: %d    |    Vidas: %d" % [
		dl, Data.wave_count(level_id), _start_gold(), _start_lives()
	], 26, UiUtil.GOLD)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(info)

	var enemies := _wave_enemies(level_id)
	if not enemies.is_empty():
		v.add_child(UiUtil.spacer(8))
		v.add_child(UiUtil.header("Inimigos desta fase:", 30))
		var names: Array[String] = []
		for e in enemies:
			names.append(Data.enemy(e).get("name", e))
		v.add_child(UiUtil.label(", ".join(names), 26, UiUtil.MUTED))

	v.add_child(UiUtil.spacer(18))
	var hb := UiUtil.hbox(20)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(hb)
	hb.add_child(UiUtil.button("< Voltar", func() -> void: nav("world_map"), Vector2(240, 76)))
	var start := UiUtil.button("Iniciar Batalha!", func() -> void: nav("level", {"level_id": level_id}), Vector2(360, 76))
	start.add_theme_color_override("font_color", UiUtil.GOLD)
	hb.add_child(start)


func _start_gold() -> int:
	var lvl := Data.level(level_id)
	var g := int(lvl.get("gold", 200)) * GameState.difficulty_mult("gold")
	return int(g + GameState.research_bonus("bonus_gold"))


func _start_lives() -> int:
	var lvl := Data.level(level_id)
	return int(lvl.get("lives", 20) + GameState.research_bonus("bonus_lives"))


func _wave_enemies(id: int) -> Array:
	var seen := {}
	var out := []
	for wave in Data.level(id).get("waves", []):
		for group in wave:
			var t = group.get("type", "")
			if t != "" and not seen.has(t):
				seen[t] = true
				out.append(t)
	return out
