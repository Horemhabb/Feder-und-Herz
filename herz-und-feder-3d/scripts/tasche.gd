class_name Tasche extends VBoxContainer
# Ausrüstung und Tasche (07-ui.js › renderInv): acht Plätze, Werte, Material und Scherben, die Tasche mit 32 Plätzen,
# das Detail des gewählten Teils (Anlegen, Aufwerten, Neuwürfeln, Wegwerfen), der Grabräuber, das Buch des Thot
# und „Neue Figur anlegen“. Jede Aktion speichert sofort.

var hud: Hud
var game: Node
var sel := {}          # {"eq": Platz} oder {"bag": Index}
var ask_reset := false

func _ready() -> void:
	add_theme_constant_override("separation", 12)
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
	b.add_theme_font_size_override("font_size", 15)
	b.custom_minimum_size = Vector2(0, 40)
	if main:
		b.add_theme_stylebox_override("normal", hud._flat(Hud.GOLD, 8))
		b.add_theme_stylebox_override("hover", hud._flat(Hud.GOLD.lightened(0.15), 8))
		b.add_theme_stylebox_override("pressed", hud._flat(Hud.GOLD.darkened(0.15), 8))
		b.add_theme_stylebox_override("disabled", hud._flat(Color(Hud.GOLD, 0.3), 8))
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			b.add_theme_color_override(c, Color("14110c"))
	else:
		b.add_theme_stylebox_override("normal", hud._flat(Color(0, 0, 0, 0), 8, Color("3d3947"), 1))
		b.add_theme_stylebox_override("hover", hud._flat(Color(1, 1, 1, 0.06), 8, Hud.DIM, 1))
		b.add_theme_stylebox_override("pressed", hud._flat(Color(1, 1, 1, 0.1), 8, Hud.DIM, 1))
		b.add_theme_stylebox_override("disabled", hud._flat(Color(0, 0, 0, 0), 8, Color("2a2731"), 1))
		b.add_theme_color_override("font_color", Hud.PARCH)
		b.add_theme_color_override("font_disabled_color", Color(Hud.DIM, 0.5))
	b.disabled = not enabled
	b.pressed.connect(func():
		game.sfx.play("ui")
		cb.call())
	return b

func _h3(t: String) -> Label:
	var l := hud._label(t.to_upper(), 12, Hud.DIM)
	return l

# Ein Feld mit Symbol: Rahmen in Seltenheitsfarbe, „+N“ für Aufwertung, „▲“ wenn besser als das Angelegte
func _cell(it, cb: Callable, chosen: bool, caption := "") -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.custom_minimum_size = Vector2(64, 64)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var col := Color("3d3947")
	if it != null:
		col = Daten.RAR[it.rar].col
		b.icon = Daten.icon(Daten.icon_of(it))
	var bg := Color("211f27")
	b.add_theme_stylebox_override("normal", hud._flat(bg, 8, col, 3 if chosen else 2))
	b.add_theme_stylebox_override("hover", hud._flat(bg.lightened(0.06), 8, col, 3))
	b.add_theme_stylebox_override("pressed", hud._flat(bg.lightened(0.1), 8, col, 3))
	if chosen:
		b.add_theme_stylebox_override("normal", hud._flat(bg.lightened(0.1), 8, Hud.PARCH, 3))
	b.pressed.connect(func():
		game.sfx.play("ui", 0.1, -6.0)
		cb.call())
	if it != null:
		if int(it.get("up", 0)) > 0:
			var u := hud._label("+%d" % it.up, 12, Hud.PARCH)
			u.position = Vector2(5, 2)
			b.add_child(u)
		if it.has("_better"):
			var a := hud._label("▲", 14, Color("7ad08a"))
			a.position = Vector2(46, 0)
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

func render() -> void:
	_clear()
	var S: Dictionary = Spiel.S
	# Kopf
	var top := HBoxContainer.new()
	var t := hud._label("Ausrüstung", 26, Hud.PARCH)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	top.add_child(_knopf(hud._taste("  Schließen  [I]  "), false, func(): game.toggle_bag()))
	add_child(top)
	# Ausrüstung
	var eqf := HFlowContainer.new()
	eqf.add_theme_constant_override("h_separation", 8)
	eqf.add_theme_constant_override("v_separation", 8)
	for slot in Daten.SLOTS:
		var s: String = slot
		eqf.add_child(_cell(Spiel.eq.get(s), func(): sel = {"eq": s}; render(), sel.get("eq", "") == s, Daten.SLOT[s].name))
	add_child(eqf)
	# Werte
	var st := HFlowContainer.new()
	st.add_theme_constant_override("h_separation", 18)
	var rows := [
		["Schaden", "%d" % round(S.dmg)], ["Leben", "%d" % S.max_hp], ["Rüstung", "%d · −%d %%" % [S.armor, round(S.red * 100.0)]],
		["Krit. Chance", "%d %%" % round(S.crit)], ["Krit. Schaden", "+%d %%" % S.crit_dmg], ["Angriffe/s", "%.2f" % S.rate],
		["Lauftempo", "%d %%" % round(S.speed * 100.0)], ["%s/s" % Spiel.CLS[Spiel.cls].res, "%d" % S.regen], ["Dornen", "%d" % S.thorns],
		["Leben pro Treffer", "%d" % S.loh], ["Erfahrung", "+%d %%" % round((S.xp_mul - 1.0) * 100.0)], ["Beuteglück", "+%d %%" % round((S.find - 1.0) * 100.0)],
	]
	for r in rows:
		var h := HBoxContainer.new()
		h.custom_minimum_size = Vector2(230, 0)
		var a := hud._label(r[0], 14, Hud.DIM)
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(a)
		h.add_child(hud._label(r[1], 14, Hud.PARCH))
		st.add_child(h)
	add_child(st)
	# Material und Scherben
	add_child(_h3("Material"))
	var mf := HFlowContainer.new()
	mf.add_theme_constant_override("h_separation", 16)
	for k in Daten.MAT_ORDER:
		mf.add_child(_mat_row(Daten.ICON[k], "%s %d" % [Daten.MATS[k].name, Spiel.mats[k]], Daten.MATS[k].txt))
	mf.add_child(_mat_row(Daten.ICON.shard, "Scherben %d" % Spiel.shards, "Für den Grabräuber, das Neuwürfeln und (bald) den Fähigkeitenbaum."))
	add_child(mf)
	# Tasche
	var bh := HBoxContainer.new()
	var bt := _h3("Tasche (%d von %d)" % [Spiel.bag.size(), Daten.BAG_MAX])
	bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
			e.custom_minimum_size = Vector2(64, 64)
			e.mouse_filter = Control.MOUSE_FILTER_PASS
			e.add_theme_stylebox_override("panel", hud._flat(Color(0, 0, 0, 0), 8, Color("2a2731"), 1))
			bf.add_child(e)
	add_child(bf)
	# Detail
	add_child(_detail())
	# Grabräuber
	var gr := HBoxContainer.new()
	gr.add_theme_constant_override("separation", 10)
	gr.add_child(_knopf("Beim Grabräuber tauschen: %d Scherben gegen ein unbekanntes Teil" % Daten.GAMBLE, false, func():
		var it := Spiel.gamble()
		if not it.is_empty():
			sel = {"bag": Spiel.bag.size() - 1}
			hud.toast_item(Daten.icon_of(it), Daten.item_name(it), game.item_sub(it), Daten.RAR[it.rar].col)
		render(), Spiel.shards >= Daten.GAMBLE and Spiel.bag.size() < Daten.BAG_MAX))
	add_child(gr)
	# Buch des Thot
	add_child(_h3("Buch des Thot (%d von %d Seiten)" % [Spiel.evid.size(), Daten.EVID.size()]))
	var found: Array = Spiel.evid.duplicate()
	found.sort()
	for i in found:
		var pv := VBoxContainer.new()
		pv.add_child(hud._label("%d · %s" % [i + 1, Daten.EVID[i][0]], 15, Hud.PARCH))
		pv.add_child(hud._para(Daten.EVID[i][1], 13, Hud.DIM))
		add_child(pv)
	if found.size() < Daten.EVID.size():
		add_child(hud._para("Noch nicht gefunden … Elite-Gegner und Hüter tragen die Seiten bei sich.", 13, Color(Hud.DIM, 0.6)))
	# Stunde wechseln: jede erreichte Stunde noch einmal betreten (beginnt neu)
	if Spiel.max_fall > 1:
		add_child(_h3("STUNDE WECHSELN"))
		var hf := HFlowContainer.new()
		hf.add_theme_constant_override("h_separation", 6)
		hf.add_theme_constant_override("v_separation", 6)
		for n in range(maxi(1, Spiel.max_fall - 11), Spiel.max_fall + 1):
			var nn: int = n
			hf.add_child(_knopf("%d · %s" % [Stunden.hour_of(n), Stunden.def(n).name] if Stunden.night_of(n) == 1 else Stunden.hour_txt(n),
				n == Spiel.fall, func(): game.go_hour(nn), n != Spiel.fall))
		add_child(hf)
	# Neue Figur
	var nf := HBoxContainer.new()
	nf.add_theme_constant_override("separation", 10)
	if ask_reset:
		nf.add_child(hud._label("Wirklich? Der Spielstand wird beim Start gelöscht.", 13, Hud.DIM))
		nf.add_child(_knopf("Ja, zur Neuanlage", false, func(): game.new_character()))
		nf.add_child(_knopf("Abbrechen", false, func(): ask_reset = false; render()))
	else:
		nf.add_child(_knopf("Neue Figur anlegen (Spielstand löschen)", false, func(): ask_reset = true; render()))
	add_child(nf)

	hud._pass_all(self)

func _mat_row(icon: int, text: String, tip: String) -> Control:
	var h := HBoxContainer.new()
	h.tooltip_text = tip
	var tr := TextureRect.new()
	tr.texture = Daten.icon(icon)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.custom_minimum_size = Vector2(28, 28)
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

func _detail() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", hud._flat(Color("08080d"), 8, Color("3d3947"), 1))
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 12)
	p.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	m.add_child(v)
	var it = _sel_item()
	if it == null:
		v.add_child(hud._label("Tipp ein Teil an, um es anzusehen.", 14, Hud.DIM))
		return p
	var worn := sel.has("eq")
	v.add_child(hud._label(Daten.item_name(it), 20, Daten.RAR[it.rar].col))
	v.add_child(hud._label("%s · %s · Gegenstandsstufe %d%s" % [Daten.RAR[it.rar].name, Daten.SLOT[it.slot].name, it.ilvl, " · angelegt" if worn else ""], 12, Hud.DIM))
	if it.has("dmg"):
		v.add_child(hud._label("Waffenschaden %d" % Daten.it_dmg(it), 15, Hud.PARCH))
	if it.has("armor"):
		v.add_child(hud._label("Rüstung %d" % Daten.it_arm(it), 15, Hud.PARCH))
	for k in it.aff.keys():
		var h := HBoxContainer.new()
		var l := hud._label(Daten.aff_line(it, k), 14, Hud.PARCH)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		var key: String = k
		h.add_child(_knopf("↻ neu würfeln", false, func():
			if Spiel.reroll(it, key):
				_changed(), _can_pay({"staub": Daten.REROLL_STAUB}, Daten.REROLL_SHARDS) and it.aff.size() < Daten.AFF_ORDER.size()))
		v.add_child(h)
	if it.aff.size() > 0:
		v.add_child(hud._label("Neu würfeln: %s ersetzt das Affix durch ein anderes." % _cost_txt({"staub": Daten.REROLL_STAUB}, Daten.REROLL_SHARDS), 11, Hud.DIM))
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
	if u < Daten.UP_MAX:
		var c := Daten.up_cost(it)
		row.add_child(_knopf("Aufwerten auf +%d: %s" % [u + 1, _cost_txt(c)], false, func():
			if Spiel.upgrade(it):
				game.sfx.play("gate", 0.1, -8.0)
				_changed(), _can_pay(c)))
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
	return p
