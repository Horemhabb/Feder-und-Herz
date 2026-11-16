# Herz und Feder · 3D-Fassung 2.0

Die zwölf Stunden der Nacht in der Spiel-Engine Godot (begonnen als Probe der ersten Stunde, „Das Tor des Westens“).
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
| W A S D oder linke Maustaste halten | laufen (steht ein Gegner in Reichweite und du tust nichts, greift die Figur von selbst an) |
| Linke Maustaste auf einen Gegner | hinlaufen und zuschlagen |
| Umschalt + linke Maustaste | auf der Stelle zuschlagen |
| 1 2 3 4 | Fähigkeiten der Klasse, gezielt auf den Mauszeiger (auf dem Handy: Knöpfe unten, sie zielen selbst) |
| Rechte Maustaste | fünfte Fähigkeit der Klasse |
| K | Fähigkeitenbaum |
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

### Etappe 2: vier Klassen und Fähigkeitenbaum

| Klasse | Modell (KayKit) | Standardangriff | 1 · 2 · 3 · 4 · rechte Maustaste |
|---|---|---|---|
| Eidträger | Ritter mit Zweihänder | Hieb | Falkenkreis · Sturz des Falken · Eid der Maat · Blick des Udjat · Strahl des Re |
| Priester des Schu | Barbar ohne Waffe | Faustfolge, jeder dritte Schlag weiter und härter | Fäuste des Month · Schritt des Schu · Kreis des Ka · Gebs Lachen · Atem des Schu |
| Wüstenjägerin | Schurkin mit Armbrust (statt Bogen), Fuchs als leuchtender Geist | Pfeil | Neiths Fächer · Sprung der Gazelle · Upuauts Hatz · Sieben Pfeile der Sachmet · Pfeil der Neith |
| Sternleserin | Magierin mit Stab | Funke, durchschlägt einmal | Zorn des Seth · Schritt durch die Duat · Seschats Maß · Hu, das Machtwort · Fallender Stern der Nut |

- Klassenwahl auf dem Startbildschirm mit den gemalten Porträts der 2D-Fassung; Symbole der Fähigkeiten aus dem Original.
- **Fähigkeitenbaum** (K, auf dem Handy „Fähigk.“): ein Punkt je Stufe, fünf Ränge je Fähigkeit (+12 % Stärke,
  Hilfsfähigkeiten −6 % Abklingzeit), ab Rang 2 Wucht oder Eile, sechs dauerhafte Stärken, ein Schlüsselstein je
  Klasse ab 8 verteilten Punkten, Zurücksetzen für 10 + 3 × Stufe Scherben.
- Daten in `scripts/klassen.gd`; Klassentest: `godot --path . -- --neu --klasse=jaegerin --klassentest`.

### Etappe 3: Gegner und Hüter

- Neun Gegnerarten aus der 2D-Fassung mit ihren Kampfweisen: **Irrende Ba** (leuchtende Lichter, schwärmen und beißen),
  **Tefens Brut** (Skorpione, Tiere: fliehen vor Upuauts Hatz), **Sebau-Krieger** (holen sichtbar aus: roter Kegel),
  **Sebau-Priesterin** und **Erloschene** (halten Abstand und schießen, ein gemeinsamer Schusstakt je Schwierigkeit),
  **Sebau-Koloss** (Aufschlag mit rotem Kreis), **Ruhelose** (liegen am Boden und stehen auf), **Herzlose** (schnell, glühen).
  Aussehen: KayKit-Skelette, eingefärbt; Lichter und Skorpione sind aus Grundformen gebaut.
- Rudel nach den Daten der Stunde (`scripts/stunden.gd`), Größe je Schwierigkeit, Aufstellung als Lager (mit Feuer),
  Wache, Streife, Ruhe oder Hinterhalt (unsichtbar, bis du nah bist). Sie bemerken dich mit Sichtkegel („?“, dann „!“),
  bei Schwer und Albtraum rufen sie Nachbarrudel. Nur so viele greifen zugleich an, wie die Schwierigkeit erlaubt.
- **Hüter**: Gestalt und Name aus der Stunde (in Stunde 1 Mahaf als großes Licht), Geschossring, Beschwörung von
  Dienern, Ansturm mit rotem Streifen als Ansage, unter 30 % Leben schneller.

### Etappe 4: zwölf Stunden mit generierten Karten

- Jede Stunde wird beim Betreten neu erzeugt (`scripts/karte.gd`, nach dem Kartengenerator der 2D-Fassung):
  Stunde 1 ist Freiland mit Felsen, Glasnadeln und Ruinen, die Stunden 2 bis 5 sind Dungeons
  (Felder von Wernes: Lehmruinen · König ohne Namen: Grabkammern · Rosetau: Glas · Höhle des Sokar: Höhle).
  Die Stunden 6 bis 12 nutzen Landschaft und Hüter-Gestalt einer früheren Stunde und mischen alle Rudel.
  Nach der zwölften Stunde beginnt die nächste Nacht, die Gegner werden weiter stärker.
- `scripts/welt.gd` baut daraus Böden, Mauern (unterschiedlich hoch, Reste und Türme), Hindernisse, Wandfackeln,
  Teppiche, Truhen, Fässer, Rudel und den Hüter.
- **Durchblick:** Mauern zwischen Kamera und Figur werden oberhalb der Hüfte gerastert ausgespart
  (`scripts/mauer.gdshader`), statt wie bisher abzusinken. Niedrige Mauerreste versperren nur den Weg, nicht Sicht und Geschosse.
- **Karte** oben rechts: Mauern, Rudel (gelb), wache Gegner (rot), Truhen, Pforte und Figur; im Dungeon nur, was du schon gesehen hast.
- Die **Pforte** führt in die nächste Stunde. **Stundenwahl**: im Startbildschirm (◀ ▶) und in der Tasche („Stunde wechseln“)
  lässt sich jede schon erreichte Stunde noch einmal betreten.
- Der Startbildschirm zeigt das Titelbild der Nebelmark (X01, Sandtor bei Nacht, `ui/titel.webp`) hinter einem Verlauf, wie in der 2D-Fassung.
- Die Figur wirft im Licht der eigenen Laterne keinen Schatten mehr (vorher lag ein dunkler Fleck um sie).

## Fassung 2.0

Vorbild für Licht und Stimmung sind die alten Dungeon-Spiele mit Blick von oben: kühles Grundlicht, in dem man alles
erkennt, dazu warme Lichtinseln. Alles spielt im alten Ägypten.

- **Licht und Kulisse:** Die erste Stunde war fast einfarbig dunkelblau, und Geröllhaufen verdeckten die Figur. Jetzt
  scheint draußen der Mond, jede Dungeon-Art hat ihre eigene Farbe (`LICHT` in `scripts/main.gd`), und die Kulisse ist
  ägyptisch und aus Grundformen gebaut (`scripts/deko.gd`): Obelisken mit goldener Spitze, Anubis-Wächter, sitzende
  Kolosse, Palmen, eine Oase mit Wasserbecken, Säulenstümpfe, Sarkophage, Felsen in passender Größe. Ein gepflasterter
  Prozessionsweg führt vom Start durch das Tor bis zur Kapelle des Hüters.
- **Feuerschalen:** In jeder Stunde stehen erloschene Feuerschalen. Wer sie berührt, entzündet sie mit dem Funken des Re:
  Die Gegend wird hell, die Karte deckt sich auf, die Figur heilt etwas. Brennen alle, ist der Hüter geschwächt.
- **Schreine:** Sachmet (Schaden), Thot (Erfahrung), Isis (Heilung), Bastet (Tempo), Hathor (Fundchance) geben für
  eine Weile ihren Segen.
- **Seelenkrüge:** In ihnen schlagen die Herzen, die der Sammler genommen hat. Freilassen oder plündern.
- **Herzwaage:** Das Spiel heißt „Herz und Feder“, und jetzt wiegt es auch. Entscheidungen, Feuerschalen und Krüge machen
  das eigene Herz leichter (Maat) oder schwerer (Isfet). Ein leichtes Herz lässt die Laterne weiter leuchten und bringt
  mehr Erfahrung, ein schweres schlägt härter zu und findet mehr Scherben. Die kleine Waage über der Leiste zeigt den Stand.
- **Quests und Gespräche:** Am Eingang jeder Stunde wartet eine Figur (Senu am Tor, die Schnitterin Merit, der Schreiber
  Chaemwese, ein erloschener Stern, der alte Richter, Isis, Selket …), erzählt ihren Teil und bittet um ein Fundstück.
  Wer es findet, entscheidet, was damit geschieht. Das Questbuch oben links führt die Aufgaben der Stunde.
- **Geschichte:** Der Laternenträger ist im Herbst gestorben und weiß es nicht. Der Sammler war einer der 42 Richter und
  hat die Waage aus Mitleid angehalten. Nach der fünften Stunde wird das eigene Herz als erstes wieder gewogen, am Tor
  des Ostens fällt das Urteil: drei Enden je nach Herz. Texte in `scripts/geschichte.gd`.
- **Oberfläche:** Lebens- und Kraftkugel wie in der 2D-Fassung (`scripts/kugel.gd`), Fähigkeiten dazwischen in einer
  Leiste mit Bronzerand, Zierschrift Cinzel und Textschrift EB Garamond (beide frei, OFL, `ui/fonts/`).
- **Musik:** je ein eigenes Stück für die Stunden 2 bis 5; die Stücke einer Stunde wechseln sich alle anderthalb Minuten ab.
- Logik der Orte und Aufgaben: `scripts/orte.gd`. Der Spieltest prüft sie mit.

### Sparsam mit der Maschine (nach Empfehlungen der Godot-Doku und anderer Entwickler)

Umgesetzt:
- **Schatten im Browser kleiner und weicher gerechnet** (`project.godot`, Einträge mit `.web`): Der Browser auf dem iPhone
  gilt für Godot nicht als „mobil“ und bekam bisher die Einstellungen für große Rechner (Schattenbilder mit 4096 Punkten).
- **Mondschatten in einem Durchgang** statt in vier Stufen (`SHADOW_ORTHOGONAL`).
- **Ferne Lichter aus:** Der Renderer rechnet höchstens 32 Lichter. Lichter weiter als 44 m von der Kamera schaltet
  `main.gd › _spar_tick` ab, sonst könnten in großen Stunden einzelne Fackeln ausfallen.
- **Ferne, schlafende Gegner stehen still** (keine Bewegung, keine Animation), bis die Figur auf 48 m heran ist.
- **Ecken der Fenster auf Handys ohne Kantenglättung:** Geglättete runde Ecken haben auf iPhones in Einzelfällen den
  Grafikkontext gekostet (Godot-Fehlerbericht 105945).
- **Farbtafeln der Modelle verkleinert:** Die 24 Farbtafeln der Figuren und Requisiten (als Datei je 14 KB) wurden als
  Texturen mit 1024 Punkten eingelesen und belegten 32 MB im Paket. Jetzt mit 512 Punkten (`process/size_limit` in den
  `.import`-Dateien unter `models/`): 8 MB. Das Paket schrumpft von 75 auf 51 MB, der Grafikspeicher wird ebenso entlastet.
- Schon vorher: Texturen im Grafikspeicher komprimiert (ETC2 fürs Handy), 3D-Auflösung auf dem Handy 60 %, Mauern und
  Böden je Abschnitt zu einem Körper zusammengefasst, Web-Export ohne Threads und ohne Erweiterungen.

Bewusst noch nicht umgesetzt (jeweils mit Risiko oder Aufwand):
- Physik mit 30 statt 60 Schritten je Sekunde und Zwischenbildern: spart Rechenzeit, ändert aber das Laufgefühl.
- Shader vorab hinter der Ladetafel aufwärmen: nähme den ersten Rucklern (erste Feuerschale, erster Treffer) die Spitze.
- Das Paket ist noch rund 51 MB groß. Den größten Teil machen jetzt die fünf Reliefkarten der Stein- und Bodentexturen
  aus (je 2,8 MB in zwei Formaten).

## Was noch Platzhalter ist

- **Figuren, Fackeln, Fässer und Kisten** stammen aus den freien KayKit-Paketen (CC0) und sehen comichaft und mittelalterlich aus.
  Sie stehen für Bewegung, Licht und Ton, nicht für das endgültige Aussehen. Animationsnamen stehen nur in den
  `ANIM`-Tabellen in `scripts/hero.gd` und `scripts/foe.gd`; ein anderes Modell ist dort ein Tausch.
- **Musik** kommt von Gomo Sounds (Spiel „Herz und Feder“ dort, vier Stücke à 30 s, nahtlos wiederholbar, „leicht utopisch, ein bisschen düster“):
  Titelthema (Startbildschirm), Wüstennacht (Freiland), Hallen der Duat (Dungeons), Hüterkampf. Dateien `audio/mus_*.ogg`,
  Lautstärken in `scripts/sfx.gd` (`VOL`), Überblenden mit `Sfx.music()`. Länger als 30 s erlaubt der kostenlose Gomo-Tarif nicht.
- Die Oberflächen der Stunden 2 bis 5 (Lehm, Feld, Grabwand, Glas, Höhle) sind getönte Verwandte der vorhandenen Texturen,
  bis die Bilder aus `bilder/auftrag_3d.txt` (W03, T10, W04, T11, W05, T12) da sind. Sie heißen dann `w03_lehm`,
  `t10_feld`, `w04_grab`, `t11_glas`, `w05_hoehle`, `t12_hoehlenboden` und werden ohne Codeänderung genutzt.

## Für Entwickler

- `scripts/main.gd` führt Licht, Kamera, Eingabe, Kampf und Beute; die Welt kommt aus `karte.gd` (Karte) und `welt.gd` (Bau),
  die Texte und Rudel der Stunde aus `stunden.gd`.
- `scripts/actor.gd`, `hero.gd`, `foe.gd`: Figuren. `scripts/hud.gd`: Anzeige. `scripts/sfx.gd`: Ton.
- Testmodus: `godot --path . -- --autotest` lässt einen Bot die Stunde durchspielen und speichert Bilder nach `test_out/`.
- `-- --stunde=3` beginnt in der dritten Stunde (für Tests).
- Rundgang: `godot --path . -- --autotest --rundgang --stunde=2` setzt die Figur an den Start, in drei Räume und vor den Hüter und macht je ein Bild, auch mit niedriger Grafik.
- Mauern derselben Art fasst `welt.gd` je Abschnitt von 6 × 6 Zellen zu einem Körper zusammen. Das spart Zeichenaufrufe, vor allem beim Schattenwurf.
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
