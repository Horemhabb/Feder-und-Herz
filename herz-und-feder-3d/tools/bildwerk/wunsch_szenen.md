# Bildwünsche: Zwischensequenzen (Neufassung der Geschichte, 4.3)

Für die Nachtschicht von Agent E. Format **1280 × 720**, Stil **`szene`** aus `bildwerk_plan.json` (wie die Akttafeln: gemalte Szene, viel Raum, Licht nur als Farbe). Ablage im Spiel: `ui/szenen/<datei>.webp` (ohne weiteren Einbau: `szene.gd` nimmt das Bild, sobald die Datei da ist; bis dahin zeigt die Sequenz einen Ersatz).
Regeln geprüft: keine Ziffern, kein Prozent, keine Wörter, die Schrift nahelegen (die Liste in `sz_akt1_liste` ist bewusst eine „papyrus scroll“ ohne Zeichen), Licht nur als Farbe (kein „moonlight“, keine „lamp“; die Laterne ist ein Gegenstand der Handlung), Tiere zuerst genannt, „dark …“ für dunklen Grund.
Wiederkehrende Figuren werden überall gleich beschrieben, damit sie wiedererkennbar bleiben:

- **Die Spielfigur**: immer von hinten, im Umhang, mit kleiner Bronzelaterne (keine Klasse, kein Gesicht).
- **Nebet**: „a slender girl in her early teens with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress“ (die blauen Finger sind ihr Zeichen; auch der blaue Faden am Krug).
- **Haremhab**: „a broad-shouldered Egyptian general in bronze scale armour and a blue war crown, seen from behind, a short curved sword at his hip“, immer von hinten oder im Profil.
- **Der Sammler**: wie das Porträt P05 (a very old, tired judge of the dead with a shaved head, a deeply lined face and sorrowful eyes, a single tall white feather tied into a plain white headband, a heavy grey linen mantle).

Hinweis: Der Stil `szene` sagt „Ancient Egyptian underworld“. Für die vier Bilder aus Sandtor (`sz_auftakt_1`, `sz_auftakt_2`, `sz_mitte_sandtor`, `sz_finale_morgen`) besser „Ancient Egyptian desert town“ einsetzen, sonst wird die Stadt zur Unterwelt. Hände sind überall verdeckt oder fern (Regel 8).

Vorschlag Varianten: `a` und `d` (stärkerer Hell-Dunkel-Kontrast) je Bild, 26 Motive × 2 = 52 Bilder, etwa 2 h 40 bei drei Minuten je Bild.

## Bilder

### 1. `sz_auftakt_1`

- **Zweck:** Auftakt, Einstellung 1: Sandtor bei Nacht, Lichter steigen auf
- **Größe:** 1280 × 720
- **motiv:** a small mud-brick desert town at the edge of the western desert at night, flat roofs, palm trees, a single window glowing warm amber, many small turquoise soul lights rising slowly from the roofs into the sky towards the west
- **tex:** deep night blue and faint turquoise colors
- **Prompt (fertig):** Wide cinematic matte painting of a small mud-brick desert town at the edge of the western desert at night, flat roofs, palm trees, a single window glowing warm amber, many small turquoise soul lights rising slowly from the roofs into the sky towards the west Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, deep night blue and faint turquoise colors. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 2. `sz_auftakt_2`

- **Zweck:** Auftakt, Einstellung 2: Nebet im Fieberhaus, du wachst neben ihr
- **Größe:** 1280 × 720
- **motiv:** a slender girl in her early teens with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress lying asleep on a reed mat in a bare mud-brick room, feverish, her blue-stained hand hanging down, beside her a lone cloaked figure seen from behind, holding up a small bronze lantern with a warm amber glow sitting on the floor, seen from behind
- **tex:** warm amber glow against deep shadow
- **Prompt (fertig):** Wide cinematic matte painting of a slender girl in her early teens with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress lying asleep on a reed mat in a bare mud-brick room, feverish, her blue-stained hand hanging down, beside her a lone cloaked figure seen from behind, holding up a small bronze lantern with a warm amber glow sitting on the floor, seen from behind Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, warm amber glow against deep shadow. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 3. `sz_auftakt_3`

- **Zweck:** Auftakt, Einstellung 3: die Hände des Priesters legen dir die Laterne in die Hände
- **Größe:** 1280 × 720
- **motiv:** an old Egyptian priest with a shaved head and a lined face, seen in profile, handing a small bronze lantern to a cloaked figure seen from behind, their hands hidden in long linen sleeves, the flame inside the lantern burns with a deep red heart-shaped glow, dark temple wall behind
- **tex:** warm red and amber against deep night blue
- **Prompt (fertig):** Wide cinematic matte painting of an old Egyptian priest with a shaved head and a lined face, seen in profile, handing a small bronze lantern to a cloaked figure seen from behind, their hands hidden in long linen sleeves, the flame inside the lantern burns with a deep red heart-shaped glow, dark temple wall behind Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, warm red and amber against deep night blue. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 4. `sz_auftakt_4`

- **Zweck:** Auftakt, Einstellung 4: am Tor des Westens; Hintergrund für die Ebene mit den Lichtern
- **Größe:** 1280 × 720
- **motiv:** a lone cloaked figure seen from behind, holding up a small bronze lantern with a warm amber glow standing before a colossal ancient stone gate in the desert cliffs, the gate opens onto a stair leading down into darkness
- **tex:** deep night blue and warm amber colors
- **Prompt (fertig):** Wide cinematic matte painting of a lone cloaked figure seen from behind, holding up a small bronze lantern with a warm amber glow standing before a colossal ancient stone gate in the desert cliffs, the gate opens onto a stair leading down into darkness Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, deep night blue and warm amber colors. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 5. `sz_auftakt_4_lichter`

- **Zweck:** Ebene über sz_auftakt_4 (wird addiert): Seelenlichter auf reinem Schwarz, keine Landschaft
- **Größe:** 1280 × 720 (Ebene, wird im Spiel addiert: reines Schwarz bleibt unsichtbar)
- **motiv:** dozens of small soft glowing turquoise soul lights drifting downwards in a loose stream, nothing else, on a pure flat black background
- **tex:** pure black background, turquoise glow only
- **Prompt (fertig):** Wide cinematic matte painting of dozens of small soft glowing turquoise soul lights drifting downwards in a loose stream, nothing else, on a pure flat black background Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, pure black background, turquoise glow only. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 6. `sz_h02_feldtor`

- **Zweck:** Nach dem Hüter der zweiten Stunde: Haremhab prüft das Siegel am Feldtor
- **Größe:** 1280 × 720
- **motiv:** a broad-shouldered Egyptian general in bronze scale armour and a blue war crown, seen from behind, a short curved sword at his hip kneeling at a tall wooden field gate in a ruined golden barley field, studying a broken red clay seal on the bolt
- **tex:** dusty gold and deep night blue colors
- **Prompt (fertig):** Wide cinematic matte painting of a broad-shouldered Egyptian general in bronze scale armour and a blue war crown, seen from behind, a short curved sword at his hip kneeling at a tall wooden field gate in a ruined golden barley field, studying a broken red clay seal on the bolt Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, dusty gold and deep night blue colors. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 7. `sz_h03_krug`

- **Zweck:** Nach dem König ohne Namen: Nebets Krug im Sarkophag
- **Größe:** 1280 × 720
- **motiv:** a single small white alabaster jar with a lid standing in an open stone sarcophagus, a thin indigo blue thread tied around its neck, gold grave goods scattered in shadow, the jar faintly glowing as if warm
- **tex:** warm amber glow inside deep tomb darkness
- **Prompt (fertig):** Wide cinematic matte painting of a single small white alabaster jar with a lid standing in an open stone sarcophagus, a thin indigo blue thread tied around its neck, gold grave goods scattered in shadow, the jar faintly glowing as if warm Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, warm amber glow inside deep tomb darkness. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 8. `sz_akt1_liste`

- **Zweck:** Ende Akt 1: der Türhüter fährt die Liste der Toten hinab
- **Größe:** 1280 × 720
- **motiv:** a tall grey stone gatekeeper without a mouth, faceless and calm, holding a very long unrolled papyrus scroll, one stone finger resting near the bottom where a fresh line of red ink still glistens
- **tex:** cold grey and deep night blue with a touch of red
- **Prompt (fertig):** Wide cinematic matte painting of a tall grey stone gatekeeper without a mouth, faceless and calm, holding a very long unrolled papyrus scroll, one stone finger resting near the bottom where a fresh line of red ink still glistens Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, cold grey and deep night blue with a touch of red. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 9. `sz_akt1_fieberhaus`

- **Zweck:** Ende Akt 1, Erinnerung: du stirbst an Nebets Bett
- **Größe:** 1280 × 720
- **motiv:** seen from high above, a bare fever room at night: a cloaked figure slumped motionless against the wall with a small bronze lantern still glowing in their lap, on the reed mat beside them a slender girl in her early teens with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress sitting up and reaching out, her mouth open in a cry
- **tex:** cold pale blue with one warm amber glow
- **Prompt (fertig):** Wide cinematic matte painting of seen from high above, a bare fever room at night: a cloaked figure slumped motionless against the wall with a small bronze lantern still glowing in their lap, on the reed mat beside them a slender girl in her early teens with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress sitting up and reaching out, her mouth open in a cry Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, cold pale blue with one warm amber glow. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 10. `sz_akt1_hoehle`

- **Zweck:** Ende Akt 1, Haken: hinter dem zerbrochenen Tor führt das Zugseil in die Höhle
- **Größe:** 1280 × 720
- **motiv:** a thick rope stretched taut across desert sand, leading down into the mouth of a vast cave, deep inside countless tiny jars glowing faintly violet like a field of embers
- **tex:** violet glow and deep night blue
- **Prompt (fertig):** Wide cinematic matte painting of a thick rope stretched taut across desert sand, leading down into the mouth of a vast cave, deep inside countless tiny jars glowing faintly violet like a field of embers Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, violet glow and deep night blue. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 11. `sz_h05_angebot`

- **Zweck:** Vor dem Kampf der fünften Stunde: das Angebot des Sammlers
- **Größe:** 1280 × 720
- **motiv:** a very old, tired judge of the dead with a shaved head, a deeply lined face and sorrowful eyes, a single tall white feather tied into a plain white headband, a heavy grey linen mantle, holding out an open white alabaster jar with both hands as an offering, behind him rows of small clay jars glow violet
- **tex:** violet glow and deep night blue
- **Prompt (fertig):** Wide cinematic matte painting of a very old, tired judge of the dead with a shaved head, a deeply lined face and sorrowful eyes, a single tall white feather tied into a plain white headband, a heavy grey linen mantle, holding out an open white alabaster jar with both hands as an offering, behind him rows of small clay jars glow violet Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, violet glow and deep night blue. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 12. `sz_mitte_isis`

- **Zweck:** Mitte: Isis sieht auf deine Schulter
- **Größe:** 1280 × 720
- **motiv:** the goddess Isis as a grieving woman with dark braided hair and a small throne-shaped crown, large folded wings of a kite behind her shoulders, gazing tenderly downwards at a small bird perched on the shoulder of a cloaked figure seen from behind
- **tex:** soft green-gold glow and deep night blue
- **Prompt (fertig):** Wide cinematic matte painting of the goddess Isis as a grieving woman with dark braided hair and a small throne-shaped crown, large folded wings of a kite behind her shoulders, gazing tenderly downwards at a small bird perched on the shoulder of a cloaked figure seen from behind Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, soft green-gold glow and deep night blue. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 13. `sz_mitte_ba`

- **Zweck:** Mitte, die Enthüllung: der Vogel hat Nebets Gesicht
- **Größe:** 1280 × 720
- **motiv:** a small falcon-like bird with the face of a young girl, the Egyptian ba bird, perched on a dark cloaked shoulder, her face is the face of a girl with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress, tear-stained, ashamed, looking up
- **tex:** pale turquoise glow and deep shadow
- **Prompt (fertig):** Wide cinematic matte painting of a small falcon-like bird with the face of a young girl, the Egyptian ba bird, perched on a dark cloaked shoulder, her face is the face of a girl with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress, tear-stained, ashamed, looking up Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, pale turquoise glow and deep shadow. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 14. `sz_mitte_sandtor`

- **Zweck:** Mitte: in Sandtor wird Nebets Leib kälter
- **Größe:** 1280 × 720
- **motiv:** a slender girl in her early teens with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress lying very still on a reed mat in a dark mud-brick room, frost-pale skin, a small clay oil dish beside her has burned almost out
- **tex:** cold blue colors with a dying ember of amber
- **Prompt (fertig):** Wide cinematic matte painting of a slender girl in her early teens with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress lying very still on a reed mat in a dark mud-brick room, frost-pale skin, a small clay oil dish beside her has burned almost out Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, cold blue colors with a dying ember of amber. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 15. `sz_h06_mitternacht`

- **Zweck:** Nach der sechsten Stunde: im Licht der Mitternacht siehst du das Ende der Nacht
- **Größe:** 1280 × 720
- **motiv:** a blinding white-gold burst of light where the sun god and the mummified Osiris meet, far beyond it on the horizon a great eastern gate, and before the gate a tiny dark shadowy figure carrying a jar
- **tex:** white gold burst fading into deep night blue
- **Prompt (fertig):** Wide cinematic matte painting of a blinding white-gold burst of light where the sun god and the mummified Osiris meet, far beyond it on the horizon a great eastern gate, and before the gate a tiny dark shadowy figure carrying a jar Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, white gold burst fading into deep night blue. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 16. `sz_h07_bug`

- **Zweck:** Nach Apophis: Haremhab am Bug der Sonnenbarke
- **Größe:** 1280 × 720
- **motiv:** a broad-shouldered Egyptian general in bronze scale armour and a blue war crown, seen from behind, a short curved sword at his hip standing at the prow of the golden sun boat, wiping his sword, looking east over dark water where the coils of a giant serpent sink away
- **tex:** dark water, gold and deep night blue
- **Prompt (fertig):** Wide cinematic matte painting of a broad-shouldered Egyptian general in bronze scale armour and a blue war crown, seen from behind, a short curved sword at his hip standing at the prow of the golden sun boat, wiping his sword, looking east over dark water where the coils of a giant serpent sink away Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, dark water, gold and deep night blue. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 17. `sz_akt2_gruft`

- **Zweck:** Ende Akt 2: in der stummen Gruft sitzt dein eigener Ba
- **Größe:** 1280 × 720
- **motiv:** a small falcon-like bird with a human face sitting alone in a dark stone crypt, a broken golden ring of the royal name hanging around it, its face shimmering and hard to see, turned towards the viewer
- **tex:** cold silver and deep night blue
- **Prompt (fertig):** Wide cinematic matte painting of a small falcon-like bird with a human face sitting alone in a dark stone crypt, a broken golden ring of the royal name hanging around it, its face shimmering and hard to see, turned towards the viewer Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, cold silver and deep night blue. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 18. `sz_akt2_osten`

- **Zweck:** Ende Akt 2: zwei gehen der Barke voraus
- **Größe:** 1280 × 720
- **motiv:** a vast dark landscape seen from above, a faint glowing path leads to a distant eastern gate on the horizon, far ahead on the path a tiny shadowy figure carrying a jar, behind it a general in bronze armour running
- **tex:** deep night blue with first pale rose at the horizon
- **Prompt (fertig):** Wide cinematic matte painting of a vast dark landscape seen from above, a faint glowing path leads to a distant eastern gate on the horizon, far ahead on the path a tiny shadowy figure carrying a jar, behind it a general in bronze armour running Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, deep night blue with first pale rose at the horizon. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 19. `sz_h12_schatten`

- **Zweck:** Vor dem letzten Kampf: der Schatten mit Nebets Krug
- **Größe:** 1280 × 720
- **motiv:** a tall faceless shadow in the shape of an old judge, made of darkness, cradling a small white alabaster jar with a blue thread in both hands, standing before a colossal eastern gate
- **tex:** deep night blue with pale rose light behind the gate
- **Prompt (fertig):** Wide cinematic matte painting of a tall faceless shadow in the shape of an old judge, made of darkness, cradling a small white alabaster jar with a blue thread in both hands, standing before a colossal eastern gate Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, deep night blue with pale rose light behind the gate. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 20. `sz_finale_waage`

- **Zweck:** Finale: die Halle der Waage
- **Größe:** 1280 × 720
- **motiv:** a vast hall of tall columns with a giant golden balance scale at its centre, an ibis-headed god holding a reed pen beside it, rows of seated judges in shadow, one seat empty
- **tex:** deep night blue and gold colors
- **Prompt (fertig):** Wide cinematic matte painting of a vast hall of tall columns with a giant golden balance scale at its centre, an ibis-headed god holding a reed pen beside it, rows of seated judges in shadow, one seat empty Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, deep night blue and gold colors. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 21. `sz_finale_dunkel`

- **Zweck:** Finale: du nimmst dein Herz aus der Laterne, das Licht geht aus
- **Größe:** 1280 × 720
- **motiv:** a small bronze lantern standing open on a dark stone floor, a glowing red heart floating up out of it, the last warm glow fading into complete darkness all around
- **tex:** deep red glow fading into black
- **Prompt (fertig):** Wide cinematic matte painting of a small bronze lantern standing open on a dark stone floor, a glowing red heart floating up out of it, the last warm glow fading into complete darkness all around Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, deep red glow fading into black. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 22. `sz_finale_leicht`

- **Zweck:** Finale, Ende „Wahr an Stimme“
- **Größe:** 1280 × 720
- **motiv:** a golden balance scale perfectly level, a heart on one pan and a white ostrich feather on the other, behind it through a tall doorway a single bright new star rising in the northern sky over the desert at first dawn
- **tex:** pale rose, gold and deep blue colors of first dawn
- **Prompt (fertig):** Wide cinematic matte painting of a golden balance scale perfectly level, a heart on one pan and a white ostrich feather on the other, behind it through a tall doorway a single bright new star rising in the northern sky over the desert at first dawn Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, pale rose, gold and deep blue colors of first dawn. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 23. `sz_finale_schwebe`

- **Zweck:** Finale, Ende „In der Schwebe“: es fehlt ein Fährmann
- **Größe:** 1280 × 720
- **motiv:** a small wooden ferry boat moored at the bank of a dark river at first dawn, a cedar oar lying across it, faint turquoise soul lights waiting on the far bank
- **tex:** pale grey dawn and turquoise colors
- **Prompt (fertig):** Wide cinematic matte painting of a small wooden ferry boat moored at the bank of a dark river at first dawn, a cedar oar lying across it, faint turquoise soul lights waiting on the far bank Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, pale grey dawn and turquoise colors. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 24. `sz_finale_schwer`

- **Zweck:** Finale, Ende „Zu schwer“: die Fresserin hebt den Kopf
- **Größe:** 1280 × 720
- **motiv:** a crocodile-headed beast with the mane of a lion lifting its head beside a tilted golden balance scale, an ibis-headed god resting one hand on the sinking pan
- **tex:** dark red and gold against deep shadow
- **Prompt (fertig):** Wide cinematic matte painting of a crocodile-headed beast with the mane of a lion lifting its head beside a tilted golden balance scale, an ibis-headed god resting one hand on the sinking pan Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, dark red and gold against deep shadow. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 25. `sz_finale_schatten`

- **Zweck:** Finale: Thot sagt dem Schatten die Wahrheit über seine Tochter
- **Größe:** 1280 × 720
- **motiv:** an ibis-headed god with a reed pen speaking to a faceless shadow of an old judge, the shadow sets down a small alabaster jar and takes a small bronze lantern instead, first light falling between them
- **tex:** pale rose light and deep night blue
- **Prompt (fertig):** Wide cinematic matte painting of an ibis-headed god with a reed pen speaking to a faceless shadow of an old judge, the shadow sets down a small alabaster jar and takes a small bronze lantern instead, first light falling between them Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, pale rose light and deep night blue. No people in the foreground except where described, nothing written anywhere, no frame, no border.

### 26. `sz_finale_morgen`

- **Zweck:** Finale: Morgen über Sandtor
- **Größe:** 1280 × 720
- **motiv:** sunrise over a small mud-brick desert town, the sun rising red from the eastern horizon, through an open window a slender girl in her early teens with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress sitting up on her reed mat, a small bird flying in through the window
- **tex:** warm rose and gold colors of sunrise
- **Prompt (fertig):** Wide cinematic matte painting of sunrise over a small mud-brick desert town, the sun rising red from the eastern horizon, through an open window a slender girl in her early teens with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress sitting up on her reed mat, a small bird flying in through the window Ancient Egyptian underworld, painterly realistic style with deep atmosphere and depth, large calm areas of dark sky or shadow in the upper third, the main subject in the lower half. Muted earthy colors against deep night blue, warm rose and gold colors of sunrise. No people in the foreground except where described, nothing written anywhere, no frame, no border.

## Für bildwerk_plan.json

Einträge für `motive` (Gruppe `szenen`), dazu eine Stufe `szenen` mit Stil `szene`, Ansicht `szene`, Breite 1280, Höhe 720, und unter `einbau` die Zuordnung zu `ui/szenen/<datei>.webp`:

```json
[
 {
  "id": "sz_auftakt_1",
  "name": "Auftakt, Einstellung 1: Sandtor bei Nacht, Lichter steigen auf",
  "gruppe": "szenen",
  "motiv": "a small mud-brick desert town at the edge of the western desert at night, flat roofs, palm trees, a single window glowing warm amber, many small turquoise soul lights rising slowly from the roofs into the sky towards the west",
  "tex": "deep night blue and faint turquoise colors"
 },
 {
  "id": "sz_auftakt_2",
  "name": "Auftakt, Einstellung 2: Nebet im Fieberhaus, du wachst neben ihr",
  "gruppe": "szenen",
  "motiv": "a slender girl in her early teens with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress lying asleep on a reed mat in a bare mud-brick room, feverish, her blue-stained hand hanging down, beside her a lone cloaked figure seen from behind, holding up a small bronze lantern with a warm amber glow sitting on the floor, seen from behind",
  "tex": "warm amber glow against deep shadow"
 },
 {
  "id": "sz_auftakt_3",
  "name": "Auftakt, Einstellung 3: die Hände des Priesters legen dir die Laterne in die Hände",
  "gruppe": "szenen",
  "motiv": "an old Egyptian priest with a shaved head and a lined face, seen in profile, handing a small bronze lantern to a cloaked figure seen from behind, their hands hidden in long linen sleeves, the flame inside the lantern burns with a deep red heart-shaped glow, dark temple wall behind",
  "tex": "warm red and amber against deep night blue"
 },
 {
  "id": "sz_auftakt_4",
  "name": "Auftakt, Einstellung 4: am Tor des Westens; Hintergrund für die Ebene mit den Lichtern",
  "gruppe": "szenen",
  "motiv": "a lone cloaked figure seen from behind, holding up a small bronze lantern with a warm amber glow standing before a colossal ancient stone gate in the desert cliffs, the gate opens onto a stair leading down into darkness",
  "tex": "deep night blue and warm amber colors"
 },
 {
  "id": "sz_auftakt_4_lichter",
  "name": "Ebene über sz_auftakt_4 (wird addiert): Seelenlichter auf reinem Schwarz, keine Landschaft",
  "gruppe": "szenen",
  "motiv": "dozens of small soft glowing turquoise soul lights drifting downwards in a loose stream, nothing else, on a pure flat black background",
  "tex": "pure black background, turquoise glow only"
 },
 {
  "id": "sz_h02_feldtor",
  "name": "Nach dem Hüter der zweiten Stunde: Haremhab prüft das Siegel am Feldtor",
  "gruppe": "szenen",
  "motiv": "a broad-shouldered Egyptian general in bronze scale armour and a blue war crown, seen from behind, a short curved sword at his hip kneeling at a tall wooden field gate in a ruined golden barley field, studying a broken red clay seal on the bolt",
  "tex": "dusty gold and deep night blue colors"
 },
 {
  "id": "sz_h03_krug",
  "name": "Nach dem König ohne Namen: Nebets Krug im Sarkophag",
  "gruppe": "szenen",
  "motiv": "a single small white alabaster jar with a lid standing in an open stone sarcophagus, a thin indigo blue thread tied around its neck, gold grave goods scattered in shadow, the jar faintly glowing as if warm",
  "tex": "warm amber glow inside deep tomb darkness"
 },
 {
  "id": "sz_akt1_liste",
  "name": "Ende Akt 1: der Türhüter fährt die Liste der Toten hinab",
  "gruppe": "szenen",
  "motiv": "a tall grey stone gatekeeper without a mouth, faceless and calm, holding a very long unrolled papyrus scroll, one stone finger resting near the bottom where a fresh line of red ink still glistens",
  "tex": "cold grey and deep night blue with a touch of red"
 },
 {
  "id": "sz_akt1_fieberhaus",
  "name": "Ende Akt 1, Erinnerung: du stirbst an Nebets Bett",
  "gruppe": "szenen",
  "motiv": "seen from high above, a bare fever room at night: a cloaked figure slumped motionless against the wall with a small bronze lantern still glowing in their lap, on the reed mat beside them a slender girl in her early teens with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress sitting up and reaching out, her mouth open in a cry",
  "tex": "cold pale blue with one warm amber glow"
 },
 {
  "id": "sz_akt1_hoehle",
  "name": "Ende Akt 1, Haken: hinter dem zerbrochenen Tor führt das Zugseil in die Höhle",
  "gruppe": "szenen",
  "motiv": "a thick rope stretched taut across desert sand, leading down into the mouth of a vast cave, deep inside countless tiny jars glowing faintly violet like a field of embers",
  "tex": "violet glow and deep night blue"
 },
 {
  "id": "sz_h05_angebot",
  "name": "Vor dem Kampf der fünften Stunde: das Angebot des Sammlers",
  "gruppe": "szenen",
  "motiv": "a very old, tired judge of the dead with a shaved head, a deeply lined face and sorrowful eyes, a single tall white feather tied into a plain white headband, a heavy grey linen mantle, holding out an open white alabaster jar with both hands as an offering, behind him rows of small clay jars glow violet",
  "tex": "violet glow and deep night blue"
 },
 {
  "id": "sz_mitte_isis",
  "name": "Mitte: Isis sieht auf deine Schulter",
  "gruppe": "szenen",
  "motiv": "the goddess Isis as a grieving woman with dark braided hair and a small throne-shaped crown, large folded wings of a kite behind her shoulders, gazing tenderly downwards at a small bird perched on the shoulder of a cloaked figure seen from behind",
  "tex": "soft green-gold glow and deep night blue"
 },
 {
  "id": "sz_mitte_ba",
  "name": "Mitte, die Enthüllung: der Vogel hat Nebets Gesicht",
  "gruppe": "szenen",
  "motiv": "a small falcon-like bird with the face of a young girl, the Egyptian ba bird, perched on a dark cloaked shoulder, her face is the face of a girl with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress, tear-stained, ashamed, looking up",
  "tex": "pale turquoise glow and deep shadow"
 },
 {
  "id": "sz_mitte_sandtor",
  "name": "Mitte: in Sandtor wird Nebets Leib kälter",
  "gruppe": "szenen",
  "motiv": "a slender girl in her early teens with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress lying very still on a reed mat in a dark mud-brick room, frost-pale skin, a small clay oil dish beside her has burned almost out",
  "tex": "cold blue colors with a dying ember of amber"
 },
 {
  "id": "sz_h06_mitternacht",
  "name": "Nach der sechsten Stunde: im Licht der Mitternacht siehst du das Ende der Nacht",
  "gruppe": "szenen",
  "motiv": "a blinding white-gold burst of light where the sun god and the mummified Osiris meet, far beyond it on the horizon a great eastern gate, and before the gate a tiny dark shadowy figure carrying a jar",
  "tex": "white gold burst fading into deep night blue"
 },
 {
  "id": "sz_h07_bug",
  "name": "Nach Apophis: Haremhab am Bug der Sonnenbarke",
  "gruppe": "szenen",
  "motiv": "a broad-shouldered Egyptian general in bronze scale armour and a blue war crown, seen from behind, a short curved sword at his hip standing at the prow of the golden sun boat, wiping his sword, looking east over dark water where the coils of a giant serpent sink away",
  "tex": "dark water, gold and deep night blue"
 },
 {
  "id": "sz_akt2_gruft",
  "name": "Ende Akt 2: in der stummen Gruft sitzt dein eigener Ba",
  "gruppe": "szenen",
  "motiv": "a small falcon-like bird with a human face sitting alone in a dark stone crypt, a broken golden ring of the royal name hanging around it, its face shimmering and hard to see, turned towards the viewer",
  "tex": "cold silver and deep night blue"
 },
 {
  "id": "sz_akt2_osten",
  "name": "Ende Akt 2: zwei gehen der Barke voraus",
  "gruppe": "szenen",
  "motiv": "a vast dark landscape seen from above, a faint glowing path leads to a distant eastern gate on the horizon, far ahead on the path a tiny shadowy figure carrying a jar, behind it a general in bronze armour running",
  "tex": "deep night blue with first pale rose at the horizon"
 },
 {
  "id": "sz_h12_schatten",
  "name": "Vor dem letzten Kampf: der Schatten mit Nebets Krug",
  "gruppe": "szenen",
  "motiv": "a tall faceless shadow in the shape of an old judge, made of darkness, cradling a small white alabaster jar with a blue thread in both hands, standing before a colossal eastern gate",
  "tex": "deep night blue with pale rose light behind the gate"
 },
 {
  "id": "sz_finale_waage",
  "name": "Finale: die Halle der Waage",
  "gruppe": "szenen",
  "motiv": "a vast hall of tall columns with a giant golden balance scale at its centre, an ibis-headed god holding a reed pen beside it, rows of seated judges in shadow, one seat empty",
  "tex": "deep night blue and gold colors"
 },
 {
  "id": "sz_finale_dunkel",
  "name": "Finale: du nimmst dein Herz aus der Laterne, das Licht geht aus",
  "gruppe": "szenen",
  "motiv": "a small bronze lantern standing open on a dark stone floor, a glowing red heart floating up out of it, the last warm glow fading into complete darkness all around",
  "tex": "deep red glow fading into black"
 },
 {
  "id": "sz_finale_leicht",
  "name": "Finale, Ende „Wahr an Stimme“",
  "gruppe": "szenen",
  "motiv": "a golden balance scale perfectly level, a heart on one pan and a white ostrich feather on the other, behind it through a tall doorway a single bright new star rising in the northern sky over the desert at first dawn",
  "tex": "pale rose, gold and deep blue colors of first dawn"
 },
 {
  "id": "sz_finale_schwebe",
  "name": "Finale, Ende „In der Schwebe“: es fehlt ein Fährmann",
  "gruppe": "szenen",
  "motiv": "a small wooden ferry boat moored at the bank of a dark river at first dawn, a cedar oar lying across it, faint turquoise soul lights waiting on the far bank",
  "tex": "pale grey dawn and turquoise colors"
 },
 {
  "id": "sz_finale_schwer",
  "name": "Finale, Ende „Zu schwer“: die Fresserin hebt den Kopf",
  "gruppe": "szenen",
  "motiv": "a crocodile-headed beast with the mane of a lion lifting its head beside a tilted golden balance scale, an ibis-headed god resting one hand on the sinking pan",
  "tex": "dark red and gold against deep shadow"
 },
 {
  "id": "sz_finale_schatten",
  "name": "Finale: Thot sagt dem Schatten die Wahrheit über seine Tochter",
  "gruppe": "szenen",
  "motiv": "an ibis-headed god with a reed pen speaking to a faceless shadow of an old judge, the shadow sets down a small alabaster jar and takes a small bronze lantern instead, first light falling between them",
  "tex": "pale rose light and deep night blue"
 },
 {
  "id": "sz_finale_morgen",
  "name": "Finale: Morgen über Sandtor",
  "gruppe": "szenen",
  "motiv": "sunrise over a small mud-brick desert town, the sun rising red from the eastern horizon, through an open window a slender girl in her early teens with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress sitting up on her reed mat, a small bird flying in through the window",
  "tex": "warm rose and gold colors of sunrise"
 }
]
```
