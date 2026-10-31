class_name ScreenBase
extends Control
## Classe base de todas as telas. Emite `navigate` para o roteador (main.gd).

signal navigate(screen_name: String, args: Dictionary)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiUtil.theme()
	_build()


## Sobrescrever nas telas concretas.
func _build() -> void:
	pass


func nav(screen_name: String, args: Dictionary = {}) -> void:
	navigate.emit(screen_name, args)


## Botao "voltar" ancorado no canto superior esquerdo.
func add_back(target: String = "main_menu") -> void:
	var b := UiUtil.button("< Voltar", func() -> void: nav(target), Vector2(200, 70))
	b.add_theme_font_size_override("font_size", 24)
	b.position = Vector2(24, 24)
	add_child(b)
