extends Control
## Roteador de telas. Mantem apenas uma tela ativa por vez.

const MainMenuScreen := preload("res://scripts/screens/main_menu.gd")
const LoadGameScreen := preload("res://scripts/screens/load_game.gd")
const WorldMapScreen := preload("res://scripts/screens/world_map.gd")
const BestiaryScreen := preload("res://scripts/screens/bestiary.gd")
const ResearchScreen := preload("res://scripts/screens/research.gd")
const SettingsScreen := preload("res://scripts/screens/settings.gd")
const BriefingScreen := preload("res://scripts/screens/briefing.gd")
const GameLevelScreen := preload("res://scripts/screens/game_level.gd")
const LevelEditorScreen := preload("res://scripts/screens/level_editor.gd")

var _current: Control = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	GameState.load_profile()
	show_screen("main_menu")


func show_screen(screen_name: String, args: Dictionary = {}) -> void:
	if is_instance_valid(_current):
		_current.queue_free()
		_current = null

	var scr: Control
	match screen_name:
		"load_game":
			scr = LoadGameScreen.new()
		"world_map":
			scr = WorldMapScreen.new()
		"bestiary":
			scr = BestiaryScreen.new()
		"research":
			scr = ResearchScreen.new()
		"settings":
			scr = SettingsScreen.new()
		"briefing":
			scr = BriefingScreen.new()
			scr.level_id = int(args.get("level_id", 1))
		"level":
			scr = GameLevelScreen.new()
			scr.level_id = int(args.get("level_id", 1))
		"editor":
			scr = LevelEditorScreen.new()
		_:
			scr = MainMenuScreen.new()

	if scr.has_signal("navigate"):
		scr.navigate.connect(show_screen)
	add_child(scr)
	_current = scr
