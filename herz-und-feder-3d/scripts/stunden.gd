class_name Stunden
# Die zwölf Stunden der Nacht (01-data.js › ACT, OPEN, caseDef, hourOf, nightOf, caseNo). Die ersten fünf erzählen die
# Geschichte, sechs bis zwölf bringen die Barke bis zum Morgen; danach beginnt die nächste Nacht (n = 13, 14, …),
# die Gegner werden über n weiter stärker.

const HOURS := 12
const ORD := ["Erste", "Zweite", "Dritte", "Vierte", "Fünfte", "Sechste", "Siebte", "Achte", "Neunte", "Zehnte", "Elfte", "Zwölfte"]

const ACT := [
	{"name": "Das Tor des Westens", "legs": ["lantern", "sight"], "lead": "Über Sandtor ziehen Lichter gegen den Wind. Es sind Seelen, und niemand holt sie ab.", "tex": "T01", "mix": [["rock", 7], ["needle", 3]], "mote": "#bcd0e8", "mood": "dust", "brief": "Zwölf Stunden bis zum Morgen. Nebet glüht vor Fieber, und der Priester sagt, es bricht im Morgengrauen, wenn eines kommt. Folge den Lichtern hinab. Halt die Laterne hoch: Was Isfet ist, weicht vor ihr zurück oder greift sie an.", "epi": "Mahafs Licht liegt jetzt in deiner Laterne, und es weist nach unten. Was er zuletzt gesagt hat, will dir nicht aus dem Kopf.", "vo2": ["epi"], "pal": {"ground": "#5a5547", "dune": "#6d6756", "rock": "#6f6657", "rockL": "#91876f"}, "packs": ["wisp*6", "skorp*4 wisp*2", "lance*2 wisp*3", "skorp*5", "lance*3", "wisp*8"], "boss": {"name": "Mahaf, das Leitlicht", "look": "wisp", "col": "#8fe3e0", "r": 30, "hp": 0.7, "say": "Der Fährmann, der hinter sich schaut. Er hat seine Fähre verloren und setzt trotzdem über.", "beiname": "Fährmann ohne Fähre", "bild": "h01"}},
	{"name": "Die Felder von Wernes", "dungeon": "ruin", "legs": ["skin", "shards"], "lead": "Wo die Gerechtfertigten Korn schnitten, häutet sich die Brut des Apophis. Jede Haut macht sie größer.", "tex": "T03", "mix": [["rock", 4], ["needle", 5], ["ruin", 1]], "mote": "#d8c9a0", "mood": "dust", "brief": "Noch elf Stunden. Mahafs Licht führt in die Felder der Seligen. Die Sebau fürchten keine Waage, denn sie haben kein Herz. Jemand hat ihnen das Feldtor geöffnet, von innen.", "epi": "Im Sand liegt der Abdruck eines Königsrings, der Name herausgekratzt. Der Ring führt eine Stunde tiefer, zu einem König, der nicht mehr weiß, wie er heißt. Ein General ist schon unterwegs dorthin.", "vo2": ["epi"], "pal": {"ground": "#4d5450", "dune": "#5f6964", "rock": "#5f6661", "rockL": "#7f8a83"}, "packs": ["lance*3 seer", "seer*2 lance*2", "haut skorp*3", "lance*4", "haut seer*2", "skorp*6"], "boss": {"name": "Die Mutter der Häute", "look": "mutter", "col": "#c9a24e", "r": 46, "hp": 0.9, "say": "Sie hat schon viele Häute getragen. Diese ist ihre zwölfte.", "beiname": "Brut des Apophis", "bild": "h02"}},
	{"name": "Der König ohne Namen", "dungeon": "tomb", "legs": ["heavy", "potion"], "lead": "Am Wasser des Osiris liegt ein König, dessen Name aus jeder Wand geschlagen ist. Er hält ein Schwert aus dem Gold der Tagesbarke.", "tex": "T04", "mix": [["ruin", 5], ["tomb", 5], ["rock", 1]], "mote": "#ffb060", "mood": "ember", "brief": "Noch zehn Stunden. Wer keinen Namen hat, den kann Thot nicht aufrufen, und wer nicht aufgerufen wird, kommt nie vor die Waage. Hier liegt der König, dessen Ring das Feldtor geöffnet hat.", "epi": "Er hat Namen und Ring verkauft, an einen Richter, der dabei weinte. Im Sarkophag stand, was der Käufer zurückließ: ein Krug, leer und warm. Er liegt jetzt in deiner Tasche. Auf dem Siegel steht Nebet.", "vo2": ["epi"], "pal": {"ground": "#47423f", "dune": "#57514c", "rock": "#5d564f", "rockL": "#7b7268"}, "packs": ["guard*3", "guard*2 wisp*3", "hohl*2 wisp*3", "guard*4", "wisp*8", "haut guard*2"], "boss": {"name": "Der König ohne Namen", "look": "koenig", "col": "#d8b04a", "r": 40, "hp": 1, "say": "Frag ihn nicht, wie er heißt. Er weiß es nicht mehr.", "undead": true, "beiname": "der seinen Namen verkaufte", "bild": "h03"}},
	{"name": "Rosetau", "dungeon": "glass", "legs": ["mirror", "star"], "lead": "Sokars Land, „der auf seinem Sand ist“. Hier wird die Barke gezogen, nicht gerudert. Die sie zogen, stehen erloschen an den Wegen.", "tex": "T02", "mix": [["ruin", 4], ["star", 4], ["needle", 2]], "mote": "#8fe3e0", "mood": "glass", "brief": "Noch neun Stunden. Nebets Krug liegt in deiner Tasche, leer und warm. Sie lebt noch. Jemand wartet darauf, dass sich das ändert. In Rosetau gibt es kein Wasser, und seit die Sterne erloschen sind, zieht niemand die Barke über den Sand.", "epi": "Das Tor des Türhüters öffnet sich nur für Tote, und es steht offen. Dahinter führt das Zugseil der Barke in eine Höhle, straff gespannt. Aus der Tiefe schlägt es tausendfach.", "vo2": ["epi"], "pal": {"ground": "#434a52", "dune": "#535b65", "rock": "#535a63", "rockL": "#737c88"}, "packs": ["fahl*4", "fahl*2 hohl*2", "hohl*3", "haut fahl*2", "wisp*8", "guard*2 fahl*2"], "boss": {"name": "Der Stumme Türhüter", "look": "grey", "col": "#a9b3b6", "r": 38, "hp": 1.1, "say": "Wer seinen Namen nennt, darf durch. Es kennt ihn keiner mehr.", "beiname": "der nach dem Namen fragt", "bild": "h04"}},
	{"name": "Die Höhle des Sokar", "dungeon": "vault", "legs": ["greed", "critres"], "lead": "Tausend Krüge, und in jedem schlägt es. In ihrer Mitte liegt die Nachtbarke auf dem Trockenen.", "tex": "T02", "mix": [["star", 3], ["ruin", 2], ["tomb", 2], ["needle", 2], ["rock", 1]], "mote": "#c9a8ff", "mood": "glass", "brief": "Noch acht Stunden. Der Mann, der die Herzen sammelt, saß einmal selbst zu Gericht, als einer der Zweiundvierzig. Er hat einen Krug für dich gemacht. Und einen für sie.", "epi": "Die Krüge zerspringen, einer nach dem anderen, und die Herzen fliegen heim. Die Waage bewegt sich, die Barke hebt sich vom Sand. Aber an der Wand, wo der Richter fiel, ist kein Schatten. Und Nebets Krug ist nicht unter den Scherben.", "vo2": ["epi"], "pal": {"ground": "#4a4452", "dune": "#5b5465", "rock": "#58515f", "rockL": "#7a7186"}, "packs": ["fahl*3 hohl", "lance*3 seer", "guard*3", "haut hohl*2", "wisp*8", "seer*2 fahl*2", "skorp*6"], "boss": {"name": "Der Sammler", "look": "sammler", "col": "#b06be0", "r": 44, "hp": 1.3, "say": "Er hat auch für dich einen Krug.", "beiname": "einst einer der Zweiundvierzig", "bild": "h05"}},
]
const OPEN := [
	{"name": "Der Leib des Osiris", "base": 2, "boss": 2, "bossName": "Der falsche Osiris", "bild": "h06", "beiname": "der auf fremdem Lager liegt", "say": "Er liegt, wo ein anderer liegen sollte.", "lead": "Die tiefste Stunde. Hier ruht, was von Osiris blieb, und Re muss es berühren, um wieder jung zu werden.", "brief": "Noch sieben Stunden. Um Mitternacht müssen Re und Osiris einander begegnen, sonst wird die Sonne nicht jung. Isis wartet am Lager. Der Vogel auf deiner Schulter will nicht zu ihr.", "epi": "Der Platz ist wieder frei. Für einen Atemzug sind Re und Osiris eins, und in diesem Licht siehst du bis ans Ende der Nacht: das Tor des Ostens, und davor einen Schatten mit einem Krug im Arm.", "vo2": ["epi"]},
	{"name": "Die Sandbank des Apophis", "base": 0, "boss": 1, "bossName": "Eine Windung des Apophis", "bild": "h07", "beiname": "nur eine Windung von vielen", "look": "apophis", "say": "Das ist nur eine Windung. Der Rest liegt unter der Sandbank.", "lead": "Eine Sandbank, so lang wie er selbst. Er hat das Wasser unter der Barke ausgetrunken.", "brief": "Noch sechs Stunden, und die Barke liegt auf dem Trockenen. Seth steht am Bug mit dem Speer, Isis spricht die Worte, Selket hält die Fessel. Neben Seth steht Haremhab. Dir bleibt das Messer.", "epi": "Er ist gebunden, nicht tot; er ist nie tot. Das Wasser kommt zurück, und die Barke fährt. Haremhab wischt seine Klinge ab und sieht nach Osten. „Ein Schatten braucht kein Wasser. Er geht zu Fuß, und er ist schneller als wir.“", "vo2": ["epi"]},
	{"name": "Die Grüfte der Götter", "base": 3, "boss": 3, "bossName": "Der Hüter ohne Stimme", "bild": "h08", "beiname": "aus dessen Gruft kein Laut kommt", "say": "Aus seiner Gruft kommt kein Laut.", "lead": "Aus den Grüften antwortet es, wenn Re vorüberfährt. Heute antwortet etwas anderes.", "brief": "Noch fünf Stunden. Wenn Re ruft, sollen die Stimmen aus den Grüften klingen wie ein Kater und wie ein Schwarm Bienen. Aus einer Gruft kommt nichts. Sie ist neu.", "epi": "Es summt wieder in den Grüften. Im Sand vor der stummen Gruft steht, mit der Schwertspitze geschrieben: „Vier Stunden. Ich bin vor dir da.“ Haremhab ist fort, dem Schatten nach.", "vo2": ["epi"]},
	{"name": "Die Ruderer", "base": 4, "boss": 0, "bossName": "Der zwölfte Ruderer", "bild": "h09", "beiname": "dessen Bank leer blieb", "say": "Sein Ba hat die Bank nicht mehr gefunden.", "lead": "Zwölf Ruderer hat die Barke. Elf sitzen auf ihren Bänken.", "brief": "Noch vier Stunden. Mit elf Rudern kommt die Barke nicht gegen die Strömung an. Der zwölfte irrt als Licht durch die Gänge und findet seine Bank nicht mehr.", "epi": "Zwölf Ruder tauchen ein, im gleichen Takt. Die Barke macht Fahrt. Am Ufer, weit voraus, geht einer zu Fuß und sieht sich nicht um.", "vo2": ["epi"]},
	{"name": "Die Ertrunkenen im Nun", "base": 1, "boss": 2, "bossName": "Der Ertrunkene König", "bild": "h10", "beiname": "der sich am Grund festhält", "say": "Er hält sich am Grund fest.", "lead": "Wer im Fluss blieb, bekam kein Grab. Horus zieht sie hier ans Ufer, damit auch sie gewogen werden.", "brief": "Noch drei Stunden. Auch wer kein Grab bekam, hat ein Recht auf die Waage. Am Ufer treiben angekohlte Seiten. Jemand hat versucht, ein Buch zu verbrennen.", "epi": "Horus ruft sie beim Namen, und sie kommen ans Ufer, einer nach dem anderen. Nur die Namen aus dem Buch kann er nicht rufen. Und das Buch ist auf dem Weg ins Feuer.", "vo2": ["epi"]},
	{"name": "Die Feuergruben", "base": 2, "boss": 1, "bossName": "Die Entronnene", "bild": "h11", "beiname": "aus der Feuergrube gekrochen", "say": "Sie ist aus der Grube gekrochen.", "lead": "Gruben voll Feuer, und an jedem Rand eine Göttin mit dem Messer. Hier endet, wer gegen die Ordnung stand.", "brief": "Noch zwei Stunden. Am Rand der Grube steht Haremhab mit dem Verzeichnis. Geh nicht zu nah an den Rand. Etwas ist herausgekommen.", "epi": "Die Grube schließt sich. Am Rand des Himmels wird es grau. Der Schatten hat das Buch verloren, aber nicht den Krug. Er wartet am Tor des Ostens.", "vo2": ["epi"]},
	{"name": "Das Tor des Ostens", "base": 0, "boss": 4, "bossName": "Der Schatten des Sammlers", "bild": "h12", "beiname": "was nach dem Wiegen blieb", "say": "Sein Herz ist gewogen. Sein Schatten wusste nichts davon.", "lead": "Die letzte Stunde. Re geht durch den Leib der Schlange „Leben der Götter“ und kommt als Chepri wieder heraus. Etwas steht davor.", "brief": "Die letzte Stunde. Hinter dem Tor wartet Schu mit erhobenen Armen, um die Sonne zu heben. Davor wartet ein Schatten mit Nebets Krug. Und dahinter die Waage.", "epi": "Schu hebt die Sonne über den Horizont. Thot schreibt diese Nacht in sein Buch und schlägt eine neue Seite auf. Apophis kommt jede Nacht wieder, und jede Nacht braucht es jemanden mit einer Laterne."},
]

static func hour_of(n: int) -> int:
	return (n - 1) % HOURS + 1

static func night_of(n: int) -> int:
	return (n - 1) / HOURS + 1

static func hour_txt(n: int) -> String:
	return ("%d. Nacht, " % night_of(n) if night_of(n) > 1 else "") + ORD[hour_of(n) - 1] + " Stunde"

static func case_no(n: int) -> String:
	if night_of(n) > 1:
		return "%d. NACHT · %s STUNDE" % [night_of(n), ORD[hour_of(n) - 1].to_upper()]
	return "%s STUNDE DER NACHT" % ORD[hour_of(n) - 1].to_upper()

# Die Stunde n: ACT für 1–5, sonst Landschaft und Legendäre von ACT[base], Hüter-Gestalt von ACT[boss], alle Rudel
# Akte (4.0): Akt 1 ist ausgebaut; Akt 2 und 3 haben vorerst ihre Tafeln (A2). Texte seit 4.3 aus der Neufassung (GESCHICHTE.md)
const AKTE := [
	{"nr": "ERSTER AKT", "name": "Der Abstieg", "txt": "Nebet fiebert, und bis zum Morgen sind es zwölf Stunden. Folge den Lichtern hinab und finde heraus, wer die Waage angehalten hat. Am Ende des Abstiegs fragt einer nach deinem Namen.", "eigen": "Eigenheit dieses Aktes: Wird ein Rudel wach, ruft es die Nachbarn."},
	{"nr": "ZWEITER AKT", "name": "Die Wahrheit", "txt": "Du weißt jetzt, was du bist. Unten wartet der Mann, der die Herzen sammelt, und er hat einen Krug für dich. Um Mitternacht erfährst du, wer die ganze Nacht auf deiner Schulter saß.", "eigen": "Eigenheit dieses Aktes: Gegner, die eine Weile nicht getroffen werden, heilen sich."},
	{"nr": "DRITTER AKT", "name": "Der Morgen", "txt": "Vier Stunden. Ein Schatten geht der Barke voraus, mit einem Buch voller Namen und einem Krug im Arm, und ein General ist ihm auf den Fersen. Wer das Buch hat, hat Sandtor.", "eigen": "Eigenheit dieses Aktes: Gegner sind schneller."},
]

static func akt(n: int) -> int:
	return clampi((hour_of(n) - 1) / 4, 0, 2)

# Bilder aus ComfyUI (BILDWERK.md, Stufen 10 und 11; einbauen.bat hueter / akttafeln). Fehlt die Datei, gibt es
# einen leeren Pfad, und Ankündigung und Tafel bleiben ohne Bild wie bisher.
# Hüter: ui/hueter/h01 bis h12 (Feld „bild“ im Hüter der Stunde). Fehlt das eigene Bild einer Stunde ab der sechsten,
# leiht sie das Bild ihrer Gestalt (Stunden.def), wie die Stunden 9 bis 12, solange h09 bis h12 nicht gemalt sind.
static func hueter_bild(boss: Dictionary) -> String:
	var p := "res://ui/hueter/%s.webp" % boss.get("bild", "")
	return p if boss.has("bild") and ResourceLoader.exists(p) else ""

# Akt i (0, 1, 2): ui/akte/a1 bis a3, hinter dem Text der Akttafel
static func akt_bild(i: int) -> String:
	var p := "res://ui/akte/a%d.webp" % (clampi(i, 0, 2) + 1)
	return p if ResourceLoader.exists(p) else ""

static func def(n: int) -> Dictionary:
	var h := hour_of(n)
	if h <= ACT.size():
		return Geschichte.fuell(ACT[h - 1])
	var o: Dictionary = OPEN[h - ACT.size() - 1]
	var b: Dictionary = ACT[o.base].duplicate(true)
	b.name = o.name
	b.lead = o.lead
	b.brief = o.brief
	b.epi = o.epi
	var packs := []
	for a in ACT:
		packs.append_array(a.packs)
	b.packs = packs
	var boss: Dictionary = ACT[o.boss].boss.duplicate()
	boss.name = o.bossName
	boss.say = o.say
	boss.beiname = o.get("beiname", "")
	if o.has("look"):
		boss.look = o.look   # eigene Gestalt statt der geliehenen (Kampfmuster bleibt das der geliehenen)
	if o.has("bild") and ResourceLoader.exists("res://ui/hueter/%s.webp" % o.bild):
		boss.bild = o.bild   # eigenes Bild, wenn es gemalt ist; sonst bleibt das der geliehenen Gestalt
	boss.hp = 1.3
	b.boss = boss
	b.vo2 = o.get("vo2", [])
	return Geschichte.fuell(b)

# Name der Ansage einer Stunde (audio/<name>.ogg): Leitsatz „lead“, Satz des Hüters „say“, Epilog „epi“.
# Seit 4.3 sind einige Texte neu (Feld „vo2“); deren alte Aufnahmen sagen noch den alten Text und spielen darum nicht
# mehr. Die neue Aufnahme heißt vo_hNN_epi2 und spielt, sobald sie unter audio/ liegt (Liste: tools/ton/sprechzeilen.json).
static func vo_name(n: int, art: String) -> String:
	return "vo_h%02d_%s%s" % [hour_of(n), art, "2" if art in def(n).get("vo2", []) else ""]

# „wisp*6 skorp*2“ → ["wisp", "wisp", …, "skorp", "skorp"]
static func expand(pack: String) -> Array:
	var out := []
	for t in pack.split(" "):
		var p := t.split("*")
		for i in (int(p[1]) if p.size() > 1 else 1):
			out.append(p[0])
	return out
