class_name Hero extends Actor
# Der Eidträger: Zweihänder, Laterne mit dem Funken des Re. Werte und Fähigkeiten stammen aus der Webfassung.

const ANIM := {
	"idle": "2H_Melee_Idle", "run": "Running_A", "atk_a": "2H_Melee_Attack_Slice", "atk_b": "2H_Melee_Attack_Chop",
	"whirl": "2H_Melee_Attack_Spin", "dash": "Dodge_Forward", "oath": "Cheer", "udjat": "Spellcast_Raise",
	"beam": "Spellcast_Shoot", "potion": "Use_Item", "hit": "Hit_A", "death": "Death_A",
}
const SPEED := 6.4
const SKILLS := {
	"whirl": {"name": "Falkenkreis", "key": "1", "cost": 25, "cd": 0.5, "txt": "Rundumschlag um dich herum."},
	"dash": {"name": "Sturz des Falken", "key": "2", "cost": 0, "cd": 5.0, "txt": "Sprung zum Ziel mit Aufprall."},
	"oath": {"name": "Eid der Maat", "key": "3", "cost": 0, "cd": 18.0, "txt": "6 Sekunden mehr Schaden, weniger erlittener Schaden."},
	"udjat": {"name": "Blick des Udjat", "key": "4", "cost": 0, "cd": 14.0, "txt": "Betäubt alles im Umkreis und löscht Geschosse."},
	"beam": {"name": "Strahl des Re", "key": "RM", "cost": 14, "cd": 0.35, "txt": "Licht aus der Laterne, das mehrere Gegner durchschlägt."},
	"potion": {"name": "Rotbier der Sachmet", "key": "Q", "cost": 0, "cd": 1.0, "txt": "Heilt dich."},
}
const ORDER := ["whirl", "dash", "oath", "udjat", "beam", "potion"]

var en := 60.0
var pots: int:   # Rotbier gehört zur Figur und überdauert den Neustart einer Stunde
	get: return Spiel.pots
	set(v): Spiel.pots = v
var hits := 0            # Standardangriffe gezählt (Fäuste des Namenlosen: jeder vierte trifft doppelt)
var skin_t := 0.0        # Haut des Mehen: bis zum nächsten abgeprallten Treffer
var cd := {}
var busy := 0.0          # so lange läuft eine Aktion, die das Laufen sperrt
var pending: Array = []  # geplante Treffer: [Zeit, Callable]
var combo := 0
var oath_t := 0.0
var inv := 1.5
var dash_t := 0.0
var dash_dir := Vector3.ZERO
var step_t := 0.0
var vel := Vector3.ZERO
var lantern: OmniLight3D
var aura: OmniLight3D
var want_dir := Vector3.ZERO   # Eingabe: Laufrichtung
var aim := Vector3.ZERO        # Eingabe: Punkt unter dem Mauszeiger
var base_dmg := 13.0

func _ready() -> void:
	setup("res://models/chars/Knight.glb", 1.0, 0.55)
	collision_layer = 2
	collision_mask = 1 | 4
	apply_stats(true)
	# nur der Zweihänder bleibt in der Hand
	for n in ["1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Round_Shield", "Spike_Shield", "1H_Sword"]:
		var c := model.find_child(n, true, false)
		if c:
			c.visible = false
	lantern = OmniLight3D.new()
	lantern.light_color = Color(1.0, 0.78, 0.48)
	lantern.light_energy = 3.2
	lantern.omni_range = 16.0
	lantern.omni_attenuation = 1.3
	lantern.shadow_enabled = true
	lantern.position = Vector3(0, 2.6, 0)
	add_child(lantern)
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
	for k in ORDER:
		cd[k] = 0.0
	play(ANIM.idle)

# Werte aus Stufe und Ausrüstung übernehmen (nach Anlegen, Aufwerten, Stufenaufstieg). full: volles Leben
func apply_stats(full := false) -> void:
	var ratio := hp / max_hp if max_hp > 0.0 else 1.0
	max_hp = float(Spiel.S.max_hp)
	hp = max_hp if full else clampf(max_hp * ratio, 1.0, max_hp)
	if lantern:
		lantern.omni_range = 16.0 * Spiel.S.cone

# Schaden an einem Gegner nach 04-combat.js › hit: Krit, Lampe der Maat, Sonnenrichter, Eid, Lebensraub, Harpune des Horus
func deal(f: Foe, mult: float, push := 6.0, stun_t := 0.0, gen := 0.0) -> void:
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
	f.hit(amt, global_position, push, stun_t, crit)
	if crit and Spiel.has_leg("critres"):
		en = minf(100.0, en + 5.0)
	if S.loh > 0.0 and not dead:
		hp = minf(max_hp, hp + S.loh)
	if gen > 0.0:
		en = minf(100.0, en + gen)

func cost_of(id: String) -> float:
	var c: float = SKILLS[id].cost
	return c * 0.5 if id == ORDER[0] and Spiel.has_leg("s1") else c

func cd_of(id: String) -> float:
	var c: float = SKILLS[id].cd
	if (id == ORDER[1] and Spiel.has_leg("s2")) or (id == ORDER[3] and Spiel.has_leg("s4")):
		return c * 0.5
	return c

func _physics_process(delta: float) -> void:
	tick_common(delta)
	if dead:
		return
	for k in cd:
		cd[k] = maxf(0.0, cd[k] - delta)
	en = minf(100.0, en + Spiel.S.regen * delta)
	skin_t -= delta
	inv -= delta
	oath_t -= delta
	aura.light_energy = move_toward(aura.light_energy, 2.2 if oath_t > 0.0 else 0.0, delta * 6.0)
	lantern.light_energy = 3.2 + sin(Time.get_ticks_msec() * 0.011) * 0.12 + sin(Time.get_ticks_msec() * 0.023) * 0.06
	# geplante Treffer
	for i in range(pending.size() - 1, -1, -1):
		pending[i][0] -= delta
		if pending[i][0] <= 0.0:
			var f: Callable = pending[i][1]
			pending.remove_at(i)
			f.call()
	busy -= delta
	if dash_t > 0.0:
		dash_t -= delta
		velocity = dash_dir * 30.0
		move_and_slide()
		if dash_t <= 0.0:
			collision_mask = 1 | 4
			game.hero_slam(global_position, 3.4, 1.4, 9.0)
		turn(delta)
		return
	var target := Vector3.ZERO
	if busy <= 0.0 and stun <= 0.0:
		target = want_dir * SPEED * Spiel.S.speed
		if want_dir.length() > 0.1:
			face = atan2(want_dir.x, want_dir.z)
	vel = vel.move_toward(target, delta * (60.0 if target.length() > 0.1 else 80.0))
	velocity = vel + kb
	move_and_slide()
	global_position.y = 0.0
	turn(delta)
	if busy <= 0.0:
		var sp := vel.length()
		if sp > 0.6:
			play(ANIM.run, clampf(sp / SPEED, 0.5, 1.2) * 1.25)
			step_t -= delta * sp / SPEED
			if step_t <= 0.0:
				step_t = 0.31
				game.sfx.play("step", 0.12)
		else:
			play(ANIM.idle)
			step_t = 0.1

func can(id: String) -> bool:
	if dead or busy > 0.0 or dash_t > 0.0 or stun > 0.0 or cd[id] > 0.0:
		return false
	if id == "potion":
		return pots > 0 and hp < max_hp
	return en >= cost_of(id)

func attack() -> bool:
	# Standardangriff: abwechselnd Schnitt und Hieb, trifft im Bogen vor der Figur
	if dead or busy > 0.0 or dash_t > 0.0 or stun > 0.0:
		return false
	look_to(aim)
	combo += 1
	hits += 1
	var heavy := Spiel.has_leg("heavy") and hits % 4 == 0
	var a: String = ANIM.atk_a if combo % 2 == 1 else ANIM.atk_b
	var tempo: float = Spiel.S.rate / 1.75
	var sp := (2.1 if combo % 2 == 1 else 2.5) * tempo
	play(a, sp, 0.08, true)
	busy = anim_len(a) / sp * 0.78
	vel = Vector3.ZERO
	game.sfx.play("swing", 0.1)
	var m := (1.0 if combo % 2 == 1 else 1.25) * (2.0 if heavy else 1.0)
	pending.append([anim_len(a) / sp * 0.42, func(): game.hero_arc(self, 3.3, 1.15, m, 6.0, true, 0.6 if heavy else 0.0)])
	return true

func cast(id: String) -> bool:
	if not can(id):
		return false
	en -= cost_of(id)
	cd[id] = cd_of(id)
	match id:
		"whirl":
			play(ANIM.whirl, 2.0, 0.08, true)
			busy = 0.55
			vel = Vector3.ZERO
			game.sfx.play("whirl")
			pending.append([0.2, func(): game.hero_slam(global_position, 4.4, 1.7, 8.0); game.ring_fx(global_position, 4.4, Color(1.0, 0.72, 0.3))])
		"dash":
			look_to(aim)
			var d := flat(aim - global_position)
			var dist := clampf(d.length(), 3.0, 13.0)
			dash_dir = forward()
			dash_t = dist / 30.0
			inv = maxf(inv, dash_t + 0.25)
			collision_mask = 1
			play(ANIM.dash, 1.6, 0.05, true)
			game.sfx.play("dash")
		"oath":
			play(ANIM.oath, 1.6, 0.1, true)
			busy = 0.5
			oath_t = 6.0
			game.sfx.play("oath")
			game.ring_fx(global_position, 3.0, Color(1.0, 0.85, 0.3))
		"udjat":
			play(ANIM.udjat, 1.8, 0.1, true)
			busy = 0.5
			vel = Vector3.ZERO
			game.sfx.play("udjat")
			pending.append([0.22, func(): game.hero_udjat(global_position, 7.0)])
		"beam":
			look_to(aim)
			play(ANIM.beam, 2.4, 0.08, true)
			busy = 0.32
			vel = Vector3.ZERO
			game.sfx.play("beam")
			pending.append([0.12, func(): game.hero_beam(self)])
		"potion":
			pots -= 1
			hp = minf(max_hp, hp + max_hp * (1.0 if Spiel.has_leg("potion") else 0.6))
			play(ANIM.potion, 1.8, 0.1, true)
			busy = 0.45
			game.sfx.play("potion")
			game.float_text(global_position, "+ Rotbier", Color(0.5, 0.9, 0.55))
	return true

# Erlittener Schaden nach 04-combat.js › hurt: Haut des Mehen, Dornen, Rüstung und Klasse, Eid der Maat
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
	var a: float = amount * (1.0 - Spiel.S.red) * randf_range(0.9, 1.1) * (0.8 if oath_t > 0.0 else 1.0)
	hp -= a
	flash()
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
	kb = Vector3.ZERO
	vel = Vector3.ZERO
	global_position = pos
	play(ANIM.idle, 1.0, 0.0, true)
