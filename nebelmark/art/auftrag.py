#!/usr/bin/env python3
"""Erzeugt den Produktionsauftrag fuer den Claude-Chat (auftrag.html) und die
Zuordnungsliste (auftrag.json), mit der die fertigen Bilder spaeter aus dem
Higgsfield-Verlauf abgeholt werden.  Aufruf:  python3 auftrag.py
"""
import json, html, pathlib

HERE = pathlib.Path(__file__).parent

STYLE = ("Realistic, highly detailed pre-rendered game asset for a dark-fantasy isometric action RPG, in the manner of classic "
         "pre-rendered isometric sprites: lifelike proportions and anatomy, believable skin, cloth, leather, wood and metal with wear "
         "and dirt, gritty and grounded. Not a cartoon, not low-poly, no outlines, no cel shading. Lighting: cool blue moonlight from "
         "the upper left and a faint warm lantern glow from the lower right, soft realistic shading. Camera: orthographic isometric "
         "three-quarter view from above, about 35 degrees elevation, the same camera for every object.")
BG = ("Background: fully transparent. No ground plane, no floor, no cast shadows, no text, no letters, "
      "no numbers, no labels, no frames, no grid lines.")
BG_MAGENTA = ("Background: one single flat uniform pure magenta color #FF00FF filling the whole image, no gradient. "
              "No ground plane, no floor, no cast shadows, no text, no letters, no numbers, no labels, no frames, "
              "no grid lines.")

def hero(who, attack):
    return (f"{STYLE} Subject: {who}. Layout: exactly 4 views of the SAME character in a clean 2 by 2 grid, each view "
            "centered in its own equal cell with wide empty space around it, nothing touches another cell or the image "
            "border, full body from head to feet, identical size, outfit and colors in all four views. "
            "Top-left: standing idle, body and face turned toward the lower-right corner of the image (front three-quarter view). "
            "Top-right: standing idle, turned toward the upper-right corner of the image, seen from behind (back three-quarter view). "
            f"Bottom-left: walking mid-stride toward the lower right. Bottom-right: {attack}, directed toward the lower right. {BG}")

def foe(who, attack):
    return (f"{STYLE} Subject: {who}. Layout: exactly 4 views of the SAME creature in a clean 2 by 2 grid, each view "
            "centered in its own equal cell with wide empty space around it, nothing touches another cell or the image "
            "border, whole body visible, identical size and colors in all four views. "
            "Top-left: standing idle, turned toward the lower-right corner of the image (front three-quarter view). "
            "Top-right: standing idle, turned toward the upper-right corner of the image, seen from behind (back three-quarter view). "
            f"Bottom-left: {attack}, directed toward the lower right. Bottom-right: defeated, lying collapsed and motionless. {BG}")

def grid(what, cols, rows, items, extra=""):
    lst = "; ".join(f"{i + 1}) {t}" for i, t in enumerate(items))
    return (f"{STYLE} Sheet of exactly {len(items)} separate {what} in a clean {cols} by {rows} grid ({cols} columns, {rows} rows), "
            "read left to right, top to bottom. Each one is centered in its own equal cell with wide empty space around it, "
            f"nothing touches another cell or the image border. {extra}Contents: {lst}. {BG}")

def bust(who):
    return ("Photorealistic cinematic character portrait for a dark-fantasy action RPG. The person looks like a real human being: natural skin "
            "with pores and small flaws, real hair, believable worn clothing and armor, shallow depth of field. Lighting: cool blue moonlight from the upper left and a warm lantern glow from the lower right. "
            f"Head-and-shoulders portrait of {who}, an adult, turned slightly to the side, calm determined expression. "
            "Background: dark indigo night sky over desert dunes, softly blurred, a few stars. No text, no letters, no frame.")

def tex(what):
    return ("Photorealistic seamless tileable ground texture for an isometric game, photographed straight from above (top-down, orthographic), "
            f"flat even moonlit lighting without any directional shadows: {what}. Natural realistic detail, muted night colors. "
            "The pattern continues evenly to all four edges so the image can be tiled, no objects, no horizon, no border, no vignette, no text.")

A = []  # (code, deutscher Name, Format, transparent?, Prompt)
def add(code, name, ratio, transparent, prompt): A.append(dict(code=code, name=name, ratio=ratio, transparent=transparent, prompt=prompt))

# ---------- Texturen für Mauern und Böden (nahtlos, frontal oder von oben) ----------
def wall(what):
    return ("Photorealistic seamless tileable wall texture, photographed straight from the front (orthographic, no perspective, no vanishing lines), "
            f"flat even dim lighting without directional shadows: {what}. Natural realistic detail, muted dark colors. The pattern continues evenly "
            "to all four edges so the image can be tiled, no floor, no ceiling, no objects, no border, no vignette, no text.")
add("W01", "Mauer: Burgmauer aus Sandstein", "1:1", False, wall("a medieval castle wall of large rough-hewn sandstone blocks in even horizontal courses, dark mortar joints, chipped edges, soot and weathering"))
add("W02", "Mauer: Gruft aus dunklem Stein", "1:1", False, wall("an ancient crypt wall of dark grey granite blocks with faint carved spiral signs, moss in the joints, damp stains"))
add("W03", "Mauer: verputztes Mauerwerk", "1:1", False, wall("old lime plaster on a stone wall, plaster partly broken off showing bricks beneath, cracks, faded ochre and grey"))
add("W04", "Mauer: Glasstadt", "1:1", False, wall("a wall of fused dark glass blocks with thin glowing teal veins between them, ancient and alien"))
add("T06", "Boden: Kopfsteinpflaster", "1:1", False, tex("old medieval cobblestone pavement with sand and dirt between the stones"))
add("T07", "Boden: Gruftplatten", "1:1", False, tex("large worn grey flagstones of a crypt floor with cracks, dust and a few bone fragments"))
add("T08", "Boden: Holzdielen", "1:1", False, tex("old dark wooden floor planks of a medieval hall, worn and scratched"))
add("T09", "Boden: Wüstensand mit Steinen", "1:1", False, tex("desert sand at night with small scattered pebbles and dry grass tufts, wind ripples, blue-grey and pale beige"))

# ---------- Ältere Aufträge (Akte Nebelmark). Sie bleiben in der Liste, damit fertige Bilder noch zugeordnet werden können. ----------
add("K01", "Eidträger (alt)", "1:1", True, hero(
    "an oath-knight of a medieval order of investigators: a realistic adult human, a broad-shouldered man around fifty with a short grey beard and a weathered face, worn steel plate armor under a hooded dark-blue tabard with a small embroidered open-eye sigil, a huge two-handed greatsword",
    "swinging the two-handed greatsword in a wide horizontal slash"))
add("G01", "Schuppenläufer (alt)", "1:1", True, foe(
    "a snake-folk warrior: a humanoid with a cobra-like hooded serpent head, sand-yellow and ochre scales, lean muscular body, clawed feet and a long tail, bone and glass jewelry, tattered cloth wraps around the waist, wielding a spear tipped with a teal glass shard",
    "lunging forward with the spear"))

# ================= Herz und Feder: die ägyptische Unterwelt (Duat) =================
EGY = "Ancient Egyptian underworld (the Duat) at night. "

# ---------- Paket 1: Klassen und Porträts ----------
add("K11", "Eidträger (Klasse)", "1:1", True, hero(EGY +
    "an oath-bearer sworn to Ma'at, goddess of truth: a realistic adult man around fifty with a short grey beard and a weathered sun-darkened face, bronze scale armor over a white linen kilt, a dark-blue linen tabard with a small embroidered Eye of Horus, a single white ostrich feather fixed at his shoulder, a huge two-handed bronze greatsword, a small brass temple lantern with a warm golden flame hanging at his belt",
    "swinging the two-handed greatsword in a wide horizontal slash"))
add("K12", "Priester des Schu (Klasse)", "1:1", True, hero(EGY +
    "a priest of Shu, god of air and breath: a realistic adult man, lean and barefoot, shaved head, a short dark beard, a white pleated linen kilt and a broad sash of pale sky-blue, a single ostrich feather in a narrow headband, linen-bandaged fists and forearms, faience bead collar",
    "throwing a straight palm strike from a low stance while a faint gust of air swirls around the hand"))
add("K13", "Wüstenjägerin (Klasse)", "1:1", True, hero(EGY +
    "a huntress devoted to the goddess Neith: a realistic adult woman, athletic, dark braided hair with small bronze beads, sand-colored linen tunic under a leather cuirass, a recurved composite bow of horn and wood, a quiver on the back, a leather bracer stamped with two crossed arrows, a fennec fox at her feet",
    "drawing the composite bow at full draw and aiming"))
add("K14", "Sternleserin (Klasse)", "1:1", True, hero(EGY +
    "a star-reader scribe of the goddess Seshat: a realistic adult woman with dark skin and silver-white hair tied up, a leopard-skin cloak over a long indigo linen robe embroidered with small gold stars, a scribe's palette at her belt, a tall staff topped with a seven-pointed golden star",
    "thrusting the star staff forward while its tip flares with white starlight"))
add("F11", "Porträt Eidträger", "3:4", False, bust("an oath-bearer of Ma'at: a broad-shouldered man around fifty with a short grey beard and sun-darkened skin, bronze scale armor, dark-blue linen tabard with a small embroidered Eye of Horus, a white ostrich feather at the shoulder"))
add("F12", "Porträt Priester des Schu", "3:4", False, bust("a priest of Shu: a lean man with a shaved head and a short dark beard, white pleated linen, a sky-blue sash, an ostrich feather in a narrow headband, a faience bead collar"))
add("F13", "Porträt Wüstenjägerin", "3:4", False, bust("a huntress of Neith: a woman with dark braided hair with bronze beads, sand-colored linen and leather, a composite bow behind her shoulder, a fennec fox peeking over her shoulder"))
add("F14", "Porträt Sternleserin", "3:4", False, bust("a star-reader scribe of Seshat: a woman with dark skin and silver-white hair tied up, a leopard-skin cloak over indigo linen with gold stars, a small seven-pointed golden star hanging from her headband"))

# ---------- Paket 2: Gegner ----------
add("G12", "Sebau-Priesterin", "1:1", True, foe(EGY +
    "a priestess of the brood of the chaos serpent Apophis: a slender humanoid with a cobra head and a flared hood, pale bone-white and black scales, a long robe of dark linen with bronze serpent jewelry, holding a bronze staff ending in a coiled snake",
    "spitting a jet of green venom from the serpent staff"))
add("G13", "Erloschener (gefallener Stern)", "1:1", True, foe(EGY +
    "an extinguished star, one of the imperishable stars that once towed the sun god's night barque: a tall gaunt humanoid made of dark meteoric iron, its body cracked with faint dying white starlight, an empty glowing hole in its chest where the heart was taken, tattered star-patterned linen around the hips",
    "hurling a shard of cold white starlight forward"))
add("G14", "Herzloser (Toter ohne Herz)", "1:1", True, foe(EGY +
    "a heartless dead man: a mummified corpse in loose torn linen wrappings, an open dark hole in its chest where the heart was taken, a faint violet glow inside the hole, gilded remnants of a funeral collar, long cracked fingernails",
    "lunging forward and raking with both hands"))
add("G15", "Ruheloser (Grabwächter)", "1:1", True, foe(EGY +
    "a restless dead tomb guard whose soul cannot find its way back: a mummified warrior in corroded bronze scale armor and a striped linen headcloth, empty eye sockets glowing pale teal, a curved bronze khopesh sword and a cowhide shield",
    "slashing with the khopesh"))
add("G17", "Kleine Gegner der Duat", "3:2", True, grid("small hostile creatures of the Egyptian underworld, each turned toward the lower right", 3, 2, [
    "a wandering ba soul: a small bird with a human face, made of pale teal light, trailing light",
    "a giant black scorpion with a bronze-tinted stinger, one of the brood of Tefen",
    "a horned desert viper coiled and ready to strike",
    "a gaunt black jackal with glowing pale eyes",
    "a carrion vulture with spread wings",
    "a crawling swarm of dark scarab beetles"], "Every creature is shown whole. "))
add("G18", "Begleiter: Wüstenfuchs", "1:1", True, foe(EGY +
    "a fennec desert fox companion with very large ears and sand-colored fur, wearing a thin collar of blue faience beads",
    "leaping forward to bite"))

# ---------- Paket 3: Hüter der Stunden ----------
add("B11", "Mahaf, der Fährmann (Hüter)", "1:1", True, foe(EGY +
    "Mahaf, the ferryman of the dead: a tall spectral boatman whose head is turned backward over his shoulder, gaunt and wrapped in grey linen, holding a long steering oar, standing in a small papyrus-reed skiff that floats above the sand, surrounded by drifting pale teal soul-lights",
    "sweeping the steering oar in a wide arc"))
add("B13", "Der König ohne Namen (Hüter)", "1:1", True, foe(EGY +
    "the king without a name: an undead pharaoh twice as tall as a man, dried regal body in gilded scale armor, a blue-and-gold royal headcloth, a royal cartouche on his chest chiselled out and blank, eye sockets burning with pale teal fire, holding a two-handed sword of pure shining gold",
    "swinging the golden sword overhead"))
add("B14", "Der Stumme Türhüter (Hüter)", "1:1", True, foe(EGY +
    "the mute doorkeeper of a gate of the underworld: a towering figure in a stiff white linen robe, its face a smooth blank stone mask without a mouth, a huge serpent coiled around its shoulders, a heavy bronze door-plate on its chest, two long curved knives in its hands",
    "crossing both knives in a scissor strike"))
add("B15", "Der Sammler (Hüter)", "1:1", True, foe(EGY +
    "the Collector, once one of the forty-two judges of the dead: a towering gaunt figure in the white linen of a judge with an ostrich feather on his head, his face hidden behind a cracked gold mask, six thin arms each carrying a canopic jar with a glowing red heart inside",
    "reaching forward with all six arms"))

# ---------- Paket 4: Welt der Duat ----------
add("P11", "Tor des Westens", "16:9", True, grid("environment props of the ancient Egyptian underworld", 4, 2, [
    "a tall stone false door, the doorway through which the dead pass between worlds", "a small papyrus-reed skiff lying on the sand",
    "an obelisk carved with hieroglyph-like signs", "a weathered stone stela with a carved winged sun disk",
    "a toppled sphinx statue missing its head", "a stone offering table with clay bowls",
    "a bundle of dry papyrus reeds", "a wooden ferry landing post with a rope"], "All props share one consistent scale. "))
add("P12", "Halle der Waage", "16:9", True, grid("environment props of the hall of judgement in the ancient Egyptian underworld", 4, 2, [
    "the great bronze scales of judgement with one empty pan and one ostrich feather in the other", "a statue of Ammit the devourer: crocodile head, lion body, hippopotamus hindquarters",
    "a standing statue of the jackal-headed god Anubis", "a statue of the ibis-headed god Thoth holding a scribe's palette",
    "a burning bronze brazier on a tall stand", "a seated statue of one of the judges of the dead",
    "a column carved with hieroglyph-like signs and a papyrus capital", "a white ostrich feather on a small gold pedestal"], "All props share one consistent scale. "))
add("P13", "Gräber", "16:9", True, grid("environment props of an ancient Egyptian tomb", 4, 2, [
    "a closed granite sarcophagus", "an open sarcophagus with the lid pushed aside",
    "a set of four canopic jars with animal-head lids", "a group of small blue faience shabti figures",
    "an upright gilded mummy case", "a wooden chest painted with the Eye of Horus",
    "a pile of fallen funeral offerings: jars, baskets and bread", "a pile of skulls and bones"], "All props share one consistent scale. "))
add("P14", "Höhle des Sokar", "16:9", True, grid("environment props of the cavern of the god Sokar in the ancient Egyptian underworld", 4, 2, [
    "a tall stack of sealed clay jars, each with a faint red heartbeat glow inside", "the sun god's night barque stranded on dry sand, its prow shaped like a lotus",
    "a thick coiled tow rope lying on the sand", "a falcon-headed statue of the god Sokar",
    "a shattered clay jar with a glowing red heart lying in the shards", "a pile of dark meteoric iron fragments faintly glowing white",
    "a broken bronze lamp stand", "a rock pillar with a carved serpent winding around it"], "All props share one consistent scale. "))
add("W11", "Mauer: Sandstein mit Reliefs", "1:1", False, wall("an ancient Egyptian temple wall of sandstone blocks covered with shallow carved hieroglyph-like reliefs and figures in profile, faint traces of old ochre and blue paint, weathered, no readable words"))
add("W12", "Mauer: bemalte Grabwand", "1:1", False, wall("an ancient Egyptian tomb wall painted with faded scenes of a night journey: a boat with figures, stars and serpents in ochre, red and blue on plaster, cracked and partly flaked off, no readable words"))
add("T11", "Boden: Basaltplatten", "1:1", False, tex("polished black basalt slabs of an ancient Egyptian temple floor, thin inlaid lines of tarnished gold, dust in the joints"))
add("T12", "Boden: Felder von Wernes", "1:1", False, tex("dry cracked field soil with stubble of cut barley and reeds, scattered husks, pale dusty brown"))

# ---------- Paket 5: Symbole für Gegenstände ----------
add("I11", "Symbole: Waffen", "1:1", True, grid("game item icons of ancient Egyptian weapons", 4, 4, [
    "a bronze khopesh sickle-sword", "a bronze battle axe with a half-moon blade", "a recurved composite bow of horn and wood", "a was-sceptre staff with a canine head and forked foot",
    "linen hand wraps", "a knapped flint knife with a wooden handle", "a pear-shaped stone mace head on a wooden shaft", "a bronze harpoon",
    "the golden harpoon of the god Horus, glowing", "a two-handed sword of shining gold with a sun disk on the crossguard", "a bronze spear", "a curved wooden throwing stick",
    "a staff topped with an ankh", "a leather quiver with arrows", "a dagger with a gold handle and lapis inlay", "a bronze war sickle"],
    "Each item is shown alone, tilted diagonally, large in its cell. "))
add("I12", "Symbole: Nebenhand und Kopf", "1:1", True, grid("game item icons of ancient Egyptian equipment", 4, 4, [
    "a bronze temple oil lamp with a warm flame", "a cowhide shield with a rounded top", "a polished bronze hand mirror with a Hathor-head handle", "a bronze sistrum rattle",
    "a scribe's palette with reed pens", "an incense burner shaped like an arm and hand", "a blue-and-gold striped royal nemes headcloth", "the blue war crown of a pharaoh",
    "a golden vulture headdress", "a golden funeral mask", "a plain linen cap", "a gold headband with a rearing cobra",
    "a lamp of truth with a white feather etched on it, glowing", "a lioness-head hood of the goddess Sekhmet", "a black jackal mask of Anubis", "a polished bronze mirror glowing softly"],
    "Each item is shown alone, large in its cell. "))
add("I13", "Symbole: Rüstung, Hände, Füße", "1:1", True, grid("game item icons of ancient Egyptian clothing and armor", 4, 4, [
    "a white pleated linen kilt", "a long white priest's robe", "a leopard skin cloak", "a leather cuirass",
    "a bronze scale armor shirt", "a broad gold pectoral collar with inlaid stones", "linen hand bandages", "a leather archer's glove",
    "bronze-plated fist guards", "a pair of gold arm cuffs", "papyrus sandals", "leather sandals",
    "soft leather travel shoes", "bronze shin guards", "a serpent-skin cloak with golden scales", "a priest's leopard skin with gold stars"],
    "Each item is shown alone, large in its cell. "))
add("I14", "Symbole: Schmuck", "1:1", True, grid("game item icons of ancient Egyptian amulets and rings", 4, 4, [
    "an Eye of Horus amulet of blue faience", "a golden ankh amulet", "a djed pillar amulet", "a red jasper knot amulet of Isis",
    "a green stone heart scarab", "a golden shen ring amulet", "a blue faience ring", "a golden signet ring",
    "a ring with an engraved cartouche", "a ring with a carved scarab", "a ring with a rearing cobra", "a gold shen ring with a lapis stone",
    "a single white ostrich feather of truth, glowing softly", "a dark meteoric iron splinter, faintly glowing", "a bone ring with a crocodile head", "a ring of black glass holding a tiny red heart"],
    "Each item is shown alone, large in its cell. "))
add("I15", "Symbole: Tränke und Material", "1:1", True, grid("game item icons for an ancient Egyptian setting", 4, 4, [
    "a clay jug of red beer with a stopper", "a small bowl of turquoise faience powder", "a rolled shed snake skin", "an iron ingot",
    "a lump of dark meteoric iron glowing white at its cracks", "a pile of broken clay jar shards", "a torn page of papyrus covered with hieroglyph-like signs", "a red glowing orb of healing light",
    "a canopic jar with a jackal-head lid", "a glowing red heart", "a white ostrich feather", "small golden scales of judgement",
    "a pile of gold rings used as money", "a bronze key", "a burning torch", "a leather pouch"],
    "Each item is shown alone, large in its cell. "))

# ---------- Paket 6: Titel und Bilder für die Stunden-Tafeln ----------
add("X11", "Titelbild", "16:9", False,
    "Photorealistic cinematic landscape for a dark-fantasy action RPG, like a film still, natural detail, atmospheric haze. "
    "Wide establishing shot of the entrance to the ancient Egyptian underworld at night: a huge stone gateway in a cliff at the western edge of the desert, "
    "pale teal soul-lights drifting toward it over the dunes, a single warm lantern glow far away on the sand, in the dark sky above the gate the faint shape of great bronze scales among the stars. "
    "Quiet, sacred, ominous mood. No characters in the foreground, no text, no letters, no logo, no frame.")
def chapter(scene):
    return ("Photorealistic cinematic landscape for a dark-fantasy action RPG, like a film still, natural detail, atmospheric haze, dark and moody, "
            f"lit only by cold moonlight and a few warm flames. Wide establishing shot of {scene}. No characters in the foreground, no text, no letters, no logo, no frame.")
add("X12", "Tafel: Das Tor des Westens", "16:9", False, chapter("a desert gate of the dead at night: a crumbling stone false door, a small papyrus skiff on the sand, pale teal lights drifting against the wind"))
add("X13", "Tafel: Die Felder von Wernes", "16:9", False, chapter("abandoned fields of the blessed dead in the underworld: rows of cut barley, irrigation channels gone dry, huge shed snake skins lying across the fields"))
add("X14", "Tafel: Der König ohne Namen", "16:9", False, chapter("a royal tomb hall beside dark underworld water: painted columns, a sarcophagus in the center, every royal cartouche on the walls hacked out and blank"))
add("X15", "Tafel: Rosetau", "16:9", False, chapter("the sandy land of the god Sokar in the underworld: a narrow path through sand between stone walls, extinguished fallen stars lying like dark iron statues along the way"))
add("X16", "Tafel: Die Höhle des Sokar", "16:9", False, chapter("a vast cavern filled with thousands of sealed clay jars, each faintly glowing red, and in their middle the golden night barque of the sun god stranded on dry sand"))

PACKS = [
    ("Paket 1 · Klassen (zuerst)", "Die vier Klassen im ägyptischen Aussehen, je vier Ansichten, dazu die Porträts für die Klassenwahl.", ["K11", "K12", "K13", "K14", "F11", "F12", "F13", "F14"]),
    ("Paket 2 · Gegner", "Sebau-Priesterin, Erloschener, Herzloser, Ruheloser, die kleinen Wesen der Duat und der Wüstenfuchs als Begleiter.", ["G12", "G13", "G14", "G15", "G17", "G18"]),
    ("Paket 3 · Hüter der Stunden", "Mahaf der Fährmann, der König ohne Namen, der Stumme Türhüter und der Sammler.", ["B11", "B13", "B14", "B15"]),
    ("Paket 4 · Welt der Duat", "Tor des Westens, Halle der Waage, Gräber, Höhle des Sokar, dazu zwei Mauern und zwei Böden.", ["P11", "P12", "P13", "P14", "W11", "W12", "T11", "T12"]),
    ("Paket 5 · Symbole", "Waffen, Kopf und Nebenhand, Rüstung, Schmuck, Tränke und Material mit den neuen Namen.", ["I11", "I12", "I13", "I14", "I15"]),
    ("Paket 6 · Titel und Stunden-Tafeln", "Ein neues Titelbild und je ein Bild für die Tafeln der ersten fünf Stunden.", ["X11", "X12", "X13", "X14", "X15", "X16"]),
]

HEAD = """Du bist die Bildproduktion für mein Spielprojekt „Herz und Feder“, ein Action-Rollenspiel in der ägyptischen Unterwelt. Erzeuge mit dem Higgsfield-Konnektor genau die unten aufgeführten Bilder.

Regeln:
1. Nutze generate_image_batch, höchstens 12 Bilder pro Aufruf, je Bild ein Eintrag.
2. Einstellungen für jedes Bild: model "gpt_image_2_6", quality "medium", resolution "2k", use_unlim true, dazu das angegebene aspect_ratio. Steht bei einem Bild „transparent“, setze zusätzlich background "transparent".
3. Gib niemals Credits aus. Wird „unbegrenzt“ abgelehnt, brich ab und sag mir den genauen Wortlaut der Meldung.
4. Übernimm jeden Prompt wörtlich und vollständig. Nicht kürzen, nicht umformulieren, nicht übersetzen, nichts ergänzen.
5. Lehnt gpt_image_2_6 diese Einstellungen ab, nimm stattdessen model "nano_banana_pro" mit resolution "2k" (ohne quality und ohne background) und ersetze in den als transparent markierten Prompts den Satz, der mit „Background: fully transparent.“ beginnt, bis zum Ende des Prompts durch: """ + BG_MAGENTA + """
6. Warte mit jobs_wait, bis alle fertig sind. Wiederhole fehlgeschlagene Bilder genau einmal.
7. Zeig mir am Ende eine Tabelle: Kürzel, Status und die vollständige Bild-Adresse (result_url, beginnt mit https://). Die Bilder selbst musst du nicht beschreiben.
"""

def vclip(code, who, act):
    return (f"{code}\nPrompt: A single {who}, shown exactly once, alone, full body, centered, realistic, highly detailed, seen from a high orthographic isometric camera "
            f"angle from above (about 35 degrees), facing the lower-right corner of the frame. {act} The figure stays in the exact center of the frame the whole time. "
            "The camera is completely locked: no pan, no zoom, no cut. Background: one flat uniform bright green color #00FF00 everywhere, no ground, no floor, no shadow, no dust, no text.\n")
WHO = {"E": "oath-bearer of Ma'at around fifty with a short grey beard, bronze scale armor over a white linen kilt, a dark-blue tabard with an Eye of Horus, a huge two-handed bronze greatsword",
       "M": "lean barefoot priest of the Egyptian air god Shu with a shaved head and short dark beard, white pleated linen kilt, sky-blue sash, an ostrich feather in a headband, bandaged fists",
       "W": "athletic Egyptian huntress with dark braided hair with bronze beads, sand-colored linen and a leather cuirass, a recurved composite bow",
       "S": "star-reader scribe woman with dark skin and silver-white hair tied up, leopard-skin cloak over an indigo robe with gold stars, a staff topped with a seven-pointed golden star"}
WALK = "walks in place on the spot in a steady, even, natural looping walk cycle, arms swinging naturally."
ATK = {"E": "swings the greatsword in one wide horizontal slash, returns to the ready stance, and repeats once.", "M": "throws a quick combination of three palm strikes, returns to stance, and repeats once.",
       "W": "draws the composite bow, aims, releases an arrow, nocks the next arrow and repeats once.", "S": "raises the star staff and thrusts it forward as light flares at its tip, returns to stance, and repeats once."}
NAMES = dict(zip("EMWS", ["Eidträger", "Priester des Schu", "Wüstenjägerin", "Sternleserin"]))
VITEMS = "".join(f"<li><span class='code'>V{c}{k}</span>{NAMES[c]} · {'Laufen' if k == 1 else 'Angriff'}</li>" for c in "EMWS" for k in (1, 2))
VIDEO = """Du bist die Bildproduktion für mein Spielprojekt „Herz und Feder“, ein Action-Rollenspiel in der ägyptischen Unterwelt. Erzeuge mit dem Higgsfield-Konnektor kurze Bewegungsvideos für die Spielfiguren.

Regeln:
1. Nutze generate_video_batch, je Video ein Eintrag. Einstellungen für jedes: model "seedance_2_5", mode "t2v", duration 5, resolution "720p", aspect_ratio "1:1", generate_audio false, use_unlim true.
2. Gib niemals Credits aus. Wird „unbegrenzt“ abgelehnt, brich ab und sag mir den genauen Wortlaut der Meldung.
3. Übernimm jeden Prompt wörtlich.
4. Warte mit jobs_wait, bis alle fertig sind. Wiederhole fehlgeschlagene genau einmal.
5. Zeig mir am Ende eine Tabelle: Kürzel, Status und die vollständige Video-Adresse (result_url, beginnt mit https://).

""" + "\n".join(vclip(f"V{c}1 · Laufen", WHO[c], WALK) + "\n" + vclip(f"V{c}2 · Angriff", WHO[c], ATK[c]) for c in "EMWS")

by = {a["code"]: a for a in A}
assert len(by) == len(A)
def pack_text(codes):
    out = [HEAD, f"Bilder ({len(codes)} Stück):", ""]
    for c in codes:
        a = by[c]
        out += [f"{c} · {a['name']} · aspect_ratio {a['ratio']}" + (" · transparent" if a["transparent"] else ""), "Prompt: " + a["prompt"], ""]
    return "\n".join(out)

used = [c for _, _, cs in PACKS for c in cs]
assert set(used) <= set(by), set(used) - set(by)   # was schon im Spiel ist, steht in keinem Paket mehr

# Zuordnungsliste: ein Stueck aus dem Motivteil jedes Prompts, das nur dort vorkommt
def key_of(p):
    for mark in ("Subject: ", "Contents: 1) ", "portrait of ", "shadows: ", "Wide establishing shot of "):
        if mark in p: return (mark + p.split(mark, 1)[1])[:70]
    raise ValueError(p[:80])
for a in A: a["key"] = key_of(a["prompt"])
keys = [a["key"] for a in A]
import collections; print([k for k, n in collections.Counter(keys).items() if n > 1]); assert len(set(keys)) == len(keys)
for a in A:
    assert sum(a["key"] in b["prompt"] for b in A) == 1, a["code"]
(HERE / "auftrag.json").write_text(json.dumps({"assets": A, "video_key": "walks in place on the spot|swings the greatsword"}, ensure_ascii=False, indent=1), encoding="utf-8")

cards = []
for i, (title, note, codes) in enumerate(PACKS):
    items = "".join(f"<li><span class='code'>{c}</span>{html.escape(by[c]['name'])}</li>" for c in codes)
    cards.append(f"""<section class="pack"><div class="pack-head"><div><h2>{html.escape(title)}</h2><p>{html.escape(note)}</p></div>
<button class="copy" type="button" id="copy{i}" data-src="txt{i}">Auftrag kopieren</button></div>
<ul class="items">{items}</ul>
<details><summary>Text ansehen</summary><textarea id="txt{i}" readonly rows="10">{html.escape(pack_text(codes))}</textarea></details></section>""")
n = len(PACKS)
cards.append(f"""<section class="pack"><div class="pack-head"><div><h2>Paket B · Bewegung</h2><p>Acht kurze Videos: alle vier Klassen im neuen Aussehen beim Laufen und Angreifen. Daraus schneide ich Bewegungsbilder für die Webfassung.</p></div>
<button class="copy" type="button" id="copy{n}" data-src="txt{n}">Auftrag kopieren</button></div>
<ul class="items">{VITEMS}</ul>
<details><summary>Text ansehen</summary><textarea id="txt{n}" readonly rows="10">{html.escape(VIDEO)}</textarea></details></section>""")

PAGE = """<title>Bildauftrag Herz und Feder</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,600&family=IBM+Plex+Sans:wght@400;600&family=IBM+Plex+Mono&display=swap">
<style>
/* Aufbau: schmale Lesespalte, oben drei Schritte, darunter je Paket ein Laufzettel mit Kopierknopf. */
:root { --bg:#eef0ec; --card:#fbfcfa; --ink:#1c2422; --dim:#55615d; --line:#cdd4cf; --glass:#0f7f7a; --on-glass:#ffffff; --seal:#9c3b2e;
  --display:"Fraunces", Georgia, serif; --body:"IBM Plex Sans", system-ui, sans-serif; --mono:"IBM Plex Mono", ui-monospace, monospace; }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { --bg:#10171a; --card:#172124; --ink:#e4ebe8; --dim:#98a8a3; --line:#2b3a3d; --glass:#3fc6bd; --on-glass:#06201f; --seal:#e0806f; color-scheme: dark } }
:root[data-theme="dark"] { --bg:#10171a; --card:#172124; --ink:#e4ebe8; --dim:#98a8a3; --line:#2b3a3d; --glass:#3fc6bd; --on-glass:#06201f; --seal:#e0806f; color-scheme: dark }
body { background:var(--bg); color:var(--ink); font-family:var(--body); font-size:16px; line-height:1.5; }
.wrap { max-width:46rem; margin:0 auto; padding-block:1.75rem 3rem; padding-left:max(16px, env(safe-area-inset-left, 0px)); padding-right:max(16px, env(safe-area-inset-right, 0px)); display:flex; flex-direction:column; gap:1.5rem; }
h1 { font-family:var(--display); font-size:clamp(1.7rem, 5vw, 2.3rem); line-height:1.15; margin:0; text-wrap:balance; }
.eyebrow { font-size:.78rem; letter-spacing:.09em; text-transform:uppercase; color:var(--seal); font-weight:600; margin:0 0 .35rem; }
.lead { margin:.6rem 0 0; color:var(--dim); max-width:38rem; }
ol.steps { margin:0; padding-left:1.3rem; display:flex; flex-direction:column; gap:.45rem; }
ol.steps b { font-weight:600; }
.note { border-left:3px solid var(--seal); padding:.15rem 0 .15rem .9rem; color:var(--dim); margin:0; }
.pack.done { opacity:.8; border-style:dashed; }
.pack { background:var(--card); border:1px solid var(--line); border-radius:6px; padding:1.1rem 1.15rem; display:flex; flex-direction:column; gap:.8rem; }
.pack-head { display:flex; gap:1rem; justify-content:space-between; align-items:flex-start; flex-wrap:wrap; }
.pack-head > div { min-width:0; flex:1 1 16rem; }
h2 { font-family:var(--display); font-size:1.2rem; margin:0 0 .2rem; }
.pack p { margin:0; color:var(--dim); font-size:.95rem; }
.copy { font:600 .95rem var(--body); background:var(--glass); color:var(--on-glass); border:0; border-radius:5px; padding:.7rem 1.1rem; min-height:44px; cursor:pointer; }
.copy:focus-visible, summary:focus-visible, textarea:focus-visible { outline:3px solid var(--seal); outline-offset:2px; }
.copy.done { background:var(--ink); color:var(--bg); }
ul.items { list-style:none; margin:0; padding:0; display:grid; grid-template-columns:repeat(auto-fill, minmax(13.5rem, 1fr)); gap:.2rem .9rem; font-size:.9rem; }
.code { font-family:var(--mono); font-size:.8rem; color:var(--glass); display:inline-block; width:2.7rem; }
summary { cursor:pointer; color:var(--dim); font-size:.9rem; }
textarea { width:100%; box-sizing:border-box; margin-top:.5rem; font:.78rem/1.45 var(--mono); background:var(--bg); color:var(--ink); border:1px solid var(--line); border-radius:4px; padding:.6rem; resize:vertical; }
</style>
<div class="wrap">
<header><p class="eyebrow">Herz und Feder · Bildproduktion</p><h1>Bildauftrag für den Claude-Chat</h1>
<p class="lead">__N__ realistische Bilder und acht Bewegungsvideos für die ägyptische Unterwelt: Klassen, Gegner, Hüter der Stunden, Welt, Symbole und Tafeln. Im Claude-Chat laufen sie über dein Ultra-Abo ohne Credits. Aus Claude Code heraus lehnt Higgsfield das ab.</p></header>
<ol class="steps">
<li>Öffne einen <b>neuen, normalen Chat</b> in Claude (nicht Code) und schalte dort den Higgsfield-Konnektor ein.</li>
<li>Tippe hier bei Paket 1 auf <b>Auftrag kopieren</b>, füge den Text in den Chat ein und schick ihn ab.</li>
<li>Wenn der Chat seine Tabelle mit den Adressen zeigt, kopier die ganze Tabelle hierher in unsere Sitzung. Ich lade die Bilder darüber, schneide sie zu und baue sie ein.</li>
<li>Danach die übrigen Pakete in ihrer Reihenfolge. Am wichtigsten sind 1 bis 3.</li>
</ol>
<p class="note">Dein unbegrenzter Zugang läuft laut Higgsfield bis zum 17. November. Die Verlängerung hast du abgestellt. Danach kosten Bilder wieder Credits. Schick die wichtigsten Pakete also vorher ab.</p>
<section class="pack done"><h2>Paket A · Texturen</h2><p>Sieben von acht fertig und geprüft (W01–W04, T06–T08). Es fehlt noch T09, der Wüstensand. Sie kommen jetzt ins 3D-Spiel. Schick mir die Adresse von T09, sobald sie da ist.</p></section>
__CARDS__
</div>
<script>
document.querySelectorAll(".copy").forEach(function (btn) {
  btn.addEventListener("click", function () {
    var box = document.getElementById(btn.dataset.src), label = btn.textContent;
    function ok() { btn.textContent = "Kopiert"; btn.classList.add("done"); setTimeout(function () { btn.textContent = label; btn.classList.remove("done"); }, 1800); }
    function fallback() { box.closest("details").open = true; box.focus(); box.select(); btn.textContent = "Text ist markiert, jetzt kopieren"; setTimeout(function () { btn.textContent = label; }, 4000); }
    try { navigator.clipboard.writeText(box.value).then(ok, fallback); } catch (e) { fallback(); }
  });
});
</script>
"""
(HERE / "auftrag.html").write_text(PAGE.replace("__N__", str(len(used))).replace("__CARDS__", "\n".join(cards)), encoding="utf-8")
print(len(A), "Bilder;", [(t, len(c), len(pack_text(c))) for t, _, c in PACKS])
