class_name Rueckmeldung extends Control
# Rückmeldung im Kampf (Etappe B): drei Dinge, die vorher fehlten.
# 1. Lebensbalken über verletzten Gegnern, mit heller Spur für den letzten Treffer (Champions golden und breiter).
#    Der Hüter hat seine Leiste oben (hud.gd), er bekommt hier keinen Balken.
# 2. Roter Blitz am Bildrand, wenn die Figur getroffen wird, stärker bei einem schweren Treffer.
# 3. Warnrand: Unter 30 % Leben pocht der Bildrand rot, je weniger Leben, desto schneller.
# Alles liest nur, was Foe, Hero und Kamera ohnehin wissen, und zeichnet in den Bildschirm; die Spielwelt bleibt unberührt.

const SICHT := 6.0         # so lange bleibt ein Balken nach dem letzten Treffer
const SPUR_VERZUG := 0.35  # so lange wartet die helle Spur, bevor sie dem Balken folgt

var game: Node
var hud: Hud
var balken := {}           # Foe -> {"hp": zuletzt gesehenes Leben, "spur": helle Spur, "t": Restzeit, "warte": Verzug}
var hero_hp_alt := -1.0
var blitz := 0.0           # 0 bis 1, fällt schnell
var warn := 0.0            # 0 bis 1, je nach fehlendem Leben
var rand: ColorRect
var rand_mat: ShaderMaterial
var sichtbar_anzahl := 0   # Zahl der Balken im letzten Bild (für den Spieltest)

const RAND_CODE := "
shader_type canvas_item;
uniform float blitz = 0.0;
uniform float warn = 0.0;
void fragment() {
	vec2 p = UV - 0.5;
	float r = smoothstep(0.3, 1.0, dot(p, p) * 2.2);
	float puls = 0.55 + 0.45 * sin(TIME * (3.0 + warn * 5.0));
	float a = r * (blitz * 0.7 + warn * 0.6 * puls);
	COLOR = vec4(0.78, 0.04, 0.03, clamp(a, 0.0, 0.9));
}
"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rand = ColorRect.new()
	rand.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = RAND_CODE
	rand_mat = ShaderMaterial.new()
	rand_mat.shader = sh
	rand.material = rand_mat
	rand.visible = false
	add_child(rand)

func _process(delta: float) -> void:
	if game == null or game.hero == null or not game.started:
		return
	var h: Hero = game.hero
	# Treffer auf die Figur: Abnahme des Lebens zwischen zwei Bildern
	if hero_hp_alt >= 0.0 and h.hp < hero_hp_alt - 0.5 and not get_tree().paused:
		blitz = maxf(blitz, clampf(0.7 + (hero_hp_alt - h.hp) / h.max_hp * 3.0, 0.7, 1.0))
	hero_hp_alt = h.hp
	blitz = maxf(0.0, blitz - delta * 1.7)
	var anteil: float = h.hp / maxf(1.0, h.max_hp)
	warn = 0.0 if (h.dead or anteil >= 0.3) else clampf((0.3 - anteil) / 0.3, 0.0, 1.0)
	rand.visible = (blitz > 0.01 or warn > 0.01) and not get_tree().paused
	if rand.visible:
		rand_mat.set_shader_parameter("blitz", blitz)
		rand_mat.set_shader_parameter("warn", warn)
	# Balken der Gegner nachführen
	for f in balken.keys():
		if not is_instance_valid(f):
			balken.erase(f)
	for f in game.foes:
		if not is_instance_valid(f) or f.kind == "boss":
			continue
		var b = balken.get(f)
		if b == null:
			if f.hp >= f.max_hp - 0.01 or f.state == Foe.St.DEAD:
				continue
			b = {"hp": f.max_hp, "spur": f.max_hp, "t": 0.0, "warte": 0.0}
			balken[f] = b
		if f.hp < b.hp - 0.01:
			b.t = SICHT
			b.warte = SPUR_VERZUG
		elif f.hp > b.hp + 0.01 and f.hp < f.max_hp:
			b.t = maxf(b.t, 2.0)   # erholt sich langsam: kurz zeigen
		b.hp = f.hp
		b.t = maxf(0.0, b.t - delta)
		b.warte = maxf(0.0, b.warte - delta)
		if b.warte <= 0.0 and b.spur > f.hp:
			b.spur = maxf(f.hp, b.spur - f.max_hp * 0.8 * delta)
		elif f.hp > b.spur:
			b.spur = f.hp
		if f.state == Foe.St.DEAD and b.spur <= f.hp + 0.01 and b.t > 0.6:
			b.t = 0.6   # tot: Spur auslaufen lassen, dann weg
		if f.hp >= f.max_hp - 0.01 and b.t <= 0.0:
			balken.erase(f)
	queue_redraw()

func _draw() -> void:
	sichtbar_anzahl = 0
	if game == null or game.cam == null or not game.started or get_tree().paused:
		return
	var cam: Camera3D = game.cam
	var vs := get_viewport_rect().size
	for f in balken:
		if not is_instance_valid(f):
			continue
		var b: Dictionary = balken[f]
		if b.t <= 0.0 or f.hidden or not f.visible:
			continue
		if f.state == Foe.St.SLEEP and f.hp >= f.max_hp:
			continue
		var kopf: float = (2.3 * f.sc) if f.proc == null else (1.7 + f.radius)
		var welt: Vector3 = f.global_position + Vector3(0, kopf, 0)
		if cam.is_position_behind(welt):
			continue
		var p := cam.unproject_position(welt)
		if p.x < -80.0 or p.y < -40.0 or p.x > vs.x + 80.0 or p.y > vs.y + 40.0:
			continue
		var elite: bool = f.elite != ""
		var w := 92.0 if elite else 60.0
		var hh := 9.0 if elite else 7.0
		var a: float = clampf(b.t / 0.8, 0.0, 1.0)
		var x := p.x - w / 2.0
		var y := p.y - hh / 2.0
		var anteil := clampf(f.hp / f.max_hp, 0.0, 1.0)
		var spur := clampf(b.spur / f.max_hp, 0.0, 1.0)
		draw_rect(Rect2(x - 2.0, y - 2.0, w + 4.0, hh + 4.0), Color(0.02, 0.015, 0.02, 0.85 * a))
		draw_rect(Rect2(x, y, w * spur, hh), Color(1.0, 0.96, 0.85, 0.85 * a))
		var farbe := Color(0.95, 0.76, 0.25) if elite else (Color(0.85, 0.2, 0.15) if anteil > 0.3 else Color(1.0, 0.45, 0.1))
		draw_rect(Rect2(x, y, w * anteil, hh), Color(farbe, a))
		draw_rect(Rect2(x - 2.0, y - 2.0, w + 4.0, hh + 4.0), Color(0.48, 0.35, 0.15, a), false, 1.0)
		sichtbar_anzahl += 1
