class_name Deko extends RefCounted
# Ägyptische Kulisse aus Grundformen (Fassung 2.0): Obelisken, Wächterstatuen, Kolosse, Palmen, Felsen, Säulenstümpfe,
# Sarkophage, Wasserbecken, dazu die Orte zum Handeln (Feuerschale, Schrein, Seelenkrug, Fundstück).
# Jede Form wird einmal gebaut und dann geteilt: ein Körper je Stück, damit auch viele Stücke wenige Zeichenaufrufe kosten.

static var cache := {}

static func mat(key: String, col: Color, rough := 0.9, emis := Color.BLACK, e := 0.0, metal := 0.0) -> StandardMaterial3D:
	if cache.has(key):
		return cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	if e > 0.0:
		m.emission_enabled = true
		m.emission = emis
		m.emission_energy_multiplier = e
	cache[key] = m
	return m

# Stein mit der Textur der Mauern, über alle drei Achsen gelegt (keine eigenen UVs nötig)
static func stone(g: Node, key: String, surf_name: String, tint: Color) -> StandardMaterial3D:
	var k := "stein_%s_%s" % [key, g.get_instance_id()]
	if cache.has(k):
		return cache[k]
	var src: StandardMaterial3D = g.surf(surf_name)
	var m: StandardMaterial3D = src.duplicate()
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * 0.28
	m.albedo_color = tint
	g.mats[k] = m   # nimmt an „Grafik niedrig“ teil
	cache[k] = m
	return m

static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	# a b c d gegen den Uhrzeigersinn von außen gesehen
	var n := (b - a).cross(d - a).normalized()
	for v in [a, c, b, a, d, c]:
		st.set_normal(n)
		st.set_uv(Vector2(v.x + v.z, v.y) * 0.3)
		st.add_vertex(v)

# Quader, der sich nach oben verjüngt: Fuß b (x, z) bei y = 0, Kopf t bei y = h
static func taper(st: SurfaceTool, b: Vector2, t: Vector2, h: float, at := Vector3.ZERO) -> void:
	var c := [Vector3(-b.x, 0, b.y) / 2, Vector3(b.x, 0, b.y) / 2, Vector3(b.x, 0, -b.y) / 2, Vector3(-b.x, 0, -b.y) / 2]
	var d := [Vector3(-t.x, 0, t.y) / 2, Vector3(t.x, 0, t.y) / 2, Vector3(t.x, 0, -t.y) / 2, Vector3(-t.x, 0, -t.y) / 2]
	for i in 4:
		c[i] += at
		d[i] += at + Vector3(0, h, 0)
	for i in 4:
		var j := (i + 1) % 4
		_quad(st, c[i], c[j], d[j], d[i])
	_quad(st, d[0], d[1], d[2], d[3])

static func box(st: SurfaceTool, size: Vector3, at: Vector3) -> void:
	taper(st, Vector2(size.x, size.z), Vector2(size.x, size.z), size.y, at)

static func _begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st

static func _commit(parts: Array) -> ArrayMesh:
	# parts: [[SurfaceTool, Material], …] → ein Körper mit je einer Fläche pro Material
	var m := ArrayMesh.new()
	for p in parts:
		var st: SurfaceTool = p[0]
		st.set_material(p[1])
		st.generate_tangents()
		st.commit(m)
	return m

static func _put(g: Node, mesh: Mesh, pos: Vector3, rot := 0.0, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	g.add_child(mi)
	mi.global_position = pos
	mi.rotation.y = rot
	mi.scale = scl
	return mi

static func gold() -> StandardMaterial3D:
	return mat("gold", Color(0.9, 0.66, 0.24), 0.4, Color(1.0, 0.7, 0.25), 0.22, 0.6)

# ---------------------------------------------------------------- Bauten
static func obelisk(g: Node, pos: Vector3) -> Node3D:
	var k := "obelisk_%s" % g.get_instance_id()
	if not cache.has(k):
		var s := _begin()
		box(s, Vector3(1.3, 0.45, 1.3), Vector3.ZERO)
		taper(s, Vector2(0.95, 0.95), Vector2(0.62, 0.62), 5.4, Vector3(0, 0.45, 0))
		var au := _begin()
		taper(au, Vector2(0.62, 0.62), Vector2(0.04, 0.04), 0.75, Vector3(0, 5.85, 0))
		cache[k] = _commit([[s, stone(g, "hell", "sandstein", Color(1.15, 1.02, 0.84))], [au, gold()]])
	return _put(g, cache[k], pos)

static func anubis(g: Node, pos: Vector3, face: float) -> Node3D:
	var k := "anubis_%s" % g.get_instance_id()
	if not cache.has(k):
		var s := _begin()
		taper(s, Vector2(1.3, 2.6), Vector2(1.2, 2.5), 1.1)
		var au := _begin()
		box(au, Vector3(1.34, 0.12, 2.64), Vector3(0, 1.1, 0))
		box(au, Vector3(0.56, 0.1, 0.56), Vector3(0, 1.78, 0.45))
		var b := _begin()
		box(b, Vector3(0.55, 0.5, 1.5), Vector3(0, 1.22, -0.2))
		box(b, Vector3(0.5, 0.16, 0.75), Vector3(0, 1.22, 0.9))
		taper(b, Vector2(0.5, 0.55), Vector2(0.36, 0.4), 0.8, Vector3(0, 1.5, 0.45))
		box(b, Vector3(0.36, 0.34, 0.42), Vector3(0, 2.25, 0.5))
		box(b, Vector3(0.2, 0.18, 0.46), Vector3(0, 2.25, 0.92))
		for sx in [-0.11, 0.11]:
			taper(b, Vector2(0.13, 0.15), Vector2(0.02, 0.02), 0.52, Vector3(sx, 2.58, 0.42))
		cache[k] = _commit([[s, stone(g, "dunkel", "granit", Color(0.8, 0.8, 0.9))], [au, gold()], [b, mat("schwarz", Color(0.06, 0.06, 0.08), 0.45)]])
	return _put(g, cache[k], pos, face)

static func koloss(g: Node, pos: Vector3, face: float) -> Node3D:
	# sitzender König, vom Wind abgeschliffen
	var k := "koloss_%s" % g.get_instance_id()
	if not cache.has(k):
		var s := _begin()
		box(s, Vector3(1.8, 0.4, 2.4), Vector3.ZERO)
		box(s, Vector3(1.4, 1.3, 1.2), Vector3(0, 0.4, -0.45))
		box(s, Vector3(1.2, 1.3, 0.5), Vector3(0, 0.4, 0.55))
		box(s, Vector3(1.2, 0.45, 1.0), Vector3(0, 1.7, 0.3))
		taper(s, Vector2(1.1, 0.7), Vector2(1.45, 0.75), 1.5, Vector3(0, 1.7, -0.5))
		box(s, Vector3(0.62, 0.7, 0.62), Vector3(0, 3.2, -0.42))
		taper(s, Vector2(1.25, 0.5), Vector2(0.75, 0.7), 0.95, Vector3(0, 3.05, -0.6))
		cache[k] = _commit([[s, stone(g, "hell", "sandstein", Color(1.15, 1.02, 0.84))]])
	return _put(g, cache[k], pos, face)

static func stumpf(g: Node, pos: Vector3, h: float, lying: bool) -> Node3D:
	var cm := CylinderMesh.new()
	cm.top_radius = 0.4
	cm.bottom_radius = 0.44
	cm.height = h
	cm.radial_segments = 10
	cm.rings = 1
	var mi := _put(g, cm, pos + Vector3(0, 0.42 if lying else h / 2, 0), randf() * TAU)
	mi.material_override = stone(g, "hell", "sandstein", Color(1.15, 1.02, 0.84))
	if lying:
		mi.rotation.x = PI / 2
	return mi

static func sarkophag(g: Node, pos: Vector3, rot: float) -> Node3D:
	var k := "sarg_%s" % g.get_instance_id()
	if not cache.has(k):
		var s := _begin()
		box(s, Vector3(0.95, 0.7, 2.1), Vector3.ZERO)
		taper(s, Vector2(1.05, 2.2), Vector2(0.7, 1.9), 0.28, Vector3(0, 0.7, 0))
		var au := _begin()
		box(au, Vector3(1.0, 0.08, 0.3), Vector3(0, 0.74, 0.5))
		box(au, Vector3(1.0, 0.08, 0.3), Vector3(0, 0.74, -0.5))
		cache[k] = _commit([[s, stone(g, "dunkel", "granit", Color(0.8, 0.8, 0.9))], [au, gold()]])
	return _put(g, cache[k], pos, rot)

static func _rock_mesh(seed_i: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_i
	var rings := 4
	var segs := 7
	var pts := []
	for r in rings + 1:
		var row := []
		var phi := PI * r / rings
		for s in segs:
			var th := TAU * s / segs + r * 0.35
			var rad := 1.0 if r == 0 or r == rings else rng.randf_range(0.7, 1.12)
			row.append(Vector3(sin(phi) * cos(th) * rad, cos(phi) * 0.72 * rad, sin(phi) * sin(th) * rad))
		pts.append(row)
	var st := _begin()
	for r in rings:
		for s in segs:
			var a: Vector3 = pts[r][s]
			var b: Vector3 = pts[r][(s + 1) % segs]
			var c: Vector3 = pts[r + 1][(s + 1) % segs]
			var d: Vector3 = pts[r + 1][s]
			for tri in [[a, b, c], [a, c, d]]:
				if (tri[0] - tri[1]).length() < 0.001 or (tri[1] - tri[2]).length() < 0.001 or (tri[0] - tri[2]).length() < 0.001:
					continue
				var n: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
				var order: Array = tri
				if n.dot(tri[0] + tri[1] + tri[2]) < 0.0:
					n = -n
				else:
					order = [tri[0], tri[2], tri[1]]
				for v in order:
					st.set_normal(n)
					st.set_uv(Vector2(v.x, v.z))
					st.add_vertex(v)
	st.generate_tangents()
	return st.commit()

static func fels(g: Node, pos: Vector3, r: float, tint: Color) -> Node3D:
	var v := randi() % 5
	if not cache.has("fels%d" % v):
		cache["fels%d" % v] = _rock_mesh(1337 + v * 17)
	var mi := _put(g, cache["fels%d" % v], pos + Vector3(0, r * 0.38, 0), randf() * TAU, Vector3(r, r * randf_range(0.75, 1.15), r))
	mi.material_override = stone(g, "fels_%s" % tint.to_html(), "fels", tint * Color(0.62, 0.64, 0.72))
	return mi

# Material mit eigener Textur, über alle drei Achsen gelegt (Requisiten und Palmen brauchen so keine eigenen UVs)
static func tex_mat(key: String, datei: String, kachel := 1.0, tint := Color.WHITE, rough := 0.85) -> StandardMaterial3D:
	if cache.has("tex_" + key):
		return cache["tex_" + key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://textures/%s.jpg" % datei)
	m.albedo_color = tint
	var np := "res://textures/%s_n.jpg" % datei
	if ResourceLoader.exists(np):
		m.normal_enabled = true
		m.normal_texture = load(np)
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * kachel
	m.roughness = rough
	cache["tex_" + key] = m
	return m

# Drehteil aus gestapelten Kegelstümpfen: Profil [[Radius unten, Radius oben, Höhe], …]
static func _dreh(st: SurfaceTool, profil: Array, at := Vector3.ZERO, s := 1.0, seg := 12) -> void:
	var y := 0.0
	for p in profil:
		var cm := CylinderMesh.new()
		cm.bottom_radius = p[0] * s
		cm.top_radius = p[1] * s
		cm.height = p[2] * s
		cm.radial_segments = seg
		cm.rings = 1
		st.append_from(cm, 0, Transform3D(Basis(), at + Vector3(0, y + p[2] * s * 0.5, 0)))
		y += p[2] * s

const KRUG := [[0.10, 0.16, 0.06], [0.16, 0.36, 0.30], [0.36, 0.40, 0.22], [0.40, 0.30, 0.24], [0.30, 0.15, 0.14], [0.15, 0.13, 0.14], [0.13, 0.20, 0.05]]

# Krüge, Kisten und Körbe (statt der Fässer der alten Kulisse); jede Form wird einmal gebaut und geteilt
static func requisit(g: Node, art: String, pos: Vector3, rot := 0.0) -> MeshInstance3D:
	var k := "req_" + art
	if not cache.has(k):
		var ton := tex_mat("ton", "p01_ton", 1.6)
		var holz := tex_mat("holz", "p02_holz", 1.3)
		var korb := tex_mat("korb", "p05_korb", 2.4)
		var bronze := mat("bronze", Color(0.45, 0.3, 0.14), 0.5, Color.BLACK, 0.0, 0.7)
		var a := _begin()
		var b := _begin()
		var c := _begin()
		var d := _begin()
		var e := _begin()
		var f := _begin()
		match art:
			"amphore":
				_dreh(a, KRUG, Vector3.ZERO, 1.0)
				for sx in [-1, 1]:      # zwei Henkel
					box(a, Vector3(0.05, 0.3, 0.07), Vector3(sx * 0.3, 0.8, 0))
					box(a, Vector3(0.14, 0.05, 0.07), Vector3(sx * 0.24, 1.08, 0))
				_dreh(c, [[0.4, 0.4, 0.035]], Vector3(0, 0.56, 0))     # bemalter Reif
			"kruege":
				_dreh(a, KRUG, Vector3(-0.3, 0, 0.12), 0.72)
				_dreh(a, KRUG, Vector3(0.28, 0, 0.2), 0.6)
				_dreh(a, KRUG, Vector3(0.02, 0, -0.3), 0.85)
				_dreh(b, [[0.2, 0.2, 0.04]], Vector3(0.02, 0.98, -0.3), 0.85)   # Holzdeckel auf dem großen
			"kiste":
				box(b, Vector3(0.95, 0.6, 0.7), Vector3.ZERO)
				box(b, Vector3(1.0, 0.1, 0.75), Vector3(0, 0.6, 0))
				for sx in [-0.3, 0.3]:
					box(c, Vector3(0.07, 0.72, 0.76), Vector3(sx, 0, 0))
			"kisten":
				box(b, Vector3(0.95, 0.6, 0.7), Vector3(-0.3, 0, 0))
				box(b, Vector3(0.7, 0.5, 0.6), Vector3(0.55, 0, 0.2))
				box(b, Vector3(0.75, 0.45, 0.6), Vector3(-0.1, 0.6, 0.05))
				for sx in [-0.6, 0.0]:
					box(c, Vector3(0.07, 0.62, 0.72), Vector3(sx, 0, 0))
			"lampen":     # drei Öllämpchen aus Ton auf dem Boden, die Dochte glimmen
				for q in [Vector3(-0.22, 0, 0.1), Vector3(0.2, 0, 0.16), Vector3(0.0, 0, -0.2)]:
					_dreh(a, [[0.07, 0.13, 0.05], [0.13, 0.11, 0.04]], q)
					_dreh(d, [[0.03, 0.005, 0.09]], q + Vector3(0, 0.08, 0), 1.0, 6)
			"waffen":     # Grabbeigaben am Ständer: ein Rundschild lehnt daran, ein Speer und ein Sichelschwert hängen
				for sx in [-0.3, 0.3]:
					box(b, Vector3(0.07, 1.1, 0.07), Vector3(sx, 0, -0.12))
				box(b, Vector3(0.74, 0.06, 0.06), Vector3(0, 0.98, -0.12))
				var schild := CylinderMesh.new()
				schild.top_radius = 0.36
				schild.bottom_radius = 0.36
				schild.height = 0.05
				schild.radial_segments = 16
				schild.rings = 1
				var lehne := Basis(Vector3.RIGHT, PI / 2 - 0.32)
				e.append_from(schild, 0, Transform3D(lehne, Vector3(0, 0.4, 0.06)))
				var buckel := CylinderMesh.new()
				buckel.top_radius = 0.05
				buckel.bottom_radius = 0.12
				buckel.height = 0.07
				buckel.radial_segments = 10
				buckel.rings = 1
				c.append_from(buckel, 0, Transform3D(lehne, Vector3(0, 0.42, 0.12)))
				box(b, Vector3(0.035, 1.75, 0.035), Vector3(0.38, 0, -0.06))            # Speerschaft
				_dreh(c, [[0.05, 0.005, 0.2]], Vector3(0.38, 1.75, -0.06), 1.0, 6)    # Speerspitze
				box(c, Vector3(0.05, 0.5, 0.02), Vector3(-0.2, 0.46, -0.08))           # Sichelschwert: Klinge
				box(c, Vector3(0.16, 0.05, 0.02), Vector3(-0.13, 0.46, -0.08))         #   Sichel
				box(b, Vector3(0.05, 0.16, 0.03), Vector3(-0.2, 0.82, -0.08))          #   Griff
			"schatz":     # Grabschatz: Goldringe, Barren und ein Krug
				for i in 5:
					_dreh(e, [[0.16 - i * 0.012, 0.16 - i * 0.012, 0.05]], Vector3(-0.2, i * 0.05, 0.05))
				for i in 3:
					box(e, Vector3(0.3, 0.07, 0.12), Vector3(0.2, i * 0.07, -0.15 + i * 0.03))
				_dreh(a, KRUG, Vector3(0.22, 0, 0.25), 0.4)
				_dreh(e, [[0.07, 0.07, 0.03]], Vector3(0.05, 0, 0.3))
			"schutt", "schutt_klein":   # Bruchstein
				var rs := RandomNumberGenerator.new()
				rs.seed = 9 if art == "schutt" else 4
				for i in (6 if art == "schutt" else 3):
					var bb := Basis(Vector3.UP, rs.randf() * TAU).scaled(Vector3.ONE * rs.randf_range(0.18, 0.42))
					f.append_from(_rock_mesh(40 + i), 0, Transform3D(bb, Vector3(rs.randf_range(-0.5, 0.5), 0.1, rs.randf_range(-0.5, 0.5))))
		var teile := []
		if art == "korb":
			var kb := _begin()
			_dreh(kb, [[0.34, 0.46, 0.5], [0.46, 0.48, 0.06], [0.48, 0.2, 0.12], [0.2, 0.06, 0.08]], Vector3.ZERO, 1.0, 14)
			teile.append([kb, korb])
		else:
			# welche Flächen die Form belegt: Ton, Holz, Bronze, Glut, Gold, Stein (leere darf man nicht übergeben)
			var voll := {"amphore": "ac", "kruege": "ab", "kiste": "bc", "kisten": "bc", "lampen": "ad", "waffen": "bce", "schatz": "ae", "schutt": "f", "schutt_klein": "f"}
			var alle := {"a": [a, ton], "b": [b, holz], "c": [c, bronze], "d": [d, mat("docht", Color(1.0, 0.7, 0.3), 1.0, Color(1.0, 0.6, 0.2), 3.0)],
				"e": [e, gold()], "f": [f, stone(g, "hell", "sandstein", Color(1.0, 0.92, 0.8))]}
			for z in voll.get(art, "a"):
				teile.append(alle[z])
		cache[k] = _commit(teile)
	return _put(g, cache[k], pos, rot)

# Palmwedel: Mittelrippe mit Fiederblättern zu beiden Seiten, zur Spitze hin hängend
static func _frond(haengen := 1.0) -> ArrayMesh:
	var st := _begin()
	var n := 11
	var pts := []
	for i in n + 1:
		var t := float(i) / n
		pts.append(Vector3(0, sin(t * 2.2) * 0.8 - t * t * 1.6 * haengen, t * 2.9))
	for i in n:
		var t := (i + 0.5) / n
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var l := 0.16 + 0.72 * sin(PI * clampf(t * 0.9 + 0.1, 0.0, 1.0))
		for sx in [-1.0, 1.0]:
			var ab := Vector3(sx * l, -l * 0.5 - 0.1, l * 0.28)
			var spitze := a.lerp(b, 0.5) + ab
			# Fieder als spitzes Blatt: an der Rippe breit, außen schmal
			if sx > 0:
				_quad(st, a, b, spitze + (b - a) * 0.12, spitze - (b - a) * 0.12)
			else:
				_quad(st, b, a, spitze - (b - a) * 0.12, spitze + (b - a) * 0.12)
	return st.commit()

static func palme(g: Node, pos: Vector3, rot: float) -> Node3D:
	var v := randi() % 3
	if not cache.has("palme%d" % v):
		var rng := RandomNumberGenerator.new()
		rng.seed = 77 + v
		var trunk := _begin()
		var lean := Vector3(rng.randf_range(-0.07, 0.07), 0, rng.randf_range(-0.07, 0.07))
		var at := Vector3.ZERO
		var segs := 10 + v * 2
		for i in segs:
			# jeder Ring unten etwas weiter als oben: die Narben alter Wedel
			var r := 0.24 - 0.008 * i
			var cm := CylinderMesh.new()
			cm.top_radius = r - 0.02
			cm.bottom_radius = r + 0.035
			cm.height = 0.5
			cm.radial_segments = 9
			cm.rings = 1
			trunk.append_from(cm, 0, Transform3D(Basis(Vector3.UP, i * 0.7), at + Vector3(0, 0.25, 0)))
			at += Vector3(0, 0.47, 0) + lean * (i + 1) * 0.3
		var leaves := _begin()
		var oben := _frond(0.75)
		var unten := _frond(1.25)
		for i in 8:
			var b := Basis(Vector3.UP, TAU * i / 8.0 + rng.randf() * 0.3) * Basis(Vector3.RIGHT, rng.randf_range(-0.75, -0.4))
			leaves.append_from(oben, 0, Transform3D(b.scaled(Vector3.ONE * rng.randf_range(0.8, 1.0)), at))
		for i in 8:
			var b := Basis(Vector3.UP, TAU * (i + 0.5) / 8.0 + rng.randf() * 0.3) * Basis(Vector3.RIGHT, rng.randf_range(-0.2, 0.15))
			leaves.append_from(unten, 0, Transform3D(b.scaled(Vector3.ONE * rng.randf_range(0.9, 1.15)), at))
		var lm: StandardMaterial3D = tex_mat("palmblatt", "p04_palmblatt", 1.2, Color(0.62, 0.78, 0.6))
		lm.cull_mode = BaseMaterial3D.CULL_DISABLED
		# Datteln unter der Krone
		var frucht := _begin()
		for i in 3:
			var sm := SphereMesh.new()
			sm.radius = 0.16
			sm.height = 0.34
			sm.radial_segments = 6
			sm.rings = 3
			frucht.append_from(sm, 0, Transform3D(Basis(), at + Vector3(cos(i * 2.1) * 0.22, -0.3, sin(i * 2.1) * 0.22)))
		cache["palme%d" % v] = _commit([[trunk, tex_mat("palmrinde", "p03_palmrinde", 1.4)], [leaves, lm], [frucht, mat("dattel", Color(0.5, 0.28, 0.1), 0.7)]])
	return _put(g, cache["palme%d" % v], pos, rot)

static func becken(g: Node, pos: Vector3, r: float) -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 0.06
	cm.radial_segments = 24
	cm.rings = 1
	var w := _put(g, cm, pos + Vector3(0, 0.05, 0))
	w.material_override = mat("wasser", Color(0.05, 0.2, 0.26), 0.08, Color(0.15, 0.5, 0.6), 0.35, 0.6)
	var rim := CylinderMesh.new()
	rim.top_radius = r + 0.35
	rim.bottom_radius = r + 0.5
	rim.height = 0.1
	rim.radial_segments = 24
	rim.rings = 1
	var e := _put(g, rim, pos + Vector3(0, 0.0, 0))
	e.material_override = stone(g, "hell", "sandstein", Color(1.15, 1.02, 0.84))

# ---------------------------------------------------------------- Orte zum Handeln
# Feuer als Shader-Flamme (zwei gekreuzte Flächen): ruhiger als Funken, ein Zeichenaufruf, in jedem Browser gleich
static func _fire(parent: Node3D, at: Vector3, big := 1.0) -> Node3D:
	return Stimmung.flamme(parent, at - Vector3(0, 0.3 * big, 0), 1.25 * big, 0.95 * big)

# Feuerschale: erloschen, bis die Figur sie mit dem Funken des Re entzündet
static func feuerschale(g: Node, pos: Vector3) -> Dictionary:
	var k := "schale_%s" % g.get_instance_id()
	if not cache.has(k):
		var s := _begin()
		taper(s, Vector2(0.8, 0.8), Vector2(0.5, 0.5), 0.85)
		var bz := _begin()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.66
		cm.bottom_radius = 0.34
		cm.height = 0.36
		cm.radial_segments = 12
		cm.rings = 1
		bz.append_from(cm, 0, Transform3D(Basis(), Vector3(0, 1.03, 0)))
		cache[k] = _commit([[s, stone(g, "dunkel", "granit", Color(0.8, 0.8, 0.9))], [bz, mat("bronze", Color(0.45, 0.3, 0.14), 0.5, Color.BLACK, 0.0, 0.7)]])
	var n := _put(g, cache[k], pos)
	var coal := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.56
	dm.bottom_radius = 0.56
	dm.height = 0.05
	dm.radial_segments = 12
	dm.rings = 1
	coal.mesh = dm
	coal.material_override = mat("kohle_kalt", Color(0.07, 0.06, 0.06), 1.0)
	n.add_child(coal)
	coal.position = Vector3(0, 1.2, 0)
	return {"n": n, "coal": coal}

static func entzuenden(g: Node, s: Dictionary) -> void:
	s.coal.material_override = mat("kohle_glut", Color(1.0, 0.5, 0.15), 1.0, Color(1.0, 0.45, 0.1), 2.5)
	_fire(s.n, Vector3(0, 1.45, 0), 1.25)
	# gemalte Bilder (zierwelt.gd): Funken und Rauch steigen aus der Schale, die Sonne glüht auf dem Boden auf
	Zierwelt.feuer_glut(s.n, Vector3(0, 1.4, 0), 1.0, g.low_gfx)
	var sonne := Zierwelt.bodenzeichen(s.n, Vector3.ZERO, 1.7, "sonne", Color(1.0, 0.8, 0.6), 0.0, 0.02, true)
	if sonne:
		Zierwelt.hell_setzen(sonne, 0.45, 1.2)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.66, 0.32)
	l.light_energy = 0.1
	l.omni_range = 17.0
	l.omni_attenuation = 1.4   # 4.1.5: fiel zu flach ab und machte die ganze Kammer taghell
	s.n.add_child(l)
	l.position = Vector3(0, 2.6, 0)
	g.torches.append({"l": l, "ph": randf() * 10.0, "e": 3.0})
	g.lichter.append(l)
	var tw: Tween = g.create_tween()
	tw.tween_property(l, "light_energy", 3.0, 0.8)

# Schrein eines Gottes: Stele mit leuchtendem Zeichen in der Farbe des Gottes
static func schrein(g: Node, pos: Vector3, col: Color) -> Dictionary:
	var s := _begin()
	box(s, Vector3(1.7, 0.25, 1.3), Vector3.ZERO)
	taper(s, Vector2(1.1, 0.4), Vector2(0.95, 0.32), 2.1, Vector3(0, 0.25, 0))
	box(s, Vector3(0.7, 0.5, 0.5), Vector3(0, 0.25, 0.62))
	var gl := _begin()
	for sz in [0.2, -0.2]:
		box(gl, Vector3(0.5, 0.5, 0.03), Vector3(0, 1.3, sz))
		box(gl, Vector3(0.14, 0.55, 0.03), Vector3(0, 0.7, sz))
	var gm := StandardMaterial3D.new()
	gm.albedo_color = col
	gm.emission_enabled = true
	gm.emission = col
	gm.emission_energy_multiplier = 1.8
	var n := _put(g, _commit([[s, stone(g, "hell", "sandstein", Color(1.15, 1.02, 0.84))], [gl, gm]]), pos, PI / 4)
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = 1.5
	l.omni_range = 6.0
	n.add_child(l)
	l.position = Vector3(0, 1.6, 0.9)
	return {"n": n, "glow": gm, "light": l}

# Pforte am Ende der Stunde (3.1): ein Pylon wie vor einem Tempel. Zwei schräge Türme mit Hohlkehle, darüber die
# geflügelte Sonnenscheibe, im Durchgang ein gemalter Blick in die nächste Stunde, davor zwei Wächter.
# Stein in der Mauerfarbe dieser Stunde; am Ende eines Aktes größer. Gibt {n, blick} zurück (Blick zum Aufblenden).
static func pforte(g: Node, pos: Vector3, rot: float, stein: Material, nd: Dictionary, gross: bool) -> Dictionary:
	var n := Node3D.new()
	g.add_child(n)
	n.global_position = pos
	n.rotation.y = rot
	if gross:
		n.scale = Vector3.ONE * 1.35
	var s := _begin()    # Stein
	var go := _begin()   # Gold
	var dk := _begin()   # dunkles Band
	# Stufen davor
	box(s, Vector3(7.6, 0.18, 3.2), Vector3(0, 0, 0.3))
	box(s, Vector3(6.4, 0.16, 2.6), Vector3(0, 0.18, 0.2))
	# zwei Türme, die sich nach oben verjüngen
	for sx in [-1, 1]:
		taper(s, Vector2(2.2, 1.6), Vector2(1.7, 1.2), 5.4, Vector3(sx * 2.25, 0.34, 0))
		box(s, Vector3(1.95, 0.32, 1.42), Vector3(sx * 2.25, 5.74, 0))      # Hohlkehle oben
		box(go, Vector3(1.8, 0.07, 1.3), Vector3(sx * 2.25, 5.66, 0.02))     # Goldband darunter
		for i in 3:                                                           # Rillen, wo Fahnenmasten standen
			box(dk, Vector3(0.08, 4.2, 0.05), Vector3(sx * 2.25 + (i - 1) * 0.42, 0.9, 0.83 - 0.06 * (1 - absf(sx))))
	# Durchgang: Laibung und Sturz
	for sx in [-1, 1]:
		box(s, Vector3(0.36, 4.2, 1.1), Vector3(sx * 1.25, 0.34, 0))
	box(s, Vector3(2.9, 0.75, 1.15), Vector3(0, 4.54, 0))
	box(s, Vector3(3.2, 0.22, 1.25), Vector3(0, 5.29, 0))
	# geflügelte Sonnenscheibe auf dem Sturz
	var scheibe := CylinderMesh.new()
	scheibe.top_radius = 0.26
	scheibe.bottom_radius = 0.26
	scheibe.height = 0.08
	scheibe.radial_segments = 20
	scheibe.rings = 1
	go.append_from(scheibe, 0, Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(0, 4.92, 0.6)))
	for sx in [-1, 1]:
		for i in 4:   # Schwingen aus gestaffelten Federn
			box(go, Vector3(0.62 - i * 0.1, 0.07, 0.04), Vector3(sx * (0.62 + i * 0.05), 4.98 - i * 0.09, 0.6))
	# der Stein der Stunde ist für Mauern gemacht, deren Kanten am Raster liegen; am Pylon mit seinen schrägen Flächen
	# verzerrten die Mauer-UVs die Textur zu Streifen. Hier legt sie sich darum dreiseitig (triplanar) um den Körper.
	var st3: StandardMaterial3D = (stein as StandardMaterial3D).duplicate() if stein is StandardMaterial3D else null
	if st3:
		var per: float = stein.get_meta("period", 2.0)
		st3.uv1_triplanar = true
		st3.uv1_triplanar_sharpness = 4.0
		st3.uv1_scale = Vector3.ONE / maxf(per, 0.5)
	var stoff := _commit([[s, st3 if st3 else stein], [go, gold()], [dk, mat("schwarz", Color(0.06, 0.06, 0.08), 0.45)]])
	var mi := MeshInstance3D.new()
	mi.mesh = stoff
	n.add_child(mi)
	# Blick in die nächste Stunde
	var pal: Dictionary = nd.get("pal", {})
	var himmel := Color(nd.get("mote", "#bcd0e8")).darkened(0.55)
	var boden := Color(pal.get("dune", "#6d6756"))
	var licht := Color(nd.get("mote", "#8fe3e0"))
	var bm := MeshInstance3D.new()
	var bmat := Stimmung.blick(bm, himmel, boden, licht, 2.14, 4.18)
	bm.position = Vector3(0, 0.34 + 2.09, 0.02)
	n.add_child(bm)
	# zwei Wächter mit Schakalkopf, zum Kommenden gewandt
	for sx in [-1, 1]:
		var w := anubis(g, Vector3.ZERO, 0.0)
		w.reparent(n, false)
		w.position = Vector3(sx * 4.3, 0, 1.0)
		w.scale = Vector3.ONE * 0.85
	var l := OmniLight3D.new()
	l.light_color = licht
	l.light_energy = 2.6
	l.omni_range = 11.0
	l.position = Vector3(0, 2.2, 1.4)
	n.add_child(l)
	Stimmung.fries(n, Vector3(0, 4.55, 0.585), 2.6, 0.42, Color(1.0, 0.78, 0.35), 0.75)
	return {"n": n, "blick": bmat, "licht": l}

# Marke über einer Figur, die etwas zu sagen hat (3.0): ein schwebendes goldenes Anch, das Zeichen für Leben.
# Es dreht sich langsam und leuchtet; Orte.tick bewegt es.
static func marke(parent: Node3D, hoehe: float, col: Color) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	n.position = Vector3(0, hoehe, 0)
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = 0.6
	m.roughness = 0.35
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 1.5
	var st := _begin()
	box(st, Vector3(0.09, 0.42, 0.07), Vector3(0, -0.42, 0))        # Schaft
	box(st, Vector3(0.4, 0.09, 0.07), Vector3(0, -0.06, 0))         # Querbalken
	var mi := MeshInstance3D.new()
	var am := ArrayMesh.new()
	st.set_material(m)
	st.generate_tangents()
	st.commit(am)
	mi.mesh = am
	n.add_child(mi)
	var ring := MeshInstance3D.new()                                  # Schlaufe
	var tm := TorusMesh.new()
	tm.inner_radius = 0.09
	tm.outer_radius = 0.17
	tm.rings = 14
	tm.ring_segments = 8
	ring.mesh = tm
	ring.material_override = m
	ring.rotation.x = PI / 2
	ring.scale = Vector3(0.9, 1.0, 1.25)
	ring.position = Vector3(0, 0.2, 0)
	n.add_child(ring)
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = 0.6
	l.omni_range = 2.5
	n.add_child(l)
	n.scale = Vector3.ONE * 1.35
	n.set_meta("y", hoehe)
	n.set_meta("mat", m)
	return n

# Werkstatt des Ptah (3.0): Sonnensegel auf vier Pfosten, darunter Werkbank, Lehmofen mit Glut und ein Steinamboss.
# Hier, und nur hier, wird Ausrüstung aufgewertet und neu gefasst.
static func werkstatt(g: Node, pos: Vector3, rot: float) -> Dictionary:
	var holz := tex_mat("holz", "p02_holz", 1.3)
	var ton := tex_mat("ton", "p01_ton", 1.6)
	var bronze := mat("bronze", Color(0.45, 0.3, 0.14), 0.5, Color.BLACK, 0.0, 0.7)
	var tuch := mat("tuch_ptah", Color(0.3, 0.1, 0.08), 0.95)
	var saum := mat("tuch_saum", Color(0.85, 0.68, 0.3), 0.8)
	var glut := mat("glut", Color(1.0, 0.45, 0.12), 0.6, Color(1.0, 0.4, 0.1), 2.6)
	var h := _begin()   # Holz
	var t := _begin()   # Ton
	var st := _begin()  # Stein
	var b := _begin()   # Bronze
	var go := _begin()  # Gold
	var tu := _begin()  # Tuch
	var sa := _begin()  # Saum
	var gl := _begin()  # Glut
	var ko := _begin()  # Schilfmatte
	# Rückwand: zwei Pfosten, ein Querbalken und ein Tuch mit goldenem Saum. Kein Dach: Die Kamera sieht von oben,
	# ein Segel würde Bank, Ofen und Goldschmied verdecken.
	for x in [-1.35, 1.35]:
		box(h, Vector3(0.12, 2.5, 0.12), Vector3(x, 0, -1.05))
		box(st, Vector3(0.3, 0.16, 0.3), Vector3(x, 0, -1.05))
	box(h, Vector3(3.0, 0.1, 0.1), Vector3(0, 2.44, -1.05))
	box(tu, Vector3(2.5, 1.5, 0.03), Vector3(0, 0.9, -1.05))
	box(sa, Vector3(2.5, 0.1, 0.05), Vector3(0, 0.84, -1.05))
	box(sa, Vector3(2.5, 0.06, 0.05), Vector3(0, 2.3, -1.05))
	# Zeichen des Ptah auf dem Tuch: der Djed-Pfeiler (Beständigkeit), vier Querbalken auf einem Schaft
	box(sa, Vector3(0.14, 0.85, 0.05), Vector3(0, 1.1, -1.04))
	for i in 4:
		box(sa, Vector3(0.5 - 0.04 * i, 0.07, 0.05), Vector3(0, 1.55 + 0.12 * i, -1.04))
	# Bodenmatte aus Schilf
	box(ko, Vector3(3.1, 0.03, 2.5), Vector3(0, 0, 0))
	# Werkbank vorn
	box(h, Vector3(1.5, 0.08, 0.62), Vector3(0.15, 0.78, 0.45))
	for x in [-0.5, 0.8]:
		for z in [0.2, 0.7]:
			box(h, Vector3(0.08, 0.78, 0.08), Vector3(x, 0, z))
	box(h, Vector3(1.3, 0.05, 0.05), Vector3(0.15, 0.3, 0.2))
	# Werkzeug und Werkstücke auf der Bank
	box(h, Vector3(0.04, 0.04, 0.34), Vector3(-0.3, 0.86, 0.45))        # Hammerstiel
	box(b, Vector3(0.16, 0.09, 0.09), Vector3(-0.3, 0.86, 0.3))        # Hammerkopf
	box(b, Vector3(0.03, 0.02, 0.3), Vector3(0.0, 0.86, 0.5))          # Meißel
	for i in 3:
		box(go, Vector3(0.2, 0.06, 0.09), Vector3(0.5 + 0.03 * i, 0.86 + 0.06 * i, 0.42 + 0.02 * i))   # Goldbarren
	_dreh(go, [[0.09, 0.11, 0.02], [0.11, 0.11, 0.015]], Vector3(0.22, 0.86, 0.62))   # Armreif
	# Lehmofen hinten links: Kuppel mit Feuerloch
	_dreh(t, [[0.5, 0.52, 0.12], [0.52, 0.46, 0.3], [0.46, 0.3, 0.26], [0.3, 0.14, 0.16], [0.14, 0.12, 0.2]], Vector3(-0.75, 0, -0.45), 1.0, 12)
	box(gl, Vector3(0.3, 0.24, 0.06), Vector3(-0.75, 0.14, 0.06))
	box(t, Vector3(0.42, 0.06, 0.1), Vector3(-0.75, 0.38, 0.07))
	# Amboss: Granitblock mit Bronzeplatte
	box(st, Vector3(0.5, 0.55, 0.42), Vector3(0.75, 0, -0.4))
	box(b, Vector3(0.42, 0.04, 0.34), Vector3(0.75, 0.55, -0.4))
	# Wasserkrug zum Abschrecken
	_dreh(t, KRUG, Vector3(1.05, 0, 0.35), 0.55)
	var n := _put(g, _commit([[h, holz], [t, ton], [st, stone(g, "dunkel", "granit", Color(0.85, 0.85, 0.9))], [b, bronze], [go, gold()],
		[tu, tuch], [sa, saum], [gl, glut], [ko, tex_mat("matte", "p05_korb", 2.4, Color(0.6, 0.52, 0.4))]]), pos, rot)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.28)
	l.light_energy = 1.6
	l.omni_range = 6.5
	l.omni_attenuation = 1.3
	n.add_child(l)
	l.position = Vector3(-0.6, 1.0, 0.5)
	Stimmung.flamme(n, Vector3(-0.75, 1.02, -0.45), 0.4, 0.3)
	return {"n": n, "light": l}

# Seelenkrug (3.0 neu geformt): eine Kanope aus Alabaster auf einem Granitsockel mit Goldband. Der Deckel ist ein
# stilisierter Kopf mit Kopftuch. Im Bauch des Kruges schlägt ein Herz: Orte.tick lässt ihn rot pulsen.
static func krug(g: Node, pos: Vector3) -> Dictionary:
	var s := _begin()
	box(s, Vector3(0.78, 0.16, 0.78), Vector3.ZERO)
	box(s, Vector3(0.62, 0.3, 0.62), Vector3(0, 0.16, 0))
	var gd := _begin()
	box(gd, Vector3(0.66, 0.05, 0.66), Vector3(0, 0.4, 0))
	var n := _put(g, _commit([[s, stone(g, "dunkel", "granit", Color(0.8, 0.8, 0.9))], [gd, gold()]]), pos)
	var jm := StandardMaterial3D.new()
	jm.albedo_texture = load("res://textures/p01_ton.jpg")
	jm.albedo_color = Color(1.25, 1.18, 1.02)       # heller Alabaster über der Tonstruktur
	jm.uv1_triplanar = true
	jm.uv1_scale = Vector3.ONE * 1.4
	jm.roughness = 0.45
	jm.emission_enabled = true
	jm.emission = Color(1.0, 0.25, 0.2)
	jm.emission_energy_multiplier = 0.4
	var bs := _begin()
	_dreh(bs, [[0.15, 0.2, 0.05], [0.2, 0.3, 0.22], [0.3, 0.33, 0.2], [0.33, 0.27, 0.16], [0.27, 0.2, 0.07]], Vector3.ZERO, 1.0, 14)
	var body := MeshInstance3D.new()
	body.mesh = _commit([[bs, jm]])
	n.add_child(body)
	body.position = Vector3(0, 0.45, 0)
	# Deckel: Kopf mit gestreiftem Kopftuch (dunkelblau und gold), vorn ein helles Gesicht
	var kopf := _begin()
	_dreh(kopf, [[0.2, 0.2, 0.04], [0.15, 0.2, 0.1], [0.2, 0.19, 0.12], [0.19, 0.1, 0.1]], Vector3.ZERO, 1.0, 12)
	var tuch := _begin()
	box(tuch, Vector3(0.44, 0.34, 0.12), Vector3(0, 0.04, -0.14))      # Kopftuch hinten
	for sx in [-0.19, 0.19]:
		box(tuch, Vector3(0.09, 0.3, 0.16), Vector3(sx, -0.02, 0.02))    # Lappen an den Seiten
	var band := _begin()
	box(band, Vector3(0.46, 0.04, 0.3), Vector3(0, 0.26, -0.06))
	var lid := MeshInstance3D.new()
	lid.mesh = _commit([[kopf, mat("krugkopf", Color(0.8, 0.7, 0.52), 0.55)], [tuch, mat("krugtuch", Color(0.1, 0.14, 0.3), 0.6)], [band, gold()]])
	n.add_child(lid)
	lid.position = Vector3(0, 1.15, 0)
	# gemalte Bilder (zierwelt.gd): unter dem Krug die Waage, vor die das Herz gehört, über dem Deckel steigt Dunst
	# auf. Beides hängt am Deckel und verschwindet mit ihm, sobald der Krug geöffnet oder zerschlagen ist.
	Zierwelt.bodenzeichen(lid, Vector3(0, -1.15, 0), 1.25, "waage", Color(0.9, 0.85, 0.85), 0.3, 0.02)
	var dunst := Zierwelt.teilchen("dunst", 3 if g.low_gfx else 5, 2.6, 0.8, Color(0.7, 1.0, 0.95, 0.45))
	if dunst:
		dunst.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		dunst.emission_sphere_radius = 0.15
		dunst.direction = Vector3(0, 1, 0)
		dunst.spread = 20.0
		dunst.initial_velocity_min = 0.2
		dunst.initial_velocity_max = 0.45
		dunst.gravity = Vector3(0, 0.1, 0)
		lid.add_child(dunst)
		dunst.position = Vector3(0, 0.3, 0)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.3, 0.25)
	l.light_energy = 0.8
	l.omni_range = 4.0
	n.add_child(l)
	l.position = Vector3(0, 1.5, 0)
	return {"n": n, "glow": jm, "light": l, "body": body, "lid": lid}

# Fundstück der Stunde: goldener Splitter, der sich über einem Sockel dreht
static func relikt(g: Node, pos: Vector3) -> Dictionary:
	var s := _begin()
	taper(s, Vector2(0.9, 0.9), Vector2(0.65, 0.65), 0.7)
	var n := _put(g, _commit([[s, stone(g, "hell", "sandstein", Color(1.15, 1.02, 0.84))]]), pos)
	var it := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(0.38, 0.6, 0.12)
	it.mesh = pm
	it.material_override = mat("relikt", Color(1.0, 0.82, 0.4), 0.3, Color(1.0, 0.75, 0.3), 2.2, 0.6)
	n.add_child(it)
	it.position = Vector3(0, 1.35, 0)
	# Goldstaub um den Splitter (Effektbild, zierwelt.gd); verschwindet mit ihm, wenn entschieden ist
	var staub := Zierwelt.teilchen("goldstaub", 3 if g.low_gfx else 6, 2.0, 0.45, Color(1.0, 0.9, 0.7, 0.8))
	if staub:
		staub.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		staub.emission_sphere_radius = 0.45
		staub.direction = Vector3(0, 1, 0)
		staub.spread = 60.0
		staub.initial_velocity_min = 0.05
		staub.initial_velocity_max = 0.25
		staub.gravity = Vector3(0, 0.08, 0)
		staub.local_coords = true
		it.add_child(staub)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.8, 0.4)
	l.light_energy = 1.6
	l.omni_range = 6.0
	n.add_child(l)
	l.position = Vector3(0, 1.8, 0)
	return {"n": n, "item": it, "light": l}

# ---------------------------------------------------------------- Verlorenes der Leute: Tiere, Säcke, Kisten, Krüge
static func _ball(parent: Node3D, r: Vector3, at: Vector3, m: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 10
	sm.rings = 5
	mi.mesh = sm
	mi.material_override = m
	mi.scale = r * 2.0
	parent.add_child(mi)
	mi.position = at

static func _legs(parent: Node3D, w: float, l: float, h: float, m: StandardMaterial3D) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var mi := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.05
			cm.bottom_radius = 0.04
			cm.height = h
			cm.radial_segments = 6
			cm.rings = 1
			mi.mesh = cm
			mi.material_override = m
			parent.add_child(mi)
			mi.position = Vector3(sx * w, h / 2, sz * l)

static func such(g: Node, pos: Vector3, ding: String) -> Dictionary:
	var n := Node3D.new()
	g.add_child(n)
	n.global_position = pos
	n.rotation.y = randf() * TAU
	var tier := true
	match ding:
		"schaf", "ziege", "esel", "katze":
			# seit 4.3 echte Tiere (tiere.gd): sie grasen, schauen, und laufen heim, wenn man sie findet
			var tr := Tier.neu(g, ding, pos)
			tr.fest = true
			n.queue_free()
			n = tr.n
			n.set_meta("tier", tr)
		"sack", "korb":
			tier = false
			var stoff := mat("sack", Color(0.62, 0.5, 0.32), 1.0) if ding == "sack" else mat("korb", Color(0.55, 0.4, 0.2), 1.0)
			_ball(n, Vector3(0.36, 0.3, 0.3), Vector3(0, 0.3, 0), stoff)
			_ball(n, Vector3(0.14, 0.12, 0.14), Vector3(0, 0.62, 0), stoff)
		"kiste":
			tier = false
			var s := _begin()
			box(s, Vector3(0.8, 0.4, 0.45), Vector3.ZERO)
			box(s, Vector3(0.5, 0.06, 0.06), Vector3(0, 0.52, 0))
			for sx in [-0.22, 0.22]:
				box(s, Vector3(0.05, 0.14, 0.05), Vector3(sx, 0.4, 0))
			var mi := MeshInstance3D.new()
			mi.mesh = _commit([[s, mat("holz", Color(0.45, 0.3, 0.16), 0.9)]])
			n.add_child(mi)
		"krug":
			tier = false
			var ton := mat("ton", Color(0.72, 0.42, 0.26), 0.8)
			_ball(n, Vector3(0.28, 0.38, 0.28), Vector3(0, 0.4, 0), ton)
			var hals := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.13
			cm.bottom_radius = 0.1
			cm.height = 0.3
			cm.radial_segments = 8
			cm.rings = 1
			hals.mesh = cm
			hals.material_override = ton
			n.add_child(hals)
			hals.position = Vector3(0, 0.86, 0)
	# ein leiser Schein, damit man es im Dunkeln findet
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.95, 0.75)
	l.light_energy = 0.9
	l.omni_range = 3.5
	n.add_child(l)
	l.position = Vector3(0, 1.3, 0)
	var aus := {"n": n, "tier": tier, "light": l}
	if n.has_meta("tier"):
		aus["tierobj"] = n.get_meta("tier")
	return aus


# Truhe wie aus einem Grab: Kasten auf Füßen, Deckel in Schreinform (vorn hoch, hinten flach), Beschläge je nach Rang
# (Bronze, dunkles Eisen, Gold mit Lapis). Der Deckel ist ein eigener Körper mit Drehpunkt an der Hinterkante.
static func truhe(g: Node, pos: Vector3, tier: int) -> Dictionary:
	var k := "truhe%d" % tier
	if not cache.has(k):
		var holz := tex_mat("holz%d" % tier, "p02_holz", 1.3, [Color.WHITE, Color(0.55, 0.5, 0.5), Color(1.0, 0.85, 0.6)][tier])
		var metall: StandardMaterial3D = [mat("bronze", Color(0.45, 0.3, 0.14), 0.5, Color.BLACK, 0.0, 0.7), mat("eisen", Color(0.3, 0.33, 0.38), 0.45, Color.BLACK, 0.0, 0.8), gold()][tier]
		var lapis := mat("lapis", Color(0.1, 0.18, 0.45), 0.5)
		var b := _begin()
		var c := _begin()
		var l := _begin()
		box(b, Vector3(1.2, 0.55, 0.76), Vector3(0, 0.12, 0))
		for sx in [-0.52, 0.52]:
			for sz in [-0.3, 0.3]:
				box(b, Vector3(0.12, 0.12, 0.12), Vector3(sx, 0, sz))
		for sx in [-0.42, 0.42]:
			box(c, Vector3(0.09, 0.57, 0.79), Vector3(sx, 0.12, 0))
		box(c, Vector3(0.16, 0.14, 0.05), Vector3(0, 0.45, 0.39))
		var teile := [[b, holz], [c, metall]]
		if tier == 2:
			box(l, Vector3(0.6, 0.3, 0.02), Vector3(0, 0.24, 0.385))
			teile.append([l, lapis])
		cache[k] = _commit(teile)
		var d := _begin()
		var dc := _begin()
		# Deckel: Drehpunkt hinten (z = 0), die Fläche reicht nach vorn (+z)
		taper(d, Vector2(1.26, 0.82), Vector2(1.26, 0.36), 0.2, Vector3(0, 0, 0.38))
		for sx in [-0.42, 0.42]:
			taper(dc, Vector2(0.09, 0.84), Vector2(0.09, 0.38), 0.21, Vector3(sx, 0, 0.38))
		box(dc, Vector3(0.14, 0.08, 0.14), Vector3(0, 0.2, 0.38))
		cache[k + "d"] = _commit([[d, holz], [dc, metall]])
	var n := _put(g, cache[k], pos)
	var lid := MeshInstance3D.new()
	lid.mesh = cache[k + "d"]
	lid.position = Vector3(0, 0.67, -0.38)
	n.add_child(lid)
	return {"n": n, "lid": lid}

# Wandlampe: Bronzearm mit Ölschale (statt der Fackeln der alten Kulisse); schaut nach +Z von der Wand weg
static func wandlampe(g: Node, pos: Vector3, rot: float) -> Node3D:
	if not cache.has("wandlampe"):
		var c := _begin()
		box(c, Vector3(0.16, 0.3, 0.05), Vector3(0, 0.1, 0.02))
		box(c, Vector3(0.05, 0.05, 0.42), Vector3(0, 0.2, 0.21))
		_dreh(c, [[0.05, 0.2, 0.1], [0.2, 0.22, 0.03]], Vector3(0, 0.22, 0.42), 1.0, 10)
		var k := _begin()
		_dreh(k, [[0.17, 0.17, 0.02]], Vector3(0, 0.33, 0.42), 1.0, 10)
		cache["wandlampe"] = _commit([[c, mat("bronze", Color(0.45, 0.3, 0.14), 0.5, Color.BLACK, 0.0, 0.7)], [k, mat("kohle_glut", Color(1.0, 0.5, 0.15), 1.0, Color(1.0, 0.45, 0.1), 2.5)]])
	return _put(g, cache["wandlampe"], pos, rot)
