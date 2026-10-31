extends Control
## Overlay de desenho do Editor de Fases: grid, rota (waypoints) e pontos de torre.

var path_points: Array[Vector2] = []
var spots: Array[Vector2] = []
var hover := Vector2.ZERO
var has_hover := false
var show_grid := true
var grid_size := 64
var bg_size := Vector2(1920, 1080)

const C_PATH := Color(0.30, 0.65, 1.0)
const C_PATH_SOFT := Color(0.30, 0.65, 1.0, 0.35)
const C_SPOT := Color(1.0, 0.85, 0.30)
const C_GRID := Color(1, 1, 1, 0.10)
const C_GRID_MAJOR := Color(1, 1, 1, 0.22)
const C_TEXT := Color(1, 1, 1, 0.95)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var fsize := ThemeDB.fallback_font_size

	if show_grid:
		var step: int = max(grid_size, 8)
		var x := 0
		while x <= int(bg_size.x):
			var major := (x % (step * 4)) == 0
			draw_line(Vector2(x, 0), Vector2(x, bg_size.y), C_GRID_MAJOR if major else C_GRID, 2.0 if major else 1.0)
			x += step
		var y := 0
		while y <= int(bg_size.y):
			var major2 := (y % (step * 4)) == 0
			draw_line(Vector2(0, y), Vector2(bg_size.x, y), C_GRID_MAJOR if major2 else C_GRID, 2.0 if major2 else 1.0)
			y += step

	for s in spots:
		draw_circle(s, 44.0, Color(C_SPOT.r, C_SPOT.g, C_SPOT.b, 0.18))
		draw_arc(s, 44.0, 0, TAU, 48, C_SPOT, 4.0, true)
		draw_line(s - Vector2(15, 0), s + Vector2(15, 0), C_SPOT, 4.0, true)
		draw_line(s - Vector2(0, 15), s + Vector2(0, 15), C_SPOT, 4.0, true)

	if path_points.size() >= 2:
		draw_polyline(path_points, Color(C_PATH.r, C_PATH.g, C_PATH.b, 0.35), 14.0, true)

	if path_points.size() > 0:
		draw_circle(path_points[0], 16.0, Color(0.25, 1.0, 0.35))
		draw_circle(path_points[path_points.size() - 1], 16.0, Color(1.0, 0.35, 0.35))

	for i in path_points.size():
		var p: Vector2 = path_points[i]
		draw_circle(p, 10.0, C_PATH)
		draw_arc(p, 10.0, 0, TAU, 24, Color(1, 1, 1, 0.8), 2.0, true)
		draw_string(font, p + Vector2(15, -10), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, fsize + 8, C_TEXT)

	if has_hover:
		draw_line(hover - Vector2(22, 0), hover + Vector2(22, 0), Color.WHITE, 2.0)
		draw_line(hover - Vector2(0, 22), hover + Vector2(0, 22), Color.WHITE, 2.0)
		draw_string(font, hover + Vector2(20, 36), "%d, %d" % [int(hover.x), int(hover.y)],
			HORIZONTAL_ALIGNMENT_LEFT, -1, fsize + 6, C_TEXT)
