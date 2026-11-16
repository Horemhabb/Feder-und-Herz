extends Node3D
# Herz und Feder · Probestunde in 3D: „Das Tor des Westens“ (erste Stunde der Nacht).
# Baut Welt, Licht und Gegner aus einer Karte, führt Kamera und Eingabe und verbindet alles mit der Anzeige.

const CELL := 4.0
# S Start · B Hüter · m Ruheloser · p Priester · t Fass/Kisten · c Säule · # Fels
const MAP := [
	"######################",
	"#.t.#m...t#c...c######",
	"#.S....m..#.....######",
	"#...#.m..p#..B..######",
	"##.###.####m...m######",
	"##.###.#####.####m.pt#",
	"#t.m.#m...t#.####....#",
	"#.......p..#.####.m..#",
	"#.m.p#.m.m...m.....m.#",
	"######t...p#####t..p##",
	"######.m.m.###########",
	"######...t.###########",
	"######################",
]
const TXT := {
	"no": "ERSTE STUNDE DER NACHT", "name": "Das Tor des Westens",
	"lead": "Über Sandtor ziehen Lichter gegen den Wind. Es sind Seelen, und niemand holt sie ab.",
	"brief": "Folge den Lichtern hinab. Halte die Laterne hoch. In ihr brennt ein Funke des Re, und was Isfet ist, weicht vor ihm zurück oder greift ihn an.",
	"boss_say": "Der Fährmann, der hinter sich schaut. Er hat seine Fähre verloren und setzt trotzdem über.",
	"epi": "Mahaf war der Fährmann. Seit die Waage stillsteht, darf er niemanden mehr übersetzen, also führte er die Seelen im Kreis. Sein Licht brennt jetzt in deiner Laterne, und es zeigt nach unten.",
	"next": "Die Felder von Wernes",
	"next_lead": "Wo die Gerechtfertigten Korn schnitten, häutet sich die Brut des Apophis. Jede Haut macht sie größer.",
	"dead": "Dein Ba hat den Weg zurück in den Leib gefunden, und die Laterne brennt noch. Was dich angegriffen hat, ist noch dort.",
}

var hero: Hero
var sfx: Sfx
var hud: Hud
var cam: Camera3D
var env: Environment
var moon: DirectionalLight3D
var foes: Array = []
var bolts: Array = []
var torches: Array = []
var wisps: Array = []
var astar := AStarGrid2D.new()
var W := 0
var H := 0
var start_pos := Vector3.ZERO
var boss: Foe
var boss_awake := false
var gate: Node3D
var gate_t := 0.0
var gate_ask := true
var shake := 0.0
var shot_gap := 0.0
var kills := 0
var total := 0
var deaths := 0
var clock := 0.0
var started := false
var low_gfx := false
var hold_attack := false
var cam_pos := Vector3.ZERO
var autotest: Node
var slow_t := 0.0
var auto_low_done := false
var sunk := {}   # Mauern, die gerade abgesenkt sind, weil sie die Figur verdecken: Knoten -> Restzeit

func _ready() -> void:
	randomize()
	H = MAP.size()
	W = MAP[0].length()
	sfx = Sfx.new()
	add_child(sfx)
	if AudioServer.get_bus_effect_count(0) == 0:
		var lim := AudioEffectHardLimiter.new()   # fängt Spitzen ab, wenn viele Treffer zugleich klingen
		lim.ceiling_db = -0.5
		AudioServer.add_bus_effect(0, lim)
	_build_env()
	_build_world()
	hero = Hero.new()
	hero.game = self
	add_child(hero)
	hero.global_position = start_pos
	cam = Camera3D.new()
	cam.fov = 30.0
	cam.far = 200.0
	add_child(cam)
	cam_pos = hero.global_position
	_place_cam(1.0)
	cam.make_current()
	hud = Hud.new()
	hud.game = self
	add_child(hud)
	sfx.loop("amb_wind")
	sfx.loop("amb_drone")
	get_tree().paused = true
	if "--autotest" in OS.get_cmdline_user_args():
		autotest = load("res://scripts/autotest.gd").new()
		autotest.game = self
		add_child(autotest)
	else:
		hud.show_chapter(TXT.no, TXT.name, TXT.lead, TXT.brief, "Eintreten", func(): begin())
		sfx.say("vo_chapter")
		if "--playtest" in OS.get_cmdline_user_args() and not get_tree().root.has_node("Playtest"):
			var pt: Node = load("res://scripts/playtest.gd").new()
			pt.name = "Playtest"
			get_tree().root.add_child.call_deferred(pt)

func begin() -> void:
	sfx.hush()
	started = true
	get_tree().paused = false
	hud.banner(TXT.name, TXT.no)

# ---------------------------------------------------------------- Welt
func is_floor(cx: int, cz: int) -> bool:
	return cx >= 0 and cz >= 0 and cx < W and cz < H and MAP[cz][cx] != "#"

func cell_pos(cx: int, cz: int) -> Vector3:
	return Vector3(cx * CELL + CELL / 2, 0, cz * CELL + CELL / 2)

func _piece(name: String, pos: Vector3, rot := 0.0, scl := Vector3.ONE) -> Node3D:
	var n: Node3D = load("res://models/dungeon/%s.glb" % name).instantiate()
	n.position = pos
	n.rotation.y = rot
	n.scale = scl
	add_child(n)
	return n

# ---------------------------------------------------------------- Stein und Boden (Higgsfield-Texturen)
# Die Texturen liegen in textures/ (aufbereitet mit tools/texturen.py). Fehlt eine Datei, z. B. der Wüstensand,
# nimmt das Spiel den Ersatz aus SURF. So lässt sich eine neue Textur einfach dazulegen.
const SURF := {
	# Name: [Datei, Kachelgröße in Metern, Tönung, Ersatz falls Datei fehlt]
	"sandstein": ["w01_sandstein", 6.0, Color(1.0, 0.93, 0.80), ""],
	"sandstein_sims": ["w01_sandstein", 6.0, Color(1.25, 1.15, 0.98), ""],
	"granit": ["w02_granit", 6.0, Color(0.85, 0.85, 0.92), ""],
	"granit_sims": ["w02_granit", 6.0, Color(1.1, 1.1, 1.15), ""],
	"gruft": ["t07_gruft", 5.5, Color(0.95, 0.90, 0.84), ""],
	"pflaster": ["t06_pflaster", 4.0, Color(0.95, 0.88, 0.78), ""],
	"sand": ["t09_sand", 6.0, Color(0.85, 0.78, 0.68), "pflaster"],
	"sand_aussen": ["t09_sand", 6.0, Color(0.45, 0.40, 0.35), ""],
}
const WALL_SINK := 2.8   # so tief sinkt eine verdeckende Mauer ein (von 4 m bleiben 1,2 m)
# Gruftraum des Hüters (Zellen x 11–15, z 1–4): dunkler Granit statt Sandstein
const CRYPT := Rect2i(11, 1, 5, 4)

var mats := {}
var block_meshes := {}

func surf(name: String) -> StandardMaterial3D:
	if mats.has(name):
		return mats[name]
	var d: Array = SURF[name]
	var path := "res://textures/%s.jpg" % d[0]
	if not ResourceLoader.exists(path):
		if d[3] != "":
			mats[name] = surf(d[3])
			return mats[name]
		mats[name] = null
		return null
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(path)
	m.albedo_color = d[2]
	var npath := "res://textures/%s_n.jpg" % d[0]
	if ResourceLoader.exists(npath):
		m.normal_texture = load(npath)
		m.normal_enabled = not low_gfx
		m.normal_scale = 0.9
	m.roughness = 0.93
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.set_meta("period", d[1])
	mats[name] = m
	return m

func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2) -> void:
	# a b c d gegen den Uhrzeigersinn von außen gesehen; Godot zeigt Dreiecke im Uhrzeigersinn, daher a c b
	for v in [[a, ua], [c, uc], [b, ub], [a, ua], [d, ud], [c, uc]]:
		st.set_normal(n)
		st.set_uv(v[1])
		st.add_vertex(v[0])

func _block_mesh(size: Vector3, mat: StandardMaterial3D, uoff: float) -> ArrayMesh:
	# Quader mit Fuß bei y = 0; UVs in Metern geteilt durch die Kachelgröße, oben bündig bei 4 m.
	# So laufen die Steinlagen über benachbarte Mauern hinweg weiter, und ein Absenken staucht nichts.
	var key := "%s|%s|%.2f" % [size, mat.get_instance_id(), uoff]
	if block_meshes.has(key):
		return block_meshes[key]
	var p: float = mat.get_meta("period")
	var x := size.x / 2
	var z := size.z / 2
	var h := size.y
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vt := func(y): return (4.0 - y) / p
	# Vorder- und Rückseite (u entlang x)
	_quad(st, Vector3(-x, 0, z), Vector3(x, 0, z), Vector3(x, h, z), Vector3(-x, h, z), Vector3(0, 0, 1),
		Vector2(uoff, vt.call(0)), Vector2(uoff + size.x / p, vt.call(0)), Vector2(uoff + size.x / p, vt.call(h)), Vector2(uoff, vt.call(h)))
	_quad(st, Vector3(x, 0, -z), Vector3(-x, 0, -z), Vector3(-x, h, -z), Vector3(x, h, -z), Vector3(0, 0, -1),
		Vector2(uoff, vt.call(0)), Vector2(uoff + size.x / p, vt.call(0)), Vector2(uoff + size.x / p, vt.call(h)), Vector2(uoff, vt.call(h)))
	# Stirnseiten (u entlang z)
	_quad(st, Vector3(x, 0, z), Vector3(x, 0, -z), Vector3(x, h, -z), Vector3(x, h, z), Vector3(1, 0, 0),
		Vector2(0, vt.call(0)), Vector2(size.z / p, vt.call(0)), Vector2(size.z / p, vt.call(h)), Vector2(0, vt.call(h)))
	_quad(st, Vector3(-x, 0, -z), Vector3(-x, 0, z), Vector3(-x, h, z), Vector3(-x, h, -z), Vector3(-1, 0, 0),
		Vector2(0, vt.call(0)), Vector2(size.z / p, vt.call(0)), Vector2(size.z / p, vt.call(h)), Vector2(0, vt.call(h)))
	# Deckfläche
	_quad(st, Vector3(-x, h, z), Vector3(x, h, z), Vector3(x, h, -z), Vector3(-x, h, -z), Vector3(0, 1, 0),
		Vector2(uoff, 0.5 + size.z / p), Vector2(uoff + size.x / p, 0.5 + size.z / p), Vector2(uoff + size.x / p, 0.5), Vector2(uoff, 0.5))
	st.set_material(mat)
	st.generate_tangents()
	var m := st.commit()
	block_meshes[key] = m
	return m

func _block(surf_name: String, pos: Vector3, size: Vector3, rot := 0.0, uoff := 0.0, sims := false) -> Node3D:
	# Halter am Fußpunkt; der Stein selbst ist ein Kind, damit das Absenken nur die Höhe des Halters ändert.
	# sims: helleres, überstehendes Gesims obendrauf, wie an ägyptischen Tempelmauern
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = rot
	var mi := MeshInstance3D.new()
	mi.mesh = _block_mesh(size, surf(surf_name), uoff)
	holder.add_child(mi)
	if sims:
		var cap := MeshInstance3D.new()
		cap.mesh = _block_mesh(Vector3(size.x + 0.1, 0.32, size.z + 0.36), surf(surf_name + "_sims"), uoff + 0.13)
		cap.position.y = size.y
		holder.add_child(cap)
	add_child(holder)
	return holder

func _probe(pos: Vector3, size: Vector3, vis: Node3D) -> void:
	# unsichtbarer Körper nur für den Sichtstrahl der Kamera (Ebene 5, Wert 16): lässt Pfeiler absinken,
	# ohne Laufwege oder Sichtlinien der Gegner zu ändern (die prüfen nur Ebene 1; Held 2, Gegner 4)
	var b := StaticBody3D.new()
	b.set_meta("vis", vis)
	b.collision_layer = 16
	b.collision_mask = 0
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	c.shape = s
	b.add_child(c)
	b.position = pos + Vector3(0, size.y / 2, 0)
	add_child(b)

func _floor_mesh(cells: Array, surf_name: String) -> void:
	# alle Bodenzellen einer Sorte als eine Fläche: ein einziger Zeichenaufruf, Muster läuft nahtlos durch
	if cells.is_empty():
		return
	var mat := surf(surf_name)
	var p: float = mat.get_meta("period")
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for c in cells:
		var x0: float = c.x * CELL
		var z0: float = c.y * CELL
		var x1 := x0 + CELL
		var z1 := z0 + CELL
		_quad(st, Vector3(x0, 0.02, z1), Vector3(x1, 0.02, z1), Vector3(x1, 0.02, z0), Vector3(x0, 0.02, z0), Vector3.UP,
			Vector2(x0, z1) / p, Vector2(x1, z1) / p, Vector2(x1, z0) / p, Vector2(x0, z0) / p)
	st.set_material(mat)
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	add_child(mi)

func _box(pos: Vector3, size: Vector3, rot := 0.0, vis: Node3D = null) -> void:
	var b := StaticBody3D.new()
	if vis:
		b.set_meta("vis", vis)
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	c.shape = s
	b.add_child(c)
	b.position = pos + Vector3(0, size.y / 2, 0)
	b.rotation.y = rot
	b.collision_layer = 1
	add_child(b)

func _build_env() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.006, 0.008, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.30, 0.38, 0.60)
	env.ambient_light_energy = 0.17
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.03, 0.05, 0.10)
	env.fog_density = 0.012
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.15
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	moon = DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.68, 1.0)
	moon.light_energy = 0.2
	moon.rotation_degrees = Vector3(-52, -35, 0)
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 70.0
	add_child(moon)

func _build_world() -> void:
	astar.region = Rect2i(0, 0, W * 2, H * 2)
	astar.cell_size = Vector2(2, 2)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	# Sandboden unter allem, damit Lücken nicht ins Leere schauen
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(W * CELL + 80, H * CELL + 80)
	ground.mesh = pm
	var gm := surf("sand_aussen")
	if gm:
		ground.mesh = null
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var e := Vector2(W * CELL + 80, H * CELL + 80) / 2
		var gp: float = gm.get_meta("period")
		_quad(st, Vector3(-e.x, 0, e.y), Vector3(e.x, 0, e.y), Vector3(e.x, 0, -e.y), Vector3(-e.x, 0, -e.y), Vector3.UP,
			Vector2(-e.x, e.y) / gp, Vector2(e.x, e.y) / gp, Vector2(e.x, -e.y) / gp, Vector2(-e.x, -e.y) / gp)
		st.set_material(gm)
		st.generate_tangents()
		ground.mesh = st.commit()
	else:
		gm = StandardMaterial3D.new()
		gm.albedo_color = Color(0.16, 0.135, 0.10)
		gm.roughness = 1.0
		ground.material_override = gm
	ground.position = Vector3(W * CELL / 2, -0.12, H * CELL / 2)
	add_child(ground)
	var pack := 0
	var packs := {}
	var floors := {"gruft": [], "sand": []}
	for cz in H:
		for cx in W:
			var ch: String = MAP[cz][cx]
			var p := cell_pos(cx, cz)
			if ch == "#":
				for sx in 2:
					for sz in 2:
						astar.set_point_solid(Vector2i(cx * 2 + sx, cz * 2 + sz), true)
				continue
			var corridor := (not is_floor(cx - 1, cz) and not is_floor(cx + 1, cz)) or (not is_floor(cx, cz - 1) and not is_floor(cx, cz + 1))
			var crypt := CRYPT.has_point(Vector2i(cx, cz))
			# Räume: Gruftplatten · Gänge: Wüstensand (solange T09 fehlt: Pflaster)
			floors["sand" if corridor and not crypt else "gruft"].append(Vector2i(cx, cz))
			# Mauern an jeder Kante zum Fels. Die Kamera schaut von Südosten: Mauern auf dieser Seite bleiben niedrig,
			# damit sie die Figur nicht verdecken.
			var edges := [[0, -1, 0.0, false], [0, 1, PI, true], [-1, 0, PI / 2, false], [1, 0, -PI / 2, true]]
			for e in edges:
				if is_floor(cx + e[0], cz + e[1]):
					continue
				var wp := p + Vector3(e[0], 0, e[1]) * (CELL / 2)
				var low: bool = e[3]
				# Versatz der Steinlagen je nach Lage: Mauerstücke wirken nicht wie Stempel
				var uoff: float = [0.0, 0.5, 0.25, 0.75][(cx * 3 + cz * 5) % 4] if e[1] != 0 else [0.0, 0.5, 0.25, 0.75][(cz * 3 + cx) % 4]
				var wn := _block("granit" if crypt else "sandstein", wp, Vector3(CELL, 1.2 if low else 4.0, 1.0), e[2], uoff, true)
				_box(wp, Vector3(CELL, 4.0, 1.0), e[2], null if low else wn)
				if not low and (cx * 5 + cz * 3) % 3 == 0 and torches.size() < 16:
					_torch(wp + Vector3(-e[0], 0, -e[1]) * 0.55 + Vector3(0, 2.4, 0), e[2])
			match ch:
				"S":
					start_pos = p
				"B":
					boss = _spawn("boss", p, 99)
				"m", "p":
					# Nachbarn im Umkreis gehören zu einem Rudel und wachen zusammen auf
					var key := "%d_%d" % [cx / 5, cz / 4]
					if not packs.has(key):
						pack += 1
						packs[key] = pack
					_spawn("minion" if ch == "m" else "mage", p + Vector3(randf_range(-0.8, 0.8), 0, randf_range(-0.8, 0.8)), packs[key])
				"t":
					var kindp: String = ["barrel_large", "crates_stacked", "barrel_small_stack", "box_large"][(cx + cz) % 4]
					_piece(kindp, p + Vector3(-0.6, 0, -0.6), (cx * 3 + cz) % 4 * PI / 2)
					_box(p + Vector3(-0.6, 0, -0.6), Vector3(2.0, 2.0, 2.0))
					astar.set_point_solid(Vector2i(cx * 2, cz * 2), true)
				"c":
					_column(p)
					_box(p, Vector3(1.6, 4.0, 1.6))
					for sx in 2:
						for sz in 2:
							astar.set_point_solid(Vector2i(cx * 2 + sx, cz * 2 + sz), true)
	# Eckpfeiler dort, wo Mauern über Eck stehen
	for vz in H + 1:
		for vx in W + 1:
			var f := [is_floor(vx - 1, vz - 1), is_floor(vx, vz - 1), is_floor(vx - 1, vz), is_floor(vx, vz)]
			var n := int(f[0]) + int(f[1]) + int(f[2]) + int(f[3])
			if n == 1 or n == 3 or (n == 2 and f[0] == f[3]):
				var low: bool = f[0] and not (f[1] and f[2])   # liegt die Ecke südöstlich einer Bodenzelle, bleibt sie niedrig
				var in_crypt := false
				for q in [Vector2i(vx - 1, vz - 1), Vector2i(vx, vz - 1), Vector2i(vx - 1, vz), Vector2i(vx, vz)]:
					if CRYPT.has_point(q) and is_floor(q.x, q.y):
						in_crypt = true
				var pp := Vector3(vx * CELL, 0, vz * CELL)
				var pn := _block("granit" if in_crypt else "sandstein", pp, Vector3(1.3, 1.5 if low else 4.5, 1.3), 0.0, 0.37, true)
				if not low:
					pn.set_meta("pfeiler", true)
					_probe(pp, Vector3(1.3, 4.5, 1.3), pn)
	for k in floors:
		_floor_mesh(floors[k], k)
	total = foes.size() - 1
	# Irrende Ba: Lichter, die gegen den Wind ziehen
	for i in 7:
		var w := OmniLight3D.new()
		w.light_color = Color(0.5, 0.95, 0.9)
		w.light_energy = 0.9
		w.omni_range = 5.0
		var m := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.14
		sm.height = 0.28
		m.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.75, 1.0, 0.97)
		m.material_override = mat
		w.add_child(m)
		add_child(w)
		w.position = Vector3(randf_range(6, W * CELL - 6), 3.0, randf_range(6, H * CELL - 6))
		wisps.append({"n": w, "ph": randf() * TAU, "sp": randf_range(0.5, 1.0)})

func _column(p: Vector3) -> void:
	# runde Granitsäule mit Sockel und Deckplatte, wie in einer Grabkammer
	if not mats.has("säule"):
		var sm: StandardMaterial3D = surf("granit").duplicate()
		sm.uv1_scale = Vector3(1.1, 1.0, 1.0)   # Umfang ≈ 4,4 m, Höhe 4 m: Steinmaß wie an der Mauer
		mats["säule"] = sm
	var mat: StandardMaterial3D = mats["säule"]
	var col := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.62
	cm.bottom_radius = 0.7
	cm.height = 4.0
	cm.radial_segments = 20
	cm.rings = 1
	col.mesh = cm
	col.material_override = mat
	col.position = p + Vector3(0, 2.0, 0)
	add_child(col)
	_block("granit", p, Vector3(1.7, 0.35, 1.7), 0.0, 0.1)
	_block("granit", p + Vector3(0, 3.7, 0), Vector3(1.6, 0.4, 1.6), 0.0, 0.6)
	# Feuerschale obendrauf: sonst bleibt die Gruft des Hüters fast schwarz
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.3)
	l.light_energy = 1.9   # flackert wie die Fackeln um diesen Wert
	l.omni_range = 13.0
	l.omni_attenuation = 1.3
	l.position = p + Vector3(0, 4.7, 0)
	add_child(l)
	var fl := CPUParticles3D.new()
	fl.amount = 18
	fl.lifetime = 0.6
	fl.direction = Vector3(0, 1, 0)
	fl.spread = 18.0
	fl.gravity = Vector3(0, 1.5, 0)
	fl.initial_velocity_min = 0.6
	fl.initial_velocity_max = 1.3
	fl.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	fl.emission_sphere_radius = 0.35
	var qm := SphereMesh.new()
	qm.radius = 0.15
	qm.height = 0.3
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color(1.0, 0.72, 0.3)
	qm.material = fm
	fl.mesh = qm
	fl.position = p + Vector3(0, 4.2, 0)
	add_child(fl)
	torches.append({"l": l, "ph": randf() * 10.0})

func _torch(pos: Vector3, rot: float) -> void:
	var t := _piece("torch_mounted", pos, rot)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.62, 0.28)
	l.light_energy = 1.9
	l.omni_range = 10.0
	l.omni_attenuation = 1.4
	l.position = Vector3(0, 0.7, 0.45)
	t.add_child(l)
	var fl := CPUParticles3D.new()
	fl.amount = 14
	fl.lifetime = 0.5
	fl.direction = Vector3(0, 1, 0)
	fl.spread = 12.0
	fl.gravity = Vector3(0, 1.5, 0)
	fl.initial_velocity_min = 0.6
	fl.initial_velocity_max = 1.2
	fl.scale_amount_min = 0.5
	fl.scale_amount_max = 1.0
	var qm := SphereMesh.new()
	qm.radius = 0.11
	qm.height = 0.22
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color(1.0, 0.72, 0.3)
	qm.material = fm
	fl.mesh = qm
	fl.position = Vector3(0, 0.55, 0.42)
	t.add_child(fl)
	if torches.size() < 6:
		sfx.loop_at("torch", t)
	torches.append({"l": l, "ph": randf() * 10.0})

func _spawn(kind: String, pos: Vector3, pack: int) -> Foe:
	var f := Foe.new()
	f.game = self
	f.init(kind, pos, pack)
	add_child(f)
	foes.append(f)
	return f

# ---------------------------------------------------------------- Wege und Sicht
func sees(a: Vector3, b: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(a + Vector3(0, 1.2, 0), b + Vector3(0, 1.2, 0), 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func walkable(a: Vector3, b: Vector3) -> bool:
	# freie Linie in Schulterbreite: zwei Strahlen links und rechts der Mitte
	var d := (b - a)
	d.y = 0
	if d.length() < 0.01:
		return true
	var side := Vector3(-d.z, 0, d.x).normalized() * 0.5
	var sp := get_world_3d().direct_space_state
	for s in [side, -side]:
		var q := PhysicsRayQueryParameters3D.create(a + s + Vector3(0, 0.6, 0), b + s + Vector3(0, 0.6, 0), 1)
		if not sp.intersect_ray(q).is_empty():
			return false
	return true

func _sub(p: Vector3) -> Vector2i:
	return Vector2i(clampi(int(p.x / 2.0), 0, W * 2 - 1), clampi(int(p.z / 2.0), 0, H * 2 - 1))

func find_path(a: Vector3, b: Vector3) -> PackedVector3Array:
	var out := PackedVector3Array()
	var ia := _sub(a)
	var ib := _sub(b)
	if astar.is_point_solid(ia) or astar.is_point_solid(ib):
		return out
	var ids := astar.get_id_path(ia, ib)
	for i in range(1, ids.size()):
		out.append(Vector3(ids[i].x * 2 + 1, 0, ids[i].y * 2 + 1))
	return out

func wake_pack(pack: int) -> void:
	var k := 0
	for f in foes:
		if f.pack == pack and f.state == Foe.St.SLEEP:
			f.wake(k * 0.25)
			k += 1

# ---------------------------------------------------------------- Kampf
func live_foes() -> Array:
	return foes.filter(func(f): return f.state != Foe.St.DEAD)

func _impact(n: int, at: Vector3) -> void:
	if n <= 0:
		return
	sfx.play_at("hit", at, 0.12)
	shake = maxf(shake, 0.22 + 0.05 * n)
	# kurzer Stillstand beim Treffer: gibt dem Hieb Gewicht
	if autotest == null:
		Engine.time_scale = 0.08
		get_tree().create_timer(0.05, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)

func hero_arc(h: Hero, reach: float, half_angle: float, mult: float, push: float, gain: bool) -> void:
	var n := 0
	for f in live_foes():
		var d: Vector3 = f.global_position - h.global_position
		d.y = 0
		if d.length() < reach + f.radius and (d.length() < 1.2 or h.forward().angle_to(d.normalized()) < half_angle):
			f.hit(h.dmg(mult), h.global_position, push)
			spark(f.global_position + Vector3(0, 1.3, 0), Color(1.0, 0.85, 0.6))
			n += 1
	if n > 0 and gain:
		h.en = minf(100.0, h.en + 7.0)
	_impact(n, h.global_position + h.forward() * 1.5)

func hero_slam(c: Vector3, r: float, mult: float, push: float) -> void:
	var n := 0
	for f in live_foes():
		if (f.global_position - c).length() < r + f.radius:
			f.hit(hero.dmg(mult), c, push)
			spark(f.global_position + Vector3(0, 1.3, 0), Color(1.0, 0.85, 0.6))
			n += 1
	_impact(n, c)

func hero_udjat(c: Vector3, r: float) -> void:
	ring_fx(c, r, Color(0.78, 0.45, 0.95))
	shake = maxf(shake, 0.4)
	for f in live_foes():
		if (f.global_position - c).length() < r + f.radius:
			f.hit(hero.dmg(2.2), c, 3.0, 2.2)
	for b in bolts:
		b.n.queue_free()
	bolts.clear()

func hero_beam(h: Hero) -> void:
	var from := h.global_position + Vector3(0, 1.5, 0)
	var dir := h.forward()
	var length := 18.0
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * length, 1)
	var res := get_world_3d().direct_space_state.intersect_ray(q)
	if not res.is_empty():
		length = (res.position - from).length()
	var n := 0
	for f in live_foes():
		var rel: Vector3 = f.global_position - h.global_position
		rel.y = 0
		var along := rel.dot(dir)
		if along > 0.0 and along < length and (rel - dir * along).length() < 0.9 + f.radius:
			f.hit(h.dmg(1.25), h.global_position, 3.0)
			n += 1
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.28, 0.28, length)
	m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.93, 0.66, 0.95)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material_override = mat
	add_child(m)
	m.global_position = from + dir * length / 2
	m.rotation.y = h.face
	var tw := create_tween()
	tw.tween_property(m, "scale", Vector3(0.05, 0.05, 1), 0.22)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.22)
	tw.tween_callback(m.queue_free)
	if n > 0:
		shake = maxf(shake, 0.2)

func spawn_bolt(pos: Vector3, dir: Vector3, dmg: float, speed: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = Color(0.9, 0.4, 0.85)
	l.light_energy = 1.3
	l.omni_range = 4.0
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.24
	sm.height = 0.48
	m.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.95, 0.55, 0.9)
	m.material_override = mat
	l.add_child(m)
	add_child(l)
	l.global_position = pos
	bolts.append({"n": l, "v": dir * speed, "dmg": dmg, "life": 3.2})

func on_foe_dead(f: Foe) -> void:
	if f == boss:
		on_boss_dead()
	else:
		kills += 1
		if randf() < 0.14 and hero.pots < 4:
			hero.pots += 1
			float_text(f.global_position, "+1 Rotbier", Color(0.5, 0.9, 0.55))

func on_boss_wake(b: Foe) -> void:
	boss_awake = true
	hud.boss_show(b.K.name)
	hud.banner(TXT.boss_say, b.K.name.to_upper(), 6.0)
	sfx.play("boss_appear")
	sfx.say("vo_boss")
	shake = maxf(shake, 0.6)

func on_boss_dead() -> void:
	hud.boss_hide()
	hud.banner("Die Stunde ist vollendet. Eine Pforte steht offen.", "DER HÜTER IST GEFALLEN", 5.0)
	sfx.play("victory")
	for f in live_foes():
		if f.global_position.distance_to(boss.global_position) < 30.0:
			f.hit(9999.0, boss.global_position)
	# die Pforte wächst in der Mitte der Bodenplatte, auf der der Hüter fiel (nie in einer Mauer)
	var bp := boss.global_position
	_build_gate(cell_pos(clampi(int(bp.x / CELL), 0, W - 1), clampi(int(bp.z / CELL), 0, H - 1)))

func on_hero_dead() -> void:
	deaths += 1
	await get_tree().create_timer(1.6).timeout
	sfx.say("vo_death")
	get_tree().paused = true
	hud.show_dead(TXT.dead, func():
		sfx.hush()
		for f in foes:
			if f.state == Foe.St.FIGHT or f.state == Foe.St.WAKING:
				f.sleep_again()
		if boss.state != Foe.St.DEAD:
			boss_awake = false
			hud.boss_hide()
		for b in bolts:
			b.n.queue_free()
		bolts.clear()
		hero.revive(start_pos)
		cam_pos = start_pos
		get_tree().paused = false)

# Scheintür: durch sie gehen die Toten zwischen den Welten
func _build_gate(pos: Vector3) -> void:
	gate = Node3D.new()
	add_child(gate)
	gate.global_position = pos + Vector3(0, -5.0, 0)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.36, 0.33, 0.28)
	stone.roughness = 0.95
	var parts := [[Vector3(-1.5, 2.1, 0), Vector3(0.7, 4.2, 0.9)], [Vector3(1.5, 2.1, 0), Vector3(0.7, 4.2, 0.9)], [Vector3(0, 4.5, 0), Vector3(4.2, 0.7, 1.0)], [Vector3(0, 5.05, 0), Vector3(4.8, 0.4, 1.2)]]
	var sand := surf("sandstein_sims")
	for pt in parts:
		var m := MeshInstance3D.new()
		if sand:
			m.mesh = _block_mesh(pt[1], sand, 0.31)   # Fuß bei y = 0, darum um die halbe Höhe tiefer setzen
			m.position = pt[0] - Vector3(0, pt[1].y / 2, 0)
		else:
			var bm := BoxMesh.new()
			bm.size = pt[1]
			m.mesh = bm
			m.material_override = stone
			m.position = pt[0]
		gate.add_child(m)
	var glowm := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(2.3, 4.1, 0.2)
	glowm.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gmat.albedo_color = Color(0.62, 0.95, 0.92)
	glowm.material_override = gmat
	glowm.position = Vector3(0, 2.1, 0)
	gate.add_child(glowm)
	var sun := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.24
	sm.height = 0.48
	sun.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_color = Color(1.0, 0.75, 0.3)
	sun.material_override = smat
	sun.position = Vector3(0, 4.5, 0.55)
	gate.add_child(sun)
	var l := OmniLight3D.new()
	l.light_color = Color(0.55, 0.95, 0.9)
	l.light_energy = 3.0
	l.omni_range = 12.0
	l.position = Vector3(0, 2.2, 1.2)
	gate.add_child(l)
	sfx.play("gate")
	var tw := create_tween()
	tw.tween_property(gate, "global_position:y", 0.0, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	gate_t = 0.0
	gate_ask = true

func _ask_gate() -> void:
	get_tree().paused = true
	sfx.play("ui")
	sfx.say("vo_epi")
	var stats := [[_clock(), "Zeit"], [str(kills), "Besiegte"], [str(deaths), "Rückschläge"]]
	hud.show_gate(TXT.no + " · VOLLENDET", TXT.name, TXT.epi, stats, "HINTER DER PFORTE · ZWEITE STUNDE DER NACHT", TXT.next, TXT.next_lead,
		func():
			sfx.hush()
			hud.show_chapter("ENDE DER PROBESTUNDE", "Herz und Feder", "Hinter der Pforte liegen die Felder von Wernes.", "Das war die erste Stunde der Nacht als 3D-Probe. Wenn sie dir gefällt, bauen wir von hier aus weiter.", "Noch einmal von vorn", func(): Engine.time_scale = 1.0; get_tree().paused = false; get_tree().reload_current_scene()),
		func():
			sfx.hush()
			get_tree().paused = false)

func _clock() -> String:
	return "%d:%02d" % [int(clock) / 60, int(clock) % 60]

# ---------------------------------------------------------------- Effekte
func float_text(pos: Vector3, text: String, col: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = 64
	l.outline_size = 14
	l.modulate = col
	l.pixel_size = 0.012
	add_child(l)
	l.global_position = pos + Vector3(randf_range(-0.4, 0.4), 2.2, randf_range(-0.2, 0.2))
	var tw := create_tween()
	tw.tween_property(l, "global_position:y", l.global_position.y + 1.6, 0.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tw.tween_callback(l.queue_free)

func ring_fx(c: Vector3, r: float, col: Color) -> void:
	var m := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.9
	tm.outer_radius = 1.0
	m.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material_override = mat
	add_child(m)
	m.global_position = c + Vector3(0, 0.25, 0)
	m.scale = Vector3(0.3, 0.3, 0.3)
	var tw := create_tween()
	tw.tween_property(m, "scale", Vector3(r, 0.4, r), 0.28).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.32)
	tw.tween_callback(m.queue_free)

func warn_fx(c: Vector3, r: float, t: float) -> void:
	# Ansage eines schweren Hiebs: roter Kreis am Boden, der sich füllt
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 0.04
	m.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.85, 0.2, 0.15, 0.12)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material_override = mat
	add_child(m)
	m.global_position = c + Vector3(0, 0.12, 0)
	var tw := create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.5, t)
	tw.tween_callback(m.queue_free)

func spark(pos: Vector3, col: Color) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 10
	p.lifetime = 0.35
	p.explosiveness = 1.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 80.0
	p.initial_velocity_min = 2.5
	p.initial_velocity_max = 5.5
	p.gravity = Vector3(0, -12, 0)
	var sm := SphereMesh.new()
	sm.radius = 0.06
	sm.height = 0.12
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	sm.material = mat
	p.mesh = sm
	add_child(p)
	p.global_position = pos
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)

# ---------------------------------------------------------------- Kamera und Eingabe
func _place_cam(k: float) -> void:
	cam_pos = cam_pos.lerp(hero.global_position, k)
	var off := Vector3(14.5, 27.0, 14.5)
	var sh := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * shake * 0.5
	cam.global_position = cam_pos + off + sh
	cam.look_at(cam_pos + Vector3(0, 1.0, 0) + sh * 0.5, Vector3.UP)

func mouse_ground() -> Vector3:
	var mp := get_viewport().get_mouse_position()
	var from := cam.project_ray_origin(mp)
	var dir := cam.project_ray_normal(mp)
	if absf(dir.y) < 0.001:
		return hero.global_position
	var t := -from.y / dir.y
	return from + dir * t

func foe_near(p: Vector3, r: float) -> Foe:
	var best: Foe = null
	var bd := r
	for f in live_foes():
		var d: float = (f.global_position - p).length() - f.radius
		if d < bd:
			bd = d
			best = f
	return best

func _unhandled_input(ev: InputEvent) -> void:
	if not started or get_tree().paused:
		return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		match ev.keycode:
			KEY_1: hero.aim = mouse_ground(); hero.cast("whirl")
			KEY_2: hero.aim = mouse_ground(); hero.cast("dash")
			KEY_3: hero.cast("oath")
			KEY_4: hero.cast("udjat")
			KEY_Q: hero.cast("potion")
			KEY_F: hud.toggle_fps()
			KEY_G: set_low(not low_gfx)
			KEY_M: sfx.set_muted(not sfx.muted)
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
		hero.aim = mouse_ground()
		hero.cast("beam")

func set_low(low: bool) -> void:
	low_gfx = low
	hero.lantern.shadow_enabled = not low
	moon.shadow_enabled = not low
	env.glow_enabled = not low
	get_viewport().scaling_3d_scale = 0.7 if low else 1.0
	# Stein ohne Reliefkarte und ohne anisotrope Filterung: weniger Texturzugriffe je Bildpunkt
	for m in mats.values():
		if m:
			m.normal_enabled = not low and m.normal_texture != null
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if low else BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	hud.toast("Grafik: %s" % ("Niedrig (ohne Schatten und Glühen)" if low else "Hoch"))

func _physics_process(delta: float) -> void:
	if not started:
		return
	clock += delta
	shot_gap -= delta
	if autotest == null:
		# Eingabe: WASD läuft (zur Kamera gedreht), linke Maustaste gehalten läuft zum Zeiger oder greift an
		var v := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if Input.is_physical_key_pressed(KEY_A): v.x -= 1
		if Input.is_physical_key_pressed(KEY_D): v.x += 1
		if Input.is_physical_key_pressed(KEY_W): v.y -= 1
		if Input.is_physical_key_pressed(KEY_S): v.y += 1
		var dir := Vector3.ZERO
		if v.length() > 0.1:
			dir = (Vector3(1, 0, -1).normalized() * v.x + Vector3(1, 0, 1).normalized() * v.y).normalized()
		var mg := mouse_ground()
		hero.aim = mg
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not hud.mouse_over_ui():
			var tgt := foe_near(mg, 1.6)
			var to := mg - hero.global_position
			to.y = 0
			if tgt and (tgt.global_position - hero.global_position).length() < 3.2 + tgt.radius:
				hero.aim = tgt.global_position
				hero.attack()
				dir = Vector3.ZERO
			elif tgt:
				hero.aim = tgt.global_position
				dir = (tgt.global_position - hero.global_position)
				dir.y = 0
				dir = dir.normalized()
			elif Input.is_physical_key_pressed(KEY_SHIFT):
				hero.attack()
				dir = Vector3.ZERO
			elif to.length() > 0.8:
				dir = to.normalized()
		hero.want_dir = dir
	# höchstens zwei Nahkämpfer greifen zugleich an, die anderen lauern
	var melee := foes.filter(func(f): return f.state == Foe.St.FIGHT and f.K.ai == "melee")
	melee.sort_custom(func(a, b): return a.global_position.distance_squared_to(hero.global_position) < b.global_position.distance_squared_to(hero.global_position))
	for i in melee.size():
		melee[i].slot = i < 2
	# Geschosse
	for i in range(bolts.size() - 1, -1, -1):
		var b: Dictionary = bolts[i]
		b.life -= delta
		var n: Node3D = b.n
		n.global_position += b.v * delta
		var hitp: Vector3 = n.global_position
		var gone: bool = b.life <= 0.0 or not sees(hitp - Vector3(0, 1.2, 0), hitp - Vector3(0, 1.2, 0) + b.v.normalized() * 0.3)
		var dh: Vector3 = hitp - hero.global_position
		dh.y = 0
		if not gone and dh.length() < hero.radius + 0.45:
			hero.hurt(b.dmg, hitp - b.v)
			gone = true
		if gone:
			n.queue_free()
			bolts.remove_at(i)
	# Pforte
	if gate:
		gate_t += delta
		var dg := (hero.global_position - gate.global_position)
		dg.y = 0
		if dg.length() > 6.0:
			gate_ask = true
		if gate_t > 3.0 and gate_ask and dg.length() < 2.2 and not hero.dead:
			gate_ask = false
			_ask_gate()

func _cutaway(delta: float) -> void:
	# Strahlen von der Kamera zur Figur: Was dazwischen steht, sinkt auf Brusthöhe und hebt sich danach wieder
	var sp := get_world_3d().direct_space_state
	var side := Vector3(1, 0, -1).normalized()
	for off in [Vector3(0, 0.4, 0), Vector3(0, 1.8, 0), side * 0.9 + Vector3(0, 1.0, 0), -side * 0.9 + Vector3(0, 1.0, 0)]:
		var excl: Array[RID] = []
		for i in 3:
			var q := PhysicsRayQueryParameters3D.create(cam.global_position, hero.global_position + off, 1 | 16)
			q.exclude = excl
			var r := sp.intersect_ray(q)
			if r.is_empty():
				break
			excl.append(r.rid)
			if r.collider.has_meta("vis"):
				sunk[r.collider.get_meta("vis")] = 0.35
	for n in sunk.keys():
		sunk[n] -= delta
		var want := -WALL_SINK if sunk[n] > 0.0 else 0.0
		n.position.y = move_toward(n.position.y, want, delta * 5.0 * 4.0)
		if sunk[n] <= 0.0 and n.position.y >= -0.001:
			n.position.y = 0.0
			sunk.erase(n)

func _process(delta: float) -> void:
	shake = maxf(0.0, shake - delta * 2.2)
	_place_cam(minf(1.0, delta * 6.0))
	_cutaway(delta)
	var t := Time.get_ticks_msec() * 0.001
	for tc in torches:
		tc.l.light_energy = 1.9 + sin(t * 9.0 + tc.ph) * 0.22 + sin(t * 23.0 + tc.ph * 2.0) * 0.12
	for w in wisps:
		var n: Node3D = w.n
		n.position.x -= delta * w.sp
		n.position.y = 2.6 + sin(t * 1.3 + w.ph) * 0.6
		n.position.z += sin(t * 0.4 + w.ph) * delta * 0.5
		if n.position.x < 2.0:
			n.position.x = W * CELL - 2.0
	if started:
		hud.refresh()
		# kommt der Rechner nicht mit, schaltet das Spiel einmal von selbst auf niedrige Grafik
		if autotest == null and not auto_low_done and not low_gfx and clock > 6.0 and not get_tree().paused:
			slow_t = slow_t + delta if Engine.get_frames_per_second() < 28 else 0.0
			if slow_t > 3.0:
				auto_low_done = true
				set_low(true)
				hud.toast("Grafik von selbst auf Niedrig gestellt, weil es ruckelte. G schaltet zurück.")
