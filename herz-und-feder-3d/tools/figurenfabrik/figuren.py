# SPDX-License-Identifier: GPL-3.0-or-later (Teil der Figurenfabrik; siehe LIZENZ.md)
"""Alle Baupläne des Baukastens (mensch.py). Aufruf:  python figuren.py <Name|alle> [Zielordner]
Quellen: rigs/Abenteurer.glb und rigs/Skelett.glb (KayKit, CC0: Skelett und Bewegungen), gemalte Bögen in bilder/."""
import os
import sys
HIER = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HIER)
import mensch

WURZEL = os.path.join(HIER, "..", "..")
B = lambda n: os.path.join(WURZEL, "bilder", n)
P = lambda n: os.path.join(WURZEL, "ui", n)
PROZ = {"glas": ("glas",), "feder": ("feder",), "griff": ("griff",)}

HELD = ["Idle", "Walking_A", "Running_A", "Dodge_Forward", "Use_Item", "Interact", "PickUp", "Cheer", "Hit_A", "Hit_B", "Death_A", "Spellcast_Raise", "Spellcast_Shoot"]
FEIND = ["Skeletons_Inactive_Floor_Pose", "Skeletons_Awaken_Floor", "Idle_Combat", "Walking_D_Skeletons", "Running_A", "1H_Melee_Attack_Chop", "2H_Melee_Attack_Chop",
         "Spellcast_Shoot", "Hit_A", "Death_C_Skeletons", "Skeleton_Inactive_Standing_Pose", "Skeletons_Awaken_Standing", "2H_Melee_Attack_Spin", "Spellcast_Summon", "Idle"]

FIGUREN = {
    # ------------------------------------------------------------ Helden
    "Priester": {
        "rig": "Abenteurer", "bogen": B("K12_voll.webp"),
        "bewegungen": HELD + ["Unarmed_Idle", "Unarmed_Melee_Attack_Punch_A", "Unarmed_Melee_Attack_Punch_B", "Unarmed_Melee_Attack_Kick"],
        "bau": {"schulter": 0.97, "taille": 0.93, "arm": 0.95},
        "teile": {"rumpf": "rumpf", "kragen": True, "guertel": "stoff", "rock": {"saum": .58, "weit": .85}, "lasche": {"saum": .46, "breit": .3},
                  "haar": "glatze", "feder": "kopf", "unterarm": "bein", "hand": "bein", "unterschenkel": "haut"},
        "tafel": dict(PROZ, **{
            "haut": ("haut", (430, 330, 470, 380), 1.15), "fuss": ("haut", (430, 330, 470, 380), 1.1), "kopf": ("haut", (430, 330, 470, 380), 1.1),
            "rumpf": [("haut", (430, 330, 470, 380), 1.15), ("mitte", (395, 290, 545, 412), 0.46, 0.2, 0.86)],
            "kragen": ("abrollen", (478, 215), 42, 92, 35, 145), "guertel": ("kachel", (410, 425, 500, 475), 64, 0.5),
            "rock": ("kachel", (400, 520, 480, 680), 256, 0.6), "lasche": ("ganz", (505, 480, 570, 770)),
            "bein": ("kachel", (328, 470, 365, 590), 256, 0.5)}),
        "gesicht": [{"bild": B("K12_voll.webp"), "cx": 487, "R": 48, "theta": 36, "y": [(2.385, 100), (2.30, 135), (2.183, 165), (2.07, 197), (2.0, 222)]},
                    {"bild": P("portrait_moench.jpg"), "cx": 322, "R": 112, "theta": 35, "oben": 2.34, "y": [(2.36, 125), (2.30, 165), (2.183, 222), (2.07, 312), (2.0, 380)]}],
    },
    "Jaegerin": {
        "rig": "Abenteurer", "bogen": B("K13_voll.webp"),
        "bewegungen": HELD + ["2H_Ranged_Aiming", "2H_Ranged_Shoot", "2H_Ranged_Shooting"],
        "bau": {"frau": True, "schulter": 0.86, "taille": 0.82, "huefte": 0.97, "arm": 0.82, "bein": 0.92},
        "teile": {"rumpf": "rumpf", "kragen": {"weit": 1.02, "tief": .03}, "guertel": "stoff", "rock": {"saum": .82, "weit": .9, "fetzen": .10, "schraeg": .12},
                  "lasche": {"saum": .70, "breit": .26}, "haar": "zoepfe", "schiene": "metall", "waffe": "bogen", "koecher": True},
        "tafel": dict(PROZ, **{
            "haut": ("haut", (345, 330, 375, 380), 1.2), "fuss": ("kachel", (345, 900, 400, 960), 128, 0.4), "kopf": ("haut", (345, 330, 375, 380), 1.2),
            "rumpf": ("kachel", (415, 290, 500, 380), 256, 0.6), "kragen": ("kachel", (430, 195, 560, 265), 128, 0.4),
            "guertel": ("kachel", (420, 385, 500, 420), 64, 0.4), "rock": ("kachel", (400, 560, 470, 680), 256, 0.6),
            "lasche": ("ganz", (480, 440, 545, 665)), "bein": ("kachel", (345, 760, 395, 880), 256, 0.4),
            "metall": ("kachel", (335, 405, 378, 500), 96, 0.4), "haar": ("kachel", (430, 60, 500, 110), 128, 0.3)}),
        "gesicht": [{"bild": B("K13_voll.webp"), "cx": 495, "R": 42, "theta": 36, "y": [(2.36, 80), (2.30, 105), (2.183, 140), (2.07, 172), (2.0, 192)]},
                    {"bild": P("portrait_jaegerin.jpg"), "cx": 342, "R": 98, "theta": 0, "y": [(2.36, 60), (2.30, 95), (2.183, 160), (2.07, 240), (2.0, 292)]}],
    },
    "Sternleserin": {
        "rig": "Abenteurer", "bogen": B("K14_voll.webp"),
        "bewegungen": HELD + ["Spellcast_Long", "Spellcasting"],
        "bau": {"frau": True, "schulter": 0.88, "taille": 0.95, "huefte": 1.0, "arm": 0.82},
        "teile": {"rumpf": "rumpf", "kragen": {"weit": .8}, "guertel": "stoff", "rock": {"saum": .16, "weit": .8, "fetzen": .0},
                  "tuch": {"umhang": True, "saum": .62}, "haar": "dutt", "schiene": "metall", "waffe": "stab", "unterschenkel": "haut"},
        "tafel": dict(PROZ, **{
            "haut": ("haut", (425, 118, 447, 140), 1.15), "fuss": ("haut", (425, 118, 447, 140), 1.0), "kopf": ("haut", (425, 118, 447, 140), 1.1),
            "rumpf": ("kachel", (420, 290, 500, 350), 256, 0.6, 70), "rock": [("kachel", (420, 520, 520, 700), 256, 0.6, 70), ("unten", (320, 792, 520, 838), 0.14)],
            "guertel": ("kachel", (372, 352, 500, 385), 64, 0.4), "tuch": ("kachel", (290, 250, 390, 330), 200, 0.5),
            "kragen": ("abrollen", (435, 195), 20, 50, 30, 150), "metall": ("kachel", (312, 445, 345, 490), 96, 0.4, 150),
            "haar": ("kachel", (360, 60, 420, 110), 128, 0.3)}),
        "gesicht": [{"bild": B("K14_voll.webp"), "cx": 435, "R": 40, "theta": 42, "y": [(2.36, 78), (2.30, 95), (2.183, 128), (2.07, 158), (2.0, 178)]},
                    {"bild": P("portrait_forensiker.jpg"), "cx": 352, "R": 95, "theta": -10, "y": [(2.36, 80), (2.30, 125), (2.183, 188), (2.07, 275), (2.0, 335)]}],
    },
    # ------------------------------------------------------------ Gegner (Bögen G14, G15, G12)
    "Ruheloser": {   # Mumie, der das Herz fehlt: Binden, Kragen, zerfetzter Schurz; liegt, bis man sie weckt
        "rig": "Skelett", "bogen": B("G14_voll.webp"), "bewegungen": FEIND, "haltung": {"spine": 8, "chest": 12, "head": -16},
        "bau": {"schulter": 0.95, "taille": 0.82, "arm": 0.85, "bein": 0.86},
        "teile": {"rumpf": "rumpf", "kragen": True, "guertel": "metall", "rock": {"saum": .70, "weit": .8, "fetzen": .14}, "lasche": {"saum": .5, "breit": .2},
                  "haar": "binden", "hals": "haut"},
        "tafel": {
            "haut": ("kachel", (310, 420, 360, 560), 128, 0.5), "bein": ("kachel", (355, 800, 420, 900), 256, 0.5), "fuss": ("kachel", (355, 800, 420, 900), 128, 0.5),
            "rumpf": [("kachel", (400, 330, 450, 400), 128, 0.5), ("mitte", (450, 265, 580, 385), 0.3, 0.12, 0.6)],
            "kragen": ("abrollen", (500, 165), 40, 95, 30, 150), "guertel": ("kachel", (410, 425, 500, 465), 64, 0.4),
            "rock": ("kachel", (380, 520, 480, 680), 256, 0.5), "lasche": ("ganz", (500, 470, 540, 760)),
            "kopf": ("kachel", (480, 30, 580, 90), 107, 0.4)},
        "gesicht": [{"bild": B("G14_voll.webp"), "cx": 535, "R": 62, "theta": 58, "y": [(2.385, 20), (2.30, 92), (2.183, 115), (2.07, 160), (2.0, 185)]}],
        "glut": [("auge", 27, 2.183, 5, (190, 220, 255)), ("fleck", "rumpf", 256, 92, 15, (190, 90, 230))],
    },
    "Krieger": {     # Sebau-Krieger: Grabwächter mit Königstuch, Schuppenpanzer, Sichelschwert und Fellschild
        "rig": "Skelett", "bogen": B("G15_voll.webp"), "bewegungen": FEIND, "haltung": {"spine": 5, "chest": 6, "head": -8},
        "bau": {"schulter": 1.05, "taille": 0.95},
        "teile": {"rumpf": "rumpf", "rumpf_metall": True, "kragen": True, "guertel": "metall", "rock": {"saum": .72, "weit": .9, "fetzen": .10},
                  "lasche": {"saum": .55, "breit": .22}, "haar": "nemes", "schiene": "metall", "waffe": "sichel", "schild": "tuch", "hals": "haut"},
        "tafel": dict(PROZ, **{
            "haut": ("kachel", (250, 300, 300, 390), 128, 0.5), "bein": ("kachel", (300, 760, 350, 860), 256, 0.5), "fuss": ("kachel", (530, 880, 640, 940), 128, 0.4),
            "rumpf": ("kachel", (400, 300, 480, 380), 256, 0.5), "kragen": ("abrollen", (500, 200), 45, 100, 30, 150),
            "guertel": ("kachel", (365, 400, 450, 450), 64, 0.4), "rock": ("kachel", (360, 520, 450, 640), 256, 0.5), "lasche": ("ganz", (470, 490, 540, 670)),
            "metall": ("kachel", (235, 405, 290, 500), 96, 0.4), "waffe": ("kachel", (310, 700, 350, 780), 96, 0.3, 110),
            "extra": ("kachel", (400, 40, 470, 160), 192, 0.3), "tuch": ("ganz", (560, 210, 700, 650)), "kopf": ("kachel", (250, 300, 300, 390), 107, 0.5)}),
        "gesicht": [{"bild": B("G15_voll.webp"), "cx": 512, "R": 44, "theta": 12, "y": [(2.36, 62), (2.30, 85), (2.183, 105), (2.07, 150), (2.0, 172)]}],
        "glut": [("auge", 27, 2.183, 6, (160, 230, 255))],
    },
    "Priesterin": {  # Sebau-Priesterin: Dienerin des Apophis mit Kobrahaube und Schlangenstab
        "rig": "Skelett", "bogen": B("G12_sebau_priesterin.webp"), "bewegungen": FEIND,
        "bau": {"frau": True, "schulter": 0.86, "taille": 0.8, "arm": 0.78},
        "teile": {"rumpf": "rumpf", "kragen": {"weit": .85}, "guertel": "metall", "rock": {"saum": .2, "weit": .75, "fetzen": .12}, "lasche": {"saum": .3, "breit": .18},
                  "tuch": {"umhang": True, "saum": .5}, "haar": "nemes", "waffe": "stab", "unterschenkel": "haut"},
        "tafel": dict(PROZ, **{
            "haut": ("haut", (305, 400, 330, 470), 0.7), "fuss": ("haut", (305, 400, 330, 470), 0.65), "rumpf": ("kachel", (400, 300, 480, 380), 256, 0.5, 60),
            "rock": ("kachel", (330, 520, 420, 700), 256, 0.5, 55), "lasche": ("ganz", (440, 480, 500, 740)), "guertel": ("kachel", (395, 395, 440, 440), 64, 0.4),
            "kragen": ("abrollen", (430, 255), 25, 60, 30, 150), "tuch": ("kachel", (300, 330, 360, 450), 200, 0.5, 50),
            "extra": ("kachel", (330, 90, 400, 210), 192, 0.3), "kopf": ("kachel", (390, 130, 440, 230), 107, 0.3), "griff": ("farbe", (120, 92, 50), 0.2)}),
        "gesicht": [{"bild": B("G12_sebau_priesterin.webp"), "cx": 455, "R": 50, "theta": 50, "y": [(2.36, 62), (2.30, 82), (2.183, 100), (2.07, 125), (2.0, 160)]}],
        "glut": [("auge", 30, 2.19, 5, (255, 210, 80))],
    },
}
# Varianten: derselbe Bauplan mit anderem Körperbau und anderen Teilen (die „Familie“ eines Gegners)
def variante(von, **ae):
    s = dict(FIGUREN[von])
    for k, v in ae.items():
        s[k] = dict(s[k], **v) if isinstance(v, dict) and isinstance(s.get(k), dict) and k != "tafel" else v
    return s

FIGUREN["Koloss"] = variante("Ruheloser", bau={"schulter": 1.38, "taille": 1.35, "huefte": 1.22, "arm": 1.5, "bein": 1.32}, haltung={"spine": 10, "chest": 14, "head": -20},
                             teile={"rumpf": "rumpf", "kragen": True, "guertel": "metall", "rock": {"saum": .78, "weit": .85, "fetzen": .12}, "haar": "binden", "hals": "haut", "waffe": "keule"},
                             tafel=dict(FIGUREN["Ruheloser"]["tafel"], griff=("griff",), waffe=("kachel", (480, 30, 580, 90), 96, 0.4, 80)))
FIGUREN["Erloschener"] = variante("Ruheloser", bau={"schulter": 0.9, "taille": 0.8, "arm": 0.78, "bein": 0.85}, haltung={"spine": 4, "chest": 6, "head": -6},
                                  teile={"rumpf": "rumpf", "kragen": True, "guertel": "metall", "rock": {"saum": .22, "weit": .7, "fetzen": .16}, "tuch": {"umhang": True, "saum": .45},
                                         "haar": "binden", "hals": "haut", "waffe": "stab", "unterschenkel": "haut"},
                                  tafel=dict(FIGUREN["Ruheloser"]["tafel"], tuch=("kachel", (380, 520, 480, 680), 200, 0.5, 70), griff=("griff",), glas=("glas",),
                                             metall=("kachel", (410, 425, 500, 465), 96, 0.4)),
                                  glut=[("auge", 27, 2.183, 6, (255, 255, 255))])
# ------------------------------------------------------------ Leute und Gestalten der Geschichte
LEUTE = ["Idle", "Unarmed_Idle", "Interact", "Cheer"]
FIGUREN["Mann"] = variante("Priester", bewegungen=LEUTE, gesicht=FIGUREN["Priester"]["gesicht"][:1],
                           teile={"rumpf": "rumpf", "guertel": "stoff", "rock": {"saum": .66, "weit": .85}, "haar": "kurz", "unterschenkel": "haut"},
                           tafel=dict(FIGUREN["Priester"]["tafel"], haar=("farbe", (38, 30, 26), 0.25)))
FIGUREN["Frau"] = variante("Jaegerin", bewegungen=LEUTE, gesicht=FIGUREN["Jaegerin"]["gesicht"][:1], bau={"frau": True, "schulter": 0.84, "taille": 0.86, "arm": 0.8},
                           teile={"rumpf": "rock", "kragen": {"weit": 1.0}, "guertel": "stoff", "rock": {"saum": .3, "weit": .7, "fetzen": .02}, "haar": "zoepfe", "unterschenkel": "haut"})
FIGUREN["Alter"] = variante("Sternleserin", bewegungen=LEUTE, gesicht=FIGUREN["Sternleserin"]["gesicht"][:1], bau={"schulter": 0.95, "taille": 1.0, "arm": 0.88},
                            teile={"rumpf": "rumpf", "kragen": {"weit": .8}, "guertel": "stoff", "rock": {"saum": .2, "weit": .75, "fetzen": .0}, "haar": "kurz", "unterschenkel": "haut"})

if __name__ == "__main__":
    wahl = sys.argv[1]
    ziel = sys.argv[2] if len(sys.argv) > 2 else os.path.join(WURZEL, "models", "chars")
    tmp = sys.argv[3] if len(sys.argv) > 3 else ziel
    for name, spec in FIGUREN.items():
        if wahl in ("alle", name):
            spec = dict(spec, name=name)
            mensch.fertige(spec, os.path.join(HIER, "rigs", spec["rig"] + ".glb"), os.path.join(ziel, name + ".glb"), os.path.join(tmp, name + "_tafel.png"))
