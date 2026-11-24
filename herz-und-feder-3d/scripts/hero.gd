class_name Hero extends Actor
# Die Figur des Spielers in einer der vier Klassen (klassen.gd): Eidträger, Priester des Schu, Wüstenjägerin, Sternleserin.
# Standardangriff und Fähigkeiten folgen 04-combat.js › basicAttack und cast; Entfernungen sind aus Weltpixeln in Meter
# umgerechnet (Daten.PX). Alle tragen die Laterne mit dem Funken des Re.

const SPEED := 7.2   # 4.0: 6,4; mit dem lebendigeren Lauftakt etwas schneller (4.1)

var cls := "ermittler"
var C: Dictionary          # Klassendaten
var ANIM: Dictionary       # Animationsnamen des Modells
var SK := {}               # Fähigkeiten dieser Klasse
var ORDER: Array = []      # Tasten 1–4, rechte Maustaste, Rotbier

var en := 60.0
var pots: int:   # Rotbier gehört zur Figur und überdauert den Neustart einer Stunde
	get: return Spiel.pots
	set(v): Spiel.pots = v
var hits := 0            # Standardangriffe gezählt (Fäuste des Namenlosen: jeder vierte trifft doppelt)
var skin_t := 0.0        # Haut des Mehen: bis zum nächsten abgeprallten Treffer
var cd := {}
var busy := 0.0          # so lange läuft eine Aktion, die das Laufen sperrt
var busy_basic := false  # die laufende Aktion ist nur ein Standardangriff: Fähigkeiten dürfen ihn unterbrechen
var pending: Array = []  # geplante Treffer: [Zeit, Callable]
var combo := 0
var oath_t := 0.0        # Eid der Maat
var mantra_t := 0.0      # Kreis des Ka
var inv := 1.5
var dash_t := 0.0
var dash_speed := 30.0     # Tempo des laufenden Satzes (Fähigkeit 30, Ausweichschritt 15)
var dodge_cd := 0.0        # bis zum nächsten Ausweichschritt
var lunge := Vector3.ZERO  # Ausfallschritt beim Hieb
var dash_dir := Vector3.ZERO
var dash_slam := Vector2.ZERO   # Aufprall am Ende eines Sprungs: Radius, Stärke (0 = ohne Schaden)
var casts := 0           # gewirkte Fähigkeiten (Wort des Thot: jede fünfte ist frei)
var step_t := 0.0
var step_ids := []                 # Knochen der Füße: Knöchel und Ballen, links dann rechts (Schrittklang)
var step_boden := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])   # tiefster Stand je Knochen, steigt langsam wieder
var step_unten := [true, true]     # steht der Fuß gerade unten (aufgesetzt)?
var step_sperre := [0.0, 0.0]      # Mindestabstand je Fuß bis zum nächsten Klang
var step_zeit := -1.0              # Zeitpunkt des letzten Blicks auf die Füße (nach einer Pause neu ansetzen)
var schritte := 0        # gezählte Schrittklänge (für den Spieltest)
# Laufen: Der Sprint der Modelle (Running_A) wird mit dem Gehen zu einem Trab gemischt (actor.gd › trab_bauen):
# halb Laufen, halb Gehen, 0,7 s für zwei Schritte. Bei SPEED ergibt das etwa 2,9 Schritte je Sekunde zu 2,5 m (der Sprint
# hatte über 4 m und schwebte), der Fuß steht beim Aufsetzen still, ohne dass die Bewegung gebremst oder gehetzt wird.
const TRAB_ANTEIL := 0.5
const TRAB_DAUER := 0.7
const LAUF_TAKT := 0.9   # kleinstes Abspieltempo beim Laufen (actor.gd › fortbewegen)
var vel := Vector3.ZERO
var lantern: OmniLight3D
var aura: OmniLight3D
var want_dir := Vector3.ZERO   # Eingabe: Laufrichtung
var aim := Vector3.ZERO        # Eingabe: Punkt unter dem Mauszeiger
var neu3d := false             # Figur stammt aus der Figurenfabrik
var auto_aim := false          # die Fähigkeit kam von einem Knopf: Sprünge ohne Schaden weichen vom Gegner weg

func _ready() -> void:
	cls = Spiel.cls if Klassen.CLS.has(Spiel.cls) else "ermittler"
	C = Klassen.CLS[cls]
	ANIM = C.anim
	a_idle = ANIM.idle
	a_walk = ANIM.walk
	a_run = ANIM.run
	ORDER = Klassen.order(cls)
	for id in ORDER:
		SK[id] = Klassen.SK[id]
		cd[id] = 0.0
	# Werkstatt: Figur aus der Figurenfabrik (gleiche Knochen, gleiche Bewegungsnamen), sonst das bisherige Modell
	neu3d = true
	var modell: String = C.neu
	if true:
		# Nach der fünften Stunde hat Thot das Herz gewogen und dem Laternenträger das Tuch der Gewogenen umgelegt
		modell = C.neu_tuch if C.has("neu_tuch") and Geschichte.hat_tuch() else C.neu
	setup("res://models/chars/%s.glb" % modell, 1.12 if neu3d else 1.0, 0.55)
	a_run = trab_bauen("Trab", TRAB_ANTEIL, TRAB_DAUER)
	if modell == C.get("neu_tuch", ""):
		tuch_faerben(Geschichte.urteil_art())
	collision_layer = 2
	collision_mask = 1 | 4 | 32
	apply_stats(true)
	for n in Klassen.WEAPONS:
		if not C.keep.has(n):
			var c := model.find_child(n, true, false)
			if c:
				c.visible = false
	lantern = OmniLight3D.new()
	lantern.light_color = Color(1.0, 0.78, 0.48)
	lantern.light_energy = 3.2
	lantern.omni_range = 16.0 * Spiel.S.cone
	lantern.omni_attenuation = 1.3
	lantern.shadow_enabled = true
	# die neue Figur ist so groß wie ein Mensch: Die Laterne hängt höher, sonst blendet sie den Scheitel weiß
	lantern.position = Vector3(0, 3.5 if neu3d else 2.6, 0)
	# die Figur wirft im Licht ihrer eigenen Laterne keinen Schatten (sonst liegt ein dunkler Fleck um sie herum);
	# im Mondlicht schon. Dafür liegt sie auf Sichtebene 2, die die Laterne beim Schattenwurf auslässt.
	for m in meshes:
		m.layers = 2
	lantern.shadow_caster_mask = 0xFFFFF & ~2
	add_child(lantern)
	if neu3d:
		# Figurenlicht: Die Laterne hängt über dem Kopf und ließ das Haar weiß ausbrennen, während das Gesicht im Dunkeln lag.
		# Jetzt beleuchtet sie nur die Welt; die Figur bekommt ein eigenes warmes Licht von der Seite der Kamera
		# (Kamera steht schräg oben bei +x +z). Wie das Führungslicht beim Film, nur für den Helden.
		lantern.light_cull_mask = 0xFFFFF & ~2
		var fuehrung := OmniLight3D.new()
		fuehrung.light_color = Color(1.0, 0.8, 0.55)
		fuehrung.light_energy = 1.6
		fuehrung.omni_range = 5.5
		fuehrung.light_cull_mask = 2
		fuehrung.position = Vector3(1.6, 3.2, 1.6)
		add_child(fuehrung)
	aura = OmniLight3D.new()
	aura.light_color = Color(1.0, 0.85, 0.3)
	aura.light_energy = 0.0
	aura.omni_range = 7.0
	aura.position = Vector3(0, 1.2, 0)
	add_child(aura)
	var ear := AudioListener3D.new()
	ear.position = Vector3(0, 1.6, 0)
	add_child(ear)
	ear.make_current()
	play(ANIM.idle)

# Farbe des Tuchs nach dem Urteil: Die Kopftuch-Figur bringt Lapis und Gold mit; für „schwer“ und „schwebe“
# tauscht sie ihre Texturtafel gegen eine, in der nur das Tuch anders gestreift ist (models/chars/tuch_*.webp).
func tuch_faerben(art: String) -> void:
	var pfad := "res://models/chars/tuch_%s.webp" % art
	if art == "leicht" or not ResourceLoader.exists(pfad):
		return
	var tex: Texture2D = load(pfad)
	for mi in meshes:
		for i in mi.mesh.get_surface_count():
			var m = mi.get_active_material(i)
			if m is StandardMaterial3D:
				var d: StandardMaterial3D = m.duplicate()
				d.albedo_texture = tex
				if d.emission_enabled and d.emission_texture:
					d.emission_texture = tex
				mi.set_surface_override_material(i, d)

# Werte aus Stufe, Ausrüstung und Baum übernehmen. full: volles Leben
func apply_stats(full := false) -> void:
	var ratio := hp / max_hp if max_hp > 0.0 else 1.0
	max_hp = float(Spiel.S.max_hp)
	hp = max_hp if full else clampf(max_hp * ratio, 1.0, max_hp)
	if lantern:
		lantern.omni_range = 16.0 * Spiel.S.cone

func reach() -> float:
	return C.range

func ranged() -> bool:
	return C.basic == "shot" or C.basic == "spark"

# Schaden an einem Gegner nach 04-combat.js › hit: Krit, Lampe der Maat, Sonnenrichter, Eid, Speer des Seth, Lebensraub
func deal(f: Foe, mult: float, push := 6.0, stun_t := 0.0, gen := 0.0, loh := true) -> void:
	if f.state == Foe.St.DEAD:
		return
	var S: Dictionary = Spiel.S
	var crit: bool = randf() * 100.0 < S.crit
	var amt: float = S.dmg * mult * randf_range(0.9, 1.1) * ((1.0 + S.crit_dmg / 100.0) if crit else 1.0)
	if Spiel.has_leg("lantern"):
		var to := flat(f.global_position - global_position)
		if to.length() > 0.01 and forward().angle_to(to.normalized()) < 0.5:
			amt *= 1.25
	if Spiel.has_leg("sun") and f.K.get("undead", false):
		amt *= 1.6
	if oath_t > 0.0:
		amt *= 1.3
	if f.elite != "" or f.kind == "boss":
		amt *= 1.0 + 0.08 * Spiel.pas("jaeger")
	f.hit(amt, global_position, push, stun_t, crit)
	if crit and Spiel.has_leg("critres"):
		en = minf(100.0, en + 5.0)
	if loh and S.loh > 0.0 and not dead:
		hp = minf(max_hp, hp + S.loh)
	if gen > 0.0:
		en = minf(100.0, en + gen)

func _free_cast(id: String) -> bool:
	# Wort des Thot: die nächste Fähigkeit ist die fünfte
	return cls == "forensiker" and Spiel.has_key() and id != "potion" and (casts + 1) % 5 == 0

func cost_of(id: String) -> float:
	if _free_cast(id):
		return 0.0
	var c: float = SK[id].cost
	if id == ORDER[0] and Spiel.has_leg("s1"):
		c *= 0.5
	if Spiel.aug(id) == "eile":
		c *= 0.75
	return c

func cd_of(id: String) -> float:
	var c: float = SK[id].cd
	if (id == ORDER[1] and Spiel.has_leg("s2")) or (id == ORDER[3] and Spiel.has_leg("s4")):
		c *= 0.5
	if Spiel.aug(id) == "eile":
		c *= 0.75
	if SK[id].util:
		c *= 1.0 - 0.06 * maxi(0, Spiel.rank(id) - 1)
	return c

func _physics_process(delta: float) -> void:
	var _u := Time.get_ticks_usec()
	_physics_process_innen(delta)
	Protokoll.zeit("held", _u)

func _physics_process_innen(delta: float) -> void:
	tick_common(delta)
	if dead:
		return
	for k in cd:
		cd[k] = maxf(0.0, cd[k] - delta)
	en = minf(100.0, en + Spiel.S.regen * delta)
	skin_t -= delta
	inv -= delta
	oath_t -= delta
	if mantra_t > 0.0:
		mantra_t -= delta
		hp = minf(max_hp, hp + max_hp * 0.04 * delta)
	aura.light_energy = move_toward(aura.light_energy, 2.2 if oath_t > 0.0 or mantra_t > 0.0 else 0.0, delta * 6.0)
	lantern.light_energy = 3.2 + sin(Time.get_ticks_msec() * 0.011) * 0.12 + sin(Time.get_ticks_msec() * 0.023) * 0.06
	# geplante Treffer
	for i in range(pending.size() - 1, -1, -1):
		pending[i][0] -= delta
		if pending[i][0] <= 0.0:
			var f: Callable = pending[i][1]
			pending.remove_at(i)
			f.call()
	busy -= delta
	dodge_cd -= delta
	lunge = lunge.move_toward(Vector3.ZERO, delta * 26.0)
	if dash_t > 0.0:
		dash_t -= delta
		velocity = dash_dir * dash_speed
		move_and_slide()
		if dash_t <= 0.0:
			dash_speed = 30.0
			collision_mask = 1 | 4 | 32
			if dash_slam.y > 0.0:
				game.hero_slam(global_position, dash_slam.x, dash_slam.y, 9.0)
		turn(delta)
		return
	var target := Vector3.ZERO
	if busy <= 0.0 and stun <= 0.0:
		target = want_dir * SPEED * Spiel.S.speed
		if want_dir.length() > 0.1:
			face = atan2(want_dir.x, want_dir.z)
	vel = vel.move_toward(target, delta * (60.0 if target.length() > 0.1 else 80.0))
	velocity = vel + kb + lunge
	move_and_slide()
	global_position.y = 0.0
	turn(delta)
	if busy <= 0.0:
		var sp := vel.length()
		# Stehen, Gehen, Laufen: Abspieltempo nach der Schrittlänge, damit die Füße nicht rutschen (actor.gd)
		fortbewegen(sp, clampf(sp / SPEED, 0.5, 1.2) * 1.25, "", LAUF_TAKT)
		schrittklang(sp, delta)

# Ein Schritt ist zu hören: Klang nach dem Untergrund unter der Figur (main.gd › untergrund). laut_db: leiser beim Gehen.
func tritt(laut_db := 0.0) -> void:
	game.sfx.play("step_" + game.untergrund(global_position), 0.12, laut_db)   # Sand, Stein, Erde oder Glas

# Schrittklang genau dann, wenn ein Fuß aufsetzt, ganz gleich, welche Bewegung in welchem Tempo läuft: Je Fuß wird die
# Höhe von Knöchel und Ballen über dem eigenen tiefsten Stand gelesen (die Figur steht bei y = 0, die Bewegung
# schwebt aber knapp darüber oder taucht ein). Ein Tritt ist, wenn der Fuß von oben unter 6 cm über diesen Stand
# fällt; erst nach 12 cm kann er wieder abheben und neu aufsetzen (Spiel gegen Zittern), und je Fuß gilt 0,15 s
# Mindestabstand. Der tiefste Stand steigt langsam (3 cm/s), damit er sich dem Boden anpasst, wenn die Bewegung wechselt.
# Vorher lief ein fester Takt neben den Beinen her (0,31 s) und klang doppelt so schnell, wie die Füße gingen.
const TRITT_NAH := 0.06
const TRITT_HOCH := 0.12
func schrittklang(sp: float, delta: float) -> void:
	if step_ids.is_empty():
		for n in ["foot.l", "toes.l", "foot.r", "toes.r"]:
			step_ids.append(skel.find_bone(n) if skel else -1)
	if step_ids.has(-1):
		# Figur ohne Füße: der alte Takt
		if sp > 0.6:
			step_t -= delta * sp / SPEED
			if step_t <= 0.0:
				step_t = 0.31
				tritt()
		else:
			step_t = 0.1
		return
	var jetzt := Time.get_ticks_msec() / 1000.0
	var pause := jetzt - step_zeit
	var neu_ansetzen := pause > 0.1   # eine Pause (Hieb, Satz, Stand): ohne Klang neu ansetzen
	step_zeit = jetzt
	var gt := skel.global_transform
	var h := [0.0, 0.0]
	for i in 4:
		var y: float = (gt * skel.get_bone_global_pose(step_ids[i])).origin.y - global_position.y
		step_boden[i] = minf(y, step_boden[i] + 0.03 * minf(pause, 2.0))
		h[i / 2] = y - step_boden[i] if i % 2 == 0 else minf(h[i / 2], y - step_boden[i])
	for f in 2:
		step_sperre[f] -= delta
		if neu_ansetzen:
			step_unten[f] = h[f] < TRITT_NAH
		elif step_unten[f]:
			if h[f] > TRITT_HOCH:
				step_unten[f] = false
		elif h[f] < TRITT_NAH:
			step_unten[f] = true
			if step_sperre[f] <= 0.0 and sp > 0.6:
				step_sperre[f] = 0.15
				schritte += 1
				# Gehen leiser als Laufen
				tritt(lerpf(-4.0, 0.0, clampf((sp / SPEED - 0.3) / 0.5, 0.0, 1.0)))

# Ausweichschritt (Leertaste, am Handy der Knopf unten rechts): ein kurzer Satz in Laufrichtung, für einen Moment
# unverwundbar und durch Gegner hindurch. Bricht den eigenen Hieb ab.
func dodge() -> bool:
	if dead or dodge_cd > 0.0 or dash_t > 0.0 or stun > 0.0:
		return false
	var d := want_dir if want_dir.length() > 0.1 else forward()
	dash_dir = d.normalized()
	face = atan2(dash_dir.x, dash_dir.z)
	dash_speed = 15.0
	dash_t = 0.2
	dash_slam = Vector2.ZERO
	dodge_cd = 0.9
	busy = 0.0
	busy_basic = false
	lunge = Vector3.ZERO
	inv = maxf(inv, 0.38)
	collision_mask = 1 | 32
	play("Dodge_Forward", 1.9, 0.05, true)
	game.sfx.play("ausweichen", 0.1)
	return true

func can(id: String) -> bool:
	if dead or (busy > 0.0 and not busy_basic) or dash_t > 0.0 or stun > 0.0 or not cd.has(id) or cd[id] > 0.0:
		return false
	if not Spiel.gelernt(id):
		return false   # noch nicht im Fähigkeitenbaum gelernt
	if id == "potion":
		return pots > 0 and hp < max_hp
	if id == "hetz" and game.hetz_target(aim) == null:
		return false
	return en >= cost_of(id)

# ---------------------------------------------------------------- Standardangriff (04-combat.js › basicAttack)
func attack() -> bool:
	if dead or busy > 0.0 or dash_t > 0.0 or stun > 0.0:
		return false
	look_to(aim)
	busy_basic = true
	combo += 1
	hits += 1
	var heavy := Spiel.has_leg("heavy") and hits % 4 == 0
	var hm := (2.0 if heavy else 1.0) * (1.0 + 0.08 * Spiel.pas("hieb"))
	var st := 0.6 if heavy else 0.0
	var tempo: float = Spiel.S.rate / 1.75
	vel = Vector3.ZERO
	if C.basic == "melee" or C.basic == "combo":
		lunge = forward() * 3.4   # ein halber Schritt in den Hieb hinein
	match C.basic:
		"melee":
			var a: String = ANIM.atk_a if combo % 2 == 1 else ANIM.atk_b
			var sp := (2.1 if combo % 2 == 1 else 2.5) * tempo
			play(a, sp, 0.08, true)
			busy = anim_len(a) / sp * 0.78
			game.sfx.play("swing", 0.1)
			var m := (1.0 if combo % 2 == 1 else 1.25) * hm
			pending.append([anim_len(a) / sp * 0.42, func(): game.hero_arc(self, 3.3, 1.15, m, 6.0, true, st)])
		"combo":
			# Priester: jeder dritte Schlag weiter, härter, mit Rückstoß
			var third := combo % 3 == 0
			var a: String = ANIM.atk_c if third else (ANIM.atk_a if combo % 3 == 1 else ANIM.atk_b)
			var sp := (1.9 if third else 2.6) * tempo
			play(a, sp, 0.06, true)
			busy = anim_len(a) / sp * (0.7 if third else 0.6)
			game.sfx.play("swing", 0.1)
			var m := (1.9 if third else 1.0) * hm
			var r: float = C.range * (1.6 if third else 1.0)
			pending.append([anim_len(a) / sp * 0.4, func():
				game.hero_arc(self, r, 1.35 if third else 1.05, m, 6.0 if third else 3.0, true, st)
				if third:
					game.shake = maxf(game.shake, 0.15)
					if Spiel.has_key():
						en = minf(100.0, en + 10.0)
						hp = minf(max_hp, hp + max_hp * 0.02)])
		"shot":
			# Jägerin: Pfeil, durchschlägt nicht, +4 Instinkt beim ersten Treffer
			play(ANIM.atk_a, 2.2 * tempo, 0.06, true)
			busy = 0.8 / Spiel.S.rate
			game.sfx.play("swing", 0.1, -4.0)
			pending.append([0.1, func(): game.spawn_shot(self, forward(), {"speed": 28.8, "r": 0.16, "life": 0.6, "mult": hm, "pierce": 0, "col": Color(0.85, 1.0, 0.85), "gen": 4.0, "stun": st, "kind": "arrow"})])
		"spark":
			# Sternleserin: Funke, durchschlägt einmal
			play(ANIM.atk_a, 2.4 * tempo, 0.06, true)
			busy = 0.8 / Spiel.S.rate
			game.sfx.play("bolt", 0.1, -6.0)
			pending.append([0.12, func(): game.spawn_shot(self, forward(), {"speed": 21.6, "r": 0.24, "life": 0.7, "mult": 0.95 * hm, "pierce": 1, "col": Color(0.85, 0.6, 1.0), "gen": 4.0, "stun": st})])
	return true

# ---------------------------------------------------------------- Fähigkeiten (04-combat.js › cast)
func _jump(max_d: float, r: float, mult: float) -> void:
	# Sprung zum Ziel; ohne Schaden und vom Knopf aus weg vom nächsten Gegner (03 jump)
	var d := flat(aim - global_position)
	if auto_aim and mult <= 0.0:
		var near: Foe = game.foe_near(global_position, 7.0)
		if near:
			d = flat(global_position - near.global_position)
	if d.length() < 0.01:
		d = forward()
	look_to(global_position + d)
	var dist := clampf(d.length(), 2.4, max_d) if not (auto_aim and mult <= 0.0) else max_d
	dash_dir = d.normalized()
	dash_t = dist / 30.0
	dash_slam = Vector2(r, mult)
	inv = maxf(inv, dash_t + 0.45)
	collision_mask = 1 | 32
	play(ANIM.get(ORDER[1], "Dodge_Forward"), 1.6, 0.05, true)
	game.sfx.play("dash")

func _clamp_aim(max_d: float) -> Vector3:
	var d := flat(aim - global_position)
	if d.length() > max_d:
		d = d.normalized() * max_d
	return global_position + d

func cast(id: String) -> bool:
	if not can(id):
		return false
	var free := _free_cast(id)
	busy_basic = false
	busy = 0.0
	en -= cost_of(id)
	cd[id] = cd_of(id)
	if id != "potion":
		casts += 1
	var pw := Spiel.sk_pow(id) * (1.5 if free else 1.0)
	var upw := Spiel.sk_upw(id)
	if free:
		game.ring_fx(global_position, 1.6, Color(0.95, 0.82, 0.3))
		game.sfx.play("oath", 0.05, -6.0)
	match id:
		# Eidträger
		"whirl":
			play(ANIM.whirl, 2.0, 0.08, true)
			busy = 0.55
			vel = Vector3.ZERO
			game.sfx.play("whirl")
			pending.append([0.2, func(): game.hero_slam(global_position, 4.4, 1.7 * pw, 8.0); game.ring_fx(global_position, 4.4, Color(1.0, 0.72, 0.3))])
		"dash":
			_jump(13.0, 3.4, 1.4 * pw)
		"oath":
			play(ANIM.oath, 1.6, 0.1, true)
			busy = 0.5
			oath_t = 6.0 * upw
			game.sfx.play("oath")
			game.ring_fx(global_position, 3.0, Color(1.0, 0.85, 0.3))
		"udjat":
			play(ANIM.udjat, 1.8, 0.1, true)
			busy = 0.5
			vel = Vector3.ZERO
			game.sfx.play("udjat")
			pending.append([0.22, func(): game.hero_ring(global_position, 7.0, 2.2 * pw, 2.2, Color(0.78, 0.45, 0.95))])
		"beam":
			look_to(aim)
			play(ANIM.beam, 2.4, 0.08, true)
			busy = 0.32
			vel = Vector3.ZERO
			game.sfx.play("beam")
			pending.append([0.12, func(): game.hero_beam(self, 1.25 * pw)])
		# Priester des Schu
		"flurry":
			look_to(aim)
			busy = 0.62
			vel = Vector3.ZERO
			for i in 5:
				pending.append([0.11 * i, func():
					play(ANIM.flurry, 3.2, 0.03, true)
					game.sfx.play("swing", 0.15, -3.0)
					game.hero_arc(self, 3.7, 0.9, 0.62 * pw, 1.2, false)])
		"step":
			_jump(10.0, 3.0, 1.1 * pw)
		"mantra":
			play(ANIM.mantra, 1.6, 0.1, true)
			busy = 0.45
			mantra_t = 7.0 * upw
			game.sfx.play("oath")
			game.ring_fx(global_position, 7.2, Color(0.94, 0.9, 0.8))
		"palm":
			look_to(aim)
			play(ANIM.palm, 1.8, 0.06, true)
			busy = 0.45
			vel = Vector3.ZERO
			game.sfx.play("whirl")
			pending.append([0.18, func(): game.hero_cone(self, 6.0, 0.95, 3.2 * pw, 8.0, 0.5, 6.0)])
		"wave":
			look_to(aim)
			play(ANIM.wave, 2.2, 0.06, true)
			busy = 0.35
			vel = Vector3.ZERO
			game.sfx.play("beam", 0.1, -2.0)
			pending.append([0.1, func(): game.spawn_shot(self, forward(), {"speed": 20.8, "r": 0.64, "life": 0.42, "mult": 2.0 * pw, "pierce": -1, "col": Color(0.92, 0.95, 1.0, 0.7), "push": 9.0, "kind": "wave"})])
		# Wüstenjägerin
		"salve":
			look_to(aim)
			play(ANIM.salve, 2.4, 0.06, true)
			busy = 0.35
			vel = Vector3.ZERO
			game.sfx.play("swing", 0.1)
			pending.append([0.1, func():
				for off in [-0.36, -0.18, 0.0, 0.18, 0.36]:
					var a: float = face + off
					game.spawn_shot(self, Vector3(sin(a), 0, cos(a)), {"speed": 28.0, "r": 0.16, "life": 0.6, "mult": 1.15 * pw, "pierce": 0, "col": Color(0.6, 0.95, 0.65), "kind": "arrow"})])
		"roll":
			_jump(9.2 * upw, 0.0, 0.0)
		"hetz":
			look_to(aim)
			play(ANIM.hetz, 1.8, 0.1, true)
			busy = 0.3
			game.sfx.play("udjat", 0.1, -4.0)
			game.pet_hetz(aim, pw)
		"rain":
			var c := _clamp_aim(16.8)
			look_to(c)
			play(ANIM.rain, 2.0, 0.06, true)
			busy = 0.35
			vel = Vector3.ZERO
			game.sfx.play("swing", 0.1)
			game.add_zone(c, 5.0, 3.2, 0.35, 0.85 * pw, 0.0, Color(0.6, 0.95, 0.65))
		"pierce":
			look_to(aim)
			play(ANIM.pierce, 2.0, 0.06, true)
			busy = 0.4
			vel = Vector3.ZERO
			game.sfx.play("bolt")
			game.shake = maxf(game.shake, 0.12)
			pending.append([0.12, func(): game.spawn_shot(self, forward(), {"speed": 34.4, "r": 0.32, "life": 0.8, "mult": 3.2 * pw, "pierce": -1, "col": Color(0.9, 1.0, 0.9), "push": 4.0, "kind": "arrow"})])
		# Sternleserin
		"chain":
			look_to(aim)
			play(ANIM.chain, 2.6, 0.06, true)
			busy = 0.3
			vel = Vector3.ZERO
			pending.append([0.1, func(): game.hero_chain(self, aim, 1.6 * pw)])
		"blink":
			_blink(13.2 * upw)
		"glass":
			var c := _clamp_aim(17.6)
			look_to(c)
			play(ANIM.glass, 1.8, 0.08, true)
			busy = 0.4
			vel = Vector3.ZERO
			game.sfx.play("udjat", 0.1, -6.0)
			game.add_zone(c, 5.6, 5.0 * upw, 0.5, 0.35 * (1.0 + 0.12 * maxi(0, Spiel.rank(id) - 1)), 1.0, Color(0.56, 0.89, 0.88))
		"nova":
			play(ANIM.nova, 1.8, 0.08, true)
			busy = 0.45
			vel = Vector3.ZERO
			game.sfx.play("udjat")
			pending.append([0.2, func(): game.hero_ring(global_position, 8.4, 1.8 * pw, 2.6, Color(0.56, 0.89, 0.88))])
		"meteor":
			var c := _clamp_aim(18.4)
			look_to(c)
			play(ANIM.meteor, 2.0, 0.08, true)
			busy = 0.45
			vel = Vector3.ZERO
			game.sfx.play("bolt", 0.1, -2.0)
			game.meteor(c, 4.6, 4.5 * pw)
		"potion":
			pots -= 1
			hp = minf(max_hp, hp + max_hp * (1.0 if Spiel.has_leg("potion") else 0.6))
			play(ANIM.potion, 1.8, 0.1, true)
			busy = 0.45
			game.sfx.play("potion")
			game.float_text(global_position, "+ Rotbier", Color(0.5, 0.9, 0.55))
	return true

func _blink(max_d: float) -> void:
	# Schritt durch die Duat: sofort versetzt, endet vor Mauern
	var d := flat(aim - global_position)
	if auto_aim:
		var near: Foe = game.foe_near(global_position, 7.0)
		if near:
			d = flat(global_position - near.global_position).normalized() * max_d
	if d.length() < 0.01:
		d = forward() * max_d
	if d.length() > max_d:
		d = d.normalized() * max_d
	var to := global_position
	var steps := int(d.length() / 0.5)
	for i in range(1, steps + 1):
		var p := global_position + d * (float(i) / steps)
		if not game.walkable(global_position, p):
			break
		to = p
	game.ring_fx(global_position, 1.4, Color(0.75, 0.42, 0.88))
	global_position = to
	look_to(global_position + d)
	model.rotation.y = face
	inv = maxf(inv, 0.3)
	game.ring_fx(global_position, 1.4, Color(0.75, 0.42, 0.88))
	game.sfx.play("dash", 0.1, -2.0)

# Erlittener Schaden nach 04-combat.js › hurt: Haut des Mehen, Dornen, Rüstung und Klasse, Eid, Kreis des Ka, Wahr an Stimme
func hurt(amount: float, from: Vector3, src: Foe = null) -> void:
	if dead or inv > 0.0:
		return
	if Spiel.has_leg("skin") and skin_t <= 0.0:
		skin_t = 8.0
		game.float_text(global_position, "abgeprallt", Color(0.6, 0.9, 1.0))
		game.sfx.play("ui", 0.05)
		return
	if src and Spiel.S.thorns > 0.0 and src.state != Foe.St.DEAD:
		src.hit(Spiel.S.thorns, global_position, 0.0)
	var a: float = amount * (1.0 - Spiel.S.red) * randf_range(0.9, 1.1)
	if oath_t > 0.0:
		a *= 0.8
	if mantra_t > 0.0:
		a *= 0.7
	if cls == "ermittler" and Spiel.has_key() and hp < max_hp * 0.35:
		a *= 0.7
	hp -= a
	flash()
	zucken(from, 1.0 + 4.0 * a / max_hp)
	if a >= max_hp * 0.2:
		game.trefferstopp()   # schwerer Treffer: kurzer Trefferstopp
	kb += flat(global_position - from).normalized() * 4.0
	game.shake = maxf(game.shake, 0.35)
	game.sfx.play("hurt", 0.1)
	game.float_text(global_position, str(int(round(a))), Color(1.0, 0.42, 0.36))
	if hp <= 0.0:
		hp = 0.0
		dead = true
		pending.clear()
		play(ANIM.death, 1.0, 0.1, true)
		game.sfx.play("hero_die")
		game.on_hero_dead()

func revive(pos: Vector3) -> void:
	dead = false
	hp = max_hp
	en = 60.0
	inv = 2.5
	pots = maxi(pots, 2)
	busy = 0.0
	stun = 0.0
	oath_t = 0.0
	mantra_t = 0.0
	kb = Vector3.ZERO
	vel = Vector3.ZERO
	global_position = pos
	play(ANIM.idle, 1.0, 0.0, true)
	reset_physics_interpolation()   # nicht vom Ort der Niederlage herübergleiten
