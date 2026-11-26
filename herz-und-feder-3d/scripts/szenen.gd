class_name Szenen
# Die Zwischensequenzen der Geschichte (4.3), abgespielt von szene.gd. Drehbuch mit Bildbeschreibungen: SZENEN.md,
# Bildwünsche: tools/bildwerk/wunsch_szenen.md, Sprechzeilen: tools/ton/sprechzeilen.json (Klangnamen „vo“ unten).
#
# Eine Sequenz: {"titel": …, "einstellungen": [Einstellung, …]}. Eine Einstellung:
#   bild      Name des Bildes in ui/szenen/ (ohne .webp)
#   ersatz    was gezeigt wird, solange das Bild fehlt, der erste vorhandene zählt: "portrait:P05", "hueter:h05",
#             "akt:0" (Akttafel 0 bis 2), "titel", "welt" (Blick in die Spielwelt), "zeichen:waage" (immer da)
#   zeichen   Zeichen auf der Ersatzfläche hinter einem Porträt (sonne, waage, krug, tor, feder, laterne, ba, auge, schlange)
#   art       "welt": gar kein Bild, die Kamera fährt in der Spielwelt (ziel: hueter, held, pforte, arena; nah: Meter;
#             winkel/dreh: Blickrichtung und langsames Kreisen; licht: Faktor für das Licht; fov)
#   fahrt     [[Zoom, x, y], [Zoom, x, y]]: langsame Kamerafahrt über das Bild (x, y von −1 bis 1)
#   ebenen    [{"bild": …, "tiefe": 1.6, "mischen": "add"}]: Ebenen für Parallaxe (Lichter auf Schwarz werden addiert)
#   zeilen    Untertitel [{"t": Text, "wer": Sprecher (leer: Erzähler), "vo": Klangname}], Dauer nach Länge oder Aufnahme
#   musik, ton, blende ("schwarz", "weiss"), beben (0 bis 1), stich (Farbe), staub (an/aus), titel (Zwischentitel), dauer

# Reihenfolge und Titel (für „Erinnerungen“)
const LISTE := [
	["auftakt", "Die Nacht, in der Nebet fiebert"],
	["h01_vor", "Der Fährmann"], ["h01_nach", "Heute schon einmal"],
	["h02_vor", "Die zwölfte Haut"], ["h02_nach", "Ein General am Feldtor"],
	["h03_vor", "Der König ohne Namen"], ["h03_nach", "Ein Krug für Nebet"],
	["h04_vor", "Die Frage"], ["akt1_ende", "Ende des ersten Aktes: Dein Name"],
	["h05_vor", "Das Angebot"], ["h05_nach", "Ein Mann ohne Schatten"],
	["mitte", "Der Name auf deiner Schulter"], ["h06_nach", "Mitternacht"],
	["h07_vor", "Die Sandbank"], ["h07_nach", "Was Haremhab kann"],
	["h08_vor", "Die stumme Gruft"], ["akt2_ende", "Ende des zweiten Aktes: Zwei Jäger"],
	["h09_vor", "Der zwölfte Ruderer"], ["h10_vor", "Der am Grund"],
	["h11_vor", "Die Entronnene"], ["h12_vor", "Das letzte Angebot"],
	["finale", "Die Waage"],
]

static func hat(name: String) -> bool:
	for p in LISTE:
		if p[0] == name:
			return true
	return false

static func liste() -> Array:
	return LISTE

static func titel(name: String) -> String:
	for p in LISTE:
		if p[0] == name:
			return p[1]
	return name

# Welche Sequenz an welcher Stelle: vor dem Hüterkampf, nach dem Hüter, vor dem ersten Gespräch der Stunde
static func vor(n: int) -> String:
	var h := Stunden.hour_of(n)
	if h == 6:
		return "mitte"   # falls das Gespräch mit Isis übersprungen wurde: spätestens hier
	var name := "h%02d_vor" % h
	return name if hat(name) else ""

static func nach(n: int) -> String:
	var h := Stunden.hour_of(n)
	if h == 4:
		return "akt1_ende"
	if h == 8:
		return "akt2_ende"
	var name := "h%02d_nach" % h
	return name if hat(name) else ""

static func vor_gespraech(n: int) -> String:
	return "mitte" if Stunden.hour_of(n) == 6 else ""

# ---------------------------------------------------------------- Bausteine
static func _z(t: String, wer := "", vo := "") -> Dictionary:
	var z := {"t": Geschichte.fuell(t), "wer": wer}
	if vo != "":
		z["vo"] = vo
	return z

static func _w(gew: int) -> String:
	return Geschichte.gewaehlt(gew)

# ---------------------------------------------------------------- die Sequenzen
static func baue(name: String) -> Dictionary:
	var E: Array = []
	match name:
		"auftakt":
			E = [
				{"bild": "sz_auftakt_1", "ersatz": ["titel", "zeichen:sonne"], "fahrt": [[1.18, 0.0, 0.5], [1.04, 0.0, -0.3]], "ton": "amb_wind",
					"zeilen": [_z("Sandtor, am Rand des Westens. Seit drei Nächten geht die Sonne später auf.", "", "vo_sz_auftakt_01"),
						_z("Und seit drei Nächten steigen aus den Dächern Lichter, die nicht wiederkommen.", "", "vo_sz_auftakt_02")]},
				{"bild": "sz_auftakt_2", "ersatz": ["zeichen:laterne"], "fahrt": [[1.04, -0.4, 0.0], [1.16, 0.3, 0.1]],
					"zeilen": [_z("Im Fieberhaus liegt Nebet. Sie webt Leinen. Ihre Finger sind blau vom Färben, und sie glüht.", "", "vo_sz_auftakt_03"),
						_z("Drei Nächte hast du an ihrem Bett gesessen und das Licht gehalten.", "", "vo_sz_auftakt_04")]},
				{"bild": "sz_auftakt_3", "ersatz": ["zeichen:laterne"], "fahrt": [[1.1, 0.0, 0.0], [1.22, 0.0, 0.2]], "stich": Color(1.0, 0.92, 0.82),
					"zeilen": [_z("„Das Fieber bricht im Morgengrauen. Wenn eines kommt.“", "Der alte Priester", "vo_sz_auftakt_05"),
						_z("„Unten steht die Waage still. Ohne Gewogene zieht niemand die Barke der Sonne.“", "Der alte Priester", "vo_sz_auftakt_06"),
						_z("„Nimm die Laterne. Geh hinab, solange sie brennt. Und frag nicht, warum gerade du.“", "Der alte Priester", "vo_sz_auftakt_07")]},
				{"bild": "sz_auftakt_4", "ersatz": ["akt:0", "titel", "zeichen:tor"], "fahrt": [[1.02, 0.0, -0.2], [1.12, 0.0, 0.3]],
					"ebenen": [{"bild": "sz_auftakt_4_lichter", "tiefe": 1.8, "mischen": "add"}],
					"zeilen": [_z("Zwölf Stunden hat die Nacht.", "", "vo_sz_auftakt_08"),
						_z("Dann kommt der Morgen. Oder er kommt nie wieder.", "", "vo_sz_auftakt_09")]},
				{"art": "welt", "ziel": "held", "nah": 6.5, "winkel": -0.5, "dreh": 0.25, "licht": 0.8,
					"zeilen": [_z("Etwas mit kleinen Flügeln setzt sich auf deine Schulter, als hätte es immer dort gesessen.", "", "vo_sz_auftakt_10"),
						_z("„Ich bin dein Ba. Ich flattere, du gehst. Frag nicht, wer führt.“", "Dein Ba", "vo_sz_auftakt_11")]},
			]
		"h01_vor":
			E = [{"art": "welt", "ziel": "hueter", "nah": 10.0, "dreh": 0.2,
				"zeilen": [_z("Ein Licht, größer als die anderen, dreht sich nach dir um. Es hält ein Ruder, das es nicht hat.", "", "vo_sz_h01_vor_01"),
					_z("„Er führt sie im Kreis. Dich auch, wenn du ihn lässt.“", "Dein Ba", "vo_sz_h01_vor_02")]}]
		"h01_nach":
			E = [{"art": "welt", "ziel": "arena", "nah": 8.0, "dreh": -0.2, "licht": 0.7,
				"zeilen": [_z("Mahaf zerfällt zu Licht. Bevor er verlischt, sieht er dich an, lange, wie man einen Fahrgast ansieht.", "", "vo_sz_h01_nach_01"),
					_z("„Dich habe ich heute schon übergesetzt.“", "Mahaf", "vo_sz_h01_nach_02"),
					_z("„Er ist verwirrt. Komm weiter.“", "Dein Ba", "vo_sz_h01_nach_03")]}]
		"h02_vor":
			E = [{"art": "welt", "ziel": "hueter", "nah": 11.0, "dreh": 0.18, "beben": 0.6,
				"zeilen": [_z("Zwischen den Garben richtet sich etwas auf, Haut über Haut, und streift die zwölfte ab.", "", "vo_sz_h02_vor_01"),
					_z("„Das ist ekelhaft. Ich sag's nur.“", "Dein Ba", "vo_sz_h02_vor_02")]}]
		"h02_nach":
			E = [{"art": "welt", "ziel": "arena", "nah": 7.0, "dreh": 0.15,
					"zeilen": [_z("Unter der letzten Haut liegt nur Sand. Darin ein Abdruck: ein Königsring, der Name herausgekratzt.", "", "vo_sz_h02_nach_01")]},
				{"bild": "sz_h02_feldtor", "ersatz": ["welt", "zeichen:tor"], "ziel": "held", "nah": 7.5, "winkel": 0.6, "fahrt": [[1.06, 0.3, 0.0], [1.16, -0.2, 0.0]],
					"zeilen": [_z("Am Feldtor kniet ein Mann in der Rüstung eines Generals und prüft das Wachs am Riegel.", "", "vo_sz_h02_nach_02"),
						_z("„Schlampig. Wer tilgt, muss gründlich tilgen, sonst spricht der Rest.“", "Haremhab", "vo_sz_h02_nach_03"),
						_z("„Du jagst ihn auch. Gut. Geh vor. Ich bin hinter dir.“", "Haremhab", "vo_sz_h02_nach_04")]}]
		"h03_vor":
			var kennt := _w(3) == "maat"
			E = [{"art": "welt", "ziel": "hueter", "nah": 9.0, "dreh": 0.15, "licht": 0.75,
				"zeilen": [_z("Auf dem Sarkophag sitzt ein König, ein Schwert aus dem Gold der Tagesbarke über den Knien. Er sieht durch dich hindurch.", "", "vo_sz_h03_vor_01"),
					_z("„Du kennst seinen Namen. Er nicht. Entzünde ihn an den Wänden, dann hört er ihn.“", "Dein Ba", "vo_sz_h03_vor_02") if kennt else
					_z("„Frag ihn nicht, wie er heißt. Entzünde die Zeichen an den Wänden. Dann hört er es.“", "Dein Ba", "vo_sz_h03_vor_03")]}]
		"h03_nach":
			E = [{"art": "welt", "ziel": "arena", "nah": 6.5, "dreh": 0.1, "licht": 0.6,
					"zeilen": [_z("Der König sinkt zurück in seinen Sarkophag. Neben ihm, wo die Beigaben liegen sollten, steht ein Krug.", "", "vo_sz_h03_nach_01")]},
				{"bild": "sz_h03_krug", "ersatz": ["zeichen:krug"], "fahrt": [[1.08, 0.0, 0.0], [1.26, 0.0, 0.1]],
					"zeilen": [_z("Leer. Versiegelt. Noch warm. Um den Hals ein Faden, blau gefärbt.", "", "vo_sz_h03_nach_02"),
						_z("Auf dem Siegel steht ein Name, den du kennst.", "", "vo_sz_h03_nach_03"),
						_z("Nebet.", "", "vo_sz_h03_nach_04"),
						_z("„Das ist nur ein Krug. Das heißt gar nichts. Komm.“", "Dein Ba", "vo_sz_h03_nach_05")]}]
		"h04_vor":
			E = [{"art": "welt", "ziel": "hueter", "nah": 10.0, "dreh": 0.12, "licht": 0.7,
				"zeilen": [_z("Der Türhüter hebt den Kopf. Er hat keinen Mund. Trotzdem hörst du die Frage.", "", "vo_sz_h04_vor_01"),
					_z("Wie heißt du?", "Der Stumme Türhüter", "vo_sz_h04_vor_02"),
					_z("„Sag es nicht. Kämpf einfach. Bitte.“", "Dein Ba", "vo_sz_h04_vor_03")]}]
		"akt1_ende":
			E = [
				{"art": "welt", "ziel": "arena", "nah": 8.0, "dreh": 0.2, "licht": 0.35,
					"zeilen": [_z("Der Türhüter liegt in den Scherben seines Tores. Er fragt noch immer.", "", "vo_sz_akt1_01"),
						_z("Wie heißt du?", "Der Stumme Türhüter", "vo_sz_akt1_02")]},
				{"bild": "sz_akt1_liste", "ersatz": ["hueter:h04", "zeichen:tor"], "fahrt": [[1.05, 0.0, -0.4], [1.2, 0.0, 0.5]],
					"zeilen": [_z("Du sagst deinen Namen.", "", "vo_sz_akt1_03"),
						_z("Er fährt mit dem Finger die Liste des Westens hinab, bis ganz nach unten, wo die Tinte noch feucht ist. Rot.", "", "vo_sz_akt1_04"),
						_z("Er nickt. Hinter ihm öffnet sich das Tor. Es öffnet sich nur für Tote.", "", "vo_sz_akt1_05")]},
				{"bild": "sz_akt1_fieberhaus", "ersatz": ["zeichen:laterne"], "blende": "weiss", "stich": Color(0.82, 0.9, 1.0), "fahrt": [[1.2, 0.0, 0.0], [1.05, 0.0, 0.0]],
					"zeilen": [_z("Du erinnerst dich.", "", "vo_sz_akt1_06"),
						_z("Das Fieberhaus. Ihr Bett. Deine Hände um die Lampe, und wie sie kalt werden, ganz ruhig, noch vor Mitternacht.", "", "vo_sz_akt1_07"),
						_z("Nebet hat geschrien. Du hast es nicht mehr gehört.", "", "vo_sz_akt1_08")]},
				{"art": "welt", "ziel": "held", "nah": 5.5, "winkel": 0.8, "dreh": -0.15, "licht": 0.2,
					"zeilen": [_z("„Ich wollte es dir sagen.“", "Dein Ba", "vo_sz_akt1_09"),
						_z("„Ich wollte nur nicht, dass du stehen bleibst.“", "Dein Ba", "vo_sz_akt1_10")]},
				{"bild": "sz_akt1_hoehle", "ersatz": ["akt:1", "zeichen:krug"], "fahrt": [[1.02, 0.0, 0.3], [1.2, 0.0, -0.1]], "musik": "mus_hoehle",
					"zeilen": [_z("„Komm herunter. Ich habe einen Krug für dich gemacht.“", "Eine Stimme aus der Tiefe", "vo_sz_akt1_11"),
						_z("„Und einen für sie.“", "Eine Stimme aus der Tiefe", "vo_sz_akt1_12")]},
				{"ersatz": ["zeichen:krug"], "titel": "Ende des ersten Aktes", "dauer": 3.6, "staub": true, "zeilen": []},
			]
		"h05_vor":
			var zeilen := []
			if _w(4) == "maat":
				zeilen.append(_z("„Ein Stern sieht wieder nach Norden. Das warst du. Und doch bist du hier.“", "Der Sammler", "vo_sz_h05_vor_01"))
			elif _w(4) == "isfet":
				zeilen.append(_z("„Zwei Herzen in deiner Laterne, und eines gestohlen. Siehst du? Wir sind uns ähnlich.“", "Der Sammler", "vo_sz_h05_vor_02"))
			zeilen.append(_z("„Leg die Laterne in den Krug. Dann ist Sandtor vollständig, und keiner von euch wird je gefressen. Auch sie nicht.“", "Der Sammler", "vo_sz_h05_vor_03"))
			zeilen.append(_z("„Hör nicht auf ihn.“", "Dein Ba", "vo_sz_h05_vor_04"))
			E = [{"bild": "sz_h05_angebot", "ersatz": ["portrait:P05"], "zeichen": "krug", "fahrt": [[1.04, 0.0, 0.0], [1.14, 0.0, -0.2]],
					"zeilen": zeilen},
				{"art": "welt", "ziel": "hueter", "nah": 11.0, "dreh": 0.2, "licht": 0.6,
					"zeilen": [_z("Um ihn herum steigen Krüge aus dem Boden, und in jedem schlägt es.", "", "vo_sz_h05_vor_05")]}]
		"h05_nach":
			E = [{"art": "welt", "ziel": "arena", "nah": 9.0, "dreh": 0.25,
				"zeilen": [_z("Die Krüge zerspringen, einer nach dem anderen. Tausend Herzen fliegen heim, und irgendwo oben bewegt sich eine Waage.", "", "vo_sz_h05_nach_01"),
					_z("An der Wand, wo der Schatten des Richters sein müsste, ist nichts.", "", "vo_sz_h05_nach_02"),
					_z("„Er ist nicht tot. Ein Mann ohne Schatten. Den finde ich.“", "Haremhab", "vo_sz_h05_nach_03")]}]
		"mitte":
			E = [
				{"bild": "sz_mitte_isis", "ersatz": ["portrait:P11"], "zeichen": "ba", "fahrt": [[1.04, 0.2, 0.0], [1.14, -0.2, 0.0]], "musik": "mus_duat",
					"zeilen": [_z("Isis sieht nicht dich an. Sie sieht auf deine Schulter.", "", "vo_sz_mitte_01"),
						_z("„Komm her, Kleine. Ich kenne deinen Namen. Ich kenne jeden Namen.“", "Isis", "vo_sz_mitte_02"),
						_z("„Nebet.“", "Isis", "vo_sz_mitte_03")]},
				{"bild": "sz_mitte_ba", "ersatz": ["zeichen:ba"], "stich": Color(0.85, 1.0, 0.98), "fahrt": [[1.1, 0.0, 0.0], [1.3, 0.0, -0.2]],
					"zeilen": [_z("Der Vogel auf deiner Schulter hat ein Gesicht. Du hast es die ganze Nacht nicht angesehen.", "", "vo_sz_mitte_04"),
						_z("„Ich bin dir nachgeflogen. Aus dem Fieber, als du nicht mehr geatmet hast.“", "Nebet", "vo_sz_mitte_05"),
						_z("„Ich hab gelogen, die ganze Nacht. Hättest du gewusst, dass du tot bist, wärst du stehen geblieben. Und ich wollte leben.“", "Nebet", "vo_sz_mitte_06")]},
				{"bild": "sz_mitte_sandtor", "ersatz": ["titel", "zeichen:laterne"], "stich": Color(0.8, 0.86, 1.0), "fahrt": [[1.12, 0.0, 0.0], [1.02, 0.0, 0.0]],
					"zeilen": [_z("„Ihr Leib liegt in Sandtor und wird kälter, je länger sie hier ist. Ein Ba, der zu lange fort ist, findet nicht zurück.“", "Isis", "vo_sz_mitte_07"),
						_z("„Es ist Mitternacht. Entscheide, bevor die Nacht es für dich tut.“", "Isis", "vo_sz_mitte_08")]},
			]
		"h06_nach":
			E = [{"bild": "sz_h06_mitternacht", "ersatz": ["akt:2", "zeichen:sonne"], "blende": "weiss", "fahrt": [[1.02, 0.0, 0.0], [1.18, 0.4, -0.2]],
				"zeilen": [_z("Für einen Atemzug sind Re und Osiris eins, und in diesem Licht siehst du bis ans Ende der Nacht.", "", "vo_sz_h06_nach_01"),
					_z("Das Tor des Ostens. Und davor ein Schatten, mit einem Krug im Arm.", "", "vo_sz_h06_nach_02")]}]
		"h07_vor":
			E = [{"art": "welt", "ziel": "hueter", "nah": 12.0, "dreh": 0.25, "beben": 0.8,
				"zeilen": [_z("Eine Windung, dick wie ein Tempel, schiebt sich aus dem Sand. Der Rest liegt darunter und trinkt.", "", "vo_sz_h07_vor_01"),
					_z("„Endlich etwas, das man ohne Zweifel töten darf.“", "Haremhab", "vo_sz_h07_vor_02")]}]
		"h07_nach":
			E = [{"bild": "sz_h07_bug", "ersatz": ["welt", "zeichen:schlange"], "ziel": "held", "nah": 7.0, "winkel": -0.7, "fahrt": [[1.05, -0.3, 0.0], [1.15, 0.3, 0.0]],
				"zeilen": [_z("„Ich habe Namen aus Wänden schlagen lassen, als ich König war. Ich weiß, wie man einen Mann auslöscht.“", "Haremhab", "vo_sz_h07_nach_01"),
					_z("„Ich hole mir sein Buch. Und dann brennt es.“", "Haremhab", "vo_sz_h07_nach_02")]}]
		"h08_vor":
			E = [{"art": "welt", "ziel": "hueter", "nah": 10.0, "dreh": 0.15, "licht": 0.5,
				"zeilen": [_z("Aus der stummen Gruft steigt etwas, das ruft, ohne einen Laut.", "", "vo_sz_h08_vor_01")]}]
		"akt2_ende":
			var stimme := _w(8) == "maat"
			E = [
				{"bild": "sz_akt2_gruft", "ersatz": ["zeichen:ba"], "stich": Color(0.92, 0.9, 1.0), "fahrt": [[1.06, 0.0, 0.0], [1.22, 0.0, -0.1]],
					"zeilen": [_z("In der stummen Gruft sitzt ein Ba ohne Gesicht. Als du die Laterne hebst, dreht er sich zum ersten Mal nach dir um.", "", "vo_sz_akt2_01"),
						_z("Er hat dein Gesicht.", "", "vo_sz_akt2_02"),
						_z("Er öffnet den Mund, und was herauskommt, ist deine Stimme.", "", "vo_sz_akt2_03") if stimme else
						_z("Er öffnet den Mund. Es kommt nichts.", "", "vo_sz_akt2_04")]},
				{"art": "welt", "ziel": "held", "nah": 6.0, "winkel": 0.4, "dreh": 0.15, "licht": 0.5,
					"zeilen": [_z("Haremhab ist fort. Im Sand vor der Gruft steht, mit der Schwertspitze geschrieben:", "", "vo_sz_akt2_05"),
						_z("„Vier Stunden. Ich bin vor dir da.“", "Haremhab", "vo_sz_akt2_06")]},
				{"bild": "sz_akt2_osten", "ersatz": ["akt:2", "zeichen:tor"], "fahrt": [[1.02, 0.0, 0.0], [1.16, 0.0, -0.3]],
					"zeilen": [_z("Zwei gehen der Barke voraus. Einer will alle Namen behalten. Einer will sie alle verbrennen.", "", "vo_sz_akt2_07"),
						_z("Und in beider Händen ist Nebet.", "", "vo_sz_akt2_08")]},
				{"ersatz": ["zeichen:tor"], "titel": "Ende des zweiten Aktes", "dauer": 3.6, "zeilen": []},
			]
		"h09_vor":
			E = [{"art": "welt", "ziel": "hueter", "nah": 10.0, "dreh": 0.15,
				"zeilen": [_z("Ein Licht mit einem Ruderer darin schlägt nach allem, was es ruft. Es war nur eine Nacht fort.", "", "vo_sz_h09_vor_01")]}]
		"h10_vor":
			var verkauft := _w(3) == "isfet"
			E = [{"art": "welt", "ziel": "hueter", "nah": 10.0, "dreh": 0.15, "licht": 0.7,
				"zeilen": [_z("Am Grund hält sich einer fest, mit beiden Händen, als wäre der Schlamm ein Thron.", "", "vo_sz_h10_vor_01"),
					_z("Du kennst ihn. Er hat seinen Namen verkauft, und du hast ihn weiterverkauft.", "", "vo_sz_h10_vor_02") if verkauft else
					_z("Auf seiner Brust klebt ein Siegel, und darauf ist kein Name.", "", "vo_sz_h10_vor_03")]}]
		"h11_vor":
			E = [{"art": "welt", "ziel": "hueter", "nah": 11.0, "dreh": 0.2, "beben": 0.4,
				"zeilen": [_z("Aus der Grube kriecht eine, die verurteilt war. Sie hat das Feuer mitgebracht.", "", "vo_sz_h11_vor_01")]}]
		"h12_vor":
			E = [{"bild": "sz_h12_schatten", "ersatz": ["welt", "zeichen:krug"], "ziel": "hueter", "nah": 9.0, "fahrt": [[1.04, 0.0, 0.0], [1.16, 0.0, -0.1]],
				"zeilen": [_z("Vor dem Tor des Ostens steht der Schatten. Er hat kein Gesicht mehr, nur Hände, und in den Händen einen Krug.", "", "vo_sz_h12_vor_01"),
					_z("„Bleib hier und trag die Krüge mit mir. Dann wird sie nie gewogen. Nie.“", "Der Schatten des Sammlers", "vo_sz_h12_vor_02")]}]
		"finale":
			E = _finale()
	return {"titel": titel(name), "einstellungen": E}

# Das Ende: Waage, Licht aus, Antwort, Urteil, der Schatten, Nebet, das Bild des Endes
static func _finale() -> Array:
	var art := Geschichte.ende_art()
	var E: Array = []
	E.append({"bild": "sz_finale_waage", "ersatz": ["akt:1", "zeichen:waage"], "fahrt": [[1.04, 0.0, 0.3], [1.18, 0.0, -0.2]], "musik": "mus_duat",
		"zeilen": [_z("Die Halle ist still. Zweiundvierzig Plätze, und einer ist leer.", "", "vo_sz_finale_01"),
			_z("„Leg dein Herz auf die Schale.“", "Thot", "vo_sz_finale_02"),
			_z("Es ist in der Laterne. Es war die ganze Nacht dort.", "", "vo_sz_finale_03")]})
	var antwort: Dictionary
	if _w(8) == "maat":
		antwort = _z("Thot ruft deinen Namen, und du antwortest. Mit deiner eigenen Stimme.", "", "vo_sz_finale_06")
	elif _w(6) != "maat":
		antwort = _z("Thot ruft deinen Namen. Du öffnest den Mund, und nichts. Da sagt etwas Kleines auf deiner Schulter: „Hier.“", "", "vo_sz_finale_07")
	else:
		antwort = _z("Thot ruft deinen Namen. Du öffnest den Mund, und nichts. Da sagt hinten in der Halle eine Frau aus Sandtor deinen Namen noch einmal, als hätte sie Angst, er sei falsch geschrieben.", "", "vo_sz_finale_08")
	E.append({"bild": "sz_finale_dunkel", "ersatz": ["zeichen:laterne"], "stich": Color(0.75, 0.75, 0.85), "fahrt": [[1.15, 0.0, 0.0], [1.04, 0.0, 0.0]],
		"zeilen": [_z("Du öffnest das Glas und nimmst es heraus. Das Licht geht aus.", "", "vo_sz_finale_04"),
			_z("Es ist dunkel, und du bist noch da.", "", "vo_sz_finale_05"), antwort]})
	match art:
		"leicht":
			E.append({"bild": "sz_finale_leicht", "ersatz": ["akt:2", "zeichen:waage"], "blende": "weiss", "fahrt": [[1.02, 0.0, 0.0], [1.14, 0.0, -0.3]],
				"zeilen": [_z("Die Schalen schwanken. Dann stehen sie still, beide gleich hoch.", "", "vo_sz_finale_09"),
					_z("„Wahr an Stimme.“ Und leiser: „Wie lange du das getragen hast.“", "Thot", "vo_sz_finale_10")]})
		"schwer":
			E.append({"bild": "sz_finale_schwer", "ersatz": ["zeichen:waage"], "stich": Color(1.0, 0.78, 0.72), "beben": 0.5, "fahrt": [[1.04, 0.0, 0.0], [1.16, 0.2, 0.2]],
				"zeilen": [_z("Die Schale sinkt. Am Fuß der Waage hebt die Fresserin den Kopf.", "", "vo_sz_finale_11"),
					_z("Thot legt die Hand auf die Schale. „Noch nicht.“", "Thot", "vo_sz_finale_12")]})
		_:
			E.append({"bild": "sz_finale_schwebe", "ersatz": ["zeichen:feder"], "fahrt": [[1.04, 0.0, 0.0], [1.14, -0.2, 0.0]],
				"zeilen": [_z("Die Waage findet keine Seite. Thot legt die Binse weg und sieht dich lange an.", "", "vo_sz_finale_13"),
					_z("„Es fehlt ein Fährmann.“", "Thot", "vo_sz_finale_14")]})
	# der Schatten: die Wahrheit über seine Tochter, dann das Buch (Stunde 11)
	var buch: Dictionary = _z("Thot schlägt das Verzeichnis auf und liest, Name um Name, ganz Sandtor. Der Schatten stellt den Krug ab und nimmt eine Laterne.", "", "vo_sz_finale_17") if _w(11) == "maat" \
		else _z("Das Verzeichnis ist Asche. Da tritt Chaemwese aus dem Dunkel und liest von seiner roten Liste, Name um Name, ganz Sandtor. Ein Schreiber vergisst nichts.", "", "vo_sz_finale_18")
	E.append({"bild": "sz_finale_schatten", "ersatz": ["zeichen:krug"], "fahrt": [[1.06, 0.0, 0.0], [1.16, 0.0, 0.0]],
		"zeilen": [_z("Thot wendet sich an den Schatten vor dem Tor.", "", "vo_sz_finale_15"),
			_z("„Du hast nicht bis zum Ende hingesehen. Deine Tochter wurde nicht gefressen. Ich habe ‚Noch nicht‘ geschrieben, und sie ging mit einer Laterne in die nächste Nacht.“", "Thot", "vo_sz_finale_16"),
			buch]})
	var nebet: Array
	if _w(6) == "maat":
		nebet = [_z("In Sandtor geht die Sonne auf. Im Fieberhaus setzt sich ein Mädchen mit blauen Fingern auf und fragt nach dir.", "", "vo_sz_finale_19")]
	else:
		nebet = [_z("„Jetzt muss ich. Ich bin schneller als die Sonne. Wetten?“", "Nebet", "vo_sz_finale_20"),
			_z("Sie fliegt mit dem ersten Licht nach Westen, sechs Stunden in einem Atemzug.", "", "vo_sz_finale_21")]
	var schluss: Dictionary
	match art:
		"leicht":
			schluss = _z("Im Norden, wo ein Platz am Himmel leer war, geht ein Stern auf, der nie mehr untergeht.", "", "vo_sz_finale_22") if _w(4) == "maat" \
				else _z("In den Feldern von Wernes legt dir Merit eine Sichel in die Hand.", "", "vo_sz_finale_23")
		"schwer":
			schluss = _z("Du gehst in die nächste Nacht, mit einer Laterne, die ohne Öl brennt.", "", "vo_sz_finale_24")
		_:
			schluss = _z("Am Ufer liegt ein Ruder aus Zedernholz. Du kennst es.", "", "vo_sz_finale_25") if _w(1) != "isfet" \
				else _z("Am Ufer liegt ein Ruder aus Treibholz. Das aus Zeder hast du verbrannt. Es wird reichen.", "", "vo_sz_finale_26")
	E.append({"bild": "sz_finale_morgen", "ersatz": ["akt:2", "titel", "zeichen:sonne"], "blende": "weiss", "fahrt": [[1.02, 0.0, 0.3], [1.16, 0.0, -0.2]], "musik": "mus_titel",
		"zeilen": nebet + [schluss]})
	E.append({"ersatz": ["zeichen:sonne"], "titel": "Ende", "dauer": 3.6, "zeilen": []})
	return E
