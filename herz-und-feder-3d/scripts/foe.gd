class_name Foe extends Actor
# Die Gegner der Duat (01-data.js › ET, 05-update.js › Gegner-KI, bossAI, idleFoe). Neun Arten mit vier Kampfweisen:
# swarm (läuft an und beißt), melee (holt sichtbar aus), ranged (hält Abstand und schießt), slam (Aufschlag mit Ansage),
# dazu die Hüter der Stunden. In Ruhe stehen, lagern, wachen, streifen oder lauern sie, bis sie den Helden bemerken.
# Aussehen: KayKit-Skelette, eingefärbt; Irrende Ba (Lichter) und Tefens Brut (Skorpione) sind selbst gebaut.
# Entfernungen der 2D-Fassung sind durch Daten.PX geteilt, Geschwindigkeiten im Verhältnis zum Helden umgerechnet.

const SPD := 6.4 / 205.0   # Weltpixel/s → m/s, im Verhältnis zum Lauftempo des Helden

const ANIM := {
	"sleep": "Skeletons_Inactive_Floor_Pose", "wake": "Skeletons_Awaken_Floor", "idle": "Idle_Combat", "walk": "Walking_D_Skeletons",
	"run": "Running_A", "atk": "1H_Melee_Attack_Chop", "atk_big": "2H_Melee_Attack_Chop", "cast": "Spellcast_Shoot",
	"hit": "Hit_A", "death": "Death_C_Skeletons", "stand": "Skeleton_Inactive_Standing_Pose", "rise": "Skeletons_Awaken_Standing",
	"slam": "2H_Melee_Attack_Spin", "summon": "Spellcast_Summon",
}

# Gegnerarten: Werte aus ET (Daten.ET), dazu Kampfweise, Aussehen und Material
const KINDS := {
	"wisp": {"ai": "swarm", "atk": 0.9, "spd": 135.0, "r": 10.0, "look": "wisp", "neu": "Ba", "neu_scale": 0.85, "col": Color("8fe3e0"), "mat": ""},
	"skorp": {"ai": "swarm", "atk": 1.1, "spd": 116.0, "r": 12.0, "look": "skorp", "neu": "Skorpion", "neu_scale": 0.8, "col": Color("b98a4a"), "mat": "", "animal": true},
	"lance": {"ai": "melee", "atk": 1.9, "spd": 92.0, "r": 14.0, "neu": "Krieger", "mat": "leder"},
	"seer": {"ai": "ranged", "atk": 2.3, "spd": 84.0, "r": 13.0, "range": 340.0, "neu": "Priesterin", "shot": Color("9be06b"), "mat": "leder"},
	"haut": {"ai": "slam", "atk": 3.0, "spd": 62.0, "r": 26.0, "neu": "Koloss", "scale": 1.3, "mat": "leder"},
	"guard": {"ai": "melee", "atk": 2.1, "spd": 74.0, "r": 15.0, "neu": "Ruheloser", "mat": "eisen", "undead": true, "lies": true},
	"fahl": {"ai": "ranged", "atk": 2.1, "spd": 88.0, "r": 13.0, "range": 360.0, "neu": "Erloschener", "neu_tint": Color(0.8, 0.95, 1.25), "shot": Color("e06bd0"), "mat": "stern"},
	"hohl": {"ai": "melee", "atk": 1.6, "spd": 112.0, "r": 15.0, "neu": "Hohler", "neu_scale": 0.94, "neu_glow": Color(0.6, 0.8, 1.0), "mat": "eisen", "demon": true, "undead": true, "glow": Color(0.95, 0.35, 0.2)},
}
# Gestalten der Hüter (ACT[…].boss.look)
const BOSS_LOOK := {
	"wisp": {"look": "wisp", "neu": "Ba", "neu_scale": 1.05, "neu_tint": Color(1.15, 1.1, 0.9), "mat": ""},
	"mutter": {"neu": "Koloss", "neu_tint": Color(1.1, 0.9, 0.62), "neu_scale": 0.72, "mat": "leder"},
	"koenig": {"neu": "Krieger", "neu_tint": Color(1.35, 1.1, 0.6), "neu_scale": 0.78, "mat": "eisen", "undead": true},
	"grey": {"neu": "Koloss", "neu_tint": Color(0.72, 0.8, 0.95), "neu_scale": 0.72, "mat": "stern"},
	# Agent A (Gegnerfabrik, 4.1): die Schlange; kämpft nach dem Muster der Mutter der Häute (eine Schlange häutet sich)
	"apophis": {"neu": "Apophis", "neu_tint": Color(1.0, 0.92, 0.75), "neu_scale": 1.0, "mat": "leder"},
	"sammler": {"neu": "Erloschener", "neu_tint": Color(1.05, 0.7, 1.4), "neu_scale": 0.8, "mat": "stern"},
}

enum St { SLEEP, WAKING, FIGHT, DEAD }

var kind := "wisp"     # Gegnerart (Daten.ET) oder „boss“
var typ := "wisp"
var K: Dictionary      # Kampfweise und Aussehen
var neu3d := false   # Figur stammt aus der Figurenfabrik
var state := St.SLEEP
var pack := 0
var wake_t := 0.0
var atk_t := 0.0       # Abklingzeit bis zum nächsten Angriff
var wind := 0.0        # Ausholen: läuft ab, dann fällt der Hieb
var act_t := 0.0       # Rest der Angriffsbewegung
var slot := true       # darf gerade angreifen (Angriffsplätze je Schwierigkeit)
var ring_i := 0        # Platz im Ring der Wartenden
var path: PackedVector3Array = []
var path_t := 0.0
var strafe := 1.0
var glow: OmniLight3D
var home := Vector3.ZERO
var home_face := 0.0
# Werte nach den Formeln der 2D-Fassung (03-world.js › spawn): Gegnerart, Stunde und Schwierigkeit
var dmg := 10.0
var spd := 4.0
var xp := 10.0
var w := 1.0
var elite := ""        # "", "flink", "zaeh" oder "wild"
var disp_name := ""
var slow_t := 0.0      # Seschats Maß: kriechen mit 40 % Tempo
var mark_t := 0.0      # Gebs Lachen: zerbirst beim Tod
var fear_t := 0.0      # Upuauts Hatz: Tiere fliehen
# Ruhe und Wahrnehmung (05-update.js › idleFoe)
var style := "ruhe"    # ruhe, lager, wache, streife, hinterhalt, reigen
var reigen_c := Vector3.ZERO   # Reigen (2.9): Mitte, um die der Schwarm der Irrlichter kreist
var reigen_i := 0
var reigen_n := 1
var hidden := false    # Hinterhalt: unsichtbar, bis der Held nah ist
var way: Array = []    # Streife: Wegpunkte
var way_i := 0
var idle_t := 0.0
var lead: Foe          # Streife: dem Anführer folgen
var alert := 0.0
var alarm := -1.0      # Nachbarrudel ruft: erwacht, wenn abgelaufen
var mark3d: Label3D    # „?“ oder „!“ über dem Kopf
var elite_teile: Array = []   # Ring und Namensschild eines Champions: verschwinden mit ihm
var mark_show := 0.0
var lying := false     # Ruhelose liegen am Boden und stehen auf
var proc: Node3D       # selbst gebautes Aussehen (Lichter, Skorpione)
var sc := 1.0
# Hüter
var boss_t := [2.0, 6.0, 4.0]   # Geschossring, Beschwörung, Ansturm
var charge_t := 0.0
var charge_dir := Vector3.ZERO
var charge_hit := false
var summoned := false   # vom Hüter beschworen: keine Erfahrung, kein Fortschritt
const HAERTER := 1.25    # 4.0: Leben und Schaden aller Gegner auf jeder Schwierigkeit
const AKT_LEBEN := 2.2   # der Endgegner eines Aktes hält so viel mehr aus als ein Hüter
const AKT_SCHADEN := 1.7 # und trifft so viel härter
# klügere Gegner (4.0): Nahkämpfer kreisen ein, statt hintereinander anzulaufen; mit wenig Leben weichen sie einmal zurück
var rueckzug_t := 0.0
var rueckzug_war := false
var ruhe_seit := 0.0     # Eigenheit des zweiten Aktes: wer eine Weile nicht getroffen wurde, heilt sich
# Der Stumme Türhüter (4.0): Endgegner von Akt 1, drei Phasen
var aktende := -1        # -1 noch nicht geprüft, 0 gewöhnlicher Hüter, 1 Endgegner des Aktes
var phase := 1
var schild_t := 0.0      # unverwundbar, solange er ruft oder das Tor zerbricht
var kampf_t := 0.0       # wie lange der Kampf schon dauert: nach drei Minuten packt ihn die Wut
var stampf_t := 4.0
var stern_t := 3.0
var welle_t := 0.0
var schild_vis: MeshInstance3D
var hour: Dictionary
# 4.1: Champions mit Eigenschaften (affixe.gd), Hüter mit eigenem Kampfmuster (hueter.gd), Dinge im Kampf (Kartuschen, Krüge)
var affixe: Array = []   # Eigenschaften eines Champions, z. B. ["glut", "feder"]
var aff := {}            # Zustand je Eigenschaft
var peitsche_t := 0.0    # von einer Totenklage aufgepeitscht: schneller und angriffslustiger
var huelle_t := 0.0      # abgestreifte Haut der Mutter: liegt still, bis sie aufsteht
var kampf: Hueter        # Kampfmuster des Hüters (null beim Türhüter und bei gewöhnlichen Gegnern)
var rolle := ""          # Ding im Hüterkampf: "kartusche", "krug", "trugbild"
var besitzer: Hueter     # wem das Ding gehört
var tritt_t := 0.0

func init(k: String, pos: Vector3, p: int, el := "", hdef := {}) -> void:
	kind = k
	pack = p
	elite = el
	hour = hdef
	var D: Dictionary = Spiel.D()
	var F := Spiel.fall
	var r_px := 15.0
	if k == "boss":
		typ = "boss"
		var B: Dictionary = hdef.get("boss", {"look": "grey", "r": 38, "hp": 1.0, "name": "Hüter"})
		K = BOSS_LOOK.get(B.look, BOSS_LOOK.grey).duplicate()
		K["ai"] = "boss"
		K["name"] = B.name
		K["bcol"] = Color(B.get("col", "#b06be0"))
		r_px = float(B.r)
		sc = r_px / 22.0
	else:
		typ = k
		K = KINDS[k].duplicate()
		K["name"] = Daten.ET[k].name
		r_px = K.r
		sc = K.get("scale", 1.0)
	K["typ"] = typ
	a_idle = ANIM.idle
	a_walk = ANIM.walk
	a_run = ANIM.run
	var T: Dictionary = Daten.ET[typ]
	# 4.0 (A4): auf jeder Stufe um ein Viertel schwerer, auch auf „Normal“
	max_hp = T.hp * 1.55 * pow(1.28, F - 1) * D.hp * HAERTER * (float(hdef.boss.hp) if k == "boss" and hdef.has("boss") else 1.0)
	dmg = T.dmg * 1.25 * pow(1.2, F - 1) * D.dmg * HAERTER
	xp = T.xp * pow(1.22, F - 1) * D.xp
	w = T.w
	spd = (58.0 if k == "boss" else float(K.spd)) * SPD * D.spd
	if Stunden.akt(Spiel.fall) == 2 and k != "boss":
		spd *= 1.12   # Eigenheit des dritten Aktes: Eile
	disp_name = K.name
	var r := r_px / Daten.PX
	if elite != "":
		max_hp *= 3.4 * (1.7 if elite == "zaeh" else 1.0)
		dmg *= 1.35 * (1.4 if elite == "wild" else 1.0)
		spd *= 1.5 if elite == "flink" else 1.0
		xp *= 4.0
		w *= 3.0
		sc *= 1.35   # 4.1: deutlich größer als das Rudel (vorher 1,25)
		r *= 1.25
		affixe = Affixe.wuerfeln(Spiel.fall, Spiel.diff, k)
		disp_name = "%s, %s" % [K.name, Affixe.LISTE[affixe[0]].titel] if not affixe.is_empty() else K.name
	if K.has("neu"):
		# Figur aus der Figurenfabrik: eigene Haut, eigene Waffe; Varianten (Hüter, Erloschene) über Größe und Tönung
		setup("res://models/chars/%s.glb" % K.neu, sc * K.get("neu_scale", 1.0), r)
		neu3d = true
		if k == "boss" or elite != "":
			# Hüter und Champions bekommen eigene Bewegungen (Agent D, bewegungen.gd): Wuchthieb, Schildbruch, Wurf …
			Bewegungen.ergaenzen(ap, skel, "boss")
			Bewegungen.ergaenzen(ap, skel, "gemeinsam")
		if K.has("neu_tint"):
			_tint(K.neu_tint)
	else:
		_build_proc(K.look, r, K.get("bcol", K.get("col", Color.WHITE)) if k == "boss" else K.col)
	collision_layer = 4
	collision_mask = 1 | 2 | 4 | 32
	hp = max_hp
	position = pos
	home = pos
	face = randf() * TAU
	if model:
		model.rotation.y = face
	strafe = 1.0 if randf() < 0.5 else -1.0
	if K.has("glow") or (k == "boss" and K.has("bcol")):
		glow = OmniLight3D.new()
		glow.light_color = K.neu_glow if neu3d and K.has("neu_glow") else K.get("glow", K.get("bcol", Color.WHITE))
		glow.light_energy = 1.4 if k == "boss" else 0.7
		glow.omni_range = 9.0 if k == "boss" else 3.0
		glow.position = Vector3(0, 2.2 * sc, 0)
		add_child(glow)
	if elite != "":
		_elite_mark(sc)
	mark3d = Label3D.new()
	mark3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mark3d.font_size = 72
	mark3d.outline_size = 14
	mark3d.pixel_size = 0.01
	mark3d.position.y = 2.6 * sc + (0.4 if elite != "" else 0.0)
	mark3d.visible = false
	add_child(mark3d)
	if typ == "wisp":
		_spur(sc)
	_rest_pose(true)
	if k == "boss":
		kampf = Hueter.fuer(self)
		if kampf:
			kampf.gestalt()

# Irrlichter ziehen eine feine Spur aus Licht hinter sich her (wenige Teilchen, im Browser billig)
func _spur(s: float) -> void:
	var p := CPUParticles3D.new()
	p.amount = 14
	p.lifetime = 1.1
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.18 * s
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.initial_velocity_min = 0.02
	p.initial_velocity_max = 0.12
	p.gravity = Vector3(0, 0.25, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var kurve := Curve.new()
	kurve.add_point(Vector2(0, 1.0))
	kurve.add_point(Vector2(1, 0.0))
	p.scale_amount_curve = kurve
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(0.55, 0.95, 0.85, 0.55)
	q.material = m
	p.mesh = q
	p.position = Vector3(0, 1.05 * s, 0.1 * s)
	add_child(p)
	set_meta("spur", p)

# Reigen: Die Irrlichter tanzen auf einer ovalen Bahn, der Form einer Kartusche, als kreisten sie um einen Namen,
# der nicht mehr da ist. Sie greifen erst an, wenn man ihren Reigen durchbricht oder einen von ihnen trifft.
func _reigen(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	var a := t * 0.55 + TAU * float(reigen_i) / float(maxi(1, reigen_n)) + sin(t * 0.9 + reigen_i) * 0.25
	var lok := Vector3(cos(a) * 1.9, 0, sin(a) * 3.3)   # hochkant wie eine Kartusche
	var ziel := reigen_c + lok.rotated(Vector3.UP, home_face)
	var dir := flat(ziel - global_position)
	if dir.length() > 0.15:
		var tempo := spd * clampf(dir.length() * 0.35, 0.15, 0.55)
		_go(dir.normalized(), tempo, delta)
		fortbewegen(tempo, 0.7, ANIM.walk)
	else:
		play(ANIM.idle)

# Ruhelose (und Hüter mit Skelett) in Ruhe: liegen oder stehen still; alle anderen stehen bereit
func _rest_pose(first := false) -> void:
	lying = K.get("lies", false) and (style == "ruhe" or style == "hinterhalt" or style == "lager") and kind != "boss"
	if proc:
		return
	if kind == "boss":
		play(ANIM.stand, 1.0, 0.0 if first else 0.2, true)
	elif lying:
		play(ANIM.sleep, 1.0, 0.0 if first else 0.2, true)
		set_collision_layer_value(3, false)   # liegend steht er niemandem im Weg
	else:
		play(ANIM.idle, 1.0, 0.0 if first else 0.2)

func set_style(s: String, wpts: Array) -> void:
	style = s
	way = wpts
	hidden = s == "hinterhalt"
	visible = not hidden
	_rest_pose()

func _tint(c: Color) -> void:
	for mi in meshes:
		var m: MeshInstance3D = mi
		if m.mesh == null:
			continue
		for i in m.mesh.get_surface_count():
			var mat = m.get_active_material(i)
			if mat is StandardMaterial3D:
				var d: StandardMaterial3D = mat.duplicate()
				d.albedo_color = d.albedo_color * c
				m.set_surface_override_material(i, d)

# Selbst gebaut: Irrender Ba (Licht mit Schweif) und Tefens Brut (Skorpion)
func _build_proc(look: String, r: float, col: Color) -> void:
	radius = r
	proc = Node3D.new()
	add_child(proc)
	model = proc
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	if look == "wisp":
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var core := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = r * 0.9
		sm.height = r * 1.8
		sm.radial_segments = 12
		sm.rings = 6
		core.mesh = sm
		core.material_override = mat
		core.position.y = 1.3 + r
		proc.add_child(core)
		var halo := MeshInstance3D.new()
		var hm := SphereMesh.new()
		hm.radius = r * 1.6
		hm.height = r * 3.2
		hm.radial_segments = 12
		hm.rings = 6
		halo.mesh = hm
		var hmat := StandardMaterial3D.new()
		hmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		hmat.albedo_color = Color(col, 0.22)
		halo.material_override = hmat
		halo.position = core.position
		proc.add_child(halo)
		for i in 3:
			var tail := MeshInstance3D.new()
			var tm := SphereMesh.new()
			tm.radius = r * (0.55 - i * 0.14)
			tm.height = tm.radius * 2.0
			tm.radial_segments = 8
			tm.rings = 4
			tail.mesh = tm
			tail.material_override = hmat
			tail.position = core.position + Vector3(0, -0.1 * i, -(i + 1) * r * 0.9)
			proc.add_child(tail)
		meshes.append(core)
	else:
		# Skorpion: Leib, Schwanz in Bögen, zwei Scheren, sechs Beine
		mat.roughness = 0.7
		var body := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = r * 0.55
		cm.height = r * 2.4
		body.mesh = cm
		body.material_override = mat
		body.rotation.x = PI / 2
		body.position.y = r * 0.6
		proc.add_child(body)
		meshes.append(body)
		var dark := mat.duplicate()
		dark.albedo_color = col.darkened(0.35)
		for i in 4:
			var seg := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = r * (0.36 - i * 0.04)
			sm.height = sm.radius * 2.0
			sm.radial_segments = 8
			sm.rings = 4
			seg.mesh = sm
			seg.material_override = dark if i == 3 else mat
			var a := 0.5 + i * 0.55
			seg.position = Vector3(0, r * 0.6 + sin(a) * r * 1.3, -r * 1.1 - (1.0 - cos(a)) * r * 0.2 + cos(a) * -r * 0.6)
			proc.add_child(seg)
			meshes.append(seg)
		for s in [-1, 1]:
			var claw := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(r * 0.35, r * 0.25, r * 0.8)
			claw.mesh = bm
			claw.material_override = dark
			claw.position = Vector3(s * r * 0.55, r * 0.5, r * 1.35)
			claw.rotation.y = s * -0.35
			proc.add_child(claw)
			meshes.append(claw)
			for j in 3:
				var leg := MeshInstance3D.new()
				var lm := BoxMesh.new()
				lm.size = Vector3(r * 0.9, r * 0.1, r * 0.1)
				leg.mesh = lm
				leg.material_override = dark
				leg.position = Vector3(s * r * 0.7, r * 0.3, (j - 1) * r * 0.55)
				leg.rotation.z = s * 0.5
				proc.add_child(leg)
	var col_shape := CollisionShape3D.new()
	var sh := CapsuleShape3D.new()
	sh.radius = r
	sh.height = maxf(2.0 * r, 1.2)
	col_shape.shape = sh
	col_shape.position.y = sh.height / 2.0
	add_child(col_shape)
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	if flash_mat == null:
		flash_mat = StandardMaterial3D.new()
		flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		# Treffer blitzen auf, ohne die Figur weiß zu übermalen (3.0): Licht wird aufaddiert, die Textur bleibt sichtbar
		flash_mat.albedo_color = Color(1.0, 0.82, 0.55, 0.42)
		flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		flash_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD

# Champion (4.1): Name über dem Kopf in der Farbe seiner ersten Eigenschaft; Aura, Krone, Glut und alles Weitere
# legt affixe.gd an (dort steht auch, was jede Eigenschaft tut)
func _elite_mark(s: float) -> void:
	var l := Label3D.new()
	l.text = disp_name
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 44
	l.outline_size = 10
	l.modulate = Affixe.farbe(self).lerp(Color(0.95, 0.82, 0.29), 0.35) if not affixe.is_empty() else Color(0.95, 0.82, 0.29)
	l.position.y = 3.1 * s if proc == null else 2.6
	l.pixel_size = 0.006
	add_child(l)
	elite_teile.append(l)
	Affixe.anlegen(self, affixe)

# eigene Bewegung, wenn die Figur sie hat (bewegungen.gd), sonst die gewöhnliche
func bew(name: String, ersatz: String) -> String:
	return name if ap and ap.has_animation(name) else ersatz

# Ein gewöhnlicher Gegner wird Champion (Feuerkette: der Gefährte des ersten), für Prüfungen auch mit festen Eigenschaften
func zum_champion(el: String, ids: Array) -> void:
	for n in elite_teile:
		if is_instance_valid(n):
			n.queue_free()
	elite_teile.clear()
	if elite == "":
		elite = el if el != "" else "zaeh"
		max_hp *= 3.4
		hp = max_hp
		dmg *= 1.35
		xp *= 4.0
		if model:
			model.scale *= 1.35
	affixe = ids.duplicate()
	disp_name = "%s, %s" % [K.name, Affixe.LISTE[affixe[0]].titel] if not affixe.is_empty() else K.name
	if neu3d:
		Bewegungen.ergaenzen(ap, skel, "boss")
		Bewegungen.ergaenzen(ap, skel, "gemeinsam")
	_elite_mark(sc * 1.35)

# Glut in den Rissen der Figur (die Figuren der Figurenfabrik bringen eine Leuchtkarte mit): Champions und Hüter
# glühen in ihrer Farbe, die Mutter der Häute mit jeder Haut stärker
func glut(energie: float, farbe: Color) -> void:
	for mi in meshes:
		var m: MeshInstance3D = mi
		if m.mesh == null:
			continue
		for i in m.mesh.get_surface_count():
			var mat = m.get_surface_override_material(i)
			if mat == null:
				var src = m.get_active_material(i)
				if not (src is StandardMaterial3D):
					continue
				mat = src.duplicate()
				m.set_surface_override_material(i, mat)
			if mat is StandardMaterial3D:
				var d: StandardMaterial3D = mat
				d.emission_enabled = true
				d.emission = farbe
				d.emission_energy_multiplier = energie

# Abgestreifte Haut der Mutter: blass, still, nimmt dreifachen Schaden; steht nach ein paar Sekunden auf
func zur_huelle(sek: float) -> void:
	huelle_t = sek
	_tint(Color(1.7, 1.55, 1.2))
	glut(0.0, Color.BLACK)
	play(ANIM.stand if ap and ap.has_animation(ANIM.stand) else ANIM.idle, 1.0, 0.0, true)
	if ap:
		ap.speed_scale = 0.0
	stun = 0.0
	_show_mark("Hülle", Color(0.95, 0.85, 0.6), sek)

func _huelle_auf() -> void:
	for mi in meshes:
		var m: MeshInstance3D = mi
		if m.mesh:
			for i in m.mesh.get_surface_count():
				m.set_surface_override_material(i, null)
	glut(1.2, Color(1.0, 0.35, 0.2))
	if ap:
		ap.speed_scale = 1.0
	play(bew("gemeinsam/Aufstehen", ANIM.rise), 1.3, 0.1, true)
	act_t = 0.8
	game.ring_fx(global_position, 2.4, Color(0.9, 0.6, 0.35))
	game.float_text(global_position + Vector3(0, 3.0, 0), "die Haut steht auf", Color(0.95, 0.7, 0.45))
	game.sfx.play_at("skel_wake", global_position, 0.1)

# Ding im Hüterkampf (Kartusche, Krug, Trugbild): kein Gegner mit eigenem Willen, aber man kann es treffen.
# Es gehört einem Kampfmuster (besitzer), das Bild und Verhalten bestimmt.
func init_objekt(r: String, pos: Vector3, leben: float, rad: float, bild: Node3D, name_: String, wem: Hueter, fest := true) -> void:
	kind = "objekt"
	typ = "wisp"
	rolle = r
	besitzer = wem
	K = {"ai": "objekt", "typ": "wisp", "name": name_, "mat": "", "col": Color.WHITE}
	dmg = 0.0
	xp = 0.0
	w = 0.0
	spd = 0.0
	summoned = true
	pack = 98
	if bild == null:
		_build_proc("wisp", rad, wem.f.K.get("bcol", Color(0.56, 0.89, 0.88)))
	else:
		_objekt_bild(bild, rad)
	collision_mask = 0
	collision_layer = 4 if fest else 0
	set_meta("fest", fest)
	mark3d = Label3D.new()
	mark3d.visible = false
	add_child(mark3d)
	position = pos
	objekt_neu(pos, leben, null)

func _objekt_bild(bild: Node3D, rad: float) -> void:
	radius = rad
	proc = bild
	add_child(proc)
	model = proc
	meshes.clear()
	_collect(proc)
	meshes = meshes.filter(func(m): return not m.top_level)
	if not has_meta("form"):
		var col_shape := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = rad
		sh.height = 2.0
		col_shape.shape = sh
		col_shape.position.y = 1.0
		add_child(col_shape)
		set_meta("form", true)
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	if flash_mat == null:
		flash_mat = StandardMaterial3D.new()
		flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		flash_mat.albedo_color = Color(1.0, 0.82, 0.55, 0.42)
		flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		flash_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD

# wiederverwenden: an neuem Ort, mit neuem Leben (und neuem Bild, wenn eines kommt)
func objekt_neu(pos: Vector3, leben: float, bild: Node3D) -> void:
	if bild != null:
		if proc:
			proc.queue_free()
		_objekt_bild(bild, radius)
	max_hp = leben
	hp = leben
	state = St.FIGHT
	dead = false
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	collision_layer = 4 if get_meta("fest", true) else 0
	if is_inside_tree():
		global_position = pos
	else:
		position = pos
	home = pos
	if proc:
		proc.scale = Vector3.ONE
		proc.visible = true

func _show_mark(t: String, col: Color, secs: float) -> void:
	mark3d.text = t
	mark3d.modulate = col
	mark3d.visible = true
	mark_show = secs

# Nach einer Niederlage des Helden: zurück an den Ursprung, wieder in Ruhe; erlittener Schaden bleibt (wie im Original)
func sleep_again() -> void:
	if state == St.DEAD:
		return
	state = St.SLEEP
	global_position = home
	face = home_face
	stun = 0.0
	wind = 0.0
	act_t = 0.0
	charge_t = 0.0
	alert = 0.0
	alarm = -1.0
	kb = Vector3.ZERO
	path = PackedVector3Array()
	visible = true
	boss_t = [2.0, 6.0, 4.0]
	peitsche_t = 0.0
	if not affixe.is_empty():
		Affixe.ruhe(self)
	_rest_pose()

func wake(delay := 0.0) -> void:
	if state != St.SLEEP:
		return
	state = St.WAKING
	wake_t = -delay
	if hidden:
		hidden = false
		visible = true
		stun = maxf(stun, 0.45)
		game.spark(global_position + Vector3(0, 0.4, 0), Color(0.7, 0.62, 0.5))
	_show_mark("!", Color(1.0, 0.45, 0.35), 0.8)
	if not affixe.is_empty():
		Affixe.auftritt(self)

# hat die Figur eine Bewegung zum Aufstehen? (Skelette ja, Lichter, Skorpione und der Ba nicht)
func _steht_auf() -> bool:
	return proc == null and ap != null and ap.has_animation(ANIM.rise)

func _physics_process(delta: float) -> void:
	var _u := Time.get_ticks_usec()
	_physics_process_innen(delta)
	Protokoll.zeit("gegner", _u)

func _physics_process_innen(delta: float) -> void:
	tick_common(delta)
	if kind == "objekt":
		if state != St.DEAD and besitzer:
			besitzer.objekt_tick(self, delta)
		return
	if schild_t > 0.0:
		# der Schild des Türhüters läuft ab, gleich was er gerade tut (auch betäubt oder im Ansturm)
		schild_t -= delta
		if schild_t <= 0.0 and schild_vis:
			schild_vis.visible = false
	slow_t -= delta
	mark_t -= delta
	fear_t -= delta
	if mark_show > 0.0:
		mark_show -= delta
		if mark_show <= 0.0:
			mark3d.visible = false
	if proc:
		_proc_anim(delta)
	var h: Hero = game.hero
	match state:
		St.DEAD:
			return
		St.SLEEP:
			_idle(delta, h)
			return
		St.WAKING:
			wake_t += delta
			if wake_t < 0.0:
				look_to(h.global_position)
				turn(delta, 8.0)
				return
			if lying:
				if cur_anim != ANIM.wake:
					play(ANIM.wake, 1.5, 0.1, true)
					game.sfx.play_at("skel_wake", global_position)
					set_collision_layer_value(3, true)
				if wake_t < anim_len(ANIM.wake) / 1.5 * 0.92:
					return
				lying = false
			elif kind == "boss" and _steht_auf() and cur_anim != ANIM.rise:
				play(ANIM.rise, 1.0, 0.1, true)
				game.on_boss_wake(self)
				return
			elif kind == "boss" and not _steht_auf() and wake_t < 0.2:
				# 4.1: auch Figuren ohne Aufsteh-Bewegung (Mahaf als Ba) erwachen; vorher blieben sie im Erwachen hängen
				# und riefen jedes Bild die Ankündigung neu aus
				game.on_boss_wake(self)
				wake_t = 0.2
			if kind == "boss" and _steht_auf() and wake_t < anim_len(ANIM.rise) * 0.9:
				return
			state = St.FIGHT
			atk_t = randf_range(0.2, 0.9)
			return
	# ---- Kampf ----
	if huelle_t > 0.0:
		# abgestreifte Haut: liegt still, bis sie aufsteht
		huelle_t -= delta
		velocity = kb
		move_and_slide()
		global_position.y = 0.0
		if huelle_t <= 0.0:
			_huelle_auf()
		return
	peitsche_t -= delta
	atk_t -= delta * (1.6 if peitsche_t > 0.0 else 1.0)
	act_t -= delta
	var to := flat(h.global_position - global_position)
	var d := to.length()
	var dirn := to / maxf(d, 0.001)
	var move := Vector3.ZERO
	var speed: float = spd * (0.4 if slow_t > 0.0 else 1.0) * (1.35 if peitsche_t > 0.0 else 1.0)
	if not affixe.is_empty():
		Affixe.tick(self, delta, h)
	if kampf:
		# das Kampfmuster läuft weiter, auch wenn der Hüter kurz taumelt oder anstürmt (Ansagen bleiben verlässlich)
		kampf.tick(delta, h, d, dirn, stun > 0.0 or charge_t > 0.0)
	# mit wenig Leben einmal zurückweichen, kurz Luft holen, dann wieder heran (nicht Schwärme und Hüter)
	if not rueckzug_war and kind != "boss" and K.ai != "swarm" and hp < max_hp * 0.25 and hp > 0.0 and not summoned:
		rueckzug_war = true
		rueckzug_t = 1.4
	if rueckzug_t > 0.0 and stun <= 0.0:
		rueckzug_t -= delta
		_go(-dirn, spd * 1.05, delta)
		fortbewegen(spd * 1.05)
		return
	# Eigenheit des zweiten Aktes: Zähigkeit. Wer vier Sekunden nicht getroffen wurde, heilt 2 % je Sekunde.
	ruhe_seit += delta
	if Stunden.akt(Spiel.fall) == 1 and ruhe_seit > 4.0 and hp < max_hp and kind != "boss":
		hp = minf(max_hp, hp + max_hp * 0.02 * delta)
	if fear_t > 0.0 and stun <= 0.0 and kind != "boss":
		_go(-dirn, spd * 1.15, delta)
		fortbewegen(spd * 1.15)
		return
	if stun > 0.0:
		wind = 0.0
		velocity = kb
		move_and_slide()
		global_position.y = 0.0
		play(ANIM.hit, 0.6)
		return
	if charge_t > 0.0:
		_charge(delta, h)
		return
	if wind > 0.0:
		wind -= delta
		if wind <= 0.0:
			_strike(h, d)
	elif act_t <= 0.0 and not h.dead:
		match K.ai:
			"swarm":
				# läuft mit Schlängeln an und beißt bei Berührung
				if d < radius + h.radius + 0.5 and atk_t <= 0.0:
					atk_t = K.atk
					h.hurt(dmg, global_position, self)
					act_t = 0.25
					game.sfx.play_at("skorpion" if typ == "skorp" else "irrlicht", global_position, 0.2)
				elif not slot and d < 7.0:
					move = _wait_ring(dirn, d, h)
					speed *= 0.6
				else:
					var wig := sin(Time.get_ticks_msec() * 0.006 + strafe * 3.0) * 0.5
					move = _toward(h.global_position, dirn, delta).rotated(Vector3.UP, wig)
			"melee", "slam":
				var reach: float = radius + h.radius + 0.64
				if K.ai == "slam" and d < 3.84 + h.radius and atk_t <= 0.0 and slot:
					_windup(ANIM.slam, 1.0, 0.8, "slam")
				elif K.ai == "melee" and d < reach and atk_t <= 0.0 and slot:
					_windup(ANIM.atk, 1.2, 0.5, "melee")
				elif not slot and d < 9.0:
					move = _wait_ring(dirn, d, h)
					speed *= 0.6
				elif d > reach - 0.3 and d < 6.0 and K.ai == "melee":
					# einkreisen: jeder Angreifer nimmt eine eigene Seite, statt in einer Reihe anzulaufen
					var seite := (float(get_instance_id() % 3) - 1.0) * 0.95
					var ziel := h.global_position - dirn.rotated(Vector3.UP, seite) * (reach * 0.85)
					move = _toward(ziel, flat(ziel - global_position).normalized(), delta)
				elif d > reach - 0.3:
					move = _toward(h.global_position, dirn, delta)
			"ranged":
				var see: bool = game.sees(global_position, h.global_position)
				var rng: float = K.range / Daten.PX
				if see and atk_t <= 0.0 and game.shot_gap <= 0.0 and d < rng + 1.6:
					game.shot_gap = float(Spiel.D().gap)
					_windup(ANIM.cast, 1.6, 0.35, "shot")
				elif d > 12.0 or not see:
					move = _toward(h.global_position, dirn, delta)
				elif d < 6.8:
					move = -dirn
					speed *= 0.9
				else:
					move = Vector3(-dirn.z, 0, dirn.x) * strafe
					speed *= 0.45
			"boss":
				if kampf:
					if not kampf.steht() and wind <= 0.0 and charge_t <= 0.0:
						move = kampf.bewegung(h, d, dirn, delta)
						speed *= 1.0 / maxf(0.6, kampf.tempo)
				else:
					_boss(delta, h, d, dirn)
					if schild_t > 0.0:
						move = Vector3.ZERO   # während er ruft oder das Tor zerbricht, steht er still
					elif d > 6.0 and wind <= 0.0 and charge_t <= 0.0:
						move = _toward(h.global_position, dirn, delta)
	if wind > 0.0 or act_t > 0.0 or h.dead:
		move = Vector3.ZERO
	if move.length() > 0.05:
		if wind <= 0.0:
			face = atan2(move.x, move.z) if speed >= spd * 0.7 else atan2(dirn.x, dirn.z)
		fortbewegen(speed, clampf(speed / maxf(spd, 0.1), 0.4, 1.4) * (1.0 if kind != "boss" else 1.3), ANIM.run if kind != "boss" else ANIM.walk)
	elif wind <= 0.0 and act_t <= 0.0:
		face = atan2(dirn.x, dirn.z)
		play(ANIM.idle)
	velocity = move.normalized() * speed + kb if move.length() > 0.05 else kb
	move_and_slide()
	global_position.y = 0.0
	turn(delta, 9.0)

func _go(dir: Vector3, speed: float, delta: float) -> void:
	velocity = dir.normalized() * speed + kb
	if dir.length() > 0.01:
		face = atan2(dir.x, dir.z)
	move_and_slide()
	global_position.y = 0.0
	turn(delta, 9.0)

# Ohne Angriffsplatz: auf Abstand lauern (05-update.js: Ring 150 + (i % 3) · 28 px)
func _wait_ring(dirn: Vector3, d: float, h: Hero) -> Vector3:
	var want := (150.0 + (ring_i % 3) * 28.0) / Daten.PX
	if not game.sees(global_position, h.global_position):
		return dirn * 0.8
	if d < want - 0.8:
		return -dirn * 0.6
	if d > want + 0.8:
		return dirn * 0.85
	return Vector3(-dirn.z, 0, dirn.x) * strafe * 0.3

# ---------------------------------------------------------------- Ruhe und Wahrnehmung
func _idle(delta: float, h: Hero) -> void:
	if alarm >= 0.0:
		alarm -= delta
		if alarm <= 0.0:
			game.wake_pack(pack)
			return
	var d := global_position.distance_to(h.global_position)
	if d > 40.0 or h.dead:
		return
	var sees: bool = d < 16.8 and game.sees(global_position, h.global_position)
	if style == "reigen":
		# wer das Stück der Kartusche trägt, dem weichen sie aus; sonst weckt nur, wer ihnen zu nahe kommt
		var nah := 3.2 * float(Spiel.D().sight)
		if d < nah and sees and not game.orte.reigen_friedlich(pack):
			game.wake_pack(pack)
			return
		_reigen(delta)
		return
	if hidden:
		if d < 6.0 and sees:
			game.wake_pack(pack)
		return
	# Sicht: vorne 350 px, hinten 180 px, je nach Schwierigkeit
	if sees:
		var to := flat(h.global_position - global_position)
		var front := forward().angle_to(to.normalized()) < 1.25 if not lying else true
		var rng := (14.0 if front else 7.2) * float(Spiel.D().sight)
		if kind == "boss":
			rng = 10.0
		if d < rng:
			alert += delta
			if mark_show <= 0.0:
				_show_mark("?", Color(0.95, 0.82, 0.3), 0.5)
			if alert >= 0.45:
				game.wake_pack(pack)
			return
	alert = maxf(0.0, alert - delta)
	if lying or kind == "boss":
		return
	# Verhalten in Ruhe
	idle_t -= delta
	match style:
		"streife":
			var target: Vector3
			if lead and lead != self and lead.state == St.SLEEP:
				target = lead.global_position + (home - lead.home)
			elif way.size() > 0:
				target = way[way_i % way.size()]
				if flat(target - global_position).length() < 2.2:
					if idle_t <= 0.0:
						idle_t = randf_range(1.5, 4.0)
						way_i += 1
					play(ANIM.idle)
					return
			else:
				return
			if idle_t > 0.0 and lead == null:
				play(ANIM.idle)
				return
			var dir := flat(target - global_position)
			if dir.length() > 0.6:
				var md := _toward(target, dir.normalized(), delta)
				_go(md, spd * 0.4, delta)
				fortbewegen(spd * 0.4, 0.8, ANIM.walk)
			else:
				play(ANIM.idle)
		"ruhe":
			if idle_t <= -randf_range(0.5, 1.4):
				idle_t = randf_range(2.0, 6.0)
			if idle_t < 0.0:
				var back := flat(home - global_position)
				var dir := back.normalized() if back.length() > 4.4 else Vector3(sin(home_face + idle_t), 0, cos(home_face + idle_t))
				_go(dir, spd * 0.3, delta)
				fortbewegen(spd * 0.3, 0.6, ANIM.walk)
			else:
				play(ANIM.idle)
		_:
			face = home_face
			turn(delta, 4.0)
			play(ANIM.idle)

# Selbst gebaute Gestalten bewegen sich ohne Skelett: schweben, schlängeln, zucken
func _proc_anim(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001 + strafe
	if K.get("look", "") == "wisp" or (kind == "boss" and BOSS_LOOK.get(hour.get("boss", {}).get("look", ""), {}).get("look", "") == "wisp"):
		proc.position.y = sin(t * 2.2) * 0.18
	else:
		proc.position.y = absf(sin(t * 9.0)) * 0.04 if velocity.length() > 0.3 else 0.0
	if state == St.DEAD:
		return
	proc.rotation.y = lerp_angle(proc.rotation.y, face, minf(1.0, delta * 9.0))

# ---------------------------------------------------------------- Angriffe
func _windup(anim: String, sp: float, t: float, what: String) -> void:
	look_to(game.hero.global_position)
	play(anim, sp, 0.1, true)
	wind = t
	act_t = t + 0.35
	atk_t = K.get("atk", 2.4) * randf_range(0.85, 1.2)
	set_meta("what", what)
	match what:
		"melee":
			game.sfx.play_at("skel_attack", global_position, 0.15)
			game.cone_fx(global_position, face, radius + game.hero.radius + 1.2, 0.8, t)
		"slam":
			game.sfx.play_at("skel_attack", global_position, 0.15, -2.0)
			game.warn_fx(global_position, 3.7, t)

func _strike(h: Hero, d: float) -> void:
	match get_meta("what", "melee"):
		"nichts":
			pass   # Eigenschaft eines Champions (Rufen, Klage, Sprung): die Wirkung kommt von dort
		"shot":
			game.sfx.play_at("bolt", global_position)
			game.spawn_bolt(global_position + Vector3(0, 1.5, 0) + forward() * 0.6, flat(h.global_position - global_position).normalized(), dmg, 215.0 / Daten.PX, K.get("shot", Color(0.95, 0.55, 0.9)), 2.6)
		"slam":
			game.ring_fx(global_position, 3.7, Color(0.85, 0.6, 0.3))
			game.shake = maxf(game.shake, 0.45)
			game.sfx.play_at("hit", global_position, 0.1, -2.0)
			if flat(h.global_position - global_position).length() < 3.7 + h.radius:
				h.hurt(dmg, global_position, self)
		_:
			# wer rechtzeitig einen Schritt zurück macht, wird nicht getroffen
			var dd := flat(h.global_position - global_position)
			if dd.length() < radius + h.radius + 0.64 + 0.56 and forward().dot(dd.normalized()) > 0.2:
				h.hurt(dmg, global_position, self)

# ---------------------------------------------------------------- Der Stumme Türhüter (4.0)
# Er fragt nach einem Namen, den niemand mehr kennt. Phase 1 am Tor: Geschossringe, Ansturm und ein Stampfer, der fast
# tötet, wenn man nicht aus dem roten Kreis tritt. Bei zwei Dritteln Leben ruft er die Erloschenen von den Wegen (Phase 2,
# unverwundbar, solange er ruft). Bei einem Drittel zerbricht das Tor: Es wird dunkel, nur die Laterne leuchtet, und
# Sterne fallen (Phase 3). Nach drei Minuten packt ihn die Wut: alles schneller und härter.
func ist_aktende() -> bool:
	if aktende < 0:
		aktende = 1 if kind == "boss" and Stunden.hour_of(Spiel.fall) == 4 else 0
		if aktende == 1:
			# nach der Duell-Messung (4.0): mit dem einfachen Leben eines Hüters fiel er in 45 s, ohne dass der Bot je fiel
			max_hp *= AKT_LEBEN
			hp = max_hp
			dmg *= AKT_SCHADEN
	return aktende == 1

func _phase_pruefen() -> void:
	if phase == 1 and hp < max_hp * 0.66:
		phase = 2
		_schild(6.0)
		welle_t = 0.0
		game.on_boss_phase(self, 2)
	elif phase == 2 and hp < max_hp * 0.33:
		phase = 3
		_schild(3.5)
		stern_t = 2.0
		game.on_boss_phase(self, 3)

func _schild(dauer: float) -> void:
	schild_t = dauer
	charge_t = 0.0
	wind = 0.0
	if schild_vis == null:
		schild_vis = MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = radius + 1.2
		sm.height = (radius + 1.2) * 2.0
		sm.radial_segments = 24
		sm.rings = 12
		schild_vis.mesh = sm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_color = Color(0.55, 0.7, 1.0, 0.22)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		schild_vis.material_override = m
		add_child(schild_vis)
		schild_vis.position = Vector3(0, 1.4, 0)
	schild_vis.visible = true

# zurück auf Anfang, wenn der Held fällt (A5: man beginnt direkt vor der Arena neu)
func tuerhueter_zuruecksetzen(geschwaecht := 0) -> void:
	phase = 1
	schild_t = 0.0
	kampf_t = 0.0
	stampf_t = 4.0
	stern_t = 3.0
	# volles Leben, aber was Feuerschalen und Entscheidungen ihm genommen haben, bleibt genommen
	hp = max_hp * (1.0 - minf(0.2, 0.1 * geschwaecht))
	if schild_vis:
		schild_vis.visible = false

func _tuerhueter(delta: float, h: Hero, d: float, dirn: Vector3) -> void:
	kampf_t += delta
	var wut := kampf_t > 150.0
	var tempo := (0.7 if wut else 1.0) * (0.85 if phase == 3 else 1.0)
	if schild_t > 0.0:
		if schild_vis:
			schild_vis.rotation.y += delta
			schild_vis.scale = Vector3.ONE * (1.0 + sin(kampf_t * 6.0) * 0.03)
		play(ANIM.cast, 1.2)
		return
	for i in 3:
		boss_t[i] -= delta
	stampf_t -= delta
	# der Stampfer: roter Kreis um ihn, 1,1 s später bebt der Boden; wer drinsteht, verliert fast alles
	if stampf_t <= 0.0 and d < 7.0:
		stampf_t = 6.5 * tempo
		var r := 4.2
		game.warn_fx(global_position, r, 1.1)
		play(ANIM.cast, 1.0, 0.1, true)
		var wo := global_position
		get_tree().create_timer(1.1, false).timeout.connect(func():
			if state == St.DEAD or h.dead:
				return
			game.shake = maxf(game.shake, 0.7)
			game.sfx.play_at("boss_phase" if game.sfx._stream("boss_phase") else "hit", wo, 0.05, -4.0)
			game.ring_fx(wo, r, Color(0.75, 0.82, 0.9))
			if flat(h.global_position - wo).length() < r + h.radius:
				h.hurt(h.max_hp * [0.55, 0.7, 0.85][Spiel.diff] * (1.25 if wut else 1.0), wo, self))
	# Geschossringe in jeder Phase
	if boss_t[0] <= 0.0:
		boss_t[0] = [3.4, 2.8, 3.2][phase - 1] * tempo
		var n := 16 + mini(10, Spiel.fall)
		var off := randf() * TAU
		game.sfx.play_at("bolt", global_position, 0.05, 2.0)
		for k in n:
			var a := off + TAU * k / n
			game.spawn_bolt(global_position + Vector3(0, 1.4, 0), Vector3(sin(a), 0, cos(a)), dmg * 1.05, 185.0 / Daten.PX, K.get("bcol", Color(0.75, 0.82, 0.95)), 3.4)
		play(ANIM.cast, 1.6, 0.1, true)
	# Phase 2: Wellen der Erloschenen
	if phase >= 2:
		welle_t -= delta
		if welle_t <= 0.0:
			welle_t = (14.0 if phase == 2 else 22.0) * tempo
			game.boss_summon(self, ["fahl", "fahl", "fahl", "hohl"] if phase == 2 else ["fahl", "fahl", "fahl"])
			play(ANIM.summon if ap and ap.has_animation(ANIM.summon) else ANIM.cast, 1.4, 0.1, true)
	# Phase 3: fallende Sterne, einer genau auf dich, die anderen ringsum
	if phase == 3:
		stern_t -= delta
		if stern_t <= 0.0:
			stern_t = 1.9 * tempo
			for i in (5 if wut else 4):
				var ziel: Vector3 = h.global_position + (Vector3.ZERO if i == 0 else Vector3(randf_range(-4.5, 4.5), 0, randf_range(-4.5, 4.5)))
				game.fallender_stern(ziel, 2.4, dmg * (2.4 if wut else 2.0), self)
	# Ansturm wie jeder Hüter
	if boss_t[2] <= 0.0:
		boss_t[2] = 7.5 * tempo
		if d < 22.4 and d > 4.0:
			charge_dir = dirn
			face = atan2(dirn.x, dirn.z)
			charge_t = 0.9 + 0.85
			charge_hit = false
			game.stripe_fx(global_position, charge_dir, 21.6, radius * 2.0, 0.9)
			game.sfx.play_at("boss_appear", global_position, 0.05, -6.0)

# Hüter (05-update.js › bossAI): Geschossring, Beschwörung, Ansturm; unter 30 % Leben schneller
func _boss(delta: float, h: Hero, d: float, dirn: Vector3) -> void:
	if ist_aktende():
		_tuerhueter(delta, h, d, dirn)
		return
	var fast := 0.65 if hp < max_hp * 0.3 else 1.0
	for i in 3:
		boss_t[i] -= delta
	if boss_t[0] <= 0.0:
		boss_t[0] = 2.8 * fast
		var n := 12 + mini(10, Spiel.fall)
		var off := randf() * TAU
		game.sfx.play_at("bolt", global_position, 0.05, 2.0)
		for k in n:
			var a := off + TAU * k / n
			game.spawn_bolt(global_position + Vector3(0, 1.4, 0), Vector3(sin(a), 0, cos(a)), dmg * 0.8, 170.0 / Daten.PX, K.get("bcol", Color(0.95, 0.55, 0.9)), 3.4)
		play(ANIM.cast, 1.6, 0.1, true)
	if boss_t[1] <= 0.0:
		boss_t[1] = 10.0 * fast
		var first: Array = Stunden.expand(hour.get("packs", ["wisp*3"])[0]).slice(0, 3)
		game.boss_summon(self, first)
		play(ANIM.summon if ap and ap.has_animation(ANIM.summon) else ANIM.cast, 1.4, 0.1, true)
	if boss_t[2] <= 0.0:
		boss_t[2] = 7.0 * fast
		if d < 22.4:
			# Ansage: roter Streifen, dann Ansturm geradeaus
			charge_dir = dirn
			face = atan2(dirn.x, dirn.z)
			charge_t = 0.9 + 0.85
			charge_hit = false
			game.stripe_fx(global_position, charge_dir, 21.6, radius * 2.0, 0.9)
			game.sfx.play_at("boss_appear", global_position, 0.05, -6.0)

func _charge(delta: float, h: Hero) -> void:
	charge_t -= delta
	if charge_t > 0.85:
		turn(delta, 12.0)
		play(ANIM.idle)
		return
	velocity = charge_dir * (620.0 * SPD) + kb
	var p0 := global_position
	move_and_slide()
	global_position.y = 0.0
	play(ANIM.run, 1.6)
	turn(delta, 12.0)
	if (global_position - p0).length() < 0.01 * delta * 60.0:
		charge_t = 0.0   # an der Mauer gestoppt
	if not charge_hit and flat(h.global_position - global_position).length() < radius + h.radius + 0.4:
		charge_hit = true
		h.hurt(dmg * 1.6, global_position, self)
		game.shake = maxf(game.shake, 0.5)

func _toward(target: Vector3, dirn: Vector3, delta: float) -> Vector3:
	# gerade, wenn der Weg frei ist; sonst über das Wegenetz um die Mauern herum
	if game.walkable(global_position, target):
		path = PackedVector3Array()
		return dirn
	path_t -= delta
	if path_t <= 0.0 or path.is_empty():
		path_t = 0.4
		path = game.find_path(global_position, target)
	while path.size() > 0 and flat(path[0] - global_position).length() < 0.7:
		path.remove_at(0)
	if path.is_empty():
		return dirn
	return flat(path[0] - global_position).normalized()

func hit(amount: float, from: Vector3, push := 6.0, stun_t := 0.0, crit := false) -> void:
	if state == St.DEAD:
		return
	if kind == "objekt":
		# Kartusche, Krug, Trugbild: kein Rückstoß, keine Betäubung
		if besitzer and not besitzer.objekt_treffbar(self):
			return
		hp -= amount
		flash()
		zucken(from, 0.6)
		game.float_text(global_position + Vector3(0, 2.4, 0), str(int(round(amount))), Color(1.0, 0.94, 0.78))
		if hp <= 0.0:
			die()
		return
	if state == St.SLEEP:
		game.wake_pack(pack)
	if schild_t > 0.0:
		game.float_text(global_position + Vector3(0, 2.6, 0), "unverwundbar", Color(0.75, 0.82, 0.9))
		return
	if huelle_t > 0.0:
		amount *= 3.0   # die leere Haut reißt leicht
	if not affixe.is_empty():
		amount = Affixe.treffer(self, amount, from)
	if kampf and amount < 1e8:
		amount = kampf.schaden(amount)
		if amount <= 0.0:
			game.float_text(global_position + Vector3(0, 2.8, 0), kampf.schild_text(), Color(1.0, 0.8, 0.4))
			return
	hp -= amount
	ruhe_seit = 0.0
	if aktende == 1 and hp > 0.0:
		_phase_pruefen()
	if kampf and hp > 0.0:
		kampf.nach_treffer()
	flash()
	zucken(from, (1.6 if crit else 1.0) / (2.0 if kind == "boss" else 1.0))
	# schwerer Treffer (Krit oder mehr als ein Drittel des Lebens auf einmal): kurzer Trefferstopp
	if crit or amount >= max_hp * 0.34:
		game.trefferstopp()
	var k := push / (8.0 if kind == "boss" else (3.0 if K.ai == "slam" else 1.0))
	kb += flat(global_position - from).normalized() * k
	if stun_t > 0.0:
		stun = maxf(stun, stun_t * (0.3 if kind == "boss" else 1.0))
		wind = 0.0
		act_t = 0.0
	var top := 2.4 * sc if proc == null else 1.8 + radius
	if crit:
		game.float_text(global_position + Vector3(0, top + 0.2, 0), str(int(round(amount))) + "!", Color(1.0, 0.66, 0.18), 1.35)   # Krit: Bernstein, etwas größer
		game.shake = maxf(game.shake, 0.18)
	else:
		game.float_text(global_position + Vector3(0, top, 0), str(int(round(amount))), Color(1.0, 0.94, 0.78))
	if hp <= 0.0:
		die()
	elif ap and kind != "boss" and wind <= 0.0 and act_t <= 0.0:
		play(ANIM.hit, 1.8, 0.05, true)
		act_t = 0.22

func die() -> void:
	if kind == "objekt":
		state = St.DEAD
		collision_layer = 0
		if besitzer:
			besitzer.objekt_tot(self)
		return
	state = St.DEAD
	collision_layer = 0
	collision_mask = 0
	charge_t = 0.0
	huelle_t = 0.0
	if ap and ap.speed_scale == 0.0:
		ap.speed_scale = 1.0
	mark3d.visible = false
	if not affixe.is_empty():
		Affixe.tod(self)
		Affixe.zerfall(self)
	# Champions: Ring und Name blenden mit aus (blieben vorher stehen, als lebte der Gegner noch)
	for n in elite_teile:
		if n is Label3D:
			n.visible = false
		else:
			var tr := create_tween()
			tr.tween_property(n, "scale", Vector3.ONE * 0.01, 0.5).set_ease(Tween.EASE_IN)
			tr.tween_callback(n.hide)
	if proc:
		var tw := create_tween()
		tw.tween_property(proc, "scale", Vector3.ONE * 0.05, 0.45).set_ease(Tween.EASE_IN)
		tw.tween_callback(func(): proc.visible = false)
		game.spark(global_position + Vector3(0, 1.0, 0), K.get("bcol", K.get("col", Color.WHITE)))
	else:
		play(ANIM.death, 1.3, 0.05, true)
		fallen()   # Fall als Gliederpuppe, sofern die Physik Platz hat (actor.gd, physik.gd)
		# der Besiegte bleibt einen Moment liegen und versinkt dann im Boden
		var tw2 := create_tween()
		tw2.tween_interval(5.0)
		tw2.tween_property(model, "position:y", -1.7, 1.8).set_ease(Tween.EASE_IN)
		tw2.tween_callback(func(): model.visible = false)
	game.sfx.play_at("skel_die", global_position)
	if glow:
		var tw := create_tween()
		tw.tween_property(glow, "light_energy", 0.0, 1.2)
	game.on_foe_dead(self)
