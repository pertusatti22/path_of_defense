extends Node
## Data - banco de dados estatico do jogo: inimigos, torres, fases e pesquisa.
## Mantido em um unico autoload para facilitar o balanceamento do MVP.

const ENEMY_SPRITE_BASE := "res://gamekit/monster-enemy-game-sprites/PNG/%d"
const BOSS_SPRITE_BASE := "res://gamekit/boss-monster-game-sprites/boss_%d/PNG"

## ---------------------------------------------------------------------------
## INIMIGOS
## hp            -> vida base (dificuldade aplica multiplicador)
## speed         -> pixels/segundo
## bounty        -> ouro entregue ao morrer
## leak          -> vidas perdidas se chegar ao fim
## armor         -> reduz dano fisico fixo (min 1)
## magic_resist  -> % de reducao a dano magico (0..1)
## sprite        -> pasta com os frames animados
## height        -> altura alvo em pixels na tela
## ---------------------------------------------------------------------------
var enemies := {
	"bandit": {
		"name": "Bandit",
		"description": "Pequenos ladroes que atacam viajantes desavisados. Fracos e faceis de derrotar, mas aparecem em grande numero.",
		"hp": 45, "speed": 62.0, "bounty": 8, "leak": 1,
		"armor": 0, "magic_resist": 0.0,
		"sprite": ENEMY_SPRITE_BASE % 1, "height": 120.0,
	},
	"brigand": {
		"name": "Brigand",
		"description": "Salteadores endurecidos pela estrada. Carregam espadas crudeis e nao fogem de uma briga.",
		"hp": 90, "speed": 55.0, "bounty": 11, "leak": 1,
		"armor": 1, "magic_resist": 0.0,
		"sprite": ENEMY_SPRITE_BASE % 3, "height": 132.0,
	},
	"marauder": {
		"name": "Marauder",
		"description": "Veteranos brutais das tropas do caos. Aguentam muito dano antes de cair.",
		"hp": 170, "speed": 47.0, "bounty": 16, "leak": 2,
		"armor": 3, "magic_resist": 0.0,
		"sprite": ENEMY_SPRITE_BASE % 6, "height": 140.0,
	},
	"raider": {
		"name": "Crossbow Raider",
		"description": "Bandido armado com besta. Dispara a distancia, mas e fragil no corpo a corpo.",
		"hp": 110, "speed": 70.0, "bounty": 18, "leak": 2,
		"armor": 0, "magic_resist": 0.0,
		"sprite": ENEMY_SPRITE_BASE % 4, "height": 128.0,
	},
	"brute": {
		"name": "Ogre Brute",
		"description": "Um gigante atormentado. Armadura de couro grosso reduz ataques fisicos, mas a magia o atinge em cheio.",
		"hp": 360, "speed": 40.0, "bounty": 32, "leak": 4,
		"armor": 6, "magic_resist": -0.15,
		"sprite": ENEMY_SPRITE_BASE % 9, "height": 165.0,
	},
	"warlord": {
		"name": "Chaos Warlord",
		"description": "O campeao da vanguarda inimiga. Blindado, veloz e implacavel. Apenas as defesas mais fortes o detem.",
		"hp": 900, "speed": 44.0, "bounty": 90, "leak": 10,
		"armor": 10, "magic_resist": 0.2,
		"sprite": ENEMY_SPRITE_BASE % 10, "height": 190.0, "is_boss": true,
	},
}

## ---------------------------------------------------------------------------
## TORRES
## kind: "archer" (alvo unico), "artillery" (area), "mage" (magia),
##       "barracks" (invoca soldados que bloqueiam)
## levels: lista de melhorias; indice 0 = nivel 1 construido
## ---------------------------------------------------------------------------
var towers := {
	"archer": {
		"name": "Archer Tower",
		"kind": "archer",
		"description": "Arqueiros disparam flechas em um unico alvo a longa distancia.",
		"icon": "res://gamekit/td-gui/PNG/upgrade/ico_2.png",
		"texture": "res://gamekit/archer-tower-game-assets/PNG/12.png",
		"levels": [
			{"cost": 70, "damage": 9.0, "range": 230.0, "cooldown": 1.10, "projectile": "arrow"},
			{"cost": 90, "damage": 16.0, "range": 260.0, "cooldown": 0.95, "projectile": "arrow"},
			{"cost": 140, "damage": 26.0, "range": 300.0, "cooldown": 0.80, "projectile": "arrow"},
		],
	},
	"artillery": {
		"name": "Stone Artillery",
		"kind": "artillery",
		"description": "Catapultas lancam pedras que explodem em area, atingindo varios inimigos.",
		"icon": "res://gamekit/td-gui/PNG/upgrade/ico_6.png",
		"texture": "res://gamekit/stone-tower-game-assets/PNG/17.png",
		"levels": [
			{"cost": 95, "damage": 24.0, "range": 270.0, "cooldown": 2.00, "splash": 70.0, "projectile": "stone"},
			{"cost": 120, "damage": 40.0, "range": 300.0, "cooldown": 1.85, "splash": 80.0, "projectile": "stone"},
			{"cost": 170, "damage": 66.0, "range": 330.0, "cooldown": 1.70, "splash": 95.0, "projectile": "stone"},
		],
	},
	"mage": {
		"name": "Mage Tower",
		"kind": "mage",
		"description": "Magos conjuram projetis arcanos que ignoram armadura. Excelentes contra inimigos blindados.",
		"icon": "res://gamekit/td-gui/PNG/upgrade/ico_8.png",
		"texture": "res://gamekit/magic-tower-game-assets/PNG/18.png",
		"levels": [
			{"cost": 100, "damage": 18.0, "range": 240.0, "cooldown": 1.30, "projectile": "magic"},
			{"cost": 130, "damage": 30.0, "range": 265.0, "cooldown": 1.15, "projectile": "magic"},
			{"cost": 180, "damage": 48.0, "range": 295.0, "cooldown": 1.00, "projectile": "magic"},
		],
	},
	"barracks": {
		"name": "Militia Barracks",
		"kind": "barracks",
		"description": "Treina soldados que barram os inimigos no caminho, dando tempo para suas torres atirarem.",
		"icon": "res://gamekit/td-gui/PNG/upgrade/ico_4.png",
		"texture": "res://gamekit/support-tower-game-assets/PNG/2.png",
		"levels": [
			{"cost": 80, "damage": 7.0, "range": 150.0, "cooldown": 1.00, "soldiers": 2, "soldier_hp": 90.0, "respawn": 9.0},
			{"cost": 110, "damage": 11.0, "range": 175.0, "cooldown": 0.90, "soldiers": 2, "soldier_hp": 140.0, "respawn": 8.0},
			{"cost": 160, "damage": 17.0, "range": 200.0, "cooldown": 0.80, "soldiers": 3, "soldier_hp": 200.0, "respawn": 7.0},
		],
	},
}

## Ordem exibida na barra de construcao.
var tower_order := ["archer", "barracks", "mage", "artillery"]

## Projeteis (tamanho/velocidade/cor).
var projectiles := {
	"arrow": {"speed": 900.0, "radius": 8.0, "color": Color(0.95, 0.9, 0.6)},
	"stone": {"speed": 620.0, "radius": 16.0, "color": Color(0.55, 0.5, 0.45)},
	"magic": {"speed": 780.0, "radius": 12.0, "color": Color(0.6, 0.4, 1.0)},
	"enemy": {"speed": 700.0, "radius": 9.0, "color": Color(1.0, 0.3, 0.3)},
}

## ---------------------------------------------------------------------------
## FASES  (MVP: fase 1 completa, demais bloqueadas)
## path     -> waypoints em coordenadas do viewport (1920x1080)
## spots    -> locais de construcao
## waves    -> lista de ondas; cada onda lista de grupos
##            group: {type, count, spacing (s), delay (s)}
## ---------------------------------------------------------------------------
var levels := {
	1: {
		"id": 1,
		"name": "Southport",
		"subtitle": "A cidade costeira",
		"briefing": "Ladroes caminham para atacar Southport. Construa torres ao longo da estrada e detenha todas as 6 ondas!",
		"gold": 260,
		"lives": 20,
		"background": 1,
		"paths": [
			[
				Vector2(300, 250), Vector2(300, 640),
				Vector2(740, 640), Vector2(740, 230), Vector2(1200, 230),
				Vector2(1200, 720), Vector2(1560, 720), Vector2(1560, 360),
				Vector2(1720, 360),
			],
		],
		"spots": [
			Vector2(180, 130), Vector2(430, 430), Vector2(430, 780),
			Vector2(610, 430), Vector2(870, 130), Vector2(1050, 430),
			Vector2(1330, 130), Vector2(1330, 500), Vector2(1680, 520),
			Vector2(1450, 830), Vector2(900, 830), Vector2(180, 520),
		],
		"waves": [
			[ {"type": "bandit", "count": 6, "spacing": 1.0, "delay": 0.0} ],
			[ {"type": "bandit", "count": 8, "spacing": 0.85, "delay": 0.0} ],
			[
				{"type": "bandit", "count": 6, "spacing": 0.8, "delay": 0.0},
				{"type": "brigand", "count": 3, "spacing": 1.1, "delay": 5.0},
			],
			[ {"type": "brigand", "count": 10, "spacing": 0.7, "delay": 0.0} ],
			[
				{"type": "brigand", "count": 6, "spacing": 0.7, "delay": 0.0},
				{"type": "marauder", "count": 4, "spacing": 1.4, "delay": 4.0},
			],
			[
				{"type": "marauder", "count": 5, "spacing": 1.0, "delay": 0.0},
				{"type": "raider", "count": 4, "spacing": 0.9, "delay": 4.0},
				{"type": "brute", "count": 1, "spacing": 1.0, "delay": 10.0},
			],
		],
	},
	2: {"id": 2, "name": "The Farmlands", "subtitle": "Campos do reino", "background": 2, "locked": true},
	3: {"id": 3, "name": "The Outskirts", "subtitle": "Arredores da capital", "background": 3, "locked": true},
	4: {"id": 4, "name": "The Royal Wood", "subtitle": "Floresta real", "background": 4, "locked": true},
	5: {"id": 5, "name": "Silveroak Forest", "subtitle": "Bosque prateado", "background": 2, "locked": true},
	6: {"id": 6, "name": "The Dark Tower", "subtitle": "A torre sombria", "background": 3, "locked": true},
}


const BACKGROUND_BASE := "res://gamekit/td-tileset3/PNG/game_background_%d/game_background_%d.png"
const LEVELS_DIR := "user://levels"


## Carrega ajustes feitos no Editor de Fases (user://levels/level_<id>.json).
func _ready() -> void:
	_load_level_overrides()


## Caminho da imagem de fundo de uma fase (1..4).
func background_path(level_id: int) -> String:
	var bg := int(levels.get(level_id, {}).get("background", 1))
	return BACKGROUND_BASE % [bg, bg]


## Retorna lista de rotas da fase (sempre Array[PackedVector2Array]).
func get_paths(level_id: int) -> Array[PackedVector2Array]:
	var lv: Dictionary = levels.get(level_id, {})
	if lv.has("paths") and lv["paths"] is Array and lv["paths"].size() > 0:
		var out: Array[PackedVector2Array] = []
		for p in lv["paths"]:
			if p is Array:
				out.append(_to_packed(p))
			elif p is PackedVector2Array:
				out.append(p)
		if out.size() > 0:
			return out
	if lv.has("path") and lv["path"] is Array and lv["path"].size() > 0:
		var out2: Array[PackedVector2Array] = []
		out2.append(_to_packed(lv["path"]))
		return out2
	return []


func _to_packed(arr: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v in arr:
		if typeof(v) == TYPE_VECTOR2:
			out.append(v)
		elif typeof(v) == TYPE_ARRAY and v.size() >= 2:
			out.append(Vector2(float(v[0]), float(v[1])))
	return out


func _load_level_overrides() -> void:
	for id in levels.keys():
		var f_path := "%s/level_%d.json" % [LEVELS_DIR, int(id)]
		if not FileAccess.file_exists(f_path):
			continue
		var f := FileAccess.open(f_path, FileAccess.READ)
		if f == null:
			continue
		var parsed = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var lv: Dictionary = levels[id]
		if parsed.has("background"):
			lv["background"] = int(parsed["background"])
		if parsed.has("paths"):
			lv["paths"] = _to_points_array(parsed["paths"])
			continue
		if parsed.has("path"):
			lv["paths"] = [_to_points(parsed["path"])]
			continue


func _to_points_array(raw_paths: Array) -> Array:
	var out := []
	for p in raw_paths:
		if p is Array:
			out.append(_to_points(p))
	return out


func _to_points(raw: Array) -> Array:
	var out := []
	for v in raw:
		if typeof(v) == TYPE_ARRAY and v.size() >= 2:
			out.append(Vector2(float(v[0]), float(v[1])))
	return out

## ---------------------------------------------------------------------------
## PESQUISA / MELHORIAS (gastas com estrelas ganhas nas fases)
## effect: chave -> valor somado ao multiplicador/bonus correspondente
## ---------------------------------------------------------------------------
var research := [
	{"id": "archer_dmg_1", "track": "archer", "tier": 1, "cost": 1, "name": "Flechas Afiadas",
		"description": "+10% de dano das torres de arqueiro.", "effect": {"archer_damage": 0.10}},
	{"id": "archer_dmg_2", "track": "archer", "tier": 2, "cost": 2, "name": "Pontaria",
		"description": "+15% de alcance das torres de arqueiro.", "effect": {"archer_range": 0.15}},
	{"id": "archer_dmg_3", "track": "archer", "tier": 3, "cost": 3, "name": "Arcos Longos",
		"description": "+20% de dano e +10% de alcance dos arqueiros.", "effect": {"archer_damage": 0.20, "archer_range": 0.10}},

	{"id": "barracks_hp_1", "track": "barracks", "tier": 1, "cost": 1, "name": "Armaduras de Couro",
		"description": "+20% de vida dos soldados da milicia.", "effect": {"barracks_soldier_hp": 0.20}},
	{"id": "barracks_hp_2", "track": "barracks", "tier": 2, "cost": 2, "name": "Treinamento",
		"description": "+15% de dano dos soldados.", "effect": {"barracks_damage": 0.15}},
	{"id": "barracks_hp_3", "track": "barracks", "tier": 3, "cost": 3, "name": "Veteranos",
		"description": "Soldados revidam mais rapido e sao mais resistentes.", "effect": {"barracks_soldier_hp": 0.25, "barracks_damage": 0.15}},

	{"id": "mage_dmg_1", "track": "mage", "tier": 1, "cost": 1, "name": "Sabedoria Arcana",
		"description": "+12% de dano das torres magicas.", "effect": {"mage_damage": 0.12}},
	{"id": "mage_dmg_2", "track": "mage", "tier": 2, "cost": 2, "name": "Cristais de Mana",
		"description": "+15% de dano magico.", "effect": {"mage_damage": 0.15}},
	{"id": "mage_dmg_3", "track": "mage", "tier": 3, "cost": 3, "name": "Archmago",
		"description": "+25% de dano e +10% de alcance magico.", "effect": {"mage_damage": 0.25, "mage_range": 0.10}},

	{"id": "art_dmg_1", "track": "artillery", "tier": 1, "cost": 1, "name": "Pedras Maiores",
		"description": "+12% de dano da artilharia.", "effect": {"artillery_damage": 0.12}},
	{"id": "art_dmg_2", "track": "artillery", "tier": 2, "cost": 2, "name": "Polvora Negra",
		"description": "+15% de dano e +10% de area de explosao.", "effect": {"artillery_damage": 0.15, "artillery_splash": 0.10}},
	{"id": "art_dmg_3", "track": "artillery", "tier": 3, "cost": 3, "name": "Catapultas Pesadas",
		"description": "+25% de dano da artilharia.", "effect": {"artillery_damage": 0.25}},

	{"id": "eco_gold", "track": "economy", "tier": 1, "cost": 2, "name": "Tesouro do Reino",
		"description": "+60 de ouro no inicio de cada fase.", "effect": {"bonus_gold": 60}},
	{"id": "eco_lives", "track": "economy", "tier": 2, "cost": 3, "name": "Muralhas Reforcadas",
		"description": "+3 vidas em cada fase.", "effect": {"bonus_lives": 3}},
]


## Retorna a definicao de um inimigo ou um dicionario vazio.
func enemy(id: String) -> Dictionary:
	return enemies.get(id, {})


## Retorna a definicao de uma torre ou um dicionario vazio.
func tower(id: String) -> Dictionary:
	return towers.get(id, {})


## Retorna a definicao de uma fase.
func level(id: int) -> Dictionary:
	return levels.get(id, {})


## Total de ondas de uma fase.
func wave_count(level_id: int) -> int:
	return levels.get(level_id, {}).get("waves", []).size()
