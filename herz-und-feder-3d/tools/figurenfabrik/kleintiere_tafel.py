# SPDX-License-Identifier: GPL-3.0-or-later (Teil der Figurenfabrik; siehe LIZENZ.md)
"""Gemeinsame Farbtafel der Kleintiere und Vögel (Fassung 4.3): models/tiere/tiere_tafel.webp, 1024 × 1024.

Jedes Tier hat ein Feld. Ein Feld zeigt das Tier so, wie das Netz es abgreift (scripts/former.gd › uv_von):
von oben (Eidechse, Käfer, Maus, Vögel im Flug: oben die Schnauze, Mitte der Rücken) oder von der Seite (Fische,
Vierbeiner, sitzende Vögel: links der Kopf, oben der Rücken). Die Lagen der Körperteile im Feld (wo der Kopf aufhört,
wo der Schwanz beginnt) stehen in MASSE und müssen zu den Maßen in scripts/tiere.gd passen.

Gemalt wird mit Formeln: Grundfarbe, Zeichnung (Bänder, Flecken, Federreihen), darüber feines Korn (Schuppen, Haare).
Liegt unter bilder/lebewesen/ eine Musterkachel aus ComfyUI (Liste: tools/bildwerk/wunsch_lebewesen.md), ersetzt sie
das gerechnete Korn des Feldes: Die Zeichnung bleibt, die Oberfläche kommt aus dem Bild. Fehlt sie, bleibt die Formel.

Aufruf:  python3 tools/figurenfabrik/kleintiere_tafel.py [Zieldatei]
"""
import math
import os
import sys
import numpy as np
from PIL import Image

HIER = os.path.dirname(os.path.abspath(__file__))
WURZEL = os.path.normpath(os.path.join(HIER, "..", ".."))
MUSTER = os.path.join(WURZEL, "bilder", "lebewesen")
GR = 1024
rng = np.random.default_rng(7)

# Felder in Bildpunkten (x, y, Breite, Höhe); dieselben Rechtecke (geteilt durch 1024) stehen in tiere.gd › FELD
FELDER = {
    "eidechse": (0, 0, 256, 512),
    "kaefer": (256, 0, 256, 256),
    "kugel": (512, 0, 128, 128),
    "schwarzkaefer": (640, 0, 128, 128),
    "maus": (256, 256, 256, 256),
    "falke_flug": (512, 128, 512, 256),
    "falke_sitz": (768, 0, 256, 128),
    "ibis_flug": (512, 384, 512, 256),
    "ibis_steh": (0, 512, 256, 256),
    "wiedehopf": (256, 512, 256, 256),
    "fisch": (512, 640, 256, 128),
    "fledermaus": (768, 640, 256, 128),
    "esel": (0, 768, 256, 256),
    "schaf": (256, 768, 256, 128),
    "ziege": (256, 896, 256, 128),
    "katze": (512, 768, 256, 256),
    "frei": (768, 768, 256, 256),
}


def farbe(h):
    """'#rrggbb' → Array"""
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], np.float32)


def glatt(feld, r=1):
    """weiches Rauschen: Mittelwert über Nachbarn"""
    a = feld.copy()
    for _ in range(r):
        a = (a + np.roll(a, 1, 0) + np.roll(a, -1, 0) + np.roll(a, 1, 1) + np.roll(a, -1, 1)) / 5.0
    return a


def rauschen(h, w, skala, keim):
    """mehrstufiges Wertrauschen 0 … 1 in der Größe h × w"""
    g = np.random.default_rng(keim)
    aus = np.zeros((h, w), np.float32)
    amp, summe = 1.0, 0.0
    for o in range(4):
        n = max(2, int(skala * (2 ** o)))
        klein = g.random((n + 1, n + 1)).astype(np.float32)
        bild = np.asarray(Image.fromarray((klein * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)).astype(np.float32) / 255.0
        aus += bild * amp
        summe += amp
        amp *= 0.5
    return aus / summe


def schuppen(h, w, groesse, keim, versatz=True):
    """Schuppenkorn: Zellen in versetzten Reihen, jede Zelle zur Mitte heller (gewölbt), Fugen dunkel. 0 … 1"""
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    zeile = np.floor(yy / groesse)
    x2 = xx / groesse + (0.5 * (zeile % 2) if versatz else 0)
    fx = x2 - np.floor(x2) - 0.5
    fy = yy / groesse - zeile - 0.5
    d = np.sqrt(fx * fx * 1.0 + fy * fy * 1.3)
    zelle = np.clip(1.0 - d * 1.6, 0, 1)
    g = np.random.default_rng(keim)
    streu = g.random((int(h / groesse) + 2, int(w / groesse) + 3)).astype(np.float32)
    s = streu[zeile.astype(int), np.floor(x2).astype(int)]
    return np.clip(0.55 + 0.45 * zelle - 0.15 * s, 0, 1)


def muster(name, h, w):
    """Musterkachel aus ComfyUI (bilder/lebewesen/<name>.webp|png) als Helligkeit 0 … 1 um 0,5, sonst None"""
    for end in (".webp", ".png", ".jpg"):
        p = os.path.join(MUSTER, name + end)
        if os.path.exists(p):
            im = Image.open(p).convert("L")
            # kacheln statt strecken: die Kachel behält ihr Maß
            k = np.asarray(im.resize((max(32, im.width // 4), max(32, im.height // 4)), Image.LANCZOS)).astype(np.float32) / 255.0
            reps = (h // k.shape[0] + 1, w // k.shape[1] + 1)
            k = np.tile(k, reps)[:h, :w]
            return 0.5 + (k - k.mean()) * 0.9
    return None


# Musterkacheln aus ComfyUI je Feld (tools/bildwerk/wunsch_lebewesen.md); die Eidechse nimmt ihre eigene schon beim Malen
FELD_MUSTER = {"kaefer": "kaefer_panzer", "schwarzkaefer": "schwarzkaefer_panzer", "maus": "maus_fell", "falke_flug": "falke_gefieder",
               "ibis_steh": "ibis_gefieder", "ibis_flug": "ibis_gefieder", "fisch": "fisch_schuppen", "esel": "esel_fell",
               "schaf": "schaf_vlies", "ziege": "ziege_fell", "katze": "katze_fell"}


class Tafel:
    def __init__(self):
        self.bild = np.zeros((GR, GR, 3), np.float32) + 120

    def setz(self, name, arr):
        x, y, w, h = FELDER[name]
        m = muster(FELD_MUSTER[name], h, w) if name in FELD_MUSTER else None
        if m is not None:
            arr = arr * (0.78 + 0.44 * m)[..., None]
        self.bild[y:y + h, x:x + w] = np.clip(arr, 0, 255)

    def raster(self, name):
        """normierte Koordinaten des Feldes: u 0 … 1 (quer), v 0 … 1 (vorn → hinten bzw. oben → unten)"""
        x, y, w, h = FELDER[name]
        vv, uu = np.mgrid[0:h, 0:w].astype(np.float32)
        return (uu + 0.5) / w, (vv + 0.5) / h, h, w


def mischen(a, b, t):
    t = np.clip(t, 0, 1)[..., None] if np.ndim(t) == 2 else t
    return a * (1 - t) + b * t


def glocke(x, mitte, breite):
    return np.exp(-((x - mitte) / breite) ** 2)


# ---------------------------------------------------------------- Eidechse (Dornschwanzagame, von oben)
# Maße wie in tiere.gd › _eidechse: x −0,16 … 0,16, z +0,22 (Schnauze) … −0,50 (Schwanzspitze)
def eidechse(T):
    u, v, h, w = T.raster("eidechse")
    X = (u - 0.5) * 0.32
    Z = 0.22 - v * 0.72
    zs = [0.21, 0.19, 0.15, 0.125, 0.1, 0.065, 0.025, -0.025, -0.075, -0.115, -0.145, -0.25, -0.4, -0.5]
    rs = [0.008, 0.026, 0.039, 0.035, 0.045, 0.062, 0.073, 0.076, 0.069, 0.055, 0.042, 0.03, 0.014, 0.002]
    breite = np.interp(-Z, [-z for z in zs], rs)
    quer = np.clip(np.abs(X) / np.maximum(breite, 0.003), 0, 2.0)   # 0 Rückenmitte, 1 Flanke
    oliv = farbe("#6e6142")
    dunkel = farbe("#3b3122")
    ocker = farbe("#b39160")
    grau = farbe("#857a68")
    a = np.zeros((h, w, 3), np.float32) + oliv
    rumpf = (Z < 0.12) & (Z > -0.15)
    schw = Z <= -0.15
    kopf = Z >= 0.115
    # Rücken: Netz aus ockergelben Tupfen in Querreihen, dazwischen dunkle Maschen
    g = np.random.default_rng(4)
    tupf = np.zeros((h, w), np.float32)
    for zz in np.arange(0.11, -0.15, -0.019):
        n = 5 if abs(zz) < 0.08 else 4
        for k in range(n):
            px = (k - (n - 1) / 2) * 0.026 + g.uniform(-0.004, 0.004)
            pz = zz + g.uniform(-0.004, 0.004) + (0.009 if k % 2 else 0)
            tupf += glocke(X, px, 0.006) * glocke(Z, pz, 0.0055)
    tupf = np.clip(tupf, 0, 1) * rumpf
    a = mischen(a, dunkel, np.clip(0.55 - tupf, 0, 1) * rumpf * 0.5)
    a = mischen(a, ocker, tupf * 0.7)
    # Flanken: heller, grauer, Falte der Haut
    a = mischen(a, grau, np.clip(quer - 0.55, 0, 1) * 0.9)
    # Schwanz: Dornenringe dunkel und hell im Wechsel (wie die Wülste im Netz, Abstand 0,0215)
    ring = 0.5 + 0.5 * np.sin((-0.165 - Z) / 0.043 * 2 * np.pi + 1.2)
    a = mischen(a, mischen(dunkel, ocker, 0.25), schw * ring * 0.75)
    a = mischen(a, grau * 1.1, schw * (1 - ring) * 0.35)
    # Kopf: graubraun, feine helle Körnchen
    a = mischen(a, mischen(grau, oliv, 0.5), kopf * 0.8)
    # Beine (außerhalb des Leibes): grau-oliv mit Tupfen
    a[quer > 1.02] = mischen(grau, oliv, 0.6) * 0.85
    korn = schuppen(h, w, 3.0, 11)
    m = muster("eidechse_schuppen", h, w)
    if m is not None:
        korn = m
    a *= (0.75 + 0.32 * korn)[..., None]
    a *= (0.9 + 0.2 * rauschen(h, w, 6, 5))[..., None]
    T.setz("eidechse", a)


# ---------------------------------------------------------------- Skarabäus und Schwarzkäfer (von oben)
# Maße wie in tiere.gd › _kaefer: x −0,1 … 0,1, z +0,11 … −0,11
def kaefer(T, name="kaefer", schwarz=False):
    u, v, h, w = T.raster(name)
    X = (u - 0.5) * 0.2
    Z = 0.11 - v * 0.22
    a = np.zeros((h, w, 3), np.float32) + (farbe("#17150f") if not schwarz else farbe("#1b1a18"))
    if not schwarz:
        # Flügeldecken: sechs Längsrillen je Seite, Naht in der Mitte, Rand etwas heller (Glanz macht der Shader)
        decken = ((X / 0.045) ** 2 + ((Z + 0.034) / 0.056) ** 2) < 1.0
        rille = np.abs(np.sin(X / 0.045 * np.pi * 6.5)) ** 8
        a = mischen(a, farbe("#2c2a20"), decken * (1 - rille) * 0.5)
        naht = glocke(X, 0, 0.0012) * decken
        a = mischen(a, farbe("#050505"), naht)
        # Halsschild: feine Körnung
        hals = (((X / 0.05) ** 2 + ((Z - 0.026) / 0.03) ** 2) < 1.0) & ~decken
        a = mischen(a, farbe("#26231b"), hals * rauschen(h, w, 30, 8) * 0.9)
        # Kopfschild: Strahlen von der Mitte zu den Zacken
        kopf = (Z > 0.045)
        winkel = np.arctan2(X, Z - 0.062)
        strahl = np.abs(np.sin(winkel * 6.0)) ** 6
        a = mischen(a, farbe("#2e2a20"), kopf * strahl * 0.6)
    else:
        # Schwarzkäfer: matte Decken mit Reihen kleiner Höcker
        hoeck = schuppen(h, w, 6.0, 21)
        a *= (0.7 + 0.6 * hoeck)[..., None]
    a *= (0.9 + 0.2 * rauschen(h, w, 12, 9))[..., None]
    T.setz(name, a)


def kugel(T):
    u, v, h, w = T.raster("kugel")
    a = np.zeros((h, w, 3), np.float32) + farbe("#6a5032")
    faser = rauschen(h, w, 20, 31)
    a = mischen(a, farbe("#8f7448"), np.clip(faser - 0.5, 0, 1) * 1.6)
    a = mischen(a, farbe("#3a2a1a"), np.clip(0.45 - faser, 0, 1) * 1.6)
    T.setz("kugel", a)


# ---------------------------------------------------------------- Falke (Lannerfalke: der Vogel des Horus)
# Flug, von oben: x −0,52 … 0,52, z +0,21 … −0,31. Oberseite schiefergrau-braun mit dunkler Bänderung, Handschwingen
# dunkler, rostroter Nacken, Schwanz grau gebändert. Die helle Unterseite färbt der Shader.
def falke_flug(T):
    u, v, h, w = T.raster("falke_flug")
    X = (u - 0.5) * 1.04
    Z = 0.21 - v * 0.52
    AX = np.abs(X)
    schiefer = farbe("#6a6258")
    dunkel = farbe("#3a332c")
    rost = farbe("#9a6a44")
    a = np.zeros((h, w, 3), np.float32) + schiefer
    # Federreihen: Deckfedern als Schuppen nahe am Leib, Schwingen als lange Streifen nach außen-hinten
    deck = (AX < 0.27) & (Z > -0.02)
    schuppe = schuppen(h, w, 7.0, 41)
    a *= (0.8 + 0.3 * np.where(deck, schuppe, 0.7))[..., None]
    schwinge = (AX > 0.05) & ~deck
    strich = 0.5 + 0.5 * np.sin((AX * 70.0 + Z * 30.0))
    a = mischen(a, dunkel, schwinge * strich * 0.35)
    # Handschwingen dunkel
    a = mischen(a, dunkel * 0.9, np.clip((AX - 0.3) / 0.12, 0, 1) * 0.85)
    # Querbänder auf den Armschwingen
    band = np.clip(np.sin(Z * 120.0) * 2 - 1.2, 0, 1) * (AX > 0.05) * (AX < 0.3)
    a = mischen(a, dunkel, band * 0.3)
    # Kopf: rostroter Nacken, dunkle Stirn
    kopf = (Z > 0.1) & (AX < 0.05)
    a = mischen(a, rost, kopf * np.clip((0.165 - Z) / 0.05, 0, 1) * 0.8)
    a = mischen(a, dunkel, kopf * np.clip((Z - 0.16) / 0.02, 0, 1) * 0.8)
    # Schwanz: grau mit schmalen dunklen Bändern, helle Spitze
    schw = (Z < -0.1) & (AX < 0.05)
    a = mischen(a, dunkel, schw * np.clip(np.sin(Z * 95.0) * 2 - 1.1, 0, 1) * 0.7)
    a = mischen(a, farbe("#c8bca8"), schw * np.clip((-0.285 - Z) / 0.01, 0, 1) * 0.8)
    a *= (0.92 + 0.16 * rauschen(h, w, 10, 42))[..., None]
    T.setz("falke_flug", a)


# Falke sitzend, von der Seite: linke Hälfte Leib und Kopf (z +0,10 … −0,18, y 0,48 … 0), rechte Hälfte die angelegten Flügel
def falke_sitz(T):
    x0, y0, w0, h0 = FELDER["falke_sitz"]
    h, w = h0, w0 // 2
    vv, uu = np.mgrid[0:h, 0:w].astype(np.float32)
    Z = 0.1 - (uu + 0.5) / w * 0.28
    Y = 0.48 - (vv + 0.5) / h * 0.48
    creme = farbe("#cbbd9f")
    dunkel = farbe("#2e2822")
    schiefer = farbe("#5e574e")
    rost = farbe("#a0704a")
    a = np.zeros((h, w, 3), np.float32) + creme
    # Brust: cremefarben mit dunklen Tropfen
    zufall = np.random.default_rng(12)
    tropfen = np.zeros((h, w), np.float32)
    for _ in range(60):
        pz, py = zufall.uniform(-0.05, 0.09), zufall.uniform(0.12, 0.32)
        tropfen += glocke(Z, pz, 0.005) * glocke(Y, py, 0.009)
    a = mischen(a, mischen(dunkel, rost, 0.4), np.clip(tropfen, 0, 1) * 0.75)
    # Rücken und Bürzel (hinten) schiefergrau
    a = mischen(a, schiefer, np.clip((-0.01 - Z) / 0.03, 0, 1))
    # Kopf: dunkle Kappe, rostiger Nacken, dunkler Bartstreif unter dem Auge, helle Wange
    kopf = Y > 0.335
    a = mischen(a, creme * 1.05, kopf * 0.6)
    a = mischen(a, rost, kopf * np.clip((Y - 0.385) / 0.02, 0, 1) * np.clip((0.02 - Z) / 0.03, 0, 1))
    a = mischen(a, dunkel, kopf * np.clip((Y - 0.405) / 0.01, 0, 1) * np.clip((Z + 0.01) / 0.02, 0, 1))
    bart = glocke(Z, 0.045, 0.012) * glocke(Y, 0.36, 0.025)
    a = mischen(a, dunkel, np.clip(bart * 1.3, 0, 1))
    # Schwanz unten: grau gebändert
    schw = Y < 0.07
    a = mischen(a, schiefer, schw * 0.8)
    a = mischen(a, dunkel, schw * np.clip(np.sin(Y * 110) * 2 - 1, 0, 1) * 0.6)
    a *= (0.92 + 0.16 * rauschen(h, w, 10, 43))[..., None]
    T.bild[y0:y0 + h, x0:x0 + w] = np.clip(a, 0, 255)
    # Flügel: schiefergrau, Deckfedern als Schuppen oben, Schwingen als Streifen unten, Spitzen dunkel
    f = np.zeros((h, w, 3), np.float32) + schiefer
    f *= (0.78 + 0.3 * schuppen(h, w, 6.0, 44))[..., None]
    streif = 0.5 + 0.5 * np.sin(Z * 160 + Y * 40)
    f = mischen(f, dunkel, (Y < 0.2) * streif * 0.4)
    f = mischen(f, dunkel, np.clip((0.12 - Y) / 0.06, 0, 1) * 0.7)
    T.bild[y0:y0 + h, x0 + w:x0 + 2 * w] = np.clip(f, 0, 255)


# ---------------------------------------------------------------- Wüstenrennmaus (von oben)
# x −0,06 … 0,06, z +0,09 … −0,21: sandfarbener Rücken mit dunklerem Aalstrich, helle Flanken, Quaste dunkel
def maus(T):
    u, v, h, w = T.raster("maus")
    X = (u - 0.5) * 0.12
    Z = 0.09 - v * 0.3
    a = np.zeros((h, w, 3), np.float32) + farbe("#a8804e")
    a = mischen(a, farbe("#7a5a36"), glocke(X, 0, 0.012) * (Z > -0.08) * 0.6)
    a = mischen(a, farbe("#d2b68a"), np.clip((np.abs(X) - 0.022) / 0.012, 0, 1) * 0.8)
    a = mischen(a, farbe("#c4a272"), (Z > 0.035) * 0.4)
    a = mischen(a, farbe("#3e2c1c"), (Z < -0.17) * 0.85)
    haar = rauschen(h, w, 40, 51)
    a *= (0.85 + 0.25 * haar)[..., None]
    T.setz("maus", a)


# ---------------------------------------------------------------- Ibis stehend (von der Seite) und im Flug (von oben)
# stehend: z +0,33 … −0,27, y 0,64 … 0 — weißer Leib, Hals und Kopf schwarz, Schmuckfedern schwarz
def ibis_steh(T):
    u, v, h, w = T.raster("ibis_steh")
    Z = 0.33 - u * 0.6
    Y = 0.64 - v * 0.64
    weiss = farbe("#e6e0d2")
    schwarz = farbe("#1e1c1b")
    a = np.zeros((h, w, 3), np.float32) + weiss
    a *= (0.88 + 0.14 * schuppen(h, w, 5.0, 61))[..., None]
    a = mischen(a, schwarz, (Y > 0.405) * 1.0)
    a = mischen(a, schwarz, np.clip((-0.1 - Z) / 0.03, 0, 1) * (Y < 0.38))
    a = mischen(a, schwarz, (Y < 0.3) * 1.0)
    a *= (0.94 + 0.1 * rauschen(h, w, 8, 62))[..., None]
    T.setz("ibis_steh", a)


# im Flug: x −0,56 … 0,56, z +0,50 … −0,36 — Flügel weiß, die Spitzen (Hinterrand der Hand) schwarz
def ibis_flug(T):
    u, v, h, w = T.raster("ibis_flug")
    X = (u - 0.5) * 1.12
    Z = 0.5 - v * 0.86
    AX = np.abs(X)
    weiss = farbe("#e8e2d4")
    schwarz = farbe("#1e1c1b")
    a = np.zeros((h, w, 3), np.float32) + weiss
    a *= (0.86 + 0.16 * schuppen(h, w, 6.0, 63))[..., None]
    strich = 0.5 + 0.5 * np.sin(AX * 90.0 + Z * 20.0)
    a *= (0.92 + 0.08 * strich * (AX > 0.06))[..., None]
    spitze = np.clip((AX - 0.42) / 0.05, 0, 1) * np.clip((0.02 - Z) / 0.04 + 0.6, 0, 1)
    a = mischen(a, schwarz, spitze)
    a = mischen(a, schwarz, (Z > 0.1) * (AX < 0.04) * 1.0)
    a = mischen(a, schwarz, (Z < -0.2) * (AX < 0.04) * 0.9)
    T.setz("ibis_flug", a)


# ---------------------------------------------------------------- Nilbuntbarsch (von der Seite): z +0,12 … −0,15, y 0,08 … −0,08
def fisch(T):
    u, v, h, w = T.raster("fisch")
    Z = 0.12 - u * 0.27
    Y = 0.08 - v * 0.16
    a = np.zeros((h, w, 3), np.float32) + farbe("#7d8a7c")
    a = mischen(a, farbe("#4a5a52"), np.clip(Y / 0.05, 0, 1) * 0.8)
    a = mischen(a, farbe("#c9b48a"), np.clip(-Y / 0.04, 0, 1) * 0.7)
    a = mischen(a, farbe("#b0684a"), np.clip((-Y - 0.03) / 0.02, 0, 1) * 0.6)
    balken = np.clip(np.sin(Z * 95.0) * 2 - 1.2, 0, 1) * (Z < 0.07) * (Z > -0.08)
    a = mischen(a, farbe("#3c4842"), balken * 0.45)
    a *= (0.82 + 0.25 * schuppen(h, w, 4.0, 71))[..., None]
    a = mischen(a, farbe("#5e8a86"), glocke(Y, 0.01, 0.012) * 0.25)
    T.setz("fisch", a)


# ---------------------------------------------------------------- Grabfledermaus (von oben): x −0,2 … 0,2, z +0,08 … −0,08
def fledermaus(T):
    u, v, h, w = T.raster("fledermaus")
    X = (u - 0.5) * 0.4
    a = np.zeros((h, w, 3), np.float32) + farbe("#3a2e28")
    finger = np.abs(np.sin(np.arctan2(v - 0.3, np.abs(X) * 3) * 5.0)) ** 20
    a = mischen(a, farbe("#1c1614"), finger * (np.abs(X) > 0.03) * 0.6)
    a = mischen(a, farbe("#7a6450"), (np.abs(X) < 0.022) * 0.8)
    a *= (0.88 + 0.2 * rauschen(h, w, 20, 81))[..., None]
    T.setz("fledermaus", a)


# ---------------------------------------------------------------- Vierbeiner (von der Seite)
# Dieselben Maße wie tiere.gd › VIER; daraus wird die Lage von Rumpf, Hals, Kopf und Beinen im Feld berechnet.
VIER = {
    "esel": dict(rumpf=(0.44, 0.2, 0.23), bein=0.58, hals=(0.38, 0.14, 0.5), kopf=(0.38, 0.09, 0.12), schwanz=0.42),
    "schaf": dict(rumpf=(0.36, 0.22, 0.22), bein=0.42, hals=(0.24, 0.1, 0.32), kopf=(0.24, 0.06, 0.075), schwanz=0.2),
    "ziege": dict(rumpf=(0.33, 0.15, 0.17), bein=0.46, hals=(0.26, 0.08, 0.4), kopf=(0.24, 0.055, 0.07), schwanz=0.09),
    "katze": dict(rumpf=(0.22, 0.08, 0.09), bein=0.24, hals=(0.1, 0.05, 0.3), kopf=(0.11, 0.065, 0.058), schwanz=0.34),
}


def vier_raster(T, name):
    V = VIER[name]
    rl, rb, rh = V["rumpf"]
    bl = V["bein"]
    hl = V["hals"][0]
    kl = V["kopf"][0]
    y0 = bl + rh * 0.55
    lang = rl + hl * 0.8 + kl
    zmin = -rl - V["schwanz"] * 0.9
    ymax = y0 + rh + hl * 1.3
    u, v, h, w = T.raster(name)
    Z = lang - u * (lang - zmin)
    Y = ymax - v * ymax
    return Z, Y, h, w, rl, rh, bl, y0, lang, kl


def vierbeiner(T, name):
    Z, Y, h, w, rl, rh, bl, y0, lang, kl = vier_raster(T, name)
    rumpf = (np.abs(Z) < rl * 1.02) & (Y > bl * 0.8)
    bauch = rumpf & (Y < y0 - rh * 0.35)
    ruecken = rumpf & (Y > y0 + rh * 0.62)
    kopf = Z > rl * 0.95
    maul = Z > lang - kl * 0.38
    beine = (Y < bl * 0.95) & ~kopf
    huf = Y < 0.05
    haar = rauschen(h, w, 30, 91)
    if name == "esel":
        # Nubischer Wildesel: grau, heller Bauch und Maul, dunkler Aalstrich und Schulterkreuz, dunkle Quaste
        a = np.zeros((h, w, 3), np.float32) + farbe("#8a8178")
        a = mischen(a, farbe("#d6cfc2"), bauch * 0.8)
        a = mischen(a, farbe("#d6cfc2"), maul * 0.85)
        a = mischen(a, farbe("#3a332e"), ruecken * 0.8)
        kreuz = glocke(Z, rl * 0.72, 0.025) * (Y > y0 - rh * 0.2) * rumpf
        a = mischen(a, farbe("#3a332e"), kreuz * 0.75)
        a = mischen(a, farbe("#3a332e"), (Z < -rl * 0.98) * (Y < y0 - 0.25) * 0.9)
        a = mischen(a, farbe("#2a2622"), huf * 1.0)
        a = mischen(a, farbe("#2a2622"), (Z > lang - 0.02) * 1.0)
    elif name == "schaf":
        # Schaf mit Haarvlies: cremeweiß, gelockt; Kopf und Beine braun
        a = np.zeros((h, w, 3), np.float32) + farbe("#d8ccb2")
        locken = schuppen(h, w, 5.0, 92)
        a *= (0.75 + 0.35 * locken)[..., None]
        a = mischen(a, farbe("#6e5236"), kopf * 0.9)
        a = mischen(a, farbe("#6e5236"), beine * 0.85)
        a = mischen(a, farbe("#2a2420"), huf)
    elif name == "ziege":
        # Ziege: dunkelbraun, Bauch und Beine heller, Gesicht mit hellem Streif
        a = np.zeros((h, w, 3), np.float32) + farbe("#5a4030")
        a = mischen(a, farbe("#8a6848"), bauch * 0.6)
        a = mischen(a, farbe("#2e221a"), ruecken * 0.6)
        a = mischen(a, farbe("#a88a68"), maul * 0.6)
        a = mischen(a, farbe("#3e2e22"), beine * 0.5)
        a = mischen(a, farbe("#1e1814"), huf)
    else:
        # Katze (Falbkatze, wie die Katzen auf den Grabbildern): sandgelb, getigert, Schwanzringe, helle Kehle
        a = np.zeros((h, w, 3), np.float32) + farbe("#b8935e")
        streif = np.clip(np.sin(Z * 70.0 + Y * 20.0) * 2 - 0.9, 0, 1) * rumpf
        a = mischen(a, farbe("#5a4026"), streif * 0.6)
        schw = Z < -rl
        a = mischen(a, farbe("#4a3420"), schw * np.clip(np.sin(Z * 60.0) * 2 - 0.5, 0, 1) * 0.8)
        a = mischen(a, farbe("#2a2018"), (Z < -rl - 0.27) * 0.9)
        a = mischen(a, farbe("#e0cca8"), bauch * 0.7)
        a = mischen(a, farbe("#e0cca8"), maul * 0.6)
        a = mischen(a, farbe("#5a4026"), beine * np.clip(np.sin(Y * 90) * 2 - 1, 0, 1) * 0.5)
    a *= (0.86 + 0.22 * haar)[..., None]
    T.setz(name, a)


# ---------------------------------------------------------------- feste Stellen: Augen, Horn, Gelb, Schwarz, Weiß, Rosa
def stellen(T):
    def fleck(x, y, f, glanz=False):
        blk = np.zeros((32, 32, 3), np.float32) + f
        if glanz:
            yy, xx = np.mgrid[0:32, 0:32]
            g = np.exp(-(((xx - 11) / 3.0) ** 2 + ((yy - 10) / 3.0) ** 2))
            blk = blk * (1 - g[..., None]) + 235 * g[..., None]
        T.bild[y:y + 32, x:x + 32] = blk
    fleck(768, 768, farbe("#1a120c"), True)   # Auge
    fleck(800, 768, farbe("#5a5048"))         # Horn, Krallen
    fleck(832, 768, farbe("#d8a830"))         # Gelb (Schnabel, Füße des Falken)
    fleck(864, 768, farbe("#1c1a1a"))         # Schwarz
    fleck(896, 768, farbe("#ece8dc"))         # Weiß
    fleck(928, 768, farbe("#c98f86"))         # Rosa (Ohren, Nase)


def main():
    ziel = sys.argv[1] if len(sys.argv) > 1 else os.path.join(WURZEL, "models", "tiere", "tiere_tafel.webp")
    T = Tafel()
    eidechse(T)
    kaefer(T)
    kaefer(T, "schwarzkaefer", True)
    kugel(T)
    falke_flug(T)
    falke_sitz(T)
    maus(T)
    ibis_steh(T)
    ibis_flug(T)
    fisch(T)
    fledermaus(T)
    for n in VIER:
        vierbeiner(T, n)
    stellen(T)
    os.makedirs(os.path.dirname(ziel), exist_ok=True)
    Image.fromarray(T.bild.astype(np.uint8)).save(ziel, quality=88, method=6)
    print("Tafel:", ziel, os.path.getsize(ziel) // 1024, "KB")


if __name__ == "__main__":
    main()
