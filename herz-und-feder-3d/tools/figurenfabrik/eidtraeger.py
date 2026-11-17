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
# gemalte Vorlage (Higgsfield-Bogen K11, 2048 Pixel): liefert Schuppen, Kragen, Leinen, Haut und Gesicht
VORLAGE = sys.argv[4] if len(sys.argv) > 4 and not sys.argv[4].startswith("--") else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "bilder", "K11_voll.webp")
PORTRAET = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "ui", "portrait_ermittler.jpg")
# Farbe des Tuchs nach dem Urteil der fünften Stunde: leicht (Lapis und Gold), schwer (Rot der Wüste und Schwarz),
# schwebe (Leinen und Mondsilber)
TUCH = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--tuch=")), "leicht")
TUCH_FARBEN = {"leicht": ((196, 150, 70), (34, 52, 112)), "schwer": ((150, 36, 26), (26, 20, 20)), "schwebe": ((214, 206, 188), (110, 122, 140))}
GESICHT = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--gesicht=")), "mischung")

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
    "nemes": (704, 832, 1024, 1024),
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


def uebermalen():
    """Felder der Tafel aus der gemalten Vorlage füllen (Koordinaten im 2048er Bogen K11)."""
    import gemalt as gm
    from PIL import Image
    if not os.path.exists(VORLAGE):
        print("ohne gemalte Vorlage:", VORLAGE)
        return
    k = Image.open(VORLAGE).convert("RGB")
    t = Image.open(TAFEL).convert("RGB")
    F = FELDER

    def gr(n):
        x0, y0, x1, y1 = F[n]
        return x1 - x0, y1 - y0
    # Schuppenpanzer (Rücken der Rückansicht): eine Schuppe wird im Spiel rund 6 cm groß
    w, h = gr("schuppen")
    gm.einsetzen(t, F["schuppen"], gm.kachel(gm.flach(k.crop((470, 236, 570, 322))), w, h, 128))
    # Perlenkragen: aus dem Bogen um den Hals abgerollt, dann gespiegelt rundherum
    w, h = gr("kragen")
    band = gm.abrollen(k, (520, 75), 86, 158, 64, 116, 256, h)
    gm.einsetzen(t, F["kragen"], gm.kachel(band, w, h))
    # Gürtel und Armschienen
    w, h = gr("guertel")
    gm.einsetzen(t, F["guertel"], gm.kachel(gm.angleichen(gm.flach(k.crop((1420, 365, 1580, 412)), 0.4), 105), w, h, h))
    # Leinenschurz: weiß, gefiedert
    w, h = gr("leinen")
    gm.einsetzen(t, F["leinen"], gm.kachel(gm.flach(k.crop((1495, 650, 1570, 735)), 0.7), w, h, 200))
    # Lasche mit dem Auge des Horus: ganz, wie gemalt
    w, h = gr("schurz")
    gm.einsetzen(t, F["schurz"], k.crop((500, 440, 585, 745)).resize((w, h), Image.LANCZOS))
    # Rückentuch: nachtblau mit Goldfäden
    w, h = gr("tuch")
    gm.einsetzen(t, F["tuch"], gm.kachel(gm.flach(k.crop((1370, 470, 1470, 640))), w, h, 240))
    # Haut, Beinwickel, Haar
    w, h = gr("haut")
    gm.einsetzen(t, F["haut"], gm.haut(k, (600, 215, 622, 245), w, h, 3, 1.1))
    w, h = gr("wickel")
    gm.einsetzen(t, F["wickel"], gm.kachel(gm.flach(k.crop((1505, 790, 1555, 900)), 0.5), w, h, h))
    w, h = gr("haar")
    gm.einsetzen(t, F["haar"], gm.kachel(k.crop((1458, 52, 1515, 80)), w, h, h))
    # Klinge aus der Rückansicht, aufgerichtet: Länge läuft im Feld von oben (Parierstange) nach unten (Spitze),
    # die Breite einmal um die flache Klinge herum (vorn eine Seite, hinten die gespiegelte)
    w, h = gr("klinge")
    kl = k.crop((1600, 470, 1880, 910)).rotate(-25.6, resample=Image.BICUBIC, center=(145, 222)).crop((118, 70, 158, 400))
    kl = gm.angleichen(kl, 120).resize((w // 2, h), Image.LANCZOS)
    band = Image.new("RGB", (w, h))
    band.paste(kl, (0, 0))
    band.paste(kl.transpose(Image.FLIP_LEFT_RIGHT), (w // 2, 0))
    gm.einsetzen(t, F["klinge"], band)
    # Bronze (Parierstange, Knauf, Laterne) aus der Armschiene der Vorderansicht
    w, h = gr("bronze")
    gm.einsetzen(t, F["bronze"], gm.kachel(gm.flach(k.crop((588, 314, 638, 340)), 0.6), w, h, 48))
    # Sandalen: Haut mit Lederriemen
    from PIL import ImageDraw
    w, h = gr("sandale")
    sa = gm.haut(k, (600, 215, 622, 245), w, h, 7, 1.05)
    d = ImageDraw.Draw(sa)
    d.rectangle([32, 0, 96, h], fill=(58, 40, 26))
    for y in (24, 52, 80, 106):
        d.line([(0, y), (w, y - 6)], fill=(70, 48, 30), width=7)
    gm.einsetzen(t, F["sandale"], sa)
    # Gesicht: Halbseite vom Ohr bis zur Nase, gespiegelt; Ohren liegen bei ±90°, Haaransatz bei 2,30 m, Bart unten
    # Kopf zuerst ganz mit Haut aus der Stirn belegen (statt des Orangetons), dann das Gesicht darüber
    w, h = gr("kopf")
    gm.einsetzen(t, F["kopf"], gm.haut(k, (500, 95, 522, 112), w, h, 5, 1.1))
    gesicht_malen(GESICHT, k, t)
    if GESICHT == "nemes":
        # Kopftuch: waagrechte Streifen Lapis und Gold, Korn und Licht aus dem gemalten Rückentuch
        import numpy as np
        w, h = gr("nemes")
        korn = np.asarray(gm.kachel(gm.flach(k.crop((1370, 470, 1470, 640)), 0.9), w, h, 160).convert("L")).astype(np.float32) / 255
        v = np.arange(h)[:, None].repeat(w, axis=1)
        gold = ((v // 12) % 2 == 0)
        hell, dunkel = TUCH_FARBEN[TUCH]
        base = np.where(gold[..., None], np.array(hell, dtype=float), np.array(dunkel, dtype=float))
        f = 0.75 + 0.6 * korn[..., None]
        gm.einsetzen(t, F["nemes"], Image.fromarray(np.clip(base * f, 0, 255).astype(np.uint8)))
    t.save(TAFEL)


def gesicht_malen(art, k, t):
    """Sieben Wege zum Gesicht (siehe WERKSTATT.md, Abschnitt 3b). k: Bogen K11, t: Tafel."""
    import gemalt as gm
    import numpy as np
    from PIL import Image, ImageDraw
    F = FELDER
    x0, y0, x1, y1 = F["kopf"]
    W, H = x1 - x0, y1 - y0
    z_von_v = lambda v: KOPF_Z[0] - (v + 0.5) / H * (KOPF_Z[0] - KOPF_Z[1])
    breite = lambda z: kopf_ring(z)[2] / 0.124
    # K11, Vorderansicht oben links: Kopf um θ = 48° gedreht (aus dem Augenabstand), Mitte x 496, Halbmesser 48 Pixel
    def k11():
        return gm.projektion(k, W, H, z_von_v, breite, 496, 48, 48, [(2.36, 30), (2.30, 47), (2.183, 87.5), (2.07, 120), (2.0, 148)])
    # Porträt der Klassenkarte: fast von vorn (θ ≈ 0), Mitte x 252, Halbmesser 99
    def portraet():
        p = Image.open(PORTRAET).convert("RGB")
        return gm.projektion(p, W, H, z_von_v, breite, 252, 99, 0, [(2.36, 70), (2.30, 95), (2.183, 160), (2.07, 240), (2.0, 300)])

    def setzen(rgba):
        rgba = gm.rand_weich(rgba, 0.12, 0.04)
        im = Image.fromarray(rgba, "RGBA")
        t.paste(im.convert("RGB"), (x0, y0), im.split()[3])

    if art == "spiegel":          # A: Halbgesicht in der Mitte gespiegelt (bisher)
        u0, v0 = gesicht_px(-95, 2.315)
        u1, v1 = gesicht_px(95, 1.99)
        fl = gm.gesicht(k, (455, 42, 0, 150), 531, int(u1 - u0), int(v1 - v0))
        gm.einsetzen(t, F["kopf"], fl, (int(u0), int(v0)), 0.3)
    elif art == "dreiviertel":    # B: 3/4-Spiegelung (Polycount): Achse seitlich versetzt, Nase und ein Auge bleiben einmalig
        u0, v0 = gesicht_px(-95, 2.315)
        u1, v1 = gesicht_px(95, 1.99)
        wv, hv = int(u1 - u0), int(v1 - v0)
        halb = k.crop((455, 42, 547, 150))                      # Ohr bis hinter die Nase (φ −90° … +20°)
        rest = k.crop((455, 42, 517, 150)).transpose(Image.FLIP_LEFT_RIGHT)   # Gegenseite aus der nahen Wange
        voll = Image.new("RGB", (halb.width + rest.width, halb.height))
        voll.paste(halb, (0, 0))
        voll.paste(rest, (halb.width, 0))
        gm.einsetzen(t, F["kopf"], voll.resize((wv, hv), Image.LANCZOS), (int(u0), int(v0)), 0.3)
    elif art == "projektion":     # C: Projektionsmalerei aus der Blickrichtung des Malers, Rückseite gespiegelt
        setzen(k11())
    elif art == "portraet":       # D: zweite Quelle: das Porträt der Klassenkarte, frontal projiziert
        setzen(portraet())
    elif art in ("mischung", "nemes"):       # E (und G mit Kopftuch): Ansichten verschmelzen (Vorder- und Seitenfoto): Gesicht aus dem Porträt, Ohren und Haar aus K11
        p = portraet()
        q = gm.farbe_angleichen(k11(), p)
        phi = np.abs((np.arange(W) + 0.5) / W - 0.5) * 360
        z = np.array([z_von_v(v) for v in range(H)])
        quer = np.clip((50 - phi) / 18, 0, 1)[None, :]      # Schläfen schon aus K11: dort fällt im Porträt Mondlicht blau aufs Haar
        hoch = np.clip((2.29 - z) / 0.03, 0, 1)[:, None]      # über dem Haaransatz zeigt das Porträt Nachthimmel: dort K11
        g = quer * hoch * (p[..., 3] / 255.0)
        setzen(gm.ueberblenden(q, p, g))
    elif art == "gemalt":   # F: Projektion, dann für die Spielentfernung vereinfacht und mit Kajal nachgezogen
        m = k11()
        rgb = gm.vereinfachen(Image.fromarray(m[..., :3]), 3, 32)
        d = ImageDraw.Draw(rgb)
        for sgn in (-1, 1):
            ex, ey = gesicht_px(sgn * 27, 2.183)
            d.line([(ex - sgn * 15, ey + 2), (ex, ey - 2), (ex + sgn * 14, ey), (ex + sgn * 28, ey - 3)], fill=(22, 15, 10), width=3)   # Kajal
            d.line([(ex - sgn * 17, ey - 14), (ex, ey - 19), (ex + sgn * 20, ey - 13)], fill=(78, 74, 70), width=5)                   # Braue
        m = np.dstack([np.asarray(rgb), m[..., 3]]).astype(np.uint8)
        setzen(m)
    else:
        raise SystemExit("unbekannte Gesichtsart: " + art)


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
    # die Nase holt ihre Farbe aus dem gemalten Gesicht, genau von der Stelle, über der sie sitzt
    kx, ky = F["kopf"][0], F["kopf"][1]
    def nuv(p):
        u, v = gesicht_px(math.degrees(math.atan2(p[0], -p[1])) * 0.6, p[2])
        return (kx + u, ky + v)
    for tri in ((n0, n2, n1), (n0, n1, n3), (n1, n2, n4), (n1, n4, n3)):
        B.flaeche(tri, [nuv(q) for q in tri], {"head": 1}, STOFF)
    B.spiegel(lambda b: b.loft([{"c": (.112, .012, 2.165), "a": .034, "b": .02, "w": {"head": 1}}, {"c": (.134, .02, 2.168), "a": .04, "b": .022, "w": {"head": 1}},
                                {"c": (.142, .026, 2.17), "a": .026, "b": .012, "w": {"head": 1}}], 8, F["haut"], STOFF, achse=(1, 0, 0), vorn=(0, 0, 1), deckel=(False, True)))
    # Haar: Kappe oben, Kranz hinten und an den Seiten
    kappe = []
    for z in (2.30, 2.325, 2.35, 2.37, 2.385, 2.396):     # die Kopfform, etwas angehoben: rund, ohne Spitze
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

    # --- Nemes (Kopftuch der Könige), nur in der Variante „nemes“: liegt über dem Haar, fällt hinter den Ohren auf die
    # Schultern, vorn zwei Laschen; beschattet Stirn und Augen wie die Kapuzen bei Diablo
    if GESICHT == "nemes":
        def ring(z, d):
            af, ab, b = kopf_ring(min(z, 2.384))
            return (af + d, ab + d), b + d
        kappe = []
        for z, d in ((2.42, 0.0), (2.40, 0.05), (2.36, 0.032), (2.31, 0.03), (2.27, 0.03)):
            a, b = ring(z, d) if z < 2.41 else ((0.012, 0.012), 0.012)
            kappe.append({"c": (0, -.012, z), "a": a, "b": b, "w": {"head": 1}})
        B.loft(kappe, 20, F["nemes"], STOFF, p=2.15)
        def nw(z):
            return {"head": 1.0} if z > 2.1 else {"head": 0.4, "chest": 0.6}
        seiten = []
        for z, a_, b_ in ((2.27, None, None), (2.18, (.15, .15), .165), (2.08, (.16, .17), .21), (1.98, (.17, .18), .26), (1.90, (.18, .19), .28)):
            if a_ is None:
                a_, b_ = ring(z, 0.03)
            seiten.append({"c": (0, 0.0 if z < 2.2 else -.012, z), "a": a_, "b": b_, "w": nw(z)})
        B.loft(seiten, 18, F["nemes"], STOFF, bogen=(math.radians(62), math.radians(298)), p=2.3)
        def lasche(b):
            for x0 in (.135,):
                pts = [(2.16, .045), (2.0, .055), (1.86, .06), (1.78, .06)]
                b.loft([{"c": (x0, -.075, z), "a": .012, "b": hw, "w": {"head": .3, "chest": .7}, "ax": (0, 0, 1), "vorn": (0, -1, 0)} for z, hw in pts],
                       6, F["nemes"], STOFF, achse=(0, 0, 1), vorn=(0, -1, 0), deckel=(False, True), p=4.0)
        B.spiegel(lasche)
        # Uräus: die aufgerichtete Kobra über der Stirn
        B.loft([{"c": (0, -.15, 2.30), "a": .016, "b": .02, "w": {"head": 1}}, {"c": (0, -.165, 2.36), "a": .012, "b": .016, "w": {"head": 1}},
                {"c": (0, -.15, 2.395), "a": .003, "b": .004, "w": {"head": 1}}], 6, F["bronze"], METALL, deckel=(True, True))

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
if "--ohne-vorlage" not in sys.argv:
    uebermalen()
arm = fabrik.lade_rig(QUELLE, BEWEGUNGEN)
J = fabrik.umbauen(arm, PLAN, K_WEG)
bild = bpy.data.images.load(TAFEL)
# Die Malerei bringt ihr Licht schon mit: Metall nur wenig spiegeln lassen, sonst glänzt es doppelt
mats = [fabrik.material("stoff", bild, 0.0, 0.85), fabrik.material("bronze", bild, 0.35, 0.6), fabrik.material("glut", bild, 0.0, 0.5, glut=1.3)]
ob = baue(J).mesh("Eidtraeger", arm, mats)
fabrik.boden(arm, ob)
print("Punkte", len(ob.data.vertices), "Dreiecke", sum(len(p.vertices) - 2 for p in ob.data.polygons))
fabrik.ausgabe(ZIEL)
print("geschrieben", ZIEL, os.path.getsize(ZIEL) // 1024, "KB")
