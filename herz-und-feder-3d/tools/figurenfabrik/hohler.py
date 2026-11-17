# SPDX-License-Identifier: GPL-3.0-or-later (ruft die Blender-Schnittstelle bpy auf; siehe LIZENZ.md)
"""Bauplan: der Hohle. Ein ausgezehrter Toter mit dunkler Schuppenhaut, dem das Herz fehlt: In der Brust klafft ein Loch,
aus dem kaltes Licht fällt. Lange Arme mit Klauen, zerfetzter Lendenschurz, vorgebeugte Haltung.
Aufruf: python hohler.py <Skeleton_Rogue.glb> <ziel.glb> [tafel.png]"""
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
GLUT = TAFEL.replace(".png", "_glut.png")

BEWEGUNGEN = ["Skeletons_Inactive_Floor_Pose", "Skeletons_Awaken_Floor", "Idle_Combat", "Walking_D_Skeletons", "Running_A", "1H_Melee_Attack_Chop",
              "2H_Melee_Attack_Chop", "Spellcast_Shoot", "Hit_A", "Death_C_Skeletons", "Skeleton_Inactive_Standing_Pose", "Skeletons_Awaken_Standing",
              "2H_Melee_Attack_Spin", "Spellcast_Summon", "Unarmed_Melee_Attack_Punch_A", "Idle"]

PLAN = {
    "root": {"head": (0, 0, 0)},
    "hips": {"head": (0, 0, 1.22), "len": 0.15},
    "spine": {"an": True, "len": 0.30},
    "chest": {"an": True, "len": 0.30},
    "head": {"head": (0, 0, 2.00), "len": 0.40},
    "upperarm.l": {"head": (0.235, 0, 1.86), "len": 0.40},
    "lowerarm.l": {"an": True, "len": 0.42},
    "wrist.l": {"an": True, "len": 0.09},
    "hand.l": {"an": True, "len": 0.16},
    "handslot.l": {"rel": (0.13, 0, -0.07)},
    "upperleg.l": {"head": (0.11, 0, 1.27), "len": 0.575},
    "lowerleg.l": {"an": True, "len": 0.56},
    "foot.l": {"an": True, "len": 0.18},
    "toes.l": {"an": True, "len": 0.15},
}
K_WEG = (0.575 + 0.56) / (0.227 + 0.15)

FELDER = {"rumpf": (0, 0, 256, 192), "haut": (256, 0, 384, 192), "gurt": (384, 0, 512, 64), "klaue": (384, 64, 512, 128), "fuss": (384, 128, 512, 192),
          "kopf": (0, 192, 256, 352), "tuch": (256, 192, 512, 352)}
HAUT = (58, 60, 70)
KALT = (200, 225, 255)
KOPF_Z = (2.475, 2.04)
RUMPF_Z = (1.985, 1.24)


def kopf_px(phi, z):
    return (0.5 + phi / 360.0) * 256, (KOPF_Z[0] - z) / (KOPF_Z[0] - KOPF_Z[1]) * 160


def rumpf_px(phi, z):
    return (0.5 + phi / 360.0) * 256, (RUMPF_Z[0] - z) / (RUMPF_Z[0] - RUMPF_Z[1]) * 192


def male():
    t = Tafel(512, FELDER)
    g = Tafel(512, FELDER, (0, 0, 0))
    for f in ("rumpf", "haut", "kopf", "fuss"):
        t.schuppen(f, HAUT, 11, 9)
        t.risse(f, 10, (150, 170, 200), 0.8, 50)
        g.risse(f, 7, (70, 100, 150), 0.8, 50)
    # Rippen: dunkle Bögen quer über die Brust
    for z in (1.60, 1.655, 1.71, 1.765):
        t.linie("rumpf", [rumpf_px(ph, z - 0.03 * abs(ph) / 70) for ph in range(-70, 71, 14)], (26, 27, 33), 2.2)
    # das Loch, wo das Herz war
    cx, cy = rumpf_px(8, 1.77)
    t.oval("rumpf", cx, cy, 21, 24, (16, 16, 22))
    t.schein("rumpf", cx, cy, 17, (235, 245, 255))
    g.schein("rumpf", cx, cy, 30, KALT, 1.0)
    g.oval("rumpf", cx, cy, 12, 14, (255, 255, 255))
    # leuchtende Wirbel den Rücken hinab (Naht der Abwicklung liegt hinten)
    for i in range(13):
        y = 14 + i * 13
        for x in (2, 254):
            t.oval("rumpf", x, y, 3, 4.5, (220, 232, 250))
            g.oval("rumpf", x, y, 3.5, 5, KALT)
    # Gesicht: Schlitzaugen aus Licht, ein Riss über die Stirn, schmaler Mund mit Zähnen
    P = kopf_px
    for sgn in (-1, 1):
        auge = [P(sgn * 14, 2.235), P(sgn * 24, 2.25), P(sgn * 38, 2.262), P(sgn * 26, 2.238)]
        t.vieleck("kopf", auge, (235, 245, 255))
        g.vieleck("kopf", auge, (255, 255, 255))
        gx, gy = P(sgn * 26, 2.248)
        g.schein("kopf", gx, gy, 12, KALT, 0.8)
        t.linie("kopf", [P(sgn * 5, 2.185), P(sgn * 7, 2.165)], (14, 14, 18), 1.6)      # Nasenschlitze
    riss = [P(6, 2.46), P(2, 2.40), P(9, 2.34), P(3, 2.29), P(7, 2.25)]
    t.linie("kopf", riss, (225, 238, 255), 1.6)
    g.linie("kopf", riss, KALT, 2.2)
    t.linie("kopf", [P(-26, 2.118), P(-12, 2.105), P(0, 2.11), P(12, 2.105), P(26, 2.118)], (12, 12, 16), 2.4)
    for ph in range(-20, 21, 8):
        t.linie("kopf", [P(ph, 2.114), P(ph, 2.098)], (190, 190, 180), 1.0)
    # Lendentuch: graubraunes Leinen mit goldenen Sternen, unten in Fetzen; Gurt mit Skarabäus
    t.falten("tuch", (92, 80, 64), 9, 0.5)
    for i in range(26):
        x, y = 8 + t.rng.random() * 240, 12 + t.rng.random() * 120
        for wi in range(5):
            a = wi * 2 * math.pi / 5
            t.linie("tuch", [(x, y), (x + 4 * math.cos(a), y + 4 * math.sin(a))], (196, 160, 80), 0.9)
    t.fuelle("gurt", (120, 104, 80), 0.1)
    t.band("gurt", 0.0, 0.16, (70, 58, 40))
    t.band("gurt", 0.84, 1.0, (70, 58, 40))
    t.oval("gurt", 64, 32, 14, 11, (196, 150, 70))
    t.linie("gurt", [(30, 32), (50, 30), (64, 34), (78, 30), (98, 32)], (196, 150, 70), 3)   # Flügel des Skarabäus
    xx, yy, w, h = t.gitter("klaue")
    t.fuelle("klaue", (40, 40, 46), 0.08, 2.0, 0.8 + 1.6 * (xx / w) ** 2)   # zur Spitze hin bleich
    t.fertig(TAFEL)
    g.fertig(GLUT)


def kopf_ring(z):
    T = [(2.04, .050, .055, .050), (2.07, .086, .070, .070), (2.12, .106, .090, .088), (2.18, .112, .120, .098), (2.25, .110, .150, .102),
         (2.32, .100, .165, .100), (2.39, .082, .155, .088), (2.44, .052, .120, .065), (2.472, .014, .05, .02)]
    for (z0, a0, c0, b0), (z1, a1, c1, b1) in zip(T, T[1:]):
        if z <= z1:
            u = max(0.0, (z - z0) / (z1 - z0))
            return a0 + (a1 - a0) * u, c0 + (c1 - c0) * u, b0 + (b1 - b0) * u
    return T[-1][1:]


def baue(J):
    B = Bau(512)
    F = FELDER
    LEIB = 0
    rumpf = [(1.24, .100, .110, .150, {"hips": 1}), (1.33, .085, .090, .120, {"hips": .6, "spine": .4}), (1.45, .090, .100, .125, {"spine": 1}),
             (1.58, .125, .125, .170, {"spine": .5, "chest": .5}), (1.72, .152, .140, .215, {"chest": 1}), (1.85, .146, .142, .235, {"chest": 1}),
             (1.93, .100, .112, .170, {"chest": 1}), (1.985, .060, .066, .070, {"chest": .6, "head": .4})]
    B.loft([{"c": (0, 0, z), "a": (af, ab), "b": b, "w": w, "v": (RUMPF_Z[0] - z) / (RUMPF_Z[0] - RUMPF_Z[1])} for z, af, ab, b, w in rumpf], 16, F["rumpf"], LEIB, p=2.3)
    B.loft([{"c": (0, 0, 1.96), "a": .056, "b": .054, "w": {"chest": .6, "head": .4}}, {"c": (0, -.01, 2.07), "a": .052, "b": .05, "w": {"head": 1}}], 8, F["haut"], LEIB)
    zs = [2.04, 2.07, 2.10, 2.13, 2.16, 2.19, 2.22, 2.25, 2.29, 2.33, 2.37, 2.41, 2.44, 2.46, 2.472]
    B.loft([{"c": (0, -.02, z), "a": kopf_ring(z)[:2], "b": kopf_ring(z)[2], "w": {"head": 1}, "v": (KOPF_Z[0] - z) / (KOPF_Z[0] - KOPF_Z[1])} for z in zs],
           16, F["kopf"], LEIB, deckel=(True, True), p=2.1)

    S, E, W, H, HT = J["upperarm.l"][0], J["lowerarm.l"][0], J["wrist.l"][0], J["hand.l"][0], J["hand.l"][1]

    def arm(b):
        dx, dz, dy = Vector((1, 0, 0)), Vector((0, 0, 1)), Vector((0, 1, 0))
        r = [(S - dx * .05, .04, .04, {"chest": 1}), (S, .074, .07, {"chest": .5, "upperarm.l": .5}), (lerp(S, E, .15), .066, .062, {"upperarm.l": 1}),
             (lerp(S, E, .55), .052, .05, {"upperarm.l": 1}), (lerp(S, E, .9), .046, .046, {"upperarm.l": .8, "lowerarm.l": .2}), (E, .056, .054, {"upperarm.l": .5, "lowerarm.l": .5}),
             (lerp(E, W, .12), .05, .05, {"upperarm.l": .2, "lowerarm.l": .8}), (lerp(E, W, .4), .052, .048, {"lowerarm.l": 1}), (lerp(E, W, .8), .04, .038, {"lowerarm.l": 1}),
             (W, .036, .038, {"lowerarm.l": .5, "wrist.l": .5})]
        b.loft([{"c": c, "a": a, "b": bb, "w": w} for c, a, bb, w in r], 10, F["haut"], LEIB, achse=(1, 0, 0), vorn=(0, 0, 1))
        hand = [(W, .034, .036, {"wrist.l": 1}), (H, .03, .056, {"wrist.l": .4, "hand.l": .6}), (H + dx * .09, .026, .064, {"hand.l": 1}), (H + dx * .13, .014, .05, {"hand.l": 1})]
        b.loft([{"c": c, "a": a, "b": bb, "w": w} for c, a, bb, w in hand], 8, F["haut"], LEIB, achse=(1, 0, 0), vorn=(0, 0, 1), deckel=(False, True))
        for k, (y, laenge) in enumerate(((-.05, .17), (-.018, .21), (.016, .20), (.048, .16))):   # vier Klauen
            p0 = H + dx * .115 + dy * y
            ax = (dx * 1.0 - dz * 0.35 + dy * y * 2).normalized()
            b.loft([{"c": p0, "a": .016, "b": .014, "w": {"hand.l": 1}, "ax": ax, "v": 0.0}, {"c": p0 + ax * laenge * .6 - dz * .012, "a": .011, "b": .009, "w": {"hand.l": 1}, "ax": ax, "v": .6},
                    {"c": p0 + ax * laenge - dz * .05, "a": .002, "b": .002, "w": {"hand.l": 1}, "ax": ax, "v": 1.0}], 5, F["klaue"], LEIB, achse=tuple(ax), vorn=(0, 0, 1))
        p0 = H + dx * .03 - dy * .05 - dz * .01   # Daumenklaue nach vorn
        ax = (dx * .5 - dy * 1.0 - dz * .3).normalized()
        b.loft([{"c": p0, "a": .016, "b": .014, "w": {"hand.l": 1}, "v": 0.0}, {"c": p0 + ax * .13, "a": .002, "b": .002, "w": {"hand.l": 1}, "v": 1.0}], 5, F["klaue"], LEIB,
               achse=tuple(ax), vorn=(0, 0, 1))
    B.spiegel(arm)

    Hj, K, A, T, TT = J["upperleg.l"][0], J["lowerleg.l"][0], J["foot.l"][0], J["toes.l"][0], J["toes.l"][1]

    def bein(b):
        r = [(Hj + Vector((0, 0, .05)), (.075, .085), .085, {"hips": .8, "upperleg.l": .2}), (lerp(Hj, K, .15), (.078, .082), .08, {"hips": .2, "upperleg.l": .8}),
             (lerp(Hj, K, .5), (.066, .064), .062, {"upperleg.l": 1}), (lerp(Hj, K, .88), (.05, .05), .05, {"upperleg.l": .8, "lowerleg.l": .2}),
             (K, (.058, .052), .054, {"upperleg.l": .5, "lowerleg.l": .5}), (lerp(K, A, .14), (.046, .054), .05, {"upperleg.l": .2, "lowerleg.l": .8}),
             (lerp(K, A, .35), (.042, .066), .052, {"lowerleg.l": 1}), (lerp(K, A, .75), (.034, .04), .036, {"lowerleg.l": 1}), (lerp(K, A, .97), (.032, .036), .034, {"lowerleg.l": .7, "foot.l": .3})]
        b.loft([{"c": c, "a": a, "b": bb, "w": w} for c, a, bb, w in r], 10, F["haut"], LEIB)
        fuss = [(Vector((A.x, A.y + .07, .03)), (.024, .026), .03, {"foot.l": 1}), (Vector((A.x, A.y + .01, .042)), (.05, .04), .042, {"foot.l": 1}),
                (Vector((A.x, lerp(A, T, .5).y, .034)), (.034, .03), .05, {"foot.l": 1}), (Vector((T.x, T.y, .026)), (.022, .022), .062, {"foot.l": .5, "toes.l": .5}),
                (Vector((TT.x, TT.y + .05, .02)), (.014, .016), .058, {"toes.l": 1})]
        b.loft([{"c": c, "a": a, "b": bb, "w": w} for c, a, bb, w in fuss], 8, F["fuss"], LEIB, achse=(0, -1, 0), vorn=(0, 0, 1), deckel=(True, True), p=2.6, start=0.0)
        for x in (-.04, 0, .04):   # drei Krallen
            p0 = Vector((TT.x + x, TT.y + .06, .022))
            ax = Vector((x * 1.5, -1, -.06)).normalized()
            b.loft([{"c": p0, "a": .016, "b": .015, "w": {"toes.l": 1}, "v": 0.0}, {"c": p0 + ax * .13, "a": .002, "b": .002, "w": {"toes.l": 1}, "v": 1.0}], 5, F["klaue"], LEIB,
                   achse=tuple(ax), vorn=(0, 0, 1))
    B.spiegel(bein)

    def bein_w(t):
        def w(th):
            L = 0.8 * t
            sn = math.sin(th)
            l = L * min(1.0, max(0.0, 0.5 + sn * 1.3))
            r = L * min(1.0, max(0.0, 0.5 - sn * 1.3))
            return {"hips": 1 - l - r, "upperleg.l": l, "upperleg.r": r}
        return w

    def fetzen(th):
        vorn = max(0.0, math.cos(th)) ** 3
        hinten = max(0.0, -math.cos(th)) ** 3
        return -0.42 * vorn - 0.30 * hinten - 0.07 * (0.5 + 0.5 * math.sin(th * 9.0) * math.sin(th * 4.0 + 1.0))
    tuch = [(1.30, .112, .118, .16, 0.0), (1.18, .135, .14, .19, .3), (1.04, .15, .15, .2, .6), (.96, .16, .155, .205, 1.0)]
    B.loft([dict({"c": (0, 0, z), "a": (af, ab), "b": b, "w": bein_w(t), "v": t}, **({"dz": fetzen} if t == 1.0 else {})) for z, af, ab, b, t in tuch], 20, F["tuch"], LEIB)
    B.loft([{"c": (0, 0, z), "a": (af, ab), "b": b, "w": {"hips": 1}} for z, af, ab, b in ((1.262, .10, .108, .148), (1.27, .118, .124, .166), (1.325, .112, .118, .16), (1.332, .09, .096, .13))],
           16, F["gurt"], LEIB, p=2.3, start=0.0)
    return B


male()
arm = fabrik.lade_rig(QUELLE, BEWEGUNGEN)
J = fabrik.umbauen(arm, PLAN, K_WEG, haltung={"spine": 10, "chest": 16, "head": -20})
bild = bpy.data.images.load(TAFEL)
glut = bpy.data.images.load(GLUT)
mats = [fabrik.material("leib", bild, 0.1, 0.6, glut=2.2, glutbild=glut)]
ob = baue(J).mesh("Hohler", arm, mats)
fabrik.boden(arm, ob)
print("Punkte", len(ob.data.vertices), "Dreiecke", sum(len(p.vertices) - 2 for p in ob.data.polygons))
fabrik.ausgabe(ZIEL)
print("geschrieben", ZIEL, os.path.getsize(ZIEL) // 1024, "KB")
