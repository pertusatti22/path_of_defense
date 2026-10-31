extends Node
## GameState - progresso do jogador, save/load, bestiario e pesquisa.
## Singleton acessado globalmente como `GameState`.

signal profile_changed

const SAVE_VERSION := 1
const SLOT_COUNT := 3

var current_slot := -1
var player_name := "General"
var difficulty := "normal"

## Progresso
var completed := {}          # level_id (int) -> estrelas (int 1..3)
var bestiary := {}           # enemy_id -> true (ja encontrado)
var research := []           # lista de ids de pesquisas compradas

## Configuracoes (globais, fora do save de campanha)
var music_volume := 0.8
var sfx_volume := 0.8

const SETTINGS_PATH := "user://settings.cfg"

## Multiplicadores de dificuldade
const DIFFICULTY := {
	"casual": {"hp": 0.8, "gold": 1.15, "label": "Casual"},
	"normal": {"hp": 1.0, "gold": 1.0, "label": "Normal"},
	"veteran": {"hp": 1.25, "gold": 0.9, "label": "Veteran"},
}


func _ready() -> void:
	randomize()
	load_settings()


# --------------------------------------------------------------------------- #
#  Save slots
# --------------------------------------------------------------------------- #
func _slot_path(slot: int) -> String:
	return "user://save_%d.json" % slot


func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))


## Le apenas o cabecalho de um slot para a tela de Load Game.
func slot_summary(slot: int) -> Dictionary:
	if not slot_exists(slot):
		return {"empty": true, "slot": slot}
	var f := FileAccess.open(_slot_path(slot), FileAccess.READ)
	if f == null:
		return {"empty": true, "slot": slot}
	var txt := f.get_as_text()
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		return {"empty": true, "slot": slot}
	var stars := 0
	for v in data.get("completed", {}).values():
		stars += int(v)
	return {
		"empty": false,
		"slot": slot,
		"name": data.get("player_name", "General"),
		"difficulty": data.get("difficulty", "normal"),
		"stars": stars,
		"levels": data.get("completed", {}).size(),
	}


func new_game(slot: int, diff: String) -> void:
	current_slot = slot
	player_name = "General"
	difficulty = diff
	completed = {}
	bestiary = {}
	research = []
	save_profile()
	profile_changed.emit()


func load_profile(slot: int = -1) -> bool:
	if slot < 0:
		slot = current_slot
	if slot < 0 or not slot_exists(slot):
		return false
	current_slot = slot
	var f := FileAccess.open(_slot_path(slot), FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return false
	player_name = data.get("player_name", "General")
	difficulty = data.get("difficulty", "normal")
	completed = _keys_to_int(data.get("completed", {}))
	bestiary = data.get("bestiary", {})
	research = data.get("research", [])
	profile_changed.emit()
	return true


func save_profile() -> void:
	if current_slot < 0:
		return
	var data := {
		"version": SAVE_VERSION,
		"player_name": player_name,
		"difficulty": difficulty,
		"completed": completed,
		"bestiary": bestiary,
		"research": research,
	}
	var f := FileAccess.open(_slot_path(current_slot), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))
		f.close()


func delete_profile(slot: int) -> void:
	if slot_exists(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_slot_path(slot)))


## JSON sempre volta strings como chaves; converte para int.
func _keys_to_int(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d.keys():
		out[int(k)] = d[k]
	return out


# --------------------------------------------------------------------------- #
#  Progresso / estrelas
# --------------------------------------------------------------------------- #
func stars_for(level_id: int) -> int:
	return int(completed.get(level_id, 0))


func stars_earned_total() -> int:
	var s := 0
	for v in completed.values():
		s += int(v)
	return s


func stars_spent() -> int:
	var s := 0
	for id in research:
		for r in Data.research:
			if r.id == id:
				s += int(r.cost)
	return s


func stars_available() -> int:
	return stars_earned_total() - stars_spent()


func is_level_unlocked(level_id: int) -> bool:
	if level_id <= 1:
		return true
	return completed.has(level_id - 1)


func complete_level(level_id: int, stars: int) -> void:
	var prev := stars_for(level_id)
	if stars > prev:
		completed[level_id] = stars
	save_profile()
	profile_changed.emit()


func total_levels() -> int:
	return Data.levels.size()


# --------------------------------------------------------------------------- #
#  Bestiario
# --------------------------------------------------------------------------- #
func is_discovered(enemy_id: String) -> bool:
	return bestiary.get(enemy_id, false)


func discover_enemy(enemy_id: String) -> bool:
	if is_discovered(enemy_id):
		return false
	bestiary[enemy_id] = true
	save_profile()
	return true


func discovered_count() -> int:
	return bestiary.size()


# --------------------------------------------------------------------------- #
#  Pesquisa
# --------------------------------------------------------------------------- #
func is_researched(id: String) -> bool:
	return research.has(id)


func can_research(r: Dictionary) -> bool:
	return not is_researched(r.id) and stars_available() >= int(r.cost)


func buy_research(id: String) -> bool:
	for r in Data.research:
		if r.id == id:
			if can_research(r):
				research.append(id)
				save_profile()
				profile_changed.emit()
				return true
			return false
	return false


func reset_research() -> void:
	research.clear()
	save_profile()
	profile_changed.emit()


## Soma o efeito de todas as pesquisas compradas para uma chave.
func research_bonus(key: String) -> float:
	var total := 0.0
	for id in research:
		for r in Data.research:
			if r.id == id:
				total += float(r.effect.get(key, 0.0))
	return total


func difficulty_mult(key: String) -> float:
	return float(DIFFICULTY.get(difficulty, DIFFICULTY["normal"]).get(key, 1.0))


# --------------------------------------------------------------------------- #
#  Configuracoes de audio (persistidas separadamente)
# --------------------------------------------------------------------------- #
func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		music_volume = cfg.get_value("audio", "music", 0.8)
		sfx_volume = cfg.get_value("audio", "sfx", 0.8)
