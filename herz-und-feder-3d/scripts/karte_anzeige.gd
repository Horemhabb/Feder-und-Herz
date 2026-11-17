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

# eine entzündete Feuerschale deckt die Karte im Umkreis auf
func reveal_around(pos: Vector3, rad: int) -> void:
	var c := Vector2i(int(pos.x / Karte.CELL), int(pos.z / Karte.CELL))
	for dy in range(-rad, rad + 1):
		for dx in range(-rad, rad + 1):
			if Karte.in_grid(c.x + dx, c.y + dy) and dx * dx + dy * dy <= rad * rad:
				seen[Karte.gi(c.x + dx, c.y + dy)] = 1

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
					# Mauern: nur die Kante zum Begehbaren, in hellem Gold; massives Gestein bleibt durchsichtig
					col = Color(0.98, 0.84, 0.52, 0.9) if nb else (Color(0, 0, 0, 0) if karte.indoor else Color(0.85, 0.72, 0.45, 0.28))
					if karte.wh[i] < 50:
						col = Color(0.85, 0.72, 0.45, 0.5)
				else:
					# Böden: ein Hauch Sand; Wege und Räume etwas kräftiger
					col = Color(0.92, 0.82, 0.6, 0.2) if karte.indoor or karte.flr[i] != 0 else Color(0.92, 0.82, 0.6, 0.07)
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
	# durchsichtig: nur ein dunkler Hauch, damit die Zeichen auf hellem Sand lesbar bleiben
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.04, 0.2))
	draw_texture_rect(tex, Rect2(Vector2.ZERO, size), false)
	# Rahmen wie eine Kartusche: feine Doppellinie in Gold, Rauten in den Ecken
	var gold := Color(0.9, 0.72, 0.36)
	draw_rect(Rect2(Vector2.ZERO, size), Color(gold, 0.85), false, 1.5)
	draw_rect(Rect2(Vector2(4, 4), size - Vector2(8, 8)), Color(gold, 0.3), false, 1.0)
	for e in [Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]:
		draw_colored_polygon(PackedVector2Array([e + Vector2(0, -6), e + Vector2(6, 0), e + Vector2(0, 6), e + Vector2(-6, 0)]), gold)
		draw_colored_polygon(PackedVector2Array([e + Vector2(0, -3), e + Vector2(3, 0), e + Vector2(0, 3), e + Vector2(-3, 0)]), Color(0.1, 0.08, 0.06))
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
	# Orte: Feuerschalen (Ring, entzündet gefüllt), Schreine, Seelenkrüge, Fundstück (Raute), Figur
	for st in game.orte.sites:
		if not _seen_at(st.pos):
			continue
		var q := _to_px(st.pos)
		match st.kind:
			"feuer":
				if st.done:
					draw_circle(q, 2.5, Color(1.0, 0.62, 0.25))
				else:
					draw_arc(q, 2.5, 0.0, TAU, 8, Color(1.0, 0.62, 0.25), 1.0)
			"schrein":
				if not st.done:
					draw_rect(Rect2(q - Vector2(1.5, 3), Vector2(3, 6)), st.gott.col)
			"krug":
				if not st.done:
					draw_circle(q, 2.0, Color(1.0, 0.35, 0.3))
			"relikt":
				if not st.done:
					draw_colored_polygon(PackedVector2Array([q + Vector2(0, -4), q + Vector2(4, 0), q + Vector2(0, 4), q + Vector2(-4, 0)]), Color(1.0, 0.85, 0.4))
			"figur":
				draw_circle(q, 2.5, Color(0.56, 0.89, 0.88))
			"helfer":
				draw_circle(q, 2.5, Color(0.8, 1.0, 0.6))
			"such":
				if not st.done and game.orte.helfer_talked:
					draw_circle(q, 1.8, Color(0.95, 0.95, 0.85))
	if game.gate:
		draw_arc(_to_px(game.gate.global_position), 5.0, 0.0, TAU, 16, Color(0.56, 0.89, 0.88), 1.5)
	if game.hero:
		# die Figur als Pfeil in Blickrichtung, mit weichem Schein
		var hp := _to_px(game.hero.global_position)
		var f: float = game.hero.face
		var v := Vector2(sin(f), cos(f))
		var q := Vector2(-v.y, v.x)
		draw_circle(hp, 7.0, Color(1.0, 0.9, 0.6, 0.18))
		draw_colored_polygon(PackedVector2Array([hp + v * 6.5, hp - v * 4.0 + q * 4.2, hp - v * 1.5, hp - v * 4.0 - q * 4.2]), Color(1.0, 0.97, 0.88))
