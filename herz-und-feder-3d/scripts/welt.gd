class_name Welt extends RefCounted
# Baut aus einer generierten Karte (karte.gd) die 3D-Stunde: Böden je Stundenart, Mauern mit ihrer Höhe (niedrige Reste
# versperren nur den Weg, nicht Sicht und Geschosse), Türme, Hindernisse (Felsen, Glasnadeln, Einrichtung), Wandfackeln,
# Teppiche, Truhen, Fässer, Rudel und den Hüter. Mauern derselben Art werden je Abschnitt zu einem Körper zusammengefasst
# und mit dem Durchblick-Shader (mauer.gdshader) gezeichnet, damit die Figur hinter Mauern sichtbar bleibt.

const C := Karte.CELL
const LOW_LAYER := 32      # Ebene 6: versperrt nur den Weg (niedrige Mauerreste)
const FELD := 6            # Abschnitt in Zellen, zu dem Mauern und Böden zusammengefasst werden
const MAX_TORCHES := 14

# Oberflächen je Stundenart: Mauer, Raumboden, Gang, Gelände (Namen aus main.gd › SURF)
const LOOK := {
	"": {"wall": "sandstein", "room": "pflaster", "path": "sand", "ground": "sand_aussen"},
	"ruin": {"wall": "lehm", "room": "feld", "path": "sand", "ground": "sand_aussen"},
	"tomb": {"wall": "grab", "room": "gruft", "path": "pflaster", "ground": "sand_aussen"},
	"glass": {"wall": "glaswand", "room": "glas", "path": "sand", "ground": "sand_aussen"},
	"vault": {"wall": "hoehle", "room": "hoehlenboden", "path": "pflaster", "ground": "sand_aussen"},
}
# Einrichtung (DPROPS-Nummern der 2D-Fassung) als KayKit-Stücke
const DECO := {0: "barrel_large", 1: "crates_stacked", 2: "candle_triple", 3: "box_large", 6: "sword_shield_gold", 7: "coin_stack_large",
	8: "rubble_large", 10: "trunk_large_A", 11: "rubble_half", 12: "candle_triple", 14: "barrel_small_stack", 15: "coin_stack_large"}

var g: Node
var k: Karte
var look: Dictionary
var merge := {}

func _init(game: Node, karte: Karte) -> void:
	g = game
	k = karte
	look = LOOK.get(k.kind if k.indoor else "", LOOK[""])

static func cell_pos(p: Vector2) -> Vector3:
	return Vector3(p.x * C, 0, p.y * C)

func bauen() -> void:
	g.astar.region = Rect2i(0, 0, Karte.GW, Karte.GH)
	g.astar.cell_size = Vector2(C, C)
	g.astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	g.astar.update()
	for y in Karte.GH:
		for x in Karte.GW:
			if k.wall(x, y):
				g.astar.set_point_solid(Vector2i(x, y), true)
	_ground()
	_floors()
	_walls()
	_edges()
	_rugs()
	_obstacles()
	_sconces()
	for c in k.chests:
		g._chest(cell_pos(c.p), c.tier)
	for p in k.casks:
		var pos := cell_pos(p)
		var n: Node3D = g._piece(["barrel_large", "barrel_small_stack", "crates_stacked", "box_large"].pick_random(), pos, randf() * TAU, Vector3.ONE * 0.7)
		var body: StaticBody3D = g._box(pos, Vector3(0.9, 1.2, 0.9))
		g.astar.set_point_solid(g._sub(pos), true)
		g.breakables.append({"n": n, "body": body, "sub": g._sub(pos), "pos": pos})
	g.start_pos = cell_pos(k.start)
	_packs()
	g.boss = g._spawn("boss", cell_pos(k.lair), 99, "", g.hdef)
	g.boss.home_face = atan2(k.start.x - k.lair.x, k.start.y - k.lair.y)
	g.boss.face = g.boss.home_face
	if g.boss.model:
		g.boss.model.rotation.y = g.boss.face

# ---------------------------------------------------------------- Boden
func _ground() -> void:
	var gm: StandardMaterial3D = g.surf(look.ground)
	var e := Vector2(Karte.GW * C + 60.0, Karte.GH * C + 60.0) / 2.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var per: float = gm.get_meta("period")
	g._quad(st, Vector3(-e.x, 0, e.y), Vector3(e.x, 0, e.y), Vector3(e.x, 0, -e.y), Vector3(-e.x, 0, -e.y), Vector3.UP,
		Vector2(-e.x, e.y) / per, Vector2(e.x, e.y) / per, Vector2(e.x, -e.y) / per, Vector2(-e.x, -e.y) / per)
	st.set_material(gm)
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	if k.indoor:
		# im Dungeon liegt das Gelände im Dunkeln: nur eine Ahnung von Sand zwischen den Mauern
		var dark := gm.duplicate()
		dark.albedo_color = gm.albedo_color * 0.25
		mi.material_override = dark
	g.add_child(mi)
	mi.global_position = Vector3(Karte.GW * C / 2.0, -0.12, Karte.GH * C / 2.0)

func _floors() -> void:
	var parts := {}
	for y in Karte.GH:
		for x in Karte.GW:
			if k.wall(x, y):
				continue
			var f := k.flr[Karte.gi(x, y)]
			var name: String
			if k.indoor:
				name = look.room if f == 0 else look.path
			elif f == 2:
				name = "pflaster"
			else:
				continue   # Freiland: das Gelände trägt den Sand
			var key := "%s|%d|%d" % [name, x / FELD, y / FELD]
			if not parts.has(key):
				parts[key] = [name, []]
			parts[key][1].append(Vector2i(x, y))
	for key in parts:
		var name: String = parts[key][0]
		var mat: StandardMaterial3D = g.surf(name)
		var per: float = mat.get_meta("period")
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for c in parts[key][1]:
			var x0: float = c.x * C
			var z0: float = c.y * C
			var x1 := x0 + C
			var z1 := z0 + C
			g._quad(st, Vector3(x0, 0.02, z1), Vector3(x1, 0.02, z1), Vector3(x1, 0.02, z0), Vector3(x0, 0.02, z0), Vector3.UP,
				Vector2(x0, z1) / per, Vector2(x1, z1) / per, Vector2(x1, z0) / per, Vector2(x0, z0) / per)
		st.set_material(mat)
		st.generate_tangents()
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		g.add_child(mi)

# ---------------------------------------------------------------- Mauern
static func wall_m(h: int) -> float:
	# Mauerhöhe der 2D-Fassung (96 = volle Mauer) in Metern; Türme ragen hoch auf
	return clampf(h / 96.0 * 3.6, 0.5, 9.6)

func _visible_wall(x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if not k.wall(x + dx, y + dy):
				return true
	return false

func _walls() -> void:
	var name: String = look.wall
	for y in Karte.GH:
		for x in Karte.GW:
			if not k.wall(x, y) or not _visible_wall(x, y):
				continue
			var hpx := k.height(x, y)
			var h := wall_m(hpx)
			var surf_name := name if hpx != Karte.TOWER else "sandstein"
			var mat: StandardMaterial3D = g.surf(surf_name)
			var uoff: float = [0.0, 0.5, 0.25, 0.75][(x * 3 + y * 5) % 4]
			var pos := Vector3((x + 0.5) * C, 0, (y + 0.5) * C)
			_add_merge(surf_name, g._block_mesh(Vector3(C, h, C), mat, uoff), Transform3D(Basis(), pos), x, y)
			var body: StaticBody3D = g._box(pos, Vector3(C, maxf(h, 1.0), C))
			body.collision_layer = 1 if hpx >= 50 else LOW_LAYER
	for key in merge:
		var mi := MeshInstance3D.new()
		mi.mesh = merge[key][0].commit()
		mi.material_override = g.cut_mat(merge[key][1])
		g.add_child(mi)
	merge.clear()

func _add_merge(surf_name: String, mesh: ArrayMesh, xf: Transform3D, x: int, y: int) -> void:
	var key := "%s|%d|%d" % [surf_name, x / FELD, y / FELD]
	if not merge.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		merge[key] = [st, surf_name]
	merge[key][0].append_from(mesh, 0, xf)

func _edges() -> void:
	# unsichtbare Grenze ringsum: im Freiland steht sonst nichts am Rand
	var w := Karte.GW * C
	var h := Karte.GH * C
	for b in [[Vector3(w / 2.0, 0, -1.0), Vector3(w + 4, 3, 2)], [Vector3(w / 2.0, 0, h + 1.0), Vector3(w + 4, 3, 2)],
			[Vector3(-1.0, 0, h / 2.0), Vector3(2, 3, h + 4)], [Vector3(w + 1.0, 0, h / 2.0), Vector3(2, 3, h + 4)]]:
		var body: StaticBody3D = g._box(b[0], b[1])
		body.collision_layer = LOW_LAYER

func _rugs() -> void:
	for r in k.rugs:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(r.w * C, 0.02, r.h * C)
		m.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = r.col
		mat.roughness = 1.0
		m.material_override = mat
		g.add_child(m)
		m.global_position = Vector3((r.x + r.w / 2.0) * C, 0.04, (r.y + r.h / 2.0) * C)

# ---------------------------------------------------------------- Hindernisse
func _obstacles() -> void:
	for o in k.obst:
		var pos := cell_pos(o.p)
		var r: float = o.r * C
		match o.kind:
			"rock", "ruin":
				var n: Node3D = g._piece("rubble_large" if o.kind == "rock" else "rubble_half", pos, randf() * TAU, Vector3.ONE * clampf(r * 1.3, 0.6, 2.2))
				n.set_meta("deko", true)
			"needle", "star":
				_needle(pos, r, Color(0.56, 0.89, 0.88) if o.kind == "needle" else Color(0.75, 0.6, 1.0))
			"tomb":
				g._piece("trunk_large_A", pos, randf() * TAU, Vector3.ONE * clampf(r * 1.4, 0.7, 1.6))
			"d":
				if o.v == 9:
					_column(pos, r)
				else:
					g._piece(DECO.get(o.v, "box_large"), pos, randf() * TAU, Vector3.ONE * clampf(r * 1.6, 0.6, 1.4))
		var body: StaticBody3D = g._box(pos, Vector3(r * 1.5, 1.6, r * 1.5))
		body.collision_layer = LOW_LAYER if o.kind != "needle" and o.kind != "star" and r < 0.6 else 1
		g.astar.set_point_solid(g._sub(pos), true)

func _needle(pos: Vector3, r: float, col: Color) -> void:
	# Glasnadel aus dem Sand: schräg, kühl leuchtend, ohne eigenes Licht
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.04
	cm.bottom_radius = clampf(r * 0.45, 0.2, 0.6)
	cm.height = clampf(r * 4.0, 2.0, 4.5)
	cm.radial_segments = 6
	cm.rings = 1
	m.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col * 0.6
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.9
	mat.roughness = 0.2
	m.material_override = mat
	g.add_child(m)
	m.global_position = pos + Vector3(0, cm.height * 0.45, 0)
	m.rotation = Vector3(randf_range(-0.25, 0.25), randf() * TAU, randf_range(-0.25, 0.25))

func _column(pos: Vector3, r: float) -> void:
	var col := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.45
	cm.bottom_radius = 0.5
	cm.height = 3.2
	cm.radial_segments = 14
	cm.rings = 1
	col.mesh = cm
	col.material_override = g.surf("granit")
	g.add_child(col)
	col.global_position = pos + Vector3(0, 1.6, 0)

func _sconces() -> void:
	var list: Array = k.sconces.duplicate()
	list.shuffle()
	for s in list.slice(0, MAX_TORCHES):
		var p := cell_pos(s.p)
		if s.dir == 0:
			g._torch(p + Vector3(0, 2.2, 0.25), 0.0)
		else:
			g._torch(p + Vector3(0.25, 2.2, 0), PI / 2)

# ---------------------------------------------------------------- Rudel (03-world.js › newFall)
func _packs() -> void:
	var D := Spiel.D()
	var pid := 0
	for sp in k.spots:
		if sp.get("extra", false) and float(D.pack) < 0.8:
			continue
		var c := cell_pos(sp.p)
		if g.astar.is_point_solid(g._sub(c)):
			continue
		pid += 1
		var comp := Stunden.expand(g.hdef.packs.pick_random())
		comp = comp.slice(0, maxi(2, int(round(comp.size() * float(D.pack)))))
		var style: String = sp.style
		var way := []
		for wp in sp.get("way", []):
			way.append(cell_pos(wp))
		if way.is_empty():
			way = [c, c + Vector3(6, 0, 0)]
		var face := randf() * TAU
		if way.size() > 1:
			face = atan2(way[1].x - way[0].x, way[1].z - way[0].z)
		if style == "lager":
			g._campfire(c)
		var lead: Foe = null
		for i in comp.size():
			var pos: Vector3 = g._pack_pos(style, c, face, i, comp.size())
			if not g.walkable(c, pos) or g.astar.is_point_solid(g._sub(pos)):
				pos = c + Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
			var el: String = ""
			if i == 0 and (sp.get("elite", false) or randf() < 0.2):
				el = Daten.ELITE.pick_random().id
			var f: Foe = g._spawn(comp[i], pos, pid, el, g.hdef)
			f.home_face = atan2(c.x - pos.x, c.z - pos.z) if style == "lager" else face
			f.face = f.home_face
			if f.model:
				f.model.rotation.y = f.face
			f.set_style(style, way)
			if style == "streife":
				f.lead = lead
				if lead == null:
					lead = f
