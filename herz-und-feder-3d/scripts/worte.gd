class_name Worte
# Wechselnde Texte (3.0): Was oft vorkommt, soll nicht jedes Mal gleich klingen. Jeder Schlüssel ist ein Stapel von
# Sätzen; „zieh“ nimmt den nächsten und mischt erst neu, wenn alle dran waren. Der erste Satz eines Stapels ist der,
# den man als Erstes hört (er erklärt am meisten), danach kommen die anderen in zufälliger Reihenfolge.

const T := {
	# dein Ba, wenn du eine Feuerschale entzündest
	"ba_feuer": ["Re sieht dieses Feuer. Auch von so weit unten.",
		"Wärmer. Merkst du es? Ich hatte vergessen, wie das ist.",
		"Jedes Feuer hier unten ist ein Stück Tag.",
		"Alle, die im Dunkeln warten, sehen es jetzt.",
		"Brenn weiter, kleines Licht. Wir kommen wieder vorbei.",
		"Ein Feuer mehr. Die Nacht zählt mit.",
		"Zu Hause hast du die Lampe immer als Erstes angezündet. Vor allen anderen."],
	# dein Ba, wenn du ein Herz freilässt
	"ba_frei": ["Es hat „Danke“ gesagt. Hast du es gehört?",
		"Es ist nach oben geflogen. Es wusste den Weg noch.",
		"Hast du gesehen, wie leicht es war?",
		"Jemand in Sandtor schläft heute ruhiger und weiß nicht, warum.",
		"Du hättest es behalten können. Ich bin froh, dass ich zu dir gehöre.",
		"Wieder eines. Der, der die Krüge aufstellt, wird schimpfen."],
	# dein Ba, wenn du einen Krug plünderst
	"ba_raub": ["Es hat nicht geschrien. Das ist das Schlimme.",
		"Zähl es nicht vor mir.",
		"Es war nur ein Krug. Sag dir das ruhig.",
		"Ich habe weggesehen. Du auch?",
		"Der, der sie aufstellt, hätte genickt.",
		"Etwas ist stiller geworden. Vielleicht bist du es."],
	# Seelenkrug: was du siehst und hörst
	"krug_bild": ["Der Krug ist warm. Unter dem Siegel schlägt es, langsam und geduldig, wie etwas, das seit dem Herbst wartet.",
		"Du hörst es, bevor du ihn siehst: ein Pochen, dumpf wie durch eine Wand. Der Ton des Kruges ist handwarm.",
		"Staub liegt auf dem Deckel, aber nicht auf dem Siegel. Jemand kommt her und wischt es ab. Darunter schlägt es schnell, wie nach einem Lauf.",
		"Der Krug steht schief, als hätte ihn jemand eilig abgestellt. Was darin schlägt, stockt, als du die Hand auflegst, und schlägt dann weiter.",
		"Kein Staub, keine Spinnweben. Der Krug ist neuer als alles um ihn herum. Das Herz darin schlägt ruhig. Es weiß noch nicht, wo es ist.",
		"Um den Hals des Kruges hängt ein Band aus blauen Perlen, wie man es Kindern umlegt oder denen, die man liebt. Es schlägt darin, sehr leise.",
		"Auf dem Siegel ist kein Name eingedrückt, nur eine Feder, sauber und tief. So siegeln die Zweiundvierzig. Darunter schlägt es, als hätte es Angst."],
	# wem das Herz gehört
	"krug_name": ["Amenemhet, Töpfer", "Satre, Hebamme", "Kawab, Ruderer", "Meritamun, Färberin", "Intef, Soldat der Torwache",
		"Mutnofret, Sängerin im Tempel", "Hapu, Schreiberlehrling", "Tjeti, Fischhändler", "Ahmose, Bierbrauerin", "Sennefer, Gärtner",
		"Renseneb, Zimmermann", "Ipuy, Salbenmischer", "Neferu, noch ein Kind", "Chnumhotep, Ziegelstreicher"],
	# die Wahl, jedes Mal klar benannt
	"krug_wahl": ["Das Herz darin wurde nie gewogen. Löst du das Siegel, ist es frei und findet den Weg zur Waage. Brichst du den Krug auf, zerfällt es, und was der Sammler dazugelegt hat, gehört dir.",
		"Löst du das Siegel, fliegt das Herz zur Waage. Zerschlägst du den Krug, bleiben dir die Beigaben, und vom Herzen bleibt nichts.",
		"Freilassen kostet dich nur die Beigaben. Aufbrechen bringt sie dir, und das Herz zerfällt zu Staub."],
	"herz_frei": ["Ein Herz findet heim", "Es steigt auf", "Frei", "Auf dem Weg zur Waage"],
	# Leute am Eingang, wenn ihre Sorge schon erledigt ist
	"helfer_wink": ["%s winkt dir zu.", "%s nickt dir zu und zählt noch einmal nach.", "%s summt vor sich hin und hebt die Hand zum Gruß.",
		"%s sieht auf und lächelt."],
	# nach einer Niederlage (solange du nicht weißt, was du bist)
	"tod": ["Für einen Augenblick war es dunkel. Dann hat dich etwas mit kleinen Flügeln an der Wange gestreift, bis du die Augen geöffnet hast. Was dich angegriffen hat, ist noch dort.",
		"Die Laterne lag neben dir im Staub und ist nicht ausgegangen. Merkwürdig, eigentlich. Steh auf. Es ist noch dort, wo du es gelassen hast.",
		"Dein Ba hat über dir gekreist und geschimpft, bis du wieder aufgestanden bist. Die Flamme ist klein geworden, aber sie brennt.",
		"Du wachst auf und atmest nicht schwer. Du atmest gar nicht schwer. Steh auf, sie warten noch auf dich."],
	# nach der fünften Stunde weißt du es
	"tod_wissend": ["Man stirbt hier nicht zweimal. Aber es tut jedes Mal so weh wie beim ersten Mal. Steh auf.",
		"Tote haben Zeit. Die Sonne hat keine. Nebet auch nicht.",
		"Die Laterne brennt noch. Solange sie brennt, bist du nicht fertig.",
		"Dunkel, dann wieder Licht. Du kennst das inzwischen. Die anderen warten, wo du sie gelassen hast."],
	# Leute unterwegs (3.2): ein Satz im Vorbeigehen. Sie wissen nicht, wo sie sind, und reden, als wäre es ein Abend in Sandtor.
	"leute_satz": ["Ist es schon spät? Es ist so lange dunkel heute.",
		"Hast du meinen Bruder gesehen? Er wollte nur kurz zum Hafen.",
		"Das Brot ist noch warm. Merkwürdig, ich habe es doch gestern gebacken.",
		"Gehst du auch zum Fest? Alle gehen in diese Richtung.",
		"Ich kenne diesen Weg. Ich glaube, ich kenne ihn.",
		"Der Fluss ist so still. Hörst du ihn?",
		"Man sagt, die Barke kommt bald. Dann wird es hell.",
		"Ich habe Durst, aber das Wasser schmeckt nach nichts.",
		"Meine Mutter wartet. Sie wartet immer.",
		"Du trägst eine Laterne? Wie schön. Hier hat niemand mehr Licht.",
		"Ich sollte mich beeilen. Ich weiß nur nicht, wohin.",
		"Wenn du zum Markt gehst, sag Nebet, ich komme später.",
		"Im Fieberhaus brennt noch eine Lampe. Einer sitzt daneben und rührt sich nicht.",
		"Hast du das Mädchen mit den blauen Fingern gesehen? Sie hat mir ein Tuch gewebt.",
		"Mir war so heiß. Und dann auf einmal gar nicht mehr.",
		"Ein alter Mann hat meinen Namen aufgeschrieben. Er war sehr freundlich. Er hat geweint.",
		"Seit wann sind die Sterne so tief?",
		"Ich träume viel in letzter Zeit. Immer von einer Waage.",
		"Pass auf die Schatten auf. Manche sind keine.",
		"Gestern war Herbst. Oder war das vor langer Zeit?",
		"Hörst du das? Irgendwo singt jemand.",
		"Ich habe meinen Namen aufgeschrieben, damit ich ihn nicht vergesse.",
		"Hier riecht es nach Myrrhe. Wie im Tempel.",
		"Bleib nicht zu lange stehen. Das tut keinem gut, hier.",
		"Kennst du den Weg nach Hause? Ich dachte, ich wüsste ihn.",
		"Die Katzen sind fort. Früher waren hier überall Katzen.",
		"Wer bist du? Du siehst aus, als wüsstest du etwas.",
		"Ich warte auf jemanden. Ich weiß nur nicht mehr, auf wen.",
		"Sei freundlich zu den Toten, sagt meine Großmutter. Sie sagt es jeden Abend."],
	"hueter_faellt": ["Die Stunde ist vollendet. Eine Pforte steht offen.", "Der Weg ist frei. Hinter dem Hüter steht eine Pforte offen.",
		"Es wird still. Wo der Hüter fiel, öffnet sich die Pforte zur nächsten Stunde."],
}

# Rückblick auf der Tafel jeder Stunde: was in der Stunde davor geschah, in schlichten Worten
# Rückblick auf der Tafel jeder Stunde: was in der Stunde davor geschah, in schlichten Worten (bisher() wählt nach Entscheidung)
const BISHER := ["",
	"Mahaf ist zu Licht zerfallen und brennt jetzt in deiner Laterne. Bevor er verlosch, sagte er, er habe dich heute schon übergesetzt.",
	"Das Feldtor wurde mit einem Königsring geöffnet, dessen Name herausgekratzt ist. Ein General jagt denselben Mann wie du.",
	"Der König ohne Namen hat Name und Ring an einen weinenden Richter verkauft. In seinem Sarkophag stand ein leerer Krug. Auf dem Siegel: Nebet.",
	"Der Türhüter hat deinen Namen auf der Liste der Toten gefunden. Du bist heute Abend gestorben, an Nebets Bett. Hinter dem Tor wartet der Richter mit seinen Krügen.",
	"Der Sammler ist gefallen, die Waage bewegt sich, und Thot hat dein Herz gewogen. Aber sein Schatten ist fort, mit dem Verzeichnis und mit Nebets Krug.",
	["Isis hat den Namen des Vogels auf deiner Schulter gesagt: Nebet. Sie ist dir aus dem Fieber nachgeflogen. Du hast sie heimgeschickt, allein, durch sechs Stunden Dunkel.",
		"Isis hat den Namen des Vogels auf deiner Schulter gesagt: Nebet. Sie ist dir aus dem Fieber nachgeflogen, und sie ist geblieben. Ihr Leib in Sandtor wartet."],
	"Apophis ist gebunden, das Wasser ist zurück. Der Schatten hat ihm den Weg gezeigt, und er geht der Barke zu Fuß voraus.",
	"In der stummen Gruft saß dein eigener Ba, ohne Namen. Haremhab ist fort, dem Schatten nach. Er will das Verzeichnis verbrennen, mit allen Namen darin.",
	"Der zwölfte Ruderer sitzt wieder auf seiner Bank. Er war nur eine Nacht fort und hätte sie beinahe nicht wiedergefunden.",
	"Horus hat die Ertrunkenen gerufen. Am Ufer trieben angekohlte Seiten voller Namen aus Sandtor.",
	["Am Rand der Feuergrube hast du Haremhab das Verzeichnis abgenommen. Es liegt in deiner Tasche, schwer wie ein Kind. Eine Stunde bleibt.",
		"Das Verzeichnis ist in der Feuergrube verbrannt. Tausend Namen sind als Funken aufgestiegen. Eine Stunde bleibt."]]

# Stunden mit zwei Fassungen: welche Entscheidung sie wählt
const BISHER_WAHL := {7: 6, 12: 11}

const SO_GEHT_ES := "So geht es: Besiege die Gegner dieser Stunde, bis sich ihr Hüter zeigt. Fällt er, öffnet sich die Pforte zur nächsten Stunde. Am Eingang wartet jemand, der dir mehr erzählen kann, und daneben steht die Werkstatt des Ptah für deine Ausrüstung."

static var stapel := {}

static func zieh(key: String) -> String:
	if not stapel.has(key):
		var k: Array = T[key].slice(1)
		k.shuffle()
		k.append(T[key][0])
		stapel[key] = k
	elif stapel[key].is_empty():
		var k: Array = T[key].duplicate()
		k.shuffle()
		stapel[key] = k
	return Geschichte.fuell(stapel[key].pop_back())

static func bisher(stunde: int) -> String:
	if stunde < 1 or stunde > BISHER.size():
		return ""
	var b: Variant = BISHER[stunde - 1]
	if b is Array:
		return b[0 if Geschichte.gewaehlt(BISHER_WAHL[stunde]) == "maat" else 1]
	return b
