class_name Tasche extends VBoxContainer
# Ausrüstung und Tasche (07-ui.js › renderInv): acht Plätze, Werte, Material und Scherben, die Tasche mit 32 Plätzen,
# das Detail des gewählten Teils (Anlegen, Aufwerten, Neuwürfeln, Wegwerfen), der Grabräuber, das Buch des Thot
# und „Neue Figur anlegen“. Jede Aktion speichert sofort.
# Seit 4.3 wie in den großen Rollenspielen: die Figur in der Mitte, links und rechts ihre acht gefassten Plätze,
# daneben die Werte auf einer schlanken Tafel; das gewählte Teil steht auf einer Karte mit Seltenheitsfarbe und
# Zierleiste; das Buch des Thot ist ein Blatt Papyrus.

var hud: Hud
var game: Node
var sel := {}          # {"eq": Platz} oder {"bag": Index}
var werkstatt := false   # dasselbe Fenster dient als Werkstatt des Ptah: nur dort wird aufgewertet und neu gefasst (3.0)
var angebot := {}        # laufendes Neu-Fassen: {"it", "k", "opts"}

const GRUSS := ["„Leg es auf den Amboss. Ich sehe mir an, was sich machen lässt.“",
	"„Ptah hat die Welt mit Herz und Zunge gemacht. Ich brauche dazu einen Hammer.“",
	"„Gutes Stück. Schlechte Fassung. Das eine kann ich ändern.“",
	"„Bezahlt wird vorher. Gold verformt sich, Abmachungen nicht.“",
	"„Was die Duat verbogen hat, biege ich gerade. Meistens.“"]

# Plätze links und rechts der Figur (von oben nach unten)
const LINKS := ["helm", "amulett", "ruestung", "handschuhe"]
const RECHTS := ["waffe", "nebenhand", "ring", "stiefel"]

var gruss := 0

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	gruss = randi() % GRUSS.size()
	render()

func _clear() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

func _knopf(text: String, main: bool, cb: Callable, enabled := true) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.custom_minimum_size = Vector2(0, 44)
	Zier.knopf_stil(b, "haupt" if main else "zweit", 15)
	b.disabled = not enabled
	b.pressed.connect(func():
		game.sfx.play("ui")
		cb.call())
	return b

func _h3(t: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(hud._label(t.to_upper(), 12, Hud.GOLD))
	var zl := Zier.leiste(0.0, "", 12.0)
	zl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(zl)
	return h

# Ein Feld mit Symbol: vertiefter Platz mit Goldfassung, innen ein Ring in Seltenheitsfarbe, „+N“ für Aufwertung,
# „▲“ wenn besser als das Angelegte. Gewählt: heller Goldring mit Schein.
func _cell(it, cb: Callable, chosen: bool, caption := "") -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.custom_minimum_size = Vector2(66, 66)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var col := Color(0, 0, 0, 0)
	if it != null:
		col = Daten.RAR[it.rar].col
		b.icon = Daten.icon(Daten.icon_of(it))
		b.tooltip_text = "%s\n%s · %s" % [Daten.item_name(it), Daten.RAR[it.rar].name, Daten.SLOT[it.slot].name]
	var sb: StyleBoxTexture = Zier.stil("platz", 9.0).duplicate()
	var hov: StyleBoxTexture = sb.duplicate()
	hov.modulate_color = Color(1.25, 1.18, 1.05)
	b.add_theme_stylebox_override("normal", hov if chosen else sb)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", hov)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.set_meta("dunkel", true)
	b.draw.connect(func():
		var r := Rect2(Vector2.ZERO, b.size)
		if chosen:
			var glow := StyleBoxFlat.new()
			glow.draw_center = false
			glow.border_color = Zier.GOLD_HELL
			glow.set_border_width_all(2)
			glow.set_corner_radius_all(8)
			glow.shadow_color = Color(1.0, 0.8, 0.4, 0.5)
			glow.shadow_size = 8
			b.draw_style_box(glow, r.grow(1))
		Zier.platz_zeichnen(b, r, Color(col, 0.9) if col.a > 0.0 else col, true))
	b.pressed.connect(func():
		game.sfx.play("ui", 0.1, -6.0)
		cb.call())
	if it != null:
		if int(it.get("up", 0)) > 0:
			var u := hud._label("+%d" % it.up, 12, Hud.PARCH)
			u.position = Vector2(10, 6)
			u.add_theme_constant_override("outline_size", 4)
			u.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
			b.add_child(u)
		if it.has("_better"):
			var a := hud._label("▲", 14, Color("7ad08a"))
			a.position = Vector2(46, 4)
			a.add_theme_constant_override("outline_size", 4)
			a.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
			b.add_child(a)
	v.add_child(b)
	if caption != "":
		var c := hud._label(caption, 10, Hud.DIM)
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(c)
	return v

func _sel_item():
	if sel.has("eq"):
		return Spiel.eq.get(sel.eq)
	if sel.has("bag") and sel.bag < Spiel.bag.size():
		return Spiel.bag[sel.bag]
	return null

func _changed() -> void:
	game.hero.apply_stats()
	render()

func _platz(s: String) -> Control:
	return _cell(Spiel.eq.get(s), func(): sel = {"eq": s}; render(), sel.get("eq", "") == s, Daten.SLOT[s].name)

func render() -> void:
	_clear()
	var S: Dictionary = Spiel.S
	hud.fenster_kopf(self, "Werkstatt des Ptah" if werkstatt else "Ausrüstung", hud._taste("  Schließen  [Esc]  " if werkstatt else "  Schließen  [I]  "),
		func(): hud.close_bag() if werkstatt else game.toggle_bag())
	if werkstatt:
		add_child(hud._para("Ptah ist der Gott der Handwerker. Sein Goldschmied wertet Ausrüstung auf und fasst ihre Eigenschaften neu, gegen Material und eine Gebühr in Scherben.", 13, Hud.DIM))
		add_child(hud._para(GRUSS[gruss], 15, Hud.PARCH))
	# Ausrüstung: die Figur in der Mitte (gemalt, aus dem Bildauftrag K11–K14), links und rechts je vier Plätze
	var oben := HBoxContainer.new()
	oben.add_theme_constant_override("separation", 22)
	var puppe := HBoxContainer.new()
	puppe.add_theme_constant_override("separation", 12)
	var links := VBoxContainer.new()
	links.add_theme_constant_override("separation", 4)
	for s in LINKS:
		links.add_child(_platz(s))
	puppe.add_child(links)
	var fig_path := "res://ui/figur_%s.webp" % Spiel.cls
	var mitte := MarginContainer.new()
	mitte.add_theme_constant_override("margin_top", 22)   # Platz für den Lotos über dem Rahmen
	mitte.add_theme_constant_override("margin_bottom", 8)
	var fig := Zier.bildrahmen(load(fig_path) if ResourceLoader.exists(fig_path) else Klassen.portrait(Spiel.cls),
		Vector2(150, 300) if not game.touch else Vector2(132, 266), "lotos")
	(fig.get_child(0) as TextureRect).stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fig.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mitte.add_child(fig)
	puppe.add_child(mitte)
	var rechts := VBoxContainer.new()
	rechts.add_theme_constant_override("separation", 4)
	for s in RECHTS:
		rechts.add_child(_platz(s))
	puppe.add_child(rechts)
	oben.add_child(puppe)
	if not werkstatt:
		oben.add_child(_werte(S))
	else:
		var mat := VBoxContainer.new()
		mat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mat.add_theme_constant_override("separation", 8)
		mat.add_child(_h3("Material"))
		mat.add_child(_material())
		oben.add_child(mat)
	add_child(oben)
	if not werkstatt:
		add_child(_h3("Material"))
		add_child(_material())
	# Tasche
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 10)
	var bt := _h3("Tasche (%d von %d)" % [Spiel.bag.size(), Daten.BAG_MAX])
	bh.add_child(bt)
	var junk := Spiel.bag.filter(func(x): return x.rar == 0).size()
	bh.add_child(_knopf("Alles Gewöhnliche wegwerfen (%d)" % junk, false, func():
		Spiel.bag = Spiel.bag.filter(func(x): return x.rar != 0)
		sel = {}
		Spiel.speichern()
		render(), junk > 0))
	add_child(bh)
	var bf := HFlowContainer.new()
	bf.add_theme_constant_override("h_separation", 6)
	bf.add_theme_constant_override("v_separation", 6)
	for i in Daten.BAG_MAX:
		if i < Spiel.bag.size():
			var it: Dictionary = Spiel.bag[i]
			var shown := it.duplicate()
			if Daten.item_score(it) > Daten.item_score(Spiel.eq.get(it.slot)) + 0.5:
				shown["_better"] = true
			var idx := i
			bf.add_child(_cell(shown, func(): sel = {"bag": idx}; render(), sel.get("bag", -1) == i))
		else:
			var e := Panel.new()
			e.custom_minimum_size = Vector2(66, 66)
			e.mouse_filter = Control.MOUSE_FILTER_PASS
			e.add_theme_stylebox_override("panel", Zier.stil("platz", 9.0))
			e.modulate = Color(0.7, 0.66, 0.62, 0.8)
			e.set_meta("dunkel", true)
			bf.add_child(e)
	add_child(bf)
	# Detail
	add_child(_detail())
	if werkstatt:
		# Grabräuber
		var gr := HBoxContainer.new()
		gr.add_theme_constant_override("separation", 10)
		gr.add_child(_knopf("Fundkiste des Grabräubers: %d Scherben gegen ein unbekanntes Teil" % Daten.GAMBLE, false, func():
			var it := Spiel.gamble()
			if not it.is_empty():
				sel = {"bag": Spiel.bag.size() - 1}
				hud.toast_item(Daten.icon_of(it), Daten.item_name(it), game.item_sub(it), Daten.RAR[it.rar].col)
			render(), Spiel.shards >= Daten.GAMBLE and Spiel.bag.size() < Daten.BAG_MAX))
		add_child(gr)
	if not werkstatt:
		# Buch des Thot: ein Schriftstück, also ein Blatt Papyrus
		add_child(_h3("Buch des Thot (%d von %d Seiten)" % [Spiel.evid.size(), Daten.EVID.size()]))
		var blatt := PanelContainer.new()
		blatt.add_theme_stylebox_override("panel", Zier.stil("papyrus", 24.0))
		hud.papier.append(blatt)
		var bv := VBoxContainer.new()
		bv.add_theme_constant_override("separation", 10)
		blatt.add_child(bv)
		var found: Array = Spiel.evid.duplicate()
		found.sort()
		for i in found:
			var pv := VBoxContainer.new()
			pv.add_child(hud._label("%d · %s" % [i + 1, Daten.EVID[i][0]], 16, Hud.GOLD))
			pv.add_child(hud._para(Daten.EVID[i][1], 14, Hud.PARCH))
			bv.add_child(pv)
		if found.size() < Daten.EVID.size():
			bv.add_child(hud._para("Noch nicht gefunden … Elite-Gegner und Hüter tragen die Seiten bei sich.", 13, Hud.DIM))
		add_child(blatt)
		add_child(hud._label("Stunde wechseln und neue Figur: im Spielmenü (%s)." % ("Knopf „Menü“" if game.touch else "Esc"), 12, Hud.DIM))

	hud._pass_all(self)

# Werte und Herzwaage auf einer schlanken dunklen Tafel neben der Figur
func _werte(S: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	Zier.tafel(p, "klein", "", 16.0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	v.add_child(_h3("Werte"))
	var st := GridContainer.new()
	st.columns = 2
	st.add_theme_constant_override("h_separation", 22)
	st.add_theme_constant_override("v_separation", 3)
	var rows := [
		["Schaden", "%d" % round(S.dmg)], ["Leben", "%d" % S.max_hp], ["Rüstung", "%d · −%d %%" % [S.armor, round(S.red * 100.0)]],
		["Krit. Chance", "%d %%" % round(S.crit)], ["Krit. Schaden", "+%d %%" % S.crit_dmg], ["Angriffe/s", "%.2f" % S.rate],
		["Lauftempo", "%d %%" % round(S.speed * 100.0)], ["%s/s" % Spiel.CLS[Spiel.cls].res, "%d" % S.regen], ["Dornen", "%d" % S.thorns],
		["Leben pro Treffer", "%d" % S.loh], ["Erfahrung", "+%d %%" % round((S.xp_mul - 1.0) * 100.0)], ["Beuteglück", "+%d %%" % round((S.find - 1.0) * 100.0)],
	]
	for r in rows:
		var h := HBoxContainer.new()
		h.custom_minimum_size = Vector2(196 if game.touch else 210, 0)
		h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var a := hud._label(r[0], 14, Hud.DIM)
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(a)
		h.add_child(hud._label(r[1], 14, Zier.GOLD_HELL))
		st.add_child(h)
	v.add_child(st)
	# Herzwaage: Stand und Wirkung, dazu die Entscheidungen dieser Nacht
	v.add_child(_h3("Herzwaage"))
	var maat := 0
	var isfet := 0
	for k in Spiel.wahl:
		if Spiel.wahl[k] == "maat":
			maat += 1
		else:
			isfet += 1
	v.add_child(hud._para("Dein Herz ist %s (%+d). Entscheidungen: %d für Maat, %d für Isfet." % [Geschichte.herz_name(Spiel.herz), int(round(Spiel.herz)), maat, isfet], 15, Hud.PARCH))
	v.add_child(hud._para(Geschichte.herz_wirkung(Spiel.herz), 13, Hud.DIM))
	return p

func _material() -> Control:
	var mf := HFlowContainer.new()
	mf.add_theme_constant_override("h_separation", 18)
	mf.add_theme_constant_override("v_separation", 4)
	for k in Daten.MAT_ORDER:
		mf.add_child(_mat_row(Daten.ICON[k], "%s %d" % [Daten.MATS[k].name, Spiel.mats[k]], Daten.MATS[k].txt))
	mf.add_child(_mat_row(Daten.ICON.shard, "Scherben %d" % Spiel.shards, "Währung der Duat: für die Werkstatt des Ptah und den Grabräuber."))
	return mf

func _mat_row(icon: int, text: String, tip: String) -> Control:
	var h := HBoxContainer.new()
	h.tooltip_text = tip
	h.add_theme_constant_override("separation", 6)
	var tr := TextureRect.new()
	tr.texture = Daten.icon(icon)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.custom_minimum_size = Vector2(30, 30)
	h.add_child(tr)
	h.add_child(hud._label(text, 14, Hud.PARCH))
	return h

func _cost_txt(c: Dictionary, sh := 0) -> String:
	var parts := []
	for k in c:
		parts.append("%d %s" % [c[k], Daten.MATS[k].name])
	if sh > 0:
		parts.append("%d Scherben" % sh)
	return ", ".join(parts)

func _can_pay(c: Dictionary, sh := 0) -> bool:
	if Spiel.shards < sh:
		return false
	for k in c:
		if Spiel.mats.get(k, 0) < c[k]:
			return false
	return true

# Karte des gewählten Teils (wie ein Tooltip): Name in Seltenheitsfarbe, darunter Art und Stufe, eine Zierleiste,
# die Werte, die Eigenschaften mit goldenen Rauten, Legendäres in Orange, der Vergleich und die Knöpfe
func _detail() -> Control:
	var p := PanelContainer.new()
	Zier.tafel(p, "klein", "", 16.0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var it = _sel_item()
	if it == null:
		v.add_child(hud._label("Tipp ein Teil an, um es anzusehen.", 14, Hud.DIM))
		return p
	var worn := sel.has("eq")
	var rc: Color = Daten.RAR[it.rar].col
	var kopf := HBoxContainer.new()
	kopf.add_theme_constant_override("separation", 12)
	var ic := Control.new()
	ic.custom_minimum_size = Vector2(56, 56)
	var tex := Daten.icon(Daten.icon_of(it))
	ic.draw.connect(func():
		var r := Rect2(Vector2.ZERO, ic.size)
		Zier.platz_zeichnen(ic, r)
		ic.draw_texture_rect(tex, r.grow(-6), false)
		Zier.platz_zeichnen(ic, r, rc, true))
	kopf.add_child(ic)
	var kv := VBoxContainer.new()
	kv.add_theme_constant_override("separation", 0)
	kv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nm := hud._label(Daten.item_name(it), 21, rc)
	nm.add_theme_font_override("font", hud.f_fett)
	kv.add_child(nm)
	kv.add_child(hud._label("%s · %s · Gegenstandsstufe %d%s" % [Daten.RAR[it.rar].name, Daten.SLOT[it.slot].name, it.ilvl, " · angelegt" if worn else ""], 12, Hud.DIM))
	kopf.add_child(kv)
	v.add_child(kopf)
	var zl := Zier.leiste(0.0, "raute", 12.0)
	zl.modulate = rc.lerp(Color.WHITE, 0.35)
	v.add_child(zl)
	if it.has("dmg"):
		v.add_child(hud._label("Waffenschaden %d" % Daten.it_dmg(it), 16, Zier.GOLD_HELL))
	if it.has("armor"):
		v.add_child(hud._label("Rüstung %d" % Daten.it_arm(it), 16, Zier.GOLD_HELL))
	for k in it.aff.keys():
		var h := HBoxContainer.new()
		var l := hud._label("◆  " + Daten.aff_line(it, k), 14, Hud.PARCH)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		var key: String = k
		if werkstatt:
			h.add_child(_knopf("neu fassen", false, func():
				var opts := Spiel.reroll_angebot(it)
				if not opts.is_empty():
					angebot = {"it": it, "k": key, "opts": opts}
					game.sfx.play("gate", 0.1, -10.0)
					render(), angebot.is_empty() and _can_pay({"staub": Daten.REROLL_STAUB}, Daten.reroll_fee(it)) and it.aff.size() < Daten.AFF_ORDER.size()))
		v.add_child(h)
	if werkstatt and not angebot.is_empty() and angebot.it == it:
		# der Goldschmied legt zwei Fassungen hin: eine nehmen oder die alte behalten
		var ab := VBoxContainer.new()
		ab.add_theme_constant_override("separation", 6)
		ab.add_child(hud._label("Zwei neue Fassungen für „%s“. Wähle eine oder behalte die alte:" % Daten.aff_line(it, angebot.k), 13, Hud.GOLD))
		var ar := HFlowContainer.new()
		ar.add_theme_constant_override("h_separation", 8)
		ar.add_theme_constant_override("v_separation", 6)
		for o in angebot.opts:
			var oo: Dictionary = o
			var probe := {"aff": {oo.k: oo.v}, "up": it.get("up", 0)}
			ar.add_child(_knopf(Daten.aff_line(probe, oo.k), true, func():
				Spiel.reroll_setzen(angebot.it, angebot.k, oo)
				angebot = {}
				game.sfx.play("oath", 0.1, -8.0)
				_changed()))
		ar.add_child(_knopf("Die alte behalten", false, func():
			angebot = {}
			render()))
		ab.add_child(ar)
		v.add_child(ab)
	elif werkstatt and it.aff.size() > 0:
		v.add_child(hud._label("Neu fassen: %s. Du wählst aus zwei neuen Eigenschaften oder behältst die alte." % _cost_txt({"staub": Daten.REROLL_STAUB}, Daten.reroll_fee(it)), 12, Hud.DIM))
	if it.has("leg"):
		v.add_child(hud._para(Daten.leg(it.leg).txt, 14, Color("ff8a3c")))
	if not worn:
		var cur = Spiel.eq.get(it.slot)
		if cur != null:
			var d := Daten.item_score(it) - Daten.item_score(cur)
			var cl := Color("7ad08a") if d > 0.0 else Color("e0705f")
			v.add_child(hud._label("%s als %s (%+d Wertung)" % ["Besser" if d > 0.0 else "Schwächer", Daten.item_name(cur), int(round(d))], 13, cl))
		else:
			v.add_child(hud._label("Der Platz ist frei.", 13, Color("7ad08a")))
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	if not worn:
		var i: int = sel.bag
		row.add_child(_knopf("Anlegen", true, func():
			Spiel.equip(i)
			sel = {"eq": it.slot}
			game.sfx.play("oath", 0.1, -8.0)
			_changed()))
	var u := int(it.get("up", 0))
	if not werkstatt:
		pass
	elif u < Daten.UP_MAX:
		var c := Daten.up_cost(it)
		row.add_child(_knopf("Aufwerten auf +%d: %s" % [u + 1, _cost_txt(c, Daten.up_fee(it))], false, func():
			if Spiel.upgrade(it):
				game.sfx.play("gate", 0.1, -8.0)
				_changed(), angebot.is_empty() and _can_pay(c, Daten.up_fee(it))))
	else:
		row.add_child(hud._label("Höchste Stufe erreicht.", 13, Hud.DIM))
	if not worn:
		var i2: int = sel.bag
		row.add_child(_knopf("Wegwerfen", false, func():
			Spiel.bag.remove_at(i2)
			sel = {}
			Spiel.speichern()
			render()))
	v.add_child(row)
	if not werkstatt:
		v.add_child(hud._label("Aufwerten und neu fassen: beim Goldschmied in der Werkstatt des Ptah, am Eingang jeder Stunde.", 12, Hud.DIM))
	return p
