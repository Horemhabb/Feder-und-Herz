class_name Menue extends VBoxContainer
# Spielmenü (3.0): Esc hält das Spiel an. Von hier aus: weiterspielen, Lexikon, Steuerung, Einstellungen,
# eine erreichte Stunde noch einmal betreten, zum Titel zurück oder eine neue Figur anlegen.

var hud: Hud
var game: Node
var seite := ""          # "", "lexikon", "steuerung", "einstellungen", "stunden", "figur"

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	render()

func _clear() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

func _knopf(text: String, main: bool, cb: Callable, enabled := true, breit := 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL   # Gamepad und Pfeiltasten wählen per Fokus (hud.gd)
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.add_theme_font_size_override("font_size", 17)
	b.custom_minimum_size = Vector2(breit, 46)
	if main:
		b.add_theme_stylebox_override("normal", hud._flat(Hud.GOLD, 8))
		b.add_theme_stylebox_override("hover", hud._flat(Hud.GOLD.lightened(0.15), 8))
		b.add_theme_stylebox_override("pressed", hud._flat(Hud.GOLD.darkened(0.15), 8))
		for c in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(c, Color("14110c"))
	else:
		b.add_theme_stylebox_override("normal", hud._flat(Color(0, 0, 0, 0), 8, Color("5c4a2e"), 1))
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

func geh(s: String) -> void:
	seite = s
	render()

# Esc: von einer Unterseite zurück ins Menü, vom Menü zurück ins Spiel. Rückgabe: ob das Menü offen bleibt
func zurueck() -> bool:
	if seite == "":
		return false
	geh("")
	return true

func _kopf(titel: String) -> void:
	var top := HBoxContainer.new()
	var t := hud._label(titel, 26, Hud.PARCH)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	if seite != "":
		top.add_child(_knopf(hud._taste("  Zurück  [Esc]  "), false, func(): geh("")))
	add_child(top)

func render() -> void:
	var fi := hud.fokus_index(hud.overlay) if hud.overlay != null else -1
	_clear()
	match seite:
		"lexikon": _lexikon()
		"steuerung": _steuerung()
		"einstellungen": _einstellungen()
		"stunden": _stunden()
		"figur": _figur()
		_: _haupt()
	hud._pass_all(self)
	if fi >= 0:
		hud.fokus_setzen(hud.overlay, fi)

func _haupt() -> void:
	add_child(hud._para("PAUSE", 13, Hud.GOLD, true))
	add_child(hud._para("Herz und Feder", 34, Hud.PARCH, true))
	add_child(hud._para("%s · %s · Stufe %d" % [Stunden.hour_txt(Spiel.fall), Spiel.CLS[Spiel.cls].name, Spiel.lvl], 14, Hud.DIM, true))
	var mitte := CenterContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	mitte.add_child(v)
	v.add_child(_knopf(hud._taste("Weiterspielen  [Esc]"), true, func(): game.toggle_menu(), true, 360))
	v.add_child(_knopf("Lexikon: Götter und Begriffe", false, func(): geh("lexikon"), true, 360))
	v.add_child(_knopf("Steuerung", false, func(): geh("steuerung"), true, 360))
	v.add_child(_knopf("Einstellungen", false, func(): geh("einstellungen"), true, 360))
	if Spiel.max_fall > 1:
		v.add_child(_knopf("Stunde wechseln", false, func(): geh("stunden"), true, 360))
	v.add_child(_knopf("Zum Titel", false, func(): game.zum_titel(), true, 360))
	v.add_child(_knopf("Neue Figur anlegen", false, func(): geh("figur"), true, 360))
	add_child(mitte)
	add_child(hud._para("Dein Fortschritt wird laufend gespeichert.", 12, Hud.DIM, true))
	var pz := hud.pad_zeile("Gamepad: Steuerkreuz oder linker Stick wählt, A bestätigt, B oder Start geht zurück.")
	pz.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(pz)

func _lexikon() -> void:
	_kopf("Lexikon")
	add_child(hud._para("Was du schon gehört hast, steht in dunkler Tinte. Der Rest ist zum Nachschlagen da.", 13, Hud.DIM))
	for g in Lexikon.gruppen():
		add_child(hud._label(g.to_upper(), 12, Hud.GOLD))
		for e in Lexikon.W:
			if e.gruppe != g:
				continue
			var kennt := Lexikon.kennt(e.id)
			var z := VBoxContainer.new()
			z.add_theme_constant_override("separation", 0)
			z.add_child(hud._label(e.name, 17, Hud.PARCH if kennt else Hud.DIM))
			z.add_child(hud._para(e.txt, 14, Hud.PARCH if kennt else Hud.DIM))
			add_child(z)

func _zeile(a: String, b: String) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var l := hud._label(a, 15, Hud.GOLD)
	l.custom_minimum_size = Vector2(250, 0)
	h.add_child(l)
	var r := hud._para(b, 15, Hud.PARCH)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(r)
	add_child(h)

func _steuerung() -> void:
	_kopf("Steuerung")
	if game.touch:
		_zeile("Finger halten", "Die Figur läuft dorthin.")
		_zeile("Gegner antippen", "Angreifen.")
		_zeile("Symbole unten", "Fähigkeiten und Rotbier. Nur gelernte Fähigkeiten wirken.")
		_zeile("Menü, Tasche, Fähigk.", "Knöpfe oben rechts.")
		_zeile("Figur am Eingang", "Antippen, um noch einmal mit ihr zu sprechen.")
	else:
		_zeile("W A S D", "Laufen. Die linke Maustaste gedrückt halten geht auch.")
		_zeile("Linke Maustaste", "Auf einen Gegner klicken: angreifen.")
		_zeile("Rechte Maustaste", "Fähigkeit der rechten Hand.")
		_zeile("1  2  3  4", "Fähigkeiten. Sie wirken erst, wenn du sie im Fähigkeitenbaum gelernt hast.")
		_zeile("Q", "Rotbier der Sachmet trinken (heilt).")
		_zeile("Leertaste", "Ausweichschritt, kurz unverwundbar.")
		_zeile("E", "Sprechen, Werkstatt betreten, in Fenstern bestätigen.")
		_zeile("K", "Fähigkeitenbaum.")
		_zeile("I oder Tab", "Tasche und Ausrüstung.")
		_zeile("Esc", "Dieses Menü. Das Spiel steht, solange es offen ist.")
		_zeile("M  G  V  F", "Ton, Grafik, Vollbild, Bildrate anzeigen.")

func _schalter(name: String, wert: String, cb: Callable) -> void:
	var h := HBoxContainer.new()
	var l := hud._label(name, 16, Hud.PARCH)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(_knopf(wert, false, func():
		cb.call()
		render(), true, 190))
	add_child(h)

func _regler(name: String, key: String, probe := "") -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var l := hud._label(name, 16, Hud.PARCH)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var wert := hud._label("%d %%" % round(float(Spiel.einst.get(key, 1.0)) * 100.0), 14, Hud.DIM)
	wert.custom_minimum_size = Vector2(56, 0)
	wert.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(Spiel.einst.get(key, 1.0))
	s.custom_minimum_size = Vector2(240, 30)
	s.focus_mode = Control.FOCUS_ALL
	s.tooltip_text = "Pfeiltasten oder Steuerkreuz links und rechts ändern den Wert."
	var zieht := [false]
	s.value_changed.connect(func(v: float):
		Spiel.einst[key] = v
		wert.text = "%d %%" % round(v * 100.0)
		game.sfx.einst_anwenden()
		if not zieht[0]:
			# per Taste oder Gamepad geändert: gleich speichern und zur Probe kurz anspielen
			Spiel.einst_speichern()
			if probe != "":
				game.sfx.play(probe))
	s.drag_started.connect(func(): zieht[0] = true)
	s.drag_ended.connect(func(_c):
		zieht[0] = false
		Spiel.einst_speichern()
		if probe != "":
			game.sfx.play(probe))
	# gewählter Regler: Name und Wert leuchten golden (der Fokusrahmen der Knöpfe passt nicht auf einen Regler)
	s.focus_entered.connect(func():
		l.add_theme_color_override("font_color", Hud.RUBRIK)
		wert.add_theme_color_override("font_color", Hud.RUBRIK))
	s.focus_exited.connect(func():
		l.add_theme_color_override("font_color", Hud.INK)   # das Menü liegt auf Papyrus: Tinte, nicht Pergamentfarbe
		wert.add_theme_color_override("font_color", Hud.INK_DIM))
	h.add_child(s)
	h.add_child(wert)
	add_child(h)

func _einstellungen() -> void:
	_kopf("Einstellungen")
	add_child(hud._label("HILFE", 12, Hud.GOLD))
	_schalter("Hinweise für neue Figuren", "An" if float(Spiel.einst.get("hinweise", 1.0)) > 0.5 else "Aus", func():
		Spiel.einst["hinweise"] = 0.0 if float(Spiel.einst.get("hinweise", 1.0)) > 0.5 else 1.0
		Spiel.einst_speichern())
	add_child(hud._label("TON", 12, Hud.GOLD))
	_schalter("Ton", "Aus" if game.sfx.muted else "An", func(): game.sfx.set_muted(not game.sfx.muted))
	_regler("Lautstärke gesamt", "laut")
	_regler("Musik", "musik")
	_regler("Geräusche (Schritte, Kampf, Umgebung)", "geraeusche", "hit")
	add_child(hud._label("BILD", 12, Hud.GOLD))
	_schalter("Grafik", game.GUETE_NAME[game.guete], func(): game.guete_von_hand((game.guete + 1) % 4))
	if not game.touch:
		_schalter("Leiste unten", "%d %%" % round(float(Spiel.einst.get("leiste", 0.75)) * 100.0), func():
			var stufen := [0.6, 0.75, 0.9, 1.0]
			var i := 0
			for k in stufen.size():
				if absf(stufen[k] - float(Spiel.einst.get("leiste", 0.75))) < 0.03:
					i = k
			Spiel.einst["leiste"] = stufen[(i + 1) % stufen.size()]
			Spiel.einst_speichern()
			hud.leiste_skalieren())
	if game.can_fullscreen or not OS.has_feature("web"):
		_schalter("Vollbild", "An" if game.is_fullscreen() else "Aus", func(): game.toggle_fullscreen())
	_schalter("Bildrate anzeigen", "An" if hud.l_fps.visible else "Aus", func(): hud.toggle_fps())
	add_child(hud._para("Vier Stufen: „Niedrig“ schaltet Schatten, Glühen und Dunst ab und rechnet das Bild kleiner; „Sparsam“ und „Minimal“ rechnen noch kleiner und mit weniger Lichtern. Ruckelt es, stellt das Spiel die Stufe von selbst herunter.", 13, Hud.DIM))
	# Protokoll (4.0.1): was beim Spielen passiert, zum Nachlesen bei Fehlern und Ruckeln
	add_child(hud._label("PROTOKOLL", 12, Hud.GOLD))
	_schalter("Protokoll", "Herunterladen" if OS.has_feature("web") else "Ordner öffnen", func(): hud.toast(Protokoll.ausgeben(), 6.0))
	add_child(hud._para("Das Spiel schreibt Bildrate, Ruckler, Rechenzeit, Fehler und eine Bau-Prüfung jeder Stunde mit (Taste F9 geht auch). Die Datei kannst du weitergeben, wenn etwas nicht stimmt.", 13, Hud.DIM))
	# Schwierigkeit nachträglich wechseln (4.0, G2): gilt ab der nächsten Stunde oder wenn man eine Stunde neu betritt
	add_child(hud._label("SCHWIERIGKEIT", 12, Hud.GOLD))
	var hf := HFlowContainer.new()
	hf.add_theme_constant_override("h_separation", 6)
	for i in Daten.DIFF.size():
		var ii: int = i
		hf.add_child(_knopf(Daten.DIFF[i].name, i == Spiel.diff, func():
			Spiel.diff = ii
			Spiel.calc()
			Spiel.speichern()
			hud.toast("Schwierigkeit: %s. Das Verhalten der Gegner gilt sofort, Leben und Schaden ab der nächsten Stunde." % Daten.DIFF[ii].name, 4.0)
			geh("einstellungen"), i != Spiel.diff))
	add_child(hf)
	add_child(hud._para("%s: %s. Ein Wechsel wirkt sofort auf das Verhalten (wie viele zugleich angreifen, ob Rudel einander rufen, wie weit Gegner sehen, wie oft Legendäres fällt); Leben und Schaden der Gegner ändern sich ab der nächsten Stunde oder wenn du eine Stunde neu betrittst." % [Daten.DIFF[Spiel.diff].name, Daten.DIFF[Spiel.diff].txt], 13, Hud.DIM))

func _stunden() -> void:
	_kopf("Stunde wechseln")
	add_child(hud._para("Jede erreichte Stunde lässt sich noch einmal betreten. Sie beginnt dann von vorn; Stufe und Ausrüstung behältst du.", 14, Hud.DIM))
	var hf := HFlowContainer.new()
	hf.add_theme_constant_override("h_separation", 6)
	hf.add_theme_constant_override("v_separation", 6)
	for n in range(maxi(1, Spiel.max_fall - 11), Spiel.max_fall + 1):
		var nn: int = n
		hf.add_child(_knopf("%d · %s" % [Stunden.hour_of(n), Stunden.def(n).name] if Stunden.night_of(n) == 1 else Stunden.hour_txt(n),
			n == Spiel.fall, func(): game.go_hour(nn), n != Spiel.fall))
	add_child(hf)

func _figur() -> void:
	_kopf("Neue Figur anlegen")
	add_child(hud._para("Der jetzige Spielstand (%s, Stufe %d) wird dabei gelöscht. Das lässt sich nicht rückgängig machen." % [Spiel.CLS[Spiel.cls].name, Spiel.lvl], 15, Hud.PARCH))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.add_child(_knopf("Ja, neue Figur anlegen", false, func(): game.new_character()))
	h.add_child(_knopf("Abbrechen", true, func(): geh("")))
	add_child(h)
