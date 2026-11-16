class_name KarteAnzeige extends Control
# Karte der Stunde oben rechts (06-draw.js › drawMini): Mauern und Böden, im Dungeon nur, was die Figur schon gesehen hat
# (Kartennebel, Umkreis 10 Zellen mit Sicht). Darauf: lebende Rudel (gelb), ungeöffnete Truhen (Quadrate), wache Gegner (rot),
# der Hüter (violett, wenn wach), die Pforte (Ring) und die Figur (weiß). Wird alle 0,2 s neu gezeichnet.

var game: Node
var karte: Karte
var seen := PackedByteArray()
var img: Image
var tex: ImageTexture
var t := 0.0

func setup(g: Node, k: Karte) -> void:
	game = g
	karte = k
	seen.resize(Karte.GW * Karte.GH)
	seen.fill(0 if k.indoor else 1)
	img = Image.create(Karte.GW, Karte.GH, false, Image.FORMAT_RGBA8)
	tex = ImageTexture.create_from_image(img)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paint()

func _process(delta: float) -> void:
	if karte == null:
		return
	t -= delta
	if t > 0.0:
		return
	t = 0.2
	if karte.indoor and game.hero:
		_reveal()
	_paint()
	queue_redraw()

func _reveal() -> void:
	var h: Vector3 = game.hero.global_position
	var hc := Vector2i(int(h.x / Karte.CELL), int(h.z / Karte.CELL))
	for dy in range(-10, 11):
		for dx in range(-10, 11):
			var c := hc + Vector2i(dx, dy)
			if not Karte.in_grid(c.x, c.y) or dx * dx + dy * dy > 100:
				continue
			var i := Karte.gi(c.x, c.y)
			if seen[i] == 1:
				continue
			var p := Vector3((c.x + 0.5) * Karte.CELL, 0, (c.y + 0.5) * Karte.CELL)
			if karte.wall(c.x, c.y) or game.sees(h, p):
				seen[i] = 1

func _paint() -> void:
	for y in Karte.GH:
		for x in Karte.GW:
			var i := Karte.gi(x, y)
			var col := Color(0, 0, 0, 0)
			if seen[i] == 1:
				if karte.grid[i] == 1:
					var nb := false
					for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						if not karte.wall(x + d.x, y + d.y):
							nb = true
					col = Color(0.62, 0.58, 0.5, 0.95) if nb or not karte.indoor else Color(0, 0, 0, 0)
					if karte.wh[i] < 50:
						col = Color(0.45, 0.42, 0.36, 0.8)
				else:
					col = Color(0.16, 0.15, 0.13, 0.7) if karte.indoor or karte.flr[i] != 0 else Color(0.12, 0.11, 0.1, 0.45)
			img.set_pixel(x, y, col)
	tex.update(img)

func _to_px(p: Vector3) -> Vector2:
	var s := size / Vector2(Karte.GW, Karte.GH)
	return Vector2(p.x / Karte.CELL, p.z / Karte.CELL) * s

func _seen_at(p: Vector3) -> bool:
	var c := Vector2i(int(p.x / Karte.CELL), int(p.z / Karte.CELL))
	return Karte.in_grid(c.x, c.y) and seen[Karte.gi(c.x, c.y)] == 1

func _draw() -> void:
	if karte == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.03, 0.05, 0.72))
	draw_texture_rect(tex, Rect2(Vector2.ZERO, size), false)
	draw_rect(Rect2(Vector2.ZERO, size), Color("3d3947"), false, 1.0)
	var packs := {}
	for f in game.foes:
		if f.state == Foe.St.DEAD or f.hidden:
			continue
		if f.kind == "boss":
			if game.boss_awake:
				draw_circle(_to_px(f.global_position), 4.0, Color("b06be0"))
		elif f.state == Foe.St.FIGHT:
			draw_circle(_to_px(f.global_position), 2.0, Color(0.9, 0.3, 0.25))
		elif _seen_at(f.global_position) and not packs.has(f.pack):
			packs[f.pack] = true
			draw_circle(_to_px(f.global_position), 2.5, Color(0.95, 0.82, 0.29))
	for c in game.chests:
		if not c.open and _seen_at(c.pos):
			var p := _to_px(c.pos)
			draw_rect(Rect2(p - Vector2(2.5, 2.5), Vector2(5, 5)), Color(0.85, 0.7, 0.4))
	if game.gate:
		draw_arc(_to_px(game.gate.global_position), 5.0, 0.0, TAU, 16, Color(0.56, 0.89, 0.88), 1.5)
	if game.hero:
		draw_circle(_to_px(game.hero.global_position), 3.0, Color.WHITE)
