# Drehbuch der Zwischensequenzen

Fassung 4.3. Quelle der Wahrheit ist `scripts/szenen.gd` (dieses Drehbuch ist daraus erzeugt und von Hand ergänzt); das System: `scripts/szene.gd`. Bildwünsche: `tools/bildwerk/wunsch_szenen.md`, Sprechzeilen: `tools/ton/sprechzeilen.json`.

**Wie es abläuft:** Jede Sequenz läuft je Spielstand einmal, pausiert das Spiel, blendet die Anzeige aus und lässt sich überspringen (Esc, B, Start, Knopf oben rechts); Klick, Tippen, Leertaste, E oder A zeigt die nächste Zeile. Im Spielmenü stehen sie unter „Erinnerungen“. Einstellungen mit Bild zeigen ein gemaltes Standbild mit langsamer Kamerafahrt; fehlt das Bild, steht der Ersatz da (Porträt im Goldrahmen, geliehenes Akt- oder Titelbild mit Schleier, ein Blick in die Spielwelt oder eine dunkle Zierfläche mit gezeichnetem Zeichen). Welt-Einstellungen fahren die Spielkamera zu Hüter, Figur oder Arena, mit breiten Schwarzbalken und gedämpftem Licht.

**Wo sie laufen:** Auftakt vor der Tafel der ersten Stunde · `hNN_vor` beim Erwachen des Hüters · `hNN_nach`, `akt1_ende`, `akt2_ende` gut drei Sekunden nach seinem Fall · `mitte` vor dem ersten Gespräch mit Isis (sonst beim Erwachen des Hüters der sechsten Stunde) · `finale` am Tor des Ostens, bevor die Pforte fragt.

Dauer: geschätzt aus der Textlänge (etwa 0,06 s je Zeichen plus 1,4 s je Zeile); mit Stimme richtet sie sich nach der Aufnahme.

## auftakt: Die Nacht, in der Nebet fiebert

*Zweck:* Vor der ersten Stunde. Setzt Uhr, Fallhöhe und Begleiter: Nebet fiebert, zwölf Stunden, die Laterne, der Vogel auf der Schulter.

1. **Bild `sz_auftakt_1`**: a small mud-brick desert town at the edge of the western desert at night, flat roofs, palm trees, a single window glowing warm amber, many small turquoise soul lights rising slowly from the roofs into the sky towards the west
   - *ohne Bild:* titel, zeichen:sonne
   - Sandtor, am Rand des Westens. Seit drei Nächten geht die Sonne später auf.
   - Und seit drei Nächten steigen aus den Dächern Lichter, die nicht wiederkommen.
2. **Bild `sz_auftakt_2`**: a slender girl in her early teens with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress lying asleep on a reed mat in a bare mud-brick room, feverish, her blue-stained hand hanging down, beside her a lone cloaked figure seen from behind, holding up a small bronze lantern with a warm amber glow sitting on the floor, seen from behind
   - *ohne Bild:* zeichen:laterne
   - Im Fieberhaus liegt Nebet. Sie webt Leinen. Ihre Finger sind blau vom Färben, und sie glüht.
   - Drei Nächte hast du an ihrem Bett gesessen und das Licht gehalten.
3. **Bild `sz_auftakt_3`**: an old Egyptian priest with a shaved head and a lined face, seen in profile, handing a small bronze lantern to a cloaked figure seen from behind, their hands hidden in long linen sleeves, the flame inside the lantern burns with a deep red heart-shaped glow, dark temple wall behind
   - *ohne Bild:* zeichen:laterne
   - **Der alte Priester:** „Das Fieber bricht im Morgengrauen. Wenn eines kommt.“
   - **Der alte Priester:** „Unten steht die Waage still. Ohne Gewogene zieht niemand die Barke der Sonne.“
   - **Der alte Priester:** „Nimm die Laterne. Geh hinab, solange sie brennt. Und frag nicht, warum gerade du.“
4. **Bild `sz_auftakt_4`**: a lone cloaked figure seen from behind, holding up a small bronze lantern with a warm amber glow standing before a colossal ancient stone gate in the desert cliffs, the gate opens onto a stair leading down into darkness
   - *ohne Bild:* akt:0, titel, zeichen:tor
   - *Ebene davor (Parallaxe, addiert):* `sz_auftakt_4_lichter`: dozens of small soft glowing turquoise soul lights drifting downwards in a loose stream, nothing else, on a pure flat black background
   - Zwölf Stunden hat die Nacht.
   - Dann kommt der Morgen. Oder er kommt nie wieder.
5. **Welt:** Kamera fährt zu deiner Figur
   - Etwas mit kleinen Flügeln setzt sich auf deine Schulter, als hätte es immer dort gesessen.
   - **Dein Ba:** „Ich bin dein Ba. Ich flattere, du gehst. Frag nicht, wer führt.“

*Dauer:* etwa 59 Sekunden.

## h01_vor: Der Fährmann

*Zweck:* Mahaf erwacht. Kurzer Blick in die Welt.

1. **Welt:** Kamera fährt zu dem Hüter
   - Ein Licht, größer als die anderen, dreht sich nach dir um. Es hält ein Ruder, das es nicht hat.
   - **Dein Ba:** „Er führt sie im Kreis. Dich auch, wenn du ihn lässt.“

*Dauer:* etwa 11 Sekunden.

## h01_nach: Heute schon einmal

*Zweck:* Erster Haken: Mahaf hat dich „heute schon übergesetzt“.

1. **Welt:** Kamera fährt zu der Arena
   - Mahaf zerfällt zu Licht. Bevor er verlischt, sieht er dich an, lange, wie man einen Fahrgast ansieht.
   - **Mahaf:** „Dich habe ich heute schon übergesetzt.“
   - **Dein Ba:** „Er ist verwirrt. Komm weiter.“

*Dauer:* etwa 14 Sekunden.

## h02_vor: Die zwölfte Haut

*Zweck:* Die Mutter der Häute; Humor des Ba.

1. **Welt:** Kamera fährt zu dem Hüter
   - Zwischen den Garben richtet sich etwas auf, Haut über Haut, und streift die zwölfte ab.
   - **Dein Ba:** „Das ist ekelhaft. Ich sag's nur.“

*Dauer:* etwa 10 Sekunden.

## h02_nach: Ein General am Feldtor

*Zweck:* Fährte Königsring; Haremhab tritt auf.

1. **Welt:** Kamera fährt zu der Arena
   - Unter der letzten Haut liegt nur Sand. Darin ein Abdruck: ein Königsring, der Name herausgekratzt.
2. **Bild `sz_h02_feldtor`**: a broad-shouldered Egyptian general in bronze scale armour and a blue war crown, seen from behind, a short curved sword at his hip kneeling at a tall wooden field gate in a ruined golden barley field, studying a broken red clay seal on the bolt
   - *ohne Bild:* welt, zeichen:tor
   - Am Feldtor kniet ein Mann in der Rüstung eines Generals und prüft das Wachs am Riegel.
   - **Haremhab:** „Schlampig. Wer tilgt, muss gründlich tilgen, sonst spricht der Rest.“
   - **Haremhab:** „Du jagst ihn auch. Gut. Geh vor. Ich bin hinter dir.“

*Dauer:* etwa 23 Sekunden.

## h03_vor: Der König ohne Namen

*Zweck:* Der König; Rückbezug auf die Namensscherbe.

1. **Welt:** Kamera fährt zu dem Hüter
   - Auf dem Sarkophag sitzt ein König, ein Schwert aus dem Gold der Tagesbarke über den Knien. Er sieht durch dich hindurch.
   - **Dein Ba:** „Du kennst seinen Namen. Er nicht. Entzünde ihn an den Wänden, dann hört er ihn.“
   - **Dein Ba:** „Frag ihn nicht, wie er heißt. Entzünde die Zeichen an den Wänden. Dann hört er es.“

*Dauer:* etwa 21 Sekunden.

## h03_nach: Ein Krug für Nebet

*Zweck:* Haken der dritten Stunde: Nebets Krug.

1. **Welt:** Kamera fährt zu der Arena
   - Der König sinkt zurück in seinen Sarkophag. Neben ihm, wo die Beigaben liegen sollten, steht ein Krug.
2. **Bild `sz_h03_krug`**: a single small white alabaster jar with a lid standing in an open stone sarcophagus, a thin indigo blue thread tied around its neck, gold grave goods scattered in shadow, the jar faintly glowing as if warm
   - *ohne Bild:* zeichen:krug
   - Leer. Versiegelt. Noch warm. Um den Hals ein Faden, blau gefärbt.
   - Auf dem Siegel steht ein Name, den du kennst.
   - Nebet.
   - **Dein Ba:** „Das ist nur ein Krug. Das heißt gar nichts. Komm.“

*Dauer:* etwa 23 Sekunden.

## h04_vor: Die Frage

*Zweck:* Der Türhüter stellt die Frage; der Ba fleht.

1. **Welt:** Kamera fährt zu dem Hüter
   - Der Türhüter hebt den Kopf. Er hat keinen Mund. Trotzdem hörst du die Frage.
   - **Der Stumme Türhüter:** Wie heißt du?
   - **Dein Ba:** „Sag es nicht. Kämpf einfach. Bitte.“

*Dauer:* etwa 12 Sekunden.

## akt1_ende: Ende des ersten Aktes: Dein Name

*Zweck:* Wende am Ende von Akt 1: Du bist tot. Haken in Akt 2: „Ein Krug für dich. Und einen für sie.“

1. **Welt:** Kamera fährt zu der Arena
   - Der Türhüter liegt in den Scherben seines Tores. Er fragt noch immer.
   - **Der Stumme Türhüter:** Wie heißt du?
2. **Bild `sz_akt1_liste`**: a tall grey stone gatekeeper without a mouth, faceless and calm, holding a very long unrolled papyrus scroll, one stone finger resting near the bottom where a fresh line of red ink still glistens
   - *ohne Bild:* hueter:h04, zeichen:tor
   - Du sagst deinen Namen.
   - Er fährt mit dem Finger die Liste des Westens hinab, bis ganz nach unten, wo die Tinte noch feucht ist. Rot.
   - Er nickt. Hinter ihm öffnet sich das Tor. Es öffnet sich nur für Tote.
3. **Bild `sz_akt1_fieberhaus`**: seen from high above, a bare fever room at night: a cloaked figure slumped motionless against the wall with a small bronze lantern still glowing in their lap, on the reed mat beside them a slender girl in her early teens with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress sitting up and reaching out, her mouth open in a cry
   - *ohne Bild:* zeichen:laterne
   - Du erinnerst dich.
   - Das Fieberhaus. Ihr Bett. Deine Hände um die Lampe, und wie sie kalt werden, ganz ruhig, noch vor Mitternacht.
   - Nebet hat geschrien. Du hast es nicht mehr gehört.
4. **Welt:** Kamera fährt zu deiner Figur
   - **Dein Ba:** „Ich wollte es dir sagen.“
   - **Dein Ba:** „Ich wollte nur nicht, dass du stehen bleibst.“
5. **Bild `sz_akt1_hoehle`**: a thick rope stretched taut across desert sand, leading down into the mouth of a vast cave, deep inside countless tiny jars glowing faintly violet like a field of embers
   - *ohne Bild:* akt:1, zeichen:krug
   - **Eine Stimme aus der Tiefe:** „Komm herunter. Ich habe einen Krug für dich gemacht.“
   - **Eine Stimme aus der Tiefe:** „Und einen für sie.“
6. **Zwischentitel** „Ende des ersten Aktes“ auf der Zierfläche

*Dauer:* etwa 56 Sekunden.

## h05_vor: Das Angebot

*Zweck:* Das Angebot des Sammlers (Rückbezug Sternenherz).

   - **Der Sammler:** „Ein Stern sieht wieder nach Norden. Das warst du. Und doch bist du hier.“
   - **Der Sammler:** „Zwei Herzen in deiner Laterne, und eines gestohlen. Siehst du? Wir sind uns ähnlich.“
   - **Der Sammler:** „Leg die Laterne in den Krug. Dann ist Sandtor vollständig, und keiner von euch wird je gefressen. Auch sie nicht.“
   - **Dein Ba:** „Hör nicht auf ihn.“
1. **Bild `sz_h05_angebot`**: a very old, tired judge of the dead with a shaved head, a deeply lined face and sorrowful eyes, a single tall white feather tied into a plain white headband, a heavy grey linen mantle, holding out an open white alabaster jar with both hands as an offering, behind him rows of small clay jars glow violet
   - *ohne Bild:* portrait:P05
2. **Welt:** Kamera fährt zu dem Hüter
   - Um ihn herum steigen Krüge aus dem Boden, und in jedem schlägt es.

*Dauer:* etwa 28 Sekunden.

## h05_nach: Ein Mann ohne Schatten

*Zweck:* Scheinbarer Sieg: Der Schatten fehlt; Haremhab jagt weiter.

1. **Welt:** Kamera fährt zu der Arena
   - Die Krüge zerspringen, einer nach dem anderen. Tausend Herzen fliegen heim, und irgendwo oben bewegt sich eine Waage.
   - An der Wand, wo der Schatten des Richters sein müsste, ist nichts.
   - **Haremhab:** „Er ist nicht tot. Ein Mann ohne Schatten. Den finde ich.“

*Dauer:* etwa 18 Sekunden.

## mitte: Der Name auf deiner Schulter

*Zweck:* Mitte, Verrat: Isis nennt den Vogel Nebet. Danach die Entscheidung der sechsten Stunde.

1. **Bild `sz_mitte_isis`**: the goddess Isis as a grieving woman with dark braided hair and a small throne-shaped crown, large folded wings of a kite behind her shoulders, gazing tenderly downwards at a small bird perched on the shoulder of a cloaked figure seen from behind
   - *ohne Bild:* portrait:P11
   - Isis sieht nicht dich an. Sie sieht auf deine Schulter.
   - **Isis:** „Komm her, Kleine. Ich kenne deinen Namen. Ich kenne jeden Namen.“
   - **Isis:** „Nebet.“
2. **Bild `sz_mitte_ba`**: a small falcon-like bird with the face of a young girl, the Egyptian ba bird, perched on a dark cloaked shoulder, her face is the face of a girl with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress, tear-stained, ashamed, looking up
   - *ohne Bild:* zeichen:ba
   - Der Vogel auf deiner Schulter hat ein Gesicht. Du hast es die ganze Nacht nicht angesehen.
   - **Nebet:** „Ich bin dir nachgeflogen. Aus dem Fieber, als du nicht mehr geatmet hast.“
   - **Nebet:** „Ich hab gelogen, die ganze Nacht. Hättest du gewusst, dass du tot bist, wärst du stehen geblieben. Und ich wollte leben.“
3. **Bild `sz_mitte_sandtor`**: a slender girl in her early teens with dark braided hair and fingertips stained deep indigo blue from dye, plain undyed linen dress lying very still on a reed mat in a dark mud-brick room, frost-pale skin, a small clay oil dish beside her has burned almost out
   - *ohne Bild:* titel, zeichen:laterne
   - **Isis:** „Ihr Leib liegt in Sandtor und wird kälter, je länger sie hier ist. Ein Ba, der zu lange fort ist, findet nicht zurück.“
   - **Isis:** „Es ist Mitternacht. Entscheide, bevor die Nacht es für dich tut.“

*Dauer:* etwa 47 Sekunden.

## h06_nach: Mitternacht

*Zweck:* Mitternacht: Blick bis ans Ende der Nacht.

1. **Bild `sz_h06_mitternacht`**: a blinding white-gold burst of light where the sun god and the mummified Osiris meet, far beyond it on the horizon a great eastern gate, and before the gate a tiny dark shadowy figure carrying a jar
   - *ohne Bild:* akt:2, zeichen:sonne
   - Für einen Atemzug sind Re und Osiris eins, und in diesem Licht siehst du bis ans Ende der Nacht.
   - Das Tor des Ostens. Und davor ein Schatten, mit einem Krug im Arm.

*Dauer:* etwa 12 Sekunden.

## h07_vor: Die Sandbank

*Zweck:* Apophis; Haremhab am Bug.

1. **Welt:** Kamera fährt zu dem Hüter
   - Eine Windung, dick wie ein Tempel, schiebt sich aus dem Sand. Der Rest liegt darunter und trinkt.
   - **Haremhab:** „Endlich etwas, das man ohne Zweifel töten darf.“

*Dauer:* etwa 11 Sekunden.

## h07_nach: Was Haremhab kann

*Zweck:* Haremhabs Plan: das Buch verbrennen.

1. **Bild `sz_h07_bug`**: a broad-shouldered Egyptian general in bronze scale armour and a blue war crown, seen from behind, a short curved sword at his hip standing at the prow of the golden sun boat, wiping his sword, looking east over dark water where the coils of a giant serpent sink away
   - *ohne Bild:* welt, zeichen:schlange
   - **Haremhab:** „Ich habe Namen aus Wänden schlagen lassen, als ich König war. Ich weiß, wie man einen Mann auslöscht.“
   - **Haremhab:** „Ich hole mir sein Buch. Und dann brennt es.“

*Dauer:* etwa 11 Sekunden.

## h08_vor: Die stumme Gruft

*Zweck:* Der Hüter ohne Stimme.

1. **Welt:** Kamera fährt zu dem Hüter
   - Aus der stummen Gruft steigt etwas, das ruft, ohne einen Laut.

*Dauer:* etwa 5 Sekunden.

## akt2_ende: Ende des zweiten Aktes: Zwei Jäger

*Zweck:* Ende von Akt 2: der eigene Ba (Rückbezug Wabe), zwei Jäger, vier Stunden.

1. **Bild `sz_akt2_gruft`**: a small falcon-like bird with a human face sitting alone in a dark stone crypt, a broken golden ring of the royal name hanging around it, its face shimmering and hard to see, turned towards the viewer
   - *ohne Bild:* zeichen:ba
   - In der stummen Gruft sitzt ein Ba ohne Gesicht. Als du die Laterne hebst, dreht er sich zum ersten Mal nach dir um.
   - Er hat dein Gesicht.
   - Er öffnet den Mund, und was herauskommt, ist deine Stimme.
   - Er öffnet den Mund. Es kommt nichts.
2. **Welt:** Kamera fährt zu deiner Figur
   - Haremhab ist fort. Im Sand vor der Gruft steht, mit der Schwertspitze geschrieben:
   - **Haremhab:** „Vier Stunden. Ich bin vor dir da.“
3. **Bild `sz_akt2_osten`**: a vast dark landscape seen from above, a faint glowing path leads to a distant eastern gate on the horizon, far ahead on the path a tiny shadowy figure carrying a jar, behind it a general in bronze armour running
   - *ohne Bild:* akt:2, zeichen:tor
   - Zwei gehen der Barke voraus. Einer will alle Namen behalten. Einer will sie alle verbrennen.
   - Und in beider Händen ist Nebet.
4. **Zwischentitel** „Ende des zweiten Aktes“ auf der Zierfläche

*Dauer:* etwa 42 Sekunden.

## h09_vor: Der zwölfte Ruderer

*Zweck:* Der zwölfte Ruderer.

1. **Welt:** Kamera fährt zu dem Hüter
   - Ein Licht mit einem Ruderer darin schlägt nach allem, was es ruft. Es war nur eine Nacht fort.

*Dauer:* etwa 7 Sekunden.

## h10_vor: Der am Grund

*Zweck:* Der am Grund (Rückbezug Namensscherbe).

1. **Welt:** Kamera fährt zu dem Hüter
   - Am Grund hält sich einer fest, mit beiden Händen, als wäre der Schlamm ein Thron.
   - Du kennst ihn. Er hat seinen Namen verkauft, und du hast ihn weiterverkauft.
   - Auf seiner Brust klebt ein Siegel, und darauf ist kein Name.

*Dauer:* etwa 17 Sekunden.

## h11_vor: Die Entronnene

*Zweck:* Die Entronnene.

1. **Welt:** Kamera fährt zu dem Hüter
   - Aus der Grube kriecht eine, die verurteilt war. Sie hat das Feuer mitgebracht.

*Dauer:* etwa 6 Sekunden.

## h12_vor: Das letzte Angebot

*Zweck:* Das letzte Angebot des Schattens.

1. **Bild `sz_h12_schatten`**: a tall faceless shadow in the shape of an old judge, made of darkness, cradling a small white alabaster jar with a blue thread in both hands, standing before a colossal eastern gate
   - *ohne Bild:* welt, zeichen:krug
   - Vor dem Tor des Ostens steht der Schatten. Er hat kein Gesicht mehr, nur Hände, und in den Händen einen Krug.
   - **Der Schatten des Sammlers:** „Bleib hier und trag die Krüge mit mir. Dann wird sie nie gewogen. Nie.“

*Dauer:* etwa 13 Sekunden.

## finale: Die Waage

*Zweck:* Am Tor des Ostens vor der Pforte: Waage, Licht aus, Antwort, Urteil, die Wahrheit über die Tochter, Nebet, Schlussbild. Varianten nach Herz und Entscheidungen (6, 8, 11, 4, 1).

1. **Bild `sz_finale_waage`** (ohne Bild: Akttafel 2, sonst Zeichen Waage): die Halle, ein leerer Platz unter den Zweiundvierzig.
   - Die Halle ist still. Zweiundvierzig Plätze, und einer ist leer.
   - **Thot:** „Leg dein Herz auf die Schale.“
   - Es ist in der Laterne. Es war die ganze Nacht dort.
2. **Bild `sz_finale_dunkel`** (Zeichen Laterne): das Herz aus der Laterne, das Licht geht aus.
   - Du öffnest das Glas und nimmst es heraus. Das Licht geht aus.
   - Es ist dunkel, und du bist noch da.
   - *eine von drei:* Wabe in der Gruft (8): „Thot ruft deinen Namen, und du antwortest. Mit deiner eigenen Stimme.“ · sonst Nebet blieb (6): „… Da sagt etwas Kleines auf deiner Schulter: ‚Hier.‘“ · sonst: „… Da sagt hinten in der Halle eine Frau aus Sandtor deinen Namen noch einmal, als hätte sie Angst, er sei falsch geschrieben.“
3. **Das Urteil** nach dem Herzen, eine von drei:
   - *Wahr an Stimme* · Bild `sz_finale_leicht` (Akttafel 3 / Waage), weiße Blende: „Die Schalen schwanken. Dann stehen sie still, beide gleich hoch.“ **Thot:** „Wahr an Stimme.“ Und leiser: „Wie lange du das getragen hast.“
   - *Zu schwer* · Bild `sz_finale_schwer` (Waage), roter Stich, Beben: „Die Schale sinkt. Am Fuß der Waage hebt die Fresserin den Kopf.“ **Thot** legt die Hand auf die Schale: „Noch nicht.“
   - *In der Schwebe* · Bild `sz_finale_schwebe` (Feder): „Die Waage findet keine Seite. Thot legt die Binse weg und sieht dich lange an.“ **Thot:** „Es fehlt ein Fährmann.“
4. **Bild `sz_finale_schatten`** (Krug): Thot und der Schatten.
   - Thot wendet sich an den Schatten vor dem Tor.
   - **Thot:** „Du hast nicht bis zum Ende hingesehen. Deine Tochter wurde nicht gefressen. Ich habe ‚Noch nicht‘ geschrieben, und sie ging mit einer Laterne in die nächste Nacht.“
   - *Buch gerettet (11):* Thot schlägt das Verzeichnis auf und liest, Name um Name, ganz Sandtor. Der Schatten stellt den Krug ab und nimmt eine Laterne. · *Buch verbrannt:* Das Verzeichnis ist Asche. Da tritt Chaemwese aus dem Dunkel und liest von seiner roten Liste, Name um Name, ganz Sandtor. Ein Schreiber vergisst nichts.
5. **Bild `sz_finale_morgen`** (Akttafel 3 / Titelbild / Sonne), weiße Blende, Musik des Titels: Morgen über Sandtor.
   - *Nebet heimgeschickt (6):* In Sandtor geht die Sonne auf. Im Fieberhaus setzt sich ein Mädchen mit blauen Fingern auf und fragt nach dir.
   - *Nebet blieb:* **Nebet:** „Jetzt muss ich. Ich bin schneller als die Sonne. Wetten?“ Sie fliegt mit dem ersten Licht nach Westen, sechs Stunden in einem Atemzug.
   - *Schlussbild:* Wahr an Stimme: der Stern im Norden (Sternenherz zurück, 4) oder Merits Sichel in Wernes · Schwebe: das Ruder aus Zedernholz (oder Treibholz, wenn es verbrannt wurde, 1) · Zu schwer: „Du gehst in die nächste Nacht, mit einer Laterne, die ohne Öl brennt.“
6. **Zwischentitel** „Ende“.

Danach fragt die Pforte wie bisher, mit dem Urteil als Text (`Geschichte.urteil(12)`).

*Dauer:* etwa 75 Sekunden.

---

Alle Sequenzen zusammen (jede Fassung einmal): etwa 9 Minuten.
