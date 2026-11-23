class_name Bild extends Node
# Bildstil je Stunde (4.1): Jede Stunde bekommt ihre eigene Farbe der Nacht. Mondlicht, Grundlicht, Tiefennebel,
# eine Farbkurve (Schatten in der Farbe der Stunde, Lichter warm), ein Randlicht an den Figuren, damit sie sich vom
# Boden lösen, ein dunkler Rand ums Bild und Teilchen in der Luft (Sand, Glut, Irrlichter, Funkeln).
# Alles bleibt im Renderer GL Compatibility. Teures (Randlicht an allen Gegnern, Funken an den Fackeln, dichtere Luft)
# nur am Desktop: „Desktop schöner, Web als Demo“. Mit „-- --webbild“ zeigt der Desktop das Bild der Webfassung.

# je Stunde: Mond (Farbe, Stärke, Höhe in Grad), Grundlicht (Farbe, Stärke), Nebel, Hintergrund,
# Farbkurve (schatten, licht), Randlicht der Figuren, Rand des Bildes und Luft (Art, Farbe)
const STUNDE := {
	1: {"name": "Tor des Westens: kaltes Mondlicht, Silber",
		"mond": Color(0.64, 0.76, 1.0), "mond_e": 0.78, "hoehe": -50.0, "amb": Color(0.36, 0.45, 0.78), "amb_e": 0.36,
		"nebel": Color(0.04, 0.07, 0.17), "bg": Color(0.015, 0.025, 0.07),
		"schatten": Color(0.02, 0.045, 0.12), "licht": Color(1.0, 0.97, 0.92), "rand": Color(0.55, 0.72, 1.0),
		"rahmen": Color(0.0, 0.01, 0.05), "luft": "irrlicht", "luft_c": Color(0.74, 0.84, 1.0)},
	2: {"name": "Felder von Wernes: Dämmerung über dem Korn, Oliv und Gold",
		"mond": Color(0.84, 0.88, 0.8), "mond_e": 0.34, "hoehe": -46.0, "amb": Color(0.36, 0.5, 0.48), "amb_e": 0.42,
		"nebel": Color(0.09, 0.1, 0.05), "bg": Color(0.012, 0.014, 0.008),
		"schatten": Color(0.03, 0.05, 0.03), "licht": Color(1.0, 0.97, 0.9), "rand": Color(1.0, 0.86, 0.52),
		"rahmen": Color(0.03, 0.03, 0.0), "luft": "staub", "luft_c": Color(1.0, 0.86, 0.5)},
	3: {"name": "König ohne Namen: Bernstein, tiefbraune Schatten",
		"mond": Color(1.0, 0.74, 0.46), "mond_e": 0.26, "hoehe": -55.0, "amb": Color(0.44, 0.4, 0.46), "amb_e": 0.4,
		"nebel": Color(0.12, 0.065, 0.03), "bg": Color(0.018, 0.01, 0.005),
		"schatten": Color(0.075, 0.035, 0.012), "licht": Color(1.0, 0.93, 0.8), "rand": Color(1.0, 0.72, 0.38),
		"rahmen": Color(0.05, 0.015, 0.0), "luft": "staub", "luft_c": Color(1.0, 0.78, 0.42)},
	4: {"name": "Rosetau: kaltes Glas, Türkis",
		"mond": Color(0.56, 0.9, 1.0), "mond_e": 0.36, "hoehe": -58.0, "amb": Color(0.3, 0.5, 0.62), "amb_e": 0.42,
		"nebel": Color(0.02, 0.09, 0.12), "bg": Color(0.004, 0.015, 0.025),
		"schatten": Color(0.0, 0.05, 0.075), "licht": Color(0.94, 1.0, 1.0), "rand": Color(0.52, 0.95, 1.0),
		"rahmen": Color(0.0, 0.025, 0.045), "luft": "funkeln", "luft_c": Color(0.62, 0.96, 0.94)},
	5: {"name": "Höhle des Sokar: Violett, fahle Krüge",
		"mond": Color(0.74, 0.64, 0.96), "mond_e": 0.32, "hoehe": -60.0, "amb": Color(0.44, 0.37, 0.6), "amb_e": 0.42,
		"nebel": Color(0.08, 0.035, 0.13), "bg": Color(0.012, 0.006, 0.022),
		"schatten": Color(0.055, 0.015, 0.09), "licht": Color(1.0, 0.94, 1.0), "rand": Color(0.86, 0.66, 1.0),
		"rahmen": Color(0.03, 0.0, 0.05), "luft": "irrlicht", "luft_c": Color(0.8, 0.66, 1.0)},
	6: {"name": "Leib des Osiris: Mitternacht, Grün des Osiris und Gold",
		"mond": Color(0.68, 0.95, 0.74), "mond_e": 0.28, "hoehe": -64.0, "amb": Color(0.37, 0.46, 0.38), "amb_e": 0.38,
		"nebel": Color(0.03, 0.08, 0.045), "bg": Color(0.004, 0.014, 0.008),
		"schatten": Color(0.015, 0.06, 0.03), "licht": Color(1.0, 0.96, 0.82), "rand": Color(0.66, 1.0, 0.66),
		"rahmen": Color(0.0, 0.03, 0.01), "luft": "irrlicht", "luft_c": Color(0.78, 1.0, 0.6)},
	7: {"name": "Sandbank des Apophis: Blutmond, Sand im Wind",
		"mond": Color(1.0, 0.68, 0.56), "mond_e": 0.62, "hoehe": -38.0, "amb": Color(0.36, 0.34, 0.62), "amb_e": 0.38,
		"nebel": Color(0.13, 0.035, 0.05), "bg": Color(0.03, 0.006, 0.012),
		"schatten": Color(0.04, 0.02, 0.06), "licht": Color(1.0, 0.92, 0.84), "rand": Color(1.0, 0.6, 0.48),
		"rahmen": Color(0.05, 0.0, 0.01), "luft": "sand", "luft_c": Color(0.95, 0.66, 0.5)},
	8: {"name": "Grüfte der Götter: Indigo, goldene Bienen",
		"mond": Color(0.6, 0.64, 1.0), "mond_e": 0.32, "hoehe": -56.0, "amb": Color(0.4, 0.4, 0.66), "amb_e": 0.4,
		"nebel": Color(0.04, 0.04, 0.13), "bg": Color(0.006, 0.006, 0.024),
		"schatten": Color(0.03, 0.03, 0.095), "licht": Color(1.0, 0.95, 0.85), "rand": Color(1.0, 0.84, 0.52),
		"rahmen": Color(0.0, 0.0, 0.05), "luft": "funkeln", "luft_c": Color(1.0, 0.82, 0.4)},
	9: {"name": "Die Ruderer: Fluss, Blaugrün",
		"mond": Color(0.56, 0.82, 0.96), "mond_e": 0.34, "hoehe": -50.0, "amb": Color(0.3, 0.47, 0.58), "amb_e": 0.42,
		"nebel": Color(0.02, 0.07, 0.1), "bg": Color(0.004, 0.012, 0.02),
		"schatten": Color(0.01, 0.05, 0.075), "licht": Color(0.96, 1.0, 1.0), "rand": Color(0.62, 0.9, 1.0),
		"rahmen": Color(0.0, 0.02, 0.04), "luft": "irrlicht", "luft_c": Color(0.66, 0.9, 1.0)},
	10: {"name": "Ertrunkene im Nun: trübes Urwasser, Grün",
		"mond": Color(0.48, 0.8, 0.84), "mond_e": 0.3, "hoehe": -62.0, "amb": Color(0.28, 0.45, 0.5), "amb_e": 0.44,
		"nebel": Color(0.02, 0.09, 0.075), "bg": Color(0.002, 0.016, 0.014),
		"schatten": Color(0.0, 0.06, 0.05), "licht": Color(0.92, 1.0, 0.94), "rand": Color(0.56, 1.0, 0.84),
		"rahmen": Color(0.0, 0.03, 0.025), "luft": "blasen", "luft_c": Color(0.6, 0.95, 0.85)},
	11: {"name": "Feuergruben: Glut, Rot",
		"mond": Color(1.0, 0.5, 0.3), "mond_e": 0.32, "hoehe": -58.0, "amb": Color(0.46, 0.3, 0.36), "amb_e": 0.4,
		"nebel": Color(0.14, 0.035, 0.015), "bg": Color(0.03, 0.006, 0.002),
		"schatten": Color(0.09, 0.015, 0.005), "licht": Color(1.0, 0.92, 0.78), "rand": Color(1.0, 0.56, 0.26),
		"rahmen": Color(0.06, 0.0, 0.0), "luft": "glut", "luft_c": Color(1.0, 0.5, 0.18)},
	12: {"name": "Tor des Ostens: erstes Grau des Morgens, Rosé",
		"mond": Color(1.0, 0.8, 0.72), "mond_e": 0.6, "hoehe": -30.0, "amb": Color(0.55, 0.5, 0.64), "amb_e": 0.36,
		"nebel": Color(0.12, 0.08, 0.11), "bg": Color(0.035, 0.025, 0.04),
		"schatten": Color(0.06, 0.035, 0.07), "licht": Color(1.0, 0.94, 0.86), "rand": Color(1.0, 0.8, 0.66),
		"rahmen": Color(0.04, 0.015, 0.03), "luft": "sand", "luft_c": Color(1.0, 0.86, 0.76)},
}

# Randlicht: von hinten und von der Seite leuchtet der Umriss der Figur in der Farbe der Stunde (aufaddiert)
const RAND := """shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_back, shadows_disabled, fog_disabled;
uniform vec4 farbe : source_color = vec4(0.6, 0.75, 1.0, 1.0);
uniform float kraft = 0.6;
void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.4);
	vec3 wn = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	f *= 0.45 + 0.55 * clamp(wn.y + 0.6, 0.0, 1.0);   // von oben stärker, als fiele das Mondlicht darauf
	ALBEDO = farbe.rgb * f * kraft;
}"""

# Rand des Bildes: zu den Ecken hin dunkler, oben (in der Ferne) ein Hauch der Stundenfarbe. Liest den Bildschirm nicht,
# ist nur eine durchscheinende Fläche: kostet auch im Browser fast nichts.
const RAHMEN := """shader_type canvas_item;
uniform vec4 farbe : source_color = vec4(0.0, 0.01, 0.05, 1.0);
uniform float kraft = 0.62;
uniform float oben = 0.28;
void fragment() {
	vec2 q = UV - 0.5;
	q.x *= 1.25;
	float r = smoothstep(0.32, 0.82, length(q));
	float o = smoothstep(0.5, 0.0, UV.y) * oben;
	COLOR = vec4(farbe.rgb, clamp(r * kraft + o, 0.0, 0.92));
}"""

static var rand_mat: ShaderMaterial
static var cache := {}

var g: Node
var luft: CPUParticles3D
var rahmen: ColorRect
var L: Dictionary

static func desktop() -> bool:
	return not OS.has_feature("web") and not "--webbild" in OS.get_cmdline_user_args()

static func stunde_nr() -> int:
	return clampi(Stunden.hour_of(Spiel.fall), 1, 12)

static func randlicht() -> ShaderMaterial:
	if rand_mat == null:
		var s := Shader.new()
		s.code = RAND
		rand_mat = ShaderMaterial.new()
		rand_mat.shader = s
	return rand_mat

# Soll diese Figur ein Randlicht tragen? Am Desktop alle, im Browser nur die eigene Figur (ein Zeichenaufruf mehr je Teil)
static func rand_fuer(a: Node) -> Material:
	if desktop() or a is Hero:
		return randlicht()
	return null

func _init(game: Node) -> void:
	g = game
	name = "Bild"

# Licht, Nebel, Farbkurve und Glühen der Stunde einstellen (nach dem Bau der Welt)
func stellen() -> void:
	L = STUNDE[stunde_nr()]
	var env: Environment = g.env
	var dt := desktop()
	env.background_color = L.bg
	env.ambient_light_color = L.amb
	env.ambient_light_energy = L.amb_e
	# Tiefennebel: was weiter weg liegt als die Figur (oben im Bild), versinkt in der Farbe der Stunde
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = L.nebel
	env.fog_light_energy = 1.0
	env.fog_density = 0.85
	env.fog_depth_begin = 33.0   # die Kamera steht etwa 28 m von der Figur: um sie herum bleibt die Luft klar
	env.fog_depth_end = 76.0
	env.fog_depth_curve = 1.6
	env.fog_sky_affect = 0.0
	# Glühen: Flammen, Feuerschalen und Zauber strahlen über ihren Rand hinaus
	env.glow_intensity = 1.1 if dt else 0.8
	env.glow_strength = 1.0
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 0.78
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT if not dt else Environment.GLOW_BLEND_MODE_SCREEN
	for i in 7:
		env.set_glow_level(i, [0.0, 0.0, 1.0, 0.8, 0.6 if dt else 0.0, 0.4 if dt else 0.0, 0.0][i])
	# Farbkurve: Schatten in der Farbe der Stunde, Lichter warm; dazu etwas mehr Kontrast
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	env.adjustment_contrast = 1.1
	env.adjustment_saturation = 1.08
	env.adjustment_color_correction = _kurve(L.schatten, L.licht)
	var moon: DirectionalLight3D = g.moon
	moon.light_color = L.mond
	moon.light_energy = L.mond_e
	moon.rotation_degrees = Vector3(L.hoehe, -35, 0)
	# Schatten: kürzerer Abstand, dafür schärfer (die Kamera sieht ohnehin nur etwa 40 m weit)
	moon.directional_shadow_max_distance = 44.0
	moon.shadow_blur = 1.4 if dt else 1.0
	moon.shadow_normal_bias = 1.2
	# etwas zum Weiß hin: Das Randlicht soll die Figur vom Boden trennen, auch wenn Boden und Licht dieselbe Farbe haben
	randlicht().set_shader_parameter("farbe", L.rand.lerp(Color(0.9, 0.95, 1.0), 0.35))
	randlicht().set_shader_parameter("kraft", 1.0)
	_rahmen()
	_luft()

static func _kurve(schatten: Color, licht: Color) -> GradientTexture1D:
	var key := schatten.to_html() + licht.to_html()
	if cache.has(key):
		return cache[key]
	var gr := Gradient.new()
	gr.set_color(0, schatten)
	gr.set_offset(0, 0.0)
	gr.set_color(1, licht)
	gr.set_offset(1, 1.0)
	var mitte := Color(0.5, 0.5, 0.5).lerp(schatten * 4.0, 0.12)
	gr.add_point(0.5, mitte)
	var t := GradientTexture1D.new()
	t.gradient = gr
	t.width = 256
	cache[key] = t
	return t

func _rahmen() -> void:
	var cl := CanvasLayer.new()
	cl.layer = -1     # unter der Oberfläche, über der Welt
	add_child(cl)
	rahmen = ColorRect.new()
	rahmen.set_anchors_preset(Control.PRESET_FULL_RECT)
	rahmen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := Shader.new()
	s.code = RAHMEN
	var m := ShaderMaterial.new()
	m.shader = s
	m.set_shader_parameter("farbe", L.rahmen)
	rahmen.material = m
	cl.add_child(rahmen)

# Luft der Stunde: Teilchen um die Kamera, die mit ihr wandern
func _luft() -> void:
	var art: String = L.luft
	var c: Color = L.luft_c
	var dt := desktop()
	var p := CPUParticles3D.new()
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(12.0, 2.0, 12.0)
	p.gravity = Vector3.ZERO
	var groesse := 0.05
	var hell := 2.2
	match art:
		"sand":      # Sand, der waagrecht über den Boden treibt
			p.amount = 110 if dt else 50
			p.lifetime = 3.0
			p.direction = Vector3(1, 0.05, 0.4)
			p.spread = 8.0
			p.initial_velocity_min = 3.5
			p.initial_velocity_max = 6.5
			p.emission_box_extents = Vector3(12.0, 0.8, 12.0)
			groesse = 0.07
			hell = 1.0
		"glut":      # Glutfunken steigen auf und verlöschen
			p.amount = 70 if dt else 30
			p.lifetime = 4.0
			p.direction = Vector3(0.15, 1, 0.05)
			p.spread = 20.0
			p.gravity = Vector3(0.3, 0.6, 0.0)
			p.initial_velocity_min = 0.4
			p.initial_velocity_max = 1.4
			groesse = 0.13
			hell = 3.0
		"blasen":    # trübe Schwebeteilchen im Urwasser, steigen langsam
			p.amount = 60 if dt else 26
			p.lifetime = 7.0
			p.direction = Vector3(0, 1, 0)
			p.spread = 30.0
			p.initial_velocity_min = 0.15
			p.initial_velocity_max = 0.45
			groesse = 0.12
			hell = 1.3
		"funkeln":   # kalte Funken, die kurz aufblitzen
			p.amount = 60 if dt else 26
			p.lifetime = 2.6
			p.direction = Vector3(0, 1, 0)
			p.spread = 180.0
			p.initial_velocity_min = 0.05
			p.initial_velocity_max = 0.25
			groesse = 0.11
			hell = 3.2
		"staub":     # Spreu und Staub, der im Licht steht
			p.amount = 80 if dt else 36
			p.lifetime = 6.0
			p.direction = Vector3(0.4, 0.3, 0.2)
			p.spread = 90.0
			p.initial_velocity_min = 0.1
			p.initial_velocity_max = 0.35
			groesse = 0.08
			hell = 1.6
		_:           # Irrlichter: wenige, große, weich glühende Punkte, die langsam ziehen
			p.amount = 26 if dt else 12
			p.lifetime = 8.0
			p.direction = Vector3(-1, 0.2, 0.3)
			p.spread = 60.0
			p.initial_velocity_min = 0.2
			p.initial_velocity_max = 0.5
			p.emission_box_extents = Vector3(12.0, 1.6, 12.0)
			groesse = 0.2
			hell = 3.0
	p.preprocess = p.lifetime
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.4
	# auf- und abschwellen über die Größe (Farbverläufe je Teilchen zeigt der Web-Renderer hier nicht zuverlässig)
	var kurve := Curve.new()
	kurve.add_point(Vector2(0.0, 0.0))
	kurve.add_point(Vector2(0.2, 1.0))
	kurve.add_point(Vector2(0.7, 0.85))
	kurve.add_point(Vector2(1.0, 0.0))
	p.scale_amount_curve = kurve
	# kleine Kugeln statt Flächen mit Punktbild: Das Bild blieb im Kompatibilitäts-Renderer unsichtbar
	var q := _kugel(groesse * (0.4 if art == "sand" else 0.5))
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(minf(c.r * hell, 1.0), minf(c.g * hell, 1.0), minf(c.b * hell, 1.0), 0.9)
	m.disable_fog = true
	q.material = m
	p.mesh = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.custom_aabb = AABB(Vector3(-40, -10, -40), Vector3(80, 30, 80))   # wandert mit der Kamera: nie wegschneiden
	g.add_child(p)
	luft = p

static func _kugel(r: float) -> SphereMesh:
	var k := SphereMesh.new()
	k.radius = r
	k.height = r * 2.0
	k.radial_segments = 6
	k.rings = 3
	return k

func _process(_delta: float) -> void:
	if luft and g.cam:
		luft.global_position = g.cam_pos + Vector3(0, 1.4, 0)
		luft.emitting = not g.low_gfx
		luft.visible = not g.low_gfx

# Funken über einer Fackel oder Feuerschale (nur am Desktop)
static func funken(parent: Node3D, pos: Vector3, menge := 10) -> void:
	if not desktop():
		return
	var p := CPUParticles3D.new()
	p.amount = menge
	p.lifetime = 1.3
	p.preprocess = 1.3
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.08
	p.direction = Vector3(0, 1, 0)
	p.spread = 25.0
	p.gravity = Vector3(0, 0.8, 0)
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 1.2
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.0
	var kurve := Curve.new()
	kurve.add_point(Vector2(0.0, 1.0))
	kurve.add_point(Vector2(1.0, 0.0))
	p.scale_amount_curve = kurve
	var q := _kugel(0.035)
	if not cache.has("funke_mat"):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(1.0, 0.62, 0.22, 0.95)
		m.disable_fog = true
		cache["funke_mat"] = m
	q.material = cache["funke_mat"]
	p.mesh = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	p.position = pos
