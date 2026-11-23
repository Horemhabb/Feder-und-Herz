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
		"Ein Feuer mehr. Die Nacht zählt mit."],
	# dein Ba, wenn du ein Herz freilässt
	"ba_frei": ["Es hat „Danke“ gesagt. Hast du es gehört?",
		"Es ist nach oben geflogen. Es wusste den Weg noch.",
		"Hast du gesehen, wie leicht es war?",
		"Jemand in Sandtor schläft heute ruhiger und weiß nicht, warum.",
		"Du hättest es behalten können. Ich bin froh, dass ich zu dir gehöre.",
		"Wieder eines. Die Waage bekommt zu tun."],
	# dein Ba, wenn du einen Krug plünderst
	"ba_raub": ["Es hat nicht geschrien. Das ist das Schlimme.",
		"Zähl es nicht vor mir.",
		"Es war nur ein Krug. Sag dir das ruhig.",
		"Ich habe weggesehen. Du auch?",
		"Der Sammler hätte genickt.",
		"Etwas ist stiller geworden. Vielleicht bist du es."],
	# Seelenkrug: was du siehst und hörst
	"krug_bild": ["Der Krug ist warm. Unter dem Siegel schlägt es, langsam und geduldig, wie etwas, das seit dem Herbst wartet.",
		"Du hörst es, bevor du ihn siehst: ein Pochen, dumpf wie durch eine Wand. Der Ton des Kruges ist handwarm.",
		"Staub liegt auf dem Deckel, aber nicht auf dem Siegel. Jemand kommt her und wischt es ab. Darunter schlägt es schnell, wie nach einem Lauf.",
		"Der Krug steht schief, als hätte ihn jemand eilig abgestellt. Was darin schlägt, stockt, als du die Hand auflegst, und schlägt dann weiter.",
		"Kein Staub, keine Spinnweben. Der Krug ist neuer als alles um ihn herum. Das Herz darin schlägt ruhig. Es weiß noch nicht, wo es ist.",
		"Um den Hals des Kruges hängt ein Band aus blauen Perlen, wie man es Kindern umlegt oder denen, die man liebt. Es schlägt darin, sehr leise."],
	# wem das Herz gehört
	"krug_name": ["Amenemhet, Töpfer", "Satre, Hebamme", "Kawab, Ruderer", "Nebet, Weberin", "Intef, Soldat der Torwache",
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
	"tod": ["Dein Ba hat den Weg zurück in den Leib gefunden, und die Laterne brennt noch. Was dich angegriffen hat, ist noch dort.",
		"Für einen Augenblick war es dunkel. Dann hat dein Ba dich gefunden, und die Flamme hat wieder Luft bekommen. Sie warten noch auf dich.",
		"Dein Ba hat über dir gekreist, bis du die Augen geöffnet hast. Die Flamme in der Laterne ist klein geworden, aber sie brennt.",
		"Die Laterne lag neben dir im Staub und ist nicht ausgegangen. Steh auf. Es ist noch dort, wo du es gelassen hast."],
	# nach der fünften Stunde weißt du es
	"tod_wissend": ["Man stirbt hier nicht zweimal. Aber es tut jedes Mal so weh, als wäre es das erste Mal. Steh auf.",
		"Dein Ba hat den Weg zurück gefunden, wie immer. Tote haben Zeit. Die Sonne hat keine.",
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
	# dein Ba, wenn du nach einer Niederlage wieder aufstehst (erster Akt); %d ist die Zahl der Rückschläge
	"ba_tod": ["Wieder aufgestanden. Ich zähle nicht mit. Doch. %d.",
		"Ich habe dich gefunden. Du lagst genau da, wo ich dich verloren hatte.",
		"Das sah schmerzhaft aus. Ich war oben. Von oben sah es auch schmerzhaft aus.",
		"Steh auf. Die Laterne brennt noch, und ich flattere nicht gern allein im Dunkeln.",
		"Ein Ba findet immer zurück. Es ist das Einzige, was ich wirklich gut kann."],
	# dein Ba, wenn alle drei verlorenen Dinge der Leute gefunden sind
	"ba_leute": ["Drei von drei. Ich hätte bei zweien aufgehört. Darum trägst du die Laterne und nicht ich.",
		"Jemand ist jetzt ein wenig weniger verloren. Das zählt hier unten doppelt.",
		"Du suchst im Totenreich nach fremden Sachen. Ich erzähle das niemandem, sonst wollen es alle."],
	"hueter_faellt": ["Die Stunde ist vollendet. Eine Pforte steht offen.", "Der Weg ist frei. Hinter dem Hüter steht eine Pforte offen.",
		"Es wird still. Wo der Hüter fiel, öffnet sich die Pforte zur nächsten Stunde."],
}

# Rückblick auf der Tafel jeder Stunde: was in der Stunde davor geschah, in schlichten Worten
const BISHER := ["",
	"Du hast Mahaf besiegt, den Fährmann, der die Seelen im Kreis führte. Sein Licht brennt jetzt in deiner Laterne und weist nach unten.",
	"In den Feldern hast du die Schlangenbrut des Apophis vertrieben. Sie trug ein Königssiegel ohne Namen: Jemand hat ihr das Tor geöffnet.",
	"Der König ohne Namen hatte seinen Namen verkauft, damit sein Herz nie gewogen wird. Der Käufer ließ einen Krug zurück, in dem es schlägt. Du trägst ihn bei dir.",
	"In Rosetau standen die erloschenen Sterne, die früher die Sonnenbarke zogen. Jemand hat ihnen die Herzen genommen. Das Zugseil der Barke führt in eine Höhle.",
	"Du hast den Sammler besiegt, der die Herzen in Krügen hortete, damit keines mehr gewogen wird. Die Waage geht wieder, die Barke fährt. Und du weißt jetzt, dass du selbst im Herbst gestorben bist.",
	"Re und Osiris sind einander begegnet, die Sonne ist wieder jung. Vor der Barke liegt die Sandbank des Apophis.",
	"Apophis ist gebunden, das Wasser ist zurück. Die Barke fährt an den Grüften der Götter vorbei.",
	"Aus den Grüften antworten wieder die richtigen Stimmen. Aber der Barke fehlt ein Ruderer.",
	"Zwölf Ruder tauchen wieder ein. Die Barke erreicht das Urwasser, in dem die Ertrunkenen treiben.",
	"Horus hat die Ertrunkenen ans Ufer gerufen. Vor dem Morgen liegen nur noch die Feuergruben.",
	"Die Feuergruben sind wieder verschlossen, am Rand des Himmels wird es grau. Eine Stunde bleibt bis zum Morgen."]

# ---------------------------------------------------------------- Dein Ba im ersten Akt (Etappe B)
# Er ist die komische Begleitfigur (GESCHICHTE.md Teil 2): trocken, liebevoll, nie über die Toten. In Akt 1 redet er viel,
# später weniger. Je Stunde (Index 0 = erste Stunde): beim ersten Kampf, wenn der Hüter erwacht, nach dem Fundstück.
const BA_VORSTELLUNG := "Ich bin dein Ba. Ich flattere, du gehst. Wir sind ein gutes Paar, solange du nicht fragst, wer führt."
const BA_KAMPF := ["Das da ist ein Irrlicht. Du hast eine Laterne. Ich will nicht sagen, wer im Vorteil ist. Du.",
	"Sie häuten sich. Ich mausere mich nur. Wir haben nichts gemeinsam, sag ihnen das.",
	"Die hier liegen wach, seit ihr König seinen Namen verkauft hat. Sei nicht zu streng mit ihnen. Doch, sei streng.",
	"Glas. Alles hier ist Glas. Schlag vorsichtig. Nein, schlag fest."]
const BA_HUETER := ["Mahaf. Er sieht sich um, als suche er jemanden. Sorg dafür, dass er dich findet. Dann kämpf.",
	"Eine Mutter mit zwölf Häuten. Ich habe nur Federn, und auch die nicht alle.",
	"Ein König. Verbeug dich nicht. Er weiß nicht einmal mehr, wovor.",
	"Er sagt nichts. Ich sage für euch beide genug. Geh."]
# nach der Entscheidung über das Fundstück: [für Maat, für Isfet]
const BA_WAHL := [
	["Ein Ruder für einen Fährmann, den du eben besiegt hast. Du bist ein seltsamer Mensch. Ich mag das.",
		"Zeder brennt schön, das muss man ihr lassen. Mahaf hätte es anders gesehen."],
	["Du hast Brot hergegeben, das du nicht essen musstest. Die Götter merken sich so etwas. Ich auch.",
		"Satt? Nein. Geheilt? Ja. Ich würde das nicht Mahlzeit nennen."],
	["Du wirst einen Namen laut sagen. Übe vorher. Könige mögen es nicht, wenn man stottert.",
		"Gute Händler, diese Grabräuber. Sie haben nicht einmal gefeilscht. Das hätte dich stutzig machen sollen."],
	["Er sieht nach Norden. Ich sehe ihn an. Du siehst mich an. Alle sehen irgendwohin, und das ist gut.",
		"Deine Laterne schlägt jetzt doppelt. Ich höre es. Schlafen wird schwierig, falls Tote schlafen."]]
# Rückbezug: Einige Zeit nach der Ankunft erinnert der Ba an eine Entscheidung aus einer früheren Stunde
const BA_RUECK := {
	2: [{"wahl": "1", "maat": "Das Ruder auf deinem Rücken klopft bei jedem Schritt. Wie ein sehr höflicher Specht.",
		"isfet": "Deine Laterne riecht nach Zeder. Ich sage nichts. Ich rieche nur."}],
	3: [{"wahl": "2", "maat": "Seit dem Feld riecht deine Laterne nach Brot.",
		"isfet": "Du hast gegessen und bist nicht satt geworden. Ich habe es gesehen. Ich sehe alles, ich bin ein Vogel."}],
	4: [{"wahl": "3h", "kartusche": "In einer Wand steht wieder ein Name. Sie hat geseufzt. Ich habe es gehört.",
		"wand": "Deine Hand ist noch warm von der Wand. Ich weiß nicht, wer sie war. Du schon, glaube ich."},
		{"wahl": "3", "maat": "Ein König weiß wieder, wie er heißt. Ich weiß meinen übrigens auch nicht. Ich bin nur „dein Ba“.",
		"isfet": "Dein Beutel klimpert. Ich habe beschlossen, es für Musik zu halten."}],
}
# nach dem ersten Gespräch mit dem Gast der Stunde
const BA_GAST := {2: "Ein General. Ich habe mich gerade aufrecht hingestellt, ohne es zu wollen.",
	3: "Ein Bart, gebunden mit zwei Schnüren. Meine Federn sind angewachsen. Ich weiß nicht, wer von uns es leichter hat.",
	4: "Er sieht zu, wie man kämpft, wenn man nicht General ist. Gib ihm etwas zu sehen."}

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
	return stapel[key].pop_back()

static func bisher(stunde: int) -> String:
	return BISHER[stunde - 1] if stunde >= 1 and stunde <= BISHER.size() else ""
