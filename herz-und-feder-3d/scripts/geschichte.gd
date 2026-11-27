class_name Geschichte
# Die Geschichte (Fassung 4.3, Neufassung als Thriller, siehe GESCHICHTE.md): In jeder Stunde wartet eine Figur am Eingang,
# erzählt ihren Teil und bittet um ein Fundstück. Wer es findet, entscheidet, was damit geschieht. Jede Entscheidung legt
# Gewicht auf die Herzwaage (Spiel.herz: über null leicht, unter null schwer von Isfet) und kommt später zurück
# (Feld „echo“: ein Satz in einem späteren Gespräch, je nach Spiel.wahl).
# Der rote Faden: Nebet, die Schwester der Spielfigur, liegt in Sandtor im Fieber. Das Fieber bricht im Morgengrauen,
# wenn eines kommt; unten steht die Waage still, und ohne Gewogene zieht niemand die Barke. Die Figur steigt hinab, um den
# Morgen zu holen, und weiß nicht, dass sie selbst heute Abend an Nebets Bett gestorben ist. Der Vogel auf ihrer Schulter
# nennt sich ihr Ba; er ist Nebets Ba (Mitte, Stunde 6). Der Sammler, einer der Zweiundvierzig, sammelt die Herzen von
# Sandtor in Krügen, damit keines mehr gefressen wird. Er hat auch für Nebet einen Krug.
#
# Platzhalter in allen Texten (fuell): {lt} wird zu „Laternenträger“ oder „Laternenträgerin“, je nach Klasse.
# Lohn einer Entscheidung: "segen" (der Hüter verliert ein Fünftel seines Lebens), "xp", "trank" (Rotbier aufgefüllt, geheilt),
# "scherben", "beute" (seltenes Teil), "legende" (legendäres Teil)

const H := [
	{   # 1 · Das Tor des Westens
		"wer": "Senu", "bild": "P01", "titel": "Wächter am Tor des Westens", "model": "Skeleton_Warrior", "tint": Color(0.75, 0.85, 0.8),
		"gruss": ["Halt. Durch das Tor des Westens geht niemand, solange ich stehe. So lautet mein Befehl, und keiner hat ihn je aufgehoben.",
			"Sieh nach oben. Die Lichter dort sind die Toten von Sandtor, die von dieser Woche. Mahaf, der Fährmann, soll sie übersetzen. Er führt sie im Kreis, Nacht für Nacht, denn drüben steht die Waage still. Einer der Zweiundvierzig ist von seinem Platz aufgestanden."],
		"fragen": [["Warum steht die Waage still?", "Ein Richter ist aufgestanden und nicht zurückgekommen. Seitdem wird niemand gewogen, und wer nicht gewogen ist, zieht keine Barke. Die Sonne kommt jeden Morgen später. Heute kommt sie gar nicht, wenn keiner hinuntergeht."],
			["Warum lässt du mich dann durch?", "Ich lasse niemanden durch. Ich sehe nur nicht hin, wenn einer mit einer Laterne kommt, die ohne Öl brennt."]],
		"quest": "Mahafs Ruder", "auftrag": "Ohne sein Ruder ist Mahaf kein Fährmann, nur ein Licht, das sich im Kreis dreht. Es liegt irgendwo im Sand jenseits der Mauer.",
		"relikt": "Mahafs Ruder", "fund": "Ein Ruder aus Zedernholz, halb im Sand begraben. Das Blatt ist glatt gegriffen von tausend Überfahrten. In deiner Hand zieht es nach Westen, als wüsste es den Weg besser als du.",
		"wahl": [["Das Ruder für Mahaf aufheben", "Du bindest es dir auf den Rücken. Fällt der Fährmann, soll er es wiederhaben. Wer ohne sein Werkzeug stirbt, findet auch im Tod keine Ruhe.", 8, "segen"],
			["Das Zedernholz in der Laterne verbrennen", "Zeder brennt hell und lange. Die Flamme schlägt hoch, und über Sandtor zuckt jedes Licht zusammen, als hätte es sich verbrannt.", -8, "beute"]],
		"ba": "Die Lichter rufen einen Namen. Hör nicht hin. Und halt die Laterne höher, du hältst sie immer zu tief.",
	},
	{   # 2 · Die Felder von Wernes
		"wer": "Merit", "bild": "P02", "titel": "Schnitterin der Seligen", "model": "Rogue", "tint": Color(0.55, 0.95, 0.9),
		"echo": {"1": ["Merit sieht auf deinen Rücken. „Du trägst ein Ruder. Dann glaubt da oben noch jemand, dass übergesetzt wird.“",
			"Merit schnuppert. „Du riechst nach Zeder und Rauch. Was hast du da oben verbrannt?“"]},
		"gruss": ["Leise. Sie hören das Korn rascheln.",
			"Hier haben wir geschnitten, wir Gerechtfertigten. Jeder Halm stand sieben Ellen hoch. Dann ging das Feldtor auf, von innen, und die Brut kam herein. Jetzt wächst hier nur noch, was Apophis abstreift."],
		"fragen": [["Wer hat das Tor geöffnet?", "Am Riegel klebt Siegelwachs. Ein Königsring, aber der Name darin ist herausgekratzt. Wer so etwas tut, will gefunden werden. Oder er will, dass man den Falschen findet."],
			["Ist ein Mädchen mit blauen Fingern unter den Lichtern?", "Eine Weberin? Die Lichter von Sandtor sind alle hier vorbeigezogen, und ich habe jedes angesehen. Sie ist nicht dabei. Noch nicht."]],
		"quest": "Die erste Garbe", "auftrag": "Irgendwo in den Ruinen liegt noch die erste Garbe der Ernte. Sie gehört auf den Opfertisch, nicht in den Staub.",
		"relikt": "Die erste Garbe", "fund": "Eine Garbe Gerste, schwer und golden, als wäre sie eben geschnitten. Sie riecht nach Brot. Dir fällt ein, dass du seit gestern nichts gegessen hast. Und dass du keinen Hunger hast.",
		"wahl": [["Die Garbe den Göttern opfern", "Du legst sie nieder und sprichst die Formel, so gut du sie kennst. Über das Feld hinweg nickt Merit dir zu. Etwas in deiner Brust wird leichter.", 10, "xp"],
			["Das Korn selbst essen", "Es schmeckt nach nichts. Aber deine Wunden schließen sich, und an deinem Gurt hängen Krüge, die vorher nicht da waren.", -8, "trank"]],
		"ba": "Hier roch es einmal nach Brot. Mutter hat Kümmel hineingetan, und du hast ihn immer herausgepult.",
	},
	{   # 3 · Der König ohne Namen
		"wer": "Chaemwese", "bild": "P03", "titel": "Schreiber des Grabes", "model": "Skeleton_Mage", "tint": Color(0.95, 0.85, 0.65),
		"echo": {"2": ["Chaemwese hebt die Nase. „Gerste und Weihrauch. Da oben hat jemand geopfert. Gut. Hier unten opfert keiner mehr.“",
			"Chaemwese sieht auf deinen Mund. „Du hast Korn zwischen den Zähnen. Gerste der Seligen. Sie macht keinen satt, der sie nimmt.“"]},
		"gruss": ["Tritt nicht auf die Splitter. Das sind Buchstaben.",
			"Ich habe seinen Namen aus diesen Wänden geschlagen, jeden einzelnen. Er hat es befohlen, und ein Schreiber fragt nicht. Jetzt liegt er wach und weiß nicht mehr, wer er ist. Vor dir war ein General hier. Er hat die Splitter gezählt und nichts gesagt."],
		"fragen": [["Hat der König das Feldtor geöffnet?", "Mit seinem Ring? Den hat er nicht mehr. Er hat ihn verkauft, zusammen mit seinem Namen, an einen Richter, der weinte, während er bezahlte. Wer keinen Namen hat, wird nicht aufgerufen. Wer nicht aufgerufen wird, kommt nie auf die Waage. Er hatte Angst vor ihr. Die meisten Könige haben Grund dazu."],
			["Was schreibst du da?", "Die Liste des Westens, für Thot. Wer stirbt, kommt darauf, mit roter Tinte. Heute Abend sind viele aus Sandtor dazugekommen. Der letzte Name steht ganz unten, die Tinte ist noch feucht. Verzeih. Ein Schreiber redet zu viel, wenn er vierhundert Jahre allein war."]],
		"quest": "Die Namensscherbe", "auftrag": "Eine einzige Kartusche hat Chaemwese damals nicht zerschlagen, sondern versteckt. Finde die Scherbe mit dem Namen des Königs.",
		"relikt": "Die Namensscherbe", "fund": "Ein Stück Kalkstein, groß wie eine Hand. In der Kartusche stehen fünf Zeichen, sauber und tief. Im ganzen Westen bist du gerade der einzige Mensch, der den Namen dieses Königs kennt.",
		"wahl": [["Dem König seinen Namen zurückgeben", "Du wirst ihn laut aussprechen, wenn du vor ihm stehst. Wer gerufen wird, muss antworten. Auch ein König. Auch vor der Waage.", 12, "segen"],
			["Die Scherbe an die Grabräuber verkaufen", "Ein Königsname ist viel wert bei denen, die mit Namen handeln. Es klimpert in deinem Beutel. Der König wird weiter wach liegen.", -12, "scherben"]],
		"ba": "Lies die Wände nicht. Was fehlt, ist das Wichtige.",
	},
	{   # 4 · Rosetau
		"wer": "Ein Erloschener", "bild": "P04", "mit": "dem Erloschenen", "titel": "einst ein Unvergänglicher Stern", "model": "Mage", "tint": Color(0.6, 0.7, 0.85),
		"echo": {"3": ["„Eben hat ein König seinen eigenen Namen gerufen, so laut, dass es bis hier herauf hallte. Warst du das?“",
			"„Über den Sand ist ein Händler gekommen, mit einem Königsnamen im Beutel. Er hat ihn für drei Krüge Bier weiterverkauft.“"]},
		"gruss": ["Du trägst Licht. Halt es nicht so hoch. Es tut weh, sich zu erinnern.",
			"Wir waren die Sterne, die niemals untergehen. Wir zogen die Barke über Sokars Sand. Dann kam einer und sagte: Gebt mir eure Herzen, und ihr werdet nie gewogen. Wir wussten nicht, dass ein Stern ohne Herz erlischt."],
		"fragen": [["Wer war das?", "Er trug den Schurz eines Richters. Einer der Zweiundvierzig. Er weinte, als er die Krüge verschloss, und er hat jeden von uns beim Namen genannt. Dann hat er die Namen aufgeschrieben und mitgenommen."],
			["Was hörst du?", "Den Krug in deiner Tasche nicht. Der ist leer. Aber da schlägt etwas, {lt}, und es schlägt nicht in deiner Brust. Es schlägt in deiner Laterne. Was haben die Priester dir da hineingelegt?"]],
		"quest": "Das Sternenherz", "auftrag": "Zwischen dem Glas liegt ein Herz, das noch glimmt. Es gehört einem der Erloschenen.",
		"relikt": "Ein Sternenherz", "fund": "Es ist kalt wie Glas und leicht wie Asche, und tief innen glimmt es noch. Ein Herz, das nie gewogen wurde. Es würde gut brennen.",
		"wahl": [["Das Herz dem Stern zurückgeben", "Du legst es dem Erloschenen in die Hände. Er leuchtet nicht auf. Aber er hebt den Kopf, zum ersten Mal, und sieht nach Norden, wo sein Platz am Himmel leer ist.", 14, "xp"],
			["Das Herz in die Laterne legen", "Die Flamme wird weiß. Deine Schläge fallen schwerer, deine Hände sicherer. Irgendwo hinter dir sinkt ein Kopf zurück auf die Brust.", -14, "legende"]],
		"ba": "Wenn der Türhüter fragt, wie du heißt: Sag es nicht gleich. Bitte.",
	},
	{   # 5 · Die Höhle des Sokar: der Sammler selbst, bevor er kämpft
		"wer": "Ein alter Richter", "bild": "P05", "mit": "dem alten Richter", "titel": "einer der Zweiundvierzig", "model": "Mage", "tint": Color(0.75, 0.55, 0.95),
		"echo": {"4": ["„Ein Stern sieht wieder nach Norden. Das warst du. Ich hätte es dir nicht zugetraut.“",
			"„In deiner Laterne brennen zwei Herzen, und eines davon ist gestohlen. Wir sind uns ähnlicher, als du denkst.“"]},
		"gruss": ["Setz dich, {lt}. Du bist weit gegangen für jemanden, der heute Abend gestorben ist.",
			"Ich habe dir einen Krug gemacht, aus dem besten Alabaster. Und einen für sie. Geht die Sonne nicht auf, stirbt sie vor dem Morgen, und ihr Herz kommt zu mir, nicht zur Fresserin. Ich benutze niemanden. Ich bewahre."],
		"fragen": [["Warum hast du die Waage angehalten?", "Ich saß zweiundvierzigtausend Nächte zu Gericht. Ich habe gesehen, wie die Fresserin den Kopf hob über Herzen, die nur müde waren, nicht böse. Eines davon gehörte meiner Tochter. Was danach geschah, habe ich nicht angesehen. Ich bin aufgestanden. Seitdem wird keiner mehr verschlungen. Nenn mir eine größere Gnade."],
			["Und die Sonne?", "Die Sonne ist der Preis. Ohne Gewogene zieht niemand die Barke, ich weiß. Tausend Herzen gegen einen Morgen: Ich habe gewogen, das ist alles, was ich je getan habe. Und frag deinen Ba einmal, wessen Gesicht er hat."]],
		"quest": "Der Krug mit deinem Namen", "auftrag": "Tief in der Höhle steht ein Krug mit deinem Namen. Der Richter sagt, er warte schon den ganzen Abend auf dich.",
		"relikt": "Der Krug mit deinem Namen", "fund": "Alabaster, sehr sauber gearbeitet. Auf dem Siegel steht dein Name, rot nachgezogen. Der Krug ist leer und ein wenig warm, als hätte jemand lange die Hände darum gelegt. Dein Herz ist das einzige in Sandtor, das der Sammler nicht bekommen hat. Die Priester haben es in deine Laterne gelegt. Es brennt.",
		"wahl": [["Den Krug zerschlagen", "Alabaster splittert leicht. Du wirst gewogen werden wie alle anderen, und du weißt nicht, wie es ausgeht. Das ist der Sinn einer Waage.", 16, "segen"],
			["Den Krug mitnehmen", "Man weiß nie. Ein Herz, das nicht gewogen wird, kann auch nicht zu schwer sein. Du verstehst den alten Richter jetzt ein wenig besser, und das gefällt dir nicht.", -16, "legende"]],
		"ba": "Es schlägt, tausendfach. Hör nicht auf ihn, egal was er dir anbietet. Hörst du? Egal was.",
	},
	{   # 6 · Der Leib des Osiris (Mitte: Isis nennt den Namen des Ba, Szene „mitte“ vor dem ersten Gespräch)
		"wer": "Isis", "bild": "P11", "titel": "die Klagende", "model": "Mage", "tint": Color(0.6, 1.0, 0.75),
		"echo": {"5": ["„Du hast deinen Krug zerschlagen. Gut. Ich mag keine Krüge. Ich habe einmal vierzehn Stücke meines Mannes einsammeln müssen, und keines lag in einem Krug.“",
			"„In deiner Tasche liegt ein leerer Krug mit deinem Namen. Wirf ihn weg, bevor du dich an ihn gewöhnst.“"]},
		"gruss": ["Sprich leise. Er schläft nicht, er wartet.",
			"Auf dem Lager meines Bruders liegt einer, der dort nicht hingehört. Solange er liegt, können Re und Osiris einander nicht begegnen, und die Sonne wird nicht jung."],
		"fragen": [["Woher kanntest du ihren Namen?", "Ich habe Re seinen geheimen Namen abgelistet, als die Welt noch jung war. Ich höre einen Namen, auch wenn er flattert. Die Frage ist nicht, wer sie ist. Die Frage ist, wie lange ihr Leib in Sandtor noch auf sie wartet."]],
		"quest": "Das Leinen des Osiris", "auftrag": "Ein Streifen vom Leinen des Osiris ist vom Lager gerissen. An so einem Faden findet ein Ba zurück zu seinem Leib, sagt Isis. Oder er bleibt, wo er ist.",
		"fund_bild": "P27",   # die Wahl um Nebet: der Ba auf deiner Schulter (ui/portraits/P27, wenn gemalt)
		"relikt": "Das Leinen des Osiris", "fund": "Ein Streifen feinsten Leinens, getränkt mit Harz und Myrrhe. Wo du ihn anfasst, hören deine Hände auf zu zittern. Auf deiner Schulter wird es sehr still.",
		"wahl": [["Nebet das Leinen umbinden und sie heimschicken", "Sie sagt nichts. Sie drückt nur einmal den Kopf an deine Wange, wie früher, wenn sie nicht schlafen konnte. Dann zieht der Faden sie nach oben, durch sechs Stunden Dunkel, allein.", 10, "xp"],
			["Das Leinen behalten. Sie bleibt bei dir.", "Sie bleibt. Sie ist leichter als vorhin, ein wenig durchscheinend. Das Leinen heilt alles, was es berührt. Sie berührt es nicht.", -8, "trank"]],
		"ba": "Tiefer geht es nicht. Geh nicht zu der Frau mit den Flügeln. Bitte. Nur dieses eine Mal.",
	},
	{   # 7 · Die Sandbank des Apophis
		"wer": "Selket", "bild": "P12", "titel": "die atmen lässt", "model": "Rogue", "tint": Color(0.95, 0.8, 0.45),
		"echo": {"6": ["„Auf deiner Schulter sitzt niemand mehr. Gut. Wo ich jetzt hingehe, sollte kein Kind sein.“",
			"„Du hast ein Kind auf der Schulter. Hier? Halt sie fest, und halt sie tief.“"]},
		"gruss": ["Halt die Laterne tiefer. Er sieht durch das Licht.",
			"Seth hält den Speer, Isis spricht die Worte, ich halte die Fessel. So war es jede Nacht. Heute liegt die Barke auf dem Trockenen, und am Bug steht ein General, der niemandem gehorcht."],
		"fragen": [["Kann man ihn töten?", "Nein. Man kann ihn nur jede Nacht besiegen. Heute hat ihm jemand den Weg zur Barke gezeigt. Einer ohne Leib, der keinen Schatten wirft, weil er selbst einer ist."]],
		"quest": "Selkets Fessel", "auftrag": "Die Fessel für die Schlange ist im Sand verloren gegangen. Ohne sie hält Apophis niemand.",
		"relikt": "Selkets Fessel", "fund": "Ein Strick aus Kupferdraht und Skorpionschwänzen, schwer und kalt. Er windet sich in deiner Hand wie etwas, das beißen möchte.",
		"wahl": [["Die Fessel der Göttin bringen", "Selket nimmt sie ohne ein Wort und prüft jeden Knoten. Dann nickt sie nach Westen, wo es sich im Sand bewegt.", 8, "segen"],
			["Die Fessel um die eigene Waffe wickeln", "Jeder Schlag brennt jetzt wie ein Stich. Am Bug der Barke steht eine Göttin mit leeren Händen.", -10, "beute"]],
		"ba": "Ich bin ein Vogel. Er ist eine Schlange. Ich sag das nur, damit es jemand gesagt hat.",
	},
	{   # 8 · Die Grüfte der Götter (Ende des zweiten Aktes: in der stummen Gruft liegt der eigene Ba)
		"wer": "Der Große Kater", "bild": "P13", "mit": "dem Großen Kater", "titel": "Re in seiner Gestalt von Heliopolis", "model": "Barbarian", "tint": Color(1.0, 0.8, 0.5),
		"echo": {"7": ["„Selket sagt, du hast ihr die Fessel gebracht. Selket sagt sonst nie etwas über irgendwen.“",
			"„Selket stand am Bug mit leeren Händen. Sie hat nicht geflucht. Das ist schlimmer.“"]},
		"gruss": ["Du riechst nach Zedernöl und Natron. Frisch balsamiert. Wie nett.",
			"Wenn ich an den Grüften vorüberfahre, antwortet es von drinnen: wie ein Kater, wie ein Schwarm Bienen, wie ein Stier. Aus einer Gruft kommt kein Laut mehr. Sie ist neu, Kind. Sie riecht nach Natron, wie du."],
		"fragen": [["Wer liegt in der stummen Gruft?", "Kein Leib. Ein Ba ohne Namen, der so lange nach dir gesucht hat, bis ihm die Stimme ausging. Er hat dein Gesicht, falls dich das tröstet. Mich würde es trösten. Ich habe ein sehr schönes Gesicht."]],
		"quest": "Die Wabe aus der Gruft", "auftrag": "In einer der Grüfte summt es nicht mehr. Eine Honigwabe liegt irgendwo im Dunkeln. Sie ist die Stimme einer Gruft.",
		"relikt": "Eine Honigwabe", "fund": "Sie ist schwer und golden und summt leise, obwohl keine Biene darin ist. Es ist die Stimme einer Gruft. Vielleicht deine.",
		"wahl": [["Die Wabe in die stumme Gruft legen", "Erst ist es still. Dann beginnt es hinter dem Stein zu summen, tief und zufrieden, und mitten im Summen sagt jemand ein Wort, mit deiner Stimme.", 8, "xp"],
			["Den Honig essen", "Er ist süßer als alles, was du lebend gekostet hast. Die Stille hinter dem Stein wird ein wenig größer.", -8, "trank"]],
		"ba": "Hör hin. Es klingt wie ein Kater. So soll es klingen. Und da drin, das bist du. Ich hab's die ganze Zeit gewusst.",
	},
	{   # 9 · Die Ruderer
		"wer": "Der elfte Ruderer", "bild": "P14", "mit": "dem elften Ruderer", "titel": "auf der Bank neben der leeren", "model": "Knight", "tint": Color(0.7, 0.8, 1.0),
		"echo": {"8": ["„Aus den Grüften summt es wieder. Und eine Stimme spricht mit, die ich nicht kenne. Sie klingt wie du.“",
			"„In den Grüften summt es. Nur in einer nicht. Du hast Honig am Kinn.“"]},
		"gruss": ["Elf Ruder. Zähl nach, wenn du willst. Ich habe die ganze Nacht nichts anderes getan.",
			"Der Zwölfte saß neben mir, seit es die Barke gibt. Sein Ba ist ausgeflogen, nur für eine Nacht, und hat die Bank nicht wiedergefunden. Wer zu lange fort ist, erkennt seinen Leib nicht mehr. Jetzt irrt er als Licht durch die Gänge und schlägt nach allem, was ihn ruft."],
		"fragen": [["Erkennt er dich noch?", "Er erkennt sein Ruder. Mehr braucht ein Ruderer nicht. Und hör: Vor uns, am Ufer, geht einer zu Fuß. Er trägt einen Krug im Arm, wie man ein Kind trägt."]],
		"quest": "Das zwölfte Ruder", "auftrag": "Das Ruder des zwölften Ruderers liegt irgendwo in den Gängen.",
		"relikt": "Das zwölfte Ruder", "fund": "Wieder ein Ruder. Diesmal weißt du, was du in der Hand hältst, und was du bist, und was es heißt, etwas zurückzubringen.",
		"wahl": [["Das Ruder auf die leere Bank legen", "Der elfte Ruderer rückt ein Stück zur Seite, wie man es für jemanden tut, der gleich kommt.", 8, "segen"],
			["Das Ruder zerbrechen", "Es splittert der Länge nach. Aus dem Holz fällt, was ein Ruderer in tausend Nächten darin versteckt hat.", -10, "beute"]],
		"ba": "Zu lange fort. Ich hab's gehört. Sag jetzt nichts.",
		"ba_eigen": "Ich bin wieder da. Ich rede nicht viel. Rudern musst du trotzdem.",
	},
	{   # 10 · Die Ertrunkenen im Nun
		"wer": "Horus", "bild": "P15", "titel": "der die Ertrunkenen ans Ufer zieht", "model": "Knight", "tint": Color(0.6, 0.9, 1.0),
		"echo": {"9": ["„Zwölf Ruder im Wasser. Das höre ich bis hierher. Danke.“",
			"„Die Barke kommt mit elf Rudern und einem Loch im Takt. Das höre ich bis hierher.“"]},
		"gruss": ["Wer im Fluss blieb, bekam kein Grab und keinen Namen auf einem Stein. Ich rufe sie trotzdem.",
			"Einer hält sich am Grund fest. Er war einmal ein König und will nicht an Land. Und am Ufer treiben Seiten, angekohlt, voller Namen aus Sandtor."],
		"fragen": [["Kannst du die Namen aus dem Buch rufen?", "Nicht, solange sie in einem Buch stehen, das keine Waage kennt. Wer das Buch hat, hat die Namen. Und wer es verbrennt, tut, was man den Königen antat, die man vergessen wollte. Der General weiß, wie das geht. Er hat es selbst getan."]],
		"quest": "Ein Name im Schlamm", "auftrag": "Am Ufer liegt ein Tonsiegel mit dem Namen eines Ertrunkenen. Kein Buch hält ihn fest, nur der Ton. Ohne Namen kann Horus ihn nicht rufen.",
		"relikt": "Ein Tonsiegel", "fund": "Ein Klumpen Nilschlamm, hart gebrannt. Ein Name ist hineingedrückt, mit dem Daumen, in Eile. Jemand wollte, dass man sich erinnert.",
		"wahl": [["Den Namen über das Wasser rufen", "Du rufst ihn dreimal. Beim dritten Mal teilt sich das Wasser, und etwas watet müde ans Ufer.", 10, "xp"],
			["Das Siegel zu Staub zerreiben", "Fayencestaub und Scherben. Mehr ist ein Name nicht, wenn man ihn zerreibt.", -8, "scherben"]],
		"ba": "Du hattest ein Grab, weißt du. Ich hab gesehen, wie sie dich gewaschen haben. Ich hab nicht geweint. Doch.",
		"ba_eigen": "Du hattest ein Grab. Jemand hat dich gewaschen. Vergiss das nicht.",
	},
	{   # 11 · Die Feuergruben (Gnade oder Ordnung: Haremhab hält das Verzeichnis über die Glut)
		"wer": "Die mit dem Messer", "bild": "P16", "mit": "der Göttin mit dem Messer", "titel": "Göttin am Rand der Grube", "model": "Rogue", "tint": Color(1.0, 0.55, 0.4),
		"echo": {"10": ["„Horus sagt, du hast einen Namen über das Wasser gerufen. Das hört man hier unten selten.“",
			"„An deinen Händen klebt Fayencestaub. Ein zerriebener Name. Ich rieche das.“"]},
		"gruss": ["Nicht so nah an den Rand. Die Hitze nimmt, was sie kriegen kann.",
			"Hier endet, wer gegen die Ordnung stand. Dort drüben steht einer, der die Ordnung so liebt, dass er ein ganzes Buch in die Glut halten will. Ich verstehe ihn gut. Das macht mir Sorgen."],
		"fragen": [["Der Sammler nannte das Grausamkeit.", "Der Sammler hat recht. Und er hat tausend Sterne gelöscht und die Sonne angehalten, um recht zu behalten. Gnade ohne Ordnung ist auch nur ein Feuer. Ordnung ohne Gnade auch."]],
		"quest": "Das Verzeichnis", "auftrag": "Haremhab hat dem Schatten das Buch abgenommen und steht damit am Rand der Grube. Darin stehen alle Namen aus Sandtor, auch deiner.",
		"fund_bild": "P26",   # Haremhab hält das Buch über die Glut (ui/portraits/P26, wenn gemalt)
		"relikt": "Das Verzeichnis", "fund": "Ein Buch aus Papyrus, dick wie ein Arm, die Ränder schwarz vom Feuer. Haremhab hält es über die Glut. „Brennt es, ist der Richter niemand mehr.“ Auf der letzten Seite stehen zwei Namen nebeneinander, frisch. Deiner. Und ihrer.",
		"wahl": [["Das Buch an dich nehmen und zur Waage tragen", "Haremhab lässt los, langsam, als täte es ihm weh. „Dann soll Thot sie lesen. Alle.“ Er sieht dich nicht an. „Auch meinen, wenn er darin steht.“", 12, "xp"],
			["Haremhab nicken", "Das Buch fällt. Für einen Atemzug brennt die Grube grün, und tausend Namen steigen als Funken auf, und keiner ruft sie. Haremhab steht sehr gerade. „Ordnung“, sagt er. Es klingt nicht wie ein Sieg.", -10, "legende"]],
		"ba": "Am Rand des Himmels wird es grau. Siehst du es? Fast. Ich muss bald los.",
		"ba_eigen": "Am Rand des Himmels wird es grau. Fast.",
	},
	{   # 12 · Das Tor des Ostens
		"wer": "Schu", "bild": "P17", "titel": "der die Sonne hebt", "model": "Barbarian", "tint": Color(0.8, 0.9, 1.0),
		"echo": {"11": ["„Du trägst ein Buch unter dem Arm, das schwerer ist als du. Thot wird sich freuen. Thot freut sich selten.“",
			"„Du riechst nach verbranntem Papyrus. Tausend Namen. Ich habe sie aufsteigen sehen. Keiner hat sie gerufen.“"]},
		"gruss": ["Da bist du. Meine Arme werden lahm.",
			"Hinter diesem Tor ist Morgen. Davor steht einer, den du schon einmal besiegt hast. Sein Herz ist gewogen; sein Schatten wusste nichts davon und tut, was Schatten tun. Er bleibt. Er hält einen Krug. Und dann bist du an der Reihe, {lt}. Thot hat die Binse schon eingetaucht."],
		"fragen": [["Was geschieht mit mir?", "Das hängt davon ab, was du unterwegs aufgehoben und was du liegen gelassen hast. So einfach ist das. So schwer."]],
		"quest": "Die Feder der Maat", "auftrag": "Vor dem Tor liegt etwas Weißes im Staub. Schu sagt, es dürfe dort nicht liegen.",
		"relikt": "Die Feder der Maat", "fund": "Sie liegt einfach da, als hätte jemand sie verloren. Eine Straußenfeder, weiß und schwerelos. Gegen sie wird jedes Herz gewogen. Gleich auch deins.",
		"wahl": [["Die Feder zurück auf die Waage legen", "Du legst sie auf die Schale und trittst zurück. Sie wiegt nichts. Sie wiegt alles. Thot nickt.", 12, "segen"],
			["Ein Körnchen Blei in den Kiel drücken", "Niemand sieht es. Kein Herz wird je wieder zu schwer sein, auch deins nicht. Irgendwo vor dem Tor lacht ein Schatten und weint dabei.", -25, "legende"]],
		"ba": "Wenn sie dich rufen, antworte. Egal, wie es ausgeht. Ich muss gleich fliegen. Gleich. Noch nicht.",
		"ba_eigen": "Wenn sie dich rufen, antworte. Ich bin da.",
	},
]

# ---------------------------------------------------------------- Leute und ihre Sorgen
# Neben der großen Geschichte gibt es in jeder Stunde jemanden mit einem ganz gewöhnlichen Kummer: Der Hirte sucht seine
# Schafe, die Bäuerin ihre Saatsäcke, das Kind die Kätzchen. Es sind Leute aus Sandtor, am selben Fieber gestorben, die es
# nicht wissen. Drei Dinge liegen oder laufen irgendwo in der Stunde herum.
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
		"gruss": "Dich kenne ich doch. Du hast im Fieberhaus gewacht, bei der Kleinen mit den blauen Fingern, und ich habe euch Wasser gebracht. Hier gibt es keins, also habe ich meines mitgebracht. Drei Krüge. Dann kam so ein graues Ding, ich bin gerannt, und jetzt stehen die Krüge irgendwo da drin.",
		"fund": "Noch voll, noch kühl. Du trinkst einen Schluck. Er schmeckt nach nichts.",
		"dank": "Du hast daraus getrunken, das sehe ich. Macht nichts, dafür ist es da. Wie geht es der Kleinen? Nein, sag nichts. Hier, das habe ich unterwegs aufgelesen."},
	{"wer": "Nefru", "bild": "P10", "titel": "ein Kind", "model": "Mage", "klein": true, "ding": "katze", "was": "Kätzchen", "eins": "Ein Kätzchen",
		"gruss": "Meine Katze hat Junge gekriegt, und die sind weggelaufen. Drei. Die Katze sucht auch schon, aber sie kann nicht so gut zählen.",
		"fund": "Es faucht dich an, so gut es kann, und läuft dann mit steilem Schwanz nach Hause.",
		"dank": "Eins, zwei, drei! Die Katze sagt danke. Sie hat dir was mitgebracht. Ich glaube, es war mal eine Maus, aber das hier glänzt mehr."},
	{"wer": "Chui", "bild": "P18", "titel": "Eseltreiber", "model": "Barbarian", "ding": "esel", "was": "Esel", "eins": "Ein Esel",
		"gruss": "Meine Esel sind klüger als ich. Als es hier unheimlich wurde, sind sie weggelaufen. Ich bin geblieben. Drei Stück, graue.",
		"fund": "Er lässt sich lange bitten. Dann geht er, als wäre es seine eigene Idee gewesen.",
		"dank": "Da sind sie ja, die Schlauköpfe. Hier, das hing an einem Sattel. Meins ist es nicht."},
	{"wer": "Meni", "bild": "P19", "titel": "Fischer", "model": "Rogue", "ding": "korb", "was": "Reusen", "eins": "Eine Reuse",
		"gruss": "Seit das Wasser weg ist, fange ich nichts mehr. Aber die Reusen will ich trotzdem zurück. Drei habe ich ausgelegt. Man hofft ja.",
		"fund": "Leer, natürlich. Aber ordentlich geflochten.",
		"dank": "Wenn das Wasser zurückkommt, bin ich bereit. In einer war das hier. Kein Fisch, aber immerhin."},
	{"wer": "Baket", "bild": "P20", "titel": "Bäckerin", "model": "Rogue", "ding": "korb", "was": "Brotkörbe", "eins": "Ein Brotkorb",
		"gruss": "Ich wollte den Leuten in den Grüften Brot bringen. Dann hat etwas gebrüllt, und ich habe die Körbe fallen lassen. Drei Körbe. Das Brot ist noch gut, wenn du dich beeilst.",
		"fund": "Es riecht nach Kümmel. Du nimmst nichts davon. Fast nichts.",
		"dank": "Es fehlt eine Ecke. Ich sage nichts. Hier, das hat mir jemand statt Bezahlung gegeben."},
	{"wer": "Senbi", "bild": "P21", "titel": "Zimmermann der Barke", "model": "Barbarian", "ding": "kiste", "was": "Werkzeugkisten", "eins": "Eine Werkzeugkiste",
		"gruss": "Die Ruderbänke knarren, und ich komme nicht an mein Werkzeug. Drei Kisten, irgendwo in den Gängen. Zwölf Ruderer auf losen Bänken, das geht nicht gut.",
		"fund": "Dechsel, Bohrer, Holznägel. Alles da.",
		"dank": "Jetzt hält die Bank auch den Dicksten. Ich baue noch eine dreizehnte, falls einer bleiben will. Das hier lag unter einer Planke. Seit wie lange, will ich gar nicht wissen."},
	{"wer": "Iti", "bild": "P22", "titel": "Wäscherin", "model": "Rogue", "ding": "korb", "was": "Wäschekörbe", "eins": "Ein Wäschekorb",
		"gruss": "Ich wasche seit vierzig Jahren am Ufer, und noch nie ist mir die Wäsche weggeschwommen. Heute gleich drei Körbe. Leinen von guten Leuten!",
		"fund": "Nass, aber sauber. Du wringst nichts aus. Das macht sie lieber selbst.",
		"dank": "Kein Hemd fehlt. Das hier war in einer Tasche eingenäht. Den Besitzer gibt es nicht mehr, glaube ich."},
	{"wer": "Pepi", "bild": "P23", "titel": "Ziegenjunge", "model": "Mage", "klein": true, "ding": "ziege", "was": "Ziegen", "eins": "Eine Ziege",
		"gruss": "Die Ziegen mögen das Feuer nicht. Ich auch nicht. Drei sind mir ausgebüxt. Mein Vater zählt jeden Abend nach.",
		"fund": "Sie versucht, an deinem Gurt zu knabbern, und springt dann davon, Richtung Junge.",
		"dank": "Drei! Vater merkt nichts. Das hier hat die Braune ausgespuckt. Du kannst es haben."},
	{"wer": "Henut", "bild": "P24", "titel": "Nachbarin", "model": "Rogue", "ding": "katze", "was": "Katzen", "eins": "Eine Katze",
		"gruss": "Bald geht die Sonne auf, und meine drei Katzen sind noch draußen. Sie kommen sonst immer vor dem Morgen heim. Und du, was machst du hier? Deine Schwester liegt allein im Fieberhaus. Ich habe nach ihr gesehen. Sie hat nach dir gefragt.",
		"fund": "Sie tut, als hätte sie dich nicht gesehen, und geht dann sehr würdevoll nach Hause.",
		"dank": "Alle drei vor Sonnenaufgang. So gehört sich das. Hier, das hat eine von ihnen angeschleppt. Und jetzt lauf. Sie wartet."},
]

static func leute(n: int) -> Dictionary:
	return fuell(LEUTE[Stunden.hour_of(n) - 1])

# Die Figur der Stunde, Platzhalter gefüllt; der Satz des Ba („ba“) folgt dem, was die Figur über ihn weiß (ba_satz)
static func def(n: int) -> Dictionary:
	var d: Dictionary = fuell(H[Stunden.hour_of(n) - 1])
	d.ba = ba_satz(Stunden.hour_of(n))
	return d

# ---------------------------------------------------------------- Platzhalter
static func weiblich() -> bool:
	return Spiel.cls in ["jaegerin", "forensiker"]

static func anrede() -> String:
	return "Laternenträgerin" if weiblich() else "Laternenträger"

# Füllt {lt} in Texten, Listen und Wörterbüchern (gibt eine Kopie zurück)
static func fuell(v: Variant) -> Variant:
	if v is String:
		return v.replace("{lt}", anrede())
	if v is Array:
		return v.map(func(x): return fuell(x))
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = fuell(v[k])
		return d
	return v

# ---------------------------------------------------------------- Rückbezüge und Begleiter
# Wahl einer Stunde: "maat", "isfet" oder "" (noch nicht entschieden)
static func gewaehlt(stunde: int) -> String:
	return str(Spiel.wahl.get(str(stunde), ""))

# Was die Figur der Stunde n über frühere Entscheidungen sagt (vor ihrem Gruß, beim ersten Gespräch)
static func echo(n: int) -> Array:
	var aus := []
	var e: Dictionary = H[Stunden.hour_of(n) - 1].get("echo", {})
	for k in e:
		var w := gewaehlt(int(k))
		if w != "":
			aus.append(fuell(e[k][0 if w == "maat" else 1]))
	return aus

# Ist der Ba enthüllt? (Isis hat in der sechsten Stunde seinen Namen gesagt)
static func ba_enthuellt() -> bool:
	return Spiel.gesehen("sz_mitte") or gewaehlt(6) != "" or Spiel.max_fall >= 7

# Wer flüstert dir zu? "Dein Ba" (bis zur Mitte), "Nebet" (wenn sie bleibt), "Dein eigener Ba" (ab Stunde 9, wenn die
# Wabe in der Gruft liegt und Nebet heim ist) oder "" (Stille: Nebet ist fort, der eigene Ba stumm)
static func ba_wer(stunde: int = Stunden.hour_of(Spiel.fall)) -> String:
	if not ba_enthuellt() or stunde <= 5:
		return "Dein Ba"
	if gewaehlt(6) != "maat":
		return "Nebet"
	if stunde >= 9 and gewaehlt(8) == "maat":
		return "Dein eigener Ba"
	return ""

static func ba_satz(stunde: int) -> String:
	var h: Dictionary = H[stunde - 1]
	var wer := ba_wer(stunde)
	if wer == "":
		return ""
	if wer == "Dein eigener Ba":
		return fuell(h.get("ba_eigen", ""))
	return fuell(h.get("ba", ""))

# Rückblick am Ende des ersten Aktes: was die Entscheidungen hinterlassen haben (Main › _aktende_lohn)
const RUECKBLICK := {
	"1": ["Mahafs Ruder liegt auf deinem Rücken.", "Mahafs Ruder ist Asche."],
	"2": ["Die erste Garbe liegt auf dem Opfertisch.", "Die erste Garbe hast du gegessen."],
	"3": ["Ein König weiß wieder, wie er heißt.", "Ein Königsname klimpert in einem fremden Beutel."],
	"4": ["Ein Stern sieht nach Norden.", "In deiner Laterne brennen zwei Herzen."],
}

static func akt1_rueckblick() -> Array:
	var spur := []
	for k in ["1", "2", "3", "4"]:
		var w := gewaehlt(int(k))
		if w != "":
			spur.append(RUECKBLICK[k][0 if w == "maat" else 1])
	spur.append("In deiner Tasche liegt Nebets Krug, leer und warm.")
	return ["Vier Stunden liegen hinter dir. Du bist hinabgestiegen, um für Nebet den Morgen zu holen. Jetzt weißt du, dass du ihn nicht mehr erleben wirst.",
		" ".join(spur)]

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

# Das Tuch der Gewogenen (Nemes): bekommt die Figur nach dem Urteil der fünften Stunde.
# Aus dem Spielstand abgeleitet (die sechste Stunde ist erreicht), damit alte Spielstände ohne neues Feld auskommen.
static func hat_tuch() -> bool:
	return Spiel.max_fall >= 6

# Wie das Herz in der fünften Stunde gewogen wurde. Steht fest, sobald die Pforte durchschritten ist;
# ältere Spielstände ohne diesen Eintrag nehmen das jetzige Herz.
static func urteil_art(h: float = Spiel.herz) -> String:
	if Spiel.urteil5 != "":
		return Spiel.urteil5
	return "leicht" if h >= LEICHT else ("schwer" if h <= SCHWER else "schwebe")

# Welches Ende die Waage am Tor des Ostens findet (nach dem jetzigen Herzen)
static func ende_art(h: float = Spiel.herz) -> String:
	return "leicht" if h >= LEICHT else ("schwer" if h <= SCHWER else "schwebe")

# Was aus Nebet wird: heimgeschickt in der sechsten Stunde, oder sie fliegt erst jetzt
static func ende_nebet() -> String:
	if gewaehlt(6) == "maat":
		return "In Sandtor geht die Sonne auf. Im Fieberhaus setzt sich ein Mädchen mit blauen Fingern auf und fragt nach dir."
	if ende_art() == "schwer":
		return "Nebet fliegt mit dem ersten Licht nach Westen, sechs Stunden in einem Atemzug. Ob sie ankommt, siehst du nicht mehr. Thot sieht ihr nach und lächelt."
	return "Nebet fliegt mit dem ersten Licht nach Westen, sechs Stunden in einem Atemzug. Sie ist schneller als die Sonne. Sie hat es dir ja gesagt."

# Urteil nach der fünften Stunde (die Waage bewegt sich wieder) und am Tor des Ostens (Ende der Nacht)
static func urteil(n: int) -> String:
	var h: float = Spiel.herz
	var hour := Stunden.hour_of(n)
	if hour == 5:
		if h >= LEICHT:
			return fuell("Thot ruft einen Namen, und es ist deiner. Dein Herz liegt auf der Schale, und die Waage neigt sich zu dir. Bring die Barke zum Morgen, dann schreibt er es auf. Als du gehst, legt er dir ein Tuch um den Kopf, gestreift in Lapis und Gold, wie es die Könige im Westen tragen. „Wer gewogen wurde, geht nicht mehr barhäuptig.“")
		if h <= SCHWER:
			return fuell("Thot ruft einen Namen, und es ist deiner. Die Schale mit deinem Herzen sinkt, und am Fuß der Waage hebt die Fresserin den Kopf. Thot legt die Hand auf die Schale. „Noch nicht. Die Barke braucht jede Hand. Sieben Stunden hast du, um leichter zu werden.“ Als du gehst, legt er dir ein Tuch um den Kopf, gestreift im Rot der Wüste und im Schwarz des Schlamms, die Farben des Seth. „Wer gewogen wurde, geht nicht mehr barhäuptig. Trag, was du bist.“")
		return fuell("Thot ruft einen Namen, und es ist deiner. Dein Herz liegt auf der Schale, und die Waage zittert und bleibt in der Schwebe. Thot wartet mit der Binse. „Sieben Stunden bis zum Morgen. Zeig mir bis dahin, wohin sie sich neigt.“ Als du gehst, legt er dir ein Tuch um den Kopf, gestreift in ungefärbtem Leinen und im Silber des Mondes. „Wer gewogen wurde, geht nicht mehr barhäuptig. Die Farbe kommt noch.“")
	if hour == 12:
		var nebet := ende_nebet()
		if h >= LEICHT:
			var stern := "Im Norden, wo ein Platz am Himmel leer war, geht ein Stern auf, der nie mehr untergeht." if gewaehlt(4) == "maat" \
				else "In den Feldern von Wernes legt dir Merit eine Sichel in die Hand. Das Korn steht sieben Ellen hoch."
			return "DAS URTEIL: WAHR AN STIMME. Die Schalen stehen still, beide gleich hoch. Thot schreibt deinen Namen in das Buch, und Schu hebt die Sonne über den Horizont. " + nebet + " " + stern
		if h <= SCHWER:
			var krug := " Im Gürtel trägst du einen Krug mit deinem Namen. Er ist leer. Noch." if gewaehlt(5) == "isfet" else ""
			return "DAS URTEIL: ZU SCHWER. Die Schale sinkt, und am Fuß der Waage hebt die Fresserin den Kopf. Thot legt die Hand auf die Schale. „Noch nicht.“ " + nebet + " Du aber gehst in die nächste Nacht, mit einer Laterne, die ohne Öl brennt." + krug
		# das Ruder am Ufer hängt an der Wahl der ersten Stunde: aufgehoben (oder nie gefunden) oder verbrannt
		var ruder := "Am Ufer liegt ein Ruder aus Zedernholz. Du kennst es."
		if gewaehlt(1) == "isfet":
			ruder = "Am Ufer liegt ein Ruder aus Treibholz, grob gebunden. Das aus Zedernholz hast du verbrannt, und sein Rauch hängt noch in deiner Laterne."
		return "DAS URTEIL: IN DER SCHWEBE. Die Waage findet keine Seite. Thot legt die Binse weg und sieht dich lange an. „Es fehlt ein Fährmann“, sagt er. " + ruder + " " + nebet + " Jede Nacht kommen Lichter gegen den Wind, und einer muss sie übersetzen."
	return ""
