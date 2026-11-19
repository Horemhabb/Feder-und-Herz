class_name Stimmung extends RefCounted
# Atmosphäre als Illusion (Fassung 2.3): Lichtstrahlen, Bodennebel, glühende Runen, Staub im Licht, Säulen.
# Der Web-Renderer (GL Compatibility) kennt weder Volumennebel noch Decals noch Lichtprojektoren. Diese Bausteine
# täuschen dasselbe mit ein paar durchscheinenden Flächen und kleinen Shadern vor. Jede kostet einen Zeichenaufruf.

static var cache := {}

const STRAHL := """shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec4 farbe : source_color = vec4(1.0, 0.82, 0.5, 1.0);
uniform float kraft = 0.5;
varying float schraeg;
void vertex() {
	// von der Seite gesehen leuchtet der Strahl, von vorn auf die Kante gesehen verschwindet die Fläche
	vec3 n = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 v = normalize((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	schraeg = abs(dot(n, v));
}
void fragment() {
	float seite = smoothstep(0.0, 0.4, UV.x) * smoothstep(1.0, 0.6, UV.x);
	float laenge = smoothstep(0.0, 0.06, UV.y) * mix(1.0, 0.18, UV.y);
	float streifen = 0.72 + 0.28 * sin(UV.x * 34.0 + sin(UV.x * 11.0 + TIME * 0.25) * 2.2);
	ALBEDO = farbe.rgb;
	ALPHA = seite * laenge * streifen * kraft * smoothstep(0.05, 0.5, schraeg);
}"""

const NEBEL := """shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec4 farbe : source_color = vec4(0.6, 0.7, 0.9, 1.0);
uniform float kraft = 0.35;
uniform float tempo = 0.03;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
	vec2 p = UV * 4.0 + vec2(TIME * tempo, TIME * tempo * 0.6);
	float w = n(p) * 0.6 + n(p * 2.3 - TIME * tempo) * 0.4;
	float rand = 1.0 - smoothstep(0.25, 0.5, length(UV - 0.5));
	ALBEDO = farbe.rgb;
	ALPHA = smoothstep(0.3, 0.9, w) * rand * kraft;
}"""

const RUNE := """shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform sampler2D maske : source_color, filter_linear_mipmap;
uniform vec4 farbe : source_color = vec4(0.3, 0.9, 0.85, 1.0);
uniform float kraft = 1.0;
uniform float dreh = 0.05;
uniform float phase = 0.0;
void fragment() {
	float a = TIME * dreh;
	vec2 q = UV - 0.5;
	q = vec2(q.x * cos(a) - q.y * sin(a), q.x * sin(a) + q.y * cos(a)) + 0.5;
	float m = texture(maske, q).a * step(0.0, q.x) * step(q.x, 1.0) * step(0.0, q.y) * step(q.y, 1.0);
	ALBEDO = farbe.rgb * (1.0 + 0.6 * m);
	ALPHA = m * kraft * (0.72 + 0.28 * sin(TIME * 1.4 + phase));
}"""

const FLAMME := """shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec4 farbe : source_color = vec4(1.0, 0.55, 0.16, 1.0);
uniform float phase = 0.0;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
	float y = 1.0 - UV.y;                      // 0 unten, 1 an der Spitze
	float x = (UV.x - 0.5) * 2.0;
	float t = TIME + phase;
	float w = n(vec2(UV.x * 3.0 + phase, y * 2.6 - t * 2.3));
	float w2 = n(vec2(UV.x * 7.0 + 3.0, y * 5.2 - t * 3.6));
	float breite = 0.78 * pow(1.0 - y, 0.8) + 0.04;
	float form = 1.0 - smoothstep(0.0, 1.0, abs(x + (w - 0.5) * 0.7 * y) / breite);
	float a = form * smoothstep(0.0, 0.1, y) * (0.55 + 0.7 * w2);
	ALBEDO = mix(farbe.rgb, vec3(1.0, 0.92, 0.6), clamp(form * form * (1.2 - y), 0.0, 1.0));
	ALPHA = clamp(a, 0.0, 1.0);
}"""

# Schleier vor einem Gesicht (2.9.1): ein ovaler Dunst, durch den waagrechte Hitzeschlieren nach oben ziehen,
# am Rand ausgefranst, mit einzelnen Funken. Er dreht sich immer zur Kamera: Von keiner Seite ist das Gesicht zu sehen.
const SCHLEIER := """shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec4 tief : source_color = vec4(0.16, 0.36, 0.38, 1.0);
uniform vec4 hell : source_color = vec4(0.78, 0.97, 0.92, 1.0);
uniform float phase = 0.0;
uniform float vor = 0.16;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex() {
	mat4 mv = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	mv[3].z += vor;   // ein Stück zur Kamera hin: der Kopf dahinter verdeckt ihn nie, von keiner Seite
	MODELVIEW_MATRIX = mv;
}
void fragment() {
	float t = TIME + phase;
	vec2 q = (UV - 0.5) * vec2(2.0, 2.0);
	// Schlieren: waagrecht gestreckt, steigen langsam, verbiegen den Umriss
	float s1 = n(vec2(UV.x * 3.0 + t * 0.2, UV.y * 9.0 + t * 1.6));
	float s2 = n(vec2(UV.x * 7.0 - t * 0.3, UV.y * 17.0 + t * 2.7));
	float rand = 0.82 + (s1 - 0.5) * 0.35;
	float oval = length(q * vec2(1.0, 0.86));
	float maske = 1.0 - smoothstep(rand - 0.38, rand, oval);
	float flimmer = 0.6 + 0.4 * sin(t * 7.0 + UV.y * 22.0 + s2 * 6.0);
	vec3 c = mix(tief.rgb, hell.rgb, clamp(s1 * 0.8 + s2 * 0.5 * flimmer, 0.0, 1.0));
	float funke = step(0.985, h(floor(UV * 26.0) + floor(t * 6.0))) * maske;
	ALBEDO = c + vec3(funke);
	ALPHA = clamp(maske * (0.74 + 0.24 * s2 * flimmer) + funke, 0.0, 0.96);
}"""

# Blick durch die Pforte (3.1): eine gemalte Ferne der nächsten Stunde. Himmel in ihrer Farbe, ein Horizont aus Hügeln,
# Dunst, der langsam zieht, Sterne, die blinken, und ein Lichtpunkt, der näher zu kommen scheint. Kein zweites Bild:
# eine Fläche mit einem Shader, damit es im Browser läuft.
const BLICK := """shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 himmel : source_color = vec4(0.1, 0.2, 0.3, 1.0);
uniform vec4 boden : source_color = vec4(0.3, 0.28, 0.24, 1.0);
uniform vec4 licht : source_color = vec4(0.6, 0.95, 0.9, 1.0);
uniform float auf = 1.0;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
	vec2 uv = vec2(UV.x, 1.0 - UV.y);          // 0 unten, 1 oben
	float t = TIME;
	vec3 c = mix(himmel.rgb * 0.35, himmel.rgb * 1.1, smoothstep(0.25, 1.0, uv.y));
	// Sterne
	vec2 g = floor(uv * vec2(40.0, 70.0));
	float st = step(0.985, h(g)) * (0.5 + 0.5 * sin(t * 2.0 + h(g + 3.0) * 40.0)) * smoothstep(0.45, 0.8, uv.y);
	c += vec3(st) * 0.9;
	// Horizont: zwei Hügelketten, die hintere heller
	float k1 = 0.34 + 0.05 * n(vec2(uv.x * 4.0, 1.0)) + 0.03 * sin(uv.x * 9.0);
	float k2 = 0.26 + 0.06 * n(vec2(uv.x * 6.0 + 7.0, 2.0));
	c = mix(c, mix(boden.rgb, himmel.rgb, 0.45), step(uv.y, k1));
	c = mix(c, boden.rgb * 0.7, step(uv.y, k2));
	// Lichtpunkt in der Ferne, pulsiert
	float d = length((uv - vec2(0.5, 0.36)) * vec2(1.4, 1.0));
	c += licht.rgb * (0.02 / (d * d + 0.004)) * (0.8 + 0.2 * sin(t * 1.7)) * 0.08;
	// ziehender Dunst
	float nb = n(vec2(uv.x * 3.0 - t * 0.12, uv.y * 5.0)) * n(vec2(uv.x * 7.0 + t * 0.2, uv.y * 9.0 + 3.0));
	c = mix(c, licht.rgb * 0.8, nb * 0.45 * smoothstep(0.55, 0.15, uv.y));
	// Rand: zum Rahmen hin heller, als käme Licht heraus
	float rand = min(min(uv.x, 1.0 - uv.x), 1.0 - uv.y) ;
	c += licht.rgb * (1.0 - smoothstep(0.0, 0.12, rand)) * 0.35;
	ALBEDO = c * auf;
}"""

static func blick(n: MeshInstance3D, himmel: Color, boden: Color, licht: Color, breite: float, hoehe: float) -> ShaderMaterial:
	n.mesh = _quad(breite, hoehe)
	var m := ShaderMaterial.new()
	m.shader = _shader("blick", BLICK)
	m.set_shader_parameter("himmel", himmel)
	m.set_shader_parameter("boden", boden)
	m.set_shader_parameter("licht", licht)
	n.material_override = m
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m

static func schleier(n: MeshInstance3D, breite := 0.36, hoehe := 0.44) -> void:
	n.mesh = _quad(breite, hoehe)
	var m := ShaderMaterial.new()
	m.shader = _shader("schleier", SCHLEIER)
	m.set_shader_parameter("phase", randf() * 10.0)
	n.material_override = m
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.sorting_offset = 0.5

static func _shader(name: String, code: String) -> Shader:
	if not cache.has(name):
		var s := Shader.new()
		s.code = code
		cache[name] = s
	return cache[name]

static func _quad(w: float, h: float, liegend := false) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(w, h)
	if liegend:
		q.orientation = PlaneMesh.FACE_Y
	return q

# Lichtstrahl: zwei gekreuzte Flächen von oben schräg zum Boden. fuss = wo er auftrifft, neig = Schräge (Bogenmaß), dreh = Richtung
static func lichtstrahl(parent: Node, fuss: Vector3, hoehe := 7.0, breite := 2.2, farbe := Color(1.0, 0.82, 0.5), kraft := 0.5, neig := 0.35, dreh := 0.0) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	n.position = fuss
	n.rotation = Vector3(0, dreh, neig)
	var m := ShaderMaterial.new()
	m.shader = _shader("strahl", STRAHL)
	m.set_shader_parameter("farbe", farbe)
	m.set_shader_parameter("kraft", kraft)
	for i in 2:
		var mi := MeshInstance3D.new()
		mi.mesh = _quad(breite, hoehe)
		mi.material_override = m
		mi.position.y = hoehe * 0.5
		mi.rotation.y = i * PI * 0.5
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(mi)
	return n

# Nebelbank dicht über dem Boden
static func nebel(parent: Node, pos: Vector3, groesse := 9.0, farbe := Color(0.6, 0.7, 0.9), kraft := 0.35, y := 0.35) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _quad(groesse, groesse, true)
	var m := ShaderMaterial.new()
	m.shader = _shader("nebel", NEBEL)
	m.set_shader_parameter("farbe", farbe)
	m.set_shader_parameter("kraft", kraft)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.position = pos + Vector3(0, y, 0)
	return mi

# Runenkreis auf dem Boden: Zeichen aus dem Zeichenvorrat des Spiels, glüht und dreht sich langsam
static func runenkreis(parent: Node, pos: Vector3, radius := 2.2, farbe := Color(0.3, 0.9, 0.85), kraft := 0.9, ids := ["udjat", "oath", "beam", "mantra", "nova", "glass", "blink", "wave"]) -> MeshInstance3D:
	var key := "kreis_" + "_".join(ids)
	if not cache.has(key):
		cache[key] = Glyphen.kreis(ids)
	var mi := MeshInstance3D.new()
	mi.mesh = _quad(radius * 2.0, radius * 2.0, true)
	var m := ShaderMaterial.new()
	m.shader = _shader("rune", RUNE)
	m.set_shader_parameter("maske", cache[key])
	m.set_shader_parameter("farbe", farbe)
	m.set_shader_parameter("kraft", kraft)
	m.set_shader_parameter("phase", randf() * TAU)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.position = pos + Vector3(0, 0.06, 0)
	return mi

# Fries glühender Zeichen an einer Wand (steht aufrecht, schaut nach +Z; mit rot drehen)
static func fries(parent: Node, pos: Vector3, breite := 6.0, hoehe := 0.7, farbe := Color(1.0, 0.75, 0.3), kraft := 0.8, rot := 0.0, ids := ["udjat", "oath", "meteor", "rain", "mantra", "glass", "hetz", "beam", "nova", "chain"]) -> MeshInstance3D:
	var key := "band_" + "_".join(ids)
	if not cache.has(key):
		cache[key] = Glyphen.band(ids)
	var mi := MeshInstance3D.new()
	mi.mesh = _quad(breite, hoehe)
	var m := ShaderMaterial.new()
	m.shader = _shader("rune", RUNE)
	m.set_shader_parameter("maske", cache[key])
	m.set_shader_parameter("farbe", farbe)
	m.set_shader_parameter("kraft", kraft)
	m.set_shader_parameter("dreh", 0.0)
	m.set_shader_parameter("phase", randf() * TAU)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.position = pos
	mi.rotation.y = rot
	return mi

# Staub, der im Licht schwebt
static func staub(parent: Node, pos: Vector3, kasten := Vector3(2, 3, 2), farbe := Color(1.0, 0.85, 0.6), menge := 36) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = menge
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = kasten * 0.5
	p.direction = Vector3(0.3, 1, 0.1)
	p.spread = 80.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.03
	p.initial_velocity_max = 0.14
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.3
	var g := Gradient.new()
	g.set_color(0, Color(farbe, 0.0))
	g.add_point(0.3, Color(farbe, 0.55))
	g.add_point(0.7, Color(farbe, 0.55))
	g.set_color(g.get_point_count() - 1, Color(farbe, 0.0))
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(0.02, 0.02)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = m
	p.mesh = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	p.position = pos
	return p

# Papyrussäule: Sockel, Schaft, Kelchkapitell, Deckplatte, dazu farbige Ringe unter dem Kapitell
static func saeule(g: Node, pos: Vector3, h := 4.6, r := 0.42) -> MeshInstance3D:
	var k := "saeule_%s_%d_%d" % [g.get_instance_id(), int(h * 10), int(r * 100)]
	if not cache.has(k):
		var stein := Deko._begin()
		var teile := [[r * 1.4, r * 1.5, 0.28, 0.14], [r * 0.86, r, h - 1.5, 0.28 + (h - 1.5) * 0.5], [r * 1.6, r * 0.9, 0.95, h - 1.22 + 0.475]]
		for t in teile:
			var c := CylinderMesh.new()
			c.top_radius = t[0]
			c.bottom_radius = t[1]
			c.height = t[2]
			c.radial_segments = 14
			c.rings = 1
			stein.append_from(c, 0, Transform3D(Basis(), Vector3(0, t[3], 0)))
		Deko.box(stein, Vector3(r * 3.0, 0.27, r * 3.0), Vector3(0, h - 0.27, 0))
		var parts := [[stein, Deko.stone(g, "hell", "sandstein", Color(1.12, 1.0, 0.84))]]
		var farben := [["ring_lapis", Color(0.12, 0.2, 0.5)], ["ring_rot", Color(0.55, 0.16, 0.1)], ["ring_gold", Color(0.85, 0.62, 0.22)]]
		for i in 3:
			var st := Deko._begin()
			for j in 2:
				var c := CylinderMesh.new()
				c.top_radius = r * 0.9
				c.bottom_radius = r * 0.9
				c.height = 0.09
				c.radial_segments = 14
				c.rings = 1
				st.append_from(c, 0, Transform3D(Basis(), Vector3(0, h - 1.36 - i * 0.12 - j * 0.42, 0)))
			parts.append([st, Deko.mat(farben[i][0], farben[i][1], 0.6, Color.BLACK, 0.0, 0.4 if i == 2 else 0.0)])
		cache[k] = Deko._commit(parts)
	return Deko._put(g, cache[k], pos)


# Flamme ohne Partikel: zwei gekreuzte Flächen, die Zungen malt der Shader. Für Feuerschalen und Fackeln.
static func flamme(parent: Node, pos: Vector3, hoehe := 1.1, breite := 0.9, farbe := Color(1.0, 0.55, 0.16)) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	n.position = pos
	var m := ShaderMaterial.new()
	m.shader = _shader("flamme", FLAMME)
	m.set_shader_parameter("farbe", farbe)
	m.set_shader_parameter("phase", randf() * 10.0)
	for i in 2:
		var mi := MeshInstance3D.new()
		mi.mesh = _quad(breite, hoehe)
		mi.material_override = m
		mi.position.y = hoehe * 0.5
		mi.rotation.y = i * PI * 0.5 + 0.4
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(mi)
	return n
