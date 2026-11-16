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
	mi.material_override = stone(g, "fels_%s" % tint.to_html(), "sandstein", tint)
	return mi

static func _frond() -> ArrayMesh:
	var st := _begin()
	var n := 6
	var prev_l := Vector3.ZERO
	var prev_r := Vector3.ZERO
	for i in n + 1:
		var t := float(i) / n
		var z := t * 2.7
		var y := sin(t * 2.2) * 0.75 - t * t * 1.5
		var w := 0.46 * sin(PI * clampf(t * 0.95 + 0.08, 0.0, 1.0))
		var l := Vector3(-w, y - w * 0.35, z)
		var r := Vector3(w, y - w * 0.35, z)
		if i > 0:
			_quad(st, prev_l, prev_r, r, l)
		prev_l = l
		prev_r = r
	return st.commit()

static func palme(g: Node, pos: Vector3, rot: float) -> Node3D:
	var v := randi() % 3
	if not cache.has("palme%d" % v):
		var rng := RandomNumberGenerator.new()
		rng.seed = 77 + v
		var trunk := _begin()
		var lean := Vector3(rng.randf_range(-0.16, 0.16), 0, rng.randf_range(-0.16, 0.16))
		var at := Vector3.ZERO
		var segs := 5 + v
		for i in segs:
			var cm := CylinderMesh.new()
			cm.top_radius = 0.2 - 0.012 * (i + 1)
			cm.bottom_radius = 0.2 - 0.012 * i + 0.03
			cm.height = 0.95
			cm.radial_segments = 7
			cm.rings = 1
			trunk.append_from(cm, 0, Transform3D(Basis(), at + Vector3(0, 0.47, 0)))
			at += Vector3(0, 0.9, 0) + lean * (i + 1) * 0.55
		var leaves := _begin()
		var fr := _frond()
		for i in 9:
			var b := Basis(Vector3.UP, TAU * i / 9.0 + rng.randf() * 0.3) * Basis(Vector3.RIGHT, rng.randf_range(-0.5, -0.05))
			leaves.append_from(fr, 0, Transform3D(b.scaled(Vector3.ONE * rng.randf_range(0.85, 1.15)), at))
		var lm := mat("palmblatt", Color(0.12, 0.26, 0.13), 0.85)
		lm.cull_mode = BaseMaterial3D.CULL_DISABLED
		cache["palme%d" % v] = _commit([[trunk, mat("palmstamm", Color(0.42, 0.3, 0.19), 0.95)], [leaves, lm]])
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
static func _fire(parent: Node3D, at: Vector3, big := 1.0) -> CPUParticles3D:
	var fl := CPUParticles3D.new()
	fl.amount = 20
	fl.lifetime = 0.7
	fl.direction = Vector3(0, 1, 0)
	fl.spread = 16.0
	fl.gravity = Vector3(0, 1.6, 0)
	fl.initial_velocity_min = 0.7
	fl.initial_velocity_max = 1.5
	fl.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	fl.emission_sphere_radius = 0.32 * big
	fl.scale_amount_min = 0.5
	fl.scale_amount_max = 1.0
	var qm := SphereMesh.new()
	qm.radius = 0.15 * big
	qm.height = 0.3 * big
	qm.radial_segments = 6
	qm.rings = 3
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color(1.0, 0.72, 0.3)
	qm.material = fm
	fl.mesh = qm
	parent.add_child(fl)
	fl.position = at
	return fl

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
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.66, 0.32)
	l.light_energy = 0.1
	l.omni_range = 17.0
	l.omni_attenuation = 1.1
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

# Seelenkrug: Kanope auf einem Sockel, in der ein Herz schlägt
static func krug(g: Node, pos: Vector3) -> Dictionary:
	var s := _begin()
	box(s, Vector3(0.7, 0.5, 0.7), Vector3.ZERO)
	var n := _put(g, _commit([[s, stone(g, "dunkel", "granit", Color(0.8, 0.8, 0.9))]]), pos)
	var jm := StandardMaterial3D.new()
	jm.albedo_color = Color(0.85, 0.78, 0.62)
	jm.roughness = 0.5
	jm.emission_enabled = true
	jm.emission = Color(1.0, 0.25, 0.2)
	jm.emission_energy_multiplier = 0.4
	var body := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.3
	cm.bottom_radius = 0.19
	cm.height = 0.7
	cm.radial_segments = 10
	cm.rings = 1
	body.mesh = cm
	body.material_override = jm
	n.add_child(body)
	body.position = Vector3(0, 0.85, 0)
	var lid := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.24
	sm.height = 0.44
	sm.radial_segments = 10
	sm.rings = 5
	lid.mesh = sm
	lid.material_override = mat("krugdeckel", Color(0.2, 0.18, 0.2), 0.5)
	n.add_child(lid)
	lid.position = Vector3(0, 1.36, 0)
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
		"schaf", "ziege", "esel":
			var wolle := mat("wolle", Color(0.92, 0.9, 0.84), 1.0) if ding == "schaf" else (mat("ziege", Color(0.5, 0.36, 0.24), 0.9) if ding == "ziege" else mat("esel", Color(0.5, 0.5, 0.52), 0.9))
			var dunkel := mat("tierkopf", Color(0.14, 0.12, 0.11), 0.8)
			var gr := 1.3 if ding == "esel" else 1.0
			_ball(n, Vector3(0.36, 0.3, 0.52) * gr, Vector3(0, 0.62 * gr, 0), wolle)
			_ball(n, Vector3(0.16, 0.17, 0.22) * gr, Vector3(0, 0.82 * gr, 0.56 * gr), dunkel if ding == "schaf" else wolle)
			for sx in [-1.0, 1.0]:
				_ball(n, Vector3(0.04, 0.12 if ding == "esel" else 0.05, 0.07) * gr, Vector3(sx * 0.13, (1.02 if ding == "esel" else 0.9) * gr, 0.5 * gr), dunkel)
			_legs(n, 0.2 * gr, 0.3 * gr, 0.4 * gr, dunkel)
		"katze":
			var fell := mat("katze", Color(0.78, 0.6, 0.36), 0.9)
			_ball(n, Vector3(0.14, 0.16, 0.2), Vector3(0, 0.2, 0), fell)
			_ball(n, Vector3(0.11, 0.11, 0.11), Vector3(0, 0.42, 0.14), fell)
			for sx in [-1.0, 1.0]:
				_ball(n, Vector3(0.035, 0.07, 0.03), Vector3(sx * 0.07, 0.54, 0.14), fell)
			_ball(n, Vector3(0.03, 0.03, 0.18), Vector3(0, 0.16, -0.3), fell)
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
	return {"n": n, "tier": tier, "light": l}
