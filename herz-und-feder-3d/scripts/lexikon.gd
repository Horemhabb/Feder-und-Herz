class_name Lexikon
# Lexikon (3.0): Nicht jeder kennt die ägyptische Mythologie. Jeder Begriff wird beim ersten Auftauchen in einem
# Satz erklärt (Fußnote unter Gesprächen und Tafeln, kurzer Hinweis nach geflüsterten Sätzen) und steht danach im
# Spielmenü unter „Lexikon“. Die Erklärungen sind bewusst schlicht: was es ist, und was es für das Spiel bedeutet.
#
# such: Wörter, an denen der Begriff im Text erkannt wird (ganze Wörter). kern: wird als Fußnote eingeblendet.

const W := [
	{"id": "duat", "name": "Duat", "such": ["Duat"], "kern": true, "gruppe": "Die Welt",
		"txt": "Die Unterwelt der alten Ägypter. Die Sonne durchfährt sie jede Nacht in zwölf Stunden. Jede Stunde ist ein eigenes Land mit eigenen Gefahren."},
	{"id": "re", "name": "Re", "such": ["Re", "Res"], "kern": true, "gruppe": "Götter",
		"txt": "Der Sonnengott. Am Tag fährt er über den Himmel, in der Nacht mit seiner Barke durch die Duat. Kommt er nicht durch, gibt es keinen Morgen."},
	{"id": "barke", "name": "Barke", "such": ["Barke", "Nachtbarke", "Tagesbarke"], "kern": true, "gruppe": "Die Welt",
		"txt": "Das Schiff des Sonnengottes. In manchen Stunden wird sie gerudert, über den Sand der Duat muss sie gezogen werden."},
	{"id": "maat", "name": "Maat", "such": ["Maat"], "kern": true, "gruppe": "Die Welt",
		"txt": "Wahrheit, Gerechtigkeit und die rechte Ordnung der Welt, zugleich eine Göttin. Ihr Zeichen ist eine Straußenfeder."},
	{"id": "isfet", "name": "Isfet", "such": ["Isfet"], "kern": true, "gruppe": "Die Welt",
		"txt": "Das Gegenteil von Maat: Lüge, Unrecht und Chaos. Wer dir hier begegnet und angreift, gehört meist dazu."},
	{"id": "waage", "name": "Herzwaage", "such": ["Waage", "Herzwaage", "gewogen", "wiegen"], "kern": true, "gruppe": "Die Welt",
		"txt": "Das Totengericht: Das Herz jedes Toten wird gegen die Feder der Maat gewogen. Ist es so leicht wie die Feder, darf er weiterleben. Deine Entscheidungen machen dein eigenes Herz leichter oder schwerer."},
	{"id": "fresserin", "name": "Die Fresserin", "such": ["Fresserin"], "kern": true, "gruppe": "Die Welt",
		"txt": "Ein Ungeheuer aus Krokodil, Löwe und Nilpferd. Es sitzt neben der Waage und verschlingt die Herzen, die zu schwer sind."},
	{"id": "ba", "name": "Ba", "such": ["Ba"], "kern": true, "gruppe": "Die Seele",
		"txt": "Ein Teil der Seele, dargestellt als Vogel mit Menschenkopf. Der Ba kann den Körper verlassen, im Schlaf oder im Fieber, und zu ihm zurückkehren. Bleibt er zu lange fort, findet er den Weg nicht mehr. Ein Ba begleitet dich und flüstert dir manchmal etwas zu."},
	{"id": "ka", "name": "Ka", "such": ["Ka"], "kern": true, "gruppe": "Die Seele",
		"txt": "Die Lebenskraft eines Menschen, eine Art unsichtbarer Zwilling. Solange der Ka genährt wird, lebt man."},
	{"id": "name", "name": "Der Name", "such": ["Kartusche", "Kartuschen"], "kern": true, "gruppe": "Die Seele",
		"txt": "Für die Ägypter lebt ein Mensch, solange sein Name gesprochen wird. Königsnamen stehen in einer Kartusche, einem ovalen Ring, der den Namen schützt. Wer einen Namen tilgt, löscht den Menschen aus."},
	{"id": "gerecht", "name": "Gerechtfertigte", "such": ["Gerechtfertigte", "Gerechtfertigten", "gerechtfertigt", "Seligen"], "kern": true, "gruppe": "Die Seele",
		"txt": "Tote, deren Herz die Wägung bestanden hat. Sie leben in den Feldern der Duat weiter und helfen, die Sonnenbarke zu ziehen."},
	{"id": "hueter", "name": "Hüter der Stunde", "such": ["Hüter"], "kern": true, "gruppe": "Die Welt",
		"txt": "Jede der zwölf Stunden hat einen Hüter. Er zeigt sich, wenn du genug seiner Gefolgschaft besiegt hast. Fällt er, öffnet sich die Pforte zur nächsten Stunde."},
	{"id": "krug", "name": "Seelenkrug", "such": ["Seelenkrug", "Seelenkrüge", "Seelenkrügen"], "kern": true, "gruppe": "Die Welt",
		"txt": "Ein versiegelter Krug, in dem ein Herz gefangen ist, das nie gewogen wurde. Du kannst es freilassen oder den Krug für seine Beigaben aufbrechen."},
	{"id": "apophis", "name": "Apophis", "such": ["Apophis"], "kern": true, "gruppe": "Götter",
		"txt": "Eine riesige Schlange, der Feind des Sonnengottes. Jede Nacht versucht sie, die Barke aufzuhalten. Sie wird jede Nacht besiegt und kommt jede Nacht wieder."},
	{"id": "sebau", "name": "Sebau", "such": ["Sebau"], "kern": true, "gruppe": "Die Welt",
		"txt": "Die Brut des Apophis: Feinde der Ordnung, die kein Herz haben und deshalb keine Waage fürchten."},
	{"id": "thot", "name": "Thot", "such": ["Thot"], "kern": true, "gruppe": "Götter",
		"txt": "Der Gott der Schrift und des Wissens, mit dem Kopf eines Ibis. Beim Totengericht schreibt er das Ergebnis der Wägung auf. Seine Schreibfeder ist eine Binse."},
	{"id": "osiris", "name": "Osiris", "such": ["Osiris"], "kern": true, "gruppe": "Götter",
		"txt": "Der Herr der Unterwelt und Richter der Toten. Er wurde ermordet und von seiner Schwester Isis ins Leben zurückgeholt. Um Mitternacht begegnet ihm der Sonnengott und wird dadurch wieder jung."},
	{"id": "isis", "name": "Isis", "such": ["Isis"], "kern": true, "gruppe": "Götter",
		"txt": "Die Göttin der Zauberkraft, Schwester und Frau des Osiris. Ihre Worte binden selbst Apophis."},
	{"id": "anubis", "name": "Anubis", "such": ["Anubis"], "kern": true, "gruppe": "Götter",
		"txt": "Der Gott mit dem Schakalkopf. Er balsamiert die Toten ein und führt sie zur Waage."},
	{"id": "seth", "name": "Seth", "such": ["Seth", "Seths"], "kern": true, "gruppe": "Götter",
		"txt": "Der Gott der Wüste und des Sturms. Gefährlich und unberechenbar, aber er steht am Bug der Sonnenbarke und sticht mit dem Speer nach Apophis."},
	{"id": "horus", "name": "Horus", "such": ["Horus", "Udjat"], "kern": true, "gruppe": "Götter",
		"txt": "Der Falkengott, Sohn von Isis und Osiris. Sein geheiltes Auge, das Udjat, ist ein Schutzzeichen."},
	{"id": "sokar", "name": "Sokar", "such": ["Sokar", "Sokars", "Rosetau"], "kern": true, "gruppe": "Götter",
		"txt": "Der Gott einer Wüstengegend in der Duat, die Rosetau heißt. Dort gibt es kein Wasser: Die Barke muss über den Sand gezogen werden."},
	{"id": "ptah", "name": "Ptah", "such": ["Ptah"], "kern": true, "gruppe": "Götter",
		"txt": "Der Gott der Handwerker und Baumeister. In seiner Werkstatt wird Ausrüstung aufgewertet und neu gefasst."},
	{"id": "sachmet", "name": "Sachmet", "such": ["Sachmet", "Sachmets"], "kern": true, "gruppe": "Götter",
		"txt": "Die Göttin mit dem Löwenkopf. Sie schickt Krankheiten und heilt sie auch. Ihr rotes Bier heilt dich."},
	{"id": "schu", "name": "Schu", "such": ["Schu"], "kern": true, "gruppe": "Götter",
		"txt": "Der Gott der Luft. Er hält den Himmel über der Erde und hebt am Morgen die Sonne über den Horizont."},
	{"id": "sandtor", "name": "Sandtor und die Nebelmark", "such": ["Sandtor", "Nebelmark"], "kern": true, "gruppe": "Die Welt",
		"txt": "Die Nebelmark ist das letzte Land der Lebenden vor dem Westen, wo die Sonne untergeht. Sandtor ist ihre Stadt. Von dort führt das Tor des Westens hinab in die Duat."},
	{"id": "laterne", "name": "Die Laterne", "such": ["Laterne", "Laternenträger"], "kern": true, "gruppe": "Die Welt",
		"txt": "Die Priester von Sandtor haben sie dir in die Hände gelegt. Sie brennt ohne Öl, leuchtet dir und ist zugleich deine Waffe: Was Isfet ist, weicht vor ihr zurück. Warum sie gerade dich geschickt haben, haben sie nicht gesagt."},
	{"id": "zweiundvierzig", "name": "Die Zweiundvierzig", "such": ["Zweiundvierzig"], "kern": true, "gruppe": "Die Welt",
		"txt": "Die zweiundvierzig Richter im Totengericht des Osiris. Vor jedem beteuert der Tote, eine bestimmte Untat nicht begangen zu haben. Erst danach wird sein Herz gewogen."},
	{"id": "mahaf", "name": "Mahaf", "such": ["Mahaf", "Mahafs"], "kern": true, "gruppe": "Götter",
		"txt": "Der Fährmann des Totenbuchs, „der hinter sich schaut“: Er setzt die Toten über das Wasser des Westens, aber nur die, die er rufen darf."},
	{"id": "schut", "name": "Schut, der Schatten", "such": ["Schut", "Schatten des Sammlers"], "kern": true, "gruppe": "Die Seele",
		"txt": "Auch der Schatten war für die Ägypter ein Teil der Seele, wie Ba und Ka. Er kann sich vom Menschen lösen und eigene Wege gehen."},
	{"id": "haremhab", "name": "Haremhab", "such": ["Haremhab", "Haremhabs"], "kern": true, "gruppe": "Die Welt",
		"txt": "Ein General, der um 1300 vor Christus selbst König wurde. Er stellte die alte Ordnung wieder her und ließ dafür die Namen der Könige vor ihm aus Wänden und Listen tilgen. Seine eigenen Tore der Nacht ließ er an die Wand seines Grabes malen."},
	{"id": "scherben", "name": "Scherben", "such": ["Scherben"], "kern": false, "gruppe": "Die Welt",
		"txt": "Beschriebene Tonscherben, das Geld der Duat. Du bezahlst damit den Goldschmied und den Grabräuber. (Umlernen kostet seit dem neuen Baum nichts mehr: Das macht Thot an seinem Schrein.)"},
	{"id": "heka", "name": "Heka", "such": ["Heka"], "kern": false, "gruppe": "Die Seele",
		"txt": "Zauberkraft: die Macht, mit dem richtigen Wort etwas wirklich werden zu lassen."},
	{"id": "selket", "name": "Selket", "such": ["Selket"], "kern": false, "gruppe": "Götter", "txt": "Die Skorpiongöttin. Sie beschützt die Atmenden und hält Apophis in Fesseln."},
	{"id": "neith", "name": "Neith", "such": ["Neith", "Neiths"], "kern": false, "gruppe": "Götter", "txt": "Die Göttin der Jagd und des Bogens."},
	{"id": "seschat", "name": "Seschat", "such": ["Seschat", "Seschats"], "kern": false, "gruppe": "Götter", "txt": "Die Göttin des Schreibens, Zählens und Messens."},
	{"id": "month", "name": "Month", "such": ["Month"], "kern": false, "gruppe": "Götter", "txt": "Ein Kriegsgott mit Falkenkopf."},
	{"id": "geb", "name": "Geb und Nut", "such": ["Geb", "Gebs", "Nut"], "kern": false, "gruppe": "Götter", "txt": "Geb ist die Erde, Nut der Himmel über ihr. Die Sterne stehen an Nuts Leib."},
	{"id": "upuaut", "name": "Upuaut", "such": ["Upuaut", "Upuauts"], "kern": false, "gruppe": "Götter", "txt": "Der „Wegöffner“, ein Gott in Gestalt eines Schakals oder Wüstenfuchses, der vorausläuft."},
	{"id": "chepri", "name": "Chepri", "such": ["Chepri"], "kern": false, "gruppe": "Götter", "txt": "Die Morgensonne in Gestalt eines Käfers (Skarabäus): der Sonnengott, neu geboren."},
	{"id": "bastet", "name": "Bastet und Hathor", "such": ["Bastet", "Hathor"], "kern": false, "gruppe": "Götter", "txt": "Bastet, die Katzengöttin, steht für Schnelligkeit und Schutz. Hathor ist die Göttin der Freude und des Glücks."},
]

static var _rx := {}

static func _findet(e: Dictionary, text: String) -> bool:
	if not _rx.has(e.id):
		var r := RegEx.new()
		r.compile("(?<![A-Za-zÄÖÜäöüß])(" + "|".join(e.such) + ")(?![A-Za-zÄÖÜäöüß])")
		_rx[e.id] = r
	return _rx[e.id].search(text) != null

# Begriffe aus den Texten, die noch nie erklärt wurden (höchstens „hoechstens“ Stück); sie gelten danach als erklärt
static func neu_in(texte: Array, hoechstens := 2) -> Array:
	var aus := []
	var ganz := " ".join(texte.map(func(t): return str(t)))
	for e in W:
		if aus.size() >= hoechstens:
			break
		if e.kern and not Spiel.gesehen("lex_" + e.id) and _findet(e, ganz):
			Spiel.wissen["lex_" + e.id] = 1
			aus.append(e)
	if not aus.is_empty():
		Spiel.speichern()
	return aus

static func gruppen() -> Array:
	return ["Die Welt", "Die Seele", "Götter"]

static func kennt(id: String) -> bool:
	return Spiel.gesehen("lex_" + id)
