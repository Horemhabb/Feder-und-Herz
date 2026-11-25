# Gegnerfabrik: aus ComfyUI-Entwürfen echte 3D-Gegner

Stand 25.11.2026. Ergänzt `WERKSTATT.md` (Figurenfabrik) und `BILDWERK.md` (Bilder aus ComfyUI). Hebt den Punkt
„Figuren aus Bild-zu-3D: nicht“ in `FAHRPLAN.md` Abschnitt 7 auf, wie vom Auftraggeber gewünscht.

**Kurzfassung**

1. Z-Image malt nachts je Gegner einen **Vorlagenbogen**: dieselbe Figur zweimal nebeneinander, links von vorn, rechts
   von hinten, ganzer Körper, A-Haltung, hellgrauer Grund (neue Bildstufe `gegner_vorlagen`).
2. **TripoSG** (MIT-Lizenz) macht in ComfyUI aus der Vorderansicht ein 3D-Netz (über die Knotensammlung
   ComfyUI-3D-rocm, gebaut für AMD-Karten). `netze.bat` erledigt das für alle gewählten Bögen in einem Lauf.
3. **`aus_netz.py`** (Blender) macht daraus eine spielbare Figur: vereinfacht auf 5.000 Dreiecke, färbt sie mit den
   beiden gemalten Ansichten ein („Figurenhaut“), misst Schultern, Hals, Schritt und Hände, passt das Skelett der
   Fabrik an und bindet das Netz daran. Alle Bewegungen der Skelettgegner gelten dann sofort.
4. Schlangen (Apophis) bekommen statt des Menschenskeletts eine **Knochenkette** längs des Körpers und eigene
   Bewegungen (schlängeln, aufrichten, zustoßen, sterben) unter den Namen, die das Spiel schon kennt.
5. Hier getestet ist alles ab dem Netz: zwei Gegner laufen im Schaukasten. Nicht getestet ist der Schritt Bild → Netz
   auf der RX 6800 XT. Das ist das eine große Risiko, und die erste Probe am PC (Abschnitt 8) prüft genau das.

---

## 1. Der Weg in Schritten

| Schritt | Werkzeug | Wo | Dauer | Ergebnis |
|---|---|---|---|---|
| 1. Vorlagenbogen malen | `bildwerk.bat`, Stufe `gegner_vorlagen` (5 Motive) und `gegner_vorlagen_tiere` (Apophis, Skorpion) | PC, nachts | 1 h bzw. 25 min (Schätzung des Skripts) | je Motiv 4 Bögen 1344 × 768 |
| 2. Auswählen | Übersichtstafel ansehen, gute Bögen nach `C:\CF\gegnerfabrik\vorlagen\` kopieren | PC, Tag | Minuten | |
| 3. Netz holen | `netze.bat` → ComfyUI → TripoSG | PC | Schätzung 1 bis 2 min je Netz | `gegnerfabrik\netze\<name>.glb`, rund 300.000 Dreiecke, ohne Farbe |
| 4. Figur bauen | `netze.bat` ruft `aus_netz.py` in Blender | PC (oder hier) | 15 bis 25 s je Figur (hier gemessen) | `gegnerfabrik\figuren\<name>.glb`, 5.000 Dreiecke, Tafel 512², 16 Bewegungen |
| 5. Ins Spiel | Datei nach `models/chars/`, `sync.bat`; Claude trägt sie ein | PC, dann Claude | | Gegner im Schaukasten und im Spiel |

**Warum die Vorderansicht gerade von vorn.** TripoSG rät die Rückseite. Die Rückansicht auf demselben Bogen färbt sie
trotzdem richtig ein, und weil beide Ansichten im selben Bild entstehen, gehören sie sicher zur selben Figur (zwei
getrennte Bilder mit verschiedenen Seeds würden zwei verschiedene Figuren zeigen).

**Warum A-Haltung.** Freie Arme und Beine lassen sich messen und sauber an Knochen binden. Die Haltung selbst ist egal:
`aus_netz.py` erkennt sie und rechnet das Netz in die T-Haltung der Bewegungen zurück.

---

## 2. Was hier wirklich lief, was nur recherchiert ist

**Hier ausgeführt und gesehen** (Linux, Blender 5.3 als Python-Modul, Godot 4.7.2, kein Grafikprozessor):

- `aus_netz.py --art zweibeiner` auf ein Ersatznetz (173.000 Dreiecke, eigene Textur auf zerstückelten Texturkoordinaten,
  so wie TRELLIS.2 sie liefert): vereinfacht, Textur übertragen, vermessen, gebunden, Boden je Bild korrigiert,
  16 Bewegungen. 16 s. Ergebnis: `models/chars/Schakalwaechter.glb`.
- Dasselbe mit einem Netz **ohne** Textur plus Vorlagenbogen (vorn | hinten): Bogen geteilt und freigestellt,
  Blickwinkel über den Umriss gefunden (Deckung 98 %), Farbe projiziert mit Verdeckungsprüfung. 22 s.
- `aus_netz.py --art kette` auf ein Ersatznetz einer aufgerichteten Schlange mit Haube (103.000 Dreiecke):
  Kette aus 14 Gliedern über die Wege auf der Oberfläche, Kopfende erkannt, 16 Bewegungen. 6 s.
  Ergebnis: `models/chars/Apophis.glb`.
- `aus_netz.py --art teil`: ein Netz fest an den Kopfknochen des fertigen Sebau-Kriegers gesetzt; der Krieger samt
  Bewegungen kam unverändert wieder heraus.
- `netze.bat` (mit `python3 -x`) gegen einen nachgebauten ComfyUI-Server: Bogen teilen, Bild hochladen, Auftrag
  schicken, Netz abholen, Blender aufrufen, fertige Figur. Läuft durch.
- Bildstufen `gegner_vorlagen` und `gegner_vorlagen_tiere`: `bildwerk.bat … --trocken` erzeugt 20 bzw. 8 Prompts,
  keine Ziffernwarnung.
- Schaukasten zeigt beide neuen Gegner (Knopf „Gegner“); Spieltest `SPIELTEST: 116 ok, 0 Fehler`.

**Wichtig: Die beiden Netze sind Ersatznetze.** Sie sind mit `ersatznetz.py` aus Formeln gebaut (Abstandsfeld und
„Marching Cubes“, also genau der letzte Schritt, mit dem auch TripoSG sein Netz bildet), nicht von einer KI. Ein echtes
TripoSG-Netz ließ sich hier nicht holen: Die Gewichte (7,5 GB) liegen auf einem Speicher, den das Netzwerk dieser
Umgebung sperrt. Ein echtes KI-Netz ist unruhiger (Beulen, verschmolzene Finger, Waffe am Körper). Die Kette ist
darauf ausgelegt (Krümel entfernen, Vereinfachen, Glätten der Gewichte nur über die Oberfläche), geprüft ist das erst
mit dem ersten echten Netz vom PC.

**Nur recherchiert** (Quellen am Ende): ob TripoSG, TRELLIS.2 oder andere auf der RX 6800 XT unter Windows laufen,
Rechenzeiten und Speicherbedarf dort, Lizenzen, Preise bei Higgsfield.

**Vermutet:** Rechenzeit auf der RX 6800 XT (aus Messungen anderer auf einer RX 7800 XT abgeleitet).

---

## 3. Die Verfahren im Vergleich (Bild → 3D)

| Verfahren | Läuft auf RX 6800 XT unter Windows? | Güte | Lizenz | Zeit, Speicher | Urteil |
|---|---|---|---|---|---|
| **TripoSG** über ComfyUI-3D-rocm | **ungeprüft.** Die Knoten brauchen keine CUDA- oder C++-Erweiterung, getestet sind sie auf RX 7800 XT (RDNA3) unter Windows. Die RX 6800 XT ist RDNA2 (gfx1030): AMDs offizielle PyTorch-Pakete für Windows nennen nur RDNA3/4; es gibt Gemeinschaftsbauten für gfx1030 | gute Form, **ohne Farbe** (die färbt `aus_netz.py` aus dem Bogen) | MIT (Modell), Apache-2.0 (Knoten) | RX 7800 XT: Netz rund 25 s, Spitze 10 GiB Grafikspeicher; 7,5 GB Platte | **erste Wahl** |
| **TRELLIS.2** (Microsoft, 4 Mrd. Parameter), seit Sommer 2026 fest in ComfyUI | ungeprüft; ComfyUI sagt „keine CUDA-Erweiterungen mehr“, Berichte von AMD-Karten fand ich keine | sehr gut, **mit Farbe** (PBR) | MIT | NVIDIA: 1 bis 2 min; 16 GB empfohlen für die hohe Stufe | **zweite Wahl**, braucht ein aktuelles ComfyUI |
| trellis.cpp (TRELLIS.2 ohne Python, Vulkan) | wahrscheinlich: Vulkan läuft auf RDNA2, fertige Windows-Programme; die 1024er-Stufe passt laut Autor in 16 GB | wie TRELLIS.2 | MIT | 6 bis 13 min je Netz (Vulkan, Strix Halo) | **Ausweg**, falls PyTorch auf der Karte nicht will |
| Hunyuan3D 2.0/2.1 (auch dessen „Paint“ in ComfyUI-3D-rocm) | ja | sehr gut | **gilt nicht in der EU**, UK, Südkorea | | **fällt weg** |
| Pixal3D (Tencent ARC, auch in ComfyUI) | | sehr gut | auf Hugging Face für die EU gesperrt | | **fällt weg** |
| Stable Fast 3D, TripoSR | SF3D braucht eigene C++/CUDA-Teile | schwächer (ältere Generation) | SF3D: Stability Community License; TripoSR: MIT | Sekunden | nicht nötig |
| InstantMesh, Direct3D-S2, Step1X-3D | CUDA-Erweiterungen (nvdiffrast, torchsparse/spconv) oder nur CUDA erprobt | gut | Apache-2.0 / MIT / Apache-2.0 | | auf AMD unter Windows kaum zu bauen |
| Sparc3D | Code und Lizenz nicht gefunden | | | | nicht bewertbar |

**Automatisches Rigging mit KI** (UniRig u. a.) braucht CUDA. Ist auch nicht nötig: `aus_netz.py` misst das Netz und
passt das vorhandene Skelett an, das ist hier geprüft. Die Bewegungen bleiben die der Fabrik.

---

## 4. Rechenzeit und Speicher auf der RX 6800 XT

| Schritt | Zeit | Speicher | Woher |
|---|---|---|---|
| Vorlagenbogen (1344 × 768) | etwa 3 min je Bild | wie bisher | Schätzung von `bildwerk.bat` |
| TripoSG, ein Netz | **geschätzt 1 bis 2 min**, erster Lauf länger | Spitze rund 10 GiB von 16 | RX 7800 XT: 25 s (Autor der Knoten); RDNA2 rechnet 16-Bit langsamer |
| TRELLIS.2 in ComfyUI | unbekannt | 16 GB empfohlen | Anleitungen für NVIDIA |
| `aus_netz.py` | 15 bis 25 s (Zweibeiner), 6 s (Kette) | unter 2 GB Hauptspeicher | hier gemessen, 4 Rechenkerne |

Eine Nacht reicht also für Bögen; die Netze sind eher eine Sache von Minuten am Tag.

---

## 5. Lizenzen

| Teil | Lizenz | Folgen |
|---|---|---|
| TripoSG (Modell und Code) | MIT | frei, auch gewerblich |
| ComfyUI-3D-rocm | Apache-2.0; der mitgelieferte Hunyuan-Maler steht unter Tencent-Lizenz | **den Maler-Knoten nicht benutzen** (EU ausgeschlossen); `netze.bat` benutzt nur TripoSG |
| TRELLIS.2 | MIT | frei |
| Hunyuan3D, Pixal3D | gelten nicht in der EU bzw. EU gesperrt | nicht benutzen |
| `aus_netz.py`, `ersatznetz.py`, `bogen.py`, `netze.bat` | GPL-3.0-or-later (wie die Fabrik, weil sie Blender aufrufen) | erzeugte Figuren gehören dir |
| Skelett und Bewegungen | KayKit, CC0 | frei |
| Z-Image Turbo | vor einer Veröffentlichung prüfen (steht schon in `BILDWERK.md`) | |

---

## 6. Mischwege, ehrlich bewertet

| Mischweg | Stand | Urteil |
|---|---|---|
| **Figurenhaut**: gemalte Ansichten aufs Netz projizieren | gebaut und geprüft (`--bogen`, `--vorne/--hinten/--seite`) | trägt; nötig, weil TripoSG keine Farbe liefert. Seiten, die keine Ansicht zeigt, bekommen die mittlere Farbe ihrer Höhe |
| **Teil auf Fabrikkörper** (Kopf, Maske, Krone, Waffe) | gebaut und geprüft (`--art teil`) | trägt für starre Teile; billig und sicher, weil Körper und Bewegungen bleiben. Gut für Schakal- oder Krokodilkopf auf einem Fabrik-Krieger, falls ganze Figuren nicht gelingen |
| **Kette für Schlangen** | gebaut und geprüft (`--art kette`) | trägt für Schlange, Wurm, Aal. Nicht für Skorpion (acht Beine) und Vogel: dort Körper aus `tiere.py`, KI nur für Panzer oder Kopf (`--art teil`) |
| Normal- und Höhenkarten aus dem Bild | nicht gebaut | bei 60 bis 90 Bildpunkten Figurengröße kaum sichtbar; lohnt nur für Hüter in Nahsicht |
| Bildkarten (Impostor) für ferne oder riesige Wesen | nicht gebaut | in Fassung 2.2 verworfen (wirkt wie ein Aufsteller); nur für Riesen am Horizont denkbar (Apophis im Hintergrund der siebten Stunde) |

---

## 7. Bezahlte Wege (nur bewertet, nichts ausgegeben)

Higgsfield-Konto: **0 Credits**, Tarif „free“ (abgefragt am 25.11.2026). Preise je Figur laut Kostenabfrage
(`get_cost`, startet nichts):

| Modell bei Higgsfield | Eingabe | Credits je Netz | etwa Euro* | Erwartung |
|---|---|---|---|---|
| Tripo H3.1 Mehransicht, Standard | 2 bis 4 Ansichten (vorn, links, hinten, rechts) | 9 | 0,30 € | gute Form und Farbe; Ansichten haben wir |
| Tripo H3.1 Mehransicht, „detailed“ | dito | 18 | 0,60 € | besser |
| Tripo H3.1 ein Bild | Vorderansicht | 9 | 0,30 € | |
| Tripo P2 ein Bild (bis 6.000 Flächen) | dito | 34 | 1,20 € | wenige Flächen schon ab Werk |
| Meshy 7, mit Farbe, 6.000 Flächen | Vorderansicht | 38 | 1,30 € | |
| Meshy 7 dazu mit Skelett | dito | 44 | 1,50 € | Skelett passt nicht zu unseren Bewegungen; unnötig |
| Hunyuan3D v3 „LowPoly“ | | 14 | 0,50 € | Lizenz für die EU vorher klären |

\* Umrechnung mit dem Monatstarif Plus (1.000 Credits für 35 €, Black-Friday-Preis vom 25.11.2026; regulär 49 €), also
3,5 Cent je Credit. Ein Abo ist dafür nicht nötig, falls Higgsfield Einzelpakete anbietet; die Abfrage zeigte keine.
Die Netze von dort laufen genauso durch `aus_netz.py` (Format GLB). **Empfehlung:** erst die kostenlose lokale Probe;
nur wenn TripoSG auf der Karte nicht läuft, zehn Figuren mit Tripo H3.1 Mehransicht für etwa 3 bis 6 €.

---

## 8. Erste Probe auf dem PC, in kleinen Häppchen

Jeder Schritt endet mit einem **Tor**: Ist es offen, weiter; ist es zu, aufhören und Claude das Ergebnis zeigen.

**Häppchen 1: Bögen malen (abends).** Sobald diese Änderung in `main` ist, holt `herz-und-feder-3d\tools\sync.bat` sie
auf den PC. Dann in PowerShell (der Pfad zum Repo steht in `C:\CF\bildwerk_ort.txt`, seit `einbauen.bat` lief):

```powershell
$repo = Get-Content C:\CF\bildwerk_ort.txt
Copy-Item "$repo\herz-und-feder-3d\tools\bildwerk\bildwerk_plan.json" C:\CF\
Copy-Item "$repo\herz-und-feder-3d\tools\gegnerfabrik\netze.bat" C:\CF\
cd C:\CF
.\bildwerk.bat gegner_vorlagen gegner_vorlagen_tiere
```

Erwartet morgens: `C:\CF\ComfyUI\output\bildwerk\gegner_vorlagen\uebersicht_01.jpg` und 28 Bögen.
**Tor 1:** Bei mindestens zwei Motiven zeigt ein Bogen links die Figur von vorn, rechts dieselbe von hinten, ganz, mit
freien Armen. Die zwei besten Bögen nach `C:\CF\gegnerfabrik\vorlagen\` kopieren (Ordner anlegen).

**Häppchen 2: Welcher Unterbau läuft?** ComfyUI wie immer starten (`start.bat`) und die ersten Zeilen im schwarzen
Fenster lesen. Steht dort `rocm` oder `hip`, ist es ROCm; steht dort `zluda`, ist es ZLUDA. Foto davon an Claude.
Vorher eine Sicherung der Python-Pakete, damit sich alles zurückdrehen lässt:

```powershell
cd C:\CF
python_embeded\python.exe -m pip freeze > C:\CF\pakete_vorher.txt
```

**Häppchen 3: TripoSG-Knoten einbauen** (ComfyUI dafür schließen):

```powershell
cd C:\CF\ComfyUI\custom_nodes
git clone https://github.com/TwelveNights/ComfyUI-3D-rocm.git
cd C:\CF
python_embeded\python.exe -m pip install -r ComfyUI\custom_nodes\ComfyUI-3D-rocm\requirements.txt
```

ComfyUI neu starten. **Tor 2:** Im Fenster kein roter Fehler zu `ComfyUI-3D-rocm`; in ComfyUI unter „Knoten
hinzufügen → 3d → TripoSG“ gibt es „TripoSG Image to Mesh (ROCm)“. Fehlt der Knoten oder meldet ComfyUI eine zu alte
Fassung (nötig ist 0.34 oder neuer): Foto an Claude. Rechnet danach das Bildwerk nicht mehr wie gewohnt, alles
zurückdrehen: Ordner `C:\CF\ComfyUI\custom_nodes\ComfyUI-3D-rocm` löschen und
`python_embeded\python.exe -m pip install -r C:\CF\pakete_vorher.txt`.

**Häppchen 4: Ein Netz holen.** ComfyUI muss laufen:

```powershell
cd C:\CF
.\netze.bat --ohne-blender
```

Beim ersten Mal lädt ComfyUI 7,5 GB (TripoSG) nach `ComfyUI\models\triposg`; das dauert. Erwartet:
`Netz: C:\CF\gegnerfabrik\netze\<name>.glb (10 bis 40 MB, … s)`.
**Tor 3:** Die Datei in Windows mit „3D-Viewer“ öffnen oder auf https://gltf-viewer.donmccurdy.com ziehen: Kopf,
Arme, Beine sind erkennbar und getrennt, die Figur steht. Steht im Fenster `hipErrorNoBinaryForGpu`, `invalid device
function` oder `out of memory`: Die Karte kann es mit diesem Unterbau nicht. Dann Weg B (trellis.cpp mit Vulkan) oder
Higgsfield; Claude schreibt die Schritte.

**Häppchen 5: Figur bauen.** Blender als Zip-Datei von https://www.blender.org/download/ (Fassung 5.3, „Windows –
Portable“) nach `C:\CF\blender` entpacken, sodass `C:\CF\blender\blender.exe` existiert. Einmal Pillow nachrüsten
(die Zahl im Pfad ist die Blender-Fassung):

```powershell
C:\CF\blender\5.3\python\bin\python.exe -m pip install pillow
cd C:\CF
.\netze.bat
```

Erwartet je Bogen die Zeilen `[ … s] gemessen: Schritt …, Hals …, Arme …` und `Figur: C:\CF\gegnerfabrik\figuren\<name>.glb (600 bis 800 KB)`.
**Tor 4:** Die Figur im 3D-Viewer: farbig, steht in T-Haltung, Bewegungen unter „Animationen“ abspielbar (z. B.
`Walking_D_Skeletons`).

**Häppchen 6: Ins Spiel.** Die Figur nach `herz-und-feder-3d\models\chars\` kopieren (Name ohne Umlaute, z. B.
`Schakalwaechter.glb`), dann `tools\sync.bat "Gegnerfabrik: erste echte Figur"`. Claude prüft, stellt sie in den
Schaukasten und trägt sie als Gegner ein.

---

## 9. Grenzen und offene Risiken

- **Läuft TripoSG auf der RX 6800 XT?** Nicht geprüft; davon hängt der kostenlose Weg ab (Abschnitt 3).
- **Echte KI-Netze** sind unruhiger als die Ersatznetze. Typische Fehler: Hände mit dem Körper verschmolzen (Arm wird
  nicht erkannt → Maß nach Proportion), Waffe als Teil des Arms, Umhang zwischen den Beinen. Waffen deshalb in der
  Vorlage weglassen (steht im Prompt: „hands open and empty“) und im Spiel als eigenes Teil anhängen.
- **Röcke und lange Gewänder** hängen am Becken, die Beine darunter bewegen sich frei. Bei den weiten Schritten der
  Skelettbewegungen stoßen die Beine durch den Stoff; wie bei den Fabrikfiguren.
- **Schlangen**: Der Körper darf sich im Bild nicht selbst berühren (Prompt verlangt es), sonst verschmilzt das Netz
  dort und die Kette findet einen falschen Weg. Skorpion und Vogel: Mischweg (Abschnitt 6).
- **Farben** stammen nur aus zwei Ansichten. Unter den Armen, im Schritt und auf dem Scheitel nimmt die Figur die
  mittlere Farbe ihrer Höhe.
- **Webgröße**: je Figur rund 0,5 bis 0,75 MB (`Schakalwaechter.glb` 744 KB, `Apophis.glb` 464 KB, Tafeln je etwa
  35 KB). Das meiste sind die 16 Bewegungen, wie bei den Fabrikfiguren.
- **Kein echtes KI-Netz geprüft** (Abschnitt 2). Bis dahin sind die zwei neuen Gegner Ersatzfiguren, die nur den Weg
  zeigen; sie stehen im Schaukasten, nicht im Spiel.

---

## 10. Werkzeuge

| Datei | Wofür | Aufruf |
|---|---|---|
| `tools/gegnerfabrik/aus_netz.py` | Netz → Figur (Blender) | `python aus_netz.py --netz roh.glb --bogen bogen.png --ziel X.glb [--art zweibeiner\|kette\|teil]` |
| `tools/gegnerfabrik/bogen.py` | Bogen teilen und freistellen | `python bogen.py bogen.png [ordner]` |
| `tools/gegnerfabrik/netze.bat` | Bögen → ComfyUI (TripoSG) → Blender, für den PC | `netze.bat [--trocken] [--ohne-blender] [bögen …]` |
| `tools/gegnerfabrik/triposg_api.json` | der ComfyUI-Auftrag für TripoSG | wird von `netze.bat` gefüllt |
| `tools/gegnerfabrik/ersatznetz.py` | Ersatznetze zum Prüfen (Schakal, Schlange) | `python ersatznetz.py schakal roh.glb` |
| `tools/bildwerk/bildwerk_plan.json` | Stile `vorlage3d`, `vorlage3d_tier`, Stufen `gegner_vorlagen`, `gegner_vorlagen_tiere`, sieben Motive | `bildwerk.bat gegner_vorlagen` |

Wichtige Schalter von `aus_netz.py`: `--hoehe` (Scheitelhöhe, Standard 2,45 m wie die Fabrikgegner), `--dreiecke`
(Standard 5.000; Hüter bis 10.000), `--tafel` (512; Hüter 1024), `--drehen` (Grad, wenn die Ausrichtung danebenliegt),
`--glieder` und `--hals` (Kette), `--knochen`, `--teilgroesse`, `--versatz` (Teil).

So arbeitet `aus_netz.py` beim Zweibeiner, kurz: Die Schulterlinie wird waagrecht gelegt, die Zehen zeigen nach vorn.
Schritt, Hals, Schultern, Hände, Knie und Knöchel werden aus waagrechten Schnitten durch das Netz gemessen. Das Skelett
der Fabrik wird darauf gestreckt (`fabrik.umbauen`, mit allen Bewegungen). Dann wird es in die Haltung des Netzes
gebracht, jeder Punkt bekommt Gewichte zu den nächsten Knochen (geglättet nur über die Oberfläche, damit der Arm nicht
am Rumpf klebt; was weit vom Oberschenkel absteht, hängt am Becken), und das Netz wird in die T-Haltung der Bewegungen
zurückgerechnet. Zum Schluss stellt `fabrik.boden` jede Bewegung Bild für Bild auf den Boden.

---

## 11. Quellen (abgerufen am 25.11.2026)

- ComfyUI-3D-rocm (TripoSG und Hunyuan-Maler für AMD, Zeiten und Speicher auf RX 7800 XT): https://github.com/TwelveNights/ComfyUI-3D-rocm
- TripoSG, Lizenz MIT: https://huggingface.co/VAST-AI/TripoSG , https://github.com/VAST-AI-Research/TripoSG
- TRELLIS.2 und Pixal3D fest in ComfyUI, „keine CUDA-Erweiterungen“: https://blog.comfy.org/p/trellis2-and-pixal3d-are-now-native , https://x.com/ComfyUI/status/2094561833638404449
- AMD-Unterstützung von TRELLIS.2 in ComfyUI „nicht geprüft“: https://lilys.ai/en/notes/comfyui-20260827/3d-ai-comfyui-free-local
- TRELLIS.2, Lizenz MIT: https://huggingface.co/microsoft/TRELLIS.2-4B ; trellis.cpp (Vulkan/ROCm, Zeiten): https://github.com/pwilkin/trellis.cpp
- TRELLIS.2 auf AMD unter Linux (7900 XTX): https://github.com/toastmanAu/trellis-2-rocm-comfyui
- Speicher und Zeiten TRELLIS.2 (NVIDIA): https://trellis2.app/blog/trellis-2-comfyui
- Pixal3D, für die EU gesperrt: https://huggingface.co/TencentARC/Pixal3D
- Hunyuan3D 2.1, Lizenz ohne EU, UK, Südkorea: https://huggingface.co/tencent/Hunyuan3D-2/blob/main/LICENSE , https://deepwiki.com/Tencent/Hunyuan3D-2/9-license-and-terms
- PyTorch für Windows auf AMD (offiziell RDNA3/4): https://www.amd.com/en/resources/support-articles/release-notes/RN-AMDGPU-WINDOWS-PYTORCH-7-2.html ; gfx1030 unter Windows offen: https://github.com/ROCm/TheRock/discussions/1612 ; Gemeinschaftsbau für RX 6800: https://github.com/ssubedir/RCOm-windows-gfx1030
- ComfyUI mit ZLUDA auf RX 6800 XT: https://github.com/patientx/ComfyUI-Zluda ; ROCm-Ableger für RX 6800: https://github.com/patientx-cfz/comfyui-rocm
- Stable Fast 3D: https://huggingface.co/stabilityai/stable-fast-3d ; Direct3D-S2 (MIT, torchsparse/spconv): https://arxiv.org/abs/2505.17412 ; Step1X-3D: https://arxiv.org/abs/2505.07747
- UniRig (braucht CUDA): https://github.com/VAST-AI-Research/UniRig
- Higgsfield: Modellliste und Kostenabfrage über den Connector (`models_explore`, `generate_3d` mit `get_cost`), Kontostand `balance`
