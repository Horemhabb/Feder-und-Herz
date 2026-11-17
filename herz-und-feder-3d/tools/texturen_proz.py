#!/usr/bin/env python3
"""Requisitentexturen aus Formeln (Fassung 2.6): nahtlos kachelbar, mit Reliefkarte, ohne fremde Bilder.
Gibt Krügen, Kisten, Körben und Palmen eine eigene Haut. (Mauern und Böden kommen gemalt über tools/texturen.py;
die Bausteine rauschen, zellen, ziegel bleiben hier für künftige Oberflächen.)
Aufruf: python tools/texturen_proz.py [Zielordner]   (braucht numpy und pillow)"""
import os
import sys
import numpy as np
from PIL import Image

ZIEL = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "textures")
rng = np.random.default_rng(11)


def rauschen(n, beta=2.0, seed=0):
    """Nahtloses Rauschen über die Frequenzen: beta groß = weich, klein = körnig. Werte 0..1."""
    r = np.random.default_rng(seed)
    f = np.fft.fftfreq(n)
    fx, fy = np.meshgrid(f, f)
    k = np.sqrt(fx ** 2 + fy ** 2)
    k[0, 0] = 1
    spek = (r.normal(size=(n, n)) + 1j * r.normal(size=(n, n))) / k ** (beta / 2)
    spek[0, 0] = 0
    a = np.real(np.fft.ifft2(spek))
    return (a - a.min()) / (a.max() - a.min())


def zellen(n, zahl, seed=0):
    """Nahtlose Voronoi-Zellen: Abstand zum nächsten und zum zweitnächsten Kern, dazu eine Zufallszahl je Zelle."""
    r = np.random.default_rng(seed)
    p = r.random((zahl, 2))
    wert = r.random(zahl)
    y, x = np.mgrid[0:n, 0:n] / n
    d1 = np.full((n, n), 9.0)
    d2 = np.full((n, n), 9.0)
    wer = np.zeros((n, n), int)
    for i, (px, py) in enumerate(p):
        dx = np.abs(x - px); dx = np.minimum(dx, 1 - dx)
        dy = np.abs(y - py); dy = np.minimum(dy, 1 - dy)
        d = np.sqrt(dx * dx + dy * dy)
        nah = d < d1
        d2 = np.where(nah, d1, np.minimum(d2, d))
        wer = np.where(nah, i, wer)
        d1 = np.where(nah, d, d1)
    return d1, d2, wert[wer]


def ziegel(n, reihen, je_reihe, fuge, seed=0, versatz=0.5):
    """Mauerverband: Höhe 1 auf dem Stein, 0 in der Fuge; dazu eine Zufallszahl je Stein."""
    r = np.random.default_rng(seed)
    y, x = np.mgrid[0:n, 0:n] / n
    rh = 1.0 / reihen
    reihe = np.floor(y / rh).astype(int)
    xs = (x + (reihe % 2) * versatz / je_reihe) % 1.0
    spalte = np.floor(xs * je_reihe).astype(int)
    lx = xs * je_reihe - spalte
    ly = y / rh - reihe
    rand = np.minimum(np.minimum(lx, 1 - lx) / (fuge * je_reihe), np.minimum(ly, 1 - ly) / (fuge * reihen))
    hoehe = np.clip(rand, 0, 1) ** 0.6
    wert = r.random((reihen, je_reihe))[reihe % reihen, spalte % je_reihe]
    return hoehe, wert


def relief(h, kraft=2.0):
    """Höhenfeld → Reliefkarte (nahtlos)."""
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * kraft * h.shape[0] / 256
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * kraft * h.shape[0] / 256
    nz = np.ones_like(h)
    l = np.sqrt(dx * dx + dy * dy + nz * nz)
    return np.clip(np.dstack([-dx / l, dy / l, nz / l]) * 127.5 + 127.5, 0, 255).astype(np.uint8)


def schreib(name, farbe, h, kraft=2.0, n_n=512):
    Image.fromarray(np.clip(farbe, 0, 255).astype(np.uint8)).save(os.path.join(ZIEL, name + ".jpg"), quality=88)
    if h is not None:
        nm = Image.fromarray(relief(h, kraft)).resize((n_n, n_n), Image.LANCZOS)
        nm.save(os.path.join(ZIEL, name + "_n.jpg"), quality=90)
    print(name)


def ton(grund, f):
    return np.array(grund, float)[None, None, :] * f[..., None]


# --- Requisiten (512): gebrannter Ton, Holz, Palmrinde, Palmblatt, Korbgeflecht
M = 512
y, x = np.mgrid[0:M, 0:M] / M
korn = rauschen(M, 1.4, 22)
gross = rauschen(M, 2.8, 23)
rillen = 0.5 + 0.5 * np.sin(y * 2 * np.pi * 40 + korn * 3)
f = (0.86 + 0.14 * rillen) * (0.8 + 0.4 * gross) * (0.9 + 0.2 * korn)
schreib("p01_ton", ton((184, 112, 72), f), 0.5 * rillen + 0.5 * korn, 1.5, 256)
faser = rauschen(M, 2.0, 24)
faser = np.repeat(faser[:, ::16], 16, axis=1)[:, :M]           # lange Fasern entlang y
bretter = np.clip(np.minimum((x * 6) % 1.0, 1 - (x * 6) % 1.0) / 0.04, 0, 1)
brett_w = np.random.default_rng(25).random(6)[np.floor(x * 6).astype(int) % 6]
f = (0.55 + 0.45 * bretter) * (0.8 + 0.3 * brett_w) * (0.75 + 0.5 * np.roll(faser, 0)) * (0.9 + 0.2 * korn)
schreib("p02_holz", ton((150, 104, 62), f), 0.6 * bretter + 0.4 * faser, 1.8, 256)
ringe = np.abs(((y * 14 + 0.15 * np.sin(x * 2 * np.pi * 3)) % 1.0) - 0.5) * 2
f = (0.6 + 0.4 * ringe ** 0.5) * (0.8 + 0.4 * korn) * (0.85 + 0.3 * gross)
schreib("p03_palmrinde", ton((142, 104, 66), f), ringe ** 0.5 * 0.7 + 0.3 * korn, 2.4, 256)
ader = np.abs(((x * 24) % 1.0) - 0.5) * 2
f = (0.75 + 0.25 * ader) * (0.8 + 0.4 * gross) * (0.9 + 0.2 * korn)
schreib("p04_palmblatt", ton((70, 122, 58), f) + (gross[..., None] - 0.5) * np.array([40, 20, 0.0]), None)
flecht = (0.5 + 0.5 * np.sin(x * 2 * np.pi * 24)) * (0.5 + 0.5 * np.sin(y * 2 * np.pi * 24 + np.floor(x * 24) * np.pi))
f = (0.6 + 0.5 * flecht) * (0.85 + 0.3 * korn)
schreib("p05_korb", ton((186, 150, 92), f), flecht, 2.0, 256)
