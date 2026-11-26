extends Node
# Die Figur über Stunden und Neustarts hinweg (Autoload „Spiel“): Klasse, Stufe, Erfahrung, Ausrüstung, Tasche,
# Scherben, Material, Buch des Thot, Schwierigkeit und Hardcore. Dazu die Werte, die daraus folgen (calcStats der 2D-Fassung),
# und der Spielstand. Wie in der 2D-Fassung wird nur die Figur gespeichert: Eine Stunde beginnt nach dem Laden von vorn.

const DATEI := "user://spielstand.json"
var schau_gesehen := false   # „-- --schau“ öffnet den Schaukasten nur beim Start, nicht bei der Rückkehr ins Spiel
var neu3d := true    # seit 2.5 stammen alle Figuren aus der Figurenfabrik
const VERSION := 1   # Aufbau des Spielstands (nicht die Fassung)
# Fassung des Spiels, sichtbar auf dem Titel und im Menü. Bei jeder Änderung, die man im Spiel merkt, erhöhen.
# Dahinter steht der Bau: GitHub schreibt beim Veröffentlichen Nummer, Zeit und Stand in scripts/bau.gd,
# am eigenen Rechner steht dort „eigener Stand“. So lässt sich die Webfassung vom PC unterscheiden.
const FASSUNG := "4.2.2"

func fassung_txt() -> String:
	var bau = load("res://scripts/bau.gd")
	return "Fassung %s · %s" % [FASSUNG, bau.TEXT if bau else "?"]

# Klassen, Fähigkeiten und Baum stehen in klassen.gd
var CLS: Dictionary:
	get: return Klassen.CLS

var cls := "ermittler"
var lvl := 1
var xp := 0.0
var eq := {}          # Platz -> Gegenstand
var bag: Array = []   # Gegenstände in der Tasche
var shards := 0
var mats := {"staub": 0, "leder": 0, "eisen": 0, "stern": 0}
var evid: Array = []  # gefundene Seiten des Buchs des Thot (Nummern 0–11)
var diff := 0
var hc := false
var fall := 1         # laufende Stunde (1, 2, … über alle Nächte)
var max_fall := 1
var muted := false
var item_id := 1
var tree := {"r": {}, "a": {}, "p": {}, "key": false}   # Fähigkeitenbaum: Ränge, Wucht/Eile, Passive, Schlüsselstein
var pots := Daten.POTS   # Rotbier: wird nicht gespeichert, wie in der 2D-Fassung
var herz := 0.0          # Herzwaage: über null leicht (Maat), unter null schwer (Isfet); −100 bis 100
var ba_heim := 0         # so viele Ba ohne Namen hat die Figur heimgeführt (2.9); jeder sagt einen Satz mehr
var einst := {"laut": 1.0, "musik": 1.0, "leiste": 0.75}   # Einstellungen (3.0): gelten für alle Figuren, eigene Datei
const EINST_DATEI := "user://einstellungen.json"
var wissen := {}         # was die Figur schon gesehen, gehört oder erklärt bekommen hat (3.0): Lexikon, Hinweise, Textwahl
var baum_neu := false   # 3.3: der alte Baum passte nicht mehr, die Punkte sind zurückgegeben (einmal sagen)
var tree_frei := 0       # geschenkte Punkte (3.0): alte Spielstände behalten ihre schon nutzbaren Fähigkeiten
var urteil5 := ""        # Urteil am Ende der fünften Stunde: "leicht", "schwer" oder "schwebe" (Farbe des Tuchs)
var wahl := {}           # Entscheidungen je Stunde der Nacht: "1" → "maat" oder "isfet"
var segen := {}          # Segen der Schreine in dieser Stunde: Gott → true (setzt main.gd, wirkt in calc)
var neu := 0             # neue Teile seit dem letzten Blick in die Tasche
var hat_stand := false   # liegt ein Spielstand vor?
var force_new := false   # Startbildschirm gleich im Modus „Neue Figur“
var skip_intro := false  # beim Neuladen der Szene gleich zur Tafel der Stunde (statt Startbildschirm)
var S := {}              # abgeleitete Werte, siehe calc()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if "--neu" in OS.get_cmdline_user_args():
		loeschen()
	else:
		einst_laden()
	laden()
	# Testläufe: „-- --klasse=jaegerin“ legt eine frische Figur dieser Klasse an
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--klasse="):
			neue_figur(a.substr(9), diff, false)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--stunde="):
			# Testläufe: „-- --stunde=3“ beginnt in dieser Stunde
			fall = maxi(1, int(a.substr(9)))
			max_fall = maxi(max_fall, fall)
	calc()

# Im Browser: steht das Wort hinter dem Fragezeichen der Adresse? („…/Feder-und-Herz/?schau“ öffnet den Schaukasten)
func web_frage(wort: String) -> bool:
	if not OS.has_feature("web"):
		return false
	return str(JavaScriptBridge.eval("window.location.search")).contains(wort)

func neue_figur(c: String, d: int, hardcore: bool) -> void:
	cls = c if CLS.has(c) else "ermittler"
	tree = {"r": {}, "a": {}, "p": {}, "key": false}
	lvl = 1
	xp = 0.0
	eq = {}
	bag = []
	shards = 0
	mats = {"staub": 0, "leder": 0, "eisen": 0, "stern": 0}
	evid = []
	diff = clampi(d, 0, 2)
	hc = hardcore
	fall = 1
	max_fall = 1
	item_id = 1
	pots = Daten.POTS
	neu = 0
	herz = 0.0
	wahl = {}
	urteil5 = ""
	ba_heim = 0
	tree_frei = 0
	baum_neu = false
	wissen = {}
	segen = {}
	calc()
	speichern()

func D() -> Dictionary:
	return Daten.DIFF[diff]

func has_leg(id: String) -> bool:
	return S.get("legs", {}).has(id)

func new_item(ilvl: int, min_rar: int, force := {}) -> Dictionary:
	var it := Daten.make_item(item_id, ilvl, min_rar, float(D().leg), force)
	item_id += 1
	return it

# Werte aus Stufe, Klasse, Ausrüstung und (ab Etappe 2) Passiven
func calc() -> void:
	var C: Dictionary = CLS[cls]
	var a := {}
	for k in Daten.AFF_ORDER:
		a[k] = 0
	var armor := 0
	var legs := {}
	for slot in eq:
		var it: Dictionary = eq[slot]
		armor += Daten.it_arm(it)
		for k in it.aff:
			a[k] += Daten.it_aff(it, k)
		if it.has("leg"):
			legs[it.leg] = true
	armor += a.armor
	var w = eq.get("waffe")
	var dmg: float = ((Daten.it_dmg(w) if w else 4) + 3.0 + lvl * 1.2) * 1.2 * (1.0 + a.dmgPct / 100.0)
	# Herzwaage und Segen der Schreine
	var leicht := 2 if herz >= 60.0 else (1 if herz >= Geschichte.LEICHT else 0)
	var schwer := 2 if herz <= -60.0 else (1 if herz <= Geschichte.SCHWER else 0)
	dmg *= (1.0 + 0.1 * schwer) * (1.3 if segen.has("sachmet") else 1.0)
	S = {
		"dmg": dmg,
		"max_hp": round((110.0 + lvl * 20.0 + a.hp) * C.hp * (1.0 + 0.06 * pas("zaeh")) * (0.9 if schwer == 2 else 1.0)),
		"armor": armor,
		"red": 1.0 - (1.0 - armor / (armor + 100.0)) * (1.0 - C.red),
		"crit": minf(60.0, 5.0 + a.crit + (15.0 if legs.has("star") else 0.0) + 2.0 * pas("scharf")),
		"crit_dmg": 50.0 + a.critDmg,
		"speed": C.spd * (1.0 + minf(45.0, a.speed + (15.0 if legs.has("caravan") else 0.0) + 3.0 * pas("flink")) / 100.0) * (1.25 if segen.has("bastet") else 1.0),
		"rate": 1.75 * (1.0 + a.as / 100.0),
		"regen": C.regen + a.regen + pas("kraft") + 2.0 * leicht,
		"loh": float(a.loh),
		"thorns": float(a.thorns),
		"xp_mul": 1.0 + a.xp / 100.0 + 0.1 * leicht + (0.5 if segen.has("seschat") else 0.0),
		"find": 1.0 + a.find / 100.0 + (0.6 if segen.has("hathor") else 0.0),
		"cone": (1.35 if legs.has("sight") else 1.0) * (1.0 + 0.125 * leicht),
		"shard": 1.0 + 0.25 * schwer,
		"pick": (170.0 if legs.has("greed") else 34.0) / Daten.PX,
		"legs": legs,
		"a": a,
	}

# Gewicht auf die Herzwaage legen (plus: Maat, minus: Isfet); gibt zurück, ob sich die Stufe geändert hat
func wiegen(v: float) -> bool:
	var vor := Geschichte.herz_name(herz)
	herz = clampf(herz + v, -100.0, 100.0)
	calc()
	return Geschichte.herz_name(herz) != vor

# ---------------------------------------------------------------- Fähigkeitenbaum (01-data.js › treeSpent, treePoints, respecCost)
func pas(id: String) -> int:
	return int(tree.p.get(id, 0))

func rank(id: String) -> int:
	return int(tree.r.get(id, 0))

func aug(id: String) -> String:
	return String(tree.a.get(id, ""))

func tree_spent() -> int:
	var n := 0
	for k in tree.r:
		n += int(tree.r[k])
	for k in tree.p:
		n += int(tree.p[k])
	return n + tree.a.size() + (1 if tree.key else 0)

# Punkte: einer je Stufe und einer zum Einstand. Mit der ersten Stufe lassen sich also zwei Fähigkeiten lernen.
func tree_points() -> int:
	return lvl + 1 + tree_frei - tree_spent()

func einst_laden() -> void:
	if not FileAccess.file_exists(EINST_DATEI):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(EINST_DATEI))
	if d is Dictionary:
		for k in einst.keys():
			if d.has(k):
				einst[k] = clampf(float(d[k]), 0.0, 1.0)

func einst_speichern() -> void:
	var f := FileAccess.open(EINST_DATEI, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(einst))
		f.close()

func gesehen(k: String) -> bool:
	return wissen.has(k)

func merke(k: String) -> void:
	if not wissen.has(k):
		wissen[k] = 1
		speichern()

# Seit 3.0 wirkt eine Fähigkeit erst, wenn sie im Baum gelernt ist (Rang 1). Das Rotbier kann jeder trinken.
func gelernt(id: String) -> bool:
	return id == "potion" or rank(id) >= 1

func lernbar(id: String) -> bool:
	return Klassen.unlock_lvl(cls, id) <= lvl

# ---- Baum als Baum (3.3): Ein Knoten ist gelernt, wenn er im Spielstand steht; lernbar nur neben Gelerntem.
func knoten_gelernt(key: String) -> bool:
	if key == "w":
		return true
	if key == "k":
		return bool(tree.key)
	if key.begins_with("s:"):
		return rank(key.substr(2)) > 0
	if key.begins_with("p:"):
		return pas(key.substr(2)) > 0
	if key.begins_with("a:"):
		var t := key.split(":")
		return aug(t[1]) == t[2]
	return false

func nachbar_gelernt(key: String) -> bool:
	var B := Klassen.baum(cls)
	for n in B.nachbarn.get(key, []):
		if knoten_gelernt(n):
			return true
	return false

# Hängt alles Gelernte über gelernte Knoten am Stamm? (Prüfung alter Spielstände)
func baum_gueltig() -> bool:
	var B := Klassen.baum(cls)
	var gesehen := {"w": true}
	var q := ["w"]
	while not q.is_empty():
		var k: String = q.pop_back()
		for n in B.nachbarn.get(k, []):
			if not gesehen.has(n) and knoten_gelernt(n):
				gesehen[n] = true
				q.append(n)
	for k in B.knoten:
		if knoten_gelernt(k) and not gesehen.has(k):
			return false
	return true

# Tests und der Spielroboter lernen der Reihe nach, was die Stufe hergibt: jede Fähigkeit Rang 1, vom Stamm nach außen
func auto_lernen() -> void:
	var mehr := true
	while mehr and tree_points() > 0:
		mehr = false
		for id in Klassen.order(cls):
			if id != "potion" and rank(id) == 0 and lernbar(id) and tree_points() > 0 and nachbar_gelernt("s:" + id):
				tree.r[id] = 1
				mehr = true
	calc()

# Umlernen kostet seit 3.3 nichts mehr, geht aber nur am Schrein des Thot
func respec_cost() -> int:
	return 0

func has_key() -> bool:
	return bool(tree.key)

# Stärke einer Fähigkeit: 12 % je Rang, Wucht 25 % (Hilfsfähigkeiten werden nicht stärker, sondern schneller bereit)
func sk_pow(id: String) -> float:
	if Klassen.SK[id].util:
		return 1.0
	return 1.0 + 0.12 * maxi(0, rank(id) - 1) + (0.25 if aug(id) == "wucht" else 0.0)

# Wirkdauer oder Weite einer Hilfsfähigkeit
func sk_upw(id: String) -> float:
	return 1.25 if aug(id) == "wucht" else 1.0

func tree_rank_up(id: String) -> bool:
	if tree_points() <= 0 or rank(id) >= Klassen.SK_RANKS:
		return false
	if rank(id) == 0 and (not lernbar(id) or not nachbar_gelernt("s:" + id)):
		return false   # erst ab der Stufe der Fähigkeit und nur neben schon Gelerntem
	tree.r[id] = rank(id) + 1
	calc()
	speichern()
	return true

func tree_aug(id: String, a: String) -> bool:
	# die erste Wahl kostet einen Punkt, Umwählen ist frei
	if rank(id) < 2:
		return false
	if aug(id) == "":
		if tree_points() <= 0:
			return false
	tree.a[id] = a
	speichern()
	return true

func tree_passive(id: String) -> bool:
	if tree_points() <= 0 or pas(id) >= Klassen.SK_RANKS:
		return false
	if pas(id) == 0 and not nachbar_gelernt("p:" + id):
		return false
	tree.p[id] = pas(id) + 1
	calc()
	speichern()
	return true

func tree_key() -> bool:
	if tree.key or tree_points() <= 0 or tree_spent() < Klassen.KEY_NEED or not nachbar_gelernt("k"):
		return false
	tree.key = true
	speichern()
	return true

func respec() -> bool:
	if tree_spent() == 0:
		return false
	tree = {"r": {}, "a": {}, "p": {}, "key": false}
	calc()
	speichern()
	return true

# Ein aufgehobener Gegenstand: in einen leeren Platz anlegen, sonst in die Tasche. Rückgabe: "angelegt", "tasche" oder "voll".
func take_item(it: Dictionary) -> String:
	if not eq.has(it.slot):
		eq[it.slot] = it
		calc()
		speichern()
		return "angelegt"
	if bag.size() >= Daten.BAG_MAX:
		return "voll"
	bag.append(it)
	neu += 1
	speichern()
	return "tasche"

func equip(i: int) -> void:
	var it: Dictionary = bag[i]
	bag.remove_at(i)
	if eq.has(it.slot):
		bag.insert(i, eq[it.slot])
	eq[it.slot] = it
	calc()
	speichern()

func pay(cost: Dictionary, sh := 0) -> bool:
	if shards < sh:
		return false
	for k in cost:
		if mats.get(k, 0) < cost[k]:
			return false
	for k in cost:
		mats[k] -= cost[k]
	shards -= sh
	return true

func upgrade(it: Dictionary) -> bool:
	if int(it.get("up", 0)) >= Daten.UP_MAX or not pay(Daten.up_cost(it), Daten.up_fee(it)):
		return false
	it["up"] = int(it.get("up", 0)) + 1
	calc()
	speichern()
	return true

# Neu fassen (3.0): Der Goldschmied zeigt zwei neue Eigenschaften zur Wahl; man nimmt eine oder behält die alte.
# Bezahlt wird für die Arbeit, also vorher. Rückgabe: [{k, v}, …] oder leer, wenn es nicht geht.
func reroll_angebot(it: Dictionary) -> Array:
	var free := Daten.AFF_ORDER.filter(func(x): return not it.aff.has(x))
	if free.is_empty() or not pay({"staub": Daten.REROLL_STAUB}, Daten.reroll_fee(it)):
		return []
	free.shuffle()
	var opts := []
	for nk in free.slice(0, 2):
		opts.append({"k": nk, "v": Daten.aff_wert(nk, int(it.ilvl))})
	speichern()
	return opts

func reroll_setzen(it: Dictionary, k: String, neu: Dictionary) -> void:
	var na := {}
	for x in it.aff:
		if x == k:
			na[neu.k] = neu.v
		else:
			na[x] = it.aff[x]
	it.aff = na
	calc()
	speichern()

func gamble() -> Dictionary:
	if bag.size() >= Daten.BAG_MAX or shards < Daten.GAMBLE:
		return {}
	shards -= Daten.GAMBLE
	var it := new_item(fall, 1)
	bag.append(it)
	speichern()
	return it

func xp_gain(v: float) -> bool:
	# gibt true zurück, wenn die Figur dabei eine Stufe aufgestiegen ist
	xp += v
	var up := false
	while xp >= Daten.xp_need(lvl):
		xp -= Daten.xp_need(lvl)
		lvl += 1
		up = true
	if up:
		calc()
		speichern()
	return up

# ---------------------------------------------------------------- Spielstand
func speichern() -> void:
	var d := {"v": VERSION, "fall": fall, "lvl": lvl, "xp": xp, "eq": eq, "bag": bag, "muted": muted, "itemId": item_id,
		"shards": shards, "evid": evid, "cls": cls, "diff": diff, "hc": hc, "mats": mats, "maxFall": max_fall, "tree": tree,
		"herz": herz, "wahl": wahl, "urteil5": urteil5, "baHeim": ba_heim, "treeFrei": tree_frei, "regel": 4, "wissen": wissen.keys()}
	var f := FileAccess.open(DATEI, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))
		f.close()
		hat_stand = true

func loeschen() -> void:
	if FileAccess.file_exists(DATEI):
		DirAccess.remove_absolute(DATEI)
	hat_stand = false

func laden() -> void:
	hat_stand = false
	if not FileAccess.file_exists(DATEI):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(DATEI))
	if not (d is Dictionary) or int(d.get("v", 0)) != VERSION or not CLS.has(d.get("cls", "")):
		return
	cls = d.cls
	diff = clampi(int(d.get("diff", 0)), 0, 2)
	hc = bool(d.get("hc", false))
	lvl = clampi(int(d.get("lvl", 1)), 1, 99)
	xp = maxf(0.0, float(d.get("xp", 0)))
	fall = clampi(int(d.get("fall", 1)), 1, 999)
	max_fall = clampi(int(d.get("maxFall", fall)), fall, 999)
	muted = bool(d.get("muted", false))
	item_id = maxi(1, int(d.get("itemId", 1)))
	shards = maxi(0, int(d.get("shards", 0)))
	herz = clampf(float(d.get("herz", 0.0)), -100.0, 100.0)
	wahl = d.get("wahl", {}) if d.get("wahl") is Dictionary else {}
	urteil5 = str(d.get("urteil5", ""))
	ba_heim = clampi(int(d.get("baHeim", 0)), 0, 99)
	eq = {}
	if d.get("eq") is Dictionary:
		for slot in d.eq:
			var it := Daten.clean_item(d.eq[slot])
			if not it.is_empty() and it.slot == slot:
				eq[slot] = it
	bag = []
	if d.get("bag") is Array:
		for v in d.bag:
			var it := Daten.clean_item(v)
			if not it.is_empty() and bag.size() < Daten.BAG_MAX:
				bag.append(it)
	mats = {"staub": 0, "leder": 0, "eisen": 0, "stern": 0}
	if d.get("mats") is Dictionary:
		for k in mats:
			mats[k] = maxi(0, int(d.mats.get(k, 0)))
	evid = []
	if d.get("evid") is Array:
		for v in d.evid:
			var i := int(v)
			if i >= 0 and i < Daten.EVID.size() and not evid.has(i):
				evid.append(i)
	tree = {"r": {}, "a": {}, "p": {}, "key": false}
	var t = d.get("tree")
	if t is Dictionary:
		var mine: Array = Klassen.order(cls)
		if t.get("r") is Dictionary:
			for k in t.r:
				if mine.has(k) and k != "potion":
					tree.r[k] = clampi(int(t.r[k]), 0, Klassen.SK_RANKS)
		if t.get("a") is Dictionary:
			for k in t.a:
				if tree.r.get(k, 0) >= 2 and Klassen.AUGS.has(t.a[k]):
					tree.a[k] = String(t.a[k])
		if t.get("p") is Dictionary:
			for pd in Klassen.PASSIVES:
				if t.p.has(pd.id):
					tree.p[pd.id] = clampi(int(t.p[pd.id]), 0, Klassen.SK_RANKS)
		tree.key = bool(t.get("key", false))
	tree_frei = clampi(int(d.get("treeFrei", 0)), 0, 99)
	wissen = {}
	if d.get("wissen") is Array:
		for k in d.wissen:
			wissen[str(k)] = 1
	if int(d.get("regel", 0)) < 3:
		# Spielstand von vor 3.0: Was die Figur schon konnte, bleibt ihr. Jede bisher nutzbare Fähigkeit gilt als gelernt,
		# gesteigerte Ränge rücken eine Stufe auf (Rang 1 ist jetzt die Grundstärke); die Punkte dafür sind geschenkt.
		for id in Klassen.order(cls):
			if id == "potion" or not lernbar(id):
				continue
			var r0: int = rank(id)
			if r0 < Klassen.SK_RANKS:
				tree.r[id] = r0 + 1
				tree_frei += 1
	if int(d.get("regel", 0)) < 4 and not baum_gueltig():
		# 3.3: Der Baum ist ein Baum geworden. Hängt etwas nicht mehr am Stamm, gibt es alle Punkte zurück zum Neuverteilen.
		tree = {"r": {}, "a": {}, "p": {}, "key": false}
		baum_neu = true
	pots = Daten.POTS
	hat_stand = true
