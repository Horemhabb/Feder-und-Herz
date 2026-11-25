class_name Affixe
# Eigenschaften der Champions (4.1, nach dem Vorbild von Diablo 4): Ein Champion ist nicht nur ein Gegner mit mehr Leben.
# Jede Eigenschaft ändert, wie er kämpft, und man sieht sie, bevor man das Schild liest: Farbe der Glut in seinen Rissen,
# Krone mit farbigem Stein, Aura am Boden, Standarte, Federschild, Ketten, Sandwolke. Mit jeder Stunde kommen mehr dazu.
# Alles, was eine Eigenschaft in die Welt setzt (Glutflecken, Kette, Diener), verschwindet mit dem Champion.
#
# Ablauf: Foe.init würfelt (wuerfeln) und legt an (anlegen); Foe ruft tick im Kampf, treffer bei jedem Treffer und tod
# beim Fallen. Der Zustand jeder Eigenschaft liegt in f.aff[id].

const LISTE := {
	"glut": {"name": "Glutspur", "titel": "der Glühende", "farbe": Color(1.0, 0.5, 0.15), "ab": 1,
		"txt": "Wo er geht, bleibt Glut liegen. Nicht hineintreten."},
	"sturm": {"name": "Sandsturm", "titel": "im Sandsturm", "farbe": Color(0.92, 0.76, 0.45), "ab": 1,
		"txt": "Seths Sand umgibt ihn. Darin brennt deine Laterne schwach, und der Sand schneidet."},
	"feder": {"name": "Schild der Maat", "titel": "unter der Feder", "farbe": Color(0.98, 0.88, 0.45), "ab": 1,
		"txt": "Von vorn hält die Feder fast alles ab. Triff ihn von der Seite oder von hinten, oder brich die Feder."},
	"ruf": {"name": "Rufer", "titel": "der Rufende", "farbe": Color(0.76, 0.5, 1.0), "ab": 1,
		"txt": "Unter seiner Standarte stehen Diener auf. Fällt er, zerfallen sie."},
	"sprung": {"name": "Ba-Sprung", "titel": "der Springende", "farbe": Color(0.45, 0.95, 0.9), "ab": 2,
		"txt": "Sein Ba springt voraus. Wo ein türkiser Kreis aufleuchtet, steht er gleich."},
	"klage": {"name": "Totenklage", "titel": "der Klagende", "farbe": Color(0.5, 0.58, 1.0), "ab": 2,
		"txt": "Er klagt, und sein Rudel wird rasend. Wer die Klage hört, sollte ihn zuerst fällen."},
	"fessel": {"name": "Fessel der Selket", "titel": "der Fesselnde", "farbe": Color(0.85, 0.3, 0.25), "ab": 3,
		"txt": "Er wirft eine Fessel entlang einer roten Bahn und zieht dich heran. Tritt zur Seite."},
	"spalt": {"name": "Zweigeteilt", "titel": "der Zweigeteilte", "farbe": Color(0.6, 1.0, 0.55), "ab": 3,
		"txt": "Ein Riss geht durch ihn. Fällt er, stehen zwei kleinere auf."},
	"kette": {"name": "Feuerkette", "titel": "kettengebunden", "farbe": Color(1.0, 0.32, 0.12), "ab": 4,
		"txt": "Zwei Champions, eine glühende Kette dazwischen. Nicht durchlaufen; fällt einer, erlischt sie."},
}
const ORDNUNG := ["glut", "sturm", "feder", "ruf", "sprung", "klage", "fessel", "spalt", "kette"]

# Wie viele Eigenschaften: eine in den ersten Stunden, zwei ab der dritten, drei ab der siebten (Albtraum: ab der dritten)
static func anzahl(fall: int, diff: int) -> int:
	var h := Stunden.hour_of(fall) + 12 * (Stunden.night_of(fall) - 1)
	var n := 1
	if h >= 3:
		n = 2
	if h >= 7 or (diff >= 2 and h >= 3):
		n = 3
	return n

static var vorgabe: Array = []   # für Prüfungen: diese Eigenschaften statt gewürfelter

static func wuerfeln(fall: int, diff: int, kind: String) -> Array:
	if not vorgabe.is_empty():
		return vorgabe.duplicate()
	var h := Stunden.hour_of(fall) + 12 * (Stunden.night_of(fall) - 1)
	var pool: Array = ORDNUNG.filter(func(id): return int(LISTE[id].ab) <= h)
	# was nicht zur Gestalt passt: Lichter tragen keinen Federschild, Schwärme keine Kette
	if kind == "wisp" or kind == "skorp":
		pool.erase("feder")
		pool.erase("fessel")
	pool.shuffle()
	return pool.slice(0, mini(anzahl(fall, diff), pool.size()))

static func farbe(f) -> Color:
	return LISTE[f.affixe[0]].farbe if not f.affixe.is_empty() else Color(0.95, 0.82, 0.29)

static func titel(f) -> String:
	return LISTE[f.affixe[0]].titel if not f.affixe.is_empty() else ""

static func _unshaded(col: Color, add := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	if col.a < 1.0 or add:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if add:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

static func _mesh(m: Mesh, mat: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

static func _teil(f, n: Node3D) -> Node3D:
	f.add_child(n)
	f.elite_teile.append(n)
	return n

# An einen Knochen der Figur hängen (Krone, Standarte, Kette); Lichter und Skorpione haben keine Knochen
const KNOCHEN_ERSATZ := {"head": "kopf", "chest": "leib", "hips": "leib"}   # Ba und Skorpion heißen anders

static func _am_knochen(f, knochen: String, n: Node3D, ersatz: Vector3) -> void:
	if f.skel and f.skel.find_bone(knochen) < 0 and f.skel.find_bone(KNOCHEN_ERSATZ.get(knochen, "")) >= 0:
		knochen = KNOCHEN_ERSATZ[knochen]
	if f.skel and f.skel.find_bone(knochen) >= 0:
		f.attach(knochen, n)
		f.elite_teile.append(n)
	else:
		n.position = ersatz
		_teil(f, n)

# ---------------------------------------------------------------- Aussehen
static func anlegen(f, ids: Array) -> void:
	f.affixe = ids.duplicate()
	f.aff = {}
	for id in ids:
		f.aff[id] = {"t": randf_range(2.0, 4.0)}
	var col := farbe(f)
	var low: bool = f.game.low_gfx
	# Boden: Aura in der Farbe der ersten Eigenschaft, darin ein goldener Ring, der sich langsam dreht
	var aura := Node3D.new()
	aura.position.y = 0.05
	var tm := TorusMesh.new()
	tm.inner_radius = f.radius * 1.5
	tm.outer_radius = f.radius * 1.75
	tm.rings = 32
	tm.ring_segments = 4
	aura.add_child(_mesh(tm, _unshaded(Color(col, 0.9), true)))
	var tm2 := TorusMesh.new()
	tm2.inner_radius = f.radius * 1.25
	tm2.outer_radius = f.radius * 1.33
	tm2.rings = 6   # sechseckig: sieht aus wie ein gezeichneter Bannkreis
	tm2.ring_segments = 3
	aura.add_child(_mesh(tm2, _unshaded(Color(0.95, 0.82, 0.29, 0.85))))
	var disk := CylinderMesh.new()
	disk.top_radius = f.radius * 1.75
	disk.bottom_radius = f.radius * 1.75
	disk.height = 0.01
	disk.radial_segments = 24
	aura.add_child(_mesh(disk, _unshaded(Color(col, 0.16), true)))
	_teil(f, aura)
	f.set_meta("aura", aura)
	# Krone mit Stein in der Farbe der ersten Eigenschaft: der Umriss eines Champions, auch von hinten
	var krone := Node3D.new()
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.85, 0.66, 0.25)
	gold.metallic = 0.8
	gold.roughness = 0.35
	gold.emission_enabled = true
	gold.emission = Color(0.6, 0.42, 0.12)
	gold.emission_energy_multiplier = 0.6
	var band := CylinderMesh.new()
	band.top_radius = 0.3
	band.bottom_radius = 0.27
	band.height = 0.14
	band.radial_segments = 10
	krone.add_child(_mesh(band, gold))
	for i in 5:
		var a := TAU * i / 5.0
		var z := CylinderMesh.new()
		z.top_radius = 0.0
		z.bottom_radius = 0.07
		z.height = 0.34 if i == 0 else 0.22
		z.radial_segments = 5
		var zi := _mesh(z, gold, Vector3(sin(a) * 0.27, 0.15 + z.height * 0.5 - 0.07, cos(a) * 0.27))
		krone.add_child(zi)
	var stein := SphereMesh.new()
	stein.radius = 0.09
	stein.height = 0.18
	stein.radial_segments = 8
	stein.rings = 4
	krone.add_child(_mesh(stein, _unshaded(col), Vector3(0, 0.1, 0.3)))
	if f.proc:
		krone.scale = Vector3.ONE * maxf(1.0, f.radius * 2.0)
		_teil(f, krone)
		krone.position = Vector3(0, (1.3 + f.radius * 2.0) if f.K.get("look", "") == "wisp" else f.radius * 1.4, 0)
		f.set_meta("krone_frei", krone)
	else:
		krone.position = Vector3(0, 0.62, 0.02)
		_am_knochen(f, "head", krone, Vector3(0, 2.6 * f.sc, 0))
	# Glut in den Rissen der Figur: in der Farbe der ersten Eigenschaft
	if not f.proc:
		f.glut(1.6, col)
	# Licht und Leuchtspur nur, wenn die Grafik es hergibt
	if not low:
		var l := OmniLight3D.new()
		l.light_color = col
		l.light_energy = 0.9
		l.omni_range = 3.6
		l.position = Vector3(0, 1.2, 0)
		_teil(f, l)
		f.set_meta("aff_licht", l)
		_teil(f, _funken(col, 10, 0.9, Vector3(0, 0.15, 0), f.radius * 0.7, Vector3(0, 0.6, 0)))
	for id in ids:
		match id:
			"glut":
				f.aff.glut["flecken"] = []
			"sturm":
				var wolke := _funken(LISTE.sturm.farbe, 16 if low else 42, 1.6, Vector3(0, 0.8, 0), 4.2, Vector3(0, 0.3, 0), 0.16)
				wolke.orbit_velocity_min = 0.25
				wolke.orbit_velocity_max = 0.45
				_teil(f, wolke)
				var boden := CylinderMesh.new()
				boden.top_radius = 5.0
				boden.bottom_radius = 5.0
				boden.height = 0.01
				boden.radial_segments = 32
				var bi := _mesh(boden, _unshaded(Color(0.85, 0.68, 0.4, 0.13), true), Vector3(0, 0.04, 0))
				_teil(f, bi)
			"feder":
				# Federschild: eine goldene Scheibe vor ihm, die sich mit ihm dreht; dazu die Feder der Maat auf dem Kopf
				var schwenk := Node3D.new()
				var sm := CylinderMesh.new()
				sm.top_radius = f.radius * 1.25 + 0.3
				sm.bottom_radius = sm.top_radius
				sm.height = 0.05
				sm.radial_segments = 20
				var scheibe := _mesh(sm, _unshaded(Color(1.0, 0.86, 0.4, 0.32), true), Vector3(0, 1.15 * maxf(1.0, f.sc), f.radius + 0.45))
				scheibe.rotation.x = PI / 2
				schwenk.add_child(scheibe)
				var rand := TorusMesh.new()
				rand.inner_radius = sm.top_radius * 0.92
				rand.outer_radius = sm.top_radius
				rand.rings = 20
				rand.ring_segments = 4
				var ri := _mesh(rand, _unshaded(Color(1.0, 0.9, 0.5, 0.9)), scheibe.position)
				ri.rotation.x = PI / 2
				schwenk.add_child(ri)
				_teil(f, schwenk)
				f.aff.feder["schwenk"] = schwenk
				f.aff.feder["scheibe"] = scheibe
				f.aff.feder["halt"] = f.max_hp * 0.3
				f.aff.feder["bruch_t"] = 0.0
				var feder := BoxMesh.new()
				feder.size = Vector3(0.05, 0.7, 0.2)
				var fm := StandardMaterial3D.new()
				fm.albedo_color = Color(0.96, 0.94, 0.86)
				fm.emission_enabled = true
				fm.emission = Color(1.0, 0.9, 0.6)
				fm.emission_energy_multiplier = 0.5
				var fe := _mesh(feder, fm, Vector3(0, 0.55, -0.05))
				fe.rotation.x = -0.25
				if f.proc:
					fe.position = Vector3(0, f.radius * 2.4, 0)
					_teil(f, fe)
				else:
					_am_knochen(f, "head", fe, Vector3(0, 2.9 * f.sc, 0))
			"ruf":
				# Standarte auf dem Rücken: Stange und Tuch
				var st := Node3D.new()
				var stange := CylinderMesh.new()
				stange.top_radius = 0.035
				stange.bottom_radius = 0.035
				stange.height = 2.2
				stange.radial_segments = 6
				var holz := StandardMaterial3D.new()
				holz.albedo_color = Color(0.32, 0.22, 0.12)
				st.add_child(_mesh(stange, holz, Vector3(0, 0.6, 0)))
				var tuch := QuadMesh.new()
				tuch.size = Vector2(0.55, 0.8)
				var tm3 := StandardMaterial3D.new()
				tm3.albedo_color = Color(0.45, 0.22, 0.7)
				tm3.emission_enabled = true
				tm3.emission = LISTE.ruf.farbe
				tm3.emission_energy_multiplier = 0.45
				tm3.cull_mode = BaseMaterial3D.CULL_DISABLED
				var ti := _mesh(tuch, tm3, Vector3(0.3, 1.35, 0))
				st.add_child(ti)
				var spitze := SphereMesh.new()
				spitze.radius = 0.09
				spitze.height = 0.18
				st.add_child(_mesh(spitze, gold, Vector3(0, 1.75, 0)))
				f.aff.ruf["tuch"] = ti
				f.aff.ruf["diener"] = []
				if f.proc:
					st.scale = Vector3.ONE * maxf(0.8, f.radius * 1.5)
					st.position = Vector3(0, f.radius, -f.radius)
					_teil(f, st)
				else:
					_am_knochen(f, "chest", st, Vector3(0, 1.2 * f.sc, -0.4))
					st.position = Vector3(0, 0.0, -0.32)
			"sprung":
				_teil(f, _funken(LISTE.sprung.farbe, 6 if low else 16, 0.6, Vector3(0, 1.0, 0), f.radius * 0.9, Vector3(0, 0.1, 0), 0.22))
			"klage":
				var traenen := _funken(LISTE.klage.farbe, 6 if low else 14, 1.0, Vector3(0, 2.1 * maxf(1.0, f.sc) if not f.proc else 1.8, 0), 0.25, Vector3(0, -2.5, 0), 0.08)
				_teil(f, traenen)
			"fessel":
				# drei Kettenglieder um den Leib, dunkelrot glühend
				var kn := Node3D.new()
				var km := StandardMaterial3D.new()
				km.albedo_color = Color(0.25, 0.16, 0.14)
				km.metallic = 0.6
				km.emission_enabled = true
				km.emission = LISTE.fessel.farbe
				km.emission_energy_multiplier = 0.7
				for i in 3:
					var glied := TorusMesh.new()
					glied.inner_radius = 0.42 + i * 0.03
					glied.outer_radius = 0.5 + i * 0.03
					glied.rings = 14
					glied.ring_segments = 5
					var gi := _mesh(glied, km, Vector3(0, -0.1 + i * 0.16, 0))
					gi.rotation.z = 0.25 * (i - 1)
					kn.add_child(gi)
				if f.proc:
					kn.scale = Vector3.ONE * maxf(0.8, f.radius * 1.6)
					kn.position.y = f.radius * 0.6
					_teil(f, kn)
				else:
					_am_knochen(f, "hips", kn, Vector3(0, 1.0 * f.sc, 0))
			"spalt":
				# eine helle Naht, senkrecht durch die Gestalt
				var naht := BoxMesh.new()
				naht.size = Vector3(0.04, 1.9 * maxf(1.0, f.sc) if not f.proc else f.radius * 2.0, f.radius * 1.4)
				var ni := _mesh(naht, _unshaded(Color(LISTE.spalt.farbe, 0.8), true), Vector3(0, (1.15 * maxf(1.0, f.sc)) if not f.proc else f.radius, 0))
				_teil(f, ni)
				f.aff.spalt["naht"] = ni
			"kette":
				f.aff.kette["partner"] = null
	f.set_meta("aff_bereit", true)

# Wenige Teilchen in einer Farbe (im Browser billig): Spur, Sandwolke, Tränen
static func _funken(col: Color, n: int, life: float, pos: Vector3, radius: float, grav: Vector3, groesse := 0.1) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = n
	p.lifetime = life
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.4
	p.gravity = grav
	var kurve := Curve.new()
	kurve.add_point(Vector2(0, 1.0))
	kurve.add_point(Vector2(1, 0.0))
	p.scale_amount_curve = kurve
	var q := QuadMesh.new()
	q.size = Vector2(groesse, groesse)
	var m := _unshaded(Color(col, 0.7), true)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = m
	p.mesh = q
	p.position = pos
	return p

# Auftritt beim Erwachen: das Rudel weicht zur Seite, zwei Ringe in seiner Farbe, ein tiefer Ton
static func auftritt(f) -> void:
	var g = f.game
	var col := farbe(f)
	g.ring_fx(f.global_position, 3.2, col)
	g.ring_fx(f.global_position, 1.8, Color(0.95, 0.82, 0.29))
	g.sfx.play_at("boss_appear", f.global_position, 0.1, -11.0)
	g.shake = maxf(g.shake, 0.2)
	for o in g.foes:
		if o != f and o.pack == f.pack and o.state != Foe.St.DEAD:
			var weg: Vector3 = f.flat(o.global_position - f.global_position)
			if weg.length() < 3.0:
				o.kb += (weg.normalized() if weg.length() > 0.05 else Vector3(1, 0, 0)) * 7.0
	f._show_mark("!", col, 1.2)

# Niederlage des Helden: Champions schlafen wieder; was sie in die Welt gesetzt haben, vergeht
static func ruhe(f) -> void:
	if not f.has_meta("aff_bereit"):
		return
	for id in f.affixe:
		var s: Dictionary = f.aff[id]
		match id:
			"glut":
				for e in s.flecken:
					_fleck_aus(e)
				s.flecken = []
			"sturm":
				if s.get("drin", false):
					s.drin = false
					_laterne(f.game, false)
			"kette":
				_kette_aus(s)
				s["gesucht"] = false
				s["partner"] = null

# ---------------------------------------------------------------- Kampf
static func tick(f, delta: float, h) -> void:
	if not f.has_meta("aff_bereit"):
		return
	var aura: Node3D = f.get_meta("aura")
	aura.rotation.y += delta * 0.6
	var to: Vector3 = f.flat(h.global_position - f.global_position)
	var d := to.length()
	var g = f.game
	# Schritt-Erschütterung: schwere Champions lassen den Boden leicht beben, wenn sie nahe heranlaufen
	if f.proc == null and f.velocity.length() > 1.0 and d < 9.0:
		f.tritt_t -= delta
		if f.tritt_t <= 0.0:
			f.tritt_t = 0.5
			g.shake = maxf(g.shake, 0.07)
	for id in f.affixe:
		var s: Dictionary = f.aff[id]
		s.t -= delta
		match id:
			"glut":
				_glut_tick(f, s, delta, h)
			"sturm":
				var drin: bool = d < 5.0 and not h.dead
				if drin != s.get("drin", false):
					s["drin"] = drin
					_laterne(g, drin)
				if drin and s.t <= 0.0:
					s.t = 1.0
					h.hurt(f.dmg * 0.18, f.global_position, f)
			"feder":
				var schwenk: Node3D = s.schwenk
				schwenk.rotation.y = f.model.rotation.y if f.model else f.face
				if s.bruch_t > 0.0:
					s.bruch_t -= delta
					if s.bruch_t <= 0.0:
						s.halt = f.max_hp * 0.3
						s.scheibe.visible = true
						schwenk.visible = true
						g.ring_fx(f.global_position, f.radius + 1.0, LISTE.feder.farbe)
						g.float_text(f.global_position + Vector3(0, 2.8, 0), "die Feder wächst nach", LISTE.feder.farbe)
			"ruf":
				var tuch: Node3D = s.tuch
				tuch.rotation.y = sin(Time.get_ticks_msec() * 0.004) * 0.35
				s.diener = s.diener.filter(func(x): return is_instance_valid(x) and x.state != Foe.St.DEAD)
				if s.t <= 0.0 and f.wind <= 0.0 and f.stun <= 0.0 and s.diener.size() < 3 and d < 16.0:
					s.t = 12.0
					_rufen(f, s)
			"sprung":
				if s.t <= 0.0 and f.wind <= 0.0 and f.stun <= 0.0 and d > 3.0 and d < 15.0 and not h.dead:
					s.t = randf_range(6.0, 8.0)
					_springen(f, h)
			"klage":
				if s.t <= 0.0 and f.wind <= 0.0 and f.stun <= 0.0 and d < 16.0:
					s.t = 10.0
					_klagen(f)
			"fessel":
				if s.t <= 0.0 and f.wind <= 0.0 and f.stun <= 0.0 and d > 3.5 and d < 11.0 and not h.dead and g.sees(f.global_position, h.global_position):
					s.t = 9.0
					_fesseln(f, h)
			"kette":
				_kette_tick(f, s, delta, h)

static func _laterne(g, dunkel: bool) -> void:
	var h = g.hero
	if h == null or h.lantern == null:
		return
	var voll: float = Hero.LATERNE_WEITE * Spiel.S.cone
	var tw: Tween = h.create_tween()
	tw.tween_property(h.lantern, "omni_range", voll * (0.45 if dunkel else 1.0), 0.6)

static func _glut_tick(f, s: Dictionary, delta: float, h) -> void:
	var g = f.game
	var fl: Array = s.flecken
	# alle 0,5 s, wenn er sich bewegt, ein neuer Fleck (höchstens acht; der älteste erlischt)
	if s.t <= 0.0 and f.velocity.length() > 0.6:
		s.t = 0.5
		var c: Vector3 = f.global_position
		if fl.is_empty() or fl[-1].c.distance_to(c) > 0.9:
			fl.append({"c": c, "bis": g.clock + 5.0, "n": _glutfleck(g, c), "tick": 0.0})
			if fl.size() > 8:
				_fleck_aus(fl.pop_front())
	for i in range(fl.size() - 1, -1, -1):
		var e: Dictionary = fl[i]
		if g.clock > e.bis:
			_fleck_aus(e)
			fl.remove_at(i)
			continue
		e.tick -= delta
		if e.tick <= 0.0 and not h.dead and f.flat(h.global_position - e.c).length() < 0.95 + h.radius * 0.5:
			e.tick = 0.5
			h.hurt(f.dmg * 0.22, e.c, f)

static func _glutfleck(g, c: Vector3) -> Node3D:
	var n := Node3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.95
	cm.bottom_radius = 0.95
	cm.height = 0.02
	cm.radial_segments = 14
	n.add_child(_mesh(cm, _unshaded(Color(1.0, 0.42, 0.1, 0.55), true)))
	var cm2 := CylinderMesh.new()
	cm2.top_radius = 0.5
	cm2.bottom_radius = 0.5
	cm2.height = 0.03
	cm2.radial_segments = 10
	n.add_child(_mesh(cm2, _unshaded(Color(1.0, 0.8, 0.35, 0.7), true)))
	if not g.low_gfx:
		n.add_child(_funken(Color(1.0, 0.55, 0.2), 5, 0.8, Vector3(0, 0.1, 0), 0.6, Vector3(0, 1.5, 0), 0.08))
	g.add_child(n)
	n.global_position = c + Vector3(0, 0.07, 0)
	n.scale = Vector3(0.3, 1, 0.3)
	n.create_tween().tween_property(n, "scale", Vector3.ONE, 0.25)
	return n

static func _fleck_aus(e: Dictionary) -> void:
	var n: Node3D = e.n
	if not is_instance_valid(n):
		return
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector3(0.05, 1, 0.05), 0.4)
	tw.tween_callback(n.queue_free)

# Rufer: violetter Kreis, Hand hoch, dann stehen zwei Diener aus dem eigenen Rudel auf
static func _rufen(f, s: Dictionary) -> void:
	var g = f.game
	var art: String = "wisp" if f.typ == "wisp" else ("skorp" if f.typ == "skorp" else ("fahl" if f.K.get("mat", "") == "stern" else ("guard" if f.K.get("undead", false) else "lance")))
	f.wind = 1.0
	f.act_t = 1.2
	f.set_meta("what", "nichts")
	f.play(Foe.ANIM.summon if f.ap and f.ap.has_animation(Foe.ANIM.summon) else Foe.ANIM.cast, 1.2, 0.1, true)
	g.ring_fx(f.global_position, 2.8, LISTE.ruf.farbe)
	g.sfx.play_at("boss_appear", f.global_position, 0.1, -12.0)
	g.float_text(f.global_position + Vector3(0, 3.0, 0), "ruft Diener", LISTE.ruf.farbe)
	var wo: Vector3 = f.global_position
	f.get_tree().create_timer(1.0, false).timeout.connect(func():
		if not is_instance_valid(f) or f.state == Foe.St.DEAD:
			return
		var vorher: int = g.foes.size()
		g.boss_summon(f, [art, art])
		for i in range(vorher, g.foes.size()):
			var x = g.foes[i]
			x.pack = f.pack
			s.diener.append(x)
		g.ring_fx(wo, 2.8, LISTE.ruf.farbe))

# Ba-Sprung: türkiser Kreis hinter dem Helden, 0,7 s später steht er dort und holt aus
static func _springen(f, h) -> void:
	var g = f.game
	var hinter: Vector3 = h.global_position - h.forward() * 2.2
	if not g.walkable(h.global_position, hinter) or g.astar.is_point_solid(g._sub(hinter)):
		hinter = h.global_position + (f.global_position - h.global_position).normalized().rotated(Vector3.UP, PI * 0.5) * 2.2
		if not g.walkable(h.global_position, hinter):
			return
	g.warn_fx(hinter, 1.0, 0.7)
	g.ring_fx(f.global_position, 1.4, LISTE.sprung.farbe)
	f.wind = 0.8
	f.act_t = 0.9
	f.set_meta("what", "nichts")
	f.play(Foe.ANIM.cast, 1.4, 0.1, true)
	g.sfx.play_at("dash", f.global_position, 0.1, -4.0)
	f.get_tree().create_timer(0.7, false).timeout.connect(func():
		if not is_instance_valid(f) or f.state == Foe.St.DEAD or f.stun > 0.0:
			return
		g.spark(f.global_position + Vector3(0, 1.0, 0), LISTE.sprung.farbe)
		f.global_position = hinter
		f.reset_physics_interpolation()
		g.spark(hinter + Vector3(0, 1.0, 0), LISTE.sprung.farbe)
		g.ring_fx(hinter, 1.6, LISTE.sprung.farbe)
		f.look_to(h.global_position)
		f.model.rotation.y = f.face
		f.atk_t = 0.0
		f.act_t = 0.0
		f.wind = 0.0
		if f.K.ai == "melee" or f.K.ai == "slam":
			f._windup(Foe.ANIM.atk, 1.0, 0.6, "melee"))

# Totenklage: blauer Ring, der wächst; wer vom Rudel darin steht, wird für sechs Sekunden rasend
static func _klagen(f) -> void:
	var g = f.game
	f.wind = 0.9
	f.act_t = 1.0
	f.set_meta("what", "nichts")
	f.play(f.bew("boss/Kratzen", Foe.ANIM.cast), 0.9, 0.1, true)
	g.sfx.play_at("boss_phase" if g.sfx._stream("boss_phase") else "boss_appear", f.global_position, 0.1, -10.0)
	g.float_text(f.global_position + Vector3(0, 3.0, 0), "Totenklage", LISTE.klage.farbe)
	g.ring_fx(f.global_position, 3.0, LISTE.klage.farbe)
	f.get_tree().create_timer(0.8, false).timeout.connect(func():
		if not is_instance_valid(f) or f.state == Foe.St.DEAD:
			return
		g.ring_fx(f.global_position, 10.0, LISTE.klage.farbe)
		for o in g.live_foes():
			if o != f and o.kind != "boss" and o.kind != "objekt" and o.global_position.distance_to(f.global_position) < 10.0:
				o.peitsche_t = 6.0
				g.spark(o.global_position + Vector3(0, 1.6, 0), LISTE.klage.farbe))

# Fessel der Selket: rote Bahn zum Helden, 0,8 s; wer dann noch auf der Bahn steht, wird herangezogen
static func _fesseln(f, h) -> void:
	var g = f.game
	var von: Vector3 = f.global_position
	var dir: Vector3 = f.flat(h.global_position - von).normalized()
	var lang: float = minf(12.0, f.flat(h.global_position - von).length() + 2.0)
	f.look_to(h.global_position)
	f.wind = 0.9
	f.act_t = 1.0
	f.set_meta("what", "nichts")
	f.play(f.bew("boss/Wurf", Foe.ANIM.cast), 1.2, 0.1, true)
	g.stripe_fx(von, dir, lang, 1.4, 0.8)
	g.sfx.play_at("skel_attack", von, 0.1, -2.0)
	f.get_tree().create_timer(0.8, false).timeout.connect(func():
		if not is_instance_valid(f) or f.state == Foe.St.DEAD or h.dead:
			return
		var rel: Vector3 = f.flat(h.global_position - von)
		var laengs := rel.dot(dir)
		var quer := (rel - dir * laengs).length()
		_kettenblitz(g, von + Vector3(0, 1.2, 0), von + dir * lang + Vector3(0, 1.2, 0), LISTE.fessel.farbe)
		if laengs > 0.0 and laengs < lang and quer < 0.7 + h.radius and h.inv <= 0.0:
			# herangezogen: Rückstoß in seine Richtung, dann holt er aus
			h.kb = -dir * minf(22.0, sqrt(2.0 * 40.0 * maxf(0.5, laengs - f.radius - 1.4)))
			h.hurt(f.dmg * 0.4, von + dir * laengs * 2.0, f)
			g.float_text(h.global_position + Vector3(0, 2.4, 0), "gefesselt", LISTE.fessel.farbe)
			f.atk_t = 0.0
			f.get_tree().create_timer(0.35, false).timeout.connect(func():
				if is_instance_valid(f) and f.state != Foe.St.DEAD and (f.K.ai == "melee" or f.K.ai == "slam"):
					f._windup(Foe.ANIM.atk, 1.1, 0.5, "melee"))
		else:
			g.float_text(f.global_position + Vector3(0, 2.8, 0), "verfehlt", Color(0.8, 0.8, 0.8)))

static func _kettenblitz(g, a: Vector3, b: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.07
	cm.bottom_radius = 0.07
	cm.height = a.distance_to(b)
	cm.radial_segments = 5
	mi.mesh = cm
	mi.material_override = _unshaded(Color(col, 0.9), true)
	g.add_child(mi)
	mi.global_position = (a + b) * 0.5
	if a.distance_to(b) > 0.01:
		mi.look_at_from_position(mi.global_position, b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)
		mi.rotate_object_local(Vector3.RIGHT, PI / 2)
	var tw := mi.create_tween()
	tw.tween_property(mi.material_override, "albedo_color:a", 0.0, 0.35)
	tw.tween_callback(mi.queue_free)

# Feuerkette: sucht sich beim Erwachen einen Gefährten aus dem Rudel und macht ihn ebenfalls zum Champion
static func _kette_tick(f, s: Dictionary, delta: float, h) -> void:
	var g = f.game
	var p = s.partner
	if p == null and not s.get("gesucht", false):
		s["gesucht"] = true
		var best = null
		var bd := 9.0
		for o in g.live_foes():
			if o != f and o.kind != "boss" and o.kind != "objekt" and o.pack == f.pack and o.global_position.distance_to(f.global_position) < bd:
				bd = o.global_position.distance_to(f.global_position)
				best = o
		if best == null:
			return
		if best.elite == "":
			best.zum_champion(f.elite, ["kette"])
		best.aff["kette"]["partner"] = f
		best.aff["kette"]["gesucht"] = true
		best.aff["kette"]["haupt"] = false
		s.partner = best
		s["haupt"] = true
		s["an_t"] = 1.0   # die Kette glüht erst auf, bevor sie brennt
		p = best
	if p == null or not s.get("haupt", false):
		return
	if not is_instance_valid(p) or p.state == Foe.St.DEAD or f.state == Foe.St.DEAD:
		_kette_aus(s)
		return
	var a: Vector3 = f.global_position + Vector3(0, 1.0, 0)
	var b: Vector3 = p.global_position + Vector3(0, 1.0, 0)
	var n: MeshInstance3D = s.get("mesh")
	if n == null:
		n = MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.09
		cm.bottom_radius = 0.09
		cm.height = 1.0
		cm.radial_segments = 6
		n.mesh = cm
		n.material_override = _unshaded(Color(1.0, 0.4, 0.12, 0.3), true)
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.add_child(n)
		s["mesh"] = n
	var lang := a.distance_to(b)
	n.global_position = (a + b) * 0.5
	if lang > 0.05:
		n.look_at_from_position(n.global_position, b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)
		n.rotate_object_local(Vector3.RIGHT, PI / 2)
	n.scale = Vector3(1, maxf(0.01, lang), 1)   # nach dem Ausrichten: look_at setzt die Größe zurück
	var an: float = s.get("an_t", 0.0)
	if an > 0.0:
		s.an_t = an - delta
		n.material_override.albedo_color.a = 0.25 + 0.15 * sin(g.clock * 20.0)
		return
	n.material_override.albedo_color = Color(1.0, 0.45 + 0.15 * sin(g.clock * 9.0), 0.12, 0.85)
	# wer die Kette berührt, verbrennt (zu nah an einem der beiden zählt nicht: dort trifft er ohnehin)
	s["brand"] = s.get("brand", 0.0) - delta
	if s.brand <= 0.0 and not h.dead and lang > 1.0:
		var ab: Vector3 = f.flat(b - a)
		var rel: Vector3 = f.flat(h.global_position - a)
		var t := clampf(rel.dot(ab) / maxf(0.01, ab.length_squared()), 0.0, 1.0)
		if (rel - ab * t).length() < 0.55 + h.radius * 0.5 and t > 0.08 and t < 0.92:
			s.brand = 0.5
			h.hurt(f.dmg * 0.35, h.global_position + Vector3(0.01, 0, 0), f)
			g.float_text(h.global_position + Vector3(0, 2.2, 0), "Feuerkette", LISTE.kette.farbe)

static func _kette_aus(s: Dictionary) -> void:
	var n = s.get("mesh")
	if n != null and is_instance_valid(n):
		var tw: Tween = n.create_tween()
		tw.tween_property(n, "scale:x", 0.01, 0.3)
		tw.tween_callback(n.queue_free)
	s["mesh"] = null
	s["haupt"] = false

# Treffer: Schild der Maat hält von vorn fast alles ab, bis er bricht
static func treffer(f, amount: float, from: Vector3) -> float:
	if not f.aff.has("feder"):
		return amount
	var s: Dictionary = f.aff.feder
	if s.bruch_t > 0.0:
		return amount
	var zu: Vector3 = f.flat(from - f.global_position)
	var vorn: Vector3 = Vector3(sin(f.model.rotation.y), 0, cos(f.model.rotation.y)) if f.model else f.forward()
	if zu.length() < 0.05 or vorn.angle_to(zu.normalized()) > 1.15:
		return amount   # von der Seite oder von hinten: voller Schaden
	s.halt -= amount
	f.game.spark(f.global_position + vorn * (f.radius + 0.5) + Vector3(0, 1.2, 0), LISTE.feder.farbe)
	if s.halt <= 0.0:
		s.bruch_t = 9.0
		s.scheibe.visible = false
		s.schwenk.visible = false
		f.game.ring_fx(f.global_position, f.radius + 2.0, LISTE.feder.farbe)
		f.game.sfx.play_at("krug_bricht" if f.game.sfx._stream("krug_bricht") else "hit", f.global_position, 0.05)
		f.game.float_text(f.global_position + Vector3(0, 3.0, 0), "die Feder bricht", LISTE.feder.farbe, 1.3)
		f.stun = maxf(f.stun, 0.8)
		return amount * 0.5
	if randf() < 0.35:
		f.game.float_text(f.global_position + Vector3(0, 2.8, 0), "die Feder hält", LISTE.feder.farbe)
	return amount * 0.15

# Tod: Zweigeteilte zerfallen in zwei, Diener vergehen, Glut erlischt, die Kette reißt, die Laterne wird wieder hell
static func tod(f) -> void:
	if not f.has_meta("aff_bereit"):
		return
	var g = f.game
	for id in f.affixe:
		var s: Dictionary = f.aff[id]
		match id:
			"glut":
				for e in s.flecken:
					_fleck_aus(e)
				s.flecken = []
			"sturm":
				if s.get("drin", false):
					s.drin = false
					_laterne(g, false)
			"ruf":
				for x in s.diener:
					if is_instance_valid(x) and x.state != Foe.St.DEAD:
						x.die()
				s.diener = []
			"kette":
				_kette_aus(s)
				var p = s.get("partner")
				if p != null and is_instance_valid(p) and p.aff.has("kette"):
					_kette_aus(p.aff.kette)
			"spalt":
				if not f.summoned and not f.get_meta("gespalten", false):
					var art: String = f.kind
					var wo: Vector3 = f.global_position
					f.get_tree().create_timer(0.5, false).timeout.connect(func():
						for i in 2:
							var a := TAU * i / 2.0 + randf()
							var p2: Vector3 = wo + Vector3(sin(a), 0, cos(a)) * 1.4
							if not g.walkable(wo, p2):
								p2 = wo
							var k = g._spawn(art, p2, f.pack, "", g.hdef)
							k.set_meta("gespalten", true)
							k.max_hp *= 0.45
							k.hp = k.max_hp
							k.xp *= 0.5
							k.state = Foe.St.FIGHT
							k.lying = false
							k.set_collision_layer_value(3, true)
							if k.model:
								k.model.scale *= 0.82
							if not k.proc:
								k.glut(1.4, LISTE.spalt.farbe)
							g.spark(p2 + Vector3(0, 1.0, 0), LISTE.spalt.farbe)
						g.ring_fx(wo, 2.4, LISTE.spalt.farbe)
						g.float_text(wo + Vector3(0, 2.6, 0), "zweigeteilt", LISTE.spalt.farbe, 1.3))

# Ende eines Champions: Zerfall in Sand und Funken in seiner Farbe, darüber eine goldene Fontäne
static func zerfall(f) -> void:
	var g = f.game
	var col := farbe(f)
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 14 if g.low_gfx else 36
	p.lifetime = 1.4
	p.explosiveness = 0.85
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.6
	p.direction = Vector3(0, 1, 0)
	p.spread = 25.0
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 8.0
	p.gravity = Vector3(0, -9.0, 0)
	var q := SphereMesh.new()
	q.radius = 0.07
	q.height = 0.14
	q.radial_segments = 6
	q.rings = 3
	q.material = _unshaded(Color(1.0, 0.85, 0.4))
	p.mesh = q
	g.add_child(p)
	p.global_position = f.global_position + Vector3(0, 1.0, 0)
	var sand := _funken(col, 24 if not g.low_gfx else 10, 1.2, Vector3.ZERO, 0.8, Vector3(0, -1.0, 0), 0.14)
	sand.one_shot = true
	sand.explosiveness = 0.9
	sand.initial_velocity_min = 1.0
	sand.initial_velocity_max = 3.0
	g.add_child(sand)
	sand.global_position = f.global_position + Vector3(0, 1.2, 0)
	sand.emitting = true
	g.ring_fx(f.global_position, 3.4, col)
	g.ring_fx(f.global_position, 2.0, Color(1.0, 0.85, 0.4))
	g.shake = maxf(g.shake, 0.3)
	g.sfx.play_at("boss_stern" if g.sfx._stream("boss_stern") else "hit", f.global_position, 0.1, -6.0)
	f.get_tree().create_timer(2.0).timeout.connect(func():
		p.queue_free()
		sand.queue_free())
