class_name Hinweise extends Node
# Kleine Hinweise für neue Figuren (4.1): in den ersten Minuten der ersten Stunde, genau dann, wenn sie gebraucht werden.
# Immer nur einer zugleich, über der Leiste; das Spiel hält dafür nicht an. Ein Hinweis verschwindet, sobald die Sache
# einmal getan ist, und kommt nie wieder: „erledigt“ steht im Spielstand der Figur (Spiel.wissen, Schlüssel „hinweis_…“).
# Der Schalter „Hinweise“ im Menü (Spiel.einst.hinweise) gilt für alle Figuren. Der Text folgt der Eingabeart.
# Das Hud erzeugt diesen Knoten; alles Weitere liest nur, was Hero, Spiel und Hud ohnehin wissen.

# Reihenfolge = Vorrang, wenn zwei zugleich anstehen
const FOLGE := ["laufen", "angriff", "faehigkeit", "heilen", "ausweichen", "tasche"]
var nah := 12.0          # so nah muss ein Gegner sein, damit Angriff und Fähigkeit dran sind (var: der Spieltest weitet es)
const ZEIT := 30.0       # so lange steht ein Hinweis höchstens da, dann zählt er als gesehen
var ruhe := 2.5          # Pause zwischen zwei Hinweisen (var: der Spieltest kürzt sie)
const PAD_TASTE := ["X", "Y", "LB", "RB"]

var hud: Hud
var game: Node
var panel: PanelContainer
var label: Label
var aktuell := ""          # der Hinweis, der gerade steht ("" = keiner)
var ausgeloest := {}       # Hinweise, deren Anlass schon eingetreten ist (bleibt, auch wenn der Anlass vergeht)
var aktiv_t := 0.0         # so lange war das Spiel frei und ohne Fenster
var start_pos := Vector3.ZERO
var gezeigt_t := 0.0
var ruhe_t := 1.0
var tw: Tween

func _ready() -> void:
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", hud._flat(Color(0.065, 0.055, 0.06, 0.88), 8, Color("5c4a2e"), 1))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.visible = false
	label = hud._label("", 15, Hud.PARCH)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rand := MarginContainer.new()
	for k in ["left", "right"]:
		rand.add_theme_constant_override("margin_" + k, 14)
	for k in ["top", "bottom"]:
		rand.add_theme_constant_override("margin_" + k, 5)
	rand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rand.add_child(label)
	panel.add_child(rand)
	hud.root.add_child(panel)

# ---------------------------------------------------------------- Zustand
func an() -> bool:
	return float(Spiel.einst.get("hinweise", 1.0)) > 0.5

func fertig(id: String) -> bool:
	return Spiel.gesehen("hinweis_" + id)

func _erledigen(id: String) -> void:
	Spiel.merke("hinweis_" + id)
	if aktuell == id:
		aktuell = ""
		ruhe_t = ruhe

func gegner_nah() -> bool:
	var h: Hero = game.hero
	for f in game.foes:
		if is_instance_valid(f) and f.state != Foe.St.DEAD and f.kind != "boss" \
				and f.global_position.distance_to(h.global_position) < nah:
			return true
	return false

# die erste Fähigkeit auf den Tasten 1 bis 4, die schon gelernt ist (Nummer 0 bis 3), sonst -1
func erste_faehigkeit() -> int:
	var h: Hero = game.hero
	for i in 4:
		if Spiel.gelernt(h.ORDER[i]):
			return i
	return -1

# hat der Spieler die Sache schon getan?
func getan(id: String) -> bool:
	var h: Hero = game.hero
	match id:
		"laufen": return start_pos != Vector3.ZERO and h.global_position.distance_to(start_pos) > 2.5
		"angriff": return h.hits > 0
		"faehigkeit": return h.casts > 0
		"heilen": return h.cd.get("potion", 0.0) > 0.0 or h.pots < Daten.POTS
		"ausweichen": return h.dodge_cd > 0.0
		"tasche": return hud.bag_open
	return false

# ist der Anlass da?
func anlass(id: String) -> bool:
	var h: Hero = game.hero
	match id:
		"laufen": return aktiv_t > 2.0
		"angriff": return gegner_nah()
		"faehigkeit": return erste_faehigkeit() >= 0 and gegner_nah()
		"heilen": return h.hp < h.max_hp * 0.5 and h.pots > 0
		"ausweichen": return h.hp < h.max_hp * 0.85
		"tasche": return Spiel.neu > 0
	return false

# ---------------------------------------------------------------- Texte
# "maus", "pad" oder "touch"
func modus() -> String:
	if game.touch:
		return "touch"
	return "pad" if game.pad else "maus"

func text_fuer(id: String, m: String) -> String:
	var h: Hero = game.hero
	match id:
		"laufen":
			return {"maus": "W A S D oder linke Maustaste halten: laufen.", "pad": "Linker Stick: laufen.", "touch": "Finger halten: laufen."}[m]
		"angriff":
			return {"maus": "Gegner anklicken: zuschlagen.", "pad": "A halten: zuschlagen.", "touch": "Gegner antippen: zuschlagen."}[m]
		"faehigkeit":
			var i := maxi(0, erste_faehigkeit())
			var n: String = h.SK[h.ORDER[i]].name
			return {"maus": "Taste %d: %s. Sie zielt auf den Zeiger." % [i + 1, n], "pad": "%s: %s." % [PAD_TASTE[i], n], "touch": "Symbol unten antippen: %s." % n}[m]
		"heilen":
			return {"maus": "Q: Rotbier trinken. Es heilt.", "pad": "LT: Rotbier trinken. Es heilt.", "touch": "Rotbier unten antippen. Es heilt."}[m]
		"ausweichen":
			return {"maus": "Leertaste: ausweichen. Kurz unverwundbar.", "pad": "B: ausweichen. Kurz unverwundbar.", "touch": "Knopf „Ausweichen“: kurz unverwundbar."}[m]
		"tasche":
			return {"maus": "I: Tasche. Dort legst du Neues an.", "pad": "Steuerkreuz runter: Tasche.", "touch": "Knopf „Tasche“ oben: Neues anlegen."}[m]
	return ""

# ---------------------------------------------------------------- Ablauf
func _process(delta: float) -> void:
	if not game.started or game.hero == null:
		return
	var h: Hero = game.hero
	# Heldentaten zählen immer, auch bei geöffnetem Fenster (der Baum und die Tasche halten das Spiel an)
	for id in FOLGE:
		if not fertig(id) and getan(id):
			_erledigen(id)
	# nur in der ersten Stunde einer neuen Figur, und nur wenn der Schalter an ist
	var gesperrt := not an() or Spiel.max_fall > 1
	if gesperrt:
		aktuell = ""
	var frei := not gesperrt and not game.get_tree().paused and hud.overlay == null and not hud.menu_open and not h.dead
	if frei:
		aktiv_t += delta
		if start_pos == Vector3.ZERO:
			start_pos = h.global_position
		for id in FOLGE:
			if not fertig(id) and not ausgeloest.has(id) and anlass(id):
				ausgeloest[id] = true
		ruhe_t -= delta
		var will := ""
		for id in FOLGE:
			if ausgeloest.has(id) and not fertig(id):
				will = id
				break
		if will != aktuell and (will != "" and (aktuell != "" or ruhe_t <= 0.0)):
			aktuell = will
			gezeigt_t = 0.0
		elif will == "" and aktuell != "":
			aktuell = ""
		if aktuell != "":
			gezeigt_t += delta
			if gezeigt_t > ZEIT:
				_erledigen(aktuell)   # lange genug gestanden: nicht noch einmal
	_zeigen(frei)

var _sichtbar_id := ""
func _zeigen(frei: bool) -> void:
	var soll := aktuell if frei else ""
	if soll != "":
		var t := text_fuer(soll, modus())
		if label.text != t:
			label.text = t
		# mittig über der Leiste (deren Höhe und Maßstab das Hud kennt)
		panel.size = Vector2.ZERO   # schrumpft auf die Größe des Textes
		var vb := hud.root.get_global_rect()
		var unten := vb.end.y - 188.0 * hud.leiste.scale.y - 14.0
		panel.position = Vector2(vb.position.x + (vb.size.x - panel.size.x) / 2.0, unten - panel.size.y)
	if soll == _sichtbar_id:
		return
	_sichtbar_id = soll
	if tw:
		tw.kill()
	if soll == "":
		panel.visible = false
		return
	panel.visible = true
	panel.modulate.a = 0.0
	tw = create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.4)
