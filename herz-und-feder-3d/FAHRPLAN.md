# Fahrplan: von der Bildrunde zum runden Spiel

Stand 23.11.2026, Fassung 2 (nach der Prüfung durch einen unabhängigen Kritiker).
Grundlage: Berichte von Spieldirektor und Technikdirektor (beide haben den Code gelesen), sechs Recherchen und vier Vorgaben des Auftraggebers.

## 1. Kurzfassung

- **Engpass ist die Aufmerksamkeit des Auftraggebers** (bis 5 Stunden je Woche), nicht der Code und nicht die Rechenzeit. Das Projekt ist acht Tage alt und hat 108 Commits: Schreiben geht schnell, Prüfen und Spielen nicht.
- **Ziel in drei Monaten:** Akt 1 (Stunden 1 bis 4) ist ein rundes Ganzes mit Einführung und Schluss, und drei bis fünf Fremde haben es gespielt.
- **Ziel in einem Jahr:** Stunden 1 bis 8 lassen sich durchspielen, es gibt eine Windows-Fassung und eine Webfassung. Akt 3 in dieser Zeit ist unwahrscheinlich.
- **Große Wünsche** (schönerer Renderer für den PC, eigener Ton, neue Figurenhaut) laufen als **Proben mit Tor**: ein kleiner Versuch, dann die Entscheidung. Keine davon blockiert das Spiel.

## 2. Vorgaben

| Vorgabe | Folge für den Plan |
|---|---|
| Lernprojekt, kein Verkauf geplant | Lizenzen werden vermerkt, sind aber kein Ausschlussgrund. Kein Aufwand für Steam, Recht, Englisch. |
| Desktop schöner, Web als Demo | Der zweite Renderweg bleibt im Plan, aber als Probe nach Etappe B (siehe 5). |
| Bis 5 Stunden je Woche | Jede Etappe nennt die Stunden des Auftraggebers. Claude trifft die Vorauswahl bei Bildern, er bestätigt. |
| Nur offen und lokal | Keine bezahlten Dienste. |

## 3. Was der Kritiker einwandte und was daraus wurde

| Einwand | Entscheidung |
|---|---|
| Die Wochenangaben waren geschönt (19 Wochen im Plan, ehrlich 25 bis 30). | Übernommen. Jede Etappe nennt jetzt die Stunden des Auftraggebers. |
| Das Sicherheitsnetz fehlt: Der Bau führt keinen Test aus und veröffentlicht sofort. | **Erledigt am 23.11.:** Der Spieltest (110 Prüfungen, 74 Sekunden) läuft bei jedem Pull Request und vor jeder Veröffentlichung. Gegenprobe mit absichtlichem Fehler: Lauf wird rot. |
| Sitzungen ohne Gedächtnis bauen auf veralteten Dokumenten auf. | Übernommen: `CLAUDE.md` im Wurzelordner als Übergabeseite, `LIESMICH.md` berichtigt. |
| Niemand außer dem Auftraggeber spielt. | Übernommen als eigene Etappe C. |
| Forward+ streichen: verdoppelt jede Lichtabstimmung, und nur der Auftraggeber sieht den Gewinn. | **Nicht gestrichen, aber verschoben und verkleinert.** Der Auftraggeber will den schöneren PC ausdrücklich. Es gibt erst eine Probe von einem Tag (siehe 5). |
| Ton per KI: drei ungetestete Modelle auf zwei Rechnern. | Verkleinert auf eine Probe (Musik), der Rest später. |
| Akt 2 mit doppelter Fläche und zwei eigenen Kämpfen ist zu groß. | Verkleinert: normale Fläche, ein eigener Kampf (Apophis). |
| Der Fehler mit dem verbrannten Ruder darf nicht vier Wochen warten. | Vorgezogen in Etappe A. |
| „Keine Bildpolitur mehr“ widersprach Phase 2 und der Figurenhaut. | Bildarbeit wird nach den offenen Stufen eingefroren. Die Figurenhaut ist eine Probe. |
| Auswahltafeln mit über 140 Bildern passen nicht zu „drei Entscheidungen je Woche“. | Claude trifft die Vorauswahl anhand der Tafel, der Auftraggeber bestätigt oder ändert. |

## 4. Die Etappen

### Etappe A: Netz und Gedächtnis (2 Wochen, Auftraggeber etwa 6 Stunden)

| Was | Stand |
|---|---|
| Spieltest läuft beim Bauen und bricht bei Fehlern ab | erledigt |
| `CLAUDE.md` als Übergabeseite, `LIESMICH.md` berichtigt | erledigt |
| Fehler im Ende „In der Schwebe“: das Ruder erscheint, auch wenn es verbrannt wurde (`geschichte.gd:267`) | offen |
| Offene Bildstufen abschließen: `symbole_neu`, `portraets_leute_nah` (laufen), danach `portraets_figuren_nah` und `texturen_neu` in einer Nacht | offen |
| Fähigkeitenbaum zeigt Symbole ohne Rahmen | offen |
| **Danach Bildarbeit einfrieren** bis Etappe D | |

### Etappe B: Akt 1 rund (6 bis 8 Wochen, Auftraggeber etwa 25 Stunden)

| Was | Fertig, wenn |
|---|---|
| **Einführung** in den ersten fünf Minuten, abschaltbar | ein Neuling kommt ohne Erklärung durch Stunde 1 |
| **Bewegungsgefühl, klein gehalten:** Überblendbaum für Gehen und Laufen, Schrittlänge passt zur Geschwindigkeit, Treffer-Zucken, kurzer Trefferstopp | Füße rutschen nicht mehr sichtbar |
| **Entscheidungen haben Folgen** innerhalb von Akt 1: je Wahl ein Rückbezug in einem späteren Gespräch | jede Entscheidung der Stunden 1 bis 4 taucht wieder auf. **Erledigt:** dazu Haremhab (2, 4), Hatschepsut (3) und der Ba als Begleiter (GESCHICHTE.md Teil 7) |
| **Sichtbarer Schluss von Akt 1** mit Rückblick auf die Entscheidungen und Abspann | nach Stunde 4 gibt es einen Punkt zum Aufhören. **Rückblick steht**, Abspann offen |
| Gamepad auch in Klassenwahl, Tasche und Menü; eigener Regler für Geräusche | |
| `main.gd` (2.428 Zeilen) in vier Teile zerlegen, Schritt für Schritt hinter den Tests | keine Datei über 1.200 Zeilen, Tests grün |
| Automatische Bildschirmfotos je Stunde beim Bauen | der Auftraggeber sieht Änderungen im Pull Request, ohne zu starten |

### Etappe C: Fremde spielen (2 Wochen, Auftraggeber etwa 6 Stunden)

| Was | Fertig, wenn |
|---|---|
| Drei bis fünf Leute bekommen den Link zur Webfassung und einen Fragezettel mit fünf Fragen | Antworten liegen vor |
| Die drei häufigsten Stolpersteine beheben | |
| Urteil des Kritikers über Akt 1 | |

### Etappe D: Akt 2, schlank (4 bis 6 Monate, Auftraggeber etwa 60 Stunden)

| Was | Fertig, wenn |
|---|---|
| Stunden 5 bis 8 mit normaler Fläche, je Stunde ein eigenes Landschaftsmerkmal (Wasser bei Apophis, Grüfte) und eigene Oberflächen (Bildstufe `texturen_stunden`) | Stunde 6 fühlt sich nicht wie Stunde 2 an |
| Ein eigener Kampf: Apophis (Stunde 7) nach dem Muster des Türhüters | drei Phasen, eigene Arena |
| Zwei neue Gegnerarten aus der Figurenfabrik | |
| Offene Fäden schließen (Rätsel der Ba ohne Namen, wer die Leute sind, Buchseiten 13 bis 24) | |
| Vorläufiges Ende nach Stunde 8 | |

### Danach, ohne Termin

Eigener Kampf für den Sammler, Akt 3, Endspiel mit Regeln statt reiner Zahlen, mehrere Speicherplätze.

## 5. Proben mit Tor

Jede Probe ist ein kleiner Versuch. Besteht sie ihr Tor nicht, wird der Weg verworfen und vermerkt.

| Probe | Wann | Umfang | Tor |
|---|---|---|---|
| **Forward+ für den PC** (Volumennebel, Umgebungsverdeckung, weichere Schatten) | nach Etappe B | ein Tag: Stunde 1 mit umgeschaltetem Renderer und einem einzigen Helligkeitsfaktor | Sieht ohne Abstimmung je Stunde klar besser aus und läuft neben ComfyUI flüssig. Sonst bleibt es bei einem Renderer. |
| **Freie Bewegungsbibliothek** (Quaternius, gemeinfrei) | in Etappe B | ein Abend | Eine Figur spielt drei fremde Bewegungen ohne verdrehte Knochen. |
| **Musik lokal** (ACE-Step 1.5 auf der AMD-Karte) | nach Etappe C | ein Abend, dann Nachtläufe | Ein Stück klingt nicht schlechter als die jetzige Musik und läuft als Schleife. |
| **Figurenhaut** (ein Bild je Feld der Tafel) | in Etappe D | eine Figur | Im Spiel bei 60 bis 90 Pixel Höhe sichtbar besser. |
| **Bildzeit halbieren** (Zeit je Schritt messen, 512 Pixel plus Hochskalieren) | vor der nächsten großen Bildnacht | ein Abend | Mindestens ein Drittel schneller bei gleicher Güte. |

## 6. Wie gearbeitet wird

- **Claude** arbeitet in Cloud-Sitzungen. Jede Änderung ist ein Pull Request, der Spieltest läuft automatisch. Seit dem 23.11. kann Claude das Spiel in seiner eigenen Umgebung starten und prüfen.
- **Der Auftraggeber** spielt je Woche 30 Minuten, bestätigt die Vorauswahl bei Bildern und führt Pull Requests zusammen.
- **Der PC** rechnet nachts, solange Bildstufen oder Proben offen sind.
- **Team:** Agenten nur, wenn Arbeit wirklich nebeneinander läuft. Am Ende jeder Etappe prüft ein unabhängiger Kritiker.
- **Möglicher Hebel:** eine geplante wöchentliche Sitzung, die den nächsten offenen Posten dieser Datei bearbeitet und einen Pull Request öffnet. Dann kostet der Fortschritt den Auftraggeber nur noch das Prüfen. Noch nicht eingerichtet.

## 7. Was wir nicht tun

| Nicht | Grund |
|---|---|
| Figuren aus Bild-zu-3D (TRELLIS.2) | 4 bis 8 Stunden Handarbeit je Figur, läuft auf der AMD-Karte unsicher, automatisches Rigging unreif |
| Bewegung aus Text oder Video | bei 60 bis 90 Pixel hohen Figuren kaum sichtbar, braucht meist Nvidia |
| Alle zwölf Stunden zugleich ausbauen | Akt für Akt, jeder abgeschlossen |
| Weitere Klassen, Mehrspieler, offene Welt | sprengt den Rahmen |
| Englisch, Steam, Rechtliches | kein Verkauf geplant |
| WebGPU, gebackene Lightmaps | kein offizieller Weg, Karten entstehen im Code |
| Sprachaufnahmen für alle Figuren | erst wenn die Texte stehen |

## 8. Ungeprüfte Annahmen

- Die Rechercheure konnten mehrere Originalseiten (Hugging Face, Godot-Doku) nicht öffnen. Lizenz- und Hardwareangaben zu ACE-Step, Stable Audio 3, Qwen3-TTS und TRELLIS.2 stammen aus Suchauszügen.
- Kein offenes Tonmodell ist auf der RX 6800 XT ausprobiert.
- Die Stundenangaben des Auftraggebers sind Schätzungen des Kritikers, keine Messung.
- Der Spieltest prüft Regeln und Abläufe, kein Bild. Was schief aussieht, fällt ihm nicht auf.
