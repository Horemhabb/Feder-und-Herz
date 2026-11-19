# Herz und Feder · Spec Sheet für Fassung 4.0 (Entwurf)

Stand: 19.11.2026, nach Fassung 3.0. Dies ist ein Entwurf: Die Abschnitte nennen, was gebaut werden soll, wie ich es
umsetzen würde, was es kostet (Aufwand, Ladezeit, Geld) und was noch zu entscheiden ist. Der Fragebogen am Ende
sammelt die offenen Entscheidungen. Sobald er beantwortet ist, wird aus dem Entwurf die verbindliche Fassung.

Warum „4.0“ und nicht „3.1“: Akte, doppelt so große Karten und ein neuer Fähigkeitenbaum ändern Spielstand,
Balance und Aufbau der Welt. Das ist ein Versionssprung. Ich schlage vor, ihn in vier Etappen zu liefern
(3.1 bis 3.4), jede einzeln spielbar und getestet, und das Ganze am Ende 4.0 zu nennen.

---

## 1. Ausgangslage (gemessen, nicht geschätzt)

| Größe | Heute |
|---|---|
| Karte je Stunde | 52 × 40 Zellen zu 2 m = 104 × 80 m |
| Aufbau der Welt | etwa 0,8 s am Rechner, am Handy mehr |
| Dreiecke im Bild | 240.000 bis 540.000 je nach Stunde |
| Download | Engine 39,5 MB, Spielpaket 20,7 MB |
| Tondateien | 66, davon 8 Musikstücke und 4 Sprachaufnahmen |
| Erzählerstimme | 4 Aufnahmen, die zu keiner Stunde passen; seit 3.0 je Figur nur einmal |
| Stunden | 12, alle mit Figur, Fundstück, Entscheidung und Hüter |
| Fähigkeitenbaum | eine Liste: 5 Fähigkeiten, 6 Stärken, 1 Schlüsselstein |
| Tests | Spieltest 97 Prüfungen, 4 Klassentests, Bots, Browser |

---

## 2. Ziele der Fassung

1. **Akte:** Die Nacht bekommt eine Dramaturgie. Akt 1 sind die Stunden 1 bis 4 und endet mit einem wirklich schweren Endgegner.
2. **Größere, lebendigere Welt:** doppelt so große Stunden, in denen Menschen und kleine Tiere unterwegs sind.
3. **Ton auf dem Niveau des Bildes:** eine geschichtete Klangkulisse, und eine Erzählerstimme, deren Text zur Stunde passt.
4. **Ein Baum, der wie ein Baum aussieht:** Knoten, Äste, Verzweigungen statt einer Liste.
5. **Die Pforte am Ende der Stunde** wird ein Bild, auf das man hinspielt.

---

## 3. Akte

### 3.1 Aufteilung (Vorschlag)

| Akt | Stunden | Bogen | Endgegner |
|---|---|---|---|
| 1 · Der Abstieg | 1 bis 4 | Du folgst den Lichtern, findest die Spur des Königssiegels und die erloschenen Sterne. | **neu:** siehe 3.2 |
| 2 · Die Wahrheit | 5 bis 8 | Der Sammler, dein eigener Tod, Mitternacht bei Osiris, Apophis. | Apophis (Stunde 7) oder die Grüfte (8) |
| 3 · Der Morgen | 9 bis 12 | Die Barke wird wieder vollständig, das Tor des Ostens. | Der Schatten des Sammlers |

Offen ist, ob Akt 2 und 3 schon in 4.0 als Akte ausgebaut werden oder vorerst nur Akt 1 (Frage A2).

### 3.2 Endgegner von Akt 1

Die vierte Stunde (Rosetau) hat heute den „Stummen Türhüter“. Für ein Aktende ist er zu gewöhnlich. Drei Wege:

- **a) Der Türhüter in drei Phasen.** Er fragt nach einem Namen, den niemand mehr kennt. Phase 1 Nahkampf am Tor; Phase 2 ruft er die Erloschenen von den Wegen (Wellen); Phase 3 zerbricht das Tor und er kämpft im Dunkeln, nur deine Laterne leuchtet. Wenig neues Bild, viel Mechanik.
- **b) Ein neuer Gegner: der erste Stern.** Der älteste der Erloschenen, dem das Herz fehlt. Fernkampf mit fallenden Sternen, Felder am Boden, denen man ausweichen muss. Braucht ein neues Modell aus der Figurenfabrik.
- **c) Vorgriff auf den Sammler.** Er erscheint selbst, kämpft mit Krügen und zieht sich bei halbem Leben zurück. Erzählerisch stark, nimmt aber Stunde 5 etwas vorweg.

Unabhängig vom Weg soll „echt schwer“ aus Mechanik kommen, nicht nur aus mehr Leben:

- drei Phasen mit je eigenem Angriffsmuster und sichtbarer Ankündigung (die Warnflächen gibt es schon)
- ein Angriff, der fast tötet, wenn man ihn nicht ausweicht
- Zwischenwellen, in denen er unverwundbar ist
- Wut nach einer festen Zeit, damit Aussitzen nicht geht
- eigene Musik, eigene Arena (doppelte Größe hilft hier)
- Feuerschalen und Entscheidungen der Stunde schwächen ihn wie bisher, aber höchstens um ein Fünftel

Vorschlag für die Messlatte: Der Spielroboter mit durchschnittlicher Ausrüstung der Stufe verliert auf „Normal“ etwa zwei von drei Versuchen. Ein Mensch, der die Muster lernt, schafft es.

### 3.3 Was ein Aktende sonst noch bekommt

- eine Tafel „Ende des ersten Aktes“ mit Rückblick, Zeit, Entscheidungen und Stand der Herzwaage
- einen festen Lohn (ein legendäres Stück zur Wahl aus drei)
- danach Zugang zu Akt 2; die Stunden von Akt 1 bleiben über das Menü wiederholbar

---

## 4. Doppelt so große Stunden

„Doppelt so groß“ kann zweierlei heißen (Frage B1): doppelte Fläche (etwa 74 × 56 Zellen) oder doppelte Kantenlänge (104 × 80 Zellen, vierfache Fläche).

**Was das technisch bedeutet**

- Der Aufbau der Welt wächst mit der Fläche. Bei doppelter Fläche etwa 1,6 s, bei vierfacher über 3 s. Das ist am Handy spürbar.
- Mehr Dreiecke und Lichter im Bild gibt es nicht automatisch, weil die Kamera nur einen Ausschnitt sieht. Kritisch sind Dinge, die überall gleichzeitig rechnen: Wegfindung, schlafende Gegner, Schatten.
- Mehr Fläche ohne mehr Inhalt fühlt sich leer an. Größe braucht Dichte: mehr Räume, mehr Rudel, mehr Orte, Abzweigungen, Sackgassen mit Lohn.

**Umsetzung (Vorschlag)**

1. Die Karte wird in Felder geteilt, die erst gebaut und eingeblendet werden, wenn man sich nähert (Boden und Mauern sind schon in Feldern organisiert). So bleibt der Start schnell.
2. Die Stunde bekommt zwei bis drei Bereiche mit eigenem Charakter, verbunden durch Engstellen (Tor, Brücke, Schlucht). Der Hüter liegt im letzten.
3. Wegmarken: Feuerschalen dienen als Rückkehrpunkte nach einer Niederlage, damit lange Wege nicht bestrafen.
4. Die Minikarte bekommt eine große Ansicht (Taste, Antippen).
5. Messziel: Aufbau unter 1,2 s bis zum ersten Bild, mindestens 30 Bilder je Sekunde auf einem Mittelklasse-Handy bei „Niedrig“.

**Risiko:** Das ist der größte Eingriff der Fassung. Karten, Bot, Rundgang und Tests hängen an der festen Größe.

---

## 5. Lebendige Welt: Menschen und Tiere

Heute stehen am Eingang zwei Figuren und der Goldschmied; Schafe und Katzen gibt es nur als Suchaufgabe.

**Geplant**

- **Leute unterwegs (4 bis 8 je Stunde):** Tote aus Sandtor, die ihren Alltag weiterführen, weil niemand sie abholt. Sie gehen Wege ab, bleiben stehen, setzen sich, tragen etwas. Ein Satz beim Vorbeigehen (aus Textstapeln), kein Gesprächsfenster. Sie fliehen vor Kämpfen und kommen danach zurück.
- **Kleintiere (10 bis 20 je Stunde, je nach Landschaft):** Skarabäen, Eidechsen, Wüstenmäuse, Ibisse am Wasser, Falken am Himmel, Katzen auf Mauern, Fische in den Becken. Sie weichen aus, wenn man nah kommt, und sind reine Kulisse.
- **Natürlicher:** Blickrichtung zum Helden, wenn er vorbeigeht; kleine Zufallspausen; Gruppen (zwei reden miteinander); Tiere reagieren auf Feuer und Kampf.
- **Bauweise:** Menschen aus dem Baukasten `mensch.py` mit drei bis vier Trachten und zufälliger Tönung; Tiere wie Fuchs und Skorpion mit eigenem Skelett und Bewegungen aus Formeln. Ziel je Tier unter 400 Dreiecken und unter 60 KB.
- **Leistung:** Was weiter als 40 m weg ist, steht still und wird nicht gezeichnet. Höchstzahl je nach Grafikstufe.

Offen: Dürfen Tiere und Leute zu Schaden kommen, und was macht das mit der Herzwaage (Frage C3)?

---

## 6. Ton

### 6.1 Klangkulisse

Heute: ein Wind, ein Dröhnen, Fackeln, Musik mit Pausen.

Geplant sind drei Schichten je Ort:

1. **Grund:** Freiland (Nachtwind, ferne Schakale, Sand), Felder (Halme, Grillen), Grab (Tropfen, Steinraum), Rosetau (Glasklirren, hohler Wind), Höhle (Wasser, tausendfaches leises Pochen).
2. **Einzelne Ereignisse** in zufälligen Abständen und Richtungen: Vogelruf, fallender Stein, fernes Tor, Flügelschlag.
3. **Quellen im Raum:** Wasserbecken, Feuerschalen, Werkstatt (Hammer), Schreine (leiser Ton), Reigen der Irrlichter (Chor), Seelenkrüge (Herzschlag, der näher lauter wird).

Dazu: Hall je nach Raum (Freiland trocken, Grab hallig), Schritte je Boden (Pflaster, Feld, Glas, Wasser kommen dazu), Musik reagiert auf Lage (Erkunden, Gefahr nahe, Kampf, Hüter) statt nur auf den Hüter.

Aufwand an Aufnahmen: etwa 35 bis 45 neue Geräusche. Bei ElevenLabs kostet ein Geräusch 17 bis 50 Credits, zusammen etwa 1.000 bis 2.000 Credits (20 bis 40 Cent). Ladezeit: etwa 1,5 bis 2,5 MB mehr.

### 6.2 Ansagen, die passen

Heute passen die vier Aufnahmen zu keiner Stunde. Drei Ausbaustufen:

| Stufe | Was gesprochen wird | Zeichen | Credits | etwa |
|---|---|---|---|---|
| klein | Leitsatz jeder Stunde (12) | 1.250 | 1.250 | 0,25 $ |
| mittel | dazu Satz des Hüters und Epilog (36 Aufnahmen) | 4.000 | 4.000 | 0,80 $ |
| groß | dazu Rückblick, Akttafeln, Niederlage in Varianten, der Ba (rund 90 Aufnahmen) | 9.000 | 9.000 | 1,80 $ |

Zusätzlich möglich: eigene Stimmen für die zwölf Figuren am Eingang (nur der Gruß, je etwa 250 Zeichen, zusammen rund 3.000 Credits).

Umsetzung: Die Texte stehen bereits im Spiel. Ein Werkzeug (`tools/ton/ansagen.py`) erzeugt je Text eine Datei mit festem Namen (`vo_h03_lead.ogg`), das Spiel spielt die Datei, wenn sie da ist, und schweigt sonst. Ändert sich ein Text, wird nur diese Datei neu erzeugt. Jede Aufnahme prüfe ich per Rückumwandlung in Text gegen das Original, weil ich selbst nicht hören kann; über Tonfall und Aussprache ägyptischer Namen entscheidest du nach Hörproben.

Ladezeit: etwa 15 KB je Sekunde Sprache. Die mittlere Stufe sind rund 4 Minuten, also etwa 3,5 MB. Vorschlag: Sprache der späteren Akte erst nachladen, wenn der Akt beginnt.

---

## 7. Fähigkeitenbaum als Baum

Heute: Karten in einem Raster. Geplant ist ein gezeichneter Baum auf Papyrus.

**Aufbau (Vorschlag)**

- **Stamm:** die Klasse, unten in der Mitte.
- **Drei Äste** je Klasse mit eigenem Thema, zum Beispiel beim Eidträger: Klinge (Schaden), Schild (Aushalten), Laterne (Licht und Kontrolle).
- **Knoten** an den Ästen: Fähigkeiten (groß, rund), Verstärkungen einer Fähigkeit (klein, hängen an ihr), dauerhafte Stärken (Rauten), am Ende jedes Astes ein Schlüsselstein.
- **Regel:** Ein Knoten lässt sich nur lernen, wenn ein Nachbar gelernt ist. Dadurch entstehen Wege und echte Entscheidungen.
- **Bild:** Äste als gemalte Linien, die golden aufleuchten, wenn sie gelernt sind; Knoten mit den Relief-Symbolen aus 2.7.1; Verschieben und Zoomen mit Maus und Finger.

**Umfang:** Heute gibt es je Klasse 12 Knoten. Für einen Baum, der sich lohnt, braucht es 25 bis 35. Das heißt neue Verstärkungen und Stärken, also Balancearbeit für vier Klassen (Frage E2).

**Spielstand:** Alte Punkte werden zurückgegeben; man verteilt neu.

---

## 8. Die Pforte

Heute: ein grauer Steinrahmen, der aus dem Boden wächst.

Geplant:

- ein ägyptisches Tor (Pylon) mit Hohlkehle, geflügelter Sonnenscheibe und zwei Wächterfiguren, in Stein und Gold der jeweiligen Stunde
- im Durchgang ein Blick in die nächste Stunde: ihre Farbe, ihr Dunst, ihr Licht (eine bemalte Fläche mit Bewegung, kein echtes zweites Bild, damit es im Browser läuft)
- Erscheinen als kleine Szene: Der Boden reißt auf, Sand rieselt, Licht fällt heraus, die Kamera fährt kurz zurück
- über dem Durchgang der Name der nächsten Stunde in Hieroglyphen-Fries und Schrift
- am Aktende ein größeres Tor mit eigenem Aussehen

---

## 9. Was ich zusätzlich vorschlage

Nach Nutzen sortiert. Nichts davon ist beschlossen.

1. **Rückkehrpunkte an Feuerschalen.** Wird mit doppelt so großen Karten fast nötig.
2. **Große Karte** auf Tastendruck mit Aufgaben und Orten.
3. **Gegner mit Eigenheiten je Akt** (in Akt 1 zum Beispiel Schildträger, die man umgehen muss; Rufer, die Verstärkung holen).
4. **Die Stunden 2 und 4 bis 12 optisch durchsehen** wie Stunde 1 und 3 in Fassung 3.0.
5. **Das Rätsel der Ba ohne Namen weiterführen:** Am Aktende lässt sich aus den gesammelten Silben ein Name zusammensetzen.
6. **Erste Hilfe für Neue:** drei kurze Hinweise in der ersten Minute (laufen, schlagen, ausweichen), abschaltbar.
7. **Gamepad** am Rechner.
8. **Kleinerer Download:** eine eigens gebaute Engine ohne ungenutzte Teile könnte die 39,5 MB deutlich senken. Aufwand unsicher, Wirkung groß.
9. **Schwierigkeit nachträglich wechseln** im Menü.
10. **Barrierefreiheit:** Schriftgröße, Farbschwäche-Modus für Warnflächen, Untertitel zu allen Ansagen (Text ist ohnehin da).

---

## 10. Etappen (Vorschlag)

| Etappe | Inhalt | Warum in dieser Reihenfolge |
|---|---|---|
| 3.1 | Pforte neu, Klangkulisse, Ansagen | sofort hör- und sichtbar, geringes Risiko |
| 3.2 | Leute und Kleintiere, Stunden 2 und 4 bis 12 durchsehen | füllt die Welt, bevor sie wächst |
| 3.3 | Fähigkeitenbaum als Baum | eigenständig, braucht Balance und Zeit zum Spielen |
| 3.4 | Doppelte Karten mit Bereichen und Rückkehrpunkten, große Karte | größter Eingriff, braucht alles Vorige |
| 4.0 | Akte, Endgegner von Akt 1, Akttafeln | setzt große Karten und den neuen Baum voraus |

Nach jeder Etappe: Spieltest, Klassentests, Bots, Browser, Veröffentlichung.

---

## 11. Kosten und Grenzen

- **Geld:** Nur Ton kostet etwas. Je nach Wahl zwischen etwa 0,25 $ und 3 $ bei ElevenLabs. Alles andere entsteht ohne Ausgaben. Ich löse nichts aus, was du nicht mit Betrag freigegeben hast.
- **Ladezeit:** Ton und neue Modelle fügen 5 bis 8 MB hinzu, wenn nichts nachgeladen wird. Gegenmaßnahme: Nachladen je Akt.
- **Was ich nicht prüfen kann:** wie etwas klingt, und wie es sich auf einem echten Handy anfühlt. Dafür brauche ich dein Urteil nach jeder Etappe.
- **Balance:** Der Endgegner und der neue Baum brauchen mehrere Runden. Der Roboter misst nur grob.

---

## 12. Fragebogen

Kurz antworten genügt, zum Beispiel „A1: 4, A2: nur Akt 1“. Wo ich einen Vorschlag habe, steht er dabei.

### A · Akte

- **A1** Wie viele Stunden hat Akt 1? *(Vorschlag: 1 bis 4, wie von dir genannt)*
- **A2** Sollen Akt 2 und 3 schon in 4.0 als Akte ausgebaut werden, oder zuerst nur Akt 1? *(Vorschlag: nur Akt 1 voll, die anderen bekommen Tafeln)*
- **A3** Endgegner von Akt 1: a) Türhüter in drei Phasen, b) neuer Gegner „der erste Stern“, c) Vorgriff auf den Sammler, d) eigene Idee? *(Vorschlag: a mit Elementen von b)*
- **A4** Wie schwer ist „echt schwer“? a) man stirbt ein paar Mal und schafft es am selben Abend, b) man muss Ausrüstung und Baum dafür anpassen, c) gnadenlos. *(Vorschlag: a auf Normal, b auf Schwer, c auf Albtraum)*
- **A5** Darf man nach einer Niederlage direkt vor dem Endgegner neu beginnen, oder muss man den Weg noch einmal gehen?
- **A6** Lohn am Aktende: ein legendäres Stück zur Wahl aus drei? Etwas anderes?

### B · Größe der Welt

- **B1** „Doppelt so groß“: doppelte Fläche (etwa 150 × 110 m) oder doppelte Kantenlänge (208 × 160 m, vierfache Fläche)? *(Vorschlag: doppelte Fläche)*
- **B2** Wie lange soll eine Stunde ungefähr dauern? Heute sind es etwa 8 bis 12 Minuten.
- **B3** Rückkehrpunkte an Feuerschalen nach einer Niederlage: ja oder nein? *(Vorschlag: ja)*
- **B4** Sollen alle zwölf Stunden wachsen oder zuerst nur die vier von Akt 1? *(Vorschlag: zuerst Akt 1)*
- **B5** Mehr Gegner im Verhältnis zur Fläche, oder mehr Ruhe und Erkunden dazwischen?

### C · Leute und Tiere

- **C1** Welche Tiere sind dir wichtig? (Skarabäen, Eidechsen, Mäuse, Ibisse, Falken, Katzen, Fische, Schlangen, Esel …)
- **C2** Sollen die Leute etwas sagen, wenn man vorbeigeht (ein Satz als Sprechblase), oder stumm bleiben?
- **C3** Können Leute und Tiere zu Schaden kommen? Wenn ja: Wiegt das auf der Herzwaage?
- **C4** Sollen manche Leute kleine Aufgaben oder Tauschgeschäfte anbieten, oder reine Kulisse sein? *(Vorschlag: Kulisse, eine von fünf mit kleinem Auftrag)*
- **C5** Sind es Tote aus Sandtor (passt zur Geschichte) oder soll man das offenlassen?

### D · Ton

- **D1** Ansagen: klein (12 Leitsätze, etwa 0,25 $), mittel (dazu Hüter und Epilog, etwa 0,80 $), groß (rund 90 Aufnahmen, etwa 1,80 $) oder gar keine? Bitte mit Betrag freigeben.
- **D2** Bleibt die Stimme „Samuel Storm“, oder möchtest du Hörproben von zwei, drei anderen (kostet je Probe etwa 2 Cent)?
- **D3** Sollen die Figuren am Eingang eigene Stimmen bekommen (nur der Gruß, rund 3.000 Credits, etwa 0,60 $)?
- **D4** Klangkulisse: rund 40 neue Geräusche für etwa 0,20 bis 0,40 $ freigeben?
- **D5** Wie klingen die neuen Schritte aus 3.0 für dich: gut, zu leise, zu spitz, zu dumpf?
- **D6** Musik: Reichen die acht Stücke, wenn sie auf die Lage reagieren, oder sollen neue dazu (Gomo, kostet Credits)?

### E · Fähigkeitenbaum

- **E1** Gefällt dir die Regel „lernbar nur neben schon Gelerntem“, oder soll alles frei wählbar bleiben und nur das Bild ein Baum sein?
- **E2** Umfang: bei den heutigen 12 Knoten bleiben und nur anders darstellen, oder auf 25 bis 35 Knoten je Klasse ausbauen? *(Vorschlag: ausbauen, in zwei Schritten)*
- **E3** Drei Äste je Klasse: einverstanden, oder lieber zwei große?
- **E4** Soll Umlernen weiter Scherben kosten, oder am Goldschmied bzw. an einem eigenen Ort (Schrein des Thot) stattfinden?
- **E5** Gibt es ein Vorbild, dessen Baum dir gefällt (nur als Richtung für Aufbau und Gefühl)?

### F · Pforte

- **F1** Soll man durch die Pforte in die nächste Stunde hineinsehen können? *(Vorschlag: ja, als gemalter Blick)*
- **F2** Kurze Szene beim Erscheinen (2 bis 3 Sekunden, Kamera fährt zurück): ja oder nein?
- **F3** Soll die Pforte je Stunde anders aussehen oder überall gleich, nur am Aktende größer?

### G · Reihenfolge und Rahmen

- **G1** Passt die Reihenfolge der Etappen in Abschnitt 10, oder ist dir etwas wichtiger?
- **G2** Welche Punkte aus Abschnitt 9 sollen hinein? (Nummern genügen)
- **G3** Gesamtbudget für Ton in dieser Fassung: Welchen Höchstbetrag gibst du frei?
- **G4** Worauf spielst du am meisten: Rechner, iPhone, beides gleich?
- **G5** Gibt es etwas an 3.0, das dich stört und zuerst behoben werden soll?
