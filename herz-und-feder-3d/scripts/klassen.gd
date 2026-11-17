class_name Klassen
# Die vier Klassen und ihre Fähigkeiten (01-data.js › CLS, SK, SK_TXT, PASSIVES, KEYSTONE, AUGS).
# Für die 3D-Fassung kommen Modell, sichtbare Waffe, Animationen und Porträt dazu. Die Fähigkeiten „udjat“ und „beam“
# heißen in der 2D-Fassung „pulse“ und „bolt“; die Namen der 3D-Probe bleiben, damit Tests und Spielstände passen.

const ORDER := ["ermittler", "moench", "jaegerin", "forensiker"]
const CLS := {
	"ermittler": {"name": "Eidträger", "like": "Nahkampf mit dem Zweihänder", "txt": "Hat auf die Feder der Maat geschworen. Hält viel aus und steht mitten im Getümmel.",
		"col": Color("e8b04a"), "res": "Eidkraft", "rc": Color("3f7fd6"), "basic": "melee", "range": 3.3,
		"sk": ["whirl", "dash", "oath", "udjat"], "rmb": "beam", "hp": 1.2, "red": 0.15, "spd": 1.0, "regen": 4.0,
		"model": "Knight", "neu": "Eidtraeger", "neu_tuch": "Eidtraeger_Nemes", "keep": ["2H_Sword"], "art": ["K01", Rect2(0, 3, 182, 411)],
		"anim": {"idle": "2H_Melee_Idle", "run": "Running_A", "atk_a": "2H_Melee_Attack_Slice", "atk_b": "2H_Melee_Attack_Chop",
			"whirl": "2H_Melee_Attack_Spin", "dash": "Dodge_Forward", "oath": "Cheer", "udjat": "Spellcast_Raise",
			"beam": "Spellcast_Shoot", "potion": "Use_Item", "hit": "Hit_A", "death": "Death_A"}},
	"moench": {"name": "Priester des Schu", "like": "Fäuste, Schlagfolgen, Kreise", "txt": "Kämpft mit bloßen Händen und dem Atem des Luftgottes. Jeder dritte Schlag trifft doppelt so weit und härter.",
		"col": Color("efe6cf"), "res": "Atem", "rc": Color("d9a04a"), "basic": "combo", "range": 2.6,
		"sk": ["flurry", "step", "mantra", "palm"], "rmb": "wave", "hp": 1.05, "red": 0.1, "spd": 1.1, "regen": 5.0,
		"model": "Barbarian", "keep": [], "art": ["K02", Rect2(0, 0, 136, 398)],
		"anim": {"idle": "Unarmed_Idle", "run": "Running_A", "atk_a": "Unarmed_Melee_Attack_Punch_A", "atk_b": "Unarmed_Melee_Attack_Punch_B", "atk_c": "Unarmed_Melee_Attack_Kick",
			"flurry": "Unarmed_Melee_Attack_Punch_A", "step": "Dodge_Forward", "mantra": "Spellcast_Raise", "palm": "Unarmed_Melee_Attack_Punch_B",
			"wave": "Spellcast_Shoot", "potion": "Use_Item", "hit": "Hit_A", "death": "Death_A"}},
	"jaegerin": {"name": "Wüstenjägerin", "like": "Bogen und ein Wüstenfuchs", "txt": "Schülerin der Neith. Schießt aus der Ferne. Ihr Fuchs, der Wegöffner, kämpft mit und verjagt feindliche Tiere.",
		"col": Color("7ad08a"), "res": "Instinkt", "rc": Color("3fa86a"), "basic": "shot", "range": 16.0, "pet": true,
		"sk": ["salve", "roll", "hetz", "rain"], "rmb": "pierce", "hp": 0.9, "red": 0.0, "spd": 1.08, "regen": 5.0,
		"model": "Rogue", "keep": ["2H_Crossbow"], "art": ["K03", Rect2(0, 8, 263, 401)],
		"anim": {"idle": "2H_Ranged_Aiming", "run": "Running_A", "atk_a": "2H_Ranged_Shoot", "atk_b": "2H_Ranged_Shoot",
			"salve": "2H_Ranged_Shooting", "roll": "Dodge_Forward", "hetz": "Interact", "rain": "2H_Ranged_Shoot",
			"pierce": "2H_Ranged_Shoot", "potion": "Use_Item", "hit": "Hit_A", "death": "Death_A"}},
	"forensiker": {"name": "Sternleserin", "like": "Heka: Magie aus Wort und Stern", "txt": "Schreiberin der Seschat. Empfindlich, aber sie bestimmt, wo gekämpft wird: Sturm, Maß und fallende Sterne.",
		"col": Color("c06be0"), "res": "Heka", "rc": Color("9a5fe0"), "basic": "spark", "range": 14.4,
		"sk": ["chain", "blink", "glass", "nova"], "rmb": "meteor", "hp": 0.82, "red": 0.0, "spd": 1.0, "regen": 8.0,
		"model": "Mage", "keep": ["2H_Staff"], "art": ["K04", Rect2(0, 18, 243, 407)],
		"anim": {"idle": "Idle", "run": "Running_A", "atk_a": "Spellcast_Shoot", "atk_b": "Spellcast_Shoot",
			"chain": "Spellcast_Shoot", "blink": "Spellcast_Raise", "glass": "Spellcast_Long", "nova": "Spellcast_Raise",
			"meteor": "Spellcast_Long", "potion": "Use_Item", "hit": "Hit_A", "death": "Death_A"}},
}
# alles, was ein Modell sonst noch in den Händen hält: wird versteckt, sofern es nicht in „keep“ steht
const WEAPONS := ["1H_Sword", "1H_Sword_Offhand", "2H_Sword", "Badge_Shield", "Rectangle_Shield", "Round_Shield", "Spike_Shield",
	"1H_Axe", "1H_Axe_Offhand", "2H_Axe", "Barbarian_Round_Shield", "Mug", "Barbarian_Hat", "Spellbook", "Spellbook_open", "1H_Wand", "2H_Staff",
	"Knife", "Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Throwable"]

const SK := {
	"whirl": {"name": "Falkenkreis", "cost": 25.0, "cd": 0.5, "util": false, "txt": "Rundumschlag um dich herum. Der Falke kreist, bevor er stößt.",
		"ic": "<circle cx=\"28\" cy=\"28\" r=\"15\" fill=\"none\" stroke=\"#e8b04a\" stroke-width=\"4\" stroke-dasharray=\"60 34\"/><path d=\"M41 15l5-9 3 10z\" fill=\"#e8b04a\"/>"},
	"dash": {"name": "Sturz des Falken", "cost": 0.0, "cd": 5.0, "util": false, "txt": "Sprung zum Ziel mit Aufprall.",
		"ic": "<path d=\"M10 40L30 20M22 44L42 24\" stroke=\"#8fe3e0\" stroke-width=\"4\" stroke-linecap=\"round\"/><circle cx=\"42\" cy=\"15\" r=\"6\" fill=\"#8fe3e0\"/>"},
	"oath": {"name": "Eid der Maat", "cost": 0.0, "cd": 18.0, "util": true, "txt": "Du schwörst auf die Feder: 6 Sekunden lang 30 % mehr Schaden, 20 % weniger erlittener Schaden.",
		"ic": "<path d=\"M28 8l16 6v12c0 10-7 17-16 21-9-4-16-11-16-21V14z\" fill=\"none\" stroke=\"#e8b04a\" stroke-width=\"4\"/><path d=\"M28 18v16M20 26h16\" stroke=\"#e8b04a\" stroke-width=\"4\" stroke-linecap=\"round\"/>"},
	"udjat": {"name": "Blick des Udjat", "cost": 0.0, "cd": 14.0, "util": false, "txt": "Das heile Auge des Horus öffnet sich. Betäubt alles im Umkreis und löscht Geschosse.",
		"ic": "<circle cx=\"28\" cy=\"28\" r=\"6\" fill=\"#c06be0\"/><circle cx=\"28\" cy=\"28\" r=\"13\" fill=\"none\" stroke=\"#c06be0\" stroke-width=\"3\"/><circle cx=\"28\" cy=\"28\" r=\"21\" fill=\"none\" stroke=\"#c06be0\" stroke-width=\"2\" opacity=\".6\"/>"},
	"beam": {"name": "Strahl des Re", "cost": 14.0, "cd": 0.35, "util": false, "txt": "Licht aus der Laterne, das mehrere Gegner durchschlägt.",
		"ic": "<path d=\"M10 28H38\" stroke=\"#ffe9a8\" stroke-width=\"5\" stroke-linecap=\"round\"/><path d=\"M36 18l12 10-12 10z\" fill=\"#ffe9a8\"/>"},
	"salve": {"name": "Neiths Fächer", "cost": 22.0, "cd": 0.4, "util": false, "txt": "Fünf Pfeile im Fächer.",
		"ic": "<path d=\"M10 28L44 12M10 28H46M10 28L44 44\" stroke=\"#7ad08a\" stroke-width=\"4\" stroke-linecap=\"round\"/>"},
	"roll": {"name": "Sprung der Gazelle", "cost": 0.0, "cd": 4.0, "util": true, "txt": "Sprung aus der Gefahr.",
		"ic": "<path d=\"M12 38a16 16 0 1 1 26 4\" fill=\"none\" stroke=\"#7ad08a\" stroke-width=\"4\" stroke-linecap=\"round\"/><path d=\"M44 36l-4 12-9-8z\" fill=\"#7ad08a\"/>"},
	"hetz": {"name": "Upuauts Hatz", "cost": 0.0, "cd": 9.0, "util": false, "txt": "Dein Fuchs springt das Ziel an und beißt 5 Sekunden lang schneller. Feindliche Tiere in der Nähe fliehen.",
		"ic": "<circle cx=\"28\" cy=\"35\" r=\"9\" fill=\"#7ad08a\"/><circle cx=\"13\" cy=\"25\" r=\"5\" fill=\"#7ad08a\"/><circle cx=\"23\" cy=\"15\" r=\"5\" fill=\"#7ad08a\"/><circle cx=\"35\" cy=\"15\" r=\"5\" fill=\"#7ad08a\"/><circle cx=\"44\" cy=\"25\" r=\"5\" fill=\"#7ad08a\"/>"},
	"rain": {"name": "Sieben Pfeile der Sachmet", "cost": 0.0, "cd": 12.0, "util": false, "txt": "Sachmets Pfeile regnen auf eine Fläche.",
		"ic": "<circle cx=\"28\" cy=\"36\" r=\"15\" fill=\"none\" stroke=\"#7ad08a\" stroke-width=\"3\"/><path d=\"M18 8v18M28 6v22M38 8v18\" stroke=\"#d8ffd8\" stroke-width=\"3\" stroke-linecap=\"round\"/>"},
	"pierce": {"name": "Pfeil der Neith", "cost": 18.0, "cd": 0.5, "util": false, "txt": "Ein Pfeil durch die ganze Reihe.",
		"ic": "<path d=\"M6 28H42\" stroke=\"#d8ffd8\" stroke-width=\"6\" stroke-linecap=\"round\"/><path d=\"M38 16l14 12-14 12z\" fill=\"#d8ffd8\"/><path d=\"M6 20l8 8-8 8\" fill=\"none\" stroke=\"#7ad08a\" stroke-width=\"3\"/>"},
	"chain": {"name": "Zorn des Seth", "cost": 16.0, "cd": 0.35, "util": false, "txt": "Seths Gewitter springt von Gegner zu Gegner.",
		"ic": "<path d=\"M8 14l14 12-8 4 16 10-6 4 20 6\" fill=\"none\" stroke=\"#e2b8ff\" stroke-width=\"4\" stroke-linejoin=\"round\" stroke-linecap=\"round\"/>"},
	"blink": {"name": "Schritt durch die Duat", "cost": 0.0, "cd": 4.0, "util": true, "txt": "Ein Schritt durch die Unterwelt versetzt dich ein Stück weit.",
		"ic": "<circle cx=\"14\" cy=\"40\" r=\"6\" fill=\"none\" stroke=\"#c06be0\" stroke-width=\"3\" stroke-dasharray=\"4 4\"/><circle cx=\"40\" cy=\"16\" r=\"8\" fill=\"#c06be0\"/><path d=\"M20 34l12-12\" stroke=\"#c06be0\" stroke-width=\"3\" stroke-dasharray=\"3 5\" stroke-linecap=\"round\"/>"},
	"glass": {"name": "Seschats Maß", "cost": 20.0, "cd": 8.0, "util": true, "txt": "Seschat misst die Zeit, und hier misst sie knapp: ein Feld, in dem Gegner nur noch kriechen.",
		"ic": "<path d=\"M16 8h24M16 48h24M19 8c0 12 18 12 18 20s-18 8-18 20M37 8c0 12-18 12-18 20s18 8 18 20\" fill=\"none\" stroke=\"#8fe3e0\" stroke-width=\"3\" stroke-linecap=\"round\"/>"},
	"nova": {"name": "Hu, das Machtwort", "cost": 0.0, "cd": 10.0, "util": false, "txt": "Ein gesprochenes Wort, das gilt. Der Ring betäubt lange.",
		"ic": "<circle cx=\"28\" cy=\"28\" r=\"6\" fill=\"#8fe3e0\"/><path d=\"M28 6v10M28 40v10M6 28h10M40 28h10M12 12l7 7M37 37l7 7M44 12l-7 7M19 37l-7 7\" stroke=\"#8fe3e0\" stroke-width=\"3\" stroke-linecap=\"round\"/>"},
	"meteor": {"name": "Fallender Stern der Nut", "cost": 35.0, "cd": 1.0, "util": false, "txt": "Ein Stern löst sich vom Leib der Nut. Trifft spät und hart.",
		"ic": "<path d=\"M42 6L24 30\" stroke=\"#ffd75e\" stroke-width=\"6\" stroke-linecap=\"round\"/><circle cx=\"22\" cy=\"34\" r=\"9\" fill=\"#ffd75e\"/><ellipse cx=\"24\" cy=\"48\" rx=\"16\" ry=\"4\" fill=\"none\" stroke=\"#ffd75e\" stroke-width=\"2\"/>"},
	"flurry": {"name": "Fäuste des Month", "cost": 24.0, "cd": 0.8, "util": false, "txt": "Fünf schnelle Schläge nach vorn.",
		"ic": "<path d=\"M8 18h20M8 28h28M8 38h20\" stroke=\"#efe6cf\" stroke-width=\"5\" stroke-linecap=\"round\"/><circle cx=\"38\" cy=\"18\" r=\"5\" fill=\"#efe6cf\"/><circle cx=\"46\" cy=\"28\" r=\"5\" fill=\"#efe6cf\"/><circle cx=\"38\" cy=\"38\" r=\"5\" fill=\"#efe6cf\"/>"},
	"step": {"name": "Schritt des Schu", "cost": 0.0, "cd": 4.5, "util": false, "txt": "Schritt durch die Gegner mit Treffer.",
		"ic": "<path d=\"M8 36q14-14 28-8M14 46q14-12 26-6\" fill=\"none\" stroke=\"#efe6cf\" stroke-width=\"4\" stroke-linecap=\"round\"/><circle cx=\"42\" cy=\"16\" r=\"6\" fill=\"#efe6cf\"/>"},
	"mantra": {"name": "Kreis des Ka", "cost": 0.0, "cd": 16.0, "util": true, "txt": "Kreis für 7 Sekunden: Deine Lebenskraft heilt dich, Gegner darin treffen schwächer.",
		"ic": "<circle cx=\"28\" cy=\"28\" r=\"21\" fill=\"none\" stroke=\"#efe6cf\" stroke-width=\"2\" stroke-dasharray=\"3 5\"/><circle cx=\"28\" cy=\"28\" r=\"12\" fill=\"none\" stroke=\"#efe6cf\" stroke-width=\"3\"/><circle cx=\"28\" cy=\"28\" r=\"4\" fill=\"#efe6cf\"/>"},
	"palm": {"name": "Gebs Lachen", "cost": 0.0, "cd": 12.0, "util": false, "txt": "Wenn Geb lacht, bebt die Erde. Getroffene zerbersten, wenn sie fallen, und reißen Nachbarn mit.",
		"ic": "<path d=\"M16 48V24l6-2V10h5v12h3V8h5v14h3V12h5v20c0 8-5 16-13 16z\" fill=\"#efe6cf\"/>"},
	"wave": {"name": "Atem des Schu", "cost": 18.0, "cd": 0.6, "util": false, "txt": "Ein Atemstoß, der alles zurückwirft.",
		"ic": "<path d=\"M12 12q16 16 0 32M24 10q20 18 0 36M36 8q24 20 0 40\" fill=\"none\" stroke=\"#efe6cf\" stroke-width=\"4\" stroke-linecap=\"round\"/>"},
	"potion": {"name": "Rotbier der Sachmet", "cost": 0.0, "cd": 1.0, "util": false, "txt": "Heilt dich: 60 % deines Lebens.",
		"ic": "<path d=\"M23 10h10v9l8 14a9 9 0 0 1-8 13H23a9 9 0 0 1-8-13l8-14z\" fill=\"#c8443a\" stroke=\"#e6dfc8\" stroke-width=\"2\"/>"},
}

const SK_RANKS := 5
const AUGS := {"wucht": {"name": "Wucht", "txt": "25 % mehr Wirkung"}, "eile": {"name": "Eile", "txt": "25 % schneller bereit, 25 % günstiger"}}
const PASSIVES := [
	{"id": "zaeh", "name": "Starker Ka", "txt": "Der Ka ist die Lebenskraft. 6 % mehr Leben je Rang"},
	{"id": "scharf", "name": "Auge des Horus", "txt": "2 % mehr kritische Trefferchance je Rang"},
	{"id": "flink", "name": "Flügel des Ba", "txt": "Der Ba fliegt, wohin er will. 3 % mehr Lauftempo je Rang"},
	{"id": "kraft", "name": "Fülle des Hapi", "txt": "Wie die Nilflut: 1 Kraft pro Sekunde mehr je Rang"},
	{"id": "hieb", "name": "Hand des Month", "txt": "8 % mehr Schaden des Standardangriffs je Rang"},
	{"id": "jaeger", "name": "Speer des Seth", "txt": "Seth steht am Bug und sticht nach der Schlange. 8 % mehr Schaden gegen Elite und Hüter der Stunden je Rang"},
]
const KEYSTONE := {
	"ermittler": {"name": "Wahr an Stimme", "txt": "Wer gerechtfertigt ist, fällt nicht leicht. Unter 35 % Leben erleidest du 30 % weniger Schaden."},
	"moench": {"name": "Hauch des Schu", "txt": "Der dritte Schlag jeder Folge gibt 10 Atem zurück und heilt 2 % deines Lebens."},
	"jaegerin": {"name": "Upuauts Rudel", "txt": "Dein Fuchs beißt doppelt so hart und ein Drittel schneller."},
	"forensiker": {"name": "Wort des Thot", "txt": "Jede fünfte Fähigkeit kostet nichts und wirkt um die Hälfte stärker."},
}
const KEY_NEED := 8

# Reihenfolge der Leiste: Tasten 1–4, rechte Maustaste, Rotbier
static func order(cls: String) -> Array:
	var C: Dictionary = CLS[cls]
	return C.sk + [C.rmb, "potion"]

# Ab welcher Stufe eine Fähigkeit zur Verfügung steht (Reihenfolge der Leiste: Tasten 1 bis 4, rechte Maustaste).
# Die Figur beginnt mit zwei Fähigkeiten und lernt die übrigen in den ersten Stunden dazu.
const UNLOCK := [1, 2, 3, 5, 1]

static func unlock_lvl(cls: String, id: String) -> int:
	var i: int = order(cls).find(id)
	return UNLOCK[i] if i >= 0 and i < UNLOCK.size() else 1

static func keys() -> Array:
	return ["1", "2", "3", "4", "RM", "Q"]

static var _ic_cache := {}

# Symbol einer Fähigkeit: das SVG aus der 2D-Fassung, gerendert
static func icon(id: String, px := 64) -> Texture2D:
	var k := "%s_%d" % [id, px]
	if _ic_cache.has(k):
		return _ic_cache[k]
	var img := Image.new()
	var svg := Glyphen.svg(id, Glyphen.cls_of(id))   # goldene Hieroglyphe auf der Steintafel der Klasse
	img.load_svg_from_string(svg, px / 56.0)
	var t := ImageTexture.create_from_image(img)
	_ic_cache[k] = t
	return t

static var _portrait := {}

static func portrait(cls: String) -> Texture2D:
	if _portrait.has(cls):
		return _portrait[cls]
	# Porträts aus Higgsfield (F11–F14); fehlt eins, der Ausschnitt aus der Figur der 2D-Fassung
	var path := "res://ui/portrait_%s.jpg" % cls
	if ResourceLoader.exists(path):
		_portrait[cls] = load(path)
		return _portrait[cls]
	var a := AtlasTexture.new()
	a.atlas = load("res://ui/%s.webp" % CLS[cls].art[0])
	a.region = CLS[cls].art[1]
	_portrait[cls] = a
	return a
