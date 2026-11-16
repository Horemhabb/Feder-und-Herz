class_name Karte extends RefCounted
# Kartengenerator der 2D-Fassung (03a-dungeon.js › genDungeon, genOutdoor), in Zellen statt Weltpixeln.
# Das Raster hat 52 × 40 Zellen; eine Zelle der 2D-Fassung (50 px) ist hier 2 m groß. Jede Zelle ist frei oder Mauer,
# Mauern haben eine Höhe in Pixeln der 2D-Fassung: unter 50 versperren sie nur den Weg, ab 50 auch Sicht und Geschosse.
# Ergebnis: grid/wh/flr, Räume, Start, Hüterbau, Rudel-Plätze, Truhen, Fässer, Hindernisse, Fackeln, Türme.

const GW := 52
const GH := 40
const CELL := 2.0          # Meter je Zelle
const WALLH := 96
const TOWER := 255
const DPROPS := {"tomb": [0, 1, 0, 2, 3, 6, 7, 9, 12], "ruin": [8, 9, 9, 10, 11, 12, 14, 3], "glass": [15, 15, 9, 8, 11, 12, 14, 2], "vault": [15, 0, 3, 7, 2, 12, 10, 6], "dorf": [3, 14, 8, 7, 3]}

var indoor := true
var kind := "tomb"           # tomb, ruin, glass, vault oder "" (Freiland)
var grid := PackedByteArray()   # 1 = Mauer
var wh := PackedByteArray()     # Mauerhöhe (Pixel der 2D-Fassung, 0–255)
var flr := PackedByteArray()  # 0 Raum, 1 Gang, 2 Gebäudeboden
var rooms: Array = []        # {x, y, w, h, shape, kind, cx, cy} in Zellen
var start := Vector2.ZERO    # in Zellen (Kommazahlen: Mitte einer Zelle = x + 0.5)
var lair := Vector2.ZERO
var spots: Array = []        # Rudel-Plätze: {p, style, way: [Vector2, Vector2], elite, extra}
var chests: Array = []       # {p, tier}
var casks: Array = []        # Fässer und Kisten: Vector2
var obst: Array = []         # Hindernisse: {p, r (Zellen), kind, v}
var sconces: Array = []      # Wandfackeln: {p, dir} (dir: 0 Mauer im Norden, 1 Mauer im Westen)
var towers: Array = []       # {x, y} (linke obere Zelle, 4 × 4)
var rugs: Array = []         # {x, y, w, h, col} in Zellen

static func gi(cx: int, cy: int) -> int:
	return cy * GW + cx

static func in_grid(cx: int, cy: int) -> bool:
	return cx >= 0 and cy >= 0 and cx < GW and cy < GH

func wall(cx: int, cy: int) -> bool:
	return not in_grid(cx, cy) or grid[gi(cx, cy)] == 1

func height(cx: int, cy: int) -> int:
	return wh[gi(cx, cy)] if in_grid(cx, cy) else WALLH

func _new_grid(solid: bool) -> void:
	grid.resize(GW * GH)
	wh.resize(GW * GH)
	flr.resize(GW * GH)
	grid.fill(1 if solid else 0)
	wh.fill(WALLH if solid else 0)
	flr.fill(0)
	rooms = []
	spots = []
	chests = []
	casks = []
	obst = []
	sconces = []
	towers = []
	rugs = []

func _open(cx: int, cy: int, fl := -1) -> void:
	if cx > 0 and cy > 0 and cx < GW - 1 and cy < GH - 1:
		var i := gi(cx, cy)
		grid[i] = 0
		wh[i] = 0
		if fl >= 0:
			flr[i] = fl

func _set_wall(cx: int, cy: int, h: int) -> void:
	if in_grid(cx, cy):
		var i := gi(cx, cy)
		grid[i] = 1
		wh[i] = h

static func cc(cx: int, cy: int) -> Vector2:
	return Vector2(cx + 0.5, cy + 0.5)

func _wall_nbrs(cx: int, cy: int) -> int:
	return int(wall(cx + 1, cy)) + int(wall(cx - 1, cy)) + int(wall(cx, cy + 1)) + int(wall(cx, cy - 1))

func _corner(x: int, y: int) -> bool:
	return (wall(x - 1, y) or wall(x + 1, y)) and (wall(x, y - 1) or wall(x, y + 1)) and not (wall(x - 1, y) and wall(x + 1, y)) and not (wall(x, y - 1) and wall(x, y + 1))

func _nooks(r: Dictionary) -> Array:
	var out := []
	for y in range(r.y, r.y + r.h):
		for x in range(r.x, r.x + r.w):
			if not wall(x, y) and _corner(x, y):
				out.append(cc(x, y))
	out.shuffle()
	return out

func _sides(r: Dictionary) -> Array:
	var out := []
	for y in range(r.y, r.y + r.h):
		for x in range(r.x, r.x + r.w):
			if not wall(x, y) and _wall_nbrs(x, y) == 1:
				out.append(cc(x, y))
	out.shuffle()
	return out

func _add_obst(p: Vector2, r: float, k: String, v: int) -> bool:
	if wall(int(p.x), int(p.y)):
		return false
	for q in obst:
		if q.p.distance_to(p) < q.r + r + 0.12:
			return false
	for c in chests:
		if c.p.distance_to(p) < r + 0.6:
			return false
	obst.append({"p": p, "r": r, "kind": k, "v": v})
	return true

func _add_chest(p: Vector2, tier: int) -> void:
	if wall(int(p.x), int(p.y)):
		return
	for q in obst:
		if q.p.distance_to(p) < q.r + 0.6:
			return
	chests.append({"p": p, "tier": tier})

func _add_casks(p: Vector2) -> void:
	for k in randi_range(2, 4):
		var q := p + Vector2(randf_range(-0.4, 0.4), randf_range(-0.4, 0.4))
		if not wall(int(q.x), int(q.y)):
			casks.append(q)

func _dress_walls(every: int) -> void:
	for cy in range(1, GH - 1):
		for cx in range(1, GW - 1):
			if wall(cx, cy):
				continue
			var hsh := (cx * 73 + cy * 151) % 97
			if height(cx, cy - 1) >= 80 and height(cx, cy - 1) != TOWER and hsh % every == 0:
				sconces.append({"p": Vector2(cx + 0.5, cy + 0.06), "dir": 0})
			elif height(cx - 1, cy) >= 80 and height(cx - 1, cy) != TOWER and hsh % every == 3:
				sconces.append({"p": Vector2(cx + 0.06, cy + 0.5), "dir": 1})

static func _wpick(pairs: Array):
	var sum := 0.0
	for p in pairs:
		sum += p[1]
	var r := randf() * sum
	for p in pairs:
		r -= p[1]
		if r <= 0.0:
			return p[0]
	return pairs[-1][0]

# ---------------------------------------------------------------- Dungeon
func gen_dungeon(dkind: String) -> void:
	_new_grid(true)
	indoor = true
	kind = dkind
	for t in 4000:
		if rooms.size() >= 11:
			break
		var shape: String = _wpick([["rect", 4], ["hall", 3], ["cross", 2], ["round", 2]])
		var w := randi_range(11, 14) if shape == "hall" else randi_range(7, 11)
		var h := randi_range(7, 8) if shape == "hall" else randi_range(6, 9)
		var x := randi_range(2, GW - w - 2)
		var y := randi_range(2, GH - h - 2)
		var clash := false
		for r in rooms:
			if x < r.x + r.w + 2 and x + w + 2 > r.x and y < r.y + r.h + 2 and y + h + 2 > r.y:
				clash = true
				break
		if clash:
			continue
		rooms.append({"x": x, "y": y, "w": w, "h": h, "shape": shape, "cx": x + w / 2.0, "cy": y + h / 2.0, "kind": ""})
	rooms.sort_custom(func(a, b): return a.cx < b.cx)
	rooms[0].kind = "start"
	var last: Array = rooms.slice(-4)
	last.sort_custom(func(a, b): return a.w * a.h > b.w * b.h)
	var boss: Dictionary = last[0]
	boss.kind = "boss"
	if boss.shape != "hall":
		boss.shape = "rect"
	var rest := rooms.filter(func(r): return r.kind == "")
	rest.sort_custom(func(a, b): return a.w * a.h < b.w * b.h)
	if rest.size() > 3:
		rest[0].kind = "schatz"
	for r in rooms:
		for y in range(r.y, r.y + r.h):
			for x in range(r.x, r.x + r.w):
				var dx: float = (x + 0.5 - r.x - r.w / 2.0) / (r.w / 2.0)
				var dy: float = (y + 0.5 - r.y - r.h / 2.0) / (r.h / 2.0)
				if r.shape == "round" and dx * dx + dy * dy > 1.02:
					continue
				if r.shape == "cross" and absf(dx) > 0.45 and absf(dy) > 0.45:
					continue
				_open(x, y, 0)
	for r in rooms:
		if r.shape == "hall":
			var x: int = r.x + 2
			while x < r.x + r.w - 2:
				_set_wall(x, r.y + 2, WALLH)
				_set_wall(x, r.y + r.h - 3, WALLH)
				x += 3
	var links := []
	var link := func(a: Dictionary, b: Dictionary) -> void:
		var ax := int(a.cx)
		var ay := int(a.cy)
		var bx := int(b.cx)
		var by := int(b.cy)
		var hfirst := randf() < 0.5
		var my := ay if hfirst else by
		var mx := bx if hfirst else ax
		var wd := randi_range(2, 3)
		for x in range(mini(ax, bx), maxi(ax, bx) + wd):
			for k in wd:
				if wall(x, my + k):
					_open(x, my + k, 1)
		for y in range(mini(ay, by), maxi(ay, by) + wd):
			for k in wd:
				if wall(mx + k, y):
					_open(mx + k, y, 1)
		links.append([a, b])
	for i in range(1, rooms.size()):
		var best: Dictionary = rooms[0]
		for j in i:
			if Vector2(rooms[j].cx, rooms[j].cy).distance_to(Vector2(rooms[i].cx, rooms[i].cy)) < Vector2(best.cx, best.cy).distance_to(Vector2(rooms[i].cx, rooms[i].cy)):
				best = rooms[j]
		link.call(best, rooms[i])
	if rooms.size() > 3:
		for k in 2:
			var a: Dictionary = rooms.pick_random()
			var b: Dictionary = rooms.pick_random()
			if a != b:
				link.call(a, b)
	start = Vector2(rooms[0].cx, rooms[0].cy)
	lair = Vector2(boss.cx, boss.cy)
	_dress_walls(7)
	var mix: Array = DPROPS.get(dkind, DPROPS.tomb)
	for r in rooms:
		var nk := _nooks(r)
		var sd := _sides(r)
		var n := 2 if r.kind == "start" else randi_range(2, 4)
		for k in n:
			if nk.is_empty():
				break
			_add_obst(nk.pop_back(), 0.44, "d", mix.pick_random())
		for k in randi_range(1, 2):
			if sd.is_empty():
				break
			_add_casks(sd.pop_back())
		if r.kind == "boss":
			rugs.append({"x": r.x + 2, "y": r.cy - 1, "w": r.w - 4, "h": 2, "col": Color("5c1f1c")})
			if not nk.is_empty():
				_add_chest(nk.pop_back(), 1)
		elif r.kind == "schatz":
			rugs.append({"x": r.cx - 1.5, "y": r.cy - 1.5, "w": 3, "h": 3, "col": Color("3d2a52")})
			_add_chest(Vector2(r.cx, r.cy), 2)
			spots.append({"p": Vector2(r.cx, r.cy), "style": "wache", "elite": true})
		elif r.kind != "start":
			if randf() < 0.6 and not nk.is_empty():
				_add_chest(nk.pop_back(), 0)
			if r.shape == "rect" and randf() < 0.4:
				rugs.append({"x": r.cx - 2, "y": r.cy - 1.2, "w": 4, "h": 2.4, "col": [Color("4a2420"), Color("2c3a4a"), Color("3f3520")].pick_random()})
			var style: String = "lager" if r.shape == "round" else ("streife" if r.shape == "hall" else ["ruhe", "lager", "wache", "hinterhalt"].pick_random())
			spots.append({"p": Vector2(r.cx + randf_range(-0.8, 0.8), r.cy + randf_range(-0.8, 0.8)), "style": style, "way": [Vector2(r.x + 2, r.cy), Vector2(r.x + r.w - 2, r.cy)]})
			if r.w * r.h >= 80:
				spots.append({"p": Vector2(r.x + 2, r.y + 2), "style": "ruhe", "extra": true})
	var ls := links.filter(func(l): return l[0].kind != "start" and l[1].kind != "start" and l[0].kind != "boss" and l[1].kind != "boss")
	ls.shuffle()
	for l in ls.slice(0, 2):
		var a: Dictionary = l[0]
		var b: Dictionary = l[1]
		spots.append({"p": Vector2((a.cx + b.cx) / 2.0, (a.cy + b.cy) / 2.0), "style": "streife", "way": [Vector2(a.cx, a.cy), Vector2(b.cx, b.cy)], "snap": true})

# ---------------------------------------------------------------- Freiland
func gen_outdoor(mix: Array) -> void:
	_new_grid(false)
	indoor = false
	kind = ""
	start = Vector2(4.8, GH / 2.0)
	var sx := int(start.x)
	var sy := int(start.y)
	var B := []
	for t in 3000:
		if B.size() >= 6:
			break
		var w := randi_range(8, 12)
		var h := randi_range(6, 9)
		var x := randi_range(9, GW - w - 3)
		var y := randi_range(3, GH - h - 3)
		var clash := x < sx + 9 and absf(y + h / 2.0 - sy) < 9
		for b in B:
			if x < b.x + b.w + 3 and x + w + 3 > b.x and y < b.y + b.h + 3 and y + h + 3 > b.y:
				clash = true
				break
		if clash:
			continue
		B.append({"x": x, "y": y, "w": w, "h": h, "ruin": randf_range(0.25, 0.85), "cx": x + w / 2.0, "cy": y + h / 2.0, "kind": ""})
	B.sort_custom(func(a, b): return a.cx < b.cx)
	if B.size() > 0:
		B[-1].ruin = 0.3
		B[-1].kind = "kapelle"
	# Wehrmauer quer durchs Gelände, mit Tor und Breschen
	var wx := int(GW * 0.36)
	var gate := randi_range(8, GH - 12)
	var blocked := false
	for b in B:
		if wx >= b.x - 2 and wx <= b.x + b.w + 1:
			blocked = true
	if not blocked:
		for y in range(2, GH - 2):
			if (y >= gate and y < gate + 4) or randf() < 0.07:
				continue
			_set_wall(wx, y, randi_range(14, 60) if randf() < 0.2 else WALLH)
			if y == gate - 1 or y == gate + 4:
				_set_wall(wx, y, WALLH + 30)
	for b in B:
		var side := randi_range(0, 3)
		var dpos := randi_range(b.x + 2, b.x + b.w - 4) if side < 2 else randi_range(b.y + 2, b.y + b.h - 4)
		for y in range(b.y, b.y + b.h):
			for x in range(b.x, b.x + b.w):
				var edge: bool = x == b.x or y == b.y or x == b.x + b.w - 1 or y == b.y + b.h - 1
				flr[gi(x, y)] = 2
				if not edge:
					continue
				var door: bool = (side == 0 and y == b.y and x >= dpos and x < dpos + 2) or (side == 1 and y == b.y + b.h - 1 and x >= dpos and x < dpos + 2) \
					or (side == 2 and x == b.x and y >= dpos and y < dpos + 2) or (side == 3 and x == b.x + b.w - 1 and y >= dpos and y < dpos + 2)
				if door or randf() < b.ruin * 0.1:
					continue
				_set_wall(x, y, randi_range(12, 44) if randf() < b.ruin * 0.55 else (randi_range(54, 80) if randf() < b.ruin * 0.5 else WALLH))
		if b.kind != "kapelle" and b.w >= 10 and randf() < 0.6:
			var px2: int = b.x + b.w / 2
			var gap := randi_range(b.y + 2, b.y + b.h - 4)
			for y in range(b.y + 1, b.y + b.h - 1):
				if y < gap or y > gap + 1:
					_set_wall(px2, y, randi_range(14, 50) if randf() < 0.3 else WALLH)
		var r := {"x": b.x + 1, "y": b.y + 1, "w": b.w - 2, "h": b.h - 2}
		var nk := _nooks(r)
		var sd := _sides(r)
		if b.kind == "kapelle":
			lair = Vector2(b.cx, b.cy)
			rugs.append({"x": b.x + 2, "y": b.cy - 0.8, "w": b.w - 4, "h": 1.6, "col": Color("5c1f1c")})
			_add_obst(Vector2(b.x + b.w - 2.5, b.cy), 0.48, "d", 6)
			var x: int = b.x + 2
			while x < b.x + b.w - 3:
				_add_obst(Vector2(x + 0.5, b.y + 2), 0.28, "d", 9)
				_add_obst(Vector2(x + 0.5, b.y + b.h - 2), 0.28, "d", 9)
				x += 3
			if not nk.is_empty():
				_add_chest(nk.pop_back(), 1)
		else:
			for k in randi_range(1, 3):
				if nk.is_empty():
					break
				_add_obst(nk.pop_back(), 0.4, "d", DPROPS.dorf.pick_random())
			for k in randi_range(1, 2):
				if sd.is_empty():
					break
				_add_casks(sd.pop_back())
			if randf() < 0.7 and not nk.is_empty():
				_add_chest(nk.pop_back(), 1 if randf() < 0.25 else 0)
			spots.append({"p": Vector2(b.cx, b.cy), "style": ["lager", "ruhe", "hinterhalt", "wache"].pick_random()})
		rooms.append({"x": r.x, "y": r.y, "w": r.w, "h": r.h, "cx": b.cx, "cy": b.cy, "kind": b.kind if b.kind != "" else "haus", "shape": "rect"})
	if lair == Vector2.ZERO:
		lair = Vector2(GW - 6, GH / 2.0)
	# zwei Türme als Landmarken
	var n := 0
	for t in 200:
		if n >= 2:
			break
		var x := randi_range(4, GW - 9)
		var y := randi_range(3, GH - 8)
		var free := true
		for yy in range(y - 2, y + 6):
			for xx in range(x - 2, x + 6):
				if wall(xx, yy) or (in_grid(xx, yy) and flr[gi(xx, yy)] != 0) or (absi(xx - sx) < 7 and absi(yy - sy) < 7):
					free = false
		for q in towers:
			if Vector2(q.x, q.y).distance_to(Vector2(x, y)) < 14:
				free = false
		if not free:
			continue
		for yy in range(y, y + 4):
			for xx in range(x, x + 4):
				_set_wall(xx, yy, TOWER)
		towers.append({"x": x, "y": y})
		n += 1
	_dress_walls(11)
	# Felsen, Glasnadeln und Wracks im offenen Land
	for i in 110:
		var p := Vector2(randf_range(2.4, GW - 2.4), randf_range(2.4, GH - 2.4))
		var r := randf_range(0.32, 0.8)
		var k: String = _wpick(mix)
		var cx := int(p.x)
		var cy := int(p.y)
		var clear := true
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if wall(cx + dx, cy + dy) or (in_grid(cx + dx, cy + dy) and flr[gi(cx + dx, cy + dy)] != 0):
					clear = false
		if not clear or p.distance_to(start) < 4.8:
			continue
		var near := false
		for q in obst:
			if q.p.distance_to(p) < q.r + r + 0.88:
				near = true
				break
		if not near:
			obst.append({"p": p, "r": r, "kind": k, "v": randi_range(0, 1) if k == "needle" else [0, 0, 1, 1, 2, 3, 4, 5].pick_random()})
	# Rudel im offenen Land
	n = 0
	for t in 400:
		if n >= 9:
			break
		var p := Vector2(randf_range(4, GW - 4), randf_range(4, GH - 4))
		if wall(int(p.x), int(p.y)) or flr[gi(int(p.x), int(p.y))] != 0 or p.distance_to(start) < 10.4:
			continue
		var close := false
		for q in spots:
			if q.p.distance_to(p) < 6.6:
				close = true
		if close:
			continue
		var a := randf() * TAU
		var to := Vector2(clampf(p.x + cos(a) * 8.4, 3, GW - 3), clampf(p.y + sin(a) * 8.4, 3, GH - 3))
		spots.append({"p": p, "style": ["streife", "streife", "lager", "ruhe", "hinterhalt"].pick_random(), "way": [p, _free_path(p, to)]})
		n += 1

func _free_path(a: Vector2, b: Vector2) -> Vector2:
	var steps := maxi(1, int(a.distance_to(b) / 0.24))
	var last := a
	for i in range(1, steps + 1):
		var q := a.lerp(b, float(i) / steps)
		if wall(int(q.x), int(q.y)):
			break
		last = q
	return last

# Breitensuche über freie Zellen (4er-Nachbarschaft): Abstand jeder Zelle zu (tx, ty) in Schritten, -1 = unerreichbar
func flood(tx: int, ty: int, block := PackedByteArray()) -> PackedInt32Array:
	var f := PackedInt32Array()
	f.resize(GW * GH)
	f.fill(-1)
	if wall(tx, ty):
		return f
	var q := [gi(tx, ty)]
	f[q[0]] = 0
	var i := 0
	while i < q.size():
		var c: int = q[i]
		i += 1
		var cx := c % GW
		var cy := c / GW
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: int = cx + d.x
			var ny: int = cy + d.y
			if wall(nx, ny):
				continue
			var n := gi(nx, ny)
			if f[n] < 0 and (block.is_empty() or block[n] == 0):
				f[n] = f[c] + 1
				q.append(n)
	return f
