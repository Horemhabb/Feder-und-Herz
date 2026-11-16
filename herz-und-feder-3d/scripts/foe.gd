class_name Foe extends Actor
# Die Ruhelosen: Tote, deren Ba nicht mehr zu ihnen zurückfindet. Sie liegen still, bis die Laterne naht.

const ANIM := {
	"sleep": "Skeletons_Inactive_Floor_Pose", "wake": "Skeletons_Awaken_Floor", "idle": "Idle_Combat", "walk": "Walking_D_Skeletons",
	"run": "Running_A", "atk": "1H_Melee_Attack_Chop", "atk_big": "2H_Melee_Attack_Chop", "cast": "Spellcast_Shoot",
	"hit": "Hit_A", "death": "Death_C_Skeletons", "stand": "Skeleton_Inactive_Standing_Pose", "rise": "Skeletons_Awaken_Standing", "taunt": "Taunt",
}
const KINDS := {
	"minion": {"typ": "guard", "mat": "eisen", "undead": true, "name": "Ruheloser", "model": "Skeleton_Minion", "scale": 1.0, "r": 0.55, "hp": 66.0, "dmg": 9.0, "spd": 3.9, "weapon": "Skeleton_Blade", "ai": "melee", "atk_cd": 1.9},
	"mage": {"typ": "fahl", "mat": "eisen", "undead": true, "name": "Ruheloser Priester", "model": "Skeleton_Mage", "scale": 1.0, "r": 0.55, "hp": 42.0, "dmg": 9.0, "spd": 3.2, "weapon": "Skeleton_Staff", "ai": "ranged", "atk_cd": 2.6},
	"boss": {"typ": "boss", "bossf": 0.7, "mat": "", "undead": false, "name": "Mahaf, das Leitlicht", "model": "Skeleton_Warrior", "scale": 1.75, "r": 1.0, "hp": 1000.0, "dmg": 18.0, "spd": 3.4, "weapon": "Skeleton_Axe", "ai": "boss", "atk_cd": 2.4},
}

enum St { SLEEP, WAKING, FIGHT, DEAD }

var kind := "minion"
var K: Dictionary
var state := St.SLEEP
var pack := 0
var wake_t := 0.0
var atk_t := 0.0       # Abklingzeit bis zum nächsten Angriff
var wind := 0.0        # Ausholen: läuft ab, dann fällt der Hieb
var act_t := 0.0       # Rest der Angriffsbewegung
var slot := true       # darf gerade angreifen (höchstens zwei zugleich)
var path: PackedVector3Array = []
var path_t := 0.0
var strafe := 1.0
var nova_t := 6.0
var glow: OmniLight3D
var home := Vector3.ZERO
# Werte nach den Formeln der 2D-Fassung (03-world.js › spawn): Gegnerart, Stunde und Schwierigkeit
var dmg := 10.0
var spd := 4.0
var xp := 10.0
var w := 1.0
var elite := ""        # "", "flink", "zaeh" oder "wild"
var slow_t := 0.0      # Seschats Maß: kriechen mit 40 % Tempo
var mark_t := 0.0      # Gebs Lachen: zerbirst beim Tod
var fear_t := 0.0      # Upuauts Hatz: Tiere fliehen
var disp_name := ""

func init(k: String, pos: Vector3, p: int, el := "") -> void:
	kind = k
	K = KINDS[k]
	pack = p
	elite = el
	var T: Dictionary = Daten.ET[K.typ]
	var D: Dictionary = Spiel.D()
	var F := Spiel.fall
	max_hp = T.hp * 1.55 * pow(1.28, F - 1) * D.hp * K.get("bossf", 1.0)
	dmg = T.dmg * 1.25 * pow(1.2, F - 1) * D.dmg
	xp = T.xp * pow(1.22, F - 1) * D.xp
	w = T.w
	spd = K.spd * D.spd
	disp_name = K.name
	var scl: float = K.scale
	if elite != "":
		max_hp *= 3.4 * (1.7 if elite == "zaeh" else 1.0)
		dmg *= 1.35 * (1.4 if elite == "wild" else 1.0)
		spd *= 1.5 if elite == "flink" else 1.0
		xp *= 4.0
		w *= 3.0
		scl *= 1.25
		for e in Daten.ELITE:
			if e.id == elite:
				disp_name = "%s, %s" % [K.name, e.name]
	setup("res://models/chars/%s.glb" % K.model, scl, K.r * (1.25 if elite != "" else 1.0))
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	hp = max_hp
	if elite != "":
		_elite_mark(scl)
	position = pos
	home = pos
	face = randf() * TAU
	model.rotation.y = face
	strafe = 1.0 if randf() < 0.5 else -1.0
	var w = load("res://models/chars/%s.gltf" % K.weapon)
	if w:
		attach("handslot.r", w.instantiate())
	if kind == "boss":
		glow = OmniLight3D.new()
		glow.light_color = Color(0.45, 0.95, 0.9)
		glow.light_energy = 1.2
		glow.omni_range = 9.0
		glow.position = Vector3(0, 3.2, 0)
		add_child(glow)
		play(ANIM.stand, 1.0, 0.0)
	else:
		play(ANIM.sleep, 1.0, 0.0)
		set_collision_layer_value(3, false)   # schlafend steht er niemandem im Weg

# Nach einer Niederlage des Helden legen sich die Wachen wieder hin; der Hüter kehrt mit voller Kraft an seinen Platz zurück.
func sleep_again() -> void:
	if state == St.DEAD:
		return
	state = St.SLEEP
	global_position = home
	stun = 0.0
	wind = 0.0
	act_t = 0.0
	kb = Vector3.ZERO
	path = PackedVector3Array()
	if kind == "boss":
		nova_t = 6.0
		play(ANIM.stand, 1.0, 0.2, true)
	else:
		play(ANIM.sleep, 1.0, 0.2, true)
		set_collision_layer_value(3, false)

func wake(delay := 0.0) -> void:
	if state != St.SLEEP:
		return
	state = St.WAKING
	wake_t = -delay

func _physics_process(delta: float) -> void:
	tick_common(delta)
	slow_t -= delta
	mark_t -= delta
	fear_t -= delta
	var h: Hero = game.hero
	match state:
		St.DEAD:
			return
		St.SLEEP:
			var d := global_position.distance_to(h.global_position)
			if not h.dead and d < (13.0 if kind != "boss" else 10.0) and game.sees(global_position, h.global_position):
				game.wake_pack(pack)
			return
		St.WAKING:
			wake_t += delta
			if wake_t < 0.0:
				return
			var a: String = ANIM.rise if kind == "boss" else ANIM.wake
			if cur_anim != a:
				play(a, 1.5 if kind != "boss" else 1.0, 0.1, true)
				game.sfx.play_at("skel_wake", global_position)
				set_collision_layer_value(3, true)
				if kind == "boss":
					game.on_boss_wake(self)
			if wake_t > anim_len(a) / ap.speed_scale * 0.92:
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
	if fear_t > 0.0 and stun <= 0.0:
		# fliehen, ohne anzugreifen
		velocity = -dirn * spd * 1.15 + kb
		face = atan2(-dirn.x, -dirn.z)
		play(ANIM.run)
		move_and_slide()
		global_position.y = 0.0
		turn(delta, 9.0)
		return
	if stun > 0.0:
		velocity = kb
		move_and_slide()
		play(ANIM.hit, 0.6)
		return
	if wind > 0.0:
		wind -= delta
		if wind <= 0.0:
			_strike(h, d)
	elif act_t <= 0.0 and not h.dead:
		var reach: float = radius + h.radius + (1.5 if kind != "boss" else 2.4)
		match K.ai:
			"melee":
				if d < reach and atk_t <= 0.0 and slot:
					_windup(ANIM.atk, 1.5, 0.45)
				elif not slot and d < 6.5:
					# kein Angriffsplatz frei: auf Abstand lauern und seitlich umkreisen
					if d < 4.2:
						move = -dirn
					else:
						move = Vector3(-dirn.z, 0, dirn.x) * strafe * 0.45
					speed *= 0.6
				elif d > reach - 0.4:
					move = _toward(h.global_position, dirn, delta)
			"ranged":
				var see: bool = game.sees(global_position, h.global_position)
				if d < 15.0 and see and atk_t <= 0.0 and game.shot_gap <= 0.0:
					game.shot_gap = float(Spiel.D().gap)
					_windup(ANIM.cast, 1.6, 0.4)
				elif d > 12.0 or not see:
					move = _toward(h.global_position, dirn, delta)
				elif d < 6.5:
					move = -dirn
					speed *= 0.9
				else:
					move = Vector3(-dirn.z, 0, dirn.x) * strafe * 0.4
			"boss":
				nova_t -= delta
				if nova_t <= 0.0 and d < 16.0:
					nova_t = 7.5
					_windup(ANIM.taunt, 1.3, 0.75, true)
				elif d < reach and atk_t <= 0.0:
					_windup(ANIM.atk_big, 1.35, 0.62)
				elif d > reach - 0.5:
					move = _toward(h.global_position, dirn, delta)
	if wind > 0.0 or act_t > 0.0:
		move = Vector3.ZERO
	if h.dead:
		move = Vector3.ZERO
	if move.length() > 0.05:
		if wind <= 0.0:
			face = atan2(move.x, move.z) if speed >= spd * 0.9 else atan2(dirn.x, dirn.z)
		play(ANIM.run if kind != "boss" else ANIM.walk, speed / spd * (1.0 if kind != "boss" else 1.3))
	elif wind <= 0.0 and act_t <= 0.0:
		face = atan2(dirn.x, dirn.z)
		play(ANIM.idle)
	velocity = move.normalized() * speed + kb if move.length() > 0.05 else kb
	move_and_slide()
	global_position.y = 0.0
	turn(delta, 9.0)

func _windup(anim: String, sp: float, at: float, nova := false) -> void:
	look_to(game.hero.global_position)
	play(anim, sp, 0.1, true)
	var total := anim_len(anim) / sp
	wind = total * at
	act_t = total * 0.95
	atk_t = K.atk_cd * randf_range(0.85, 1.2)
	set_meta("nova", nova)
	if kind != "mage" and not nova:
		game.sfx.play_at("skel_attack", global_position, 0.15)
	if kind == "boss" and not nova:
		game.warn_fx(global_position + forward() * 2.6, 3.0, wind)
	if nova:
		game.warn_fx(global_position, 2.2, wind)

func _strike(h: Hero, d: float) -> void:
	if get_meta("nova", false):
		game.sfx.play_at("bolt", global_position, 0.05, 3.0)
		for i in 10:
			var a := TAU * i / 10.0 + randf() * 0.2
			game.spawn_bolt(global_position + Vector3(0, 1.4, 0), Vector3(sin(a), 0, cos(a)), dmg * 0.6, 7.5)
		return
	match K.ai:
		"ranged":
			game.sfx.play_at("bolt", global_position)
			game.spawn_bolt(global_position + Vector3(0, 1.5, 0) + forward() * 0.8, flat(h.global_position - global_position).normalized(), dmg, 9.5)
		"boss":
			var c := global_position + forward() * 2.6
			game.ring_fx(c, 3.0, Color(0.45, 0.95, 0.9))
			game.shake = maxf(game.shake, 0.5)
			game.sfx.play_at("hit", c, 0.1, -3.0)
			if flat(h.global_position - c).length() < 3.0 + h.radius:
				h.hurt(dmg, global_position, self)
		_:
			# wer rechtzeitig einen Schritt zurück macht, wird nicht getroffen
			var dd := flat(h.global_position - global_position)
			if dd.length() < radius + h.radius + 2.0 and forward().dot(dd.normalized()) > 0.3:
				h.hurt(dmg, global_position, self)

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
	var k := push / (6.0 if kind == "boss" else 1.0)
	kb += flat(global_position - from).normalized() * k
	if stun_t > 0.0 and kind != "boss":
		stun = maxf(stun, stun_t)
		wind = 0.0
		act_t = 0.0
	if crit:
		game.float_text(global_position + Vector3(0, 2.6 * K.scale, 0), str(int(round(amount))) + "!", Color(1.0, 0.85, 0.2), 1.5)
		game.shake = maxf(game.shake, 0.18)
	else:
		game.float_text(global_position + Vector3(0, 2.4 * K.scale, 0), str(int(round(amount))), Color(1.0, 0.9, 0.6))
	if hp <= 0.0:
		die()
	elif kind != "boss" and wind <= 0.0 and act_t <= 0.0:
		play(ANIM.hit, 1.8, 0.05, true)
		act_t = 0.22

func die() -> void:
	state = St.DEAD
	collision_layer = 0
	collision_mask = 0
	play(ANIM.death, 1.3, 0.05, true)
	game.sfx.play_at("skel_die", global_position)
	if glow:
		var tw := create_tween()
		tw.tween_property(glow, "light_energy", 0.0, 1.2)
	game.on_foe_dead(self)

# Elite: goldener Ring am Boden und der Name über dem Kopf
func _elite_mark(scl: float) -> void:
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
	var l := Label3D.new()
	l.text = disp_name
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 44
	l.outline_size = 10
	l.modulate = Color(0.95, 0.82, 0.29)
	l.position.y = 2.9 * scl
	l.pixel_size = 0.006
	add_child(l)
