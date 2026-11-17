# SPDX-License-Identifier: GPL-3.0-or-later (ruft die Blender-Schnittstelle bpy auf; siehe LIZENZ.md)
"""Bauplan: der Eidträger. Alter Kämpfer mit Schuppenpanzer, Perlenkragen, Leinenschurz mit dem Auge des Horus,
Laterne an der Hüfte, der Feder der Maat an der Schulter und einem Bronzeschwert.
Aufruf: python eidtraeger.py <Knight.glb> <ziel.glb> [tafel.png]"""
import math
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
from mathutils import Vector
import fabrik
from fabrik import Bau, lerp
from malen import Tafel

QUELLE, ZIEL = sys.argv[1], sys.argv[2]
TAFEL = sys.argv[3] if len(sys.argv) > 3 else ZIEL.replace(".glb", "_tafel.png")

BEWEGUNGEN = ["Idle", "2H_Melee_Idle", "Walking_A", "Running_A", "2H_Melee_Attack_Slice", "2H_Melee_Attack_Chop", "2H_Melee_Attack_Spin",
              "2H_Melee_Attack_Stab", "Dodge_Forward", "Cheer", "Spellcast_Raise", "Spellcast_Shoot", "Use_Item", "Interact", "PickUp",
              "Hit_A", "Hit_B", "Death_A", "Death_A_Pose"]

# Skelett: Mensch von 2,40 Einheiten Höhe (die Vorlage ist ein Kindchenschema mit riesigem Kopf)
PLAN = {
    "root": {"head": (0, 0, 0)},
    "hips": {"head": (0, 0, 1.16), "len": 0.16},
    "spine": {"an": True, "len": 0.30},
    "chest": {"an": True, "len": 0.28},
    "head": {"head": (0, 0, 1.93), "len": 0.40},
    "upperarm.l": {"head": (0.275, 0, 1.79), "len": 0.33},
    "lowerarm.l": {"an": True, "len": 0.33},
    "wrist.l": {"an": True, "len": 0.09},
    "hand.l": {"an": True, "len": 0.14},
    "handslot.l": {"rel": (0.12, 0, -0.072)},
    "upperleg.l": {"head": (0.125, 0, 1.22), "len": 0.55},
    "lowerleg.l": {"an": True, "len": 0.52},
    "foot.l": {"an": True, "len": 0.18},
    "toes.l": {"an": True, "len": 0.15},
}
K_WEG = (0.55 + 0.52) / (0.227 + 0.15)

FELDER = {
    "schuppen": (0, 0, 512, 256), "kragen": (512, 0, 1024, 128), "guertel": (512, 128, 1024, 192),
    "leinen": (0, 256, 512, 512), "schurz": (512, 192, 704, 512), "tuch": (704, 192, 1024, 512),
    "kopf": (0, 512, 512, 832), "haut": (512, 768, 704, 1024), "wickel": (512, 512, 704, 768),
    "klinge": (704, 512, 1024, 608), "bronze": (704, 608, 864, 704), "griff": (864, 608, 1024, 704),
    "feder": (704, 704, 1024, 832), "glas": (0, 832, 128, 960), "sandale": (128, 832, 256, 960), "haar": (256, 832, 512, 960),
}
HAUT = (160, 104, 68)
BRONZE = (176, 132, 66)
GOLD = (204, 160, 72)
LAPIS = (38, 62, 128)
TUERKIS = (52, 150, 140)
KARNEOL = (160, 56, 34)
NACHT = (34, 38, 56)
GRAU = (124, 124, 122)
KOPF_Z = (2.385, 1.99)   # Scheitel und Kinn: so liegt das Gesicht in der Tafel


def gesicht_px(phi, z):
    """Winkel (Grad, 0 = vorn, + = linke Seite der Figur) und Höhe -> Pixel im Feld „kopf“."""
    return (0.5 + phi / 360.0) * 512, (KOPF_Z[0] - z) / (KOPF_Z[0] - KOPF_Z[1]) * 320


def male():
    t = Tafel(1024, FELDER)
    t.schuppen("schuppen", BRONZE)
    # Kragen (Usech): innen Goldreif, dann Lapis, Türkisperlen, Gold, Karneoltropfen am Rand
    t.fuelle("kragen", GOLD, 0.06)
    t.band("kragen", 0.10, 0.30, LAPIS)
    t.perlen("kragen", 0.34, 0.52, [TUERKIS, GOLD, LAPIS, GOLD], 9)
    t.band("kragen", 0.56, 0.72, LAPIS)
    t.perlen("kragen", 0.76, 0.98, [KARNEOL, GOLD, TUERKIS, GOLD], 12)
    # Gürtel und Armschienen: Bronze mit Feldern
    t.fuelle("guertel", BRONZE, 0.07)
    t.band("guertel", 0.0, 0.14, (120, 86, 40))
    t.band("guertel", 0.86, 1.0, (120, 86, 40))
    t.perlen("guertel", 0.26, 0.74, [(150, 108, 50), GOLD], 16)
    t.falten("leinen", (196, 188, 168))
    # Schurz: nachtblaues Tuch, Goldborte, Auge des Horus, Fransen
    t.gewebe("schurz", NACHT)
    for x in (10, 182):
        t.linie("schurz", [(x, 0), (x, 268)], GOLD, 2.5)
    t.linie("schurz", [(10, 268), (182, 268)], GOLD, 2.5)
    t.linie("schurz", [(10, 12), (182, 12)], GOLD, 2.5)
    t.udjat("schurz", 92, 170, 44, GOLD)
    t.fransen("schurz", 0.86, (190, 150, 70))
    t.gewebe("tuch", (44, 46, 62))
    t.linie("tuch", [(0, 262), (320, 262)], (170, 132, 60), 3)
    t.fransen("tuch", 0.86, (150, 116, 56))
    # Haut
    t.fuelle("haut", HAUT, 0.05, 4.0)
    # Unterschenkel: Lederriemen über Kreuz
    t.fuelle("wickel", HAUT, 0.05, 4.0)
    leder = (92, 58, 34)
    for i in range(-2, 9):
        t.linie("wickel", [(0, 40 + i * 44), (192, 40 + i * 44 - 96)], leder, 5)
        t.linie("wickel", [(0, 40 + i * 44 - 96), (192, 40 + i * 44)], leder, 5)
    t.band("wickel", 0.0, 0.07, leder)
    t.band("wickel", 0.9, 1.0, leder)
    # Klinge: Bronze, heller Grat, dunkle Zeichen
    xx, yy, w, h = t.gitter("klinge")
    t.fuelle("klinge", (204, 160, 90), 0.05, 2.0, 0.8 + 0.35 * (1 - abs(xx / w - 0.5) * 2) ** 3 + 0.25 * (abs(xx / w - 0.5) > 0.44))
    for i in range(9):
        t.linie("klinge", [(152, 10 + i * 9), (168, 10 + i * 9)], (110, 76, 36), 1.5)
    t.fuelle("bronze", BRONZE, 0.1, 3.0)
    t.fuelle("griff", (70, 44, 28), 0.08)
    for i in range(12):
        t.linie("griff", [(i * 14 - 8, 0), (i * 14 + 8, 96)], (40, 24, 14), 2)
    # Feder: weiß, Kiel, schräge Äste
    t.fuelle("feder", (212, 208, 198), 0.03)
    for i in range(46):
        t.linie("feder", [(i * 7, 64), (i * 7 + 16, 4)], (196, 190, 176), 1)
        t.linie("feder", [(i * 7, 64), (i * 7 + 16, 124)], (196, 190, 176), 1)
    t.linie("feder", [(0, 64), (320, 64)], (160, 150, 130), 2.5)
    # Laternenglas
    xx, yy, w, h = t.gitter("glas")
    t.fuelle("glas", (255, 150, 50), 0.05, 2.0, 0.7 + 0.45 * (1 - abs(yy / h - 0.5) * 2))
    for i in range(7):
        t.linie("glas", [(i * 21.3, 0), (i * 21.3, 128)], (90, 60, 26), 3)
    t.linie("glas", [(0, 64), (128, 64)], (90, 60, 26), 2)
    # Sandale: oben Fußrücken mit Riemen, unten Sohle
    t.fuelle("sandale", HAUT, 0.05)
    t.vieleck("sandale", [(32, 0), (96, 0), (96, 128), (32, 128)], (70, 46, 28))        # Sohle (unten herum)
    for y in (30, 62, 96):
        t.linie("sandale", [(0, y), (128, y)], leder, 5)
    t.fuelle("haar", GRAU, 0.3, 2.5)
    # Gesicht
    xx, yy, w, h = t.gitter("kopf")
    seite = abs(xx / w - 0.5) * 2
    t.fuelle("kopf", HAUT, 0.04, 4.0, 1.04 - 0.16 * seite ** 2)
    P = gesicht_px
    bart = [P(-105, 2.20), P(-88, 2.12), P(-60, 2.085), P(-30, 2.10), P(-12, 2.112), P(0, 2.108), P(12, 2.112), P(30, 2.10), P(60, 2.085),
            P(88, 2.12), P(105, 2.20), P(120, 1.99), P(-120, 1.99)]
    t.vieleck("kopf", bart, (156, 154, 148))
    for i in range(160):   # Barthaare
        ph = -100 + 200 * t.rng.random()
        z = 1.995 + 0.1 * t.rng.random()
        t.linie("kopf", [P(ph, z), P(ph + 1.5, z - 0.02)], (112, 110, 106) if i % 2 else (196, 194, 188), 1.0)
    t.vieleck("kopf", [P(-180, 2.4), P(-112, 2.4), P(-108, 2.2), P(-125, 1.98), P(-180, 1.98)], GRAU)   # Haar an den Seiten und hinten
    t.vieleck("kopf", [P(180, 2.4), P(112, 2.4), P(108, 2.2), P(125, 1.98), P(180, 1.98)], GRAU)
    t.vieleck("kopf", [P(-115, 2.4), P(115, 2.4), P(112, 2.305), P(60, 2.30), P(0, 2.292), P(-60, 2.30), P(-112, 2.305)], GRAU)  # Haaransatz
    t.linie("kopf", [P(-13, 2.074), P(-5, 2.070), P(5, 2.070), P(13, 2.074)], (96, 52, 40), 3.0)   # Mund
    for sgn in (-1, 1):
        ex, ey = P(sgn * 27, 2.183)
        t.oval("kopf", ex, ey, 15, 7.5, (236, 228, 212))
        t.oval("kopf", ex - sgn * 1, ey, 6.2, 6.2, (46, 30, 20))
        t.oval("kopf", ex - sgn * 3, ey - 2, 1.6, 1.6, (240, 236, 226))
        t.linie("kopf", [(ex - sgn * 16, ey + 1), (ex - sgn * 6, ey - 8), (ex + sgn * 8, ey - 8), (ex + sgn * 17, ey - 1), (ex + sgn * 30, ey - 3)], (26, 20, 18), 3.0)  # Lidstrich
        t.linie("kopf", [(ex - sgn * 15, ey + 2), (ex, ey + 8), (ex + sgn * 16, ey)], (70, 44, 30), 1.5)
        t.linie("kopf", [(ex - sgn * 19, ey - 17), (ex, ey - 23), (ex + sgn * 21, ey - 16)], (104, 102, 100), 5.5)   # Braue
        t.linie("kopf", [(ex - sgn * 10, ey + 30), (ex + sgn * 5, ey + 40)], (140, 92, 60), 1.8)                   # Wangenfalte
    for z in (2.262, 2.278):
        t.linie("kopf", [P(-30, z), P(0, z - 0.003), P(30, z)], (148, 98, 64), 1.2)                              # Stirnfalten
    t.fertig(TAFEL)


def kopf_ring(z):
    """Kopfform: Halbmesser vorn, hinten, seitlich in der Höhe z (zwischen den Stützstellen linear)."""
    T = [(2.00, .070, .075, .070), (2.02, .104, .082, .086), (2.06, .124, .098, .104), (2.11, .130, .112, .114), (2.16, .128, .126, .121),
         (2.22, .133, .136, .124), (2.28, .124, .136, .119), (2.33, .096, .112, .096), (2.365, .05, .058, .05), (2.384, .012, .014, .012)]
    for (z0, a0, c0, b0), (z1, a1, c1, b1) in zip(T, T[1:]):
        if z <= z1:
            u = max(0.0, (z - z0) / (z1 - z0))
            return a0 + (a1 - a0) * u, c0 + (c1 - c0) * u, b0 + (b1 - b0) * u
    return T[-1][1:]


def baue(J):
    B = Bau(1024)
    F = FELDER
    STOFF, METALL, GLUT = 0, 1, 2

    # --- Rumpf im Schuppenpanzer
    rumpf = [(1.20, .150, .150, .215, {"hips": 1}), (1.30, .140, .140, .200, {"hips": .6, "spine": .4}), (1.42, .145, .150, .200, {"spine": 1}),
             (1.55, .165, .160, .225, {"spine": .6, "chest": .4}), (1.68, .190, .170, .260, {"chest": 1}), (1.80, .185, .170, .280, {"chest": 1}),
             (1.88, .140, .140, .230, {"chest": 1}), (1.925, .090, .095, .110, {"chest": .7, "head": .3})]
    B.loft([{"c": (0, 0, z), "a": (af, ab), "b": b, "w": w, "v": 1 - (z - 1.20) / 0.725} for z, af, ab, b, w in rumpf], 20, F["schuppen"], METALL, p=2.5)
    # Hals
    B.loft([{"c": (0, 0, 1.89), "a": .08, "b": .08, "w": {"chest": 1}}, {"c": (0, -.004, 1.96), "a": .07, "b": .068, "w": {"chest": .5, "head": .5}},
            {"c": (0, -.01, 2.03), "a": .068, "b": .066, "w": {"head": 1}}], 10, F["haut"], STOFF)

    # --- Kopf
    zs = [2.00, 2.02, 2.045, 2.07, 2.095, 2.12, 2.15, 2.18, 2.21, 2.24, 2.27, 2.30, 2.33, 2.355, 2.372, 2.384]
    ringe = []
    for z in zs:
        af, ab, b = kopf_ring(z)
        ringe.append({"c": (0, -.012, z), "a": (af, ab), "b": b, "w": {"head": 1}, "v": (KOPF_Z[0] - z) / (KOPF_Z[0] - KOPF_Z[1])})
    B.loft(ringe, 18, F["kopf"], STOFF, deckel=(False, True), p=2.15)
    hx, hy = (F["haut"][0] + F["haut"][2]) / 2, (F["haut"][1] + F["haut"][3]) / 2
    n0, n1, n2, n3, n4 = (0, -.142, 2.205), (0, -.180, 2.128), (.024, -.136, 2.118), (-.024, -.136, 2.118), (0, -.138, 2.104)
    for tri in ((n0, n2, n1), (n0, n1, n3), (n1, n2, n4), (n1, n4, n3)):
        B.flaeche(tri, [(hx, hy), (hx + 6, hy + 8), (hx - 6, hy + 8)], {"head": 1}, STOFF)
    B.spiegel(lambda b: b.loft([{"c": (.112, .012, 2.165), "a": .034, "b": .02, "w": {"head": 1}}, {"c": (.134, .02, 2.168), "a": .04, "b": .022, "w": {"head": 1}},
                                {"c": (.142, .026, 2.17), "a": .026, "b": .012, "w": {"head": 1}}], 8, F["haut"], STOFF, achse=(1, 0, 0), vorn=(0, 0, 1), deckel=(False, True)))
    # Haar: Kappe oben, Kranz hinten und an den Seiten
    kappe = []
    for z in (2.275, 2.30, 2.325, 2.35, 2.37, 2.385, 2.396):     # die Kopfform, etwas angehoben: rund, ohne Spitze
        af, ab, b = kopf_ring(z - 0.012)
        d = 0.015
        kappe.append({"c": (0, -.012, z), "a": (af + d, ab + d), "b": b + d, "w": {"head": 1}})
    B.loft(kappe, 16, F["haar"], STOFF, deckel=(False, True), p=2.15)
    kranz = []
    for z in (2.075, 2.12, 2.17, 2.22, 2.28):
        af, ab, b = kopf_ring(z)
        kranz.append({"c": (0, -.012, z), "a": (af + .016, ab + .016), "b": b + .016, "w": {"head": 1}})
    B.loft(kranz, 12, F["haar"], STOFF, bogen=(math.radians(78), math.radians(282)), p=2.15)

    # --- Arme
    S, E, W, H = J["upperarm.l"][0], J["lowerarm.l"][0], J["wrist.l"][0], J["hand.l"][0]

    def arm(b):
        dx = Vector((1, 0, 0))
        r = [(S - dx * .06, .05, .05, {"chest": 1}), (S - dx * .015, .100, .095, {"chest": .6, "upperarm.l": .4}), (S + dx * .03, .112, .105, {"chest": .2, "upperarm.l": .8}),
             (lerp(S, E, .30), .100, .095, {"upperarm.l": 1}), (lerp(S, E, .60), .088, .085, {"upperarm.l": 1}), (lerp(S, E, .87), .074, .072, {"upperarm.l": .85, "lowerarm.l": .15}),
             (E, .068, .068, {"upperarm.l": .5, "lowerarm.l": .5}), (lerp(E, W, .13), .076, .074, {"upperarm.l": .15, "lowerarm.l": .85}), (lerp(E, W, .35), .080, .075, {"lowerarm.l": 1}),
             (lerp(E, W, .70), .064, .060, {"lowerarm.l": 1}), (W, .050, .048, {"lowerarm.l": .5, "wrist.l": .5})]
        b.loft([{"c": c, "a": a, "b": bb, "w": w} for c, a, bb, w in r], 12, F["haut"], STOFF, achse=(1, 0, 0), vorn=(0, 0, 1))
        dz = Vector((0, 0, 1))
        faust = [(W + dx * .02, .045, .050, {"wrist.l": 1}), (H - dx * .02 - dz * .01, .056, .062, {"wrist.l": .5, "hand.l": .5}), (H + dx * .05 - dz * .035, .064, .068, {"hand.l": 1}),
                 (H + dx * .11 - dz * .048, .058, .062, {"hand.l": 1}), (H + dx * .15 - dz * .048, .034, .04, {"hand.l": 1})]
        b.loft([{"c": c, "a": a, "b": bb, "w": w} for c, a, bb, w in faust], 10, F["haut"], STOFF, achse=(1, 0, 0), vorn=(0, 0, 1), deckel=(False, True), p=2.6)
        schiene = [(.36, .086, .081), (.40, .094, .089), (.55, .086, .080), (.84, .070, .066), (.92, .070, .066), (.94, .060, .056)]
        b.loft([{"c": lerp(E, W, t), "a": a, "b": bb, "w": {"lowerarm.l": 1}} for t, a, bb in schiene], 12, F["guertel"], METALL, achse=(1, 0, 0), vorn=(0, 0, 1))
    B.spiegel(arm)

    # --- Beine
    Hj, K, A, T, TT = J["upperleg.l"][0], J["lowerleg.l"][0], J["foot.l"][0], J["toes.l"][0], J["toes.l"][1]

    def bein(b):
        ob = [(Hj + Vector((0, 0, .06)), (.10, .11), .110, {"hips": .8, "upperleg.l": .2}), (lerp(Hj, K, .12), (.10, .11), .105, {"hips": .2, "upperleg.l": .8}),
              (lerp(Hj, K, .45), (.095, .092), .090, {"upperleg.l": 1}), (lerp(Hj, K, .80), (.072, .074), .070, {"upperleg.l": .85, "lowerleg.l": .15}),
              (K, (.068, .066), .064, {"upperleg.l": .5, "lowerleg.l": .5})]
        b.loft([{"c": c, "a": a, "b": bb, "w": w} for c, a, bb, w in ob], 12, F["haut"], STOFF)
        un = [(K, (.068, .066), .064, {"upperleg.l": .5, "lowerleg.l": .5}), (lerp(K, A, .15), (.058, .072), .063, {"upperleg.l": .15, "lowerleg.l": .85}),
              (lerp(K, A, .35), (.055, .086), .066, {"lowerleg.l": 1}), (lerp(K, A, .70), (.046, .058), .050, {"lowerleg.l": 1}),
              (lerp(K, A, .96), (.042, .046), .043, {"lowerleg.l": .7, "foot.l": .3})]
        b.loft([{"c": c, "a": a, "b": bb, "w": w} for c, a, bb, w in un], 12, F["wickel"], STOFF)
        fuss = [(Vector((A.x, A.y + .075, .034)), (.026, .03), .036, {"foot.l": 1}), (Vector((A.x, A.y + .015, .048)), (.062, .044), .050, {"foot.l": 1}),
                (Vector((A.x, lerp(A, T, .5).y, .040)), (.044, .036), .056, {"foot.l": 1}), (Vector((T.x, T.y, .030)), (.027, .026), .063, {"foot.l": .5, "toes.l": .5}),
                (Vector((TT.x, TT.y + .01, .023)), (.019, .020), .056, {"toes.l": 1}), (Vector((TT.x, TT.y - .022, .020)), (.008, .012), .034, {"toes.l": 1})]
        b.loft([{"c": c, "a": a, "b": bb, "w": w} for c, a, bb, w in fuss], 10, F["sandale"], STOFF, achse=(0, -1, 0), vorn=(0, 0, 1), deckel=(True, True), p=2.7, start=0.0)
    B.spiegel(bein)

    # --- Schurz aus Leinen: schwingt mit den Beinen
    def bein_w(t):
        def w(th):
            L = 0.85 * t
            sn = math.sin(th)
            l = L * min(1.0, max(0.0, 0.5 + sn * 1.3))
            r = L * min(1.0, max(0.0, 0.5 - sn * 1.3))
            return {"hips": 1 - l - r, "upperleg.l": l, "upperleg.r": r}
        return w

    def fetzen(th):
        return -0.035 * (0.5 + 0.5 * math.sin(th * 7.0) * math.sin(th * 3.0 + 1.0))
    rock = [(1.34, .150, .150, .205, 0.0), (1.24, .180, .190, .245, .2), (1.08, .210, .215, .275, .5), (.90, .235, .235, .295, .8), (.74, .250, .245, .305, 1.0)]
    B.loft([dict({"c": (0, 0, z), "a": (af, ab), "b": b, "w": bein_w(t), "v": t}, **({"dz": fetzen} if t == 1.0 else {})) for z, af, ab, b, t in rock], 24, F["leinen"], STOFF)
    lasche = [(1.33, .168, .222, 0.0), (1.24, .197, .262, .2), (1.08, .227, .292, .5), (.90, .252, .312, .8), (.62, .270, .325, 1.0)]
    B.loft([{"c": (0, 0, z), "a": a, "b": b, "w": bein_w(t * 0.9), "v": (1.33 - z) / 0.71} for z, a, b, t in lasche], 5, F["schurz"], STOFF, bogen=(-0.48, 0.48))
    # Gürtel
    B.loft([{"c": (0, 0, z), "a": a, "b": b, "w": {"hips": .8, "spine": .2}} for z, a, b in ((1.268, .152, .208), (1.275, .166, .224), (1.35, .162, .220), (1.357, .146, .204))],
           20, F["guertel"], METALL, p=2.5)

    # --- Perlenkragen
    def kr_w(th):
        s = abs(math.sin(th))
        return {"chest": 1.0}
    kragen = [{"c": (0, 0, 1.965), "a": .085, "b": .085, "v": 0.0}, {"c": (0, 0, 1.94), "a": (.14, .13), "b": .16, "v": 0.25},
              {"c": (0, 0, 1.87), "a": (.195, .175), "b": .265, "v": 0.6, "dz": lambda th: -0.03 * max(0, math.cos(th)) ** 2 + 0.05 * math.sin(th) ** 2},
              {"c": (0, 0, 1.80), "a": (.232, .205), "b": .35, "v": 1.0, "dz": lambda th: -0.07 * max(0, math.cos(th)) ** 2 + 0.118 * math.sin(th) ** 2}]
    for r in kragen:
        r["w"] = kr_w
    B.loft(kragen, 24, F["kragen"], STOFF)

    # --- Rückentuch mit Fransen
    tuch = [(1.885, .155, .20, {"chest": 1}), (1.76, .215, .285, {"chest": 1}), (1.52, .205, .255, {"chest": .5, "spine": .5}), (1.30, .215, .255, {"spine": .5, "hips": .5}),
            (1.10, .245, .275, {"hips": 1})]
    B.loft([dict({"c": (0, 0, z), "a": (a, a), "b": b, "w": w, "v": (1.885 - z) / 0.785}, **({"dz": fetzen} if z == 1.10 else {})) for z, a, b, w in tuch], 9, F["tuch"], STOFF,
           bogen=(math.radians(98), math.radians(262)))

    # --- Feder der Maat hinter der rechten Schulter
    kiel = [Vector(p) for p in ((-.20, .15, 1.86), (-.25, .18, 2.08), (-.30, .185, 2.28), (-.345, .165, 2.46), (-.375, .11, 2.60), (-.385, .03, 2.70))]
    breit = [.012, .06, .085, .085, .06, .012]
    fx0, fy0, fx1, fy1 = F["feder"]
    for i in range(len(kiel) - 1):
        q = []
        for j in (i, i + 1):
            d = (kiel[min(j + 1, len(kiel) - 1)] - kiel[max(j - 1, 0)]).normalized()
            n = d.cross(Vector((0, 1, 0.25))).normalized() * breit[j]
            q.append((kiel[j] - n, kiel[j] + n, j / (len(kiel) - 1)))
        B.flaeche([q[0][0], q[0][1], q[1][1], q[1][0]],
                  [(fx0 + q[0][2] * 320, fy0), (fx0 + q[0][2] * 320, fy1), (fx0 + q[1][2] * 320, fy1), (fx0 + q[1][2] * 320, fy0)], {"chest": 1}, STOFF)

    # --- Laterne an der linken Hüfte
    lw = {"hips": .7, "upperleg.l": .3}
    L = Vector((.30, -.15, 0))
    B.loft([{"c": L + Vector((0, 0, z)), "a": r, "b": r, "w": lw} for z, r in ((.925, .012), (.935, .045), (.955, .052), (.96, .044))], 6, F["bronze"], METALL, deckel=(True, False))
    B.loft([{"c": L + Vector((0, 0, z)), "a": .042, "b": .042, "w": lw} for z in (.96, 1.05)], 6, F["glas"], GLUT)
    B.loft([{"c": L + Vector((0, 0, z)), "a": r, "b": r, "w": lw} for z, r in ((1.05, .044), (1.055, .054), (1.08, .034), (1.105, .01))], 6, F["bronze"], METALL, deckel=(False, True))
    B.loft([{"c": L + Vector((0, 0, 1.10)), "a": .006, "b": .006, "w": lw}, {"c": (.215, -.10, 1.30), "a": .006, "b": .006, "w": {"hips": 1}}], 4, F["bronze"], METALL)

    # --- Bronzeschwert in der rechten Hand: Griff quer durch die Faust, Klinge nach vorn
    O = J["handslot.r"][0]
    sw = {"handslot.r": 1}

    def stab(teile, feld, mat, n=8, deckel=(False, False), p=2.0):
        B.loft([{"c": O + Vector((0, -d, 0)), "a": a, "b": b, "w": sw} for d, a, b in teile], n, feld, mat,
               achse=(0, -1, 0), vorn=(1, 0, 0), deckel=deckel, p=p, start=0.0)
    stab([(-.37, .012, .012), (-.36, .042, .042), (-.325, .046, .046), (-.30, .024, .024)], F["bronze"], METALL, deckel=(True, False))
    stab([(-.30, .023, .023), (.16, .023, .023)], F["griff"], STOFF)
    stab([(.16, .03, .03), (.168, .16, .034), (.20, .19, .036), (.215, .21, .026), (.222, .055, .02)], F["bronze"], METALL, p=3.0)
    stab([(.222, .066, .017), (.50, .074, .017), (.95, .088, .016), (1.20, .072, .013), (1.38, .04, .01), (1.50, .004, .003)], F["klinge"], METALL, deckel=(False, True), p=1.15)
    return B


male()
arm = fabrik.lade_rig(QUELLE, BEWEGUNGEN)
J = fabrik.umbauen(arm, PLAN, K_WEG)
bild = bpy.data.images.load(TAFEL)
mats = [fabrik.material("stoff", bild, 0.0, 0.85), fabrik.material("bronze", bild, 0.5, 0.55), fabrik.material("glut", bild, 0.0, 0.5, glut=1.3)]
ob = baue(J).mesh("Eidtraeger", arm, mats)
fabrik.boden(arm, ob)
print("Punkte", len(ob.data.vertices), "Dreiecke", sum(len(p.vertices) - 2 for p in ob.data.polygons))
fabrik.ausgabe(ZIEL)
print("geschrieben", ZIEL, os.path.getsize(ZIEL) // 1024, "KB")
