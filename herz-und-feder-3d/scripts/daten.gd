class_name Daten
# Spieldaten aus der 2D-Fassung (nebelmark/src/01-data.js): Seltenheiten, Ausrüstungsplätze, Affixe, Legendäre,
# Buch des Thot, Material, Schwierigkeit und die Regeln für Gegenstände. Zahlen unverändert übernommen.
# Gegenstände sind Dictionaries wie in der 2D-Fassung, damit sie sich ohne Umweg speichern lassen.

const PX := 25.0   # so viele Weltpixel der 2D-Fassung entsprechen einem Meter hier

const RAR := [
	{"name": "Gewöhnlich", "col": Color("b9b3a0"), "aff": [0, 0], "mult": 1.0},
	{"name": "Magisch", "col": Color("6fa8ff"), "aff": [1, 2], "mult": 1.15},
	{"name": "Selten", "col": Color("f2d04b"), "aff": [3, 4], "mult": 1.3},
	{"name": "Legendär", "col": Color("ff8a3c"), "aff": [4, 4], "mult": 1.5},
]

const SLOTS := ["waffe", "nebenhand", "helm", "ruestung", "handschuhe", "stiefel", "amulett", "ring"]
const SLOT := {
	"waffe": {"name": "Waffe", "arm": 0.0, "bases": ["Chepesch", "Streitaxt", "Kompositbogen", "Was-Zepter", "Faustbinden", "Feuersteinmesser", "Birnenkeule", "Harpune"]},
	"nebenhand": {"name": "Nebenhand", "arm": 0.5, "bases": ["Tempellampe", "Fellschild", "Hathorspiegel", "Sistrum", "Schreibpalette", "Räucherarm"]},
	"helm": {"name": "Kopf", "arm": 0.6, "bases": ["Nemes-Tuch", "Chepresch", "Geierhaube", "Totenmaske", "Leinenkappe", "Stirnband mit Uräus"]},
	"ruestung": {"name": "Rüstung", "arm": 1.0, "bases": ["Leinenschurz", "Priestergewand", "Leopardenfell", "Lederkoller", "Schuppenpanzer", "Goldpektoral"]},
	"handschuhe": {"name": "Hände", "arm": 0.4, "bases": ["Leinenbinden", "Schützenhandschuhe", "Bronzefäustlinge", "Armschienen"]},
	"stiefel": {"name": "Füße", "arm": 0.4, "bases": ["Papyrussandalen", "Ledersandalen", "Reiseschuhe", "Beinschienen"]},
	"amulett": {"name": "Amulett", "arm": 0.0, "bases": ["Udjat-Auge", "Anch", "Djed-Pfeiler", "Isisknoten", "Herzskarabäus", "Schen-Schleife"]},
	"ring": {"name": "Ring", "arm": 0.0, "bases": ["Fayencering", "Siegelring", "Kartuschenring", "Skarabäusring", "Uräus-Ring", "Schen-Ring"]},
}

# Sachmet: Zorn · Chnum formt den Leib · Bes schützt · Horus: Falkenauge · Seth: Gewalt · Schu: Wind · Month: Kampf
# Thot: Klarheit · Isis: Heilung · Selket: Skorpion · Seschat: Lernen · Renenutet: Ernteglück
const AFF_ORDER := ["dmgPct", "hp", "armor", "crit", "critDmg", "speed", "as", "regen", "loh", "thorns", "xp", "find"]
const AFF := {
	"dmgPct": {"name": "Schaden", "unit": " %", "w": 1.2, "suf": "der Sachmet"},
	"hp": {"name": "Leben", "unit": "", "w": 0.12, "suf": "des Chnum"},
	"armor": {"name": "Rüstung", "unit": "", "w": 0.35, "suf": "des Bes"},
	"crit": {"name": "Kritische Trefferchance", "unit": " %", "w": 2.2, "suf": "des Horus"},
	"critDmg": {"name": "Kritischer Schaden", "unit": " %", "w": 0.45, "suf": "des Seth"},
	"speed": {"name": "Lauftempo", "unit": " %", "w": 1.0, "suf": "des Schu"},
	"as": {"name": "Angriffstempo", "unit": " %", "w": 1.3, "suf": "des Month"},
	"regen": {"name": "Kraft pro Sekunde", "unit": "", "w": 1.5, "suf": "des Thot"},
	"loh": {"name": "Leben pro Treffer", "unit": "", "w": 0.8, "suf": "der Isis"},
	"thorns": {"name": "Dornen (Schaden an Angreifern)", "unit": "", "w": 0.25, "suf": "der Selket"},
	"xp": {"name": "Erfahrung", "unit": " %", "w": 0.6, "suf": "der Seschat"},
	"find": {"name": "Beuteglück", "unit": " %", "w": 0.5, "suf": "der Renenutet"},
}

static func aff_wert(k: String, l: int) -> int:
	match k:
		"dmgPct": return randi_range(5 + l, 9 + l * 2)
		"hp": return randi_range(10 + l * 6, 20 + l * 10)
		"armor": return randi_range(4 + l * 2, 8 + l * 4)
		"crit": return randi_range(2, 5)
		"critDmg": return randi_range(10, 22) + l
		"speed": return randi_range(3, 7)
		"as": return randi_range(3, 8)
		"regen": return randi_range(1, 3)
		"loh": return randi_range(1 + l, 2 + l * 2)
		"thorns": return randi_range(4 + l * 3, 8 + l * 5)
		"xp": return randi_range(4, 10)
		"find": return randi_range(5, 14)
	return 0

const RARE_NAMES := ["Nachtfahrt", "Zweiter Tod", "Wahr an Stimme", "Millionen Jahre", "Feuersee", "Binsengefilde", "Herz auf der Waage", "Westwind", "Erstes Mal", "Rosetau"]

# Legendäre Kräfte: zwei je Ausrüstungsplatz. „sun“ fällt nur beim König ohne Namen.
const LEGS := [
	{"id": "critres", "slot": "waffe", "name": "Harpune des Horus", "txt": "Mit ihr traf er Seth. Jeder kritische Treffer gibt dir 5 deiner Kraft zurück."},
	{"id": "sun", "slot": "waffe", "quest": true, "name": "Sonnenrichter", "txt": "Zweihänder aus dem Gold der Tagesbarke. 60 % mehr Schaden gegen Ruhelose und Herzlose."},
	{"id": "lantern", "slot": "nebenhand", "name": "Lampe der Maat", "txt": "Im Licht der Wahrheit steht jeder da, wie er ist. Gegner in deinem Lichtkegel erleiden 25 % mehr Schaden."},
	{"id": "mirror", "slot": "nebenhand", "name": "Spiegel der Hathor", "txt": "Jedes vierte Geschoss, das dich träfe, fliegt zum Schützen zurück."},
	{"id": "potion", "slot": "helm", "name": "Löwenhaube der Sachmet", "txt": "Die Göttin, die Seuchen schickt, heilt sie auch. Rotbier heilt dich vollständig."},
	{"id": "sight", "slot": "helm", "name": "Maske des Anubis", "txt": "Der Balsamierer sieht im Dunkeln. Dein Lichtkegel reicht ein Drittel weiter."},
	{"id": "s4", "slot": "ruestung", "name": "Fell des Sem-Priesters", "txt": "Er öffnet den Toten den Mund. Deine vierte Fähigkeit lädt doppelt so schnell."},
	{"id": "skin", "slot": "ruestung", "name": "Haut des Mehen", "txt": "Die Schlange, die sich um Re legt. Alle 8 Sekunden prallt ein Treffer ganz an dir ab."},
	{"id": "shards", "slot": "handschuhe", "name": "Hände des Grabräubers", "txt": "Gegner lassen doppelt so viele Scherben fallen."},
	{"id": "heavy", "slot": "handschuhe", "name": "Fäuste des Namenlosen", "txt": "Jeder vierte Standardangriff trifft doppelt und betäubt kurz."},
	{"id": "s2", "slot": "stiefel", "name": "Sandalen des Upuaut", "txt": "Der Wegöffner geht voran. Deine Ausweichfähigkeit lädt doppelt so schnell."},
	{"id": "caravan", "slot": "stiefel", "name": "Sandalen des Sinuhe", "txt": "Er lief bis Retjenu und kam doch heim. 15 % mehr Lauftempo. Isisblut (rote Kugeln) heilt doppelt."},
	{"id": "s1", "slot": "amulett", "name": "Feder der Maat", "txt": "Was leicht ist, kostet wenig. Deine erste Fähigkeit kostet nur die Hälfte."},
	{"id": "star", "slot": "amulett", "name": "Splitter des Mesechtiu", "txt": "Himmelseisen aus dem Sternbild des Stierschenkels. 15 % mehr kritische Trefferchance."},
	{"id": "leech", "slot": "ring", "name": "Ring der Ammit", "txt": "Die Fresserin verschlingt, was zu schwer wiegt. Jeder besiegte Gegner heilt dich um 3 % deines Lebens."},
	{"id": "greed", "slot": "ring", "name": "Ring des Sammlers", "txt": "Scherben, Isisblut und Buchseiten fliegen dir aus großer Entfernung zu."},
]

static func leg(id: String) -> Dictionary:
	for l in LEGS:
		if l.id == id:
			return l
	return {}

# Das Buch des Thot: zwölf Seiten. Elite-Gegner und Hüter tragen sie, Seite für Seite erzählen sie, warum die Waage stillsteht.
const EVID := [
	["Die Lichter über Sandtor", "Die Lichter über Sandtor sind keine Irrlichter. Es sind die Toten der Stadt. Sie finden den Weg nicht, denn unten ruft niemand mehr ihre Namen."],
	["Die leere Schale", "In der Halle der Beiden Wahrheiten hängt die Waage still. Auf der einen Schale liegt die Feder der Maat. Auf der anderen hat lange kein Herz mehr gelegen."],
	["Von der Häutung", "Apophis wird nicht geboren, er häutet sich. Was er abstreift, steht auf und folgt ihm. So wächst seine Brut, solange die Sonne schwach ist."],
	["Der fünfte Krug", "Vier Krüge kennt der Balsamierer: für Leber, Lunge, Magen und Gedärm. Das Herz bleibt im Leib, damit es gewogen werden kann. Der Sammler hat einen fünften Krug erfunden."],
	["Vom Namen", "Was keinen Namen hat, kann Thot nicht aufrufen, und wer nicht aufgerufen wird, kommt nie vor die Waage. Darum schlagen Feinde die Namen aus dem Stein."],
	["Spruch für das Herz", "„Mein Herz meiner Mutter, steh nicht gegen mich auf.“ So beten die Toten vor der Waage. Doch ein Herz, das in einem Krug liegt, spricht weder für noch gegen sie."],
	["Der Handel des Königs", "Ein König gab dem Sammler seinen Namen. Dafür sollte sein Herz niemals gewogen werden. Seitdem liegt er wach in seinem Grab, und keiner weiß mehr, wie er hieß."],
	["Das Zugseil", "In Sokars Land fährt die Barke nicht, sie wird über den Sand gezogen. Ziehen dürfen nur die Gerechtfertigten. Ist keiner mehr gerechtfertigt, bleibt das Seil liegen."],
	["Die Unvergänglichen", "Die Sterne im Norden gehen niemals unter. Doch der Sammler nahm auch ihnen das Herz, und sie fielen erloschen in den Sand von Rosetau."],
	["Der Richter, der ging", "Zweiundvierzig Richter sitzen in der Halle, und jeder kennt eine Sünde. Einer kannte seine eigene zu gut. Er stand auf, ging hinaus und kam als der Sammler wieder."],
	["Lied der Klagefrauen", "„Sieben Stunden bis zum Morgen, und in der siebten liegt der, der das Wasser trinkt. Wer zieht die Barke, wenn keiner gerechtfertigt ist?“"],
	["Der Krug mit deinem Namen", "Tief in Sokars Höhle steht ein leerer Krug. Auf seinem Siegel steht dein Name, in sauberer Schrift. Er wartet schon lange."],
]

# Material zum Sammeln: fällt je nach Gegnerart, wird beim Aufwerten und Neuwürfeln verbraucht
const MAT_ORDER := ["staub", "leder", "eisen", "stern"]
const MATS := {
	"staub": {"name": "Fayencestaub", "col": Color("8fe3e0"), "txt": "Türkis wie die Grabbeigaben. Von fast allem, was in der Duat umgeht. Grundstoff fürs Aufwerten."},
	"leder": {"name": "Schlangenhaut", "col": Color("c9a24e"), "txt": "Von den Sebau, der Brut des Apophis. Für Rüstung ab Stufe +3."},
	"eisen": {"name": "Sethknochen", "col": Color("aab3bd"), "txt": "So nennen die Priester das Eisen. Von Ruhelosen und Herzlosen. Für Waffen und Schmuck ab Stufe +3."},
	"stern": {"name": "Himmelseisen", "col": Color("e9fffd"), "txt": "Eisen, das vom Himmel fiel. Von Erloschenen und Hütern der Stunden. Für die letzte Stufe +5."},
}

# Schwierigkeit: zähere, härtere Gegner, dafür mehr Erfahrung und mehr Legendäres.
# pack: Anteil der Rudelgröße · slots: so viele Nahkämpfer greifen gleichzeitig an · gap: Mindestabstand zwischen zwei Gegnerschüssen
const DIFF := [
	{"name": "Normal", "txt": "kleinere Rudel, höchstens zwei Gegner greifen gleichzeitig an, die übrigen warten auf Abstand; Treffer sind schwach", "hp": 0.65, "dmg": 0.5, "xp": 1.15, "leg": 1.0, "pack": 0.6, "slots": 2, "gap": 1.1, "alarm": false, "spd": 0.88, "sight": 0.85},
	{"name": "Schwer", "txt": "größere Rudel, bis zu vier Angreifer zugleich, Nachbarrudel kommen zu Hilfe, mehr Legendäres", "hp": 1.3, "dmg": 1.2, "xp": 1.3, "leg": 1.6, "pack": 0.85, "slots": 4, "gap": 0.45, "alarm": true, "spd": 1.0, "sight": 1.0},
	{"name": "Albtraum", "txt": "volle Rudel, die dich einkreisen; für eingespielte Figuren mit guter Ausrüstung", "hp": 2.5, "dmg": 2.0, "xp": 1.7, "leg": 2.4, "pack": 1.0, "slots": 6, "gap": 0.15, "alarm": true, "spd": 1.05, "sight": 1.1},
]

# Gegnerarten der 2D-Fassung (01-data.js › ET), soweit sie Werte für Leben, Schaden und Erfahrung liefern
const ET := {
	"wisp": {"name": "Irrender Ba", "hp": 22.0, "dmg": 6.0, "xp": 6.0, "w": 1.0, "drop": 0.1},
	"skorp": {"name": "Tefens Brut", "hp": 32.0, "dmg": 8.0, "xp": 8.0, "w": 1.2, "drop": 0.12},
	"lance": {"name": "Sebau-Krieger", "hp": 62.0, "dmg": 13.0, "xp": 14.0, "w": 2.0, "drop": 0.2},
	"seer": {"name": "Sebau-Priesterin", "hp": 38.0, "dmg": 10.0, "xp": 12.0, "w": 1.6, "drop": 0.18},
	"haut": {"name": "Sebau-Koloss", "hp": 170.0, "dmg": 26.0, "xp": 32.0, "w": 4.0, "drop": 0.45},
	"guard": {"name": "Ruheloser", "hp": 82.0, "dmg": 15.0, "xp": 16.0, "w": 2.2, "drop": 0.22},
	"fahl": {"name": "Erloschener", "hp": 44.0, "dmg": 12.0, "xp": 14.0, "w": 1.8, "drop": 0.2},
	"hohl": {"name": "Herzloser", "hp": 70.0, "dmg": 16.0, "xp": 16.0, "w": 2.2, "drop": 0.22},
	"boss": {"name": "Hüter", "hp": 1500.0, "dmg": 20.0, "xp": 300.0, "w": 0.0, "drop": 1.0},
}
const ELITE := [{"id": "flink", "name": "flink"}, {"id": "zaeh", "name": "zäh"}, {"id": "wild", "name": "rasend"}]

const POTS := 4
const UP_MAX := 5
const BAG_MAX := 32
const GAMBLE := 25
const REROLL_STAUB := 4
const REROLL_SHARDS := 8

# Symbole aus dem Bildbogen (6 x 6 Felder): welche Felder zu welchem Platz gehören
const ICON_N := 6
const ICON := {"waffe": [0, 1, 2, 3, 4, 5], "nebenhand": [6, 7], "helm": [8, 9, 10, 11], "ruestung": [12, 13, 14, 15], "handschuhe": [16, 17], "stiefel": [18, 19, 20], "amulett": [21, 22, 23], "ring": [24, 25, 26],
	"potion": 29, "staub": 30, "leder": 31, "eisen": 32, "stern": 33, "shard": 34, "evid": 35}
# Symbol passend zum Namen (Beil zeigt ein Beil, Maske eine Maske); nur wo nichts passt, entscheidet der Zufall des Teils
const ICON_BY_NAME := [["beil|axt", 1], ["bogen", 2], ["stab|zepter|keule", 3], ["wickel|faust|binden", 4], ["dolch|messer", 5], ["klinge|schwert|säbel|speer|richter|dreigestirn|chepesch|harpune", 0],
	["laterne|lampe|räucher", 6], ["schild|spiegel|mappe|sandglas|sistrum|palette", 7], ["maske", 11], ["geier|löwe", 10], ["helm|chepresch", 9], ["haube|kapuze|turban|hut|reif|nemes|kappe|stirnband", 8],
	["robe|burnus|mantel|rock|schurz|gewand", 12], ["wams|haut|fell|koller", 13], ["kettenhemd|schuppenpanzer", 14], ["pektoral", 15], ["handschuh|leinenbinden|hände", 16], ["fäustling|fäuste|armschiene", 17], ["sandal", 18], ["stiefel|läufer|schuh", 19], ["beinschiene", 20],
	["sonne|anch|skarabäus|isisknoten", 22], ["glas|splitter|stern|djed|feder|schleife", 23], ["marke|auge|talisman|siegelstein|sternkarte", 21], ["siegelring|mondring|kartusche|skarabäusring", 25], ["schlange|uräus", 26], ["fayence|schen", 24]]

static var _icon_tex: Texture2D
static var _icon_cache := {}

static func icon(i: int) -> AtlasTexture:
	if _icon_cache.has(i):
		return _icon_cache[i]
	if _icon_tex == null:
		_icon_tex = load("res://ui/icons.webp")
	var a := AtlasTexture.new()
	a.atlas = _icon_tex
	var s := _icon_tex.get_width() / float(ICON_N)
	a.region = Rect2((i % ICON_N) * s, (i / ICON_N) * s, s, s)
	_icon_cache[i] = a
	return a

static func icon_of(it: Dictionary) -> int:
	var a: Array = ICON[it.slot]
	var low := String(it.name).to_lower()
	for p in ICON_BY_NAME:
		var re := RegEx.create_from_string(p[0])
		if re.search(low) and a.has(p[1]):
			return p[1]
	return a[int(it.get("ic", it.id)) % a.size()]

static func xp_need(l: int) -> int:
	return int(round(60.0 * pow(l, 1.6)))

# Aufwerten: Kosten der nächsten Stufe und Wirkung
static func up_cost(it: Dictionary) -> Dictionary:
	var u := int(it.get("up", 0))
	var c := {"staub": 3 * (u + 1)}
	if u >= 2:
		c["leder" if SLOT[it.slot].arm > 0.0 else "eisen"] = u - 1
	if u >= 4:
		c["stern"] = 1
	return c

static func up_mul(it: Dictionary) -> float:
	return 1.0 + 0.12 * int(it.get("up", 0))

static func it_dmg(it: Dictionary) -> int:
	return int(round(float(it.get("dmg", 0)) * up_mul(it)))

static func it_arm(it: Dictionary) -> int:
	return int(round(float(it.get("armor", 0)) * up_mul(it)))

static func it_aff(it: Dictionary, k: String) -> int:
	return int(round(float(it.aff[k]) * (1.0 + 0.06 * int(it.get("up", 0)))))

static func item_name(it: Dictionary) -> String:
	var u := int(it.get("up", 0))
	return String(it.name) + (" +%d" % u if u > 0 else "")

static func item_score(it) -> float:
	if it == null or (it is Dictionary and it.is_empty()):
		return 0.0
	var s := it_dmg(it) * 1.5 + it_arm(it) * 0.35
	for k in it.aff:
		s += it_aff(it, k) * AFF[k].w
	if it.has("leg"):
		s += 15.0 + int(it.ilvl) * 2.0
	return s

# Ein neuer Gegenstand. leg_roll: Faktor der Schwierigkeit für Legendäres; force: {"slot": …, "leg": …}
static func make_item(id: int, ilvl: int, min_rar: int, leg_roll: float, force := {}) -> Dictionary:
	var roll := randf() / leg_roll
	var rar := maxi(min_rar, 3 if roll < 0.045 else (2 if roll < 0.16 else (1 if roll < 0.5 else 0)))
	var R: Dictionary = RAR[rar]
	var slot: String = force.get("slot", SLOTS.pick_random())
	var it := {"id": id, "slot": slot, "rar": rar, "ilvl": ilvl, "aff": {}, "ic": 0 if force.get("leg", "") == "sun" else randi_range(0, 59), "up": 0}
	if slot == "waffe":
		it["dmg"] = int(round((5.0 + ilvl * 3.2) * R.mult * randf_range(0.88, 1.12)))
	if SLOT[slot].arm > 0.0:
		it["armor"] = int(round((8.0 + ilvl * 5.0) * SLOT[slot].arm * R.mult * randf_range(0.88, 1.12)))
	var keys := AFF_ORDER.duplicate()
	keys.shuffle()
	keys = keys.slice(0, randi_range(R.aff[0], R.aff[1]))
	for k in keys:
		it.aff[k] = aff_wert(k, ilvl)
	var base: String = SLOT[slot].bases.pick_random()
	if rar == 3:
		var L: Dictionary
		if force.has("leg"):
			L = leg(force.leg)
		else:
			L = LEGS.filter(func(l): return l.slot == slot and not l.get("quest", false)).pick_random()
		it["leg"] = L.id
		it["name"] = L.name
	elif rar == 2:
		it["name"] = "%s „%s“" % [base, RARE_NAMES.pick_random()]
	elif rar == 1:
		it["name"] = "%s %s" % [base, AFF[keys[0]].suf]
	else:
		it["name"] = base
	return it

# Ein gespeicherter Gegenstand: Zahlen kommen aus JSON als Kommazahlen zurück, unbekannte Teile werden verworfen
static func clean_item(v) -> Dictionary:
	if not (v is Dictionary) or not SLOT.has(v.get("slot", "")) or not v.has("name"):
		return {}
	var it := {"id": int(v.get("id", 0)), "slot": v.slot, "rar": clampi(int(v.get("rar", 0)), 0, 3), "ilvl": maxi(1, int(v.get("ilvl", 1))),
		"aff": {}, "ic": int(v.get("ic", 0)), "up": clampi(int(v.get("up", 0)), 0, UP_MAX), "name": String(v.name)}
	if v.has("dmg"):
		it["dmg"] = int(v.dmg)
	if v.has("armor"):
		it["armor"] = int(v.armor)
	if v.get("aff") is Dictionary:
		for k in v.aff:
			if AFF.has(k):
				it.aff[k] = int(v.aff[k])
	if v.has("leg") and not leg(String(v.leg)).is_empty():
		it["leg"] = String(v.leg)
		it["name"] = leg(it.leg).name
	return it

# Zeilen, die einen Gegenstand beschreiben (für Tasche, Truhe und Meldungen)
static func aff_line(it: Dictionary, k: String) -> String:
	return "+%d%s %s" % [it_aff(it, k), AFF[k].unit, AFF[k].name]
