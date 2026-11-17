# SPDX-License-Identifier: GPL-3.0-or-later (ruft die Blender-Schnittstelle bpy auf; siehe LIZENZ.md)
"""Baukasten für Menschen und Menschenähnliche (Fassung 2.4): Ein Bauplan ist nur noch eine Beschreibung.

    spec = {"name": …, "bewegungen": […], "bau": {…Körperbau…}, "teile": {…Tracht und Waffen…},
            "bogen": gemalter Figurenbogen, "tafel": {Feld: Anweisung}, "gesicht": […]}
    mensch.fertige(spec, quelle_glb, ziel_glb, tafel_png)

Der Eidträger (eidtraeger.py) war das Einzelstück, an dem alles ausprobiert wurde. Hier steckt dasselbe als Baukasten:
Körperbau über Faktoren (Schultern, Taille, Hüfte, Arme, Beine, weibliche Form), Teile zum An- und Abwählen
(Kragen, Rock in jeder Länge, Lasche, Rückentuch oder Umhang, Haartrachten, Kopftuch, Feder, Laterne, Waffen, Schild)
und eine Texturtafel, die Feld für Feld aus dem gemalten Bogen gefüllt wird.
"""
import math
import os
import bpy
import numpy as np
from mathutils import Vector
from PIL import Image
import fabrik
from fabrik import Bau, lerp
from malen import Tafel
import gemalt as gm

PLAN = {
    "root": {"head": (0, 0, 0)}, "hips": {"head": (0, 0, 1.16), "len": 0.16}, "spine": {"an": True, "len": 0.30}, "chest": {"an": True, "len": 0.28},
    "head": {"head": (0, 0, 1.93), "len": 0.40}, "upperarm.l": {"head": (0.275, 0, 1.79), "len": 0.33}, "lowerarm.l": {"an": True, "len": 0.33},
    "wrist.l": {"an": True, "len": 0.09}, "hand.l": {"an": True, "len": 0.14}, "handslot.l": {"rel": (0.12, 0, -0.072)},
    "upperleg.l": {"head": (0.125, 0, 1.22), "len": 0.55}, "lowerleg.l": {"an": True, "len": 0.52}, "foot.l": {"an": True, "len": 0.18},
    "toes.l": {"an": True, "len": 0.15},
}
K_WEG = (0.55 + 0.52) / (0.227 + 0.15)

# Felder der Texturtafel (1024 × 1024), für alle Figuren gleich
F = {
    "rumpf": (0, 0, 512, 256), "kragen": (512, 0, 1024, 128), "guertel": (512, 128, 1024, 192),
    "rock": (0, 256, 512, 512), "lasche": (512, 192, 704, 512), "tuch": (704, 192, 1024, 512),
    "kopf": (0, 512, 512, 832), "bein": (512, 512, 704, 768), "haut": (512, 768, 704, 1024),
    "waffe": (704, 512, 1024, 608), "metall": (704, 608, 864, 704), "griff": (864, 608, 1024, 704),
    "feder": (704, 704, 1024, 832), "glas": (0, 832, 128, 960), "fuss": (128, 832, 256, 960), "haar": (256, 832, 512, 960),
    "extra": (704, 832, 1024, 1024), "arm": (0, 960, 512, 1024),
}
KOPF_Z = (2.385, 1.99)
STOFF, METALL, GLUT = 0, 1, 2


def gesicht_px(phi, z):
    return (0.5 + phi / 360.0) * 512, (KOPF_Z[0] - z) / (KOPF_Z[0] - KOPF_Z[1]) * 320


def kopf_ring(z):
    T = [(2.00, .070, .075, .070), (2.02, .104, .082, .086), (2.06, .124, .098, .104), (2.11, .130, .112, .114), (2.16, .128, .126, .121),
         (2.22, .133, .136, .124), (2.28, .124, .136, .119), (2.33, .096, .112, .096), (2.365, .05, .058, .05), (2.384, .012, .014, .012)]
    for (z0, a0, c0, b0), (z1, a1, c1, b1) in zip(T, T[1:]):
        if z <= z1:
            u = max(0.0, (z - z0) / (z1 - z0))
            return a0 + (a1 - a0) * u, c0 + (c1 - c0) * u, b0 + (b1 - b0) * u
    return T[-1][1:]


# ---------------------------------------------------------------- Texturtafel
def male(spec, pfad, glut_pfad=None):
    """Tafel füllen. Anweisungen je Feld:
    ("kachel", Kasten, Höhe[, flach, hell, senkrecht])  Fleck aus dem Bogen kacheln
    ("ganz", Kasten[, Drehung])                         Ausschnitt als Ganzes
    ("haut", Kasten[, hell])                            Farbe des Flecks mit feinem Korn
    ("farbe", (r, g, b)[, Streuung])                    einfarbig mit Korn
    ("abrollen", Mitte, r_innen, r_außen, w_von, w_bis) Bogen (Kragen) gerade ziehen
    ("streifen", hell, dunkel[, Breite])                waagrechte Streifen (Kopftuch)
    ("glas",), ("feder",), ("griff",)                   gezeichnete Muster"""
    t = Tafel(1024, F)
    ops = spec["tafel"]
    for feld, op in [(f_, o_) for f_, oo in ops.items() for o_ in (oo if isinstance(oo, list) else [oo])]:
        if op[0] == "farbe":
            t.fuelle(feld, op[1], op[2] if len(op) > 2 else 0.08)
        elif op[0] == "glas":
            xx, yy, w, h = t.gitter(feld)
            t.fuelle(feld, (255, 150, 50), 0.05, 2.0, 0.7 + 0.45 * (1 - abs(yy / h - 0.5) * 2))
            for i in range(7):
                t.linie(feld, [(i * 21.3, 0), (i * 21.3, 128)], (90, 60, 26), 3)
        elif op[0] == "feder":
            t.fuelle(feld, (212, 208, 198), 0.03)
            for i in range(46):
                t.linie(feld, [(i * 7, 64), (i * 7 + 16, 4)], (176, 170, 156), 1)
                t.linie(feld, [(i * 7, 64), (i * 7 + 16, 124)], (176, 170, 156), 1)
            t.linie(feld, [(0, 64), (320, 64)], (150, 140, 120), 2.5)
        elif op[0] == "griff":
            t.fuelle(feld, (70, 44, 28), 0.08)
            for i in range(12):
                t.linie(feld, [(i * 14 - 8, 0), (i * 14 + 8, 96)], (40, 24, 14), 2)
    t.fertig(pfad)
    im = Image.open(pfad).convert("RGB")
    k = Image.open(spec["bogen"]).convert("RGB") if spec.get("bogen") else None
    einzeln = [(feld, op) for feld, o in ops.items() for op in (o if isinstance(o, list) else [o])]
    for feld, op in einzeln:
        x0, y0, x1, y1 = F[feld]
        w, h = x1 - x0, y1 - y0
        if op[0] == "mitte":       # ("mitte", Kasten, Anteil der Breite, v_von, v_bis): Ausschnitt weich in die Feldmitte (Brust auf nackter Haut)
            bw = int(w * op[2])
            fl = k.crop(op[1]).resize((bw, int(h * (op[4] - op[3]))), Image.LANCZOS)
            gm.einsetzen(im, F[feld], fl, ((w - bw) // 2, int(h * op[3])), 0.35)
        elif op[0] == "unten":     # ("unten", Kasten, Anteil): Borte am unteren Rand entlang
            bh = int(h * op[2])
            fl = k.crop(op[1])
            gm.einsetzen(im, F[feld], gm.kachel(fl, w, bh, bh), (0, h - bh))
        elif op[0] == "kachel":
            fl = k.crop(op[1])
            fl = gm.flach(fl, op[3] if len(op) > 3 and op[3] is not None else 0.6)
            if len(op) > 4 and op[4]:
                fl = gm.angleichen(fl, op[4])
            gm.einsetzen(im, F[feld], gm.kachel(fl, w, h, op[2] or h, len(op) > 5 and op[5]))
        elif op[0] == "ganz":
            fl = k.crop(op[1])
            if len(op) > 2 and op[2]:
                fl = fl.rotate(op[2], resample=Image.BICUBIC, expand=True)
            gm.einsetzen(im, F[feld], fl.resize((w, h), Image.LANCZOS))
        elif op[0] == "haut":
            gm.einsetzen(im, F[feld], gm.haut(k, op[1], w, h, 3, op[2] if len(op) > 2 else 1.1))
        elif op[0] == "abrollen":
            band = gm.abrollen(k, op[1], op[2], op[3], op[4], op[5], 256, h)
            gm.einsetzen(im, F[feld], gm.kachel(band, w, h))
        elif op[0] == "streifen":
            v = np.arange(h)[:, None].repeat(w, axis=1)
            br = op[3] if len(op) > 3 else 12
            base = np.where(((v // br) % 2 == 0)[..., None], np.array(op[1], dtype=float), np.array(op[2], dtype=float))
            korn = np.random.default_rng(5).random((h, w))[..., None] * 0.25 + 0.88
            gm.einsetzen(im, F[feld], Image.fromarray(np.clip(base * korn, 0, 255).astype(np.uint8)))
    # Gesicht: erste Quelle für Schläfen, Ohren, Haaransatz; zweite (wenn vorhanden) für die Gesichtsmitte
    gs = spec.get("gesicht", [])
    if gs:
        x0, y0, x1, y1 = F["kopf"]
        W, H = x1 - x0, y1 - y0
        z_von_v = lambda v: KOPF_Z[0] - (v + 0.5) / H * (KOPF_Z[0] - KOPF_Z[1])
        breite = lambda z: kopf_ring(z)[2] / 0.124
        lagen = [gm.projektion(Image.open(g["bild"]).convert("RGB"), W, H, z_von_v, breite, g["cx"], g["R"], g["theta"], g["y"]) for g in gs]
        m = lagen[0]
        if len(lagen) > 1:
            p = lagen[1]
            q = gm.farbe_angleichen(m, p)
            phi = np.abs((np.arange(W) + 0.5) / W - 0.5) * 360
            z = np.array([z_von_v(v) for v in range(H)])
            g = np.clip((50 - phi) / 18, 0, 1)[None, :] * np.clip((gs[1].get("oben", 2.29) - z) / 0.03, 0, 1)[:, None] * (p[..., 3] / 255.0)
            m = gm.ueberblenden(q, p, g)
        m = gm.rand_weich(m, 0.12, 0.04)
        g_im = Image.fromarray(m, "RGBA")
        im.paste(g_im.convert("RGB"), (x0, y0), g_im.split()[3])
    im.save(pfad)
    if glut_pfad:
        # Leuchtkarte: schwarz, dazu Flecken ("auge", Winkel, Höhe, Größe, Farbe) im Kopf-Feld oder ("fleck", Feld, x, y, r, Farbe)
        g = Tafel(1024, F, (0, 0, 0))
        for e in spec.get("glut", []):
            if e[0] == "auge":
                for sgn in (-1, 1):
                    ex, ey = gesicht_px(sgn * e[1], e[2])
                    g.schein("kopf", ex, ey, e[3] * 2.2, e[4], 0.9)
                    g.oval("kopf", ex, ey, e[3], e[3] * 0.6, (255, 255, 255))
            else:
                g.schein(e[1], e[2], e[3], e[4] * 2.0, e[5], 0.9)
                g.oval(e[1], e[2], e[3], e[4] * 0.6, e[4] * 0.6, (255, 255, 255))
        g.fertig(glut_pfad)


# ---------------------------------------------------------------- Körper
def _stab(B, O, bone, teile, feld, mat, n=8, deckel=(False, False), p=2.0, kruemm=0.0):
    """Stabförmiges Ding in der Hand: entlang der Griffachse (in Ruhe nach vorn). kruemm biegt es seitlich (Sichelschwert)."""
    B.loft([{"c": O + Vector((kruemm * max(0.0, d - .3) ** 2, -d, 0)), "a": a, "b": b, "w": {bone: 1}} for d, a, b in teile], n, feld, mat,
           achse=(0, -1, 0), vorn=(1, 0, 0), deckel=deckel, p=p, start=0.0)


def _band(B, pts, breite, quer, uvfeld, w, mat=STOFF):
    """Flaches Band durch Punkte (Bogen, Sehne, Feder)."""
    x0, y0, x1, y1 = uvfeld
    n = len(pts) - 1
    for i in range(n):
        q = []
        for j in (i, i + 1):
            d = (pts[min(j + 1, n)] - pts[max(j - 1, 0)]).normalized()
            s = d.cross(Vector(quer)).normalized() * (breite[j] if isinstance(breite, (list, tuple)) else breite)
            q.append((pts[j] - s, pts[j] + s, j / n))
        B.flaeche([q[0][0], q[0][1], q[1][1], q[1][0]],
                  [(x0 + q[0][2] * (x1 - x0), y0), (x0 + q[0][2] * (x1 - x0), y1), (x0 + q[1][2] * (x1 - x0), y1), (x0 + q[1][2] * (x1 - x0), y0)], w, mat)


def baue(J, spec):
    B = Bau(1024)
    bau = spec.get("bau", {})
    T = spec.get("teile", {})
    ks, kt, kh = bau.get("schulter", 1.0), bau.get("taille", 1.0), bau.get("huefte", 1.0)
    ka, kb = bau.get("arm", 1.0), bau.get("bein", 1.0)
    frau = bau.get("frau", False)
    f_rumpf = F[T.get("rumpf", "rumpf")]
    m_rumpf = METALL if T.get("rumpf_metall") else STOFF

    # --- Rumpf
    rumpf = [(1.20, .150, .150, .215, {"hips": 1}, kh), (1.30, .140, .140, .200, {"hips": .6, "spine": .4}, (kh + kt) / 2), (1.42, .145, .150, .200, {"spine": 1}, kt),
             (1.55, .165, .160, .225, {"spine": .6, "chest": .4}, kt), (1.68, .190 + (.045 if frau else 0), .170, .260, {"chest": 1}, ks),
             (1.80, .185 + (.012 if frau else 0), .170, .280, {"chest": 1}, ks), (1.88, .140, .140, .230, {"chest": 1}, ks), (1.925, .090, .095, .110, {"chest": .7, "head": .3}, 1.0)]
    B.loft([{"c": (0, 0, z), "a": (af * (1 + (k - 1) * .6), ab * (1 + (k - 1) * .6)), "b": b * k, "w": w, "v": 1 - (z - 1.20) / 0.725} for z, af, ab, b, w, k in rumpf], 20, f_rumpf, m_rumpf, p=2.5)
    f_hals = F[T.get("hals", "haut")]
    B.loft([{"c": (0, 0, 1.89), "a": .08, "b": .08, "w": {"chest": 1}}, {"c": (0, -.004, 1.96), "a": .07, "b": .068, "w": {"chest": .5, "head": .5}},
            {"c": (0, -.01, 2.03), "a": .068, "b": .066, "w": {"head": 1}}], 10, f_hals, STOFF)

    # --- Kopf, Nase, Ohren
    zs = [2.00, 2.02, 2.045, 2.07, 2.095, 2.12, 2.15, 2.18, 2.21, 2.24, 2.27, 2.30, 2.33, 2.355, 2.372, 2.384]
    B.loft([{"c": (0, -.012, z), "a": kopf_ring(z)[:2], "b": kopf_ring(z)[2], "w": {"head": 1}, "v": (KOPF_Z[0] - z) / (KOPF_Z[0] - KOPF_Z[1])} for z in zs],
           18, F["kopf"], STOFF, deckel=(False, True), p=2.15)
    n0, n1, n2, n3, n4 = (0, -.142, 2.205), (0, -.180, 2.128), (.024, -.136, 2.118), (-.024, -.136, 2.118), (0, -.138, 2.104)
    kx, ky = F["kopf"][0], F["kopf"][1]

    def nuv(p):
        u, v = gesicht_px(math.degrees(math.atan2(p[0], -p[1])) * 0.6, p[2])
        return (kx + u, ky + v)
    for tri in ((n0, n2, n1), (n0, n1, n3), (n1, n2, n4), (n1, n4, n3)):
        B.flaeche(tri, [nuv(q) for q in tri], {"head": 1}, STOFF)
    haar = T.get("haar", "kurz")
    if haar not in ("nemes", "binden"):
        B.spiegel(lambda b: b.loft([{"c": (.112, .012, 2.165), "a": .034, "b": .02, "w": {"head": 1}}, {"c": (.134, .02, 2.168), "a": .04, "b": .022, "w": {"head": 1}},
                                    {"c": (.142, .026, 2.17), "a": .026, "b": .012, "w": {"head": 1}}], 8, f_hals, STOFF, achse=(1, 0, 0), vorn=(0, 0, 1), deckel=(False, True)))
    # --- Haartracht
    if haar in ("kurz", "zoepfe", "dutt"):
        kappe = []
        for z in (2.30, 2.325, 2.35, 2.37, 2.385, 2.396):
            af, ab, b = kopf_ring(z - 0.012)
            kappe.append({"c": (0, -.012, z), "a": (af + .015, ab + .015), "b": b + .015, "w": {"head": 1}})
        B.loft(kappe, 16, F["haar"], STOFF, deckel=(False, True), p=2.15)
        kranz = []
        for z in (2.075, 2.12, 2.17, 2.22, 2.28):
            af, ab, b = kopf_ring(z)
            kranz.append({"c": (0, -.012, z), "a": (af + .016, ab + .016), "b": b + .016, "w": {"head": 1}})
        if haar == "zoepfe":     # langes Haar bis auf die Schulterblätter
            kranz = [{"c": (0, .03, 1.62), "a": (.13, .20), "b": .19, "w": {"chest": 1}}, {"c": (0, .02, 1.82), "a": (.13, .19), "b": .21, "w": {"chest": .8, "head": .2}},
                     {"c": (0, 0, 1.98), "a": (.12, .15), "b": .15, "w": {"head": .8, "chest": .2}}] + kranz
        B.loft(kranz, 12, F["haar"], STOFF, bogen=(math.radians(78 if haar != "zoepfe" else 70), math.radians(282 if haar != "zoepfe" else 290)), p=2.15)
        if haar == "dutt":
            B.loft([{"c": (0, .15, z), "a": r, "b": r, "w": {"head": 1}} for z, r in ((2.26, .02), (2.29, .07), (2.34, .085), (2.39, .07), (2.42, .02))], 10, F["haar"], STOFF, deckel=(True, True))
    elif haar == "nemes":
        def ring(z, d):
            af, ab, b = kopf_ring(min(z, 2.384))
            return (af + d, ab + d), b + d
        kappe = []
        for z, d in ((2.42, 0.0), (2.40, 0.05), (2.36, 0.032), (2.31, 0.03), (2.27, 0.03)):
            a, b = ring(z, d) if z < 2.41 else ((0.012, 0.012), 0.012)
            kappe.append({"c": (0, -.012, z), "a": a, "b": b, "w": {"head": 1}})
        B.loft(kappe, 20, F["extra"], STOFF, p=2.15)
        seiten = []
        for z, a_, b_ in ((2.27, None, None), (2.18, (.15, .15), .165), (2.08, (.16, .17), .21), (1.98, (.17, .18), .26), (1.90, (.18, .19), .28)):
            if a_ is None:
                a_, b_ = ring(z, 0.03)
            seiten.append({"c": (0, 0.0 if z < 2.2 else -.012, z), "a": a_, "b": b_, "w": {"head": 1.0} if z > 2.1 else {"head": 0.4, "chest": 0.6}})
        B.loft(seiten, 18, F["extra"], STOFF, bogen=(math.radians(62), math.radians(298)), p=2.3)
        B.spiegel(lambda b: b.loft([{"c": (.135, -.075, z), "a": .012, "b": hw, "w": {"head": .3, "chest": .7}} for z, hw in ((2.16, .045), (2.0, .055), (1.86, .06), (1.78, .06))],
                                   6, F["extra"], STOFF, deckel=(False, True), p=4.0))
        B.loft([{"c": (0, -.15, 2.30), "a": .016, "b": .02, "w": {"head": 1}}, {"c": (0, -.165, 2.36), "a": .012, "b": .016, "w": {"head": 1}},
                {"c": (0, -.15, 2.395), "a": .003, "b": .004, "w": {"head": 1}}], 6, F["metall"], METALL, deckel=(True, True))

    # --- Arme
    S, E, W, H = J["upperarm.l"][0], J["lowerarm.l"][0], J["wrist.l"][0], J["hand.l"][0]
    f_arm = F[T.get("oberarm", "haut")]
    f_uarm = F[T.get("unterarm", "haut")]
    f_hand = F[T.get("hand", "haut")]

    def arm(b):
        dx, dz = Vector((1, 0, 0)), Vector((0, 0, 1))
        ob = [(S - dx * .06, .05, .05, {"chest": 1}), (S - dx * .015, .100, .095, {"chest": .6, "upperarm.l": .4}), (S + dx * .03, .112, .105, {"chest": .2, "upperarm.l": .8}),
              (lerp(S, E, .30), .100, .095, {"upperarm.l": 1}), (lerp(S, E, .60), .088, .085, {"upperarm.l": 1}), (lerp(S, E, .87), .074, .072, {"upperarm.l": .85, "lowerarm.l": .15}),
              (E, .068, .068, {"upperarm.l": .5, "lowerarm.l": .5})]
        un = [(E, .068, .068, {"upperarm.l": .5, "lowerarm.l": .5}), (lerp(E, W, .13), .076, .074, {"upperarm.l": .15, "lowerarm.l": .85}), (lerp(E, W, .35), .080, .075, {"lowerarm.l": 1}),
              (lerp(E, W, .70), .064, .060, {"lowerarm.l": 1}), (W, .050, .048, {"lowerarm.l": .5, "wrist.l": .5})]
        b.loft([{"c": c, "a": a * ka, "b": bb * ka, "w": w} for c, a, bb, w in ob], 12, f_arm, STOFF, achse=(1, 0, 0), vorn=(0, 0, 1))
        b.loft([{"c": c, "a": a * ka, "b": bb * ka, "w": w} for c, a, bb, w in un], 12, f_uarm, STOFF, achse=(1, 0, 0), vorn=(0, 0, 1))
        faust = [(W + dx * .02, .045, .050, {"wrist.l": 1}), (H - dx * .02 - dz * .01, .056, .062, {"wrist.l": .5, "hand.l": .5}), (H + dx * .05 - dz * .035, .064, .068, {"hand.l": 1}),
                 (H + dx * .11 - dz * .048, .058, .062, {"hand.l": 1}), (H + dx * .15 - dz * .048, .034, .04, {"hand.l": 1})]
        kf = (1 + ka) / 2
        b.loft([{"c": c, "a": a * kf, "b": bb * kf, "w": w} for c, a, bb, w in faust], 10, f_hand, STOFF, achse=(1, 0, 0), vorn=(0, 0, 1), deckel=(False, True), p=2.6)
        if T.get("schiene"):
            sch = [(.36, .086, .081), (.40, .094, .089), (.55, .086, .080), (.84, .070, .066), (.92, .070, .066), (.94, .060, .056)]
            b.loft([{"c": lerp(E, W, t), "a": a * ka, "b": bb * ka, "w": {"lowerarm.l": 1}} for t, a, bb in sch], 12, F[T["schiene"]], METALL, achse=(1, 0, 0), vorn=(0, 0, 1))
    B.spiegel(arm)

    # --- Beine und Füße
    Hj, K, A, Tz, TT = J["upperleg.l"][0], J["lowerleg.l"][0], J["foot.l"][0], J["toes.l"][0], J["toes.l"][1]
    f_ob = F[T.get("oberschenkel", "haut")]
    f_un = F[T.get("unterschenkel", "bein")]

    def bein(b):
        ob = [(Hj + Vector((0, 0, .06)), (.10, .11), .110, {"hips": .8, "upperleg.l": .2}), (lerp(Hj, K, .12), (.10, .11), .105, {"hips": .2, "upperleg.l": .8}),
              (lerp(Hj, K, .45), (.095, .092), .090, {"upperleg.l": 1}), (lerp(Hj, K, .80), (.072, .074), .070, {"upperleg.l": .85, "lowerleg.l": .15}),
              (K, (.068, .066), .064, {"upperleg.l": .5, "lowerleg.l": .5})]
        b.loft([{"c": c, "a": (a[0] * kb, a[1] * kb), "b": bb * kb, "w": w} for c, a, bb, w in ob], 12, f_ob, STOFF)
        un = [(K, (.068, .066), .064, {"upperleg.l": .5, "lowerleg.l": .5}), (lerp(K, A, .15), (.058, .072), .063, {"upperleg.l": .15, "lowerleg.l": .85}),
              (lerp(K, A, .35), (.055, .086), .066, {"lowerleg.l": 1}), (lerp(K, A, .70), (.046, .058), .050, {"lowerleg.l": 1}),
              (lerp(K, A, .96), (.042, .046), .043, {"lowerleg.l": .7, "foot.l": .3})]
        b.loft([{"c": c, "a": (a[0] * kb, a[1] * kb), "b": bb * kb, "w": w} for c, a, bb, w in un], 12, f_un, STOFF)
        fuss = [(Vector((A.x, A.y + .075, .034)), (.026, .03), .036, {"foot.l": 1}), (Vector((A.x, A.y + .015, .048)), (.062, .044), .050, {"foot.l": 1}),
                (Vector((A.x, lerp(A, Tz, .5).y, .040)), (.044, .036), .056, {"foot.l": 1}), (Vector((Tz.x, Tz.y, .030)), (.027, .026), .063, {"foot.l": .5, "toes.l": .5}),
                (Vector((TT.x, TT.y + .01, .023)), (.019, .020), .056, {"toes.l": 1}), (Vector((TT.x, TT.y - .022, .020)), (.008, .012), .034, {"toes.l": 1})]
        b.loft([{"c": c, "a": a, "b": bb * (1 + kb) / 2, "w": w} for c, a, bb, w in fuss], 10, F["fuss"], STOFF, achse=(0, -1, 0), vorn=(0, 0, 1), deckel=(True, True), p=2.7, start=0.0)
    B.spiegel(bein)

    # --- Rock: jede Länge vom Schurz bis zum Kleid; schwingt mit Ober- und Unterschenkeln
    def rock_w(z, anteil=0.85):
        t = min(1.0, max(0.0, (1.34 - z) / 0.6))
        u = min(1.0, max(0.0, (0.72 - z) / 0.4))

        def w(th):
            L = anteil * t
            sn = math.sin(th)
            l = L * min(1.0, max(0.0, 0.5 + sn * 1.3))
            r = L * min(1.0, max(0.0, 0.5 - sn * 1.3))
            return {"hips": 1 - l - r, "upperleg.l": l * (1 - u), "upperleg.r": r * (1 - u), "lowerleg.l": l * u, "lowerleg.r": r * u}
        return w

    def profil(saum, weit):
        P = [(1.34, .150, .150, .205), (1.24, .180, .190, .245), (1.08, .210, .215, .275), (.90, .235, .235, .295), (.74, .250, .245, .305), (.45, .262, .258, .315), (.14, .285, .28, .335)]
        out = []
        for i, (z, af, ab, b) in enumerate(P):
            if z > saum + .03:
                out.append((z, af, ab, b))
            else:
                (z0, a0, c0, b0) = P[i - 1]
                u = (z0 - saum) / (z0 - z)
                out.append((saum, a0 + (af - a0) * u, c0 + (ab - c0) * u, b0 + (b - b0) * u))
                break
        return [(z, 1 + (af / .15 - 1) * weit, 1 + (ab / .15 - 1) * weit, 1 + (b / .205 - 1) * weit) for z, af, ab, b in out]

    R = T.get("rock")
    if R:
        saum, weit, amp = R.get("saum", .74), R.get("weit", 1.0), R.get("fetzen", .035)
        pr = profil(saum, weit)

        def fetzen(th):
            return -amp * (0.5 + 0.5 * math.sin(th * 7.0) * math.sin(th * 3.0 + 1.0)) - R.get("schraeg", 0.0) * (0.5 + 0.5 * math.sin(th))
        B.loft([dict({"c": (0, 0, z), "a": (.150 * kh * fa, .150 * kh * fb), "b": .205 * kh * fq, "w": rock_w(z), "v": (1.34 - z) / (1.34 - saum)}, **({"dz": fetzen} if i == len(pr) - 1 else {}))
                for i, (z, fa, fb, fq) in enumerate(pr)], 24, F[R.get("feld", "rock")], STOFF)
    Lp = T.get("lasche")
    if Lp:
        saum = Lp.get("saum", .62)
        pl = profil(saum, (R or {}).get("weit", 1.0))
        B.loft([{"c": (0, 0, z - (.01 if i == 0 else 0)), "a": .150 * kh * fa + .02, "b": .205 * kh * fq + .02, "w": rock_w(z, .76), "v": (1.33 - z) / (1.33 - saum)} for i, (z, fa, fb, fq) in enumerate(pl)],
               5, F["lasche"], STOFF, bogen=(-Lp.get("breit", .48), Lp.get("breit", .48)))
    if T.get("guertel"):
        B.loft([{"c": (0, 0, z), "a": a * (kh + kt) / 2, "b": b * (kh + kt) / 2, "w": {"hips": .8, "spine": .2}} for z, a, b in ((1.268, .152, .208), (1.275, .166, .224), (1.35, .162, .220), (1.357, .146, .204))],
               20, F["guertel"], METALL if T["guertel"] == "metall" else STOFF, p=2.5)

    # --- Kragen (Perlenkragen oder Schultertuch)
    if T.get("kragen"):
        kg = T["kragen"] if isinstance(T["kragen"], dict) else {}
        kw = kg.get("weit", 1.0)
        kr = [{"c": (0, 0, 1.965), "a": .085, "b": .085, "v": 0.0}, {"c": (0, 0, 1.94), "a": (.14, .13), "b": .16 * ks, "v": 0.25},
              {"c": (0, 0, 1.87), "a": (.195 * kw, .175 * kw), "b": .265 * ks * kw, "v": 0.6, "dz": lambda th: -0.03 * max(0, math.cos(th)) ** 2 + 0.05 * math.sin(th) ** 2},
              {"c": (0, 0, 1.80), "a": (.232 * kw, .205 * kw), "b": .35 * ks * kw, "v": 1.0, "dz": lambda th: -(0.07 + kg.get("tief", 0)) * max(0, math.cos(th)) ** 2 + 0.118 * math.sin(th) ** 2}]
        for r in kr:
            r["w"] = {"chest": 1.0}
        B.loft(kr, 24, F["kragen"], STOFF)

    # --- Rückentuch oder Umhang
    U = T.get("tuch")
    if U:
        saum = U.get("saum", 1.10)
        um = U.get("umhang", False)
        tz = [(1.885, .155, .20, {"chest": 1}), (1.76, .215, .285 + (.075 if um else 0), {"chest": 1}), (1.52, .205 + (.03 if um else 0), .255 + (.07 if um else 0), {"chest": .5, "spine": .5}),
              (1.30, .215 + (.03 if um else 0), .255 + (.06 if um else 0), {"spine": .5, "hips": .5}), (1.10, .245, .275 + (.05 if um else 0), {"hips": 1})]
        if saum < 1.05:
            tz.append((saum, .27, .30 + (.04 if um else 0), rock_w(saum, .7)))
        else:
            tz[-1] = (saum,) + tz[-1][1:]

        def fz(th):
            return -0.035 * (0.5 + 0.5 * math.sin(th * 7.0) * math.sin(th * 3.0 + 1.0))
        bg = U.get("bogen", (58, 302) if um else (98, 262))
        B.loft([dict({"c": (0, 0, z), "a": (a * ks, a * ks), "b": b * ks, "w": w, "v": (1.885 - z) / (1.885 - saum)}, **({"dz": fz} if i == len(tz) - 1 else {})) for i, (z, a, b, w) in enumerate(tz)],
               12 if um else 9, F["tuch"], STOFF, bogen=(math.radians(bg[0]), math.radians(bg[1])))

    # --- Feder
    fd = T.get("feder")
    if fd == "schulter":
        kiel = [Vector(p) for p in ((-.20, .15, 1.86), (-.25, .18, 2.08), (-.30, .185, 2.28), (-.345, .165, 2.46), (-.375, .11, 2.60), (-.385, .03, 2.70))]
        _band(B, kiel, [.012, .06, .085, .085, .06, .012], (0, 1, 0.25), F["feder"], {"chest": 1})
    elif fd == "kopf":
        kiel = [Vector(p) for p in ((0, .06, 2.37), (0, .10, 2.47), (0, .12, 2.58), (0, .10, 2.68), (0, .04, 2.75))]
        _band(B, kiel, [.01, .045, .06, .05, .01], (0, 1, 0), F["feder"], {"head": 1})

    # --- Laterne an der linken Hüfte
    if T.get("laterne"):
        lw = {"hips": .7, "upperleg.l": .3}
        L = Vector((.30, -.15, 0))
        B.loft([{"c": L + Vector((0, 0, z)), "a": r, "b": r, "w": lw} for z, r in ((.925, .012), (.935, .045), (.955, .052), (.96, .044))], 6, F["metall"], METALL, deckel=(True, False))
        B.loft([{"c": L + Vector((0, 0, z)), "a": .042, "b": .042, "w": lw} for z in (.96, 1.05)], 6, F["glas"], GLUT)
        B.loft([{"c": L + Vector((0, 0, z)), "a": r, "b": r, "w": lw} for z, r in ((1.05, .044), (1.055, .054), (1.08, .034), (1.105, .01))], 6, F["metall"], METALL, deckel=(False, True))
        B.loft([{"c": L + Vector((0, 0, 1.10)), "a": .006, "b": .006, "w": lw}, {"c": (.215, -.10, 1.30), "a": .006, "b": .006, "w": {"hips": 1}}], 4, F["metall"], METALL)

    # --- Köcher auf dem Rücken
    if T.get("koecher"):
        ax = Vector((.35, 0, 1)).normalized()
        B.loft([{"c": Vector((-.02, .21, 1.45)) + ax * d, "a": r, "b": r, "w": {"chest": .7, "spine": .3}, "ax": tuple(ax)} for d, r in ((0, .03), (.02, .06), (.5, .065), (.52, .05))],
               8, F["griff"], STOFF, achse=tuple(ax), vorn=(0, 1, 0), deckel=(True, True))
        for i in range(3):
            p0 = Vector((-.02 + (i - 1) * .025, .21, 1.45)) + ax * .5
            _band(B, [p0, p0 + ax * .16], .018, (0, 1, 0), F["feder"], {"chest": 1})

    # --- Waffe in der rechten Hand
    O = J["handslot.r"][0]
    wf = T.get("waffe")
    if wf == "schwert":
        _stab(B, O, "handslot.r", [(-.37, .012, .012), (-.36, .042, .042), (-.325, .046, .046), (-.30, .024, .024)], F["metall"], METALL, deckel=(True, False))
        _stab(B, O, "handslot.r", [(-.30, .023, .023), (.16, .023, .023)], F["griff"], STOFF)
        _stab(B, O, "handslot.r", [(.16, .03, .03), (.168, .16, .034), (.20, .19, .036), (.215, .21, .026), (.222, .055, .02)], F["metall"], METALL, p=3.0)
        _stab(B, O, "handslot.r", [(.222, .066, .017), (.50, .074, .017), (.95, .088, .016), (1.20, .072, .013), (1.38, .04, .01), (1.50, .004, .003)], F["waffe"], METALL, deckel=(False, True), p=1.15)
    elif wf == "sichel":      # Chepesch: das Sichelschwert
        _stab(B, O, "handslot.r", [(-.16, .02, .02), (.12, .022, .022)], F["griff"], STOFF, deckel=(True, False))
        _stab(B, O, "handslot.r", [(.12, .04, .02), (.2, .035, .014), (.45, .05, .014), (.7, .062, .013), (.9, .05, .011), (1.02, .004, .003)], F["waffe"], METALL, deckel=(False, True), p=1.15, kruemm=.55)
    elif wf == "stab":        # Sternenstab
        _stab(B, O, "handslot.r", [(-.95, .018, .018), (1.15, .02, .02)], F["griff"], STOFF, deckel=(True, False))
        _stab(B, O, "handslot.r", [(1.15, .035, .035), (1.2, .03, .03)], F["metall"], METALL)
        c = O + Vector((0, -1.32, 0))
        for i in range(4):   # Stern aus vier gekreuzten Spitzen
            a = i * math.pi / 4
            d = Vector((math.cos(a), 0, math.sin(a)))
            n = Vector((-math.sin(a), 0, math.cos(a)))
            for sgn in (-1, 1):
                B.flaeche([c + n * .035, c + d * sgn * .17, c - n * .035], [(F["glas"][0] + 20, F["glas"][1] + 60), (F["glas"][0] + 60, F["glas"][1] + 60), (F["glas"][0] + 40, F["glas"][1] + 90)], {"handslot.r": 1}, GLUT)
        B.flaeche([c + Vector((0, -.16, 0)), c + Vector((.04, 0, 0)), c + Vector((0, .0, .04)), c + Vector((-.04, 0, 0))],
                  [(F["glas"][0] + 20, F["glas"][1] + 60)] * 4, {"handslot.r": 1}, GLUT)
    elif wf == "keule":       # Steinkeule des Kolosses
        _stab(B, O, "handslot.r", [(-.3, .03, .03), (.75, .035, .035)], F["griff"], STOFF, deckel=(True, False))
        _stab(B, O, "handslot.r", [(.75, .05, .05), (.82, .15, .15), (1.0, .18, .18), (1.15, .14, .14), (1.22, .03, .03)], F["waffe"], METALL, deckel=(False, True), p=2.6)
    elif wf == "bogen":       # Bogen: steht senkrecht in der Faust, Sehne zur Figur hin
        # (beim Zielen zeigt die Griffachse zum Ziel und die Querachse der Hand nach oben: Dort liegen die Bogenarme)
        pts = [O + Vector((.78 * t, -(.10 - .34 * t * t) - .02, 0)) for t in [i / 8 - 1 for i in range(17)]]
        _band(B, pts, .022, (0, 1, 0), F["griff"], {"handslot.r": 1})
        _band(B, pts, .022, (0, 0, 1), F["griff"], {"handslot.r": 1})
        _band(B, [pts[0], pts[-1]], .004, (0, 0, 1), F["feder"], {"handslot.r": 1})
    # --- Schild am linken Arm
    if T.get("schild"):
        Ol = J["handslot.l"][0]
        # die Fläche steht quer zur Griffachse: so deckt der Schild den Körper, wenn der Arm ihn vor sich hält
        B.loft([{"c": Ol + Vector((0, -d, .05)), "a": rz, "b": rx, "w": {"handslot.l": 1}} for d, rx, rz in ((.03, .02, .03), (.07, .30, .40), (.09, .33, .44), (.11, .30, .40), (.14, .02, .03))],
               14, F[T["schild"]], METALL, achse=(0, -1, 0), vorn=(0, 0, 1), p=2.4)
    return B


def fertige(spec, quelle, ziel, tafel):
    glut_pfad = tafel.replace(".png", "_glut.png") if spec.get("glut") else None
    male(spec, tafel, glut_pfad)
    arm = fabrik.lade_rig(quelle, spec["bewegungen"])
    J = fabrik.umbauen(arm, PLAN, K_WEG, haltung=spec.get("haltung"))
    bild = bpy.data.images.load(tafel)
    gl = bpy.data.images.load(glut_pfad) if glut_pfad else None
    mats = [fabrik.material("stoff", bild, 0.0, 0.85, glut=1.8 if gl else 0.0, glutbild=gl), fabrik.material("bronze", bild, 0.35, 0.6),
            fabrik.material("glut", bild, 0.0, 0.5, glut=1.3)]
    ob = baue(J, spec).mesh(spec["name"], arm, mats)
    fabrik.boden(arm, ob)
    tri = sum(len(p.vertices) - 2 for p in ob.data.polygons)
    fabrik.ausgabe(ziel)
    print("%s: %d Dreiecke, %d Bewegungen, %d KB" % (spec["name"], tri, len(spec["bewegungen"]), os.path.getsize(ziel) // 1024))
