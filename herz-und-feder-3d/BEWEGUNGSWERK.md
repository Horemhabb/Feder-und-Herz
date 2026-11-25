# Bewegungswerk: neue Bewegungen für die Figuren

Stand 25.11.2026. Frage: Wie bekommt jede Klasse und jeder Boss eigene Bewegungen (Kampfhaltung, Hiebfolgen, Zauber,
Ausweichen, Jubel, Sterben, Ausholen), die es bei KayKit nicht gibt? Getestet in der Cloud-Sitzung (Prozessor, keine
Grafikkarte), recherchiert per Websuche. Kennzeichnung: **[hier gelaufen]**, **[recherchiert]**, **[vermutet]**.

## 1. Kurzfassung: der empfohlene Weg

1. **Sofort: freie Bibliotheken (CC0) über unseren eigenen Umrechner.** Quaternius' *Universal Animation Library* 1 und 2
   (rund 85 Bewegungen in der freien Fassung) wird ohne Blender auf das KayKit-Skelett der Fabrikfiguren übertragen.
   42 Bewegungen in sechs Sätzen liegen fertig in `models/anim/` (zusammen 321 KB). **[hier gelaufen]**
2. **Eigen machen statt suchen:** Dieselbe Kette verändert Bewegungen: langsamer und schwerer (Boss), gespiegelt,
   Haltung verschoben, aus einzelnen Schlüsselposen neu getaktet. So wird aus „Sword_Heavy_Combo“ der Wuchthieb des
   Bosses. **[hier gelaufen]**
3. **Fehlt etwas, filmst du dich mit dem Handy** (2–4 Sekunden, ganzer Körper). `bewegungswerk.bat` schätzt die Pose auf
   dem Prozessor (MediaPipe) und schreibt eine BVH-Datei, Claude überträgt sie. Taugt für große Gesten (Wurf, Jubel,
   Ausholen, Fallen), **nicht** für saubere Schwerthiebe: gemessen rund 35° Fehler je Knochen. **[hier gelaufen, mit gefilmter Puppe]**
4. **Nächste Probe für bessere Güte:** SAM 3D Body (Meta, hat eigene ComfyUI-Knoten mit BVH-Ausgabe) oder GVHMR auf der
   RX 6800 XT. Vorher Lizenz klären (beide nicht frei für alles) und ob es auf AMD läuft. **[recherchiert]**
5. **Nicht jetzt:** Text zu Bewegung (Kimodo, HY-Motion, MoMask) und KI-Video (Wan 2.2) als Bewegungsquelle. Zu viel
   Grafikspeicher, Nvidia-lastig, Lizenzen mit Haken, und ein KI-Video als Vorlage verdoppelt die Unschärfe. **[recherchiert]**

## 2. Was im Spiel bereitliegt

**Einhängen** (Agent B, eine Zeile, Rest bleibt unverändert):

- Held, in `hero.gd` direkt nach `setup(...)`: `Bewegungen.fuer_klasse(ap, skel, cls)`
- Gegner/Boss, in `foe.gd` nach `setup(...)`: `Bewegungen.ergaenzen(ap, skel, "boss")`
  (Figuren ohne KayKit-Skelett wie Ba und Skorpion bekommen still nichts.)

Danach heißen die Bewegungen `<satz>/<name>` und laufen über `play()` wie jede andere, z. B.
`play("eidtraeger/Hiebfolge", 1.0, 0.1, true)`. Schleifen sind schon als Schleife markiert.

| Satz | Bewegungen (Name im Spiel) | Quelle (Quaternius) |
|---|---|---|
| `eidtraeger` | Kampfhaltung (Schleife), Hiebfolge, Hieb_A, Hieb_B, Hieb_C, Schwerer_Hieb, Vorstoss, Abwehr, Ausweichrolle | Sword_Idle, Sword_Regular_Combo/A/B/C, Sword_Heavy_Combo, Sword_Dash, Sword_Block, Roll |
| `priester` | Kampfhaltung (Schleife), Gerade, Kreuzschlag, Haken, Atemstoss, Vorstoss, Ausweichrolle (gespiegelt) | Spell_Simple_Idle_Loop, Punch_Jab, Punch_Cross, Melee_Hook, Spell_Simple_Shoot, Sword_Dash, Roll |
| `jaegerin` | Kampfhaltung (Schleife), Zielen (Schleife), Schuss, Nachladen, Wurf, Rutschen, Ausweichrolle | Pistol_Idle_Loop, Pistol_Aim_Neutral, Pistol_Shoot, Pistol_Reload, OverhandThrow, Slide_Start, Roll |
| `sternleserin` | Kampfhaltung (Schleife), Zauber_Beginn, Zauber, Zauber_Ende, Ausweichschritt, Ausweichrolle | Spell_Simple_Idle_Loop/Enter/Shoot/Exit, Shield_Dash, Roll |
| `gemeinsam` | Treffer_Brust, Treffer_Kopf, Rueckstoss, Sterben, Aufstehen, Jubel, Tanz (Schleife) | Hit_Chest, Hit_Head, Hit_Knockback, Death01, LayToIdle, Yes, Dance_Loop |
| `boss` | Lauern (Schleife), Schlurfen (Schleife), Kratzen, Wuchthieb (70 % Tempo), Schildbruch, Wurf (80 %) | Zombie_Idle_Loop, Zombie_Walk_Fwd_Loop, Zombie_Scratch, Sword_Heavy_Combo, Idle_Shield_Break, OverhandThrow |

Hinweise für den Einbau: Die Bewegungen laufen auf der Stelle wie die KayKit-Bewegungen (der Körper wird vom Spiel
bewegt). Für Bewegungen mit herausgerechnetem Weg (Rezept-Feld `auf_der_stelle`) gibt `Bewegungen.weg_bei(ap, name, t)`
an, wie weit der Körper zur Zeit t geschoben werden muss; im jetzigen Satz nutzt das keine Bewegung. Eine Bibliothek
wird zwischen allen Figuren geteilt: Wer eine Bewegung zur Laufzeit ändert, ändert sie für alle. Die Quaternius-Hiebe
sind Einhandhiebe; der Zweihänder des Eidträgers sitzt weiter in der rechten Hand, die linke greift nicht mit.

## 3. Die Kette

```
Quelle                          Mitte                            Spiel
Quaternius .glb / Mixamo .fbx ─┐
BVH (Mocap, Text-zu-Bewegung) ─┼─> tools/bewegung/umrechnen.gd ─> models/anim/<satz>.res ─> Bewegungen.ergaenzen()
Video / Handy / Standbild ─────┘   (Rezept: saetze.json)
   └─ pose_zu_bvh.py (MediaPipe) ─> BVH
```

**Der Umrechner** (`tools/bewegung/umrechner.gd`, GDScript, läuft in Godot ohne Bildschirm, alle 42 Bewegungen in
1,5 Sekunden) macht fünf Dinge:

1. **Drehung im Raum übertragen:** Wie weit sich ein Knochen der Quelle gegenüber seiner Ruhelage dreht, so weit dreht
   sich der passende KayKit-Knochen. Unabhängig davon, wie die Knochen innen ausgerichtet sind. Weicht die Ruhehaltung
   ab (A-Haltung, Arme nach hinten), gleicht eine Schwenkung je Glied das aus.
2. **Becken skalieren** mit dem Verhältnis der Beinlängen (Quaternius 0,83 m, Fabrikfigur 1,06 m).
3. **Füße festhalten:** Steht der Fuß der Quelle, wird der Knöchel der Figur per Zweigelenk-IK genau dorthin gesetzt
   (kein Rutschen). Ist der Fuß in der Luft, zählt seine Lage zur Hüfte (Tritt, Rolle). Reicht ein Bein nicht (breiter
   Stand, andere Beinteilung), senkt sich das Becken gerade so weit, dass es reicht.
4. **Schlüssel ausdünnen:** Beine und Becken streng (0,1°), Arme und Rumpf 0,8°. Das hält die Dateien klein, ohne dass
   die Füße wandern.
5. **Verändern:** Tempo, Ausschnitt, Spiegeln, Haltung verschieben, Schlüsselposen auf eine Zeitachse legen.

**Godots eingebautes Retargeting** (BoneMap, `SkeletonProfileHumanoid`, Rest Fixer beim Import) **[recherchiert, nicht
benutzt]**: Es funktioniert nur, wenn Quelle *und* Zielfigur beim Import auf das Godot-Profil umbenannt und
umgerichtet werden. Unsere Figuren müssten dafür neu importiert werden; dann hießen die Knochen anders (`Hips` statt
`hips`, `RightHand` statt `handslot.r`), und Spielcode, der Knochen beim Namen nennt (Waffen, Schrittklang,
Schritttempo), bräche. Außerdem hält es die Füße nicht am Boden. Der eigene Umrechner rechnet dieselbe Mathematik,
lässt die Figuren unangetastet und kann IK. Quelle: [Godot-Doku „Retargeting 3D Skeletons“ (4.7)](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/retargeting_3d_skeletons.html).

## 4. Was hier geprüft ist

| Weg | Ergebnis | Beleg |
|---|---|---|
| Quaternius → Fabrikfiguren | **trägt.** Haltungen gleichen der Quelle Bild für Bild, keine verdrehten Knochen, kein durchgedrücktes Knie (0 %) in 42 Bewegungen. Fußrutschen im Mittel 3 cm/s (Quelle selbst: 0–8 cm/s); frühe Fassungen des Umrechners ohne Becken- und Fußausgleich kamen bei einzelnen Bewegungen auf über 40 cm/s. Läuft auch auf Krieger und Hohler (anderes Beinmaß, wird beim Laden angepasst). | Bilderfolgen (unten Quelle, oben Spielfigur), `tools/bewegung/pruefen.gd` |
| BVH lesen und schreiben | **trägt.** Hin- und Rückweg (Quaternius → BVH → Figur) weicht 0,0° ab. | `tools/bewegung/nach_bvh.gd`, `vergleich.gd` |
| Video → Bewegung mit MediaPipe (Prozessor) | **trägt nur grob.** Probe mit bekannter Wahrheit: die Quaternius-Puppe wurde gefilmt (Kreuzschlag, Wurf), geschätzt, übertragen und mit der direkten Übertragung verglichen. Mittlerer Fehler 33° bzw. 38° je Knochen, Gelenke im Mittel 16–19 cm daneben (Figur 2 m). Der Wurf ist als Wurf erkennbar, die Deckung beim Kreuzschlag nicht. Größte Schwäche: Drehung um die Hochachse und Tiefe (ein Auge sieht keine Tiefe). 31 Bilder in knapp 5 Sekunden. | `pose_zu_bvh.py`, `film.gd` |
| Standbild → Pose (gemalte Figur K11) | **trägt nicht mit MediaPipe.** Von vier Haltungen des Bogens K11 wurde eine sauber erkannt, eine gar nicht, zwei kamen kopfüber heraus (Malerei, dunkler Grund, Streiflicht). Das Skript verwirft solche Bilder jetzt mit Meldung. | `pose_zu_bvh.py --einzeln` |
| Posen zu Bewegung (Schlüsselposen zeitlich überblenden) | **Werkzeug läuft**, ein Beweis mit guten Posen steht aus (siehe vorige Zeile). | Rezept-Felder `posen`, `zeiten`, `weich` |
| Text → Bewegung | **nicht ausgeführt.** Modellgewichte liegen bei Hugging Face, deren Download-Server waren in der Cloud gesperrt; PyTorch fehlte. | – |
| KI-Video (Wan 2.2) | **nicht ausgeführt** (keine Grafikkarte). Workflow-Datei liegt bei, ungeprüft. | `tools/bewegung/comfyui/wan22_bewegung_api.json` |

## 5. Lizenzlage je Quelle

| Quelle | Lizenz | Ins offene Repo? |
|---|---|---|
| [Quaternius Universal Animation Library 1](https://quaternius.com/packs/universalanimationlibrary.html) / [2](https://quaternius.com/packs/universalanimationlibrary2.html) | CC0 1.0 (freie Fassung, rund 70 % des Pakets; die Quelldatei .blend ist bezahlt) | **ja** |
| KayKit (schon im Spiel) | CC0 1.0 | ja |
| [Mixamo](https://community.adobe.com/t5/mixamo-discussions/mixamo-faq-licensing-royalties-ownership-eula-and-tos/td-p/13234775) | im Spiel erlaubt, **Rohdateien weitergeben verboten**; ob übertragene Dateien als Rohdateien gelten, ist offen | **nein** (offenes Repo = Weitergabe) |
| [CMU Mocap](https://paperswithcode.com/dataset/cmu-motion-capture) | „free for all uses“, an anderer Stelle „for research“ | erst nach Blick in die CMU-FAQ |
| [100STYLE](https://ianxmason.github.io/100style) (Gangarten) | CC BY 4.0 | ja, mit Namensnennung |
| [Bandai Namco Motion Dataset](https://github.com/BandaiNamcoResearchInc/Bandai-Namco-Research-Motiondataset) | CC BY-NC 4.0 (anderswo: BY-NC-ND) | nein (keine gewerbliche Nutzung; Spiel ist zwar unverkäuflich, aber öffentlich) |
| LAFAN1 (Ubisoft) | nicht bestätigt (vermutlich nicht-kommerziell) | nein, bis geprüft |
| MediaPipe Pose (Werkzeug) | Apache 2.0 | Werkzeug ja; Ergebnis gehört dir |
| [GVHMR](https://github.com/zju3dv/GVHMR), WHAM, 4D-Humans | Gewichte nur nicht-kommerzielle Forschung, brauchen [SMPL](https://smpl.is.tue.mpg.de/license.html) (Registrierung, nicht weitergebbar) | Ergebnis heikel |
| [SAM 3D Body](https://arxiv.org/abs/2511.15586) + [MHR](https://facebookresearch.github.io/MHR) | „SAM License“ (Meta); MHR „industriefreundlich“, Wortlaut nicht geprüft | vor Nutzung prüfen |
| [Kimodo](https://research.nvidia.com/labs/sil/projects/kimodo) (NVIDIA, März 2026) | Code Apache 2.0; Gewichte NVIDIA Open Model License bzw. [SMPLX-Modell nur Forschung](https://huggingface.co/nvidia/Kimodo-SMPLX-RP-v1) | SOMA-Modelle vermutlich ja, prüfen |
| [HY-Motion 1.0](https://arxiv.org/abs/2512.23464) (Tencent) | Community-Lizenz [gilt nicht in EU, UK, Südkorea](https://github.com/Tencent-Hunyuan/HY-Motion-1.0/issues/49) | **nein** (Projekt aus Deutschland) |
| [MoMask](https://github.com/EricGuo5513/momask-codes) | Code MIT; trainiert auf HumanML3D (aus AMASS, nicht-kommerziell) | heikel |
| Higgsfield „Motion Control“ (Connector im Konto) | überträgt Bewegung aus einem Video auf ein Bild, Ergebnis ist **Video**, kein 3D; kostet Credits | nur als Videoquelle; nicht benutzt |

## 6. Rechenzeit und Speicher auf der RX 6800 XT (16 GB)

| Schritt | Wo | Zeit | Speicher | Stand |
|---|---|---|---|---|
| Umrechner (alle Sätze) | jeder Rechner, Godot | 1,5 s für 42 Bewegungen | gering | [hier gelaufen] |
| MediaPipe Pose (heavy) | Prozessor | 31 Bilder in knapp 5 s samt Start (4 Kerne der Cloud) | < 1 GB | [hier gelaufen] |
| SAM 3D Body / GVHMR | Grafikkarte | unbekannt | GVHMR-Pakete nennen nur CUDA und Apple; ob ROCm unter Windows reicht, offen | [recherchiert] |
| Wan 2.2 TI2V 5B, 2 s Video, 832 × 480 | Grafikkarte | **vermutet 1–3 Stunden je Clip** (aus den gemessenen 185 s je Megapixel für Z-Image hochgerechnet; kein Messwert für diese Karte gefunden) | das ungekürzte 5B-Modell sprengt laut AMD-Blog den Speicher von 16-GB-Karten der Reihe RX 9070 (Auslagern oder kleinere Fassung nötig); AMD-Windows-ROCm unterstützt RDNA2 (gfx1030) [offiziell nicht](https://github.com/ROCm/TheRock/discussions/1612), es läuft über [Gemeinschaftsbauten](https://github.com/ssubedir/RCOm-windows-gfx1030) oder [ZLUDA](https://huggingface.co/Zarxrax/removetext/discussions/1) | [recherchiert/vermutet] |
| Kimodo (Text) | Grafikkarte | – | etwa 17 GB, mit Text-Kodierer auf dem Prozessor unter 3 GB; braucht Llama 3 8B (Zugang beantragen) | [recherchiert] |
| HY-Motion (Text) | Grafikkarte | – | 24–26 GB laut [CGWORLD](https://cgworld.jp/flashnews/01-202601-HY-Motion.html): passt nicht | [recherchiert] |
| MoMask (Text) | Prozessor | läuft laut einem [Hugging-Face-Space](https://huggingface.co/spaces/nocapdev/MomaskWorking) ohne Grafikkarte | – | [recherchiert] |

Weitere Fundstellen: [ComfyUI-MotionCapture (GVHMR-Knoten)](https://github.com/PozzettiAndrea/ComfyUI-MotionCapture),
[InstantHMR für ComfyUI (8.11.2026)](https://comfyui-wiki.com/en/news/2026-11-08-comfyui-instant-hmr),
[ComfyUI-Kimodo mit BVH-Export (nur SOMA-Skelett)](https://github.com/jtydhr88/ComfyUI-Kimodo),
[ComfyUI-MotionDiff (MDM, MotionGPT, 4D-Humans)](https://github.com/Fannovel16/ComfyUI-MotionDiff),
[ComfyUI: ROCm unter Windows](https://blog.comfy.org/p/official-amd-rocm-support-arrives),
[AMD: Wan 2.2 in ComfyUI](https://rocm.docs.amd.com/projects/comfyui/en/docs-26.04/how-to/wan-inference-workflow.html).
Alle abgerufen am 25.11.2026 über die Websuche; einzelne Seiten (docs.comfy.org, quaternius.com) waren aus der Cloud
nicht direkt erreichbar, dort stammen die Angaben aus Suchauszügen.

## 7. Erste Probe auf dem PC (etwa 30 Minuten)

Ziel: Klappt „Handy-Video → Bewegung“ bei dir? Alles läuft auf dem Prozessor, ComfyUI muss dafür nicht laufen.

**Häppchen 1: Dateien holen.** Den Stand mit diesem Dokument holen (Pull Request zusammengeführt), dann in PowerShell:

```powershell
$repo = Get-Content C:\CF\bildwerk_ort.txt
Copy-Item "$repo\herz-und-feder-3d\tools\bewegung\bewegungswerk.bat" C:\CF\
Copy-Item "$repo\herz-und-feder-3d\tools\bewegung\pose_zu_bvh.py" C:\CF\
Copy-Item "$repo\herz-und-feder-3d\tools\bewegung\comfyui\wan22_bewegung_api.json" C:\CF\
```

(`bildwerk_ort.txt` hat `einbauen.bat` angelegt. Fehlt sie, den Repo-Pfad von Hand für `$repo` einsetzen.)

**Häppchen 2: Einrichten** (einmal, wenige Minuten, lädt MediaPipe, etwa 25 MB, und ein Posenmodell von 30 MB):

```powershell
cd C:\CF
.\bewegungswerk.bat einrichten
```

Erwartet am Ende: `Fertig. Probe:  bewegungswerk.bat video <Datei.mp4>`.

**Häppchen 3: Dich filmen.** Handy quer, auf Hüfthöhe, 3–4 Meter Abstand, ganzer Körper im Bild, helle Kleidung vor
ruhigem Hintergrund. Frontal oder leicht schräg. Eine Bewegung, 2–4 Sekunden, mit einer Sekunde Stillstand vorher
und nachher. Vorschlag: ein Wurf aus der Schulter oder „beide Arme hoch zum Jubel“. Datei nach `C:\CF\jubel.mp4`.

**Häppchen 4: Umrechnen.**

```powershell
.\bewegungswerk.bat video C:\CF\jubel.mp4
```

Erwartet: `Bilder: …, mittlere Sichtbarkeit 0.8…` (über 0,7 ist gut), dann `BVH geschrieben`, nach wenigen Sekunden.
Ergebnis in `C:\CF\ComfyUI\output\bewegung\`: `jubel.bvh` und `jubel_vorschau.png`.

**Häppchen 5: Tor.** Öffne `jubel_vorschau.png` (oben von vorn, unten von der Seite, links blau, rechts rot).
Der Weg trägt, wenn (a) die Strichmännchen in allen Bildern aufrecht stehen, (b) die Arme deine Bewegung erkennbar
nachmachen und (c) die Füße auf der Linie bleiben, solange du standest. Dann `jubel.bvh` und das Vorschaubild an Claude
schicken (oder `herz-und-feder-3d\tools\sync.bat "Bewegung jubel"` nach Kopieren in den Repo-Ordner); Claude überträgt
sie mit einer Zeile im Rezept auf die Figuren und zeigt Bilder. Trägt es nicht: Vorschaubild schicken, dann ist der
nächste Versuch SAM 3D Body.

**Häppchen 6 (später, Nacht): Video aus Wan 2.2.** Nur wenn du die Wan-2.2-Modelle (`wan2.2_ti2v_5B_fp16.safetensors`,
`umt5_xxl_fp8_e4m3fn_scaled.safetensors`, `wan2.2_vae.safetensors`, zusammen etwa 18 GB Download) in ComfyUI hast und ComfyUI
läuft:

```powershell
.\bewegungswerk.bat wan "a man in plain white linen kilt stands on flat sand, full body visible, he raises both arms high in triumph, static camera, side view" jubel_wan
```

Ungeprüft: Workflow aus der offiziellen Vorlage nachgebaut. Tor: Das Video zeigt *eine* ganze Figur, die Kamera steht
still, die Bewegung ist in zwei Sekunden zu sehen. Erst dann lohnt Häppchen 4 mit dieser Datei.

## 8. Neue Bewegungen einbauen (für Claude)

```bash
# Quellen (nicht im Repo) in einen Ordner legen, Rezept tools/bewegung/saetze.json ergänzen, dann:
godot --headless --path . -s res://tools/bewegung/umrechnen.gd -- --quellen=<Ordner>          # baut models/anim/*.res
godot --headless --path . -s res://tools/bewegung/pruefen.gd -- --quellen=<Ordner>            # Rutschen, Knie
xvfb-run -a godot --rendering-driver opengl3 --path . res://tools/bewegung/probe.tscn -- \
  --modell=Eidtraeger --satz=eidtraeger --bew=Hiebfolge --phasen=8 \
  --quelle=<Ordner>/UAL2_Standard.glb --quellbew=Sword_Regular_Combo --aus=/tmp/x.png          # Bilderfolge
python pose_zu_bvh.py <video|bild|ordner|.npy> aus.bvh --vorschau v.png [--drehung 30] [--einzeln]
```

Rezept-Felder je Bewegung: `name`, `quelle`, `bew`, `schleife`, `tempo`, `von`/`bis`, `spiegeln`, `haltung`
(`{"chest": [10, 0, 0]}` = Brust 10° nach vorn), `auf_der_stelle`, `posen`/`zeiten`/`weich` (Schlüsselposen),
`karte` (`ual`, `mixamo`, `smpl`, `cmu`; sonst geraten). Text-zu-Bewegung-Ausgaben im HumanML3D-Format (`.npy`,
Bilder × 22 × 3) nimmt `pose_zu_bvh.py` direkt.

## 9. Offene Punkte und Risiken

- **Im Spiel noch nicht eingehängt.** Erst Agent B entscheidet, welche Bewegung wann läuft; Trefferzeitpunkte der neuen
  Hiebe (wann trifft die Klinge?) müssen in die Klassentabellen.
- **Einhandhiebe für einen Zweihänder.** Quaternius hat keine Zweihänder-Folgen; die linke Hand greift nicht mit.
  Abhilfe später: Hand-IK auf den Griff.
- **Arme länger als bei Quaternius:** Beim Priester liegt die Deckungsfaust etwas im Gesicht. Abhilfe per `haltung`.
- **Quelldateien aus Spiegeln geladen** (quaternius.com war gesperrt), aber zwei Spiegel lieferten dieselbe Datei.
- **Bei 60–90 Pixel Figurenhöhe** sieht man Feinheiten kaum (FAHRPLAN, Abschnitt 7). Große, klare Bewegungen mit
  Ausholen lohnen sich am meisten, und genau die liefert dieser Weg.
- **Größe:** 321 KB für 42 Bewegungen. Godots `Animation.compress()` könnte das etwa vierteln, verhindert aber das
  Anpassen an andere Beinlängen beim Laden; daher noch nicht benutzt.
- **Der Spieltest** lief einmal mit einem Fehler in einer Prüfung zur Herzwaage (ohne Bezug zu Bewegungen), im zweiten
  Lauf mit 0 Fehlern; vermutlich Zeitnot durch parallel rechnende Agenten.
