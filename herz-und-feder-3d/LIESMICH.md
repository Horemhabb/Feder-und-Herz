# Herz und Feder · Probestunde in 3D

Die erste Stunde der Nacht, „Das Tor des Westens“, als Probe in der Spiel-Engine Godot.
Die Webfassung (Ordner `nebelmark/`) bleibt das eigentliche Spiel. Diese Probe soll zeigen,
ob sich Bewegung, Licht und Ton in 3D echter anfühlen.

## So startest du die Probe (Windows)

**Weg A: fertiges Programm.** Wenn du die Datei `HerzUndFeder-Probe.zip` bekommen hast:
entpacken, `HerzUndFeder.exe` doppelklicken. Windows warnt bei unbekannten Programmen
(„Der Computer wurde durch Windows geschützt“): „Weitere Informationen“ und dann
„Trotzdem ausführen“ wählen.

**Weg B: mit Godot.** Dauert fünf Minuten und du kannst danach selbst hineinschauen.

1. Godot 4.7 herunterladen: https://godotengine.org/download/windows/ („Godot Engine“, nicht „.NET“).
   Es ist eine einzelne Datei, keine Installation.
2. Diesen Ordner `herz-und-feder-3d` auf den PC holen (als ZIP von GitHub oder aus der Datei, die Claude geschickt hat) und entpacken.
3. Godot starten, „Importieren“ wählen, die Datei `project.godot` in diesem Ordner auswählen.
4. Beim ersten Öffnen bereitet Godot die Modelle vor (etwa eine Minute). Danach **F5** drücken.

## Mac, Windows und Web (auch iPhone)

Das Projekt hat vier Export-Voreinstellungen (`export_presets.cfg`): **macOS**, **Windows**, **Web** und Linux.

- **Automatisch:** Bei jedem Push nach `main` baut GitHub (Workflow `.github/workflows/bauen.yml`) die **Web-Fassung**
  und stellt sie auf GitHub Pages. Mac und Windows ruhen vorerst; ihre Voreinstellungen bleiben im Projekt.
- **Selbst bauen:** In Godot „Projekt → Exportieren“, Voreinstellung wählen, „Projekt exportieren“.
  Beim ersten Mal bietet Godot an, die Exportvorlagen herunterzuladen (rund 1,2 GB).
  Von der Befehlszeile: `godot --path . --export-release macOS` (oder `Windows`, `Web`). Die Ergebnisse landen in `build/`.
- **Mac:** `build/HerzUndFeder-Mac.zip` entpacken. Das Programm ist nicht bei Apple angemeldet. Beim ersten Start
  deshalb Rechtsklick auf das Programm und „Öffnen“ wählen, oder in den Systemeinstellungen unter
  „Datenschutz & Sicherheit“ auf „Dennoch öffnen“ klicken.
- **Web:** Der Ordner `build/web/` muss von einem Webserver über https ausgeliefert werden; ein Doppelklick auf
  `index.html` genügt nicht. Zum Ausprobieren am eigenen Rechner: `python3 -m http.server` in `build/web/`
  und dann `http://localhost:8000` öffnen.
- **Vollbild im Browser:** Beim Druck auf „Eintreten“ schaltet das Spiel selbst auf Vollbild (der Browser verlangt dafür
  eine Berührung). Danach schalten der Knopf „Vollbild“ (Handy) oder die Taste V um, mit Esc verlässt der Browser es wieder.
  **Auf dem iPhone gibt es für Webseiten kein Vollbild**: Dort unten auf Teilen tippen, „Zum Home-Bildschirm“ wählen und
  das Spiel vom Symbol aus starten, dann läuft es ohne Adressleiste. Die Tafel zu Beginn weist darauf hin.
- **iPhone und iPad:** die Web-Adresse in Safari öffnen und das Gerät quer halten. Auf Geräten mit Berührungsbildschirm startet es von selbst im **Handy-Modus**:
  größere Anzeige, Knöpfe für Vollbild, Beutel, Grafik, Ton und Bildrate, niedrige Grafik und geringere 3D-Auflösung.
  Finger halten heißt laufen, Gegner antippen heißt angreifen (auch ein flüchtiger Tipp), Fähigkeiten unten antippen (auch mit dem zweiten Finger im Laufen).
  Am Rechner lässt sich der Handy-Modus mit `godot --path . -- --touch` ansehen.

## Steuerung

| Taste | Wirkung |
|---|---|
| W A S D oder linke Maustaste halten | laufen |
| Linke Maustaste auf einen Gegner | hinlaufen und zuschlagen |
| Umschalt + linke Maustaste | auf der Stelle zuschlagen |
| 1 | Falkenkreis (Rundumschlag) |
| 2 | Sturz des Falken (Sprung zum Mauszeiger) |
| 3 | Eid der Maat (stärker und zäher für 6 Sekunden) |
| 4 | Blick des Udjat (betäubt alles ringsum) |
| Rechte Maustaste | Strahl des Re |
| Q | Rotbier der Sachmet (heilt) |
| F | Bildrate anzeigen |
| G | Grafik hoch/niedrig (ohne Schatten und Glühen) |
| M | Ton an/aus |
| I oder Tab | Tasche: Ausrüstung, Werte, Material, Aufwerten, Neuwürfeln, Grabräuber, Buch des Thot (das Spiel steht, solange sie offen ist) |
| V | Vollbild an/aus |
| E oder Eingabe | Fenster bestätigen |

## Was drin ist

- Eidträger als 3D-Figur mit ineinander überblendeten Bewegungen
- Laterne mit Schattenwurf, Fackeln, Mondlicht, Nebel
- Ruhelose, die am Boden liegen und aufstehen, wenn du näher kommst; Priester, die schießen; Mahaf als Hüter
- Mauern und Eckpfeiler, die die Figur verdecken würden, sinken in den Boden
- Steinmauern aus Sandstein mit hellem Gesims, die Gruft des Hüters aus dunklem Granit mit Feuerschalen auf den Säulen,
  Böden aus Gruftplatten, Gänge mit Wüstensand (Texturen von Higgsfield)
- Geräusche, Umgebungston und Erzählerstimme von ElevenLabs
- Tafel am Anfang, Pforte mit Bestätigung am Ende

### Aus der 2D-Fassung übernommen (Etappe 1 von 4: Gerüst)

Regeln und Zahlen stammen aus `nebelmark/src` (Daten in `scripts/daten.gd`, Figur in `scripts/spiel.gd`).
- **Startbildschirm** mit Schwierigkeit (Normal, Schwer, Albtraum), Hardcore und „Weiterspielen“.
- **Spielstand** (`user://spielstand.json`, im Browser dauerhaft gespeichert): Stufe, Erfahrung, Ausrüstung, Tasche,
  Scherben, Material, Buch des Thot, Schwierigkeit. Wie im Original beginnt eine Stunde nach dem Laden von vorn.
  Hardcore: Stirbt die Figur, ist der Spielstand sofort gelöscht.
- **Werte und Stufen**: Schaden, Leben, Rüstung, Krit, Angriffstempo, Lauftempo, Kraft je Sekunde, Dornen, Lebensraub,
  Erfahrung und Beuteglück nach den Formeln des Originals; Erfahrungskurve 60 · Stufe^1,6.
- **Gegner** nach Stunde und Schwierigkeit skaliert, Elite-Gegner (flink, zäh, rasend) mit goldenem Ring.
- **Beute**: Gegenstände in vier Seltenheiten mit 12 Affixen und 16 legendären Kräften (die für den Eidträger wirken),
  Scherben, vier Materialien, Isisblut, Seiten aus dem Buch des Thot. Truhen (Truhe, Eisentruhe, Prunktruhe) mit
  Fundfenster, zerschlagbare Fässer und Kisten, der Hüter lässt vier Gegenstände fallen.
- **Tasche**: acht Ausrüstungsplätze, Werte, Material, 32 Plätze, Vergleich mit dem Angelegten (▲), Anlegen,
  Aufwerten bis +5, Neuwürfeln eines Affixes, Wegwerfen, „Alles Gewöhnliche wegwerfen“, Grabräuber, Buch des Thot.

Noch offen: Etappe 2 (vier Klassen, Fähigkeitenbaum), Etappe 3 (alle Gegnerarten und Hüter), Etappe 4 (zwölf Stunden,
Kartengenerator, Karte, Stundenwahl).

## Was noch Platzhalter ist

- **Figuren, Fackeln, Fässer und Kisten** stammen aus den freien KayKit-Paketen (CC0) und sehen comichaft und mittelalterlich aus.
  Sie stehen für Bewegung, Licht und Ton, nicht für das endgültige Aussehen. Animationsnamen stehen nur in den
  `ANIM`-Tabellen in `scripts/hero.gd` und `scripts/foe.gd`; ein anderes Modell ist dort ein Tausch.
- **Musik** gibt es keine. Die ElevenLabs-Anbindung dieser Sitzung erzeugt Geräusche und Sprache, aber keine Musik;
  als Ersatz läuft ein dunkler Klangteppich.
- Fähigkeitenbaum, die drei übrigen Klassen, die übrigen Gegnerarten und die Stunden 2 bis 12 folgen in den
  nächsten Etappen. Bis dahin beginnt nach der Pforte die erste Stunde von vorn, die Figur behält alles.

## Für Entwickler

- `scripts/main.gd` baut Welt, Licht und Gegner aus der Karte `MAP` und führt Kamera und Eingabe.
- `scripts/actor.gd`, `hero.gd`, `foe.gd`: Figuren. `scripts/hud.gd`: Anzeige. `scripts/sfx.gd`: Ton.
- Testmodus: `godot --path . -- --autotest` lässt einen Bot die Stunde durchspielen und speichert Bilder nach `test_out/`.
- Rundgang: `godot --path . -- --autotest --rundgang` setzt die Figur an feste Stellen (Start, Gang, Halle, Gruft …) und macht je ein Bild, auch mit niedriger Grafik.
- Mauern und Sockel, die nie absinken, fasst `main.gd` je Material zu einem einzigen Körper zusammen (`_fest`, `_fest_bauen`).
  Das spart Zeichenaufrufe, vor allem beim Schattenwurf.
- `tools/hol_godot.sh` lädt Godot 4.7.2 für Linux (zum Testen ohne Bildschirm).

### Stein- und Bodentexturen

- Liegen verkleinert (1024 px, JPG) in `textures/`, je mit Normalenkarte `_n.jpg` für das Relief im Fackellicht.
  Die 2048er Originale von Higgsfield liegen nicht im Repo.
- `tools/texturen.py` lädt die Originale, glättet die Kachelnaht, verkleinert und schreibt die Normalenkarte.
- Welche Fläche welche Textur trägt, steht in der Tabelle `SURF` oben in `scripts/main.gd` (Datei, Kachelgröße in Metern, Tönung).
  Die Mauern sind eigene Steinkörper mit passenden UV-Koordinaten (die KayKit-Mauern nutzten nur einen Farbatlas).
- **Wüstensand (T09)** ist eingebaut: Die Gänge und das Gelände hinter den Mauern tragen Sand statt Pflaster bzw. dunkler Erde.
- Taste G (niedrige Grafik) schaltet zusätzlich die Normalenkarten und die anisotrope Filterung ab.

## Herkunft

- Modelle: KayKit Adventurers, KayKit Skeletons, KayKit Dungeon Remastered von Kay Lousberg, Lizenz CC0.
- Stein- und Bodentexturen: erzeugt mit Higgsfield.
- Ton: erzeugt mit ElevenLabs (Sound Effects v2, Sprache mit der Stimme „Samuel Storm“).
