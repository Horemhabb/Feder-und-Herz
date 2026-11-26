class_name Stunden
# Die zwölf Stunden der Nacht (01-data.js › ACT, OPEN, caseDef, hourOf, nightOf, caseNo). Die ersten fünf erzählen die
# Geschichte, sechs bis zwölf bringen die Barke bis zum Morgen; danach beginnt die nächste Nacht (n = 13, 14, …),
# die Gegner werden über n weiter stärker.

const HOURS := 12
const ORD := ["Erste", "Zweite", "Dritte", "Vierte", "Fünfte", "Sechste", "Siebte", "Achte", "Neunte", "Zehnte", "Elfte", "Zwölfte"]

const ACT := [
	{"name": "Das Tor des Westens", "legs": ["lantern", "sight"], "lead": "Über Sandtor ziehen Lichter gegen den Wind. Es sind Seelen, und niemand holt sie ab.", "tex": "T01", "mix": [["rock", 7], ["needle", 3]], "mote": "#bcd0e8", "mood": "dust", "brief": "Folge den Lichtern hinab. Halte die Laterne hoch. In ihr brennt ein Funke des Re, und was Isfet ist, weicht vor ihm zurück oder greift ihn an.", "epi": "Mahaf war der Fährmann. Seit die Waage stillsteht, darf er niemanden mehr übersetzen, also führte er die Seelen im Kreis. Sein Licht brennt jetzt in deiner Laterne, und es zeigt nach unten.", "pal": {"ground": "#5a5547", "dune": "#6d6756", "rock": "#6f6657", "rockL": "#91876f"}, "packs": ["wisp*6", "skorp*4 wisp*2", "lance*2 wisp*3", "skorp*5", "lance*3", "wisp*8"], "boss": {"name": "Mahaf, das Leitlicht", "look": "wisp", "col": "#8fe3e0", "r": 30, "hp": 0.7, "say": "Der Fährmann, der hinter sich schaut. Er hat seine Fähre verloren und setzt trotzdem über.", "beiname": "Fährmann ohne Fähre", "bild": "h01"}},
	{"name": "Die Felder von Wernes", "dungeon": "ruin", "legs": ["skin", "shards"], "lead": "Wo die Gerechtfertigten Korn schnitten, häutet sich die Brut des Apophis. Jede Haut macht sie größer.", "tex": "T03", "mix": [["rock", 4], ["needle", 5], ["ruin", 1]], "mote": "#d8c9a0", "mood": "dust", "brief": "Mahafs Licht führt in die Felder, die einmal die Seligen ernährten. Die Sebau fürchten keine Waage, denn sie haben kein Herz. Jemand muss ihnen den Weg hierher geöffnet haben.", "epi": "Unter ihrer letzten Haut lag kein Leib, nur Sand und der Abdruck eines Siegels: ein Königsring ohne Namen darin. Was Apophis gebiert, kann man nicht wiegen. Also braucht er jemanden, der die Waage für ihn anhält.", "pal": {"ground": "#4d5450", "dune": "#5f6964", "rock": "#5f6661", "rockL": "#7f8a83"}, "packs": ["lance*3 seer", "seer*2 lance*2", "haut skorp*3", "lance*4", "haut seer*2", "skorp*6"], "boss": {"name": "Die Mutter der Häute", "look": "mutter", "col": "#c9a24e", "r": 46, "hp": 0.9, "say": "Sie hat schon viele Häute getragen. Diese ist ihre zwölfte.", "beiname": "Brut des Apophis", "bild": "h02"}},
	{"name": "Der König ohne Namen", "dungeon": "tomb", "legs": ["heavy", "potion"], "lead": "Am Wasser des Osiris liegt ein König, dessen Name aus jeder Wand geschlagen ist. Er hält ein Schwert aus dem Gold der Tagesbarke.", "tex": "T04", "mix": [["ruin", 5], ["tomb", 5], ["rock", 1]], "mote": "#ffb060", "mood": "ember", "brief": "Wer keinen Namen hat, den kann Thot nicht aufrufen, und wer nicht aufgerufen wird, kommt nie vor die Waage. Die Toten in diesen Gräbern liegen wach. Ihr Ba findet nicht mehr zu ihnen zurück.", "epi": "Er hat seinen Namen verkauft. Der Käufer versprach ihm dafür, dass sein Herz nie auf die Waage kommt. Im Sarkophag liegt die Quittung: ein versiegelter Krug. Er ist warm, und er schlägt.", "pal": {"ground": "#47423f", "dune": "#57514c", "rock": "#5d564f", "rockL": "#7b7268"}, "packs": ["guard*3", "guard*2 wisp*3", "hohl*2 wisp*3", "guard*4", "wisp*8", "haut guard*2"], "boss": {"name": "Der König ohne Namen", "look": "koenig", "col": "#d8b04a", "r": 40, "hp": 1, "say": "Frag ihn nicht, wie er heißt. Er weiß es nicht mehr.", "undead": true, "beiname": "der seinen Namen verkaufte", "bild": "h03"}},
	{"name": "Rosetau", "dungeon": "glass", "legs": ["mirror", "star"], "lead": "Sokars Land, „der auf seinem Sand ist“. Hier wird die Barke gezogen, nicht gerudert. Die sie zogen, stehen erloschen an den Wegen.", "tex": "T02", "mix": [["ruin", 4], ["star", 4], ["needle", 2]], "mote": "#8fe3e0", "mood": "glass", "brief": "Der Krug aus dem Sarkophag schlägt in deiner Tasche wie ein zweites Herz, und er zieht nach Westen. In Rosetau gibt es kein Wasser. Seit die Sterne erloschen sind, zieht niemand mehr die Barke über den Sand.", "epi": "Die Erloschenen waren Unvergängliche Sterne. Sie zogen die Barke, bis jemand ihnen das Herz nahm. Hinter dem Tor liegt das Zugseil. Es führt in eine Höhle, und es ist straff gespannt.", "pal": {"ground": "#434a52", "dune": "#535b65", "rock": "#535a63", "rockL": "#737c88"}, "packs": ["fahl*4", "fahl*2 hohl*2", "hohl*3", "haut fahl*2", "wisp*8", "guard*2 fahl*2"], "boss": {"name": "Der Stumme Türhüter", "look": "grey", "col": "#a9b3b6", "r": 38, "hp": 1.1, "say": "Wer seinen Namen nennt, darf durch. Es kennt ihn keiner mehr.", "beiname": "der nach dem Namen fragt", "bild": "h04"}},
	{"name": "Die Höhle des Sokar", "dungeon": "vault", "legs": ["greed", "critres"], "lead": "Tausend Krüge, und in jedem schlägt es. In ihrer Mitte liegt die Nachtbarke auf dem Trockenen.", "tex": "T02", "mix": [["star", 3], ["ruin", 2], ["tomb", 2], ["needle", 2], ["rock", 1]], "mote": "#c9a8ff", "mood": "glass", "brief": "Der Sammler saß einmal selbst zu Gericht, als einer der Zweiundvierzig. Er weiß, was die Waage findet. Sein eigenes Herz ist ihm zu schwer geworden, also hat er beschlossen, dass sie nie wieder etwas findet.", "epi": "Die Krüge zerspringen, einer nach dem anderen. Die Herzen finden heim, die Waage bewegt sich, und Thot taucht die Binse ein. Die Barke hebt sich vom Sand. Sieben Stunden bleiben bis zum Morgen, und in der siebten wartet Apophis.", "pal": {"ground": "#4a4452", "dune": "#5b5465", "rock": "#58515f", "rockL": "#7a7186"}, "packs": ["fahl*3 hohl", "lance*3 seer", "guard*3", "haut hohl*2", "wisp*8", "seer*2 fahl*2", "skorp*6"], "boss": {"name": "Der Sammler", "look": "sammler", "col": "#b06be0", "r": 44, "hp": 1.3, "say": "Er hat auch für dich einen Krug.", "beiname": "einst einer der Zweiundvierzig", "bild": "h05"}},
]
const OPEN := [
	{"name": "Der Leib des Osiris", "base": 2, "boss": 2, "bossName": "Der falsche Osiris", "bild": "h06", "beiname": "der auf fremdem Lager liegt", "say": "Er liegt, wo ein anderer liegen sollte.", "lead": "Die tiefste Stunde. Hier ruht, was von Osiris blieb, und Re muss es berühren, um wieder jung zu werden.", "brief": "Die Barke fährt wieder, aber sie ist schwach. Um Mitternacht müssen Re und Osiris einander begegnen. Auf dem Lager des Osiris liegt jemand, der dort nicht hingehört.", "epi": "Der Platz ist wieder frei. Für einen Atemzug sind Re und Osiris eins, und der Funke in deiner Laterne wird heller."},
	{"name": "Die Sandbank des Apophis", "base": 0, "boss": 1, "bossName": "Eine Windung des Apophis", "bild": "h07", "beiname": "nur eine Windung von vielen", "look": "apophis", "say": "Das ist nur eine Windung. Der Rest liegt unter der Sandbank.", "lead": "Eine Sandbank, so lang wie er selbst. Er hat das Wasser unter der Barke ausgetrunken.", "brief": "Seth steht am Bug mit dem Speer. Isis spricht die Worte, Selket hält die Fessel. Dir bleibt das Messer.", "epi": "Isis hat ihn besprochen, Selket hat ihn gebunden, du hast das Messer geführt. Er ist nicht tot, er ist nie tot. Aber das Wasser kommt zurück, und die Barke fährt."},
	{"name": "Die Grüfte der Götter", "base": 3, "boss": 3, "bossName": "Der Hüter ohne Stimme", "bild": "h08", "beiname": "aus dessen Gruft kein Laut kommt", "say": "Aus seiner Gruft kommt kein Laut.", "lead": "Aus den Grüften antwortet es, wenn Re vorüberfährt. Heute antwortet etwas anderes.", "brief": "Wenn Re ruft, sollen die Stimmen aus den Grüften klingen wie ein Kater und wie ein Schwarm Bienen. Hör hin, ob sie es noch tun.", "epi": "Es summt wieder in den Grüften, und irgendwo schreit ein Kater. So soll es sein."},
	{"name": "Die Ruderer", "base": 4, "boss": 0, "bossName": "Der zwölfte Ruderer", "beiname": "dessen Bank leer blieb", "say": "Sein Ba hat die Bank nicht mehr gefunden.", "lead": "Zwölf Ruderer hat die Barke. Elf sitzen auf ihren Bänken.", "brief": "Mit elf Rudern kommt die Barke nicht gegen die Strömung an. Der zwölfte irrt als Licht durch die Gänge.", "epi": "Zwölf Ruder tauchen ein. Zum ersten Mal in dieser Nacht hörst du Wasser."},
	{"name": "Die Ertrunkenen im Nun", "base": 1, "boss": 2, "bossName": "Der Ertrunkene König", "beiname": "der sich am Grund festhält", "say": "Er hält sich am Grund fest.", "lead": "Wer im Fluss blieb, bekam kein Grab. Horus zieht sie hier ans Ufer, damit auch sie gewogen werden.", "brief": "Auch wer kein Grab bekam, hat ein Recht auf die Waage. Einer will nicht an Land.", "epi": "Horus ruft sie beim Namen, und sie kommen ans Ufer, einer nach dem anderen."},
	{"name": "Die Feuergruben", "base": 2, "boss": 1, "bossName": "Die Entronnene", "beiname": "aus der Feuergrube gekrochen", "say": "Sie ist aus der Grube gekrochen.", "lead": "Gruben voll Feuer, und an jedem Rand eine Göttin mit dem Messer. Hier endet, wer gegen die Ordnung stand.", "brief": "Geh nicht zu nah an den Rand. Etwas ist herausgekommen.", "epi": "Die Grube ist wieder voll. Am Rand des Himmels wird es grau."},
	{"name": "Das Tor des Ostens", "base": 0, "boss": 4, "bossName": "Der Schatten des Sammlers", "beiname": "was nach dem Wiegen blieb", "say": "Sein Herz ist gewogen. Sein Schatten wusste nichts davon.", "lead": "Die letzte Stunde. Re geht durch den Leib der Schlange „Leben der Götter“ und kommt als Chepri wieder heraus. Etwas steht davor.", "brief": "Hinter dem Tor wartet Schu mit erhobenen Armen, um die Sonne zu heben. Vor dem Tor wartet jemand, den du schon einmal besiegt hast.", "epi": "Schu hebt die Sonne über den Horizont. Thot schreibt diese Nacht in sein Buch und schlägt eine neue Seite auf. Apophis kommt jede Nacht wieder, und jede Nacht braucht es jemanden mit einer Laterne."},
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
# Akte (4.0): Akt 1 ist ausgebaut; Akt 2 und 3 haben vorerst ihre Tafeln (A2)
const AKTE := [
	{"nr": "ERSTER AKT", "name": "Der Abstieg", "txt": "Du folgst den Lichtern hinab, findest die Spur des Königssiegels und die erloschenen Sterne. Am Ende wartet der Stumme Türhüter.", "eigen": "Eigenheit dieses Aktes: Wird ein Rudel wach, ruft es die Nachbarn."},
	{"nr": "ZWEITER AKT", "name": "Die Wahrheit", "txt": "Der Sammler, dein eigener Tod, Mitternacht bei Osiris und die Schlange Apophis.", "eigen": "Eigenheit dieses Aktes: Gegner, die eine Weile nicht getroffen werden, heilen sich."},
	{"nr": "DRITTER AKT", "name": "Der Morgen", "txt": "Die Barke wird wieder vollständig. Vor dem Tor des Ostens steht ein Schatten, den du kennst.", "eigen": "Eigenheit dieses Aktes: Gegner sind schneller."},
]

static func akt(n: int) -> int:
	return clampi((hour_of(n) - 1) / 4, 0, 2)

# Bilder aus ComfyUI (BILDWERK.md, Stufen 10 und 11; einbauen.bat hueter / akttafeln). Fehlt die Datei, gibt es
# einen leeren Pfad, und Ankündigung und Tafel bleiben ohne Bild wie bisher.
# Hüter: ui/hueter/h01 bis h08 (Feld „bild“ im Hüter der Stunde; die Stunden 9 bis 12 leihen das Bild ihrer Gestalt).
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
		return ACT[h - 1]
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
	if o.has("bild"):
		boss.bild = o.bild   # eigenes Bild; sonst bleibt das der geliehenen Gestalt (Stunden 9 bis 12)
	boss.hp = 1.3
	b.boss = boss
	return b

# „wisp*6 skorp*2“ → ["wisp", "wisp", …, "skorp", "skorp"]
static func expand(pack: String) -> Array:
	var out := []
	for t in pack.split(" "):
		var p := t.split("*")
		for i in (int(p[1]) if p.size() > 1 else 1):
			out.append(p[0])
	return out
