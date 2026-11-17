extends Node3D
# Herz und Feder · Probestunde in 3D: „Das Tor des Westens“ (erste Stunde der Nacht).
# Baut Welt, Licht und Gegner aus einer Karte, führt Kamera und Eingabe und verbindet alles mit der Anzeige.

const CELL := Karte.CELL   # Meter je Kartenzelle
var hdef: Dictionary           # die Stunde aus Stunden.def: Rudel, Hüter, Legendäre, Texte
const CHEST := [{"name": "Truhe", "model": "chest"}, {"name": "Eisentruhe", "model": "chest"}, {"name": "Prunktruhe", "model": "chest_gold"}]
const DEAD_TXT := "Dein Ba hat den Weg zurück in den Leib gefunden, und die Laterne brennt noch. Was dich angegriffen hat, ist noch dort."
var karte: Karte               # die generierte Stunde (karte.gd), gebaut von welt.gd
var karte_ui: KarteAnzeige
var lichter: Array = []        # feste Lichter der Stunde: weit entfernte werden abgeschaltet (der Renderer rechnet höchstens 32)
var spar_t := 0.0
var freeze_foes := false       # der Rundgang hält die Gegner selbst an
var orte: Orte                 # Feuerschalen, Schreine, Seelenkrüge, Figur, Fundstück und das Questbuch der Stunde

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
var loot: Array = []          # Beute am Boden
var chests: Array = []        # {"n", "lid", "tier", "open", "label"}
var breakables: Array = []    # Fässer und Kisten: {"n", "body", "sub"}
var chests_open := 0
var shots: Array = []         # Geschosse der Figur: {"n", "v", "life", "r", "mult", "pierce", "push", "gen", "stun", "hit"}
var zones: Array = []         # Flächen: Pfeilregen, Seschats Maß
var pet: Node3D               # der Fuchs der Jägerin, vorerst als leuchtender Geist
var pet_t := 0.0              # bis zum nächsten Biss
var pet_rage := 0.0           # Upuauts Hatz: schnelleres Beißen
var pet_tgt: Foe
var full_t := 0.0             # „Tasche voll“ höchstens alle 4 Sekunden melden
var can_fullscreen := true    # im Browser: kann diese Seite Vollbild? (iPhone-Safari kann es nicht)
var total := 0
var deaths := 0
var clock := 0.0
var started := false
var low_gfx := false
var touch := false   # Handy oder Tablet im Browser: größere Anzeige, Knöpfe statt Tasten, sparsame Grafik
var hold_attack := false
var tap_t := 0.0     # Handy: ein kurzer Fingertipp zählt noch einen Moment als gedrückt (bei wenigen Bildern je Sekunde sonst verloren)
var cam_pos := Vector3.ZERO
var autotest: Node
var slow_t := 0.0
var auto_low_done := false

var cine_t := 0.0        # so lange blickt die Kamera zum Hüter, wenn er erwacht
var staub: CPUParticles3D
var stimmung: Array = []   # Lichtstrahlen, Nebelbänke, Runenkreise (Stimmung): bei „Grafik niedrig“ aus

func _ready() -> void:
	if ("--schau" in OS.get_cmdline_user_args() or Spiel.web_frage("schau")) and not Spiel.schau_gesehen:
		# Werkstatt: der Schaukasten mit den Figuren aus der Figurenfabrik
		Spiel.schau_gesehen = true
		get_tree().change_scene_to_file.call_deferred("res://schau.tscn")
		return
	randomize()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed(int(a.substr(7)))   # Tests und Bildvergleiche: dieselbe Karte noch einmal
	# Zwischenbilder (Physik-Interpolation): Die Physik rechnet 60-mal je Sekunde, viele Bildschirme zeigen 120 Bilder.
	# Ohne Zwischenbilder ruckelt jede Bewegung. Eingeschaltet ist sie nur für das, was die Physik bewegt
	# (Figur, Gegner, Geschosse, Fuchs); alles andere bewegt sich ohnehin je Bild.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	W = Karte.GW
	H = Karte.GH
	sfx = Sfx.new()
	add_child(sfx)
	if AudioServer.get_bus_effect_count(0) == 0:
		var lim := AudioEffectHardLimiter.new()   # fängt Spitzen ab, wenn viele Treffer zugleich klingen
		lim.ceiling_db = -0.5
		AudioServer.add_bus_effect(0, lim)
	Spiel.pots = mini(Daten.POTS, Spiel.pots + 2)
	hdef = Stunden.def(Spiel.fall)
	orte = Orte.new()
	orte.game = self
	add_child(orte)
	_build_env()
	_build_world()
	orte.setup()
	for l in find_children("*", "OmniLight3D", true, false):
		lichter.append(l)
	hero = Hero.new()
	hero.game = self
	add_child(hero)
	hero.global_position = start_pos
	hero.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	lvl_seen = Spiel.lvl
	if hero.C.get("pet", false):
		_build_pet()
	cam = Camera3D.new()
	cam.fov = 30.0
	cam.far = 200.0
	add_child(cam)
	cam_pos = hero.global_position
	_place_cam(0.0, true)
	cam.make_current()
	_build_staub()
	touch = "--touch" in OS.get_cmdline_user_args() or OS.has_feature("web_android") or OS.has_feature("web_ios") \
		or (OS.has_feature("web") and DisplayServer.is_touchscreen_available())
	if touch:
		get_window().content_scale_factor = 1.5   # Schrift und Knöpfe anderthalbmal so groß: mit dem Finger treffbar
	var standalone := false
	if OS.has_feature("web"):
		can_fullscreen = bool(JavaScriptBridge.eval("!!(document.fullscreenEnabled || document.webkitFullscreenEnabled)"))
		standalone = bool(JavaScriptBridge.eval("(window.navigator.standalone === true) || window.matchMedia('(display-mode: fullscreen)').matches || window.matchMedia('(display-mode: standalone)').matches"))
	hud = Hud.new()
	hud.game = self
	if OS.has_feature("web") and not can_fullscreen and not standalone:
		hud.chapter_note = "Vollbild auf dem iPhone: unten auf Teilen tippen, „Zum Home-Bildschirm“ wählen und das Spiel von dort starten."
	add_child(hud)
	# Karte der Stunde oben rechts, mit Kartennebel im Dungeon
	karte_ui = KarteAnzeige.new()
	karte_ui.setup(self, karte)
	karte_ui.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	var ks := Vector2(Karte.GW, Karte.GH) * (2.6 if touch else 3.6)
	karte_ui.size = ks
	karte_ui.position = Vector2(-ks.x - 16, 112 if touch else 86)
	hud.root.add_child(karte_ui)
	if touch:
		auto_low_done = true
		set_low(true, true)
	sfx.loop("amb_wind")
	sfx.loop("amb_drone")
	sfx.music("mus_titel")
	get_tree().paused = true
	if "--autotest" in OS.get_cmdline_user_args():
		autotest = load("res://scripts/autotest.gd").new()
		autotest.game = self
		add_child(autotest)
	elif not Spiel.skip_intro:
		hud.show_intro(Spiel.force_new)
		Spiel.force_new = false
	else:
		hud.show_chapter(Stunden.case_no(Spiel.fall), hdef.name, hdef.lead, hdef.brief, "Eintreten", func(): begin())
		sfx.say("vo_chapter")
	if autotest == null:
		if "--klassentest" in OS.get_cmdline_user_args() and not get_tree().root.has_node("Klassentest"):
			var kt: Node = load("res://scripts/klassentest.gd").new()
			kt.name = "Klassentest"
			get_tree().root.add_child.call_deferred(kt)
		if "--playtest" in OS.get_cmdline_user_args() and not get_tree().root.has_node("Playtest"):
			var pt: Node = load("res://scripts/playtest.gd").new()
			pt.name = "Playtest"
			get_tree().root.add_child.call_deferred(pt)

func begin() -> void:
	# der Knopf „Eintreten“ ist die Berührung, die der Browser für Vollbild verlangt
	if OS.has_feature("web") and can_fullscreen:
		set_fullscreen(true)
	sfx.hush()
	started = true
	sfx.music_set(area_music())
	get_tree().paused = false
	Spiel.speichern()
	hud.banner(hdef.name, Stunden.case_no(Spiel.fall))

# Startbildschirm: neue Figur oder weiterspielen. Danach baut sich die Stunde mit den gewählten Werten neu auf.
func start_game(neu: bool, d: int, hardcore: bool, cls := "ermittler", hour := 0) -> void:
	if neu:
		Spiel.neue_figur(cls, d, hardcore)
	else:
		Spiel.diff = d
		if hour > 0:
			Spiel.fall = clampi(hour, 1, Spiel.max_fall)
		Spiel.speichern()
	restart(true)

# aus der Tasche: zurück zum Startbildschirm, dort gleich „Neue Figur“
func new_character() -> void:
	Spiel.force_new = true
	restart(false)

func restart(skip_intro: bool) -> void:
	Spiel.skip_intro = skip_intro
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()

# ---------------------------------------------------------------- Welt
func is_fullscreen() -> bool:
	var m := DisplayServer.window_get_mode()
	return m == DisplayServer.WINDOW_MODE_FULLSCREEN or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

func set_fullscreen(on: bool) -> void:
	if on != is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)

func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen())

func toggle_bag() -> void:
	# Tasche: Ausrüstung, Werte, Material, Buch des Thot; das Spiel steht, solange sie offen ist
	if not started or hero.dead:
		return
	if hud.bag_open:
		sfx.play("ui")
		hud.close_bag()
	elif hud.overlay == null and not get_tree().paused:
		sfx.play("ui")
		get_tree().paused = true
		Spiel.neu = 0
		hud.show_bag()

func add_site(kind: String, pos: Vector3, v: int) -> void:
	orte.add(kind, pos, v)

func is_floor(cx: int, cz: int) -> bool:
	return Karte.in_grid(cx, cz) and not karte.wall(cx, cz)

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
	# Name: [Datei, Kachelgröße in Metern, Tönung, Ersatz falls Datei fehlt, Tönung des Ersatzes]
	"sandstein": ["w01_sandstein", 6.0, Color(1.0, 0.93, 0.80), "", Color.WHITE],
	"sandstein_sims": ["w01_sandstein", 6.0, Color(1.25, 1.15, 0.98), "", Color.WHITE],
	"granit": ["w02_granit", 6.0, Color(0.85, 0.85, 0.92), "", Color.WHITE],
	"gruft": ["t07_gruft", 5.5, Color(0.95, 0.90, 0.84), "", Color.WHITE],
	"pflaster": ["t06_pflaster", 4.0, Color(0.95, 0.88, 0.78), "", Color.WHITE],
	"sand": ["t09_sand", 6.0, Color(0.85, 0.78, 0.68), "pflaster", Color(0.95, 0.88, 0.78)],
	"sand_aussen": ["t09_sand", 6.0, Color(0.45, 0.40, 0.35), "", Color.WHITE],
	"weg": ["t06_pflaster", 4.0, Color(1.25, 1.12, 0.92), "", Color.WHITE],
	# Stunden 2–5 (Bildauftrag W03–W05, T10–T12): bis die Bilder da sind, getönte Verwandte
	"lehm": ["w03_lehm", 6.0, Color(1.0, 0.95, 0.88), "sandstein", Color(0.78, 0.66, 0.50)],
	"feld": ["t10_feld", 6.0, Color(0.9, 0.85, 0.78), "sand", Color(0.72, 0.66, 0.50)],
	"grab": ["w04_grab", 6.0, Color(1.0, 0.95, 0.9), "sandstein", Color(1.0, 0.9, 0.74)],
	"glaswand": ["w02_granit", 6.0, Color(0.72, 0.84, 1.0), "", Color.WHITE],
	"glas": ["t11_glas", 5.0, Color(0.9, 0.92, 1.0), "gruft", Color(0.66, 0.74, 0.88)],
	"hoehle": ["w05_hoehle", 6.0, Color(0.95, 0.92, 1.0), "granit", Color(0.72, 0.64, 0.80)],
	"hoehlenboden": ["t12_hoehlenboden", 5.0, Color(0.9, 0.88, 0.92), "gruft", Color(0.78, 0.70, 0.74)],
}

var mats := {}
var cut_mats := {}      # Mauermaterial mit Durchblick (mauer.gdshader) je Oberfläche
var block_meshes := {}
var spark_meshes := {}  # Funkenform je Farbe, damit nicht jeder Treffer ein neues Material anlegt
const MAUER_SHADER := preload("res://scripts/mauer.gdshader")

func surf(name: String) -> StandardMaterial3D:
	# fehlt die Datei, nimmt das Spiel die Datei des Ersatzes mit dessen eigener Tönung
	if mats.has(name):
		return mats[name]
	var d: Array = SURF[name]
	var file: String = d[0]
	var tint: Color = d[2]
	var per: float = d[1]
	if not ResourceLoader.exists("res://textures/%s.jpg" % file):
		if d[3] == "":
			mats[name] = null
			return null
		var e: StandardMaterial3D = surf(d[3])
		var m0: StandardMaterial3D = e.duplicate()
		m0.albedo_color = d[4]
		m0.set_meta("period", e.get_meta("period"))
		mats[name] = m0
		return m0
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://textures/%s.jpg" % file)
	m.albedo_color = tint
	var npath := "res://textures/%s_n.jpg" % file
	if ResourceLoader.exists(npath):
		m.normal_texture = load(npath)
		m.normal_enabled = not low_gfx
		m.normal_scale = 0.9
	m.roughness = 0.93
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.set_meta("period", per)
	mats[name] = m
	return m

func cut_mat(name: String) -> ShaderMaterial:
	# dieselbe Oberfläche als Mauer mit Durchblick: was zwischen Kamera und Figur steht, wird ausgespart
	if cut_mats.has(name):
		return cut_mats[name]
	var src := surf(name)
	var m := ShaderMaterial.new()
	m.shader = MAUER_SHADER
	m.set_shader_parameter("tex_albedo", src.albedo_texture)
	m.set_shader_parameter("tint", src.albedo_color)
	m.set_shader_parameter("tex_normal", src.normal_texture)
	m.set_shader_parameter("use_normal", src.normal_texture != null and not low_gfx)
	cut_mats[name] = m
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

func _box(pos: Vector3, size: Vector3, rot := 0.0, vis: Node3D = null) -> StaticBody3D:
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
	return b

# Licht der Stunde. Vorbild sind die alten Dungeon-Spiele: kühles Grundlicht, in dem man alles erkennt,
# dazu warme Lichtinseln aus Laterne, Fackeln und Feuerschalen. Draußen scheint der Mond, drinnen färbt die Stunde das Dunkel.
const LICHT := {
	"": {"amb": Color(0.40, 0.50, 0.86), "amb_e": 0.36, "moon": 0.5, "fog": Color(0.05, 0.08, 0.17), "fog_d": 0.005, "bg": Color(0.02, 0.03, 0.07)},
	"ruin": {"amb": Color(0.52, 0.56, 0.5), "amb_e": 0.5, "moon": 0.3, "fog": Color(0.08, 0.10, 0.09), "fog_d": 0.008, "bg": Color(0.01, 0.015, 0.02)},
	"tomb": {"amb": Color(0.62, 0.48, 0.36), "amb_e": 0.46, "moon": 0.22, "fog": Color(0.10, 0.07, 0.04), "fog_d": 0.009, "bg": Color(0.015, 0.01, 0.008)},
	"glass": {"amb": Color(0.38, 0.56, 0.66), "amb_e": 0.5, "moon": 0.3, "fog": Color(0.04, 0.10, 0.13), "fog_d": 0.008, "bg": Color(0.008, 0.015, 0.025)},
	"vault": {"amb": Color(0.5, 0.4, 0.68), "amb_e": 0.48, "moon": 0.25, "fog": Color(0.08, 0.05, 0.13), "fog_d": 0.009, "bg": Color(0.012, 0.008, 0.02)},
}

func _build_env() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.fog_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.15
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.15
	env.adjustment_contrast = 1.06
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	moon = DirectionalLight3D.new()
	moon.light_color = Color(0.62, 0.74, 1.0)
	moon.rotation_degrees = Vector3(-52, -35, 0)
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 70.0
	# ein Schattenbild statt vier Stufen: bei dieser Kamera reicht das, und jedes Stück wird nur einmal mehr gezeichnet
	moon.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(moon)
	# Aufhellung von der Kameraseite, ohne Schatten: Figuren heben sich vom Boden ab
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(1.0, 0.86, 0.7)
	fill.light_energy = 0.1
	fill.rotation_degrees = Vector3(-35, 135, 0)
	fill.shadow_enabled = false
	add_child(fill)
	_set_light("")

func _set_light(kind: String) -> void:
	var L: Dictionary = LICHT.get(kind, LICHT[""])
	env.background_color = L.bg
	env.ambient_light_color = L.amb
	env.ambient_light_energy = L.amb_e
	env.fog_light_color = L.fog
	env.fog_density = L.fog_d
	moon.light_energy = L.moon

func _build_world() -> void:
	# die Stunde aus karte.gd: Dungeon (Stunden 2–5 und die offenen Stunden je nach Vorlage) oder Freiland
	stimmung.clear()
	karte = Karte.new()
	if hdef.has("dungeon"):
		karte.gen_dungeon(hdef.dungeon)
	else:
		karte.gen_outdoor(hdef.mix)
	Welt.new(self, karte).bauen()
	# Prüfbilder: „-- --zeig=hohl“ stellt drei Gegner dieser Art neben den Eingang
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--zeig=") and Foe.KINDS.has(a.substr(7)):
			for i in 3:
				_spawn(a.substr(7), Welt.cell_pos(karte.start) + Vector3(2.5 + i * 2.2, 0, -3.0 + i * 0.6), 98)
	total = foes.size() - 1
	_set_light(karte.kind if karte.indoor else "")
	# Irrende Ba: Lichter, die gegen den Wind ziehen (Farbe nach der Stunde)
	var mote := Color(hdef.get("mote", "#bcd0e8"))
	for i in 5:
		var w := OmniLight3D.new()
		w.light_color = mote
		w.light_energy = 0.9
		w.omni_range = 5.0
		var m := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.14
		sm.height = 0.28
		m.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = mote.lightened(0.4)
		m.material_override = mat
		w.add_child(m)
		add_child(w)
		w.position = Vector3(randf_range(6, W * CELL - 6), 3.0, randf_range(6, H * CELL - 6))
		wisps.append({"n": w, "ph": randf() * TAU, "sp": randf_range(0.5, 1.0)})

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

func _chest(pos: Vector3, tier: int) -> void:
	var n := _piece(CHEST[tier].model, pos, PI, Vector3.ONE * (1.25 if tier == 2 else 1.0))
	var lid := n.find_child("*_lid", true, false)
	var body := _box(pos, Vector3(1.4, 1.0, 1.0))
	var l := Label3D.new()
	l.text = CHEST[tier].name
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 40
	l.outline_size = 10
	l.modulate = [Color(0.85, 0.78, 0.62), Color(0.75, 0.82, 0.9), Color(0.98, 0.78, 0.35)][tier]
	l.pixel_size = 0.0055
	l.position = pos + Vector3(0, 1.8, 0)
	l.visible = false
	add_child(l)
	if tier == 2:
		var o := OmniLight3D.new()
		o.light_color = Color(1.0, 0.8, 0.4)
		o.light_energy = 1.2
		o.omni_range = 4.0
		o.position = pos + Vector3(0, 1.4, 0)
		add_child(o)
	astar.set_point_solid(_sub(pos), true)
	chests.append({"n": n, "lid": lid, "tier": tier, "open": false, "label": l, "body": body, "pos": pos})

func _pack_pos(style: String, c: Vector3, face: float, i: int, n: int) -> Vector3:
	var fwd := Vector3(sin(face), 0, cos(face))
	var side := Vector3(fwd.z, 0, -fwd.x)
	match style:
		"lager":
			var a := TAU * i / n
			return c + Vector3(sin(a), 0, cos(a)) * randf_range(2.3, 3.3)
		"wache":
			return c + fwd * 1.8 + side * ((i - (n - 1) / 2.0) * 1.5)
		"streife":
			return c - fwd * (i / 2) * 1.5 + side * ((i % 2) * 1.4 - 0.7)
	var a2 := randf() * TAU
	return c + Vector3(sin(a2), 0, cos(a2)) * randf_range(2.4, 5.0)

func _campfire(c: Vector3) -> void:
	var logs := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.45
	cm.bottom_radius = 0.55
	cm.height = 0.25
	cm.radial_segments = 8
	logs.mesh = cm
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color(0.25, 0.17, 0.1)
	logs.material_override = lm
	add_child(logs)
	logs.global_position = c + Vector3(0, 0.12, 0)
	var fl := CPUParticles3D.new()
	fl.amount = 14
	fl.lifetime = 0.5
	fl.direction = Vector3(0, 1, 0)
	fl.spread = 14.0
	fl.gravity = Vector3(0, 1.5, 0)
	fl.initial_velocity_min = 0.6
	fl.initial_velocity_max = 1.3
	fl.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	fl.emission_sphere_radius = 0.3
	var qm := SphereMesh.new()
	qm.radius = 0.12
	qm.height = 0.24
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color(1.0, 0.65, 0.25)
	qm.material = fm
	fl.mesh = qm
	add_child(fl)
	fl.global_position = c + Vector3(0, 0.3, 0)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.3)
	l.light_energy = 1.6
	l.omni_range = 7.0
	add_child(l)
	l.global_position = c + Vector3(0, 1.0, 0)
	torches.append({"l": l, "ph": randf() * 10.0})
	_box(c, Vector3(1.0, 0.5, 1.0))
	astar.set_point_solid(_sub(c), true)

func _spawn(kind: String, pos: Vector3, pack: int, elite := "", hd := {}) -> Foe:
	var f := Foe.new()
	f.game = self
	f.init(kind, pos, pack, elite, hd)
	f.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
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
		var q := PhysicsRayQueryParameters3D.create(a + s + Vector3(0, 0.6, 0), b + s + Vector3(0, 0.6, 0), 1 | Welt.LOW_LAYER)
		if not sp.intersect_ray(q).is_empty():
			return false
	return true

func _sub(p: Vector3) -> Vector2i:
	return Vector2i(clampi(int(p.x / CELL), 0, W - 1), clampi(int(p.z / CELL), 0, H - 1))

func _free_cell(c: Vector2i) -> Vector2i:
	if not astar.is_point_solid(c):
		return c
	for r in range(1, 4):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var q := c + Vector2i(dx, dy)
				if maxi(absi(dx), absi(dy)) == r and astar.is_in_boundsv(q) and not astar.is_point_solid(q):
					return q
	return c

func find_path(a: Vector3, b: Vector3) -> PackedVector3Array:
	var out := PackedVector3Array()
	# steht jemand dicht an einer Requisite, kann seine Zelle als belegt gelten: dann von der nächsten freien Zelle aus
	var ia := _free_cell(_sub(a))
	var ib := _free_cell(_sub(b))
	if astar.is_point_solid(ia) or astar.is_point_solid(ib):
		return out
	var ids := astar.get_id_path(ia, ib)
	for i in range(1, ids.size()):
		out.append(Vector3(ids[i].x * 2 + 1, 0, ids[i].y * 2 + 1))
	return out

func wake_pack(pack: int) -> void:
	var k := 0
	var woke := []
	for f in foes:
		if f.pack == pack and f.state == Foe.St.SLEEP:
			f.wake(k * 0.35)
			woke.append(f)
			k += 1
	if Spiel.D().alarm and pack != 99:
		for f in foes:
			if f.state == Foe.St.SLEEP and f.pack != pack and f.pack != 99 and f.alarm < 0.0:
				for o in woke:
					if (o.global_position - f.global_position).length() < 13.2 and sees(o.global_position, f.global_position):
						f.alarm = 1.2
						break

# Der Hüter ruft Diener herbei: sofort wach, ohne Erfahrung und Fortschritt
func boss_summon(b: Foe, kinds: Array) -> void:
	for i in kinds.size():
		var a := TAU * i / kinds.size() + randf()
		var p := b.global_position + Vector3(sin(a), 0, cos(a)) * 2.8
		if not walkable(b.global_position, p):
			p = b.global_position
		var f := _spawn(kinds[i], p, 98, "", hdef)
		f.summoned = true
		f.xp = 0.0
		f.w = 0.0
		f.state = Foe.St.FIGHT
		f.lying = false
		f.set_collision_layer_value(3, true)
		f.play(Foe.ANIM.idle)
		spark(p + Vector3(0, 0.8, 0), Color(0.75, 0.45, 0.95))

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

func hero_arc(h: Hero, reach: float, half_angle: float, mult: float, push: float, gain: bool, stun_t := 0.0) -> void:
	var n := 0
	for f in live_foes():
		var d: Vector3 = f.global_position - h.global_position
		d.y = 0
		if d.length() < reach + f.radius and (d.length() < 1.2 or h.forward().angle_to(d.normalized()) < half_angle):
			h.deal(f, mult, push, stun_t)
			spark(f.global_position + Vector3(0, 1.3, 0), Color(1.0, 0.85, 0.6))
			n += 1
	# Kraftgewinn wie in der 2D-Fassung: 5 und 1 je weiterem Getroffenen, höchstens 9
	if n > 0 and gain:
		h.en = minf(100.0, h.en + 5.0 + mini(4, n - 1))
	smash_around(h.global_position + h.forward() * 1.6, 2.0)
	_impact(n, h.global_position + h.forward() * 1.5)

func hero_slam(c: Vector3, r: float, mult: float, push: float) -> void:
	var n := 0
	for f in live_foes():
		if (f.global_position - c).length() < r + f.radius:
			hero.deal(f, mult, push)
			spark(f.global_position + Vector3(0, 1.3, 0), Color(1.0, 0.85, 0.6))
			n += 1
	smash_around(c, r)
	_impact(n, c)

func hero_ring(c: Vector3, r: float, mult: float, stun_t: float, col: Color) -> void:
	ring_fx(c, r, col)
	shake = maxf(shake, 0.4)
	for f in live_foes():
		if (f.global_position - c).length() < r + f.radius:
			hero.deal(f, mult, 3.0, stun_t)
	smash_around(c, r)
	for i in range(bolts.size() - 1, -1, -1):
		if (bolts[i].n.global_position - c).length() < r + 1.0 and not bolts[i].get("hero", false):
			bolts[i].n.queue_free()
			bolts.remove_at(i)

func hero_beam(h: Hero, mult := 1.25) -> void:
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
			h.deal(f, mult, 3.0)
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

# ---------------------------------------------------------------- Fähigkeiten der Klassen (04-combat.js › cast)
func _auto_target() -> Foe:
	var best: Foe = null
	var bd := hero.reach() - 0.24
	for f in live_foes():
		if hero.ranged() and f.state != Foe.St.FIGHT:
			continue
		var d: float = (f.global_position - hero.global_position).length() - f.radius
		if d < bd and sees(hero.global_position, f.global_position):
			bd = d
			best = f
	return best

func toggle_tree() -> void:
	if not started or hero.dead:
		return
	if hud.tree_open:
		sfx.play("ui")
		hud.close_bag()
	elif hud.overlay == null and not get_tree().paused:
		sfx.play("ui")
		get_tree().paused = true
		hud.show_tree()

# Kegel vor der Figur (Gebs Lachen): Schaden, Rückstoß, Betäubung und Markierung
func hero_cone(h: Hero, reach: float, half_angle: float, mult: float, push: float, stun_t: float, mark: float) -> void:
	var n := 0
	for f in live_foes():
		var d: Vector3 = f.global_position - h.global_position
		d.y = 0
		if d.length() < reach + f.radius and (d.length() < 1.2 or h.forward().angle_to(d.normalized()) < half_angle):
			if f.kind != "boss":
				f.mark_t = mark
			h.deal(f, mult, push, stun_t)
			n += 1
	ring_fx(h.global_position + h.forward() * reach * 0.5, reach * 0.5, Color(0.94, 0.9, 0.8))
	smash_around(h.global_position + h.forward() * 2.0, 2.6)
	_impact(n, h.global_position + h.forward() * 2.0)

# Markierte zerbersten, wenn sie fallen, und reißen Nachbarn mit (Kettenreaktion möglich)
func _mark_burst(f: Foe) -> void:
	var c := f.global_position
	ring_fx(c, 4.6, Color(0.94, 0.75, 0.45))
	shake = maxf(shake, 0.3)
	sfx.play_at("hit", c, 0.1)
	for o in live_foes():
		if o != f and (o.global_position - c).length() < 4.6 + o.radius:
			hero.deal(o, 1.5, 5.0, 0.0, 0.0, false)

# Zorn des Seth: springt von Gegner zu Gegner
func hero_chain(h: Hero, at: Vector3, mult: float) -> void:
	var first: Foe = null
	var bd := INF
	for f in live_foes():
		if (f.global_position - h.global_position).length() < 18.8 and sees(h.global_position, f.global_position):
			var d: float = (f.global_position - at).length()
			if d < bd:
				bd = d
				first = f
	if first == null:
		_bolt_line(h.global_position + Vector3(0, 1.5, 0), _spot_ahead(h, 8.0) + Vector3(0, 1.0, 0))
		return
	var hit := []
	var cur: Foe = first
	var from := h.global_position + Vector3(0, 1.5, 0)
	for i in 6:
		_bolt_line(from, cur.global_position + Vector3(0, 1.2, 0))
		h.deal(cur, mult, 1.2)
		hit.append(cur)
		from = cur.global_position + Vector3(0, 1.2, 0)
		var nxt: Foe = null
		var nd := 7.6
		for f in live_foes():
			if hit.has(f):
				continue
			var d: float = (f.global_position - cur.global_position).length()
			if d < nd:
				nd = d
				nxt = f
		if nxt == null:
			break
		cur = nxt
	sfx.play_at("bolt", first.global_position, 0.1)

func _spot_ahead(h: Hero, d: float) -> Vector3:
	return h.global_position + h.forward() * d

func _bolt_line(a: Vector3, b: Vector3) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var len := (b - a).length()
	bm.size = Vector3(0.12, 0.12, len)
	m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.89, 0.72, 1.0, 0.95)
	m.material_override = mat
	add_child(m)
	m.global_position = (a + b) / 2.0
	if len > 0.01:
		m.look_at(b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)
	var tw := create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tw.tween_callback(m.queue_free)

# Geschosse der Figur: Pfeile, Funken, Atem des Schu. pierce: so viele weitere Gegner, -1 = alle
func spawn_shot(h: Hero, dir: Vector3, o: Dictionary) -> void:
	var m := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var col: Color = o.get("col", Color.WHITE)
	mat.albedo_color = col
	if col.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var r: float = o.get("r", 0.2)
	match o.get("kind", "orb"):
		"arrow":
			var bm := BoxMesh.new()
			bm.size = Vector3(0.07, 0.07, 0.9)
			m.mesh = bm
		"wave":
			var bm := BoxMesh.new()
			bm.size = Vector3(r * 2.6, 0.5, 0.35)
			m.mesh = bm
		_:
			var sm := SphereMesh.new()
			sm.radius = maxf(0.14, r)
			sm.height = maxf(0.28, r * 2.0)
			sm.radial_segments = 10
			sm.rings = 5
			m.mesh = sm
	m.material_override = mat
	add_child(m)
	var d := Vector3(dir.x, 0, dir.z).normalized()
	m.global_position = h.global_position + Vector3(0, 1.3, 0) + d * 0.6
	m.look_at(m.global_position + d, Vector3.UP)
	m.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	shots.append({"n": m, "v": d * float(o.get("speed", 20.0)), "life": float(o.get("life", 0.6)), "r": r, "mult": float(o.get("mult", 1.0)),
		"pierce": int(o.get("pierce", 0)), "push": float(o.get("push", 3.6)), "gen": float(o.get("gen", 0.0)), "stun": float(o.get("stun", 0.0)), "hit": []})

func _shots_tick(delta: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var b: Dictionary = shots[i]
		b.life -= delta
		var n: Node3D = b.n
		var p0 := n.global_position
		n.global_position += b.v * delta
		var gone: bool = b.life <= 0.0 or not sees(p0 - Vector3(0, 1.2, 0), n.global_position - Vector3(0, 1.2, 0))
		if not gone:
			for f in live_foes():
				if b.hit.has(f):
					continue
				var d: Vector3 = n.global_position - f.global_position
				d.y = 0
				if d.length() < f.radius + b.r + 0.2:
					hero.deal(f, b.mult, b.push, b.stun, b.gen if b.hit.is_empty() else 0.0)
					b.hit.append(f)
					spark(n.global_position, Color(1.0, 0.9, 0.7))
					if b.pierce >= 0 and b.hit.size() > b.pierce:
						gone = true
						break
		if gone:
			n.queue_free()
			shots.remove_at(i)

# Flächen: Sieben Pfeile der Sachmet (Schaden in Takten) und Seschats Maß (verlangsamt, schwacher Schaden)
func add_zone(c: Vector3, r: float, t: float, every: float, mult: float, slow: float, col: Color) -> void:
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 0.05
	cm.radial_segments = 40
	cm.rings = 1
	m.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(col, 0.22)
	m.material_override = mat
	add_child(m)
	m.global_position = c + Vector3(0, 0.08, 0)
	zones.append({"n": m, "mat": mat, "c": c, "r": r, "t": t, "t0": t, "every": every, "next": 0.0, "mult": mult, "slow": slow, "col": col})

func _zones_tick(delta: float) -> void:
	for i in range(zones.size() - 1, -1, -1):
		var z: Dictionary = zones[i]
		z.t -= delta
		z.next -= delta
		for f in live_foes():
			if (f.global_position - z.c).length() < z.r + f.radius:
				if z.slow > 0.0:
					f.slow_t = 0.2
				if z.next <= 0.0:
					hero.deal(f, z.mult, 0.3, 0.0, 0.0, false)
		if z.next <= 0.0:
			z.next = z.every
			if z.slow <= 0.0:
				for k in 4:
					var a := randf() * TAU
					spark(z.c + Vector3(sin(a), 0, cos(a)) * randf() * z.r + Vector3(0, 0.3, 0), z.col)
		z.mat.albedo_color.a = 0.22 * clampf(z.t / 0.4, 0.0, 1.0)
		if z.t <= 0.0:
			z.n.queue_free()
			zones.remove_at(i)

# Fallender Stern der Nut: Vorwarnung, dann Einschlag
func meteor(c: Vector3, r: float, mult: float) -> void:
	warn_fx(c, r, 0.7)
	get_tree().create_timer(0.7, false).timeout.connect(func():
		ring_fx(c, r, Color(1.0, 0.84, 0.37))
		spark(c + Vector3(0, 0.8, 0), Color(1.0, 0.84, 0.37))
		shake = maxf(shake, 0.7)
		sfx.play_at("hit", c, 0.05)
		for f in live_foes():
			if (f.global_position - c).length() < r + f.radius:
				hero.deal(f, mult, 7.0)
		smash_around(c, r))

# ---------------------------------------------------------------- Der Fuchs der Jägerin (05-update.js › Begleittier)
func _build_pet() -> void:
	pet = Node3D.new()
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.28
	sm.height = 0.5
	sm.radial_segments = 12
	sm.rings = 6
	m.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.82, 0.5)
	m.material_override = mat
	m.position.y = 0.55
	pet.add_child(m)
	for k in 2:
		var ear := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.14, 0.28, 0.06)
		ear.mesh = pm
		ear.material_override = mat
		ear.position = Vector3(-0.12 + 0.24 * k, 0.86, 0.0)
		pet.add_child(ear)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.75, 0.4)
	l.light_energy = 1.0
	l.omni_range = 3.0
	l.position.y = 0.7
	pet.add_child(l)
	add_child(pet)
	pet.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	pet.global_position = hero.global_position + Vector3(-1.2, 0, 1.2)

func hetz_target(at: Vector3) -> Foe:
	if pet == null:
		return null
	var best: Foe = null
	var bd := INF
	for f in live_foes():
		if (f.global_position - hero.global_position).length() < 20.8:
			var d: float = (f.global_position - at).length()
			if d < bd:
				bd = d
				best = f
	return best

func pet_hetz(at: Vector3, pw: float) -> void:
	var t := hetz_target(at)
	if t == null:
		return
	pet_tgt = t
	pet_rage = 5.0
	pet.global_position = t.global_position + (pet.global_position - t.global_position).normalized() * (t.radius + 0.4)
	hero.deal(t, 3.0 * pw, 4.8, 0.0, 0.0, false)
	ring_fx(t.global_position, 1.6, Color(1.0, 0.75, 0.4))
	# feindliche Tiere in der Nähe fliehen (nicht die Elite)
	for f in live_foes():
		if f.K.get("animal", false) and f.elite == "" and (f.global_position - pet.global_position).length() < 11.2:
			f.fear_t = 4.0

func _pet_tick(delta: float) -> void:
	if pet == null:
		return
	pet_rage -= delta
	pet_t -= delta
	var hp_ := hero.global_position
	if pet_tgt and (pet_tgt.state == Foe.St.DEAD or (pet_tgt.global_position - hp_).length() > 17.6):
		pet_tgt = null
	var t: Foe = pet_tgt
	if t == null:
		var bd := 12.0
		for f in live_foes():
			if f.state == Foe.St.FIGHT:
				var d: float = (f.global_position - hp_).length()
				if d < bd:
					bd = d
					t = f
	var goal: Vector3 = hp_ - hero.forward() * 1.8 + Vector3(sin(hero.face + 1.6), 0, cos(hero.face + 1.6)) * 0.8
	if t:
		goal = t.global_position
	var d := goal - pet.global_position
	d.y = 0
	var reach := (t.radius + 0.8) if t else 0.3
	if d.length() > reach:
		pet.global_position += d.normalized() * minf(d.length() - reach * 0.8, 11.2 * delta)
	pet.look_at(pet.global_position + Vector3(d.x, 0, d.z + 0.001), Vector3.UP)
	pet.get_child(0).position.y = 0.55 + absf(sin(Time.get_ticks_msec() * 0.012)) * 0.12
	var key := Spiel.has_key() and hero.cls == "jaegerin"
	if t and d.length() <= reach + 0.2 and pet_t <= 0.0:
		pet_t = (0.4 if pet_rage > 0.0 else 0.85) * (0.7 if key else 1.0)
		hero.deal(t, 0.45 * (2.0 if key else 1.0), 0.8, 0.0, 0.0, false)
		spark(t.global_position + Vector3(0, 0.8, 0), Color(1.0, 0.8, 0.5))
	var far := (pet.global_position - hp_).length()
	if far > 28.8 or (far > 10.4 and not sees(pet.global_position, hp_)):
		pet.global_position = hp_ - hero.forward() * 1.2

func spawn_bolt(pos: Vector3, dir: Vector3, dmg: float, speed: float, col := Color(0.95, 0.55, 0.9), life := 3.2) -> void:
	# ohne eigenes Licht: ein Geschossring des Hüters hätte sonst zwanzig Lichter auf einmal
	var n := Node3D.new()
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.24
	sm.height = 0.48
	sm.radial_segments = 10
	sm.rings = 5
	m.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	m.material_override = mat
	n.add_child(m)
	add_child(n)
	n.global_position = pos
	n.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	bolts.append({"n": n, "v": dir * speed, "dmg": dmg, "life": life})

func on_foe_dead(f: Foe) -> void:
	if f.mark_t > 0.0 and f != boss:
		_mark_burst(f)
	_drops(f)
	if Spiel.has_leg("leech") and not hero.dead:
		hero.hp = minf(hero.max_hp, hero.hp + hero.max_hp * 0.03)
	if Spiel.xp_gain(f.xp * Spiel.S.xp_mul):
		_level_up()
	if f == boss:
		on_boss_dead()
	elif not f.summoned:
		kills += 1

var lvl_seen := 0   # bis zu dieser Stufe sind neue Fähigkeiten schon angekündigt

func _level_up() -> void:
	hero.apply_stats(true)
	hero.en = 100.0
	# groß in der Bildmitte: die neue Stufe, der freie Punkt und jede Fähigkeit, die jetzt gelernt ist
	hud.announce(null, "AUFSTIEG", "Stufe %d" % Spiel.lvl, "Ein Fähigkeitenpunkt ist frei. %s öffnet den Fähigkeitenbaum: Ränge, Verstärkungen und Passive." % ("„Fähigk.“ oben rechts" if touch else "Taste K"), 5.0)
	for i in 5:
		var id: String = hero.ORDER[i]
		var need := Klassen.unlock_lvl(hero.cls, id)
		if need > lvl_seen and need <= Spiel.lvl and need > 1:
			var S: Dictionary = hero.SK[id]
			hud.announce(Klassen.icon(id, 176), "NEUE FÄHIGKEIT · %s" % ("ANTIPPEN" if touch else ("RECHTE MAUSTASTE" if i == 4 else "TASTE %d" % (i + 1))), S.name, S.txt, 7.0)
	lvl_seen = Spiel.lvl
	sfx.play("aufstieg")
	ring_fx(hero.global_position, 2.6, Color(1.0, 0.85, 0.4))

# ---------------------------------------------------------------- Beute (04-combat.js › kill, 03a-dungeon.js › openChest)
func _shard_mul() -> int:
	return 2 if Spiel.has_leg("shards") else 1

func _drops(f: Foe) -> void:
	var at := f.global_position
	var n := Spiel.fall
	if f == boss:
		_boss_drops(at)
		return
	var T: Dictionary = Daten.ET[f.K.typ]
	var el := f.elite != ""
	if f.summoned:
		# Diener des Hüters: nur Gegenstand nach Fundchance und Isisblut
		if randf() < T.drop * Spiel.S.find:
			drop_item(at, Spiel.new_item(n, 0))
		if randf() < 0.07:
			drop("blood", at)
		return
	if el:
		drop_item(at, Spiel.new_item(n, 1))
		if randf() < 0.5:
			drop_item(at, Spiel.new_item(n, 0))
		if randf() < 0.08:
			drop_item(at, Spiel.new_item(n, 3))
	elif randf() < T.drop * Spiel.S.find:
		drop_item(at, Spiel.new_item(n, 0))
	if randf() < 0.45:
		drop("shard", at, randi_range(1, 3) * (4 if el else 1) * _shard_mul())
	if el and randf() < 0.4:
		_drop_page(at)
	if el:
		drop("mat", at, randi_range(2, 3), "staub")
	elif randf() < 0.12:
		drop("mat", at, 1, "staub")
	var m: String = f.K.mat
	if m != "" and randf() < (0.6 if el else (0.05 if m == "stern" else 0.1)):
		drop("mat", at, 1, m)
	if randf() < (0.5 if el else 0.07):
		drop("blood", at)

func _boss_drops(at: Vector3) -> void:
	drop("mat", at, randi_range(4, 6), "staub")
	var m: String = boss.K.mat
	if m == "":
		drop("mat", at, 3, "stern")
	else:
		drop("mat", at, 2 if m == "stern" else 3, m)
		if m != "stern":
			drop("mat", at, 1, "stern")
	drop("shard", at, 25 * _shard_mul())
	_drop_page(at)
	var n1 := Spiel.fall + 1
	var its := [Spiel.new_item(n1, 3 if randf() < 0.6 else 2)]
	if randf() < 0.4:
		var lid: String = hdef.legs.pick_random()
		its.append(Spiel.new_item(n1, 3, {"slot": Daten.leg(lid).slot, "leg": lid}))
	else:
		its.append(Spiel.new_item(n1, 2))
	its.append(Spiel.new_item(n1, 2))
	its.append(Spiel.new_item(n1, 2))
	for i in its.size():
		var a := TAU * i / its.size() + 0.4
		drop_item(at, its[i], at + Vector3(sin(a), 0, cos(a)) * 3.4)

func _drop_page(at: Vector3) -> void:
	var lying := loot.filter(func(b): return b.kind == "page").map(func(b): return b.page)
	for i in Daten.EVID.size():
		if not Spiel.evid.has(i) and not lying.has(i):
			var b := drop("page", at)
			b.page = i
			return

func _spot(at: Vector3) -> Vector3:
	# ein freier Fleck neben at, nie in einer Mauer
	for k in 6:
		var a := randf() * TAU
		var p := at + Vector3(sin(a), 0, cos(a)) * randf_range(0.9, 1.9)
		if walkable(at, p) and not astar.is_point_solid(_sub(p)):
			return p
	return at

func drop(kind: String, at: Vector3, amount := 1, m := "", to := Vector3.INF) -> Beute:
	var b := Beute.new()
	b.kind = kind
	b.amount = amount
	b.mat = m
	add_child(b)
	b.global_position = _spot(at) if to == Vector3.INF else to
	loot.append(b)
	return b

func drop_item(at: Vector3, it: Dictionary, to := Vector3.INF) -> void:
	var b := Beute.new()
	b.kind = "item"
	b.item = it
	add_child(b)
	b.global_position = _spot(at) if to == Vector3.INF else (to if walkable(at, to) else _spot(at))
	loot.append(b)
	if it.rar >= 2:
		sfx.play_at("udjat" if it.rar == 3 else "ui", b.global_position, 0.05, -4.0 if it.rar == 2 else 0.0)
		if it.rar == 3:
			shake = maxf(shake, 0.3)

func item_sub(it: Dictionary) -> String:
	# Seltenheit, Platz und Vergleich mit dem Angelegten (07-ui.js › itemSub)
	var t: String = "%s · %s" % [Daten.RAR[it.rar].name, Daten.SLOT[it.slot].name]
	var cur = Spiel.eq.get(it.slot)
	if cur == null:
		return t + " · Platz frei"
	var dlt := Daten.item_score(it) - Daten.item_score(cur)
	if dlt > 0.5:
		return t + " · ▲ besser als angelegt (+%d)" % int(round(dlt))
	return t

func _take(b: Beute) -> bool:
	match b.kind:
		"item":
			var sub := item_sub(b.item)
			var res := Spiel.take_item(b.item)
			if res == "voll":
				if full_t <= 0.0:
					full_t = 4.0
					hud.toast_item(-1, "Tasche voll", "Wirf in der Tasche (I) etwas weg.", Color(0.9, 0.45, 0.4))
				return false
			if res == "angelegt":
				hero.apply_stats()
				sub = "direkt angelegt"
			hud.toast_item(Daten.icon_of(b.item), Daten.item_name(b.item), sub, Daten.RAR[b.item.rar].col, 6.5 if b.item.rar >= 2 else 4.0)
			sfx.play("aufheben", 0.1)
		"shard":
			var am := int(round(b.amount * float(Spiel.S.shard)))   # ein schweres Herz findet mehr
			Spiel.shards += am
			float_text(hero.global_position, "+%d Scherben" % am, Color(0.95, 0.85, 0.55))
			sfx.play("ui", 0.15, -8.0)
		"mat":
			Spiel.mats[b.mat] += b.amount
			Spiel.speichern()
			hud.toast_item(Daten.ICON[b.mat], "%d × %s" % [b.amount, Daten.MATS[b.mat].name], "jetzt %d" % Spiel.mats[b.mat], Daten.MATS[b.mat].col)
			sfx.play("aufheben", 0.15, -4.0)
		"blood":
			hero.hp = minf(hero.max_hp, hero.hp + hero.max_hp * (0.3 if Spiel.has_leg("caravan") else 0.15))
			if Spiel.pots < Daten.POTS:
				Spiel.pots += 1
				float_text(hero.global_position, "+1 Rotbier", Color(0.5, 0.9, 0.55))
			sfx.play("potion", 0.1, -4.0)
		"page":
			if not Spiel.evid.has(b.page):
				Spiel.evid.append(b.page)
				Spiel.neu += 1
				Spiel.speichern()
				hud.banner(Daten.EVID[b.page][0], "BUCH DES THOT · SEITE %d VON %d" % [b.page + 1, Daten.EVID.size()], 5.6)
				hud.toast_item(Daten.ICON.evid, Daten.EVID[b.page][0], "Seite aus dem Buch des Thot. Lies sie in der Tasche (I).", Color(0.98, 0.9, 0.62), 6.5)
				sfx.play("papyrus", 0.05, 4.0)
	return true

func _loot_tick(delta: float) -> void:
	full_t -= delta
	var hp_ := hero.global_position
	for i in range(loot.size() - 1, -1, -1):
		var b: Beute = loot[i]
		if b.age < 0.25:
			continue
		var d := hp_ - b.global_position
		d.y = 0.0
		var dist := d.length()
		if b.kind != "item" and dist < Spiel.S.pick and dist > 0.01:
			b.global_position += d / dist * minf(dist, 16.8 * delta)
		if dist < 1.36 and not hero.dead and _take(b):
			loot.remove_at(i)
			b.queue_free()

# Fässer und Kisten zerschlagen (03a-dungeon.js › smashAround)
func smash_around(c: Vector3, r: float) -> void:
	for i in range(breakables.size() - 1, -1, -1):
		var br: Dictionary = breakables[i]
		var d: Vector3 = br.pos - c
		d.y = 0.0
		if d.length() > r + 1.0:
			continue
		breakables.remove_at(i)
		br.n.queue_free()
		br.body.queue_free()
		astar.set_point_solid(br.sub, false)
		sfx.play_at("hit", br.pos, 0.2, -4.0)
		spark(br.pos + Vector3(0, 0.8, 0), Color(0.7, 0.55, 0.35))
		if randf() < 0.34:
			drop("shard", br.pos, randi_range(1, 3) * _shard_mul())
		if randf() < 0.12:
			drop("mat", br.pos, 1, "staub")
		if randf() < 0.06:
			drop("blood", br.pos)

# Truhen öffnen sich, sobald die Figur sie berührt
func _chest_tick() -> void:
	for c in chests:
		var d: Vector3 = c.pos - hero.global_position
		d.y = 0.0
		c.label.visible = not c.open and d.length() < 10.0
		if not c.open and d.length() < 1.9 and not hero.dead and hud.overlay == null:
			_open_chest(c)
			return

func _open_chest(c: Dictionary) -> void:
	c.open = true
	chests_open += 1
	if c.lid:
		var tw := create_tween()
		tw.tween_property(c.lid, "rotation:x", -1.7, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sfx.play_at("truhe", c.pos, 0.1)
	shake = maxf(shake, 0.2)
	var T: int = c.tier
	var n := Spiel.fall
	var its := []
	match T:
		0:
			for i in randi_range(1, 2):
				its.append(Spiel.new_item(n, 1))
		1:
			for i in randi_range(2, 3):
				its.append(Spiel.new_item(n, 2 if i == 0 else 1))
		2:
			its.append(Spiel.new_item(n + 1, 3 if randf() < 0.45 else 2))
			its.append(Spiel.new_item(n + 1, 2))
			its.append(Spiel.new_item(n + 1, 2))
	var sh: int = [randi_range(6, 14), randi_range(15, 30), randi_range(40, 60)][T] * _shard_mul()
	var mats := {"staub": randi_range(1, 3) + 2 * T}
	if T > 0 or randf() < 0.3:
		var mk: String = "stern" if T == 2 else ["leder", "eisen"].pick_random()
		mats[mk] = mats.get(mk, 0) + 1
	var lines := []
	for it in its:
		lines.append([Daten.icon_of(it), Daten.item_name(it), item_sub(it), Daten.RAR[it.rar].col])
	lines.append([Daten.ICON.shard, "%d Scherben" % sh, "", Color(0.95, 0.85, 0.55)])
	for k in mats:
		lines.append([Daten.ICON[k], "%d × %s" % [mats[k], Daten.MATS[k].name], "", Daten.MATS[k].col])
	var free := Daten.BAG_MAX - Spiel.bag.size()
	var note := "" if free >= its.size() else "In der Tasche ist nur noch Platz für %d Teile. Was nicht passt, bleibt neben der Truhe liegen." % maxi(0, free)
	get_tree().paused = true
	hud.show_chest("PRUNKFUND" if T == 2 else "FUND", CHEST[T].name, lines, note,
		func():
			Spiel.shards += sh
			for k in mats:
				Spiel.mats[k] += mats[k]
			var got := 0
			for it in its:
				var res := Spiel.take_item(it)
				if res == "voll":
					drop_item(c.pos, it)
				else:
					got += 1
			hero.apply_stats()
			Spiel.speichern()
			hud.toast_item(Daten.ICON.shard, "Truhe geleert", "%d Teile, %d Scherben" % [got, sh], Color(0.95, 0.85, 0.55))
			get_tree().paused = false,
		func():
			for it in its:
				drop_item(c.pos, it)
			drop("shard", c.pos, sh)
			for k in mats:
				drop("mat", c.pos, mats[k], k)
			get_tree().paused = false)

# Musik der Stunde: im Freiland die Wüstennacht, im Dungeon das Stück seiner Art, jeweils im Wechsel mit einem zweiten
const MUSIK := {"ruin": "mus_felder", "tomb": "mus_grab", "glass": "mus_rosetau", "vault": "mus_hoehle"}

# Untergrund unter einem Punkt: Stein in Gräbern und Gebäuden, sonst Sand (für den Klang der Schritte)
func auf_stein(p: Vector3) -> bool:
	if karte == null:
		return false
	if karte.indoor:
		return true
	var cx := int(p.x / Karte.CELL)
	var cy := int(p.z / Karte.CELL)
	if cx < 0 or cy < 0 or cx >= Karte.GW or cy >= Karte.GH:
		return false
	return karte.flr[cy * Karte.GW + cx] == 2

func area_music() -> Array:
	if karte and karte.indoor:
		return [MUSIK.get(karte.kind, "mus_duat"), "mus_duat"]
	return ["mus_wueste", "mus_titel"]

func on_boss_wake(b: Foe) -> void:
	boss_awake = true
	cine_t = 2.4
	sfx.music("mus_kampf", 1.0)
	hud.boss_show(b.K.name)
	hud.banner(hdef.boss.say, b.K.name.to_upper(), 6.0)
	sfx.play("boss_appear")
	sfx.say("vo_boss")
	shake = maxf(shake, 0.6)

func on_boss_dead() -> void:
	hud.boss_hide()
	sfx.music_set(area_music(), 3.0)
	hud.banner("Die Stunde ist vollendet. Eine Pforte steht offen.", "DER HÜTER IST GEFALLEN", 5.0)
	sfx.play("victory")
	for f in live_foes():
		if f.global_position.distance_to(boss.global_position) < 30.0:
			f.hit(9999.0, boss.global_position)
	# die Pforte wächst in der Mitte der Bodenplatte, auf der der Hüter fiel (nie in einer Mauer)
	_build_gate(Welt.cell_pos(karte.lair))

func on_hero_dead() -> void:
	deaths += 1
	if Spiel.hc:
		# Hardcore: der Spielstand ist sofort verloren (04-combat.js › hurt)
		Spiel.loeschen()
	await get_tree().create_timer(1.6).timeout
	sfx.say("vo_death")
	get_tree().paused = true
	if Spiel.hc:
		hud.show_dead("Hardcore: %s, Stufe %d, gefallen in der %s. Ausrüstung und Erfahrung sind verloren." % [Spiel.CLS[Spiel.cls].name, Spiel.lvl, Stunden.hour_txt(Spiel.fall)], func(): restart(false), "Neue Figur anlegen")
		return
	hud.show_dead(DEAD_TXT, func():
		sfx.hush()
		for f in foes:
			if f.state == Foe.St.FIGHT or f.state == Foe.St.WAKING:
				f.sleep_again()
		if boss.state != Foe.St.DEAD:
			boss_awake = false
			sfx.music_set(area_music())
			hud.boss_hide()
		for b in bolts:
			b.n.queue_free()
		bolts.clear()
		hero.revive(start_pos)
		if pet:
			pet.global_position = start_pos + Vector3(-1.2, 0, 1.2)
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
	var stats := [[_clock(), "Zeit"], [str(kills), "Besiegte"], ["%d/%d" % [chests_open, chests.size()], "Truhen"], ["%d/%d" % [Spiel.evid.size(), Daten.EVID.size()], "Seiten"], [str(deaths), "Rückschläge"]]
	var n1 := Spiel.fall + 1
	var nd := Stunden.def(n1)
	var epi: String = hdef.epi
	var urteil := Geschichte.urteil(Spiel.fall)
	if urteil != "":
		epi += "\n\n" + urteil
	hud.show_gate(Stunden.case_no(Spiel.fall) + " · VOLLENDET", hdef.name, epi, stats, "HINTER DER PFORTE · " + Stunden.case_no(n1), nd.name, nd.lead,
		func():
			sfx.hush()
			go_hour(n1),
		func():
			sfx.hush()
			get_tree().paused = false)

# in eine andere Stunde wechseln (Pforte, Startbildschirm, Tasche): die Welt baut sich mit der neuen Stunde neu auf
func go_hour(n: int) -> void:
	Spiel.fall = clampi(n, 1, maxi(Spiel.max_fall, n))
	Spiel.max_fall = maxi(Spiel.max_fall, Spiel.fall)
	Spiel.speichern()
	restart(true)

func _clock() -> String:
	return "%d:%02d" % [int(clock) / 60, int(clock) % 60]

# ---------------------------------------------------------------- Effekte
func float_text(pos: Vector3, text: String, col: Color, big := 1.0) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = 64
	l.outline_size = 14
	l.modulate = col
	l.pixel_size = 0.012 * big
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

# Ansage eines Hiebs: roter Kegel vor dem Gegner (05-update.js: Kegel ±0,8 rad)
func cone_fx(c: Vector3, face: float, r: float, half: float, t: float) -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 10
	for i in steps:
		var a0 := face - half + 2.0 * half * i / steps
		var a1 := face - half + 2.0 * half * (i + 1) / steps
		im.surface_add_vertex(Vector3.ZERO)
		im.surface_add_vertex(Vector3(sin(a1), 0, cos(a1)) * r)
		im.surface_add_vertex(Vector3(sin(a0), 0, cos(a0)) * r)
	im.surface_end()
	var m := MeshInstance3D.new()
	m.mesh = im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(0.85, 0.2, 0.15, 0.1)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material_override = mat
	add_child(m)
	m.global_position = c + Vector3(0, 0.1, 0)
	var tw := create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.45, t)
	tw.tween_callback(m.queue_free)

# Ansage des Ansturms: roter Streifen in Laufrichtung
func stripe_fx(c: Vector3, dir: Vector3, length: float, width: float, t: float) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, 0.04, length)
	m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.85, 0.2, 0.15, 0.1)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material_override = mat
	add_child(m)
	m.global_position = c + dir * (length / 2.0) + Vector3(0, 0.1, 0)
	m.rotation.y = atan2(dir.x, dir.z)
	var tw := create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.45, t)
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
	if not spark_meshes.has(col):
		var sm := SphereMesh.new()
		sm.radius = 0.06
		sm.height = 0.12
		sm.radial_segments = 8
		sm.rings = 4
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = col
		sm.material = mat
		spark_meshes[col] = sm
	p.mesh = spark_meshes[col]
	add_child(p)
	p.global_position = pos
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)

# ---------------------------------------------------------------- Kamera und Eingabe
# Staub im Laternenlicht: wenige helle Körnchen, die um die Figur treiben
func _build_staub() -> void:
	staub = CPUParticles3D.new()
	staub.amount = 34
	staub.lifetime = 7.0
	staub.preprocess = 7.0
	staub.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	staub.emission_box_extents = Vector3(8.0, 1.6, 8.0)
	staub.direction = Vector3(1, 0.2, 0.3)
	staub.spread = 180.0
	staub.gravity = Vector3(0, 0.02, 0)
	staub.initial_velocity_min = 0.08
	staub.initial_velocity_max = 0.3
	staub.scale_amount_min = 0.5
	staub.scale_amount_max = 1.3
	var qm := SphereMesh.new()
	qm.radius = 0.022
	qm.height = 0.044
	qm.radial_segments = 4
	qm.rings = 2
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color(1.0, 0.86, 0.6, 0.55)
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.material = fm
	staub.mesh = qm
	add_child(staub)

# Kamera: folgt der Figur gedämpft und blickt ein Stück in Laufrichtung voraus. Erwacht der Hüter, schwenkt sie
# kurz zu ihm; im Hüterkampf öffnet sie den Blick etwas.
func _place_cam(delta: float, snap := false) -> void:
	var hp: Vector3 = hero.get_global_transform_interpolated().origin
	var want := hp + hero.vel * 0.2
	var hueter: bool = boss != null and boss_awake and boss.state != Foe.St.DEAD
	if cine_t > 0.0 and hueter:
		cine_t -= delta
		want = hp.lerp(boss.global_position, 0.6)
	cam_pos = want if snap else cam_pos.lerp(want, 1.0 - exp(-delta * (3.0 if cine_t > 0.0 else 7.5)))
	cam.fov = 30.0 if snap else lerpf(cam.fov, 33.5 if hueter else 30.0, 1.0 - exp(-delta * 2.0))
	if staub:
		staub.global_position = cam_pos + Vector3(0, 1.8, 0)
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
			KEY_1, KEY_2, KEY_3, KEY_4:
				hero.aim = mouse_ground()
				hero.auto_aim = false
				hero.cast(hero.ORDER[ev.keycode - KEY_1])
			KEY_Q: hero.cast("potion")
			KEY_SPACE: hero.dodge()
			KEY_E:
				if orte.near_helfer() and (not orte.near_npc() or hero.global_position.distance_to(orte.helfer.pos) < hero.global_position.distance_to(orte.npc.pos)):
					orte.talk_helfer()
				elif orte.near_npc():
					orte.talk()
			KEY_K: toggle_tree()
			KEY_F: hud.toggle_fps()
			KEY_G: set_low(not low_gfx)
			KEY_V: toggle_fullscreen()
			KEY_I, KEY_TAB: toggle_bag()
			KEY_M: sfx.set_muted(not sfx.muted)
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and orte.talked and orte.near_npc() \
			and mouse_ground().distance_to(orte.npc.pos) < 1.8 and not hud.mouse_over_ui():
		# die Figur der Stunde antippen oder anklicken: noch einmal mit ihr sprechen
		orte.talk()
		return
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and orte.helfer_talked and orte.near_helfer() \
			and mouse_ground().distance_to(orte.helfer.pos) < 1.8 and not hud.mouse_over_ui():
		orte.talk_helfer()
		return
	if touch and ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		tap_t = 0.3
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
		hero.aim = mouse_ground()
		hero.auto_aim = false
		hero.cast(hero.ORDER[4])

func set_low(low: bool, still := false) -> void:
	low_gfx = low
	hero.lantern.shadow_enabled = not low
	moon.shadow_enabled = not low
	env.glow_enabled = not low
	if staub:
		staub.emitting = not low
	for n in stimmung:
		if is_instance_valid(n):
			n.visible = not low
	# Handys haben sehr dichte Bildschirme (bis dreifach): dort die 3D-Auflösung stärker senken
	get_viewport().scaling_3d_scale = (0.6 if touch else 0.7) if low else 1.0
	# Stein ohne Reliefkarte und ohne anisotrope Filterung: weniger Texturzugriffe je Bildpunkt
	for m in mats.values():
		if m:
			m.normal_enabled = not low and m.normal_texture != null
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if low else BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	for name in cut_mats:
		cut_mats[name].set_shader_parameter("use_normal", not low and surf(name).normal_texture != null)
	if not still:
		hud.toast("Grafik: %s" % ("Niedrig (ohne Schatten und Glühen)" if low else "Hoch"))

func _physics_process(delta: float) -> void:
	if not started:
		return
	clock += delta
	shot_gap -= delta
	_loot_tick(delta)
	_chest_tick()
	orte.tick(delta)
	_foes_sleep_far()
	_shots_tick(delta)
	_zones_tick(delta)
	_pet_tick(delta)
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
		var gedrueckt := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or tap_t > 0.0
		tap_t = maxf(0.0, tap_t - delta)
		if gedrueckt and not hud.mouse_over_ui():
			var tgt := foe_near(mg, 1.6)
			var to := mg - hero.global_position
			to.y = 0
			if tgt and (tgt.global_position - hero.global_position).length() < hero.reach() - 0.1 + tgt.radius and (not hero.ranged() or sees(hero.global_position, tgt.global_position)):
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
		elif dir == Vector3.ZERO:
			# Auto-Angriff ohne Eingabe (05-update.js): nächster Gegner in Reichweite und Sicht
			var af := _auto_target()
			if af:
				hero.aim = af.global_position
				hero.attack()
		hero.want_dir = dir
	# höchstens zwei Nahkämpfer greifen zugleich an, die anderen lauern
	var melee := foes.filter(func(f): return f.state == Foe.St.FIGHT and f.K.ai != "ranged" and f.K.ai != "boss" and f.fear_t <= 0.0)
	melee.sort_custom(func(a, b): return a.global_position.distance_squared_to(hero.global_position) < b.global_position.distance_squared_to(hero.global_position))
	for i in melee.size():
		melee[i].slot = i < int(Spiel.D().slots)
		melee[i].ring_i = i
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
		if b.get("hero", false):
			for f in live_foes():
				var df: Vector3 = hitp - f.global_position
				df.y = 0
				if not gone and df.length() < f.radius + 0.45:
					f.hit(b.dmg, hitp - b.v, 3.0)
					gone = true
		elif not gone and dh.length() < hero.radius + 0.45 and not hero.dead and hero.inv <= 0.0:
			if Spiel.has_leg("mirror") and randf() < 0.25:
				# Spiegel der Hathor: das Geschoss fliegt zum Schützen zurück
				b.v = -b.v * 1.6
				b.dmg *= 1.6
				b.life = 1.6
				b["hero"] = true
				float_text(hero.global_position, "gespiegelt", Color(0.95, 0.85, 0.55))
			else:
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

# Sparen: Lichter jenseits des Bildes abschalten (alle 0,3 s), schlafende Gegner weit weg anhalten (auch ihre Animation)
func _spar_tick() -> void:
	var c := cam_pos
	for l in lichter:
		if is_instance_valid(l):
			l.visible = l.global_position.distance_squared_to(c) < 44.0 * 44.0

func _foes_sleep_far() -> void:
	if freeze_foes:
		return
	var c := hero.global_position
	for f in foes:
		var far: bool = f.state == Foe.St.SLEEP and f.global_position.distance_squared_to(c) > 48.0 * 48.0
		if far != (f.process_mode == Node.PROCESS_MODE_DISABLED):
			f.process_mode = Node.PROCESS_MODE_DISABLED if far else Node.PROCESS_MODE_INHERIT

func _process(delta: float) -> void:
	spar_t -= delta
	if spar_t <= 0.0 and hero:
		spar_t = 0.3
		_spar_tick()
	shake = maxf(0.0, shake - delta * 2.2)
	_place_cam(delta)
	# Durchblick der Mauern (mauer.gdshader): Kamera und Figur als globale Werte
	RenderingServer.global_shader_parameter_set("cut_cam", cam.global_position)
	RenderingServer.global_shader_parameter_set("cut_hero", hero.global_position)
	var t := Time.get_ticks_msec() * 0.001
	for tc in torches:
		tc.l.light_energy = tc.get("e", 1.9) * (1.0 + sin(t * 9.0 + tc.ph) * 0.11 + sin(t * 23.0 + tc.ph * 2.0) * 0.06)
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
