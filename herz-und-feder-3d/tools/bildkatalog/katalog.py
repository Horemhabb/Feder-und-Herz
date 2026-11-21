#!/usr/bin/env python3
"""Bildkataloge für generierte Grafiken (Fassung 4.0.6): Stilbibel + je Bild ein fertiger Prompt.
Schreibt KATALOG.md (zum Lesen) und katalog.json (zum Abarbeiten). Aufruf: python3 katalog.py"""
import json, os
HIER = os.path.dirname(os.path.abspath(__file__))

STIL = ("Ancient Egyptian painted-relief style game icon, single centered motif filling about 75% of the frame, bold clean silhouette "
        "that stays readable at 64 pixels, flat saturated tomb-painting colors (Egyptian blue, malachite green, ochre, carnelian red, "
        "ivory) with thin black outlines, small gold-leaf accents, subtle warm glow behind the motif, plain dark sandstone background, "
        "no text, no border, no frame, square")
FARBE = {"ermittler": "lapis blue", "moench": "turquoise", "jaegerin": "carnelian red", "forensiker": "amethyst violet", "basalt": "dark basalt", "": "gold"}

# (id, Klasse, Name, Wirkung, Motiv)
FAEHIG = [
 ("whirl","ermittler","Falkenkreis","Rundumschlag","a falcon of Horus circling in a spiral, wings spread wide, a red arc of sweeping wind around it"),
 ("dash","ermittler","Sturz des Falken","Sprung mit Aufprall","a falcon of Horus diving head-down with talons forward, motion streaks above, small impact burst below"),
 ("oath","ermittler","Eid der Maat","Schaden hoch, Schaden erlitten runter","the feather of Maat glowing upright above a raised open hand taking an oath, gold light"),
 ("udjat","ermittler","Blick des Udjat","Betäubt und löscht Geschosse","the Eye of Horus (udjat) opening, radiating a pulse ring of light"),
 ("beam","ermittler","Strahl des Re","Licht durchschlägt Gegner","a red sun disc of Re with long straight rays ending in small hands, beam shooting downward"),
 ("flurry","moench","Fäuste des Month","Fünf schnelle Schläge","two clenched fists in rapid motion with several ghost afterimages and ochre impact streaks, Month the war god"),
 ("step","moench","Schritt des Schu","Schritt durch Gegner","a long striding leg in sandals with wind streaks, small star at the footfall, god Schu"),
 ("mantra","moench","Kreis des Ka","Heil- und Schutzkreis","the raised ka arms (two upstretched arms) inside a glowing ring, a red heart in the center"),
 ("palm","moench","Gebs Lachen","Erdbeben, Getroffene zerbersten","cracked earth with a green god-of-earth ground splitting open, flying rock shards, Geb"),
 ("wave","moench","Atem des Schu","Atemstoß wirft zurück","a billowing sail catching a strong wind, curling turquoise breath streams, Schu the air god"),
 ("salve","jaegerin","Neiths Fächer","Fünf Pfeile im Fächer","five arrows fanned out from one point over the crossed-arrows-and-shield emblem of Neith"),
 ("roll","jaegerin","Sprung der Gazelle","Sprung aus der Gefahr","a gazelle in mid-leap over a dune, dust trail"),
 ("hetz","jaegerin","Upuauts Hatz","Fuchs springt an und beißt","a desert fox head in attack, snarling, ears forward, small slash marks, Wepwawet the wolf god"),
 ("rain","jaegerin","Sieben Pfeile der Sachmet","Pfeilregen auf Fläche","seven arrows falling from a lion-goddess sun sky onto a circle on the ground, Sachmet"),
 ("pierce","jaegerin","Pfeil der Neith","Pfeil durch die Reihe","a single long arrow piercing straight through three scarab beetles in a row"),
 ("chain","forensiker","Zorn des Seth","Gewitter springt von Gegner zu Gegner","the Seth animal head with a forked lightning bolt arcing between two small jars, storm-red"),
 ("blink","forensiker","Schritt durch die Duat","Kurzer Sprung","a five-pointed star inside a circle (Duat sign) with a swirling portal ring, figure fading"),
 ("glass","forensiker","Seschats Maß","Zeitfeld, Gegner kriechen","the palm-rib measuring staff of Seschat with a seven-petal star, a faint ring of slowed time around it"),
 ("nova","forensiker","Hu, das Machtwort","Ring betäubt lange","an open mouth speaking (god Hu, the spoken word) with concentric shock rings of light"),
 ("meteor","forensiker","Fallender Stern der Nut","Stern schlägt spät und hart ein","a star-covered arched sky goddess Nut body above, a blazing star falling from her with a fiery tail"),
 ("potion","","Rotbier der Sachmet","Heilt 60 % Leben","an ochre clay beer jar with red beer foaming over the rim, a small lion-goddess stamp"),
]
STAERKEN = [
 ("p_zaeh","Starker Ka","6 % mehr Leben","the ka sign: two upraised arms with an ankh between them"),
 ("p_scharf","Auge des Horus","Kritische Trefferchance","a sharp eye of Horus with a bright pupil and small star glints"),
 ("p_flink","Flügel des Ba","Lauftempo","a ba-bird (human-headed soul bird) in swift flight"),
 ("p_kraft","Fülle des Hapi","Kraft pro Sekunde","Nile flood waves with a lotus and overflowing water, Hapi"),
 ("p_hieb","Hand des Month","Schaden des Standardangriffs","a fist gripping a curved khopesh sword"),
 ("p_jaeger","Speer des Seth","Schaden gegen Elite und Hüter","a spear piercing a coiled serpent, Seth at the prow"),
]
SCHLUESSEL = [
 ("k_ermittler","ermittler","Wahr an Stimme","a golden scale of Maat balancing a heart against a feather"),
 ("k_moench","moench","Hauch des Schu","a single large ostrich feather in swirling breath"),
 ("k_jaegerin","jaegerin","Upuauts Rudel","a jackal standard on a pole with a fox pup beside it"),
 ("k_forensiker","forensiker","Wort des Thot","an ibis of Thot holding a scribe's palette and reed pen"),
]
AUGS = [
 ("a_wucht","Wucht","25 % mehr Wirkung","a small glowing ochre flame-star, plain, simple, leaf-sized badge motif"),
 ("a_eile","Eile","25 % schneller bereit","a small turquoise winged sandal or swift feather, plain, simple, leaf-sized badge motif"),
]
AESTE = {"ermittler":["Klinge","Licht","Eid"],"moench":["Faust","Atem","Ka"],"jaegerin":["Fächer","Neith","Sachmet"],"forensiker":["Gewitter","Sterne","Wort"]}
AST_MOTIV = {"Klinge":"a khopesh blade","Licht":"a sun disc with rays","Eid":"a feather of Maat","Faust":"a clenched fist","Atem":"a sail in wind","Ka":"two ka arms",
             "Fächer":"a fan of arrows","Neith":"crossed arrows over a shield","Sachmet":"a lioness head","Gewitter":"a lightning bolt","Sterne":"a five-pointed star","Wort":"a speaking mouth"}
GEGNER = [
 ("wisp","Irrender Ba","a wandering ba soul bird, translucent pale blue, eerie glow"),
 ("skorp","Tefens Brut","a desert scorpion with raised tail, ochre and black"),
 ("lance","Sebau-Krieger","a gaunt undead spear warrior in tattered bandages, bronze spear"),
 ("seer","Sebau-Priesterin","a hollow-eyed priestess in ritual wraps raising a glowing staff"),
 ("haut","Sebau-Koloss","a hulking stone-skinned giant with cracked body, small head, massive fists"),
 ("guard","Ruheloser","a restless mummy guardian in dark wraps with a rusty shield"),
 ("fahl","Erloschener","a pale ashen spirit whose inner light has gone out, dim ember eyes"),
 ("hohl","Herzloser","a hollow-chested figure with an empty gaping chest cavity, no heart, cold blue glow"),
 ("boss","Hüter der Stunde","a towering guardian of the gate with jackal head, golden collar, glowing eyes, menacing"),
]

def bild(i, gruppe, name, wirkung, motiv, farbe=""):
    zusatz = f" Accent color: {farbe}." if farbe else ""
    return {"id": i, "gruppe": gruppe, "name": name, "wirkung": wirkung, "prompt": f"{motiv}.{zusatz} {STIL}"}
alle = []
for i,k,n,w,m in FAEHIG: alle.append(bild(i,"1 Fähigkeiten",n,w,m,FARBE[k]))
for i,n,w,m in STAERKEN: alle.append(bild(i,"2 Baum: Stärken",n,w,m,FARBE["basalt"]))
for i,k,n,m in SCHLUESSEL: alle.append(bild(i,"2 Baum: Schlüsselsteine",n,"Schlüsselstein der Klasse",m,FARBE[k]))
for i,n,w,m in AUGS: alle.append(bild(i,"2 Baum: Verstärkungen",n,w,m))
for c,ae in AESTE.items():
    for a in ae: alle.append(bild(f"ast_{c}_{a.lower()}","3 Baum: Astzeichen",f"Ast {a}",c,AST_MOTIV[a]+", emblem",FARBE[c]))
for i,n,m in GEGNER: alle.append(bild(f"g_{i}","4 Gegner (Lexikon)",n,"Bild für das Lexikon",m+", bust portrait, dramatic low light"))
json.dump({"stil": STIL, "bilder": alle}, open(os.path.join(HIER,"katalog.json"),"w"), ensure_ascii=False, indent=1)

md = ["# Bildkataloge\n", "Jeder Eintrag hat einen fertigen Prompt (Englisch, für die Bild-KI). Das Zuschneiden, der Goldrahmen, das Klassenband und die "
      "graue Sperre kommen danach aus dem eigenen Werkzeug, nicht von der KI: So bleibt der Satz einheitlich.\n",
      "## Stilbibel (steht in jedem Prompt)\n", f"> {STIL}\n",
      "Regeln: immer ein Motiv, nie Text, nie Rahmen; immer dasselbe Referenzbild mitgeben, sobald eine Vorlage gewählt ist; "
      "Quadrat; danach auf 64 Pixel verkleinern und prüfen, ob man es noch erkennt.\n"]
gr = {}
for b in alle: gr.setdefault(b["gruppe"], []).append(b)
anz = {"1": "Priorität 1", "2": "Priorität 1", "3": "Priorität 2 (optional)", "4": "Priorität 3 (optional)"}
for g, lst in gr.items():
    md.append(f"\n## {g}: {len(lst)} Bilder · {anz[g[0]]}\n")
    md.append("| Nr | ID | Name | Wirkung |\n|---|---|---|---|")
    for n,b in enumerate(lst,1): md.append(f"| {n} | `{b['id']}` | {b['name']} | {b['wirkung']} |")
    md.append("")
md.append("\n## Prompts\n")
for b in alle: md.append(f"**{b['id']} · {b['name']}**  \n{b['prompt']}\n")
open(os.path.join(HIER,"KATALOG.md"),"w").write("\n".join(md))
print({g: len(l) for g,l in gr.items()}, len(alle))
