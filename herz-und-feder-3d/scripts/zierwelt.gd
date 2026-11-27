class_name Zierwelt extends RefCounted
# Gemalte Bilder aus ComfyUI in der 3D-Welt (4.3, NACHTSCHICHTEN.md › Einbau, Stufen 15 bis 17; einbauen.bat zeichen|fx|fries):
#   Bodenzeichen  ui/zeichen/<id>.webp, RGB auf Schwarz: ein flaches Viereck knapp über dem Boden, additiv (Schwarz bleibt
#                 unsichtbar), ohne Licht und ohne Tiefenschreiben. Unter den Hütern, als Zauberkreise, an Feuerschalen.
#   Effektbilder  textures/fx/<id>.webp: Glut, Goldstaub, Dunst und Blitz auf Schwarz (additiv), Rauch und Sand mit Alpha.
#                 Als Bild der Teilchen statt farbiger Kugeln; ein geteiltes Material je Bild, Farbe und Ausblenden über
#                 die Teilchenfarbe.
#   Friese        textures/fries/<id>.jpg mit _n.jpg: bemalte Bänder an den Mauern der Gräber und Hallen.
# Fehlt eine Datei, gibt jede Funktion null (oder false) zurück, und der Aufrufer zeichnet wie vor 4.3.

const ZEICHEN := "res://ui/zeichen/%s.webp"
const FX := "res://textures/fx/%s.webp"
const FRIES := "res://textures/fries/%s.jpg"
const FX_ALPHA := ["rauch", "sand"]   # einbauen.bat › fx_art: mit Alphakanal, normal gemischt

# Das Zeichen unter dem Hüter jeder Stunde, nach der Geschichte (GESCHICHTE.md):
#   1 Mahaf heißt „der hinter sich schaut“: das Auge      2 die Mutter der Häute ist Brut des Apophis: die Schlange
#   3 der König mit dem Schwert aus dem Gold der Tagesbarke: die Sonne
#   4 der Türhüter in Rosetau, wo die Sterne erloschen sind: der Sternenkranz      5 der Sammler, ein Richter: die Waage
#   6 der falsche Osiris auf dem Lager, wo Re jung wird: die Lebenszeichen um den Lotos      7 Apophis: die Schlange
#   8 der Hüter ohne Stimme, aus dessen Gruft dein eigener Ba nicht rufen kann: die Feder mit Flügeln
#   9 die Ruderer der Sonnenbarke sind die Unermüdlichen Sterne      10 Horus zieht die Ertrunkenen ans Ufer: das Auge
#   11 am Rand der Grube, Gnade oder Ordnung: die Waage      12 am Tor des Ostens kommt Re als Chepri heraus: der Skarabäus
const HUETER := ["udjat", "schlange", "sonne", "sterne", "waage", "leben", "schlange", "feder", "sterne", "udjat", "waage", "skarabaeus"]

# Friese je Stunde: [Band auf halber Höhe, Band oben unter der Decke] („“ = keins). Nur in Gräbern und Hallen.
const FRIES_STUNDE := {
	2: ["lotos", ""], 3: ["schakale", "sterndecke"], 4: ["barke", "sterndecke"], 5: ["federn", ""],
	6: ["goetterzug", "sterndecke"], 8: ["goetterzug", ""], 9: ["barke", ""], 10: ["lotos", ""], 11: ["schakale", "sterndecke"],
}
# Wo im Bild das bemalte Band liegt (v von oben nach unten): darüber und darunter ist nur Stein, den die Mauer schon hat
const FRIES_V := {"barke": [0.2, 0.78], "federn": [0.29, 0.75], "goetterzug": [0.2, 0.84], "lotos": [0.2, 0.84],
	"schakale": [0.24, 0.8], "sterndecke": [0.0, 0.58]}
const FRIES_HELL := Color(0.92, 0.88, 0.84)   # die Bänder sind schon auf die Helligkeit der Mauern gedämpft (hell_ziel)

const ZEICHEN_SHADER := """shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform sampler2D bild : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 farbe : source_color = vec4(1.0);
uniform float kraft = 1.0;
uniform float dreh = 0.0;
uniform float phase = 0.0;
uniform float puls = 0.0;
void fragment() {
	float a = TIME * dreh + phase;
	vec2 q = UV - 0.5;
	q = vec2(q.x * cos(a) - q.y * sin(a), q.x * sin(a) + q.y * cos(a));
	float rund = 1.0 - smoothstep(0.47, 0.5, length(q));
	float p = 1.0 + puls * sin(TIME * 1.7 + phase);
	ALBEDO = texture(bild, q + 0.5).rgb * farbe.rgb * (kraft * rund * p);
}"""

static var cache := {}

static func zeichen_da(id: String) -> bool:
	return id != "" and ResourceLoader.exists(ZEICHEN % id)

static func fx_da(id: String) -> bool:
	return ResourceLoader.exists(FX % id)

static func hueter_zeichen(n: int) -> String:
	return HUETER[(Stunden.hour_of(n) - 1) % HUETER.size()]

static func _shader() -> Shader:
	if not cache.has("shader"):
		var s := Shader.new()
		s.code = ZEICHEN_SHADER
		cache["shader"] = s
	return cache["shader"]

static func _quad(groesse: float) -> QuadMesh:
	var k := "quad_%.2f" % groesse
	if not cache.has(k):
		var q := QuadMesh.new()
		q.size = Vector2(groesse, groesse)
		q.orientation = PlaneMesh.FACE_Y
		cache[k] = q
	return cache[k]

# Material eines Zeichens. Ohne „eigen“ teilen sich alle mit denselben Werten eines (Kulisse); mit „eigen“ bekommt
# es ein eigenes, das man aufblenden und heller machen kann (Hüter, Zauberkreise). Die Textur ist immer dieselbe.
static func zeichen_mat(id: String, farbe := Color.WHITE, kraft := 1.0, dreh := 0.0, eigen := false) -> ShaderMaterial:
	if not zeichen_da(id):
		return null
	var k := "z_%s_%s_%.2f_%.3f" % [id, farbe.to_html(), kraft, dreh]
	if not eigen and cache.has(k):
		return cache[k]
	var m := ShaderMaterial.new()
	m.shader = _shader()
	m.set_shader_parameter("bild", load(ZEICHEN % id))
	m.set_shader_parameter("farbe", farbe)
	m.set_shader_parameter("kraft", kraft)
	m.set_shader_parameter("dreh", dreh)
	m.set_shader_parameter("phase", fmod(Time.get_ticks_usec() * 0.000731, TAU) if eigen else 0.0)   # nicht randf: die Welt würfelt gleich, ob mit Bild oder ohne
	if not eigen:
		cache[k] = m
	return m

# Bodenzeichen: liegt flach auf dem Boden, Mitte pos, Halbmesser radius. dreh: Drehung je Sekunde (langsam: 0,03)
static func bodenzeichen(parent: Node, pos: Vector3, radius: float, id: String, farbe := Color.WHITE, kraft := 1.0, dreh := 0.0, eigen := false) -> MeshInstance3D:
	var m := zeichen_mat(id, farbe, kraft, dreh, eigen)
	if m == null:
		return null
	var mi := MeshInstance3D.new()
	mi.mesh = _quad(2.0)
	mi.material_override = m
	mi.scale = Vector3(radius, 1.0, radius)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.position = pos + Vector3(0, 0.06, 0)
	return mi

# Zeichen, das aufleuchtet und vergeht (Zauberkreis): wächst kurz auf, wird hell, blendet aus. false = Datei fehlt
static func aufleuchten(g: Node, c: Vector3, r: float, id: String, farbe := Color.WHITE, dauer := 0.7, kraft := 1.4) -> bool:
	var mi := bodenzeichen(g, Vector3(c.x, 0.0, c.z), r, id, farbe, 0.0, 0.5, true)
	if mi == null:
		return false
	var m: ShaderMaterial = mi.material_override
	mi.scale = Vector3(r * 0.6, 1.0, r * 0.6)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(r, 1.0, r), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_method(func(v: float): m.set_shader_parameter("kraft", v), 0.0, kraft, 0.12)
	tw.tween_method(func(v: float): m.set_shader_parameter("kraft", v), kraft, 0.0, maxf(0.2, dauer - 0.12)).set_ease(Tween.EASE_IN)
	tw.tween_callback(mi.queue_free)
	return true

# Helligkeit eines eigenen Zeichens weich ändern
static func hell_setzen(mi: MeshInstance3D, ziel: float, dauer := 0.8) -> void:
	if mi == null or not is_instance_valid(mi):
		return
	var m: ShaderMaterial = mi.material_override
	var von: float = m.get_shader_parameter("kraft")
	mi.create_tween().tween_method(func(v: float): m.set_shader_parameter("kraft", v), von, ziel, dauer)

# ---------------------------------------------------------------- Effektbilder
static func fx_mat(id: String) -> StandardMaterial3D:
	if not fx_da(id):
		return null
	var k := "fx_" + id
	if cache.has(k):
		return cache[k]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = load(FX % id)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if not id in FX_ALPHA:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.disable_fog = true
	cache[k] = m
	return m

# Teilchen mit einem Effektbild: gedreht, in der Größe gestreut, blenden weich ein und aus. Richtung, Schwere und
# Austrittsform setzt der Aufrufer. null = Bild fehlt (dann bleibt es bei den alten Teilchen)
static func teilchen(id: String, menge: int, leben: float, groesse: float, farbe := Color.WHITE) -> CPUParticles3D:
	var m := fx_mat(id)
	if m == null:
		return null
	var k := "fxq_%s_%.2f" % [id, groesse]
	if not cache.has(k):
		var q := QuadMesh.new()
		q.size = Vector2(groesse, groesse)
		q.material = m
		cache[k] = q
	var p := CPUParticles3D.new()
	p.amount = maxi(1, menge)
	p.lifetime = leben
	p.mesh = cache[k]
	p.local_coords = false
	p.angle_min = -180.0
	p.angle_max = 180.0
	p.angular_velocity_min = -30.0
	p.angular_velocity_max = 30.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var g := Gradient.new()
	g.set_color(0, Color(farbe, 0.0))
	g.add_point(0.2, farbe)
	g.add_point(0.65, Color(farbe, farbe.a * 0.7))
	g.set_color(g.get_point_count() - 1, Color(farbe, 0.0))
	p.color_ramp = g
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p

# Einmaliger Ausstoß (Stufenaufstieg, Truhe, Einschlag): räumt sich selbst auf. false = Bild fehlt
static func stoss(g: Node, id: String, pos: Vector3, menge: int, groesse: float, farbe := Color.WHITE, tempo := 3.0, schwere := -2.0, leben := 1.2, radius := 0.4) -> bool:
	var p := teilchen(id, menge, leben, groesse, farbe)
	if p == null:
		return false
	p.one_shot = true
	p.explosiveness = 0.9
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius
	p.direction = Vector3(0, 1, 0)
	p.spread = 70.0
	p.initial_velocity_min = tempo * 0.4
	p.initial_velocity_max = tempo
	p.gravity = Vector3(0, schwere, 0)
	p.damping_min = 1.0
	p.damping_max = 2.5
	g.add_child(p)
	p.global_position = pos
	p.emitting = true
	g.get_tree().create_timer(leben + 0.6).timeout.connect(p.queue_free)
	return true

# Glut über einem Feuer: Funken steigen, ein wenig Rauch darüber (Rauch nur auf hoher Grafikstufe)
static func feuer_glut(parent: Node3D, at: Vector3, gross := 1.0, low := false) -> bool:
	var p := teilchen("glut", 6 if low else 12, 1.3, 0.38 * gross, Color(1.0, 0.85, 0.7))
	if p == null:
		return false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.25 * gross
	p.direction = Vector3(0, 1, 0)
	p.spread = 18.0
	p.initial_velocity_min = 0.6 * gross
	p.initial_velocity_max = 1.4 * gross
	p.gravity = Vector3(0, 0.6, 0)
	p.scale_amount_min = 0.3
	p.scale_amount_max = 1.0
	parent.add_child(p)
	p.position = at
	if not low:
		var r := teilchen("rauch", 5, 3.2, 1.1 * gross, Color(0.22, 0.2, 0.19, 0.35))
		if r:
			r.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			r.emission_sphere_radius = 0.2 * gross
			r.direction = Vector3(0, 1, 0)
			r.spread = 12.0
			r.initial_velocity_min = 0.4
			r.initial_velocity_max = 0.8
			r.gravity = Vector3(0.15, 0.25, 0.05)
			r.scale_amount_min = 0.7
			r.scale_amount_max = 1.6
			parent.add_child(r)
			r.position = at + Vector3(0, 0.6 * gross, 0)
	return true

# Flamme wie Stimmung.flamme, aber ohne zu würfeln (die Welt wird beim Bauen mit festem Startwert gewürfelt; ein Feuer,
# das es nur mit Bild gibt, soll daran nichts ändern)
static func flamme(parent: Node, pos: Vector3, hoehe: float, breite: float) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	n.position = pos
	var m := ShaderMaterial.new()
	m.shader = Stimmung._shader("flamme", Stimmung.FLAMME)
	m.set_shader_parameter("farbe", Color(1.0, 0.55, 0.16))
	m.set_shader_parameter("phase", fmod(pos.x * 0.37 + pos.z * 0.11, 10.0))
	for i in 2:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(breite, hoehe)
		mi.mesh = q
		mi.material_override = m
		mi.position.y = hoehe * 0.5
		mi.rotation.y = i * PI * 0.5 + 0.4
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(mi)
	return n

# ---------------------------------------------------------------- Friese
static func fries_der_stunde(n: int) -> Array:
	return FRIES_STUNDE.get(Stunden.hour_of(n), ["", ""])

static func fries_da(id: String) -> bool:
	return id != "" and ResourceLoader.exists(FRIES % id)

# Ein Band an der Mauer: derselbe Durchblick-Shader wie die Mauer (mauer.gdshader), damit es mit ihr ausgespart wird
static func fries_mat(id: String, shader: Shader, low: bool) -> ShaderMaterial:
	if not fries_da(id):
		return null
	var k := "fries_" + id
	if cache.has(k):
		return cache[k]
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("tex_albedo", load(FRIES % id))
	m.set_shader_parameter("tint", FRIES_HELL)
	var np := "res://textures/fries/%s_n.jpg" % id
	var hat_n := ResourceLoader.exists(np)
	if hat_n:
		m.set_shader_parameter("tex_normal", load(np))
	m.set_shader_parameter("use_normal", hat_n and not low)
	m.set_meta("hat_n", hat_n)
	cache[k] = m
	return m

# Grafikstufe (main.gd › set_low): ohne Reliefkarte auf „Niedrig“
static func grafik(low: bool) -> void:
	for k in cache:
		if str(k).begins_with("fries_"):
			cache[k].set_shader_parameter("use_normal", not low and cache[k].get_meta("hat_n", false))
