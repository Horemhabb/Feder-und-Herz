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
	"wisp": {"ai": "swarm", "atk": 0.9, "spd": 135.0, "r": 10.0, "look": "wisp", "col": Color("8fe3e0"), "mat": ""},
	"skorp": {"ai": "swarm", "atk": 1.1, "spd": 116.0, "r": 12.0, "look": "skorp", "col": Color("b98a4a"), "mat": "", "animal": true},
	"lance": {"ai": "melee", "atk": 1.9, "spd": 92.0, "r": 14.0, "model": "Skeleton_Rogue", "tint": Color(0.95, 0.78, 0.42), "weapon": "Skeleton_Blade", "mat": "leder"},
	"seer": {"ai": "ranged", "atk": 2.3, "spd": 84.0, "r": 13.0, "range": 340.0, "model": "Skeleton_Mage", "tint": Color(0.85, 0.95, 0.7), "weapon": "Skeleton_Staff", "shot": Color("9be06b"), "mat": "leder"},
	"haut": {"ai": "slam", "atk": 3.0, "spd": 62.0, "r": 26.0, "model": "Skeleton_Warrior", "scale": 1.6, "tint": Color(0.75, 0.62, 0.4), "weapon": "Skeleton_Axe", "mat": "leder"},
	"guard": {"ai": "melee", "atk": 2.1, "spd": 74.0, "r": 15.0, "model": "Skeleton_Minion", "weapon": "Skeleton_Blade", "mat": "eisen", "undead": true, "lies": true},
	"fahl": {"ai": "ranged", "atk": 2.1, "spd": 88.0, "r": 13.0, "range": 360.0, "model": "Skeleton_Mage", "tint": Color(0.7, 0.78, 0.85), "weapon": "Skeleton_Staff", "shot": Color("e06bd0"), "mat": "stern"},
	"hohl": {"ai": "melee", "atk": 1.6, "spd": 112.0, "r": 15.0, "neu": "Hohler", "neu_glow": Color(0.6, 0.8, 1.0), "model": "Skeleton_Rogue", "tint": Color(0.55, 0.26, 0.24), "weapon": "Skeleton_Blade", "mat": "eisen", "demon": true, "undead": true, "glow": Color(0.95, 0.35, 0.2)},
}
# Gestalten der Hüter (ACT[…].boss.look)
const BOSS_LOOK := {
	"wisp": {"look": "wisp", "mat": ""},
	"mutter": {"model": "Skeleton_Warrior", "tint": Color(0.92, 0.75, 0.4), "weapon": "Skeleton_Axe", "mat": "leder"},
	"koenig": {"model": "Skeleton_Warrior", "tint": Color(1.0, 0.85, 0.45), "weapon": "Skeleton_Axe", "mat": "eisen", "undead": true},
	"grey": {"model": "Skeleton_Warrior", "tint": Color(0.72, 0.78, 0.82), "weapon": "Skeleton_Axe", "mat": "stern"},
	"sammler": {"model": "Skeleton_Mage", "tint": Color(0.8, 0.55, 1.0), "weapon": "Skeleton_Staff", "mat": "stern"},
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
var style := "ruhe"    # ruhe, lager, wache, streife, hinterhalt
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
var hour: Dictionary

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
	var T: Dictionary = Daten.ET[typ]
	max_hp = T.hp * 1.55 * pow(1.28, F - 1) * D.hp * (float(hdef.boss.hp) if k == "boss" and hdef.has("boss") else 1.0)
	dmg = T.dmg * 1.25 * pow(1.2, F - 1) * D.dmg
	xp = T.xp * pow(1.22, F - 1) * D.xp
	w = T.w
	spd = (58.0 if k == "boss" else float(K.spd)) * SPD * D.spd
	disp_name = K.name
	var r := r_px / Daten.PX
	if elite != "":
		max_hp *= 3.4 * (1.7 if elite == "zaeh" else 1.0)
		dmg *= 1.35 * (1.4 if elite == "wild" else 1.0)
		spd *= 1.5 if elite == "flink" else 1.0
		xp *= 4.0
		w *= 3.0
		sc *= 1.25
		r *= 1.25
		for e in Daten.ELITE:
			if e.id == elite:
				disp_name = "%s, %s" % [K.name, e.name]
	if Spiel.neu3d and K.has("neu") and k != "boss":
		# Werkstatt: Figur aus der Figurenfabrik, mit eigener Haut und eigenen Klauen (keine Tönung, keine Waffe)
		setup("res://models/chars/%s.glb" % K.neu, sc * 0.94, r)
		neu3d = true
	elif K.has("model"):
		setup("res://models/chars/%s.glb" % K.model, sc * (1.0 if k != "boss" else 1.0), r)
		if K.has("tint"):
			_tint(K.tint)
		var wpn = load("res://models/chars/%s.gltf" % K.get("weapon", "Skeleton_Blade"))
		if wpn:
			attach("handslot.r", wpn.instantiate())
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
	_rest_pose(true)

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
		flash_mat.albedo_color = Color(1, 0.95, 0.85, 0.75)
		flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

# Elite: goldener Ring am Boden und der Name über dem Kopf
func _elite_mark(s: float) -> void:
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = radius * 1.35
	tm.outer_radius = radius * 1.6
	tm.rings = 24
	tm.ring_segments = 6
	ring.mesh = tm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.95, 0.82, 0.29, 0.85)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = m
	ring.position.y = 0.06
	add_child(ring)
	elite_teile.append(ring)
	var l := Label3D.new()
	l.text = disp_name
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 44
	l.outline_size = 10
	l.modulate = Color(0.95, 0.82, 0.29)
	l.position.y = 2.9 * s if proc == null else 2.4
	l.pixel_size = 0.006
	add_child(l)
	elite_teile.append(l)

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

func _physics_process(delta: float) -> void:
	tick_common(delta)
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
			elif kind == "boss" and proc == null and cur_anim != ANIM.rise:
				play(ANIM.rise, 1.0, 0.1, true)
				game.on_boss_wake(self)
				return
			elif kind == "boss" and proc != null and wake_t < 0.2:
				game.on_boss_wake(self)
				wake_t = 0.2
			if kind == "boss" and proc == null and wake_t < anim_len(ANIM.rise) * 0.9:
				return
			state = St.FIGHT
			atk_t = randf_range(0.2, 0.9)
			return
	# ---- Kampf ----
	atk_t -= delta
	act_t -= delta
	var to := flat(h.global_position - global_position)
	var d := to.length()
	var dirn := to / maxf(d, 0.001)
	var move := Vector3.ZERO
	var speed: float = spd * (0.4 if slow_t > 0.0 else 1.0)
	if fear_t > 0.0 and stun <= 0.0 and kind != "boss":
		_go(-dirn, spd * 1.15, delta)
		play(ANIM.run)
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
				_boss(delta, h, d, dirn)
				if d > 6.0 and wind <= 0.0 and charge_t <= 0.0:
					move = _toward(h.global_position, dirn, delta)
	if wind > 0.0 or act_t > 0.0 or h.dead:
		move = Vector3.ZERO
	if move.length() > 0.05:
		if wind <= 0.0:
			face = atan2(move.x, move.z) if speed >= spd * 0.7 else atan2(dirn.x, dirn.z)
		play(ANIM.run if kind != "boss" else ANIM.walk, clampf(speed / maxf(spd, 0.1), 0.4, 1.4) * (1.0 if kind != "boss" else 1.3))
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
				play(ANIM.walk if ap and ap.has_animation(ANIM.walk) else ANIM.run, 0.8)
			else:
				play(ANIM.idle)
		"ruhe":
			if idle_t <= -randf_range(0.5, 1.4):
				idle_t = randf_range(2.0, 6.0)
			if idle_t < 0.0:
				var back := flat(home - global_position)
				var dir := back.normalized() if back.length() > 4.4 else Vector3(sin(home_face + idle_t), 0, cos(home_face + idle_t))
				_go(dir, spd * 0.3, delta)
				play(ANIM.walk if ap and ap.has_animation(ANIM.walk) else ANIM.run, 0.6)
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

# Hüter (05-update.js › bossAI): Geschossring, Beschwörung, Ansturm; unter 30 % Leben schneller
func _boss(delta: float, h: Hero, d: float, dirn: Vector3) -> void:
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
	if state == St.SLEEP:
		game.wake_pack(pack)
	hp -= amount
	flash()
	var k := push / (8.0 if kind == "boss" else (3.0 if K.ai == "slam" else 1.0))
	kb += flat(global_position - from).normalized() * k
	if stun_t > 0.0:
		stun = maxf(stun, stun_t * (0.3 if kind == "boss" else 1.0))
		wind = 0.0
		act_t = 0.0
	var top := 2.4 * sc if proc == null else 1.8 + radius
	if crit:
		game.float_text(global_position + Vector3(0, top + 0.2, 0), str(int(round(amount))) + "!", Color(1.0, 0.85, 0.2), 1.5)
		game.shake = maxf(game.shake, 0.18)
	else:
		game.float_text(global_position + Vector3(0, top, 0), str(int(round(amount))), Color(1.0, 0.9, 0.6))
	if hp <= 0.0:
		die()
	elif ap and kind != "boss" and wind <= 0.0 and act_t <= 0.0:
		play(ANIM.hit, 1.8, 0.05, true)
		act_t = 0.22

func die() -> void:
	state = St.DEAD
	collision_layer = 0
	collision_mask = 0
	charge_t = 0.0
	mark3d.visible = false
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
