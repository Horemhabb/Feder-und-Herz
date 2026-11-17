class_name Geschichte
# Die Geschichte der Fassung 2.0: In jeder Stunde wartet eine Figur am Eingang, erzählt ihren Teil und bittet um ein
# Fundstück. Wer es findet, entscheidet, was damit geschieht. Jede Entscheidung legt Gewicht auf die Herzwaage
# (Spiel.herz: über null ist das Herz leicht wie die Feder der Maat, unter null schwer von Isfet).
# Der rote Faden: Der Laternenträger ist im Herbst am Fieber gestorben. Die Priester haben ihm sein Herz gelassen und die
# Laterne in die Hände gelegt, denn nur Tote kommen durch das Tor des Westens. Der Sammler, einst einer der zweiundvierzig
# Richter, hat die Waage angehalten, damit niemand mehr von der Fresserin verschlungen wird. Nach der fünften Stunde wird
# das Herz des Laternenträgers als erstes wieder gewogen; das Urteil fällt am Tor des Ostens.
#
# Lohn einer Entscheidung: "segen" (der Hüter verliert ein Fünftel seines Lebens), "xp", "trank" (Rotbier aufgefüllt, geheilt),
# "scherben", "beute" (seltenes Teil), "legende" (legendäres Teil)

const H := [
	{   # 1 · Das Tor des Westens
		"wer": "Senu", "bild": "P01", "titel": "Wächter am Tor des Westens", "model": "Skeleton_Warrior", "tint": Color(0.75, 0.85, 0.8),
		"gruss": ["Halt. Niemand geht durch das Tor des Westens, solange ich hier stehe. So lautete mein Befehl, und er wurde nie aufgehoben.",
			"Aber sieh dich um. Sie gehen nicht hindurch, sie kommen nicht einmal mehr an. Die Lichter dort oben sind die Toten von Sandtor. Mahaf, der Fährmann, sollte sie übersetzen. Stattdessen führt er sie im Kreis, Nacht für Nacht."],
		"fragen": [["Wer hat dir den Befehl gegeben?", "Ein König, dessen Namen ich vergessen habe. Das ist seltsam. Ich vergesse sonst nichts. Ich stehe hier seit vierhundert Überschwemmungen und kenne jedes Sandkorn."],
			["Warum lässt du mich dann durch?", "Weil nur Tote durch dieses Tor kommen, Laternenträger, und du bist schon halb hindurch. Sieh mich nicht so an. Frag die, die dir die Laterne in die Hände gelegt haben."]],
		"quest": "Mahafs Ruder", "auftrag": "Ohne sein Ruder ist Mahaf kein Fährmann. Es liegt irgendwo im Sand jenseits der Mauer.",
		"relikt": "Mahafs Ruder", "fund": "Ein Ruder aus Zedernholz, halb im Sand begraben. Das Blatt ist glatt gegriffen von tausend Überfahrten. Es zieht in deiner Hand nach Westen, als wüsste es den Weg.",
		"wahl": [["Das Ruder für Mahaf aufheben", "Du bindest es dir auf den Rücken. Wenn der Fährmann fällt, soll er es wiederhaben. Wer ohne sein Werkzeug stirbt, findet auch im Tod keine Ruhe.", 8, "segen"],
			["Das Zedernholz in der Laterne verbrennen", "Zeder brennt hell und lange. Die Flamme schlägt hoch, und für einen Augenblick siehst du jedes Licht über Sandtor zusammenzucken.", -8, "beute"]],
		"ba": "Die Lichter kennen dich. Hörst du? Sie rufen einen Namen, und es ist deiner.",
	},
	{   # 2 · Die Felder von Wernes
		"wer": "Merit", "bild": "P02", "titel": "Schnitterin der Seligen", "model": "Rogue", "tint": Color(0.55, 0.95, 0.9),
		"gruss": ["Leise. Sie hören das Korn rascheln.",
			"Hier haben wir geschnitten, wir Gerechtfertigten. Jeder Halm stand sieben Ellen hoch. Dann kam die Brut und häutete sich zwischen den Garben, und jetzt wächst hier nur noch, was Apophis abstreift."],
		"fragen": [["Wie sind sie hereingekommen?", "Jemand hat das Feldtor von innen geöffnet. Am Riegel klebt Siegelwachs. Ein Königsring, aber der Name darin ist herausgekratzt."],
			["Du siehst mich seltsam an.", "Dein Atem beschlägt das Glas deiner Laterne nicht. Meiner auch nicht. Ich dachte nur, du wüsstest es."]],
		"quest": "Die erste Garbe", "auftrag": "Irgendwo in den Ruinen liegt noch die erste Garbe der Ernte. Sie gehört auf den Opfertisch, nicht in den Staub.",
		"relikt": "Die erste Garbe", "fund": "Eine Garbe Gerste, schwer und golden, als wäre sie eben geschnitten. Sie riecht nach Brot. Du hast seit dem Herbst nichts gegessen, fällt dir ein, und nie Hunger gehabt.",
		"wahl": [["Die Garbe den Göttern opfern", "Du legst sie nieder und sprichst die Formel, so gut du sie kennst. Über das Feld hinweg nickt Merit dir zu. Etwas in deiner Brust wird leichter.", 10, "xp"],
			["Das Korn selbst essen", "Es schmeckt nach nichts. Aber deine Wunden schließen sich, und an deinem Gurt hängen Krüge, die vorher nicht da waren.", -8, "trank"]],
		"ba": "Hier roch es einmal nach Brot. Erinnerst du dich an Brot?",
	},
	{   # 3 · Der König ohne Namen
		"wer": "Chaemwese", "bild": "P03", "titel": "Schreiber des Grabes", "model": "Skeleton_Mage", "tint": Color(0.95, 0.85, 0.65),
		"gruss": ["Tritt nicht auf die Splitter. Das sind Buchstaben.",
			"Ich habe seinen Namen aus diesen Wänden geschlagen, jeden einzelnen. Er hat es mir selbst befohlen, und ich habe nicht gefragt, warum. Ein Schreiber fragt nicht. Jetzt liegt er wach und weiß nicht mehr, wer er ist."],
		"fragen": [["Warum befiehlt ein König so etwas?", "Wer keinen Namen hat, wird nicht aufgerufen. Wer nicht aufgerufen wird, wird nicht gewogen. Er hatte Angst vor der Waage. Die meisten Könige haben Grund dazu."],
			["Kennst du meinen Namen?", "Ich habe ihn im Herbst geschrieben. Auf eine Liste des Sonnentempels, mit roter Tinte. Rot ist die Farbe für … Verzeih. Ein Schreiber redet zu viel, wenn er vierhundert Jahre allein war."]],
		"quest": "Die Namensscherbe", "auftrag": "Eine einzige Kartusche hat Chaemwese damals nicht zerschlagen, sondern versteckt. Finde die Scherbe mit dem Namen des Königs.",
		"relikt": "Die Namensscherbe", "fund": "Ein Stück Kalkstein, groß wie eine Hand. In der Kartusche stehen fünf Zeichen, sauber und tief. Im ganzen Totenreich bist du gerade der einzige Mensch, der den Namen dieses Königs kennt.",
		"wahl": [["Dem König seinen Namen zurückgeben", "Du wirst ihn laut aussprechen, wenn du vor ihm stehst. Wer gerufen wird, muss antworten. Auch ein König. Auch vor der Waage.", 12, "segen"],
			["Die Scherbe an die Grabräuber verkaufen", "Ein Königsname ist viel wert bei denen, die mit Namen handeln. Es klimpert in deinem Beutel. Der König wird weiter wach liegen.", -12, "scherben"]],
		"ba": "Lies die Wände nicht. Was fehlt, ist das Wichtige.",
	},
	{   # 4 · Rosetau
		"wer": "Ein Erloschener", "bild": "P04", "mit": "dem Erloschenen", "titel": "einst ein Unvergänglicher Stern", "model": "Mage", "tint": Color(0.6, 0.7, 0.85),
		"gruss": ["Du trägst Licht. Halt es nicht so hoch. Es tut weh, sich zu erinnern.",
			"Wir waren die Sterne, die niemals untergehen. Wir zogen die Barke über Sokars Sand. Dann kam einer und sagte: Gebt mir eure Herzen, und ihr werdet nie gewogen. Wir wussten nicht, dass ein Stern ohne Herz erlischt."],
		"fragen": [["Wer war das?", "Er trug den Schurz eines Richters. Einer der Zweiundvierzig. Er weinte, als er die Krüge verschloss. Das habe ich nie verstanden."],
			["Hörst du den Krug in meiner Tasche?", "Den höre ich. Aber da schlägt noch etwas, Laternenträger, und es schlägt nicht in deiner Brust. Es schlägt in deiner Laterne. Was haben die Priester dir da hineingelegt?"]],
		"quest": "Das Sternenherz", "auftrag": "Zwischen dem Glas liegt ein Herz, das noch glimmt. Es gehört einem der Erloschenen.",
		"relikt": "Ein Sternenherz", "fund": "Es ist kalt wie Glas und leicht wie Asche, und tief innen glimmt es noch. Ein Herz, das nie gewogen wurde. Es würde gut brennen.",
		"wahl": [["Das Herz dem Stern zurückgeben", "Du legst es dem Erloschenen in die Hände. Er leuchtet nicht auf. Aber er hebt den Kopf, zum ersten Mal, und sieht nach Norden, wo sein Platz am Himmel leer ist.", 14, "xp"],
			["Das Herz in die Laterne legen", "Die Flamme wird weiß. Deine Schläge fallen schwerer, deine Hände sicherer. Irgendwo hinter dir sinkt ein Kopf zurück auf die Brust.", -14, "legende"]],
		"ba": "Sieh nicht nach oben. Da ist nichts mehr.",
	},
	{   # 5 · Die Höhle des Sokar
		"wer": "Ein alter Richter", "bild": "P05", "mit": "dem alten Richter", "titel": "der Schatten des Sammlers", "model": "Mage", "tint": Color(0.75, 0.55, 0.95),
		"gruss": ["Setz dich, Laternenträger. Du bist weit gegangen für jemanden, der im Herbst gestorben ist.",
			"Ja. Am Fieber, wie die halbe Stadt. Die Priester haben dich gewaschen und gesalbt und dir die Laterne in die Hände gelegt, bevor du kalt warst. Nur Tote kommen durch das Tor, und nur wer es nicht weiß, geht ohne Furcht. Sie haben dich benutzt. Ich benutze niemanden. Ich bewahre."],
		"fragen": [["Warum hast du die Waage angehalten?", "Ich saß zweiundvierzigtausend Nächte zu Gericht. Ich habe gesehen, wie die Fresserin Herzen verschlang, die nur müde waren, nicht böse. Eines davon gehörte meiner Tochter. Da stand ich auf. Seitdem wird niemand mehr verschlungen. Nenn mir eine größere Gnade."],
			["Und die Sonne?", "Die Sonne ist der Preis. Ohne Gerechtfertigte zieht niemand die Barke, ich weiß. Ich habe gewogen, das ist alles, was ich je getan habe: tausend Herzen gegen einen Morgen. Die Waage steht nicht still, Laternenträger. Sie steht bei mir."]],
		"quest": "Der Krug mit deinem Namen", "auftrag": "Tief in der Höhle steht ein leerer Krug. Der Richter sagt, er warte schon lange auf dich.",
		"relikt": "Der Krug mit deinem Namen", "fund": "Er ist aus Alabaster und sehr sauber gearbeitet. Auf dem Siegel steht dein Name. Der Krug ist leer und ein wenig warm, als hätte jemand lange die Hände darum gelegt. Dein Herz ist das einzige in ganz Sandtor, das der Sammler nicht bekommen hat. Die Priester haben es dir gelassen. Es brennt in deiner Laterne.",
		"wahl": [["Den Krug zerschlagen", "Alabaster splittert leicht. Du wirst gewogen werden wie alle anderen, und du weißt nicht, wie es ausgeht. Das ist der Sinn einer Waage.", 16, "segen"],
			["Den Krug mitnehmen", "Man weiß nie. Ein Herz, das nicht gewogen wird, kann auch nicht zu schwer sein. Du verstehst den alten Richter jetzt ein wenig besser, und das gefällt dir nicht.", -16, "legende"]],
		"ba": "Es schlägt, tausendfach. Und ein Krug ist still. Geh nicht zu ihm. Geh doch zu ihm.",
	},
	{   # 6 · Der Leib des Osiris
		"wer": "Isis", "titel": "die Klagende", "model": "Mage", "tint": Color(0.6, 1.0, 0.75),
		"gruss": ["Sprich leise. Er schläft nicht, er wartet.",
			"Auf dem Lager meines Bruders liegt einer, der dort nicht hingehört. Solange er liegt, können Re und Osiris einander nicht begegnen, und die Sonne wird nicht jung."],
		"fragen": [["Du weißt, was ich bin.", "Tot, ja. Das sind hier alle, die etwas taugen. Die Frage ist, was du daraus machst. Ich habe aus einem toten Mann einen König der Ewigkeit gemacht. Du hast nur eine Barke zu ziehen."]],
		"quest": "Das Leinen des Osiris", "auftrag": "Ein Streifen vom Leinen des Osiris ist vom Lager gerissen worden. Isis will ihn zurück.",
		"relikt": "Das Leinen des Osiris", "fund": "Ein Streifen feinsten Leinens, getränkt mit Harz und Myrrhe. Wo du ihn anfasst, hören deine Hände auf zu zittern.",
		"wahl": [["Das Leinen zurück auf das Lager legen", "Du faltest es so sorgfältig, wie die Priester im Herbst dein eigenes gefaltet haben müssen.", 8, "xp"],
			["Die eigenen Wunden damit verbinden", "Es heilt alles, was es berührt. Dafür war es gemacht. Nur nicht für dich.", -8, "trank"]],
		"ba": "Tiefer geht es nicht. Von hier an führt jeder Schritt zum Morgen.",
	},
	{   # 7 · Die Sandbank des Apophis
		"wer": "Selket", "titel": "die atmen lässt", "model": "Rogue", "tint": Color(0.95, 0.8, 0.45),
		"gruss": ["Halt die Laterne tiefer. Er sieht durch das Licht.",
			"Seth hält den Speer, Isis spricht die Worte, ich halte die Fessel. So war es jede Nacht. Heute fehlt die Fessel. Ohne sie wird aus dem Kampf ein Gemetzel, und zwar an uns."],
		"fragen": [["Kann man ihn töten?", "Nein. Man kann ihn nur jede Nacht besiegen. Das ist kein Trost, ich weiß. Aber es ist eine Arbeit, und Arbeit ist mehr, als die meisten Toten haben."]],
		"quest": "Selkets Fessel", "auftrag": "Die Fessel für die Schlange ist im Sand verloren gegangen. Ohne sie hält Apophis niemand.",
		"relikt": "Selkets Fessel", "fund": "Ein Strick aus Kupferdraht und Skorpionschwänzen, schwer und kalt. Er windet sich in deiner Hand wie etwas, das beißen möchte.",
		"wahl": [["Die Fessel der Göttin bringen", "Selket nimmt sie ohne ein Wort und prüft jeden Knoten. Dann nickt sie nach Westen, wo es sich im Sand bewegt.", 8, "segen"],
			["Die Fessel um die eigene Waffe wickeln", "Jeder Schlag brennt jetzt wie ein Stich. Am Bug der Barke steht eine Göttin mit leeren Händen.", -10, "beute"]],
		"ba": "Sieben Stunden hat er gesagt. Hier ist die, vor der die Klagefrauen warnen.",
	},
	{   # 8 · Die Grüfte der Götter
		"wer": "Der Große Kater", "mit": "dem Großen Kater", "titel": "Re in seiner Gestalt von Heliopolis", "model": "Barbarian", "tint": Color(1.0, 0.8, 0.5),
		"gruss": ["Du riechst nach Zedernöl und Natron. Frisch balsamiert. Wie nett.",
			"Wenn ich an den Grüften vorüberfahre, antwortet es von drinnen: wie ein Kater, wie ein Schwarm Bienen, wie ein Stier. Aus einer Gruft kommt kein Laut mehr. Ich mag keine Stille. Stille ist, was Apophis übrig lässt."],
		"fragen": [["Warum hilfst du nicht selbst?", "Ich bin die Sonne, Kind. Ich bin alt, es ist Nacht, und ich bin auf dem Weg, wieder jung zu werden. Bis dahin bin ich auf Leute mit Laternen angewiesen."]],
		"quest": "Die Wabe aus der Gruft", "auftrag": "In einer der Grüfte summt es nicht mehr. Eine Honigwabe liegt irgendwo im Dunkeln.",
		"relikt": "Eine Honigwabe", "fund": "Sie ist schwer und golden und summt leise, obwohl keine Biene darin ist. Es ist die Stimme einer Gruft.",
		"wahl": [["Die Wabe in die stumme Gruft legen", "Erst ist es still. Dann beginnt es hinter dem Stein zu summen, tief und zufrieden.", 8, "xp"],
			["Den Honig essen", "Er ist süßer als alles, was du lebend gekostet hast. Die Stille hinter dir wird ein wenig größer.", -8, "trank"]],
		"ba": "Hör hin. Es klingt wie ein Kater. So soll es klingen.",
	},
	{   # 9 · Die Ruderer
		"wer": "Der elfte Ruderer", "mit": "dem elften Ruderer", "titel": "auf der Bank neben der leeren", "model": "Knight", "tint": Color(0.7, 0.8, 1.0),
		"gruss": ["Elf Ruder. Zähl nach, wenn du willst. Ich habe die ganze Nacht nichts anderes getan.",
			"Der Zwölfte saß neben mir, seit es die Barke gibt. Sein Ba ist ausgeflogen und hat die Bank nicht wiedergefunden. Jetzt irrt er als Licht durch die Gänge und schlägt nach allem, was ihn ruft."],
		"fragen": [["Erkennt er dich noch?", "Er erkennt sein Ruder. Mehr braucht ein Ruderer nicht zu erkennen."]],
		"quest": "Das zwölfte Ruder", "auftrag": "Das Ruder des zwölften Ruderers liegt irgendwo in den Gängen.",
		"relikt": "Das zwölfte Ruder", "fund": "Wieder ein Ruder. Diesmal weißt du, was du in der Hand hältst, und was du bist, und was es heißt, etwas zurückzubringen.",
		"wahl": [["Das Ruder auf die leere Bank legen", "Der elfte Ruderer rückt ein Stück zur Seite, wie man es für jemanden tut, der gleich kommt.", 8, "segen"],
			["Das Ruder zerbrechen", "Es splittert der Länge nach. Aus dem Holz fällt, was ein Ruderer in tausend Nächten darin versteckt.", -10, "beute"]],
		"ba": "Wasser. Hörst du es? Noch nicht. Aber bald.",
	},
	{   # 10 · Die Ertrunkenen im Nun
		"wer": "Horus", "titel": "der die Ertrunkenen ans Ufer zieht", "model": "Knight", "tint": Color(0.6, 0.9, 1.0),
		"gruss": ["Wer im Fluss blieb, bekam kein Grab und keinen Namen auf einem Stein. Ich rufe sie trotzdem.",
			"Auch sie haben ein Recht auf die Waage. Du weißt inzwischen, was das heißt: ein Recht darauf, nicht zu wissen, wie es ausgeht. Einer hält sich am Grund fest. Er war einmal ein König und will nicht an Land."],
		"fragen": [["Hattest du nie Angst vor der Waage?", "Ich bin ein Gott. Wir werden nicht gewogen. Das ist kein Vorzug. Frag den Sammler, was aus einem wird, der immer nur wiegt und nie gewogen wird."]],
		"quest": "Ein Name im Schlamm", "auftrag": "Am Ufer liegt ein Tonsiegel mit dem Namen eines Ertrunkenen. Ohne Namen kann Horus ihn nicht rufen.",
		"relikt": "Ein Tonsiegel", "fund": "Ein Klumpen Nilschlamm, hart gebrannt. Ein Name ist hineingedrückt, mit dem Daumen, in Eile. Jemand wollte, dass man sich erinnert.",
		"wahl": [["Den Namen über das Wasser rufen", "Du rufst ihn dreimal. Beim dritten Mal teilt sich das Wasser, und etwas watet müde ans Ufer.", 10, "xp"],
			["Das Siegel zu Staub zerreiben", "Fayencestaub und Scherben, mehr ist ein Name nicht, wenn man ihn zerreibt.", -8, "scherben"]],
		"ba": "Du hattest ein Grab. Vergiss das nicht. Jemand hat dich gewaschen.",
	},
	{   # 11 · Die Feuergruben
		"wer": "Die mit dem Messer", "mit": "der Göttin mit dem Messer", "titel": "Göttin am Rand der Grube", "model": "Rogue", "tint": Color(1.0, 0.55, 0.4),
		"gruss": ["Nicht so nah an den Rand. Die Hitze nimmt, was sie kriegen kann.",
			"Hier endet, wer gegen die Ordnung stand. Es gefällt mir nicht. Es muss mir nicht gefallen. Eine ist herausgekrochen, und ich verstehe sie gut, aber wenn die Grube nicht hält, hält gar nichts."],
		"fragen": [["Der Sammler nannte das Grausamkeit.", "Der Sammler hat recht. Und er hat tausend Sterne gelöscht und die Sonne angehalten, um recht zu behalten. Gnade ohne Ordnung ist auch nur ein Feuer."]],
		"quest": "Ein Herz am Grubenrand", "auftrag": "Etwas Kleines ist aus der Grube gekrochen und versteckt sich. Die Göttin will wissen, was du damit tust.",
		"relikt": "Ein verurteiltes Herz", "fund": "Es ist versengt und sehr klein. Als du es aufhebst, schlägt es schneller, wie ein Vogel in der Hand. Es wurde gewogen und für zu schwer befunden. Du kennst das Urteil nicht. Nur das Herz.",
		"wahl": [["Das Urteil vollstrecken", "Du trägst es zurück. Die mit dem Messer sieht weg, als du es fallen lässt. Ordnung ist etwas, das jemand tun muss.", 8, "xp"],
			["Das Herz heimlich einstecken", "Es wird ruhig an deiner Brust. So also hat es beim Sammler angefangen: mit einem.", -12, "legende"]],
		"ba": "Am Rand des Himmels wird es grau. Siehst du es? Fast.",
	},
	{   # 12 · Das Tor des Ostens
		"wer": "Schu", "titel": "der die Sonne hebt", "model": "Barbarian", "tint": Color(0.8, 0.9, 1.0),
		"gruss": ["Da bist du. Meine Arme werden lahm.",
			"Hinter diesem Tor ist Morgen. Davor steht einer, den du schon einmal besiegt hast. Sein Herz ist gewogen. Sein Schatten wusste nichts davon und tut, was Schatten tun: Er bleibt. Und dann bist du an der Reihe, Laternenträger. Thot hat die Binse schon eingetaucht."],
		"fragen": [["Was geschieht mit mir?", "Das hängt davon ab, was du unterwegs aufgehoben und was du liegen gelassen hast. So einfach ist das. So schwer."]],
		"quest": "Die Feder der Maat", "auftrag": "Vor dem Tor liegt etwas Weißes im Staub. Schu sagt, es dürfe dort nicht liegen.",
		"relikt": "Die Feder der Maat", "fund": "Sie liegt einfach da, als hätte jemand sie verloren. Eine Straußenfeder, weiß und schwerelos. Gegen sie wird jedes Herz gewogen. Gleich auch deins.",
		"wahl": [["Die Feder zurück auf die Waage legen", "Du legst sie auf die Schale und trittst zurück. Sie wiegt nichts. Sie wiegt alles. Thot nickt.", 12, "segen"],
			["Ein Körnchen Blei in den Kiel drücken", "Niemand sieht es. Kein Herz wird je wieder zu schwer sein, auch deins nicht. Irgendwo, sehr weit unten, lacht ein alter Richter und weint dabei.", -25, "legende"]],
		"ba": "Wenn sie dich rufen, antworte. Egal wie es ausgeht. Antworte.",
	},
]

# ---------------------------------------------------------------- Leute und ihre Sorgen
# Neben der großen Geschichte gibt es in jeder Stunde jemanden mit einem ganz gewöhnlichen Kummer: Der Hirte sucht seine
# Schafe, die Bäuerin ihre Saatsäcke, das Kind die Kätzchen. Drei Dinge liegen oder laufen irgendwo in der Stunde herum.
# ding: schaf, esel, ziege (Tiere) · sack, korb (Säcke) · kiste (Werkzeug) · krug (Wasser) · katze
const LEUTE := [
	{"wer": "Djau", "bild": "P06", "titel": "Schafhirte aus Sandtor", "model": "Barbarian", "ding": "schaf", "was": "Schafe", "eins": "Ein Schaf",
		"gruss": "Du da, mit der Lampe! Hast du meine Schafe gesehen? Drei Stück. Die Lichter am Himmel haben sie erschreckt, und weg waren sie. Ohne die Schafe brauche ich gar nicht erst heimzukommen.",
		"fund": "Es sieht dich vorwurfsvoll an und trottet dann von selbst zum Hirten zurück.",
		"dank": "Alle drei, auch die Dicke! Ich habe nicht viel, aber das hier habe ich im Sand gefunden. Nimm es, du kannst es besser brauchen."},
	{"wer": "Ipi", "bild": "P07", "titel": "Bäuerin", "model": "Rogue", "ding": "sack", "was": "Saatsäcke", "eins": "Ein Sack Gerste",
		"gruss": "Die Biester haben mir die Saat verschleppt. Drei Säcke Gerste. Wenn die weg sind, gibt es nächstes Jahr kein Brot, ganz gleich in welcher Welt.",
		"fund": "Schwer, aber heil. Du stellst ihn so hin, dass Ipi ihn vom Weg aus sieht.",
		"dank": "Das reicht für ein ganzes Feld. Hier, das lag zwischen den Halmen. Ich kann damit nichts anfangen."},
	{"wer": "Hori", "bild": "P08", "titel": "Steinmetz", "model": "Barbarian", "ding": "kiste", "was": "Werkzeugkisten", "eins": "Eine Werkzeugkiste",
		"gruss": "Ich habe mein Werkzeug fallen lassen, als die Toten aufstanden. Hättest du auch. Meißel, Schlegel, Lot: drei Kisten. Ohne Werkzeug bin ich nur ein Mann mit starken Armen.",
		"fund": "Kupfermeißel, sauber geschliffen. Wer so mit Werkzeug umgeht, will es wiederhaben.",
		"dank": "Nichts fehlt. Sogar das Lot hängt noch gerade. Das hier habe ich aus einer Wand gebrochen, bevor ich wusste, wem sie gehört. Nimm du es."},
	{"wer": "Tia", "bild": "P09", "titel": "Wasserträgerin", "model": "Rogue", "ding": "krug", "was": "Wasserkrüge", "eins": "Ein Wasserkrug",
		"gruss": "Hier gibt es kein Wasser, also habe ich meines mitgebracht. Drei Krüge. Dann kam so ein graues Ding auf mich zu, ich bin gerannt, und jetzt stehen die Krüge irgendwo da drin.",
		"fund": "Noch voll, noch kühl. Du trinkst einen Schluck. Das wird sie dir verzeihen.",
		"dank": "Du hast daraus getrunken, das sehe ich. Macht nichts, dafür ist es da. Hier, das habe ich unterwegs aufgelesen."},
	{"wer": "Nefru", "bild": "P10", "titel": "ein Kind", "model": "Mage", "klein": true, "ding": "katze", "was": "Kätzchen", "eins": "Ein Kätzchen",
		"gruss": "Meine Katze hat Junge gekriegt, und die sind weggelaufen. Drei. Die Katze sucht auch schon, aber sie kann nicht so gut zählen.",
		"fund": "Es faucht dich an, so gut es kann, und läuft dann mit steilem Schwanz nach Hause.",
		"dank": "Eins, zwei, drei! Die Katze sagt danke. Sie hat dir was mitgebracht. Ich glaube, es war mal eine Maus, aber das hier glänzt mehr."},
	{"wer": "Chui", "titel": "Eseltreiber", "model": "Barbarian", "ding": "esel", "was": "Esel", "eins": "Ein Esel",
		"gruss": "Meine Esel sind klüger als ich. Als es hier unheimlich wurde, sind sie weggelaufen. Ich bin geblieben. Drei Stück, graue.",
		"fund": "Er lässt sich lange bitten. Dann geht er, als wäre es seine eigene Idee gewesen.",
		"dank": "Da sind sie ja, die Schlauköpfe. Hier, das hing an einem Sattel. Meins ist es nicht."},
	{"wer": "Meni", "titel": "Fischer", "model": "Rogue", "ding": "korb", "was": "Reusen", "eins": "Eine Reuse",
		"gruss": "Seit das Wasser weg ist, fange ich nichts mehr. Aber die Reusen will ich trotzdem zurück. Drei habe ich ausgelegt. Man hofft ja.",
		"fund": "Leer, natürlich. Aber ordentlich geflochten.",
		"dank": "Wenn das Wasser zurückkommt, bin ich bereit. In einer war das hier. Kein Fisch, aber immerhin."},
	{"wer": "Baket", "titel": "Bäckerin", "model": "Rogue", "ding": "korb", "was": "Brotkörbe", "eins": "Ein Brotkorb",
		"gruss": "Ich wollte den Leuten in den Grüften Brot bringen. Dann hat etwas gebrüllt, und ich habe die Körbe fallen lassen. Drei Körbe. Das Brot ist noch gut, wenn du dich beeilst.",
		"fund": "Es riecht nach Kümmel. Du nimmst nichts davon. Fast nichts.",
		"dank": "Es fehlt eine Ecke. Ich sage nichts. Hier, das hat mir jemand statt Bezahlung gegeben."},
	{"wer": "Senbi", "titel": "Zimmermann der Barke", "model": "Barbarian", "ding": "kiste", "was": "Werkzeugkisten", "eins": "Eine Werkzeugkiste",
		"gruss": "Die Ruderbänke knarren, und ich komme nicht an mein Werkzeug. Drei Kisten, irgendwo in den Gängen. Zwölf Ruderer auf losen Bänken, das geht nicht gut.",
		"fund": "Dechsel, Bohrer, Holznägel. Alles da.",
		"dank": "Jetzt hält die Bank auch den Dicksten. Das hier lag unter einer Planke. Seit wie lange, will ich gar nicht wissen."},
	{"wer": "Iti", "titel": "Wäscherin", "model": "Rogue", "ding": "korb", "was": "Wäschekörbe", "eins": "Ein Wäschekorb",
		"gruss": "Ich wasche seit vierzig Jahren am Ufer, und noch nie ist mir die Wäsche weggeschwommen. Heute gleich drei Körbe. Leinen von guten Leuten!",
		"fund": "Nass, aber sauber. Du wringst nichts aus. Das macht sie lieber selbst.",
		"dank": "Kein Hemd fehlt. Das hier war in einer Tasche eingenäht. Den Besitzer gibt es nicht mehr, glaube ich."},
	{"wer": "Pepi", "titel": "Ziegenjunge", "model": "Mage", "klein": true, "ding": "ziege", "was": "Ziegen", "eins": "Eine Ziege",
		"gruss": "Die Ziegen mögen das Feuer nicht. Ich auch nicht. Drei sind mir ausgebüxt. Mein Vater zählt jeden Abend nach.",
		"fund": "Sie versucht, an deinem Gurt zu knabbern, und springt dann davon, Richtung Junge.",
		"dank": "Drei! Vater merkt nichts. Das hier hat die Braune ausgespuckt. Du kannst es haben."},
	{"wer": "Henut", "titel": "Nachbarin", "model": "Rogue", "ding": "katze", "was": "Katzen", "eins": "Eine Katze",
		"gruss": "Bald geht die Sonne auf, und meine drei Katzen sind noch draußen. Sie kommen sonst immer vor dem Morgen heim. Heute ist nichts wie sonst.",
		"fund": "Sie tut, als hätte sie dich nicht gesehen, und geht dann sehr würdevoll nach Hause.",
		"dank": "Alle drei vor Sonnenaufgang. So gehört sich das. Hier, das hat eine von ihnen angeschleppt."},
]

static func leute(n: int) -> Dictionary:
	return LEUTE[Stunden.hour_of(n) - 1]

static func def(n: int) -> Dictionary:
	return H[Stunden.hour_of(n) - 1]

# ---------------------------------------------------------------- Herzwaage
const LEICHT := 25.0
const SCHWER := -25.0

static func herz_name(h: float) -> String:
	if h >= 60.0:
		return "leicht wie die Feder"
	if h >= LEICHT:
		return "leicht"
	if h <= -60.0:
		return "schwer von Isfet"
	if h <= SCHWER:
		return "schwer"
	return "in der Schwebe"

static func herz_wirkung(h: float) -> String:
	if h >= 60.0:
		return "Kraft kehrt schneller zurück (+4), Laterne leuchtet ein Viertel weiter, Erfahrung +20 %"
	if h >= LEICHT:
		return "Kraft kehrt schneller zurück (+2), Laterne leuchtet weiter, Erfahrung +10 %"
	if h <= -60.0:
		return "Schaden +20 %, Scherben +50 %, aber Leben −10 %"
	if h <= SCHWER:
		return "Schaden +10 %, Scherben +25 %"
	return "Noch neigt sich die Waage nicht. Entscheidungen, Feuerschalen und Seelenkrüge legen Gewicht darauf."

# Urteil nach der fünften Stunde (die Waage bewegt sich wieder) und am Tor des Ostens (Ende der Nacht)
static func urteil(n: int) -> String:
	var h: float = Spiel.herz
	var hour := Stunden.hour_of(n)
	if hour == 5:
		if h >= LEICHT:
			return "Thot ruft einen Namen, und es ist deiner. Dein Herz liegt auf der Schale, und die Feder sinkt. Du bist tot, Laternenträger, das weißt du jetzt. Aber die Waage neigt sich zu dir. Bring die Barke zum Morgen, dann schreibt er es auf."
		if h <= SCHWER:
			return "Thot ruft einen Namen, und es ist deiner. Die Schale mit deinem Herzen sinkt, und am Fuß der Waage hebt die Fresserin den Kopf. Thot legt die Hand auf die Schale. „Noch nicht. Die Barke braucht jede Hand. Sieben Stunden hast du, um leichter zu werden.“"
		return "Thot ruft einen Namen, und es ist deiner. Dein Herz liegt auf der Schale, und die Waage zittert und bleibt in der Schwebe. Thot wartet mit der Binse. „Sieben Stunden bis zum Morgen. Zeig mir bis dahin, wohin sie sich neigt.“"
	if hour == 12:
		if h >= LEICHT:
			return "DAS URTEIL: WAHR AN STIMME. Die Feder sinkt, dein Herz steigt. Thot schreibt deinen Namen in das Buch, und Schu hebt dich mit der Sonne über den Horizont. In Sandtor wird es Morgen. Im Norden, wo ein Platz am Himmel leer war, geht ein Stern auf, der nie mehr untergeht."
		if h <= SCHWER:
			return "DAS URTEIL: ZU SCHWER. Die Schale sinkt. Die Fresserin steht auf. Da tritt ein Schatten zwischen euch, und er trägt den Schurz eines Richters. „Jetzt verstehst du mich“, sagt er und hält dir einen Krug hin. Auf dem Siegel steht dein Name. Die Nacht beginnt von vorn, und diesmal trägst du keine Laterne. Du trägst Krüge."
		return "DAS URTEIL: IN DER SCHWEBE. Die Waage findet keine Seite. Thot legt die Binse weg und sieht dich lange an. „Es fehlt ein Fährmann“, sagt er. Am Ufer liegt ein Ruder aus Zedernholz. Du kennst es. Jede Nacht kommen Lichter gegen den Wind, und einer muss sie übersetzen."
	return ""
