# Bildwerk: Masterplan für die Bilder des Spiels

Version 5.2.0. Stand 23.11.2026, nach der ersten Nachtschicht (132 Symbole in 6 h 19 min, kein Fehlschlag).

Ziel: Der PC rechnet nachts mit ComfyUI (Z-Image Turbo, RX 6800 XT), tagsüber wird ausgewählt und eingebaut.
Zwei Fronten laufen gleichzeitig: **Erzeugen** (Nacht) und **Einbauen** (Tag). Was erzeugt ist, soll schnell im Spiel sichtbar werden.

## 1. Werkzeuge

| Datei (Repo: `tools/bildwerk/`) | Ablage am PC | Aufgabe |
|---|---|---|
| `bildwerk.bat` | `C:\CF` | Masterskript: Stufen wählen (auch mehrere für eine Nacht), rechnet, baut Übersichtstafeln |
| `bildwerk_plan.json` | `C:\CF` | Alle Texte: Stile, Motive, Stufen, Seeds, Regeln, Auswahl für den Einbau |
| `einbauen.bat` | `C:\CF` | Bringt die Auswahl ins Spiel: Symbole mit Rahmen (wie `magie.py`), Porträts zugeschnitten, direkt ins Repo |

`symbole.bat` (Ordner `tools/bildkatalog/`) bleibt für die Symbolläufe der ersten Nacht stehen, neue Läufe gehen über `bildwerk.bat`.

**Ein Tag im Ablauf**
1. Abends: `bildwerk.bat`, im Menü die Stufen der Nacht wählen (z. B. `1 2 3`). Alle Rückfragen kommen vor dem Start.
2. Morgens: Tafeln `uebersicht_*.jpg` aus `ComfyUI\output\bildwerk\<stufe>\` an Claude schicken, gemeinsam auswählen.
3. Die Auswahl in `bildwerk_plan.json` unter `einbau` eintragen (Claude liefert die Zeilen).
4. `einbauen.bat`: schreibt die Dateien ins Repo und sichert die alten in `fuers_spiel\sicherung_vorher\`.
5. `herz-und-feder-3d\tools\sync.bat "Bilder aus ComfyUI"`: schiebt den Stand auf den Zweig `mac-pc`.
6. Claude prüft, ein Pull Request nach `main`, GitHub baut die Webfassung.

## 2. Regeln aus den ersten Läufen (stehen auch im Plan)

1. **Keine Ziffern und kein Prozentzeichen im Prompt.** Aus „80%“ wurden „%“, „0%“ und „9%“ als Bildmotiv. Das Skript warnt vor jedem Lauf.
2. **Keine Wörter, die Schrift nahelegen.** „Hu, the spoken word“ ergab einmal den Schriftzug HU. Eigennamen der Leute stehen deshalb nicht im Prompt.
3. **Ägyptische Merkmale positiv und genau beschreiben** (Kopf im Profil, Einlagen aus Lapislazuli). Das trägt deutlich, Verbote („no frame“) tragen kaum.
4. **Seltene Wesen kennt das Modell nicht.** Das Seth-Tier wurde zu Anubis. Lieber über Gegenstände und Wirkung zeigen.
5. **Das Tier zuerst und ausdrücklich nennen.** Aus „lioness-goddess sun disc“ wurde ein Hund.
6. **square, plaque, tile, coin, medallion** locken Tafeln und Rahmen an.
7. **Das Wort für den Hintergrund bestimmt die Helligkeit.** „grey stone“ gab hellgrauen Grund, darum immer „dark …“.
8. **Hände und Füße** haben oft vier Finger oder Zehen: verdecken oder in der Auswahl meiden.
9. **Neue Stile zuerst als Probe** mit gleichem Seed gegen den alten Stil, erst dann in die Nacht.
10. **Höchstens etwa ein Megapixel**, Entschlüsseln in Kacheln (AMD-Treiber). Etwa 3 Minuten je Bild, eine Nacht reicht für 110 bis 120 Bilder.
11. **Lange Prompts kosten Zeit** (Text-Encoder auf dem Prozessor): etwa 25 Sekunden je Bild.
12. **Licht nur als Farbe beschreiben.** „moonlight“ und „oil-lamp“ werden wörtlich gemalt: Mond und moderne Sturmlaterne in jedem Porträt. Kleidung als schlichtes Leinen benennen, sonst kommen Ledergürtel, Schürzen und Strohhüte.

## 3. Stufen, die jetzt bereit sind

| Nr | Stufe | Bilder | Dauer | Im Spiel sichtbar | Einbau |
|---|---|---|---|---|---|
| 1 | `symbole_neu`: Seth, Sachmet, Schritt und Atem des Schu, Hapi, Eid der Maat, Ba | 28 | 1 h 26 | ja | `einbauen.bat`, sofort |
| 2 | `portraets_figuren`: Erloschener, alter Richter, Isis, Selket, Großer Kater, elfter Ruderer, Horus, die mit dem Messer, Schu | 36 | 1 h 49 | ja, im Gesprächsfenster | `einbauen.bat`; Kürzel P04, P05, P11–P17 stehen im Code |
| 3 | `portraets_leute`: die zwölf Leute mit ihren Sorgen | 48 | 2 h 25 | ja, im Gesprächsfenster | `einbauen.bat`; Kürzel P06–P10, P18–P24 stehen im Code |
| 4 | `texturen_stunden`: Wand und Boden der Stunden 6 bis 12 | 56 | 2 h 52 | erst nach Code | Naht glätten und Normalenkarte wie `tools/texturen.py`, dann `main.gd` erweitern (Claude) |
| 5 | `astzeichen`: zwölf Zeichen der Äste | 48 | 2 h 28 | noch kein Platz | Baum (`baum.gd`) müsste sie zeigen |
| 6 | `gegner_lexikon`: neun Gegner als Büste | 36 | 1 h 49 | noch kein Platz | ein Lexikon im Buch des Thot wäre nötig |
| 7 | `portraets_leute_nah`: die zwölf Leute, zweiter Anlauf (nah, Leinen, ohne Mond und Laterne) | 48 | 2 h 25 | ja, im Gesprächsfenster | ersetzt Stufe 3, die Mond und Sturmlaterne in jedem Bild zeigte |
| 9 | `texturen_neu`: alle 17 vorhandenen Texturen (Wände w01–w05, Böden t06 t07 t09–t12, Fels f01, Requisiten p01–p05) als Auswahl neben den alten | 51 (je 3 Varianten) | 2 h 35 | ja, ersetzt die gleichnamigen Dateien | `einbauen.bat texturen`: Helligkeit ausgleichen, Naht glätten, Normalenkarte |
| 8 | `portraets_figuren_nah`: Erloschener, Richter, sieben Götter, zweiter Anlauf | 36 | 1 h 49 | ja, im Gesprächsfenster | ersetzt die Übergangsporträts aus Stufe 2 |
| 10 | `hueter`: Hüter der Stunden 1 bis 8 als Büste (Stil `hueter`, Licht nur als Farbe) | 32 | etwa 1 h 10 | erst nach Code | Bild in der Ankündigung des Hüters (Claude) |
| 11 | `akttafeln`: drei breite Szenen (Abstieg, Waage, Morgen), 1280 × 720, Stil `szene` (neu, zugleich die Probe) | 12 | etwa 25 min | erst nach Code | Hintergrund der Akttafeln und Schluss von Akt 1 (Claude) |
| 12 | `sand_neu`: Sand ohne Käfer, Löcher und Verlauf | 8 | etwa 20 min | ja | `einbauen.bat texturen`, ersetzt `t09_sand` |

Alle Stufen 1 bis 9 sind gerechnet und eingebaut (Fassung 4.1.4). Die Stufen 10 bis 12 dienen Etappe B des Fahrplans (Schluss von Akt 1, Ankündigung der Hüter) und dem Sand; danach ruht die Bildarbeit wieder.

**Vorschlag für die Nächte**
- **Nacht 2:** Stufen 1, 2, 3 (etwa 5 h 40). Danach ist jede Gesprächsfigur mit Gesicht möglich, das ist der größte sichtbare Gewinn.
- **Nacht 3:** Stufe 4 und 5 (etwa 5 h 20). Parallel baut Claude den Code für die neuen Texturen.
- **Nacht 4:** Stufe 6 plus die ersten Stufen aus Abschnitt 4.

### Texturen im Einbau

`einbauen.bat texturen` liest `einbau.texturen` (Spieldatei → Quelle), gleicht den Lichtverlauf aus, blendet große Sprünge an der Naht über, glättet die Naht und erzeugt die Normalenkarte (`_n.jpg`, ohne Relief nur für `texturen_ohne_relief`). Ergebnis: `textures/<name>.jpg` (1024 × 1024). Test mit einem absichtlich nicht kachelbaren Bild: Naht von 26 auf 0,75 (1 = so glatt wie das Bild selbst).
**Stunden 6 bis 12** haben im Spiel noch keine eigenen Oberflächen (`welt.gd › LOOK` kennt nur vier Stundenarten plus Freiland, `main.gd › SURF` die Dateinamen). Für Stufe 4 braucht es dort neue Einträge (Claude).

## 4. Spätere Stufen (noch nicht im Plan)

| Stufe | Inhalt | Platz im Spiel | Anmerkung |
|---|---|---|---|
| Klassenbilder | die vier Porträts (540 × 723), Figuren der Tasche, Tafeln K01–K04 | vorhanden | nur, wenn die neuen Porträts stilistisch davonziehen |
| Titel und Start | `titel.webp` (1600 × 905), `start.png` | vorhanden | Querformat um ein Megapixel (z. B. 1280 × 720), dann hochskalieren |
| Requisiten-Texturen | Ton, Holz, Palmrinde, Palmblatt, Korb (512 px) | vorhanden | Ersatz für die Higgsfield-Texturen, gleicher Weg wie Stufe 4 |
| Hüter der Stunden | ein Bild je Hüter für die Ankündigung | Code nötig | zwölf Hüter, Namen in `stunden.gd` |
| Akttafeln | drei Bilder für „Ende des ersten Aktes“ usw. | Code nötig | Texte in `stunden.gd` |
| Blick durch die Pforte | zwölf gemalte Ausblicke | Code nötig | Bewegung als Video eher über Higgsfield |
| Vorlagen für die Figurenfabrik | Vorder-, Seiten- und Rückansicht der Gegner, Kopf von vorn | Blender | Grundlage für Texturen der 3D-Figuren (siehe `WERKSTATT.md`) |
| Bild zu 3D | TripoSG (MIT) über ComfyUI-3D-rocm | Blender | Hunyuan3D gilt nicht in der EU; Netze brauchen Nacharbeit |

## 5. Grenzen und offene Punkte

- **Lizenz von Z-Image Turbo** vor einer Veröffentlichung prüfen (hier nicht nachgeschlagen).
- **Markennamen:** Der Symbolstil `aegypt` nennt zwei fremde Spiele. Die Bilder zeigen sie nicht; für einen Verkauf wäre der Stil `frei` sauberer (noch ungetestet). Die neuen Stile für Porträts, Texturen und Lexikon enthalten keine.
- **Größe der Webfassung:** 21 Porträts kosten etwa 2 MB mehr Download, Texturen je Stunde etwa 1,5 MB.
- **Gleiche Wesen:** Hatz, Upuauts Rudel und der Hüter zeigen Schakale. Das ist gewollt, Seth und Sachmet nicht mehr.
- `einbauen.bat` wurde gegen eine Kopie des Repos und echte Gemälde als Stellvertreter getestet, noch nicht auf Windows.
