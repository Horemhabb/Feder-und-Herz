# Werkstatt: von gemalten Figuren zu echten 3D-Figuren (Fassung 2.3)

Dieses Dokument beantwortet den Auftrag „Transformation in eine atmosphärische ägyptische 3D-Welt, Zero Budget“:
Bestandsaufnahme, Methodenvergleich, was gebaut wurde, was es kostet (Rechenzeit, nicht Geld), wie es ins Spiel kommt
und welche Werkzeuge und Lizenzen dahinterstehen.

**Kurzfassung**

- Es gibt jetzt eine **Figurenfabrik** (`tools/figurenfabrik/`): ein Blender-Python-Skript, das aus einem Bauplan eine
  fertige, animierte Figur für Godot erzeugt. Ein Lauf dauert etwa 15 Sekunden.
- Zwei Figuren sind fertig: der **Eidträger** (Spielfigur) und der **Herzlose** (Gegner, nach dem Bild G13).
- Beide laufen im echten Spiel, hinter dem Schalter „Neue 3D-Figuren“ auf dem Titelbild. Der Spielstand bleibt unberührt.
- Der **Schaukasten** (Knopf auf dem Titelbild, im Web auch `…/Feder-und-Herz/?schau`) zeigt beide Figuren in einer
  Tempelkammer mit Lichtstrahlen, Bodennebel, glühenden Runen, Feuer und Staub, mit allen neun Bewegungen.
- Ausgegeben wurde nichts. Die einzige Ausnahme waren die ausdrücklich freigegebenen Gomo-Credits für Geräusche.

---

## 1. Bestandsaufnahme

| Bereich | Stand vor 2.3 |
|---|---|
| Engine | Godot 4.7.2, Renderer GL Compatibility (WebGL 2), ein Projekt für Web, Mac, Windows |
| Kamera | Schrägsicht von oben, Blickfeld 30°, Figur etwa 60–90 Bildpunkte hoch |
| Figuren | KayKit-Modelle (CC0): Knight, Barbarian, Rogue, Mage, vier Skelette. Kindchenschema: Kopf fast halbe Körperhöhe |
| Skelett | bei allen KayKit-Figuren dasselbe: 23 formende Knochen, dazu 18 Steuerknochen |
| Bewegungen | 76 (Abenteurer) bzw. 95 (Skelette) je Modell, Namen stehen nur in den Tabellen `ANIM` |
| Gemalte Vorlagen | K11–K14 (vier Klassen, je vier Haltungen), G12–G18 (Gegner), dazu Porträts. Keine Ansichten von vorn und von der Seite, keine Bewegungsphasen |
| Licht | Laterne der Figur (Punktlicht mit Schatten), Mond, Fackeln; Glühen (Bloom), Tiefennebel |
| Architektur | Held und Gegner erben von `Actor`; ein Modell ist nur ein Dateiname plus Bewegungsnamen |

Der letzte Punkt ist der Hebel: Ein anderes Modell mit denselben Knochen- und Bewegungsnamen ist nur ein Tausch.

**Was der Web-Renderer nicht kann** (und was deshalb vorgetäuscht werden muss): Volumennebel, Decals, Lichtprojektoren,
Spiegelungen im Bildraum, globale Beleuchtung in Echtzeit. Umgebungsverdeckung (SSAO) steht in der Doku, zeigte im
Versuch (Fassung 2.2) aber keine sichtbare Wirkung.

---

## 2. Methodenvergleich

Bewertet für dieses Projekt: null Euro, kein Grafikprozessor in der Bauumgebung, Web und iPhone als Ziel.

| Methode | Qualität | Aufwand | Schwierigkeit | Performance im Spiel | Kosten | Erweiterbarkeit |
|---|---|---|---|---|---|---|
| **A. KI: Bild zu 3D** (Meshy über Higgsfield; offen: TripoSR, InstantMesh, Hunyuan3D) | Standbild oft gut, Netz ungeordnet, Hände und Gesichter schwach; Skelett und Bewegung fehlen noch | gering je Figur, aber Nacharbeit (Netz ordnen, Gewichte) | mittel | schlecht ohne Nacharbeit (50.000+ Dreiecke) | Higgsfield: Credits (Konto steht auf 0). Offene Modelle brauchen eine Grafikkarte | jede Figur ein Einzelstück, Stil schwankt |
| **B. Figurenfabrik: Blender-Python, geerbtes Skelett** (gewählt) | stilisiert, klar lesbar, einheitlich; kein Fotorealismus | einmal hoch (Fabrik), dann 1–3 Stunden je Bauplan | hoch beim Bau, danach gering | sehr gut: 2.000–3.700 Dreiecke, 1–3 Zeichenaufrufe | 0 | sehr gut: neue Figur = neuer Bauplan, alle Bewegungen gratis |
| **C. Rein prozedural in Godot** (starre Segmente, Bewegung per Code) | hölzern: keine weichen Gelenke, eigene Bewegungen wirken mechanisch | mittel | mittel | gut | 0 | gut für Tiere und Geister (so sind Skorpion und Irrlicht gebaut), schwach für Menschen |
| **D. Gemalte Figur als Bildkarte** (Impostor) | im Standbild am schönsten, aber flach; wird vom Licht der Szene nicht geformt | gering | gering | sehr gut | 0 | schlecht: je Figur nur vier Haltungen, keine Bewegungsphasen |
| **E. Silhouette aufblasen** (Relief aus dem Bild) | Vorderseite brauchbar, Rückseite fehlt | mittel | mittel | gut | 0 | schlecht: 3/4-Ansichten der Vorlagen passen nicht |

**Warum B.** Die Vorlagen zeigen jede Figur nur schräg von vorn und hinten. Daraus lässt sich kein Körper rechnen, ohne
dass eine KI rät (A) oder die Figur flach bleibt (D, E). Versuch D wurde in Fassung 2.2 gemacht und verworfen: Die
gemalte Figur stand wie ein Aufsteller im Raum. Methode B dreht die Aufgabe um: Statt die Bilder zu vermessen, werden
sie *gelesen*: Kragen, Schuppenpanzer, Schurz mit Horusauge, Laterne, Feder. Diese Teile baut ein Skript nach.

**Der Kniff: Bewegungen erben statt erfinden.** Neun gute Bewegungen von Hand oder per Formel zu bauen, wäre der
teuerste Teil gewesen und hätte am schlechtesten ausgesehen. Die Fabrik übernimmt stattdessen das KayKit-Skelett samt
allen Bewegungen (CC0) und streckt es auf menschliche Maße:

1. Knochen behalten Richtung und Rollwinkel, nur ihre Längen und Ansatzpunkte ändern sich. Damit gelten alle Drehungen
   der Bewegungen unverändert weiter.
2. Die Beine werden je Bild neu berechnet (Zweigelenk-IK): gleiche Richtung, gleicher Streckungsgrad, gleiche Knieebene
   wie in der Vorlage. Der Fuß behält seine Lage im Raum.
3. Die Höhe über dem Boden wird je Bild am echten Körper gemessen: Der tiefste Punkt der neuen Figur liegt dort, wo der
   tiefste Punkt der Vorlage lag. Füße stehen, Liegende liegen, Sprünge bleiben Sprünge.
4. Die Haltung lässt sich verschieben, ohne das Skelett anzufassen (der Herzlose geht gebeugt).

**Zu den offenen KI-Modellen** (für später, falls ein Rechner mit Grafikkarte da ist): TripoSR steht unter MIT,
InstantMesh unter Apache 2.0. Hunyuan3D 2.0/2.1 schließt die EU, Großbritannien und Südkorea in seiner Lizenz
ausdrücklich aus und fällt damit für ein Projekt aus Deutschland weg. Auch dann liefern diese Modelle nur ein
unbewegtes Netz; die Fabrik könnte es als Körperteil übernehmen.

---

## 3. Der Eidträger

Vorlage: K11. Gebaut aus Querschnitten („Drechselbank“): Jedes Körperteil ist eine Folge von Ellipsen entlang eines
Knochens, mit Gewichten je Ring. Das ergibt saubere Netze, weiche Gelenke und Texturkoordinaten ohne Handarbeit.

- Körper: Rumpf im Schuppenpanzer, Arme, Fäuste, Beine mit Riemenwickeln, Sandalen, Kopf mit Nase und Ohren, Haar
- Tracht: Perlenkragen (Usech), Gürtel, Armschienen, gefältelter Leinenschurz, nachtblaue Lasche mit Horusauge,
  Rückentuch mit Fransen, Feder der Maat an der Schulter, Laterne an der Hüfte (leuchtet), Bronzeschwert
- Der Schurz hängt an Becken und Oberschenkeln und schwingt beim Laufen mit
- Eine Texturtafel (1024 × 1024), vollständig per Skript gemalt: Schuppen, Leinenfalten, Perlen, Gesicht mit Lidstrich
- 19 Bewegungen, darunter die neun geforderten:

| Gefordert | Bewegung |
|---|---|
| Idle | `2H_Melee_Idle`, `Idle` |
| Walk / Run | `Walking_A` / `Running_A` |
| Attack / Heavy Attack | `2H_Melee_Attack_Slice` / `2H_Melee_Attack_Chop` |
| Hit Reaction | `Hit_A`, `Hit_B` |
| Dodge | `Dodge_Forward` |
| Death | `Death_A` |
| Special Ability | `2H_Melee_Attack_Spin`, `Spellcast_Raise`, `Spellcast_Shoot`, `Cheer` |

## 4. Der Herzlose

Vorlage: G13. Im Spiel hieß die Gegnerart schon „Herzloser“; jetzt sieht man es. Dunkle Schuppenhaut, in der Brust
ein Loch, aus dem kaltes Licht fällt, leuchtende Wirbel den Rücken hinab, Schlitzaugen aus Licht, vier Klauen je Hand,
zerfetztes Lendentuch. Das Leuchten ist eine zweite Tafel (Leuchtkarte), kein zusätzliches Licht. 16 Bewegungen
vom Skelett-Paket (Erwachen, Lauern, Gehen, Laufen, Hieb, Treffer, Tod, Beschwören).

Derselbe Weg führt zu jeder weiteren Figur: Bauplan schreiben (Maße, Teile, Farben), Fabrik starten, fertig.
Das ist die „Monster-Generierungsmaschine“ aus dem Auftrag, im Kleinen.

---

## 5. Testumgebung und Atmosphäre

**Schaukasten** (`schau.tscn`, `scripts/schau.gd`): Tempelkammer mit sechs Papyrussäulen, zwei Anubis-Wächtern,
Sarkophag, zwei Feuerschalen, Wasserbecken. Knöpfe: Bewegung vor und zurück, Blick (Überblick, Eidträger, Herzloser),
Vergleich mit den alten Figuren, Kamera schwenkt oder steht, selbst steuern (W A S D, Leertaste, J, K).

**Atmosphäre als Illusion** (`scripts/stimmung.gd`). Jeder Baustein ist eine durchscheinende Fläche mit kleinem Shader
und kostet einen Zeichenaufruf:

| Baustein | Täuscht vor | Technik |
|---|---|---|
| `lichtstrahl` | Lichtschacht, „Gottesstrahlen“ | zwei gekreuzte Flächen, additiv, Streifen wandern; blendet aus, wenn man auf die Kante schaut |
| `nebel` | Bodennebel | liegende Fläche, wanderndes Rauschen aus dem Shader, weicher Rand |
| `runenkreis`, `fries` | glühende Zeichen auf Boden und Wand | Maske aus den Hieroglyphen des Spiels (SVG), additiv, pulsiert |
| `staub` | Staub im Licht | 36 winzige Teilchen, additiv |
| `flamme` | Feuer in Schalen | zwei gekreuzte Flächen, die Zungen malt der Shader; keine Partikel |
| `saeule` | Tempelarchitektur | ein Körper, vier Materialien, einmal gebaut und geteilt |

Davon ist schon im Spiel: Lichtstrahl und Runenkreis an jedem Schrein, kalter Nebel um die Seelenkrüge, ein schmaler
Strahl auf dem Fundstück, ein Bannkreis am Platz des Hüters. Bei „Grafik niedrig“ sind sie aus.

---

## 6. Performance

**Gemessen** (Dateien und Zähler des Renderers):

| | Knight (alt) | Eidträger (neu) | Skeleton_Rogue (alt) | Herzloser (neu) |
|---|---|---|---|---|
| Dreiecke | 6.952 (mit verstecktem Zubehör) | 3.696 | 5.278 | 2.128 |
| Netze / Zeichenaufrufe | 15 Netze, davon etwa 9 sichtbar | 1 Netz, 3 Materialien | 10 Netze | 1 Netz, 1 Material |
| Knochen | 41 | 23 | 41 | 23 |
| Datei | 3,6 MB | 0,7 MB | 4,8 MB | 0,6 MB |
| Bewegungen | 76 | 19 | 95 | 16 |

Die neuen Figuren sind also in jeder Zählung billiger als die alten. Das Paket fürs Web wächst um etwa 1,8 MB
(zwei Modelle, 24 Geräusche).

**Im laufenden Spiel**, dieselbe Karte (`--seed=7`, Stunde 3), derselbe Weg des Bots, einmal mit alten, einmal mit
neuen Figuren. Die Zahlen enthalten die Schattendurchgänge:

| Zeitpunkt | Zeichenaufrufe alt → neu | Dreiecke je Bild alt → neu |
|---|---|---|
| 10 s | 614 → 598 | 896.809 → 895.957 |
| 20 s | 544 → 461 | 693.279 → 672.892 |

**Schaukasten:** 171 Zeichenaufrufe, rund 39.000 Dreiecke je Bild, mit allen Effekten und Schatten.

**Web und iPhone-Format:** Der Web-Export wurde in einem Browser mit den Maßen eines iPhone 14 (quer) geöffnet:
Schaukasten über `?schau`, Titelbild, Spiel mit `?neu3d`. Alle drei erscheinen richtig, der Browser meldet keine
Fehler. Das Paket ist 53,8 MB groß (Fassung 2.2: rund 51 MB). Die Texturtafeln liegen verlustbehaftet gepackt im
Paket (175 KB für den Eidträger) und belegen im Grafikspeicher etwa 5,6 MB (Eidträger) und 2,8 MB (Herzloser).

**Nicht gemessen:** die Bildrate auf einem echten iPhone. Die Bauumgebung hat keinen Grafikprozessor; Bildraten von
dort sagen nichts. Die Zähler oben sind der belastbare Teil. Bitte auf dem Gerät prüfen: Titelbild → Schaukasten,
dann ein Spiel mit „Neue 3D-Figuren“. Ruckelt es, hilft Taste G (oder der Knopf „Grafik“).

**Stellschrauben, falls nötig:** Texturtafel des Eidträgers auf 512 verkleinern; Bewegungen streichen, die das Spiel
nicht braucht; Atmosphäre-Bausteine sind bei niedriger Grafik ohnehin aus.

**Desktop-Fassung mit stärkerem Renderer:** Im Augenblick läuft das Spiel überall mit dem Web-Renderer
(`rendering_method="gl_compatibility"` in `project.godot`). Godot erlaubt je Plattform einen eigenen Wert: Mac und
Windows könnten Forward+ bekommen (echter Volumennebel, SSAO, Spiegelungen), Web und Handy blieben, wie sie sind, bei
gleicher Mechanik und gleichem Spielstand. Umgeschaltet ist das nicht, weil es sich hier nicht anzeigen ließ (kein
Vulkan in der Bauumgebung) und ungeprüft nichts ins Spiel soll. Es ist ein eigener, kleiner Schritt mit Test am Mac.

---

## 7. Integration in Schritten

| Schritt | Inhalt | Sicherung |
|---|---|---|
| 1 (fertig) | Fabrik, Eidträger, Herzloser, Schaukasten, Schalter | Schalter aus = Spiel wie in 2.2. Einstellung liegt in `einstellungen.json`, nie im Spielstand |
| 2 | Die drei anderen Klassen (K12–K14): je ein Bauplan | Jede Klasse fällt einzeln auf ihr altes Modell zurück (`"neu"` fehlt = alt) |
| 3 | Gegner G14–G18, danach die Hüter | wie Schritt 2, je Gegnerart |
| 4 | Leute und Götter in den Gesprächen | nur Aussehen, keine Mechanik |
| 5 | Schalter standardmäßig an, alte Modelle entfernen (spart rund 30 MB) | Git-Marke vor dem Entfernen |
| 6 (wahlweise) | Forward+ für Mac und Windows | eigener Export, Web unverändert |

Tests nach jedem Schritt, wie bisher: Spieltest (76 Prüfungen), Klassentest (21 je Klasse), Bot, Web-Probe.
Alle liefen für Fassung 2.3 mit alten und mit neuen Figuren.

**Offene Punkte, ehrlich benannt**

- Im Browser der Prüfumgebung (der ohne Grafikprozessor rechnet) wurden die Funken-Partikel der Feuerschalen falsch
  gezeichnet: eine riesige gelbe Kugel und ein Strich quer durchs Bild. Am Desktop sind sie richtig. Der Schaukasten
  benutzt deshalb die Shader-Flamme. Die Feuerschalen im Spiel benutzen weiter die Partikel, wie seit Fassung 2.0.
  Ob der Fehler nur an der Prüfumgebung liegt, weiß ich nicht. Bitte einmal im Browser eine Feuerschale entzünden
  und hinsehen; zeigt sich der Fehler, ist die Shader-Flamme der fertige Ersatz.
- Im Schaukasten wirkt der Eidträger stimmig. Im Spiel steht er neben Gegnern im Kindchenschema, solange die übrigen
  Figuren nicht nachgezogen sind. Deshalb ist der Schalter anfangs aus.
- Hände sind Fäuste ohne Finger; das Gesicht ist gemalt, nicht modelliert. Für die Spielkamera reicht das, für
  Nahaufnahmen nicht.
- Stoff ist an Knochen gebunden, nicht simuliert. Bei extremen Posen kann das Schwert durch den Schurz gehen.
- Die Figur gleicht der gemalten Vorlage in Tracht und Farbe, nicht in der malerischen Tiefe. Das wäre nur mit
  gemalten Texturen je Figur zu holen (Higgsfield-Bild als Tafel) oder mit Methode A.

---

## 8. Werkzeuge und Lizenzen

| Werkzeug / Quelle | Wofür | Lizenz | Kosten | Gewerblich nutzbar |
|---|---|---|---|---|
| Godot 4.7.2 | Engine | MIT | 0 | ja |
| Blender 5.3 als Python-Modul (`pip install bpy`) | Figurenfabrik | GPL 3; was man damit erzeugt, gehört einem selbst | 0 | ja |
| Pillow, NumPy | Texturtafeln malen | HPND (MIT-artig), BSD | 0 | ja |
| KayKit Adventurers und Skeletons (Kay Lousberg) | Skelett und Bewegungen | CC0 1.0 | 0 | ja, ohne Namensnennung |
| Eigene Skripte der Fabrik | | GPL-3.0-or-later (Pflicht, weil sie `bpy` aufrufen und öffentlich sind; siehe `tools/figurenfabrik/LIZENZ.md`) | 0 | ja |
| Erzeugte Modelle und Tafeln | Spiel | deine | 0 | ja |
| Almendra | Schrift | SIL OFL 1.1 | 0 | ja |
| Higgsfield-Bilder (K11–K14, G12–G18) | Vorlage für Tracht und Farben, nicht im Modell enthalten | nach deinem Tarif bei Higgsfield | bereits vorhanden | laut deinem Tarif |
| Gomo Sounds | 18 Geräusche, Musik | nach deinem Tarif bei Gomo | 65 Credits, von dir freigegeben | laut deinem Tarif |
| ffmpeg | Geräusche schneiden und wandeln | LGPL/GPL, nur als Werkzeug | 0 | ja |

Keine neue Abhängigkeit im Spiel: Blender, Pillow und ffmpeg werden nur beim Bauen gebraucht, nicht zur Laufzeit.

---

## So baust du eine Figur neu

```bash
python -m venv bl
```

```bash
bl/bin/pip install bpy pillow
```

```bash
bl/bin/python tools/figurenfabrik/eidtraeger.py models/chars/Knight.glb models/chars/Eidtraeger.glb
```

```bash
bl/bin/python tools/figurenfabrik/hohler.py models/chars/Skeleton_Rogue.glb models/chars/Hohler.glb
```

Prüfbild einer Figur in mehreren Bewegungen:

```bash
godot --path . res://tools/figurenfabrik/probe.tscn -- --modell=Eidtraeger --bew=2H_Melee_Idle:0.3:0,Running_A:0.25:60 --aus=/tmp/probe.png
```

Ein neuer Bauplan besteht aus drei Teilen: `PLAN` (Maße des Skeletts), `male()` (Texturtafel) und `baue()` (Körperteile
als Ringe mit Gewichten). `hohler.py` ist das kürzere Beispiel.
