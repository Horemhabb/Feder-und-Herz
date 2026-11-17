extends Node3D
# Schaukasten der Werkstatt (Fassung 2.3): eine kleine Kammer im Tempel, in der die Figuren aus der Figurenfabrik stehen.
# Hier lassen sich alle Helden und Gegner mit allen Bewegungen durchschalten und der Held frei bewegen.
# Start: Knopf „Werkstatt“ auf dem Titelbild oder „-- --schau“. Prüfbilder: „-- --schau --schau-bild=<Ordner>“.

const BEWEGUNGEN := [["Stehen", true], ["Gehen", true], ["Laufen", true], ["Angriff", false], ["Schwerer Angriff", false], ["Treffer", false],
	["Ausweichen", false], ["Tod", false], ["Besondere Fähigkeit", false]]
# Name, Modell, die neun Bewegungen in der Reihenfolge von BEWEGUNGEN
const HELDEN := [
	["Eidträger", "Eidtraeger", ["2H_Melee_Idle", "Walking_A", "Running_A", "2H_Melee_Attack_Slice", "2H_Melee_Attack_Chop", "Hit_A", "Dodge_Forward", "Death_A", "2H_Melee_Attack_Spin"]],
	["Priester des Schu", "Priester", ["Unarmed_Idle", "Walking_A", "Running_A", "Unarmed_Melee_Attack_Punch_A", "Unarmed_Melee_Attack_Kick", "Hit_A", "Dodge_Forward", "Death_A", "Spellcast_Raise"]],
	["Wüstenjägerin", "Jaegerin", ["2H_Ranged_Aiming", "Walking_A", "Running_A", "2H_Ranged_Shoot", "2H_Ranged_Shooting", "Hit_A", "Dodge_Forward", "Death_A", "Interact"]],
	["Sternleserin", "Sternleserin", ["Idle", "Walking_A", "Running_A", "Spellcast_Shoot", "Spellcast_Long", "Hit_A", "Dodge_Forward", "Death_A", "Spellcast_Raise"]],
]
const FEIND_BEW := ["Idle_Combat", "Walking_D_Skeletons", "Running_A", "1H_Melee_Attack_Chop", "2H_Melee_Attack_Chop", "Hit_A", "Spellcast_Shoot", "Death_C_Skeletons", "Spellcast_Summon"]
const FEINDE := [["Herzloser", "Hohler", 1.0], ["Ruheloser", "Ruheloser", 1.0], ["Sebau-Krieger", "Krieger", 1.0], ["Sebau-Priesterin", "Priesterin", 1.0],
	["Sebau-Koloss", "Koloss", 1.3], ["Erloschener", "Erloschener", 1.0]]
const SCHLEIFEN := ["2H_Melee_Idle", "Idle_Combat", "Idle", "Unarmed_Idle", "2H_Ranged_Aiming", "Walking_A", "Walking_D_Skeletons", "Running_A"]
const SURF := {"sandstein": ["w01_sandstein", 6.0, Color(1.0, 0.93, 0.80)], "granit": ["w02_granit", 6.0, Color(0.85, 0.85, 0.92)],
	"pflaster": ["t06_pflaster", 4.0, Color(0.95, 0.88, 0.78)], "sand": ["t09_sand", 6.0, Color(0.85, 0.78, 0.68)]}
const PLATZ_HELD := Vector3(-2.3, 0.18, 0.2)
const PLATZ_FEIND := Vector3(2.3, 0.18, 0.2)

# das braucht Deko von seinem Spielknoten
var mats := {}
var torches: Array = []
var lichter: Array = []

var held: Node3D
var feind: Node3D
var hi := 0               # welcher Held, welcher Gegner
var fi := 0
var cam: Camera3D
var laterne: OmniLight3D
var bew := 0
var pause_t := 0.0
var tuch := ""            # Tuch der Gewogenen: "" (keins), "leicht", "schwer", "schwebe"
const TUCH_NAME := {"": "aus", "leicht": "Lapis und Gold", "schwer": "Rot und Schwarz", "schwebe": "Leinen und Silber"}
var frei := false
var dreht := true
var ziel := 0             # Kamera: 0 Überblick, 1 Eidträger, 2 Herzloser
var t := 0.0
var winkel := 0.0
var cam_mitte := Vector3(0, 1.4, -0.3)
var cam_weit := 10.5
var l_bew: Label
var l_info: Label
var knoepfe := {}
var blick := 0.0          # Blickrichtung der Figur im freien Lauf
var busy := 0.0
var f_text: FontFile
var f_fett: FontFile

func surf(name: String) -> StandardMaterial3D:
	if mats.has(name):
		return mats[name]
	var d: Array = SURF[name]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://textures/%s.jpg" % d[0])
	m.albedo_color = d[2]
	var np := "res://textures/%s_n.jpg" % d[0]
	if ResourceLoader.exists(np):
		m.normal_enabled = true
		m.normal_texture = load(np)
		m.normal_scale = 0.9
	m.roughness = 0.93
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.set_meta("period", d[1])
	mats[name] = m
	return m

func _ready() -> void:
	get_tree().paused = false
	# Hier bewegt nichts die Physik. Zwischenbilder (im Projekt eingeschaltet) würden nur stören: Funken der Feuerschalen
	# zogen im Browser als Strich von Schale zu Schale. Wie im Spiel: aus für alles, was unter diesem Knoten hängt.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	f_text = load("res://ui/fonts/almendra.woff")
	f_fett = load("res://ui/fonts/almendra_fett.woff")
	_licht()
	_kammer()
	_figuren()
	_anzeige()
	cam = Camera3D.new()
	cam.fov = 38.0
	add_child(cam)
	cam.make_current()
	_zeige(0)
	_kamera(0.0, true)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--schau-bild="):
			_pruefbilder(a.get_slice("=", 1))

func _licht() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.012, 0.022)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.46, 0.44, 0.62)
	env.ambient_light_energy = 0.26
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.07, 0.065, 0.09)
	env.fog_density = 0.022
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.18
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.15
	env.adjustment_contrast = 1.06
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	# das Licht, das durch die Öffnung in der Decke fällt (dieselbe Richtung wie der gemalte Strahl)
	var sonne := DirectionalLight3D.new()
	sonne.rotation_degrees = Vector3(-62, -24, 0)
	sonne.light_color = Color(1.0, 0.86, 0.62)
	sonne.light_energy = 0.34
	sonne.shadow_enabled = true
	sonne.directional_shadow_max_distance = 40.0
	add_child(sonne)

func _wand(pos: Vector3, groesse: Vector3) -> void:
	var st := Deko._begin()
	Deko.box(st, groesse, Vector3.ZERO)
	Deko._put(self, Deko._commit([[st, Deko.stone(self, "wand", "sandstein", Color(0.7, 0.62, 0.54))]]), pos)

func _kammer() -> void:
	var boden := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(26, 20)
	boden.mesh = pm
	var bm: StandardMaterial3D = surf("pflaster").duplicate()
	bm.uv1_scale = Vector3(6.5, 5.0, 1)
	bm.albedo_color = Color(0.7, 0.66, 0.6)
	boden.material_override = bm
	add_child(boden)
	_wand(Vector3(0, 0, -7.6), Vector3(20, 6.5, 1.0))
	_wand(Vector3(-10.2, 0, -1), Vector3(1.0, 6.5, 14))
	_wand(Vector3(10.2, 0, -1), Vector3(1.0, 6.5, 14))
	# Sockelstufe vor der Rückwand und zwei runde Podeste für die Figuren
	_wand(Vector3(0, 0, -5.4), Vector3(9, 0.3, 3.4))
	for p in [PLATZ_HELD, PLATZ_FEIND]:
		var c := CylinderMesh.new()
		c.top_radius = 1.25
		c.bottom_radius = 1.4
		c.height = 0.18
		c.radial_segments = 24
		c.rings = 1
		Deko._put(self, c, Vector3(p.x, 0.09, p.z)).material_override = Deko.stone(self, "dunkel", "granit", Color(0.8, 0.8, 0.9))
	for x in [-6.6, -3.3, 3.3, 6.6]:
		Stimmung.saeule(self, Vector3(x, 0, -5.6), 5.6, 0.46)
	for x in [-8.4, 8.4]:
		Stimmung.saeule(self, Vector3(x, 0, 2.6), 5.6, 0.46)
	Deko.sarkophag(self, Vector3(0, 0.3, -5.3), PI * 0.5)
	Deko.anubis(self, Vector3(-5.0, 0, -2.6), PI * 0.22)
	Deko.anubis(self, Vector3(5.0, 0, -2.6), -PI * 0.22)
	Deko.becken(self, Vector3(-6.4, 0, 2.2), 1.15)
	for x in [-8.2, 8.2]:
		# Feuerschale mit Shader-Flamme statt Funken-Partikeln (die zeichnete der Software-Browser der Prüfumgebung falsch)
		var s := Deko.feuerschale(self, Vector3(x, 0, -2.4))
		s.coal.material_override = Deko.mat("kohle_glut", Color(1.0, 0.5, 0.15), 1.0, Color(1.0, 0.45, 0.1), 2.5)
		Stimmung.flamme(s.n, Vector3(0, 1.2, 0), 1.3, 1.1)
		var fl := OmniLight3D.new()
		fl.light_color = Color(1.0, 0.66, 0.32)
		fl.omni_range = 17.0
		fl.omni_attenuation = 1.1
		s.n.add_child(fl)
		fl.position = Vector3(0, 2.6, 0)
		torches.append({"l": fl, "ph": randf() * 10.0, "e": 3.0})
	# Atmosphäre: alles Illusion, nichts davon rechnet der Renderer als Volumen
	Stimmung.lichtstrahl(self, Vector3(0.4, 0, -4.6), 9.5, 3.4, Color(1.0, 0.84, 0.56), 0.5, 0.2, 0.4)
	Stimmung.lichtstrahl(self, Vector3(-1.6, 0, -3.9), 9.0, 1.6, Color(1.0, 0.84, 0.56), 0.3, 0.2, 0.4)
	Stimmung.staub(self, Vector3(-0.4, 3.2, -4.4), Vector3(4.5, 6.4, 3.5))
	Stimmung.nebel(self, Vector3(0, 0, -1.5), 22.0, Color(0.55, 0.6, 0.8), 0.3, 0.28)
	Stimmung.nebel(self, Vector3(1.5, 0, 0.5), 16.0, Color(0.7, 0.66, 0.6), 0.22, 0.5).rotation.y = 1.3
	Stimmung.runenkreis(self, Vector3(PLATZ_HELD.x, 0.0, PLATZ_HELD.z), 2.3, Color(1.0, 0.72, 0.28), 0.8)
	Stimmung.runenkreis(self, Vector3(PLATZ_FEIND.x, 0.0, PLATZ_FEIND.z), 2.3, Color(0.45, 0.75, 1.0), 0.8)
	Stimmung.fries(self, Vector3(0, 3.7, -7.07), 15.0, 0.95, Color(1.0, 0.7, 0.26), 0.7)
	Stimmung.fries(self, Vector3(0, 1.5, -7.07), 15.0, 0.6, Color(0.3, 0.85, 0.8), 0.45, 0.0, ["wave", "blink", "salve", "roll", "pierce", "flurry", "palm", "step", "whirl", "dash"])

func _lade(name: String, pos: Vector3, toenung := Color.WHITE) -> Node3D:
	var m: Node3D = load("res://models/chars/%s.glb" % name).instantiate()
	add_child(m)
	m.position = pos
	var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	for n in SCHLEIFEN:
		if ap.has_animation(n):
			ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	for w in Klassen.WEAPONS:
		if w != "2H_Sword":
			var c := m.find_child(w, true, false)
			if c:
				c.visible = false
	if toenung != Color.WHITE:
		for mi in m.find_children("*", "MeshInstance3D", true, false):
			for i in mi.mesh.get_surface_count():
				var mat = mi.get_active_material(i)
				if mat is StandardMaterial3D:
					var d: StandardMaterial3D = mat.duplicate()
					d.albedo_color = d.albedo_color * toenung
					mi.set_surface_override_material(i, d)
	return m

func _figuren() -> void:
	held = _lade("Eidtraeger", PLATZ_HELD)
	feind = _lade("Hohler", PLATZ_FEIND)
	feind.rotation.y = -0.5
	held.rotation.y = 0.5
	# die Laterne des Eidträgers, wie im Spiel
	laterne = OmniLight3D.new()
	laterne.light_color = Color(1.0, 0.78, 0.48)
	laterne.light_energy = 1.5
	laterne.omni_range = 8.0
	laterne.omni_attenuation = 1.3
	held.add_child(laterne)
	laterne.position = Vector3(0.9, 2.0, 1.3)
	var kalt := OmniLight3D.new()
	kalt.light_color = Color(0.55, 0.75, 1.0)
	kalt.light_energy = 1.3
	kalt.omni_range = 5.0
	feind.add_child(kalt)
	kalt.position = Vector3(0, 1.8, 0.7)

func _ap(n: Node3D) -> AnimationPlayer:
	return n.find_child("AnimationPlayer", true, false)

func _spiele(n: Node3D, name: String) -> void:
	var ap := _ap(n)
	if ap.has_animation(name):
		ap.play(name, 0.15)
		ap.seek(0.0, true)

func _zeige(i: int) -> void:
	bew = posmod(i, BEWEGUNGEN.size())
	var b: Array = BEWEGUNGEN[bew]
	pause_t = 0.0
	if not frei:
		_spiele(held, HELDEN[hi][2][bew])
	_spiele(feind, FEIND_BEW[bew])
	if l_bew:
		l_bew.text = "%s  ·  %d von %d" % [b[0], bew + 1, BEWEGUNGEN.size()]

func _knopf(text: String, tu: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", f_text)
	b.add_theme_font_size_override("font_size", 19)
	b.custom_minimum_size = Vector2(0, 46)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.075, 0.06, 0.88)
	sb.border_color = Color("c9a04a")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	var hb: StyleBoxFlat = sb.duplicate()
	hb.bg_color = Color(0.2, 0.15, 0.08, 0.95)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hb)
	b.add_theme_stylebox_override("pressed", hb)
	b.add_theme_color_override("font_color", Color("efe6cf"))
	b.pressed.connect(tu)
	return b

func _anzeige() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	var oben := VBoxContainer.new()
	oben.position = Vector2(24, 18)
	cl.add_child(oben)
	var titel := Label.new()
	titel.text = "Werkstatt · Figurenfabrik"
	titel.add_theme_font_override("font", f_fett)
	titel.add_theme_font_size_override("font_size", 30)
	titel.add_theme_color_override("font_color", Color("e8c070"))
	oben.add_child(titel)
	l_info = Label.new()
	l_info.text = "Vier Helden und sechs Gegner aus der Figurenfabrik, je 2.100 bis 3.700 Dreiecke.
Alle stehen auf demselben Skelett. Körper, Tracht und Texturen baut ein Skript aus einem Bauplan und dem gemalten Bogen."
	l_info.add_theme_font_override("font", f_text)
	l_info.add_theme_font_size_override("font_size", 16)
	l_info.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7, 0.85))
	oben.add_child(l_info)
	var unten := VBoxContainer.new()
	unten.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	unten.grow_vertical = Control.GROW_DIRECTION_BEGIN
	unten.offset_bottom = -16
	unten.alignment = BoxContainer.ALIGNMENT_END
	cl.add_child(unten)
	l_bew = Label.new()
	l_bew.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_bew.add_theme_font_override("font", f_fett)
	l_bew.add_theme_font_size_override("font_size", 24)
	l_bew.add_theme_color_override("font_color", Color("efe6cf"))
	unten.add_child(l_bew)
	var reihe := HFlowContainer.new()
	reihe.alignment = FlowContainer.ALIGNMENT_CENTER
	reihe.add_theme_constant_override("h_separation", 8)
	reihe.add_theme_constant_override("v_separation", 6)
	unten.add_child(reihe)
	reihe.add_child(_knopf("  ‹ Bewegung  ", func(): _zeige(bew - 1)))
	reihe.add_child(_knopf("  Bewegung ›  ", func(): _zeige(bew + 1)))
	knoepfe.ziel = _knopf("  Blick: Überblick  ", func(): _ziel((ziel + 1) % 3))
	reihe.add_child(knoepfe.ziel)
	knoepfe.vgl = _knopf("  Held: Eidträger  ", func(): _held((hi + 1) % HELDEN.size()))
	knoepfe.fnd = _knopf("  Gegner: Herzloser  ", func(): _feind((fi + 1) % FEINDE.size()))
	reihe.add_child(knoepfe.fnd)
	reihe.add_child(knoepfe.vgl)
	knoepfe.tuch = _knopf("  Tuch: aus  ", func(): _tuch(["", "leicht", "schwer", "schwebe"][(["", "leicht", "schwer", "schwebe"].find(tuch) + 1) % 4]))
	reihe.add_child(knoepfe.tuch)
	knoepfe.dreh = _knopf("  Kamera: schwenkt  ", func(): _dreh(not dreht))
	reihe.add_child(knoepfe.dreh)
	knoepfe.frei = _knopf("  Selbst steuern: aus  ", func(): _frei(not frei))
	reihe.add_child(knoepfe.frei)
	reihe.add_child(_knopf("  Zurück zum Spiel  ", func(): get_tree().change_scene_to_file("res://main.tscn")))

func _ziel(z: int) -> void:
	ziel = z
	knoepfe.ziel.text = "  Blick: %s  " % ["Überblick", HELDEN[hi][0], FEINDE[fi][0]][z]

# Eidträger mit oder ohne Nemes-Kopftuch: Modell tauschen, Ort, Blick, Laterne und Bewegung bleiben
func _tuch(art: String) -> void:
	tuch = art
	knoepfe.tuch.text = "  Tuch: %s  " % TUCH_NAME[art]
	if hi != 0:
		_held(0)
	var neu := _lade("Eidtraeger_Nemes" if art != "" else "Eidtraeger", held.position)
	if art in ["schwer", "schwebe"]:
		var tex: Texture2D = load("res://models/chars/tuch_%s.webp" % art)
		for mi in neu.find_children("*", "MeshInstance3D", true, false):
			for i in mi.mesh.get_surface_count():
				var m = mi.get_active_material(i)
				if m is StandardMaterial3D:
					var d: StandardMaterial3D = m.duplicate()
					d.albedo_texture = tex
					if d.emission_enabled and d.emission_texture:
						d.emission_texture = tex
					mi.set_surface_override_material(i, d)
	neu.rotation = held.rotation
	laterne.reparent(neu, false)
	held.queue_free()
	held = neu
	_zeige(bew)

func _held(i: int) -> void:
	hi = i
	tuch = ""
	knoepfe.tuch.text = "  Tuch: aus  "
	knoepfe.vgl.text = "  Held: %s  " % HELDEN[hi][0]
	var neu := _lade(HELDEN[hi][1], held.position)
	neu.rotation = held.rotation
	laterne.reparent(neu, false)
	held.queue_free()
	held = neu
	_ziel(ziel)
	_zeige(bew)

func _feind(i: int) -> void:
	fi = i
	knoepfe.fnd.text = "  Gegner: %s  " % FEINDE[fi][0]
	var neu := _lade(FEINDE[fi][1], feind.position)
	neu.rotation = feind.rotation
	neu.scale = Vector3.ONE * FEINDE[fi][2]
	for c in feind.get_children():
		if c is OmniLight3D:
			c.reparent(neu, false)
	feind.queue_free()
	feind = neu
	_ziel(ziel)
	_zeige(bew)

func _dreh(an: bool) -> void:
	dreht = an
	knoepfe.dreh.text = "  Kamera: %s  " % ("schwenkt" if an else "steht")

func _frei(an: bool) -> void:
	frei = an
	knoepfe.frei.text = "  Selbst steuern: %s  " % ("W A S D, Leertaste, J" if an else "aus")
	if an:
		_ziel(1)
		blick = held.rotation.y
		_ap(held).play(HELDEN[hi][2][0], 0.2)
	else:
		held.position = PLATZ_HELD
		held.rotation.y = 0.5
		_zeige(bew)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.physical_keycode:
			KEY_RIGHT, KEY_E: _zeige(bew + 1)
			KEY_LEFT, KEY_Q: _zeige(bew - 1)
			KEY_V: _held((hi + 1) % HELDEN.size())
			KEY_TAB: _ziel((ziel + 1) % 3)
			KEY_ESCAPE: get_tree().change_scene_to_file("res://main.tscn")
			KEY_SPACE:
				if frei and busy <= 0.0:
					_ap(held).play("Dodge_Forward", 0.1)
					busy = 0.45
			KEY_J:
				if frei and busy <= 0.0:
					_ap(held).play(HELDEN[hi][2][3], 0.1)
					busy = 0.7
			KEY_K:
				if frei and busy <= 0.0:
					_ap(held).play(HELDEN[hi][2][8], 0.1)
					busy = 1.0

func _steuern(delta: float) -> void:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W): v.y -= 1
	if Input.is_physical_key_pressed(KEY_S): v.y += 1
	if Input.is_physical_key_pressed(KEY_A): v.x -= 1
	if Input.is_physical_key_pressed(KEY_D): v.x += 1
	busy -= delta
	var ap := _ap(held)
	var tempo := 9.0 if ap.current_animation == "Dodge_Forward" and busy > 0.0 else 4.6
	if ap.current_animation == "Dodge_Forward" and busy > 0.0:
		held.position += Vector3(sin(blick), 0, cos(blick)) * tempo * delta
	elif v != Vector2.ZERO and busy <= 0.0:
		# Richtung auf dem Bildschirm: nach der Kamera ausgerichtet
		var vor := -cam.global_transform.basis.z
		vor.y = 0
		vor = vor.normalized()
		var rechts := vor.cross(Vector3.UP)
		var d := (rechts * v.x - vor * v.y).normalized()
		blick = atan2(d.x, d.z)
		held.position += d * tempo * delta
		ap.play("Running_A", 0.15)
		ap.speed_scale = 1.25
	elif busy <= 0.0:
		ap.play(HELDEN[hi][2][0], 0.2)
		ap.speed_scale = 1.0
	held.position.x = clampf(held.position.x, -9.0, 9.0)
	held.position.z = clampf(held.position.z, -3.4, 6.0)
	held.position.y = 0.18 if Vector2(held.position.x - PLATZ_HELD.x, held.position.z - PLATZ_HELD.z).length() < 1.25 else 0.0
	held.rotation.y = lerp_angle(held.rotation.y, blick, minf(1.0, delta * 14.0))

func _kamera(delta: float, sofort := false) -> void:
	var mitte := Vector3(0, 1.4, -0.3)
	var weit := 10.5
	if ziel == 1:
		mitte = held.position + Vector3(0, 1.25, 0)
		weit = 5.0
	elif ziel == 2:
		mitte = feind.position + Vector3(0, 1.3, 0)
		weit = 5.0
	var k := 1.0 if sofort else minf(1.0, delta * 3.0)
	cam_mitte = cam_mitte.lerp(mitte, k)
	cam_weit = lerpf(cam_weit, weit, k)
	var a := sin(winkel) * 0.62
	cam.position = cam_mitte + Vector3(sin(a) * cam_weit, cam_weit * 0.3, cos(a) * cam_weit)
	cam.look_at(cam_mitte)

func _process(delta: float) -> void:
	t += delta
	if dreht:
		winkel += delta * 0.22
	for tc in torches:
		tc.l.light_energy = tc.get("e", 3.0) * (0.86 + 0.14 * sin(t * 9.0 + tc.ph) * sin(t * 5.3 + tc.ph * 2.0))
	if frei:
		_steuern(delta)
	# einmalige Bewegungen nach kurzer Pause wiederholen
	var b: Array = BEWEGUNGEN[bew]
	if not b[1]:
		var ap := _ap(feind)
		if not ap.is_playing():
			pause_t += delta
			if pause_t > (1.6 if b[0] == "Tod" else 0.7):
				_zeige(bew)
	_kamera(delta)

# Prüfbilder für den Bericht: feste Blickwinkel, dann Ende
func _pruefbilder(ordner: String) -> void:
	dreht = false
	DirAccess.make_dir_recursive_absolute(ordner)
	# Name, Bewegung, Blick, Winkel, Held, Gegner, Tuch
	var folge := [["ueberblick", 0, 0, 0.0, 0, 0, ""], ["tuch_leicht", 0, 1, -0.3, 0, 0, "leicht"], ["tuch_schwer", 0, 1, -0.3, 0, 0, "schwer"], ["tuch_schwebe", 0, 1, -0.3, 0, 0, "schwebe"],
		["priester", 4, 0, 0.3, 1, 1, ""], ["jaegerin", 0, 0, -0.3, 2, 2, ""], ["sternleserin", 3, 0, 0.2, 3, 3, ""], ["koloss", 4, 0, 0.0, 0, 4, ""], ["erloschener", 6, 0, 0.4, 3, 5, ""],
		["h_priester", 0, 1, -0.4, 1, 1, ""], ["h_jaegerin", 0, 1, -0.4, 2, 2, ""], ["h_sternleserin", 0, 1, -0.4, 3, 3, ""],
		["g_ruheloser", 0, 2, 0.5, 0, 1, ""], ["g_krieger", 0, 2, 0.5, 0, 2, ""], ["g_priesterin", 0, 2, 0.5, 0, 3, ""], ["g_koloss", 0, 2, 0.5, 0, 4, ""], ["g_erloschener", 0, 2, 0.5, 0, 5, ""]]
	for f in folge:
		if f[4] != hi:
			_held(f[4])
		if f[5] != fi:
			_feind(f[5])
		if f[6] != tuch:
			_tuch(f[6])
		_ziel(f[2])
		winkel = f[3]
		_zeige(f[1])
		_kamera(0.0, true)
		await get_tree().create_timer(0.55).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/schau_%s.png" % [ordner, f[0]])
	print("Schaukasten: Bilder/s ", Engine.get_frames_per_second(), " · Zeichenaufrufe ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		" · Dreiecke ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	get_tree().quit()
