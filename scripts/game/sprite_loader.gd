class_name SpriteLoader
extends RefCounted
## Carrega SpriteFrames a partir de uma pasta de PNGs com nomes tipo
## "<prefix>_<anim>_<numero>.png", tolerante a maiusculas e prefixos.

const ANIMS := ["idle", "walk", "run", "attack", "die", "hurt", "jump"]
const FPS := 8.0


## Retorna um SpriteFrames com todas as animacoes detectadas, ou null.
static func load_frames(dir_path: String) -> SpriteFrames:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return null

	# anim -> array de {num, file}
	var buckets := {}
	for f in dir.get_files():
		var lower := f.to_lower()
		if not lower.ends_with(".png"):
			continue
		var anim := _anim_of(lower)
		if anim == "":
			continue
		if not buckets.has(anim):
			buckets[anim] = []
		buckets[anim].append({"num": _trailing_number(f), "file": f})

	if buckets.is_empty():
		return null

	var frames := SpriteFrames.new()
	# Remove a animacao default para nao sobrar "default".
	if frames.has_animation("default"):
		frames.remove_animation("default")

	for anim in ANIMS:
		if not buckets.has(anim):
			continue
		var arr: Array = buckets[anim]
		arr.sort_custom(func(a, b): return a.num < b.num)
		frames.add_animation(anim)
		frames.set_animation_speed(anim, FPS)
		frames.set_animation_loop(anim, anim != "die" and anim != "attack")
		for item in arr:
			frames.add_frame(anim, load(dir_path.path_join(item.file)))

	return frames


## Animacao "de andar" preferida, com fallback.
static func locomotion_anim(frames: SpriteFrames) -> String:
	for a in ["walk", "run", "idle"]:
		if frames.has_animation(a):
			return a
	return frames.get_animation_names()[0] if frames.get_animation_names().size() > 0 else "default"


static func idle_anim(frames: SpriteFrames) -> String:
	for a in ["idle", "walk", "run"]:
		if frames.has_animation(a):
			return a
	return frames.get_animation_names()[0] if frames.get_animation_names().size() > 0 else "default"


static func attack_anim(frames: SpriteFrames) -> String:
	for a in ["attack", "walk", "idle"]:
		if frames.has_animation(a):
			return a
	return locomotion_anim(frames)


static func _anim_of(lower_name: String) -> String:
	for a in ANIMS:
		if lower_name.contains(a):
			return a
	return ""


static func _trailing_number(fname: String) -> int:
	var base := fname.get_basename()
	var digits := ""
	for i in range(base.length() - 1, -1, -1):
		var c := base[i]
		if c >= "0" and c <= "9":
			digits = c + digits
		else:
			break
	return int(digits) if digits != "" else 0


## Primeiro frame disponivel (para portar retratos/botoes estaticos).
static func first_texture(dir_path: String) -> Texture2D:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return null
	var best := ""
	for f in dir.get_files():
		var lower := f.to_lower()
		if not lower.ends_with(".png"):
			continue
		if not (lower.contains("idle") or lower.contains("walk") or lower.contains("run")):
			continue
		if best == "" or f < best:
			best = f
	return load(dir_path.path_join(best)) if best != "" else null
