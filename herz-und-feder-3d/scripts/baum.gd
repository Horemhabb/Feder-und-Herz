class_name Baum extends VBoxContainer
# Fähigkeitenbaum als Baum (3.3): ein Stamm unten, drei Äste mit eigenem Thema (Klassen.baum). Knoten: Fähigkeiten
# (groß, rund, mit ihrem Relief), Wucht und Eile als kleine Blätter daneben, dauerhafte Stärken als Rauten und der
# Schlüsselstein oben am mittleren Ast. Gelernt werden kann nur, was neben schon Gelerntem liegt; gelernte Äste leuchten
# golden. Einen Knoten antippen oder anklicken zeigt ihn rechts (am Handy darunter) mit dem Knopf zum Lernen.
# Umlernen geht nur am Schrein des Thot und kostet dort nichts.

const BREITE := 760.0
const HOEHE := 600.0

var hud: Hud
var game: Node
var wahl := ""            # gewählter Knoten
var bild: BaumBild

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	render()

func _exit_tree() -> void:
	Spiel.baum_neu = false   # der Hinweis auf den neuen Baum steht nur, bis man ihn einmal gesehen hat

func _clear() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

func _knopf(text: String, main: bool, cb: Callable, enabled := true) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.add_theme_font_size_override("font_size", 15)
	b.custom_minimum_size = Vector2(44, 42)
	var edge := Hud.GOLD if main else Color("5c4a2e")
	b.add_theme_stylebox_override("normal", hud._flat(Color(Hud.GOLD, 0.14) if main else Color(0, 0, 0, 0), 8, edge, 1))
	b.add_theme_stylebox_override("hover", hud._flat(Color(1, 1, 1, 0.06), 8, Hud.GOLD, 1))
	b.add_theme_stylebox_override("pressed", hud._flat(Color(1, 1, 1, 0.1), 8, Hud.GOLD, 1))
	b.add_theme_stylebox_override("disabled", hud._flat(Color(0, 0, 0, 0), 8, Color("2a2731"), 1))
	b.add_theme_color_override("font_color", Hud.GOLD if main else Hud.PARCH)
	b.add_theme_color_override("font_disabled_color", Color(Hud.DIM, 0.45))
	b.disabled = not enabled
	b.pressed.connect(func():
		game.sfx.play("ui")
		cb.call()
		game.hero.apply_stats()
		render())
	return b

# ---------------------------------------------------------------- was ein Knoten ist und kann
static func name_von(key: String) -> String:
	var k: Dictionary = Klassen.baum(Spiel.cls).knoten[key]
	match k.art:
		"stamm":
			return Spiel.CLS[Spiel.cls].name
		"faehigkeit":
			return Klassen.SK[k.ref].name
		"blatt":
			return "%s: %s" % [Klassen.SK[k.ref].name, Klassen.AUGS[k.aug].name]
		"staerke":
			for pd in Klassen.PASSIVES:
				if pd.id == k.ref:
					return pd.name
		"schluessel":
			return Klassen.KEYSTONE[Spiel.cls].name
	return key

# Kann der Knoten jetzt (mit einem Punkt) gelernt oder gesteigert werden? Gibt "" zurück oder den Grund, warum nicht.
static func hindernis(key: String) -> String:
	var k: Dictionary = Klassen.baum(Spiel.cls).knoten[key]
	var pts := Spiel.tree_points()
	match k.art:
		"stamm":
			return "Der Stamm: hier beginnt jeder Weg."
		"faehigkeit":
			var r := Spiel.rank(k.ref)
			if r >= Klassen.SK_RANKS:
				return "Höchster Rang erreicht."
			if r == 0 and not Spiel.lernbar(k.ref):
				return "Lernbar ab Stufe %d." % Klassen.unlock_lvl(Spiel.cls, k.ref)
			if r == 0 and not Spiel.nachbar_gelernt(key):
				return "Noch kein Weg dorthin: Lerne zuerst einen Nachbarn."
		"staerke":
			var r := Spiel.pas(k.ref)
			if r >= Klassen.SK_RANKS:
				return "Höchster Rang erreicht."
			if r == 0 and not Spiel.nachbar_gelernt(key):
				return "Noch kein Weg dorthin: Lerne zuerst einen Nachbarn."
		"blatt":
			if Spiel.rank(k.ref) < 2:
				return "Ab Rang 2 von %s." % Klassen.SK[k.ref].name
			if Spiel.aug(k.ref) == k.aug:
				return "Gewählt."
			if Spiel.aug(k.ref) != "":
				return ""   # Umwählen ist frei
		"schluessel":
			if Spiel.has_key():
				return "Freigeschaltet."
			if not Spiel.nachbar_gelernt(key):
				return "Noch kein Weg dorthin: Lerne zuerst einen Nachbarn."
			if Spiel.tree_spent() < Klassen.KEY_NEED:
				return "Braucht %d verteilte Punkte (jetzt %d)." % [Klassen.KEY_NEED, Spiel.tree_spent()]
	if pts <= 0:
		return "Kein freier Punkt. Jeder Aufstieg bringt einen."
	return ""

static func lernen(key: String) -> bool:
	var k: Dictionary = Klassen.baum(Spiel.cls).knoten[key]
	match k.art:
		"faehigkeit":
			return Spiel.tree_rank_up(k.ref)
		"staerke":
			return Spiel.tree_passive(k.ref)
		"blatt":
			return Spiel.tree_aug(k.ref, k.aug)
		"schluessel":
			return Spiel.tree_key()
	return false

# ---------------------------------------------------------------- Aufbau des Fensters
func render() -> void:
	_clear()
	var B := Klassen.baum(Spiel.cls)
	if wahl == "" or not B.knoten.has(wahl):
		wahl = _vorschlag()
	var pts := Spiel.tree_points()
	var top := HBoxContainer.new()
	var t := hud._label("Fähigkeitenbaum", 26, Hud.PARCH)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	var close := Button.new()
	close.text = hud._taste("  Schließen  [K]  ").strip_edges()
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 15)
	close.add_theme_stylebox_override("normal", hud._flat(Color(0, 0, 0, 0), 8, Color("5c4a2e"), 1))
	close.pressed.connect(func(): game.toggle_tree())
	top.add_child(close)
	add_child(top)
	add_child(hud._para("%s · Stufe %d · %s" % [Spiel.CLS[Spiel.cls].name, Spiel.lvl, ("%d freie Punkte" % pts) if pts != 1 else "1 freier Punkt"], 15, Hud.GOLD if pts > 0 else Hud.DIM))
	if Spiel.baum_neu:
		add_child(hud._para("Der Baum ist neu gewachsen: Er hat jetzt drei Äste, und lernen lässt sich nur, was neben schon Gelerntem liegt. Deine Punkte sind zurückgegeben, verteile sie neu.", 14, Hud.GOLD))
	elif not game.hero.ORDER.any(func(i): return i != "potion" and Spiel.gelernt(i)):
		add_child(hud._para("Wähle deine ersten Fähigkeiten. Eine Fähigkeit wirkt erst, wenn du sie gelernt hast. Jeder Weg beginnt am Stamm, und gelernt werden kann nur, was neben schon Gelerntem liegt.", 14, Hud.GOLD))
	var breit: float = get_viewport().get_visible_rect().size.x
	var neben: bool = breit >= 1150.0 and not game.touch
	var body: BoxContainer = HBoxContainer.new() if neben else VBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	add_child(body)
	# das Bild des Baums; am Handy in einem eigenen Rollbereich, damit man es seitlich verschieben kann
	bild = BaumBild.new()
	bild.baum = self
	var platz := minf(BREITE, breit - 80.0)
	var s := 1.0 if neben else clampf(platz / BREITE, 0.72, 1.0)
	bild.skala = s
	bild.custom_minimum_size = Vector2(BREITE, HOEHE) * s
	if neben or BREITE * s <= platz + 1.0:
		body.add_child(bild)
	else:
		var sc := ScrollContainer.new()
		sc.custom_minimum_size = Vector2(platz, HOEHE * s)
		sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		sc.add_child(bild)
		body.add_child(sc)
		sc.set_deferred("scroll_horizontal", int(BREITE * s * 0.5 - platz * 0.5))
	body.add_child(_beschreibung(neben))
	# Umlernen
	var rr := HBoxContainer.new()
	rr.add_theme_constant_override("separation", 10)
	if game.orte.near_thot():
		rr.add_child(_knopf("Am Schrein des Thot umlernen: alle Punkte zurück", false, func(): Spiel.respec(), Spiel.tree_spent() > 0))
	else:
		rr.add_child(hud._label("Umlernen: am Schrein des Thot nahe dem Eingang jeder Stunde (kostenlos).", 13, Hud.DIM))
	add_child(rr)
	hud._pass_all(self)

# Gamepad (4.0): Knoten der Reihe nach von links nach rechts wählen, A lernt
func pad_schritt(r: int) -> void:
	var B := Klassen.baum(Spiel.cls)
	var keys: Array = B.knoten.keys().filter(func(k): return B.knoten[k].art != "stamm")
	keys.sort_custom(func(a, b): return (B.knoten[a].pos as Vector2).x * 1000.0 + (B.knoten[a].pos as Vector2).y < (B.knoten[b].pos as Vector2).x * 1000.0 + (B.knoten[b].pos as Vector2).y)
	var i := keys.find(wahl)
	wahl = keys[(i + r + keys.size()) % keys.size()]
	game.sfx.play("ui")
	render()

func pad_lernen() -> void:
	if wahl != "" and hindernis(wahl) == "":
		game.sfx.play("ui")
		lernen(wahl)
		game.hero.apply_stats()
		render()

# Was ist sinnvoll vorzuwählen? Der erste Knoten, der sich gerade lernen lässt, sonst die erste Fähigkeit
func _vorschlag() -> String:
	var B := Klassen.baum(Spiel.cls)
	for id in Klassen.order(Spiel.cls):
		if id != "potion" and Spiel.rank(id) == 0 and hindernis("s:" + id) == "":
			return "s:" + id
	for k in B.knoten:
		if B.knoten[k].art != "blatt" and B.knoten[k].art != "stamm" and hindernis(k) == "":
			return k
	return "s:" + Klassen.order(Spiel.cls)[0]

func _beschreibung(neben: bool) -> Control:
	var B := Klassen.baum(Spiel.cls)
	var k: Dictionary = B.knoten[wahl]
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(320 if neben else 0, 0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	p.add_theme_stylebox_override("panel", hud._flat(Color("211f27"), 8, Color("5c4a2e"), 1))
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 12)
	p.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	m.add_child(v)
	var ast: int = k.ast
	var kopf := HBoxContainer.new()
	kopf.add_theme_constant_override("separation", 10)
	var ic := TextureRect.new()
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.custom_minimum_size = Vector2(64, 64)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.texture = BaumBild.symbol(wahl)
	if ic.texture:
		kopf.add_child(ic)
	var kv := VBoxContainer.new()
	kv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kv.add_child(hud._label(name_von(wahl), 18, Hud.PARCH))
	var art_txt := {"stamm": "Stamm", "faehigkeit": "Fähigkeit", "blatt": "Verstärkung", "staerke": "Dauerhafte Stärke", "schluessel": "Schlüsselstein"}[k.art] as String
	if ast >= 0:
		art_txt += " · Ast „%s“" % B.aeste[ast]
	kv.add_child(hud._label(art_txt, 12, Hud.DIM))
	kopf.add_child(kv)
	v.add_child(kopf)
	var txt := ""
	var wirkung := ""
	match k.art:
		"stamm":
			txt = Spiel.CLS[Spiel.cls].get("txt", "")
			wirkung = "Drei Äste: %s." % ", ".join(B.aeste)
		"faehigkeit":
			var S: Dictionary = Klassen.SK[k.ref]
			txt = S.txt
			var rk := Spiel.rank(k.ref)
			var taste: String = Klassen.keys()[game.hero.ORDER.find(k.ref)]
			if rk == 0:
				wirkung = "Taste %s · wirkt erst, wenn du sie lernst (1 Punkt)." % taste
			elif S.util:
				wirkung = "Taste %s · Rang %d von %d · Abklingzeit −6 %% je weiterem Rang, jetzt %.1f s" % [taste, rk, Klassen.SK_RANKS, game.hero.cd_of(k.ref)]
			else:
				wirkung = "Taste %s · Rang %d von %d · Stärke +12 %% je weiterem Rang, jetzt ×%.2f" % [taste, rk, Klassen.SK_RANKS, Spiel.sk_pow(k.ref)]
		"blatt":
			txt = Klassen.AUGS[k.aug].txt + "."
			wirkung = "Nur Wucht oder Eile. Die erste Wahl kostet einen Punkt, Umwählen ist frei."
		"staerke":
			for pd in Klassen.PASSIVES:
				if pd.id == k.ref:
					txt = pd.txt + "."
			wirkung = "Rang %d von %d" % [Spiel.pas(k.ref), Klassen.SK_RANKS]
		"schluessel":
			txt = Klassen.KEYSTONE[Spiel.cls].txt
			wirkung = "Braucht %d verteilte Punkte und einen Weg dorthin." % Klassen.KEY_NEED
	v.add_child(hud._para(txt, 13, Hud.PARCH))
	v.add_child(hud._label(wirkung, 12, Hud.TEAL))
	if k.art != "stamm":
		var grund := hindernis(wahl)
		var schon := Spiel.knoten_gelernt(wahl)
		var titel := "Lernen (1 Punkt)"
		if k.art == "blatt" and Spiel.aug(k.ref) != "" and Spiel.aug(k.ref) != k.aug:
			titel = "Umwählen"
		elif schon:
			titel = "Steigern (1 Punkt)"
		var w := wahl
		if grund == "":
			v.add_child(_knopf(titel, true, func(): lernen(w)))
		else:
			v.add_child(hud._label(grund, 12, Color("7ad08a") if grund == "Gewählt." or grund == "Freigeschaltet." or grund == "Höchster Rang erreicht." else Hud.DIM))
	return p


# ---------------------------------------------------------------- das gezeichnete Bild
class BaumBild extends Control:
	var baum: Baum
	var skala := 1.0
	var t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		set_process(true)

	func _process(d: float) -> void:
		t += d
		queue_redraw()   # lernbare Knoten pulsieren

	static func symbol(key: String) -> Texture2D:
		var k: Dictionary = Klassen.baum(Spiel.cls).knoten[key]
		match k.art:
			"faehigkeit":
				return Klassen.icon(k.ref, 128)
			"staerke":
				return Klassen.icon("p_" + k.ref, 128)
			"schluessel":
				return Klassen.icon("k_" + Spiel.cls, 128)
			"stamm":
				return Klassen.portrait(Spiel.cls)
		return null

	# Anteil, den man von jedem Rand der Symbole abschneidet (Goldrahmen und Ecken, siehe ui/symbole/)
	const RAHMEN_RAND := 0.09

	# Symbole aus ui/symbole/ tragen einen Rahmen; Porträt und gezeichnete Zeichen nicht
	static func rahmen_ab(tex: Texture2D) -> bool:
		return tex.resource_path.begins_with("res://ui/symbole/")

	static func radius(art: String) -> float:
		return {"stamm": 34.0, "faehigkeit": 30.0, "staerke": 24.0, "blatt": 15.0, "schluessel": 32.0}.get(art, 20.0)

	# der kleine Knopf unter dem gewählten Knoten (am Handy liegt die Beschreibung sonst unter dem Bild)
	func knopf_rect() -> Rect2:
		if baum.wahl == "" or Baum.hindernis(baum.wahl) != "":
			return Rect2()
		var n: Dictionary = Klassen.baum(Spiel.cls).knoten[baum.wahl]
		if n.art == "stamm":
			return Rect2()
		var p: Vector2 = n.pos
		var r := radius(n.art)
		var unten := p.y + r + 18.0 + 32.0 < Baum.HOEHE
		return Rect2(p + Vector2(-52, r + 18.0 if unten else -r - 50.0), Vector2(104, 32))

	func knopf_text() -> String:
		var n: Dictionary = Klassen.baum(Spiel.cls).knoten[baum.wahl]
		if n.art == "blatt" and Spiel.aug(n.ref) != "" and Spiel.aug(n.ref) != n.aug:
			return "Umwählen"
		return "Steigern" if Spiel.knoten_gelernt(baum.wahl) else "Lernen"

	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var p: Vector2 = ev.position / skala
			var kr := knopf_rect()
			if kr.size.x > 0.0 and kr.grow(6.0).has_point(p):
				baum.game.sfx.play("ui")
				Baum.lernen(baum.wahl)
				baum.game.hero.apply_stats()
				baum.render.call_deferred()
				accept_event()
				return
			var B := Klassen.baum(Spiel.cls)
			var best := ""
			var bd := 1e9
			for k in B.knoten:
				var d: float = (B.knoten[k].pos as Vector2).distance_to(p)
				if d < radius(B.knoten[k].art) + 12.0 and d < bd:
					bd = d
					best = k
			if best != "":
				baum.game.sfx.play("ui")
				if best == baum.wahl and ev.double_click and Baum.hindernis(best) == "":
					Baum.lernen(best)
					baum.game.hero.apply_stats()
				baum.wahl = best
				baum.render.call_deferred()
				accept_event()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * skala)
		var B := Klassen.baum(Spiel.cls)
		var gold := Hud.GOLD
		var dunkel := Color(0.24, 0.2, 0.15)
		var font := get_theme_default_font()
		# Äste: gelernt golden und dick, halb gelernt Tinte, sonst ein dunkler Strich
		var fertig := {}
		for a in B.nachbarn:
			for b in B.nachbarn[a]:
				var kk: String = a + "|" + b if a < b else b + "|" + a
				if fertig.has(kk):
					continue
				fertig[kk] = true
				var pa: Vector2 = B.knoten[a].pos
				var pb: Vector2 = B.knoten[b].pos
				var la := Spiel.knoten_gelernt(a)
				var lb := Spiel.knoten_gelernt(b)
				var col := gold if la and lb else (Color(0.62, 0.52, 0.36) if la or lb else dunkel)
				var w := 6.0 if la and lb else (3.5 if la or lb else 2.5)
				if B.knoten[a].art == "blatt" or B.knoten[b].art == "blatt":
					w *= 0.6
				# leicht geschwungen wie ein Zweig
				var mitte := (pa + pb) * 0.5 + (pb - pa).orthogonal() * 0.08
				var pts := PackedVector2Array()
				for i in 13:
					var u := i / 12.0
					pts.append(pa.lerp(mitte, u).lerp(mitte.lerp(pb, u), u))
				draw_polyline(pts, col, w, true)
		# Namen der Äste über ihren Spitzen
		var oben := [Vector2(170, 32), Vector2(470, 30), Vector2(640, 40)]
		for i in 3:
			draw_string(font, oben[i] - Vector2(60, 0), String(B.aeste[i]).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 120, 17, Color(0.3, 0.19, 0.08, 0.9))
		# Knoten
		for k in B.knoten:
			var n: Dictionary = B.knoten[k]
			var p: Vector2 = n.pos
			var r := radius(n.art)
			var gel := Spiel.knoten_gelernt(k)
			var offen: bool = not gel and Baum.hindernis(k) == "" and n.art != "stamm"
			var ring := gold if gel else (Color(0.56, 0.89, 0.88) if offen else Color(0.36, 0.3, 0.22))
			if offen:
				# lernbar: ein Schein, der langsam atmet
				draw_circle(p, r + 7.0 + sin(t * 3.0) * 2.5, Color(0.56, 0.89, 0.88, 0.16))
			if k == baum.wahl:
				draw_arc(p, r + 9.0, 0, TAU, 40, Color(1, 1, 1, 0.75), 2.0, true)
			match n.art:
				"staerke", "schluessel":
					var rr := r * 1.25
					var poly := PackedVector2Array([p + Vector2(0, -rr), p + Vector2(rr, 0), p + Vector2(0, rr), p + Vector2(-rr, 0)])
					draw_colored_polygon(poly, Color(0.1, 0.09, 0.11))
					poly.append(poly[0])
					draw_polyline(poly, ring, 3.0, true)
				_:
					draw_circle(p, r, Color(0.1, 0.09, 0.11))
					draw_arc(p, r, 0, TAU, 40, ring, 3.0, true)
			var tex := symbol(k)
			if tex and rahmen_ab(tex):
				# Symbole mit eingebranntem Rahmen: nur das Innere zeigen, an der Form des Knotens abgeschnitten
				var halb := r * 1.25 if n.art in ["staerke", "schluessel"] else r
				var rand := halb - 2.0   # knapp innerhalb des Rings
				var form := PackedVector2Array()
				if n.art in ["staerke", "schluessel"]:
					form = PackedVector2Array([Vector2(0, -rand), Vector2(rand, 0), Vector2(0, rand), Vector2(-rand, 0)])
				else:
					for i in 40:
						form.append(Vector2.from_angle(i * TAU / 40.0) * rand)
				var uvs := PackedVector2Array()
				for q in form:
					uvs.append(Vector2(RAHMEN_RAND, RAHMEN_RAND) + (q / (halb * 2.0) + Vector2(0.5, 0.5)) * (1.0 - 2.0 * RAHMEN_RAND))
				var farbe := Color.WHITE if gel else Color(0.55, 0.52, 0.5, 0.85)
				var pts := PackedVector2Array()
				for q in form:
					pts.append(p + q)
				draw_colored_polygon(pts, farbe, uvs, tex)
			elif tex:
				var s := r * (1.5 if n.art != "stamm" else 1.7)
				draw_texture_rect(tex, Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), false, Color.WHITE if gel or n.art == "stamm" else Color(0.55, 0.52, 0.5, 0.85))
			elif n.art == "blatt":
				var buch: String = "W" if n.aug == "wucht" else "E"
				draw_string(font, p + Vector2(-8, 6), buch, HORIZONTAL_ALIGNMENT_CENTER, 16, 16, gold if gel else Color(Hud.PARCH, 0.75))
			# Ränge als kleine Punkte unter dem Knoten
			var rk := 0
			if n.art == "faehigkeit":
				rk = Spiel.rank(n.ref)
			elif n.art == "staerke":
				rk = Spiel.pas(n.ref)
			if rk > 0:
				for i in Klassen.SK_RANKS:
					var q := p + Vector2((i - 2) * 9.0, r + 9.0)
					draw_circle(q, 3.0, gold if i < rk else Color(0.36, 0.3, 0.22))
		var kr := knopf_rect()
		if kr.size.x > 0.0:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.86, 0.66, 0.25)
			sb.set_corner_radius_all(9)
			sb.border_color = Color(0.3, 0.19, 0.08)
			sb.set_border_width_all(1)
			draw_style_box(sb, kr)
			draw_string(font, kr.position + Vector2(0, 22), knopf_text(), HORIZONTAL_ALIGNMENT_CENTER, kr.size.x, 16, Color(0.16, 0.1, 0.04))
