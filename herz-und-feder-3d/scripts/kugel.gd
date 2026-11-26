class_name Kugel extends Control
# Lebens- und Kraftkugel wie in der 2D-Fassung: eine Glaskugel, in der die Flüssigkeit mit dem Wert steigt und fällt.
# Seit 4.3 sitzt sie in einer getriebenen Goldfassung (ui/zier/kugel_fassung.webp: Lotos oben, Federn der Maat zu den
# Seiten, Skarabäus unten), die etwas über den Platz der Kugel hinausragt. Wenig Leben: das Glas pulsiert langsam.

const CODE := "
shader_type canvas_item;
uniform float fill = 1.0;
uniform vec4 col : source_color = vec4(0.8, 0.1, 0.1, 1.0);
uniform float off = 0.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float z = sqrt(max(0.0, 1.0 - r * r));
	float level = 1.0 - fill * 2.0;
	float wave = (sin(p.x * 7.0 + TIME * 2.2 + off) * 0.035 + sin(p.x * 13.0 - TIME * 3.1 + off) * 0.015) * step(0.01, fill) * step(fill, 0.99);
	float inside = smoothstep(level + wave - 0.02, level + wave + 0.02, p.y);
	vec3 glass = vec3(0.06, 0.05, 0.065);
	float swirl = sin(p.x * 5.0 + p.y * 4.0 + TIME * 0.9 + off) * 0.5 + 0.5;
	vec3 liq = col.rgb * (0.4 + 0.75 * z) * (0.82 + 0.3 * swirl);
	vec3 c = mix(glass, liq, inside);
	c += col.rgb * 0.55 * smoothstep(0.06, 0.0, abs(p.y - (level + wave))) * step(0.01, fill) * step(fill, 0.99);
	c *= 0.5 + 0.65 * z;
	vec3 n = normalize(vec3(p.x, p.y, z));
	float spec = pow(max(0.0, dot(n, normalize(vec3(-0.45, -0.6, 0.65)))), 22.0);
	c += vec3(1.0, 0.97, 0.9) * spec * 0.6;
	c += col.rgb * 0.12 * pow(1.0 - z, 3.0);
	COLOR = vec4(c, smoothstep(1.0, 0.96, r));
}
"

static var shader: Shader

var value := 1.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		if mat:
			mat.set_shader_parameter("fill", value)
var text := "":
	set(v):
		if v != text:
			text = v
			queue_redraw()
var caption := ""
var font: Font
var mat: ShaderMaterial
var glass: ColorRect
var top: Control
var fassung: Texture2D
var puls := false:          # wenig Leben: das Glas atmet hell und dunkel
	set(v):
		if v != puls:
			puls = v
			set_process(v)
			if not v and glass:
				glass.modulate = Color.WHITE
var _t := 0.0

func _process(d: float) -> void:
	_t += d
	var k := 0.5 + 0.5 * sin(_t * 5.0)
	glass.modulate = Color(1.0 + 0.45 * k, 1.0 + 0.1 * k, 1.0 + 0.1 * k)

func setup(col: Color, cap: String, f: Font, px: float) -> void:
	caption = cap
	font = f
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	fassung = Zier.tex("kugel_fassung")
	set_process(false)
	if shader == null:
		shader = Shader.new()
		shader.code = CODE
	mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("col", col)
	mat.set_shader_parameter("off", col.r * 7.0)
	glass = ColorRect.new()
	glass.material = mat
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glass)
	# Ring und Zahl liegen über der Kugel
	top = Control.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.draw.connect(_draw_top)
	add_child(top)
	resized.connect(_fit)
	_fit()

func _fit() -> void:
	var m := 7.0
	glass.position = Vector2(m, m)
	glass.size = size - Vector2(m, m) * 2.0
	top.size = size
	top.queue_redraw()

func queue_top() -> void:
	if top:
		top.queue_redraw()

func _draw_top() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 4.0
	if fassung:
		# die Fassung so groß, dass ihr innerer Rand (99 von 144 Pixeln des Halbmessers) am Glas liegt
		var halb := (r - 2.0) * 144.0 / 99.0
		top.draw_texture_rect(fassung, Rect2(c - Vector2(halb, halb), Vector2(halb, halb) * 2.0), false)
	else:
		_ring_alt(c, r)
	if font:
		var fs := int(size.y * 0.2)
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var at := c + Vector2(-w / 2.0, fs * 0.36)
		top.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0, 0, 0, 0.85))
		top.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("f3ead2"))

# der frühere Ring aus Bronze und Gold, falls die Fassung fehlt
func _ring_alt(c: Vector2, r: float) -> void:
	top.draw_arc(c, r, 0.0, TAU, 64, Color("1c1712"), 8.0, true)
	top.draw_arc(c, r + 2.5, 0.0, TAU, 64, Color("7a5a26"), 2.0, true)
	top.draw_arc(c, r - 3.0, 0.0, TAU, 64, Color("c9a04a"), 1.5, true)
	top.draw_arc(c, r, PI * 1.1, PI * 1.55, 20, Color(1.0, 0.9, 0.6, 0.35), 3.0, true)
	# vier Nieten
	for i in 4:
		var a := PI / 4 + i * PI / 2
		top.draw_circle(c + Vector2(cos(a), sin(a)) * r, 3.2, Color("c9a04a"))
		top.draw_circle(c + Vector2(cos(a), sin(a)) * r, 1.6, Color("3a2c14"))

func set_text(v: String) -> void:
	if v != text:
		text = v
		queue_top()
