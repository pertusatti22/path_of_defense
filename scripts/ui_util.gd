class_name UiUtil
extends RefCounted
## Fabrica de controles de UI e tema visual (estilo medieval do gamekit).

const GOLD := Color("#e8c65a")
const GOLD_DARK := Color("#8a6a22")
const WOOD := Color("#3a2718")
const WOOD_LIGHT := Color("#5a3d24")
const PARCHMENT := Color("#f0e2c0")
const INK := Color("#2a1c10")
const RED := Color("#a83232")
const GREEN := Color("#3f8f4a")
const MUTED := Color("#b9a888")

static var _theme: Theme = null


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = 30

	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = WOOD_LIGHT
	btn_normal.set_corner_radius_all(14)
	btn_normal.set_border_width_all(4)
	btn_normal.border_color = GOLD_DARK
	btn_normal.content_margin_left = 26
	btn_normal.content_margin_right = 26
	btn_normal.content_margin_top = 14
	btn_normal.content_margin_bottom = 14

	var btn_hover := btn_normal.duplicate()
	btn_hover.bg_color = Color("#6e4a2c")

	var btn_pressed := btn_normal.duplicate()
	btn_pressed.bg_color = WOOD

	var btn_disabled := btn_normal.duplicate()
	btn_disabled.bg_color = Color("#2a2018")
	btn_disabled.border_color = Color("#4a4038")

	for state in [["normal", btn_normal], ["hover", btn_hover], ["pressed", btn_pressed], ["disabled", btn_disabled], ["focus", btn_hover]]:
		t.set_stylebox(state[0], "Button", state[1])
	t.set_color("font_color", "Button", PARCHMENT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color("#6a5f50"))
	t.set_font_size("font_size", "Button", 30)

	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.13, 0.09, 0.06, 0.92)
	panel.set_corner_radius_all(18)
	panel.set_border_width_all(4)
	panel.border_color = GOLD_DARK
	panel.content_margin_left = 24
	panel.content_margin_right = 24
	panel.content_margin_top = 20
	panel.content_margin_bottom = 20
	t.set_stylebox("panel", "PanelContainer", panel)

	t.set_color("font_color", "Label", PARCHMENT)
	_theme = t
	return t


## Botao de menu padrao.
static func button(text: String, on_press: Callable = Callable(), size := Vector2(420, 92)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	if on_press.is_valid():
		b.pressed.connect(on_press)
	return b


## Botao pequeno (icone/texto curto).
static func small_button(text: String, on_press: Callable = Callable(), size := Vector2(180, 70)) -> Button:
	var b := button(text, on_press, size)
	b.add_theme_font_size_override("font_size", 24)
	return b


static func title(text: String, fsize := 64) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", GOLD)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	return l


static func header(text: String, fsize := 40) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", GOLD)
	return l


static func label(text: String, fsize := 28, color := PARCHMENT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## TextureRect de fundo que preenche a tela.
static func background(path: String) -> TextureRect:
	var tr := TextureRect.new()
	if ResourceLoader.exists(path):
		tr.texture = load(path)
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


static func texture_icon(path: String, size: float) -> TextureRect:
	var tr := TextureRect.new()
	if ResourceLoader.exists(path):
		tr.texture = load(path)
	tr.custom_minimum_size = Vector2(size, size)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return tr


static func spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


## Container horizontal/vertical de conveniencia.
static func vbox(sep := 14) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 14) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


## Painel de fundo (PanelContainer) com conteudo centralizado.
static func panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", theme().get_stylebox("panel", "PanelContainer"))
	return p


## Cria uma cena-semente (raiz Control) pronta para uso.
static func root_control() -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.theme = theme()
	return c
