# Bildwerk: Masterplan für die Bilder des Spiels

Version 5.4.0. Stand 26.11.2026: Nächte als Einheit, nahtlose Texturen (freiwillig, fest genagelte Erweiterung), Freistellen, Messwerte auf den Tafeln, feste Figuren-Bausteine, fünf volle Nächte (zuerst die Szenenbilder der neuen Geschichte) und eine Probenacht. Was der Auftraggeber abends tippt, steht in `NACHTSCHICHTEN.md`.

Ziel: Der PC rechnet nachts mit ComfyUI (Z-Image Turbo, RX 6800 XT), tagsüber wird ausgewählt und eingebaut.
Zwei Fronten laufen gleichzeitig: **Erzeugen** (Nacht) und **Einbauen** (Tag). Was erzeugt ist, soll schnell im Spiel sichtbar werden.

## 1. Werkzeuge

| Datei (Repo: `tools/bildwerk/`) | Ablage am PC | Aufgabe |
|---|---|---|
| `bildwerk.bat` | `C:\CF` | Masterskript: eine **Nacht** (`bildwerk.bat nacht 1`) oder Stufen wählen, rechnet, baut Übersichtstafeln mit Messwerten und Empfehlung, füllt Restzeit mit Reserve-Stufen, schreibt am Ende eine Zusammenfassung |
| `bildwerk_plan.json` | `C:\CF` | Alle Texte: Stile, Motive, Stufen, Nächte, Seeds, Regeln, Auswahl für den Einbau |
| `einbauen.bat` | `C:\CF` | Bringt die Auswahl ins Spiel: Symbole, Porträts, Texturen (mit Messung der Perspektive), Hüter, Akttafeln und 15 neue Arten (Szenen, gemalte Oberfläche, Fellmuster, Freistellen, additive Bilder, Bänder, Bildbogen der Gegenstände …; Liste: `einbauen.bat hilfe`) |
| `pruefe_plan.py` | nur Repo | Prüft Plan und Skripte gegen alle Regeln (Ziffern, Schrift, Licht, Tafelwörter, Größe, Dauer der Nächte, Einbau-Pfade, gleicher gemeinsamer Block). Muss grün sein, bevor ein Plan zum PC geht: `python3 pruefe_plan.py` |
| `attrappe_comfy.py` | nur Repo | ComfyUI-Attrappe für Tests ohne Grafikkarte (legt passende Probebilder ab, prüft die Verdrahtung des Kachel-Knotens) |

`bildwerk.bat` und `einbauen.bat` tragen dieselbe `VERSION` wie der Plan und weigern sich, mit einem anderen Plan zu laufen. Ändert sich das Format, alle drei gemeinsam erhöhen. Der Block „gemeinsam: Messwerte und Freistellen“ steht in beiden Skripten wortgleich (das prüft `pruefe_plan.py`), damit Tafel und Einbau dasselbe messen.

**Ein Tag im Ablauf**
1. Abends: `.\bildwerk.bat nacht <n>` in `C:\CF`. Alle Rückfragen kommen vor dem Start.
2. Morgens: die Zusammenfassung `ComfyUI\output\bildwerk\zusammenfassung_<nacht>_<datum>.txt` nennt alle Tafeln; die Tafeln an Claude schicken.
3. Claude wählt vor (auf den Tafeln ist die gemessen beste Variante golden umrandet), der Auftraggeber bestätigt; Claude trägt die Auswahl unter `einbau` ein.
4. `.\einbauen.bat <art>`: schreibt die Dateien ins Repo und sichert die alten in `fuers_spiel\sicherung_vorher\`. Mit `pruefen` statt einer Art wird nur gemessen.
5. `herz-und-feder-3d\tools\sync.bat "Bilder aus ComfyUI"`: schiebt den Stand auf den Zweig `mac-pc`.
6. Claude prüft, ein Pull Request nach `main`, GitHub baut die Webfassung.

## 2. Regeln aus den bisherigen Läufen (stehen auch im Plan)

1. **Keine Ziffern und kein Prozentzeichen im Prompt.** Aus „80%“ wurden „%“, „0%“ und „9%“ als Bildmotiv. Das Skript warnt vor jedem Lauf. (Die alten Symbolstile `alt`, `positiv`, `aegypt` nennen zwei Spiele mit Ziffern; neue Stufen nehmen `frei`.)
2. **Keine Wörter, die Schrift nahelegen.** „Hu, the spoken word“ ergab einmal den Schriftzug HU. Eigennamen der Leute stehen deshalb nicht im Prompt.
3. **Ägyptische Merkmale positiv und genau beschreiben** (Kopf im Profil, Einlagen aus Lapislazuli). Das trägt deutlich, Verbote („no frame“) tragen kaum.
4. **Seltene Wesen kennt das Modell nicht.** Das Seth-Tier wurde zu Anubis. Lieber über Gegenstände und Wirkung zeigen.
5. **Das Tier zuerst und ausdrücklich nennen.** Aus „lioness-goddess sun disc“ wurde ein Hund.
6. **square, plaque, tile, coin, medallion** (auch frame, border) locken Tafeln und Rahmen an.
7. **Das Wort für den Hintergrund bestimmt die Helligkeit.** „grey stone“ gab hellgrauen Grund, darum immer „dark …“.
8. **Hände und Füße** haben oft vier Finger oder Zehen: verdecken oder in der Auswahl meiden.
9. **Neue Stile zuerst als Probe** mit gleichem Seed, erst dann in die Nacht (Nacht 0).
10. **Höchstens etwa ein Megapixel**, Entschlüsseln in Kacheln (AMD-Treiber). Etwa 3 Minuten je Bild, eine Nacht reicht für 110 bis 150 Bilder.
11. **Lange Prompts kosten Zeit** (Text-Encoder auf dem Prozessor): etwa 25 Sekunden je Bild.
12. **Licht nur als Farbe beschreiben.** „moonlight“ und „oil-lamp“ werden wörtlich gemalt: Mond und moderne Sturmlaterne in jedem Porträt. Kleidung als schlichtes Leinen benennen, sonst kommen Ledergürtel, Schürzen und Strohhüte.
13. **Texturen „von oben“ kamen mit Perspektive und Lichtverlauf.** Der neue Sand hatte oben feine, unten grobe Rippel: das kachelt nie. Darum kein „photographed“ und kein Boden als Szene, sondern eine Materialprobe „seen perfectly perpendicular … the same scale of detail in every corner“ (Stil `flaeche`), am besten nahtlos gerechnet (Abschnitt 6). `einbauen.bat` misst die Perspektive und baut ab 1,5 nicht ein.
14. **Die Bilder sind drei- bis neunmal so hell, wie das Licht des Spiels erwartet** (`main.gd › HELL`, Ziel lineare Helligkeit um 0,24). Neue Stile sagen „muted medium-dark“, `einbauen.bat` dämpft neue Flächen auf höchstens 0,24 (`texturen_hell`, `hell_ziel`; nie heller).
15. **Freistellen:** Gegenstände und Abziehbilder auf „a plain flat medium grey background“ (nicht Weiß wegen Leinen, nicht Schwarz wegen Eisen). Leuchtendes auf reinem Schwarz.
16. **Additive Bilder müssen am Rand reines Schwarz sein**, sonst sieht man im Spiel ein helles Viereck. `einbauen.bat` zieht das Rest-Grau ab und blendet den Rand weich aus.
17. **Wiederkehrende Figuren als Bausteine.** Spielfigur, Laterne, Nebet, Haremhab, Sammler, sein Schatten, der Ba und Thot stehen unter `bausteine` im Plan und werden in Motiven als `{NEBET}` usw. eingesetzt: überall wortgleich, damit sie wiedererkennbar bleiben. Die Laterne darf als Gegenstand gemalt werden, aber nur über `{LATERNE}` (alte runde Bronzelaterne mit Löchern an kurzer Kette; „oil-lamp“ gab die moderne Sturmlaterne). `pruefe_plan.py` lässt „lantern“ nur dort durch (Feld `ausnahme` mit `grund`).

## 3. Bestandsaufnahme (26.11.)

| Stufe | Stand | Warum |
|---|---|---|
| 1 `symbole_neu`, Symbole der ersten Nacht | eingebaut | Stil `aegypt` trägt, 132 Symbole ohne Fehlschlag |
| 2 `portraets_figuren`, 3 `portraets_leute` | verworfen | Mond und Sturmlaterne in jedem Bild (Regel 12) |
| 7 `portraets_leute_nah`, 8 `portraets_figuren_nah` | eingebaut (P04–P24) | Stil `portraet_nah`: nah, Leinen, Licht nur als Farbe |
| 4 `texturen_stunden` | gerechnet, **nie eingebaut** | kein Platz im Code (`SURF`/`LOOK` kennen nur fünf Stundenarten); alter Stil `textur`, also Perspektive möglich. Mit `bildwerk.bat tafeln texturen_stunden` lassen sich die 56 Bilder jetzt messen. Nacht 3 rechnet sie im neuen Stil neu |
| 5 `astzeichen` | gerechnet, kein Platz | Baum zeigt sie noch nicht |
| 6 `gegner_lexikon` | gerechnet, kein Platz | brauchbar für eine Seite „Gegner“ im Buch des Thot oder als Bild in der Champion-Ansage (Code) |
| 9 `texturen_neu` | eingebaut (17 Texturen) | Helligkeit erst im Spiel über `HELL` gedämpft (Regel 14) |
| 10 `hueter`, 11 `akttafeln` | eingebaut (Fassung 4.2.2) | Stile `hueter` und `szene` tragen |
| 12 `sand_neu` | verworfen | alle acht Bilder mit Perspektive; im Spiel bleibt der von Hand korrigierte Sand (darum `texturen_von_hand`) |
| 13–17 Vorlagen, Bodenzeichen, Effektbilder, Friese | laufen (Nacht vom 26.11.) | Einbau-Arten `zeichen`, `fx`, `fries` sind bereit |

Bewährt sind damit: Emblem (`aegypt`), Porträt nah, Hüter, Szene. Neu und ungeprüft: `flaeche`, `ding`, `abzieh`, `relief`, `ansicht`, `buchbild`, `frei`, `lichter`, `zierflaeche`, die Figuren-Bausteine, dazu das nahtlose Rechnen. Darum zuerst Nacht 0.

## 4. Nächte (ab 5.3)

`bildwerk.bat nacht <Nummer oder Name>`. Reihenfolge der Stufen nach Nutzen; `fuellen` sind Reserve-Stufen, die nur laufen, solange der Rahmen (`stunden`, ab Beginn gezählt) reicht. Zeiten geschätzt mit 185 s je Megapixel, nahtlos gerechnete Bilder etwa 1,7-mal so lang.

| Nacht | Zweck | Stufen | Bilder (+Reserve) | Dauer | Im Spiel |
|---|---|---|---|---|---|
| 0 `proben` | neue Stile, Figuren-Bausteine, Kachel-Knoten prüfen | probe_kachel, probe_flaeche, probe_szene, probe_lichter, probe_zier, probe_ding, probe_frei, probe_abzieh, probe_relief, probe_ansicht, probe_buchbild | 21 | 56 min | Entscheidung |
| 1 `szenen` | alle 26 Szenenbilder der Zwischensequenzen, Porträts Nebet/Haremhab/Ba, gemalte Oberfläche | szenen_sandtor, szenen, szenen_lichter, portraet_nebet, portraets_geschichte, zier_flaechen, zier_karte, zier_sterne; Reserve zier_ornamente, lebewesen | 134 (+51) | 6 h 16 | Szenen und Oberfläche **sofort** (`einbauen.bat szenen`, `zier`), Porträts nach einer Zeile Code |
| 2 `dinge` | Gegenstände der Tasche ägyptisch (36 Felder), Champion-Zeichen, Flächen für Requisiten | gegenstaende, champion_zeichen, requisiten_flaechen; Reserve gegenstaende_d, lebewesen, vorlagen_mehr | 156 (+95) | 6 h 21 (ohne Kacheln 5 h 35) | Gegenstände **sofort** |
| 3 `welt` | eigene Wände und Böden für die Stunden 6–12, zweite Wandart, Sand, Wasser, Himmel | stunden_flaechen, boden_neu, wand_varianten, wasser_himmel; Reserve stunden_flaechen_d, lebewesen | 78 (+53) | 6 h 50 (ohne Kacheln 4 h 00) | Sand sofort, Stunden nach Code |
| 4 `boden_wand` | Abziehbilder, Wandbilder, Tore, Teppiche, Säulen | abziehbilder, wandbilder, tore, teppiche, saeulen; Reserve abziehbilder_d, wandbilder_d, vorlagen_mehr | 108 (+44) | 5 h 33 | nach Code |
| 5 `erzaehlung` | Titel, Hüter 9–12, Ladebild je Stunde, Lexikon | titel, hueter_spaet, ladebilder, buchbilder; Reserve buchbilder_d, ladebilder_d, vorlagen_mehr | 110 (+50) | 4 h 41 | Titel sofort, Hüter fast sofort, Rest nach Code |

**Warum diese Reihenfolge:** Die Szenen zuerst, weil die Geschichte neu ist und ihre 22 Sequenzen bis dahin Ersatzbilder zeigen; sie sind sofort im Spiel, ohne Code, und der Stil `szene` ist bewährt. Die gemalte Oberfläche läuft in derselben Nacht mit, weil sie klein ist und ebenfalls ohne Code wirkt. Danach die Dinge (sofort im Spiel), dann die Welt und Boden/Wand (brauchen Code), zuletzt die Erzählung (ihr Bestes, die Enden, steckt jetzt in den Szenen). Die Fellmuster der Tiere sind Reserve: Sie wirken erst, wenn Claude die Tafel neu rechnet, und ihre Felder sind klein.

### Aus den Wunschlisten (zweiter Durchgang)

| Liste | übernommen | geändert | abgelehnt |
|---|---|---|---|
| `wunsch_szenen.md` (Agent D) | alle 26 Bilder mit den Namen aus `scripts/szenen.gd` (geprüft), Stil `szene`, Lichter-Ebene additiv | **vier** statt zwei Varianten (die wichtigsten Bilder des Spiels); Figuren als Bausteine statt eingefügter Sätze (Ds Nebet-Satz stand auch am Vogel: „bird … linen dress“); die Laterne als alte Bronzelaterne; Sandtor-Bilder im neuen Stil `szene_stadt`; Lichter-Ebene im neuen Stil `lichter` statt `szene` (sonst malt es Landschaft); „papyrus scroll … line of red ink“ → leeres Papyrusband mit rotem Tropfen; „ring of the royal name“ → goldener ovaler Ring; „reed pen“ gestrichen (Schreibzeug lockt Schrift); „oil dish“ → Tonschale mit kleiner Flamme; Ba als Seelenvogel mit Menschenkopf, nicht „falcon-like“ (Regel aus Stufe 1); Hände des Sammlers in den Ärmeln | – |
| Porträts (Agent D) | Nebet (P25), Haremhab (P26), Ba mit Nebets Gesicht (P27), Stile `portraet_nah`/`portraet_nah_figur` | Nebet-Satz gekürzt (Prompt sonst über 175 Wörter) | – |
| `wunsch_ui.md` (Agent A) | `grund_dunkel` (Leder, Lapislazuli, Ebenholz als drei Motive), `karte_grund`, `sterne` (nahtlos), `papyrus`, Ornamente als Reserve | eigener Stil `zierflaeche` statt der Negativlisten (Z-Image rechnet ohne Negativprompt, cfg 1); Ornamente auf Grau statt Schwarz (Gold hat dunkle Stellen) und in der **Pixelgröße der erzeugten Dateien** (200 × 48, 96 × 64, 64 × 64), weil `Zier` sie in Dateigröße zeichnet, nicht in den Maßen der Liste | 9-Feld-Rahmen (wie A selbst sagt) |
| `wunsch_lebewesen.md` (Agent C) | alle 13 Kacheln mit den Dateinamen aus `kleintiere_tafel.py` | drei statt vier Varianten; Stil `flaeche` nahtlos (das Skript kachelt die Kachel mit `np.tile`, also muss sie nahtlos sein); als Reserve, nicht als eigene Nacht | – |
| erster Entwurf | – | – | Stufe `enden` gestrichen (die neuen Schlussbilder `sz_finale_*` ersetzen sie) |

### Neue Stile und ihr Risiko

| Stil | wofür | abgeleitet aus | Risiko |
|---|---|---|---|
| `flaeche` | alle Texturen ab 5.3 | `textur` + Regel 13, 14 | mittel: Perspektive kann bleiben; mit Kachel-Knoten gering |
| `ding` | Gegenstände der Tasche | `aegypt` (Werkstoffe) + Regel 15 | mittel: Grau statt dunklem Grund, Nemes könnte ein Gesicht bekommen |
| `frei` | Champion-Zeichen | `aegypt` ohne Spielnamen (stand seit der ersten Symbolnacht ungetestet im Plan) | gering bis mittel |
| `abzieh` | Abziehbilder | `ding` + „exactly from above“ | mittel: kleine Szenen statt flacher Flecken |
| `relief` | Wandbilder | `fries` (Stufe 17) | mittel: Hieroglyphenspalten (Schrift) möglich |
| `ansicht` | Tore | `fries`/`vorlage3d` | mittel |
| `buchbild` | Lexikon | `szene`, Papyrus wie die Oberfläche | höher: Totenbuch-Vignetten tragen oft Schriftspalten; Rückfall `szene` |
| `szene_stadt` | Szenen in Sandtor | `szene` mit „desert town of the living“ statt Unterwelt | gering |
| `lichter` | Lichter-Ebene der Szenen | `funke` (Stufe 16) | mittel: kann Landschaft andeuten; Rand wird ohnehin geputzt |
| `zierflaeche` | gemalte Oberfläche | `flaeche` | gering bis mittel: Mitte muss ruhig bleiben (Text darauf) |
| Bausteine in `szene` | wiederkehrende Figuren | Porträtsätze (P05) und Wunschliste D | mittel: Z-Image hält Figuren über Bilder nicht sicher gleich; Probe `probe_szene` |

## 5. Stufen

| Nr | Stufe | Bilder | Dauer | Im Spiel sichtbar | Einbau |
|---|---|---|---|---|---|
| 1 | `symbole_neu`: Seth, Sachmet, Schritt und Atem des Schu, Hapi, Eid der Maat, Ba | 28 | 1 h 26 | ja | `einbauen.bat`, sofort |
| 2 | `portraets_figuren` | 36 | 1 h 49 | verworfen | ersetzt durch Stufe 8 |
| 3 | `portraets_leute` | 48 | 2 h 25 | verworfen | ersetzt durch Stufe 7 |
| 4 | `texturen_stunden`: Wand und Boden der Stunden 6 bis 12 (alter Stil) | 56 | 2 h 52 | nie eingebaut | Nacht 3 rechnet neu |
| 5 | `astzeichen` | 48 | 2 h 28 | noch kein Platz | Baum (`baum.gd`) |
| 6 | `gegner_lexikon` | 36 | 1 h 49 | noch kein Platz | Lexikon oder Champion-Ansage |
| 7 | `portraets_leute_nah` | 48 | 2 h 25 | ja | eingebaut |
| 8 | `portraets_figuren_nah` | 36 | 1 h 49 | ja | eingebaut |
| 9 | `texturen_neu`: alle 17 Texturen | 51 | 2 h 35 | ja | eingebaut |
| 10 | `hueter`: Stunden 1 bis 8 | 32 | 1 h 10 | ja | eingebaut |
| 11 | `akttafeln` | 12 | 25 min | ja | eingebaut |
| 12 | `sand_neu` | 8 | 20 min | verworfen | Perspektive |
| 13 | `gegner_vorlagen` (Stil `vorlage3d`) | 20 | 1 h | Vorlage fürs 3D | `GEGNERFABRIK.md` |
| 14 | `gegner_vorlagen_tiere` | 8 | 25 min | Vorlage fürs 3D | `GEGNERFABRIK.md` |
| 15 | `bodenzeichen` (Stil `zeichen`) | 24 | 1 h 15 | nach Code | `einbauen.bat zeichen` → `ui/zeichen/` |
| 16 | `effektbilder` (Stil `funke`) | 18 | 55 min | nach Code | `einbauen.bat fx` → `textures/fx/` (`fx_art`: add oder alpha) |
| 17 | `friese` (Stil `fries`) | 18 | 40 min | nach Code | `einbauen.bat fries` → `textures/fries/` |
| 18–25 | `probe_*` (Nacht 0; `probe_kachel` jetzt mit zwei Flächen, `probe_frei` nur noch Stil frei) | 17 | 45 min | Probe | `einbauen.bat pruefen` |
| 26 | `gegenstaende` (Stil `ding`, 768 px) | 108 | 3 h 07 | **sofort** | `einbauen.bat gegenstaende` → `ui/icons.webp` |
| 27 | `champion_zeichen` (Stil `frei`) | 27 | 1 h 23 | nach Code | `einbauen.bat champions` → `ui/affixe/` |
| 28 | `requisiten_flaechen` (nahtlos) | 21 | 1 h 50 | nach Code | `einbauen.bat texturen` |
| 29 | `stunden_flaechen` (nahtlos) | 42 | 3 h 41 | nach Code | `einbauen.bat texturen` |
| 30 | `wand_varianten` (nahtlos) | 15 | 1 h 19 | nach Code | `einbauen.bat texturen` |
| 31 | `boden_neu` (nahtlos) | 9 | 47 min | Sand sofort | `einbauen.bat texturen t09_sand` |
| 32 | `wasser_himmel` (nahtlos) | 12 | 1 h 03 | nach Code | `einbauen.bat texturen` |
| 33 | `abziehbilder` (Stil `abzieh`) | 42 | 2 h 09 | nach Code | `einbauen.bat abzieh` → `textures/abzieh/` |
| 34 | `wandbilder` (Stil `relief`, 1024 × 768) | 30 | 1 h 09 | nach Code | `einbauen.bat wandbilder` → `textures/wand/` |
| 35 | `tore` (Stil `ansicht`, 768 × 1024) | 15 | 35 min | nach Code | `einbauen.bat tore` → `textures/tor/` |
| 36 | `teppiche` (nahtlos) | 12 | 1 h 03 | nach Code | `einbauen.bat texturen` |
| 37 | `saeulen` (nahtlos waagrecht) | 9 | 36 min | nach Code | `einbauen.bat saeulen` → `textures/saeule/` |
| 38 | `ladebilder` (Stil `szene`) | 36 | 1 h 37 | nach Code | `einbauen.bat ladebilder` → `ui/laden/` |
| 39 | `buchbilder` (Stil `buchbild`) | 54 | 2 h 04 | nach Code | `einbauen.bat buchbilder` → `ui/lexikon/lx_<id>.webp` |
| 40 | `hueter_spaet` (Stil `hueter`) | 16 | 48 min | fast sofort | `einbauen.bat hueter` |
| 42 | `titel` (Stil `szene`) | 4 | 11 min | **sofort** | `einbauen.bat titel` → `ui/titel.webp` |
| 43–47 | Reserve: `gegenstaende_d`, `stunden_flaechen_d`, `abziehbilder_d`, `wandbilder_d`, `ladebilder_d`, `buchbilder_d`, `vorlagen_mehr` | | | | wie oben |
| 48–50 | `probe_szene`, `probe_lichter`, `probe_zier` (Nacht 0) | 4 | 11 min | Probe | |
| 51 | `szenen` (Stil `szene`, 1280 × 720) | 80 | 3 h 36 | **sofort** | `einbauen.bat szenen` → `ui/szenen/<name>.webp` |
| 52 | `szenen_sandtor` (Stil `szene_stadt`) | 20 | 54 min | **sofort** | `einbauen.bat szenen` |
| 53 | `szenen_lichter` (Stil `lichter`) | 4 | 11 min | **sofort** | `einbauen.bat szenen` (Name in `szenen_add`: RGB auf Schwarz, additiv) |
| 54 | `portraet_nebet` (P25) | 4 | 12 min | nach einer Zeile Code | `einbauen.bat portraets` |
| 55 | `portraets_geschichte` (P26 Haremhab, P27 Ba) | 8 | 24 min | nach einer Zeile Code | `einbauen.bat portraets` |
| 56 | `zier_flaechen` (Leder, Lapislazuli, Ebenholz, Papyrus) | 12 | 37 min | **sofort** | `einbauen.bat zier` → `ui/zier/gemalt/` |
| 57 | `zier_karte` (1024 × 640) | 3 | 6 min | **sofort** | `einbauen.bat zier` |
| 58 | `zier_sterne` (nahtlos) | 3 | 16 min | **sofort** | `einbauen.bat zier` (512 px, nahtlos) |
| 59 | Reserve `zier_ornamente` (Stil `ding`) | 12 | 21 min | **sofort** | `einbauen.bat zier` (freigestellt, Dateigröße wie die erzeugten) |
| 60 | Reserve `lebewesen` (Stil `flaeche`, nahtlos) | 39 | 3 h 25 (ohne Kacheln 2 h) | nach Neurechnen der Tiertafel | `einbauen.bat lebewesen` → `bilder/lebewesen/`, dann `kleintiere_tafel.py` (Claude) |

### Texturen im Einbau

`einbauen.bat texturen` liest `einbau.texturen` (Spieldatei → Quelle), gleicht den Lichtverlauf aus, blendet große Sprünge an der Naht über, glättet die Naht und erzeugt die Normalenkarte (`_n.jpg`, ohne Relief nur für `texturen_ohne_relief`). Neu in 5.3: Es misst vorher **Perspektive** (P) und **Lichtverlauf** (V) und meldet sie; ab P = 1,5 baut es nur ein, wenn der Name ausdrücklich genannt ist. `texturen_hell` dämpft auf eine lineare Helligkeit (z. B. 0,24), damit neue Dateien in `main.gd › HELL` keinen Eintrag brauchen. `texturen_von_hand` (heute `t09_sand`) überspringt der Aufruf ohne Namen, damit die von Hand korrigierte Datei nicht überschrieben wird.

Das Perspektivmaß vergleicht die Größe der Zeichnung (Autokorrelation in Flecken) oben, in der Mitte und unten bzw. links und rechts. Grob: die 17 Texturen im Spiel liegen bei 1,02 bis 1,26; künstlich schräg verzerrte Böden bei 1,4 bis 2,2. Es ist ein grobes Maß, die Tafel zeigt darum jede Textur 2 × 2 gekachelt.

### Messwerte auf den Tafeln

| Kürzel | Bedeutung | gut |
|---|---|---|
| S | Schärfe (feine Zeichnung im Verhältnis zum Kontrast) | über 15 |
| H | lineare Helligkeit | um 0,24 für hellen Stein |
| N | Naht (Sprung am Rand im Verhältnis zum Bild) | um 1 |
| P | Perspektive (Detailgröße oben/unten) | bis 1,25 |
| V | Lichtverlauf (hellstes/dunkelstes Feld) | bis 1,3 |
| Rand | Helligkeit (Schwarz-Bilder) oder Deckkraft (Grau-Bilder) am Rand | unter 0,01 / 0,02 |
| Grund | Unruhe des grauen Hintergrunds | unter 0,04 |

Je Motiv bekommt die Variante mit der besten Punktzahl einen goldenen Rahmen („EMPFOHLEN“). Das ist eine Vorauswahl nach Zahlen, kein Urteil über das Motiv.

## 6. Nahtlose Texturen (Recherche 26.11.)

- **Kein Kernknoten in ComfyUI** schaltet nahtloses Rechnen ein. Der alte Kniff (alle Faltungen auf zirkuläres Auffüllen umstellen) wirkt nur bei Faltungsnetzen (SD 1.5, SDXL); Z-Image ist ein Transformer, dort greift er nicht.
- **Erweiterung „Seamless Latent Tiling“** (github.com/mikemojen/ComfyUI-seamless_latent_tiling, Knoten `SeamlessLatentTiling`): legt in jedem Rechenschritt die gegenüberliegenden Ränder des Latents um das Bild, rechnet das Modell auf dem größeren Bild und schneidet zurück. Sie hängt sich über `set_model_unet_function_wrapper` um das Modell, nicht in es, und nennt Z-Image Turbo ausdrücklich als verträglich. Einstellungen: `padding` (Standard 64, empfohlen 128), `tile_x`, `tile_y` (für Friese und Säulen nur waagrecht). Kostet Speicher und Zeit (bei 128 Pixeln Rand etwa 1,7-mal).
- **Erweiterung „ComfyUI-seamless-tiling“** (spinagon): `SeamlessTile` (Faltungen, für Z-Image wirkungslos), `MakeCircularVAE`/`CircularVAEDecode` (zirkuläres Entschlüsseln). Nicht übernommen: Das zirkuläre Entschlüsseln verträgt sich nicht mit dem Entschlüsseln in Kacheln, das der AMD-Treiber braucht. Die kleine Restnaht des Entschlüsselns glättet `einbauen.bat` (3 Pixel).
- Gehostete Dienste (fal.ai „z-image/turbo/tiling“, ein Replicate-Modell mit „toroidalem RoPE“) zeigen, dass es bei Z-Image grundsätzlich geht, sind aber nicht lokal.
- **Entscheidung:** `bildwerk.bat` nutzt den Knoten, wenn er da ist (Stufenfeld `kachel`: `xy`, `x`, `y`; Dateien enden auf `_k`). Fehlt er, fragt es vor dem Start; **Enter heißt: ohne Kacheln rechnen** (`--ohne-kachel` fragt gar nicht). Das Einrichten ist **freiwillig**.
- **Fest genagelt (5.4):** `bildwerk.bat kachel_einrichten` lädt nicht mehr den Zweig `main` als ZIP, sondern die drei Dateien des Commits `b4cba00b22817ab0ac48ba0d4af7eb1a325c4602` (10.03.2026) einzeln von `raw.githubusercontent.com` und vergleicht jede mit ihrer SHA-256 (`__init__.py` b25c575e…, `nodes.py` 9990356a…, `LICENSE` c71d239d…, voll im Skript). Weicht eine ab, wird nichts eingerichtet. Einzelne Dateien statt ZIP, weil GitHub für erzeugte Archive keine bytegleichen Prüfsummen zusagt. Durchsicht (Claude, 26.11.): `__init__.py` importiert nur `nodes.py`; `nodes.py` (492 Zeilen) importiert nur `torch`, `torch.nn.functional` und `math`, hat vier Knoten (`SeamlessLatentTiling` hängt per `set_model_unet_function_wrapper` einen Wrapper um das Modell, der das Latent zirkulär auffüllt und danach zurückschneidet; drei Bildknoten für Farbangleich und Verschieben), keinen Netz-, Datei-, Prozess- oder `eval`-Zugriff, keine weiteren Abhängigkeiten. Lizenz Apache 2.0. **Ungeprüft auf AMD:** Nacht 0 rechnet zwei Flächen mit und ohne Knoten (`probe_kachel`, `probe_flaeche`).
- Nebenbei: Ein nahtlos gerechnetes Bild kann keine Perspektive haben (oben fein und unten grob passt an der Naht nicht zusammen). Der Knoten behebt damit beide alten Fehler.

Quellen: README und `nodes.py` von github.com/mikemojen/ComfyUI-seamless_latent_tiling; README von github.com/spinagon/ComfyUI-seamless-tiling; Websuche nach Z-Image und Kacheln (Einträge von comfy.icu, runcomfy, fal.ai, replicate; diese Seiten selbst waren aus der Cloud nicht erreichbar).

## 7. Grenzen und offene Punkte

- **Lizenz von Z-Image Turbo** vor einer Veröffentlichung prüfen (hier nicht nachgeschlagen).
- **Fremde Erweiterung:** `kachel_einrichten` legt fremden Code in ComfyUI, fest auf einen gelesenen Stand mit Prüfsummen. Freiwillig; alles läuft auch ohne.
- **Markennamen:** Der Symbolstil `aegypt` nennt zwei fremde Spiele. Neue Stufen nehmen `frei` (Probe in Nacht 0).
- **Größe der Webfassung:** Der Bildbogen der Gegenstände wächst von 672 auf 960 Pixel (etwa 300 KB mehr), Texturen je Stunde etwa 1,5 MB, Ladebilder je etwa 120 KB.
- **GL Compatibility kennt keine Decal-Knoten:** Abziehbilder werden flache Vierecke mit Alpha über dem Boden.
- `einbauen.bat` und `bildwerk.bat` sind hier mit der Attrappe und Probebildern in einem nachgebauten `C:\CF` getestet, nicht auf Windows.
