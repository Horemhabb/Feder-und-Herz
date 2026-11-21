#!/usr/bin/env python3
"""Symbole der Fähigkeiten, Fassung 4.0.6 „Magie“: das Zeichen glüht von innen auf fast schwarzem Grund (ruhig, kein Strahlenkranz),
mit Licht und Volumen statt Comic-Flächen, weichen dünnen Konturen und feiner Materialstruktur. Rahmen: dünne Goldlinie.
Zeichen kommen aus zeichen.py. Aufruf: python3 magie.py [Zielordner] [Zeichen …]   (Standard: ui/symbole, alle; braucht cairosvg)"""
import os, sys, io, zlib
import numpy as np
import cairosvg
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import zeichen as Z
from zeichen import I, ZU, N, x, y, alpha, inner
weich = Z.weich
# Klassenfarbe: Grundton, Schein
CL = {"ermittler": ((40, 90, 200), (120, 190, 255)), "moench": ((20, 150, 140), (110, 255, 225)), "jaegerin": ((190, 70, 40), (255, 170, 90)),
      "forensiker": ((130, 70, 210), (210, 150, 255)), "basalt": ((90, 80, 70), (255, 215, 140)), "": ((190, 110, 30), (255, 210, 120))}
SKALA = {"salve": 0.8}

def licht(h, kraft, L=(-0.5, -0.65, 0.58), ex=36):
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * kraft
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * kraft
    n = np.dstack([-dx, -dy, np.ones_like(h)]); n /= np.linalg.norm(n, axis=2, keepdims=True)
    L = np.array(L); L /= np.linalg.norm(L); H = L + np.array([0, 0, 1.0]); H /= np.linalg.norm(H)
    return np.clip((n * L).sum(2), 0, 1), np.clip((n * H).sum(2), 0, 1) ** ex

def magie(id_, skala=None):
    skala = skala or SKALA.get(id_, 0.9)
    rng = np.random.default_rng(zlib.crc32(id_.encode())); Z.rng = rng; R = Z.rauschen
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 56 56" width="{N}" height="{N}"><g transform="translate(28 28) scale({skala}) translate(-28 -28)">{I[id_]}</g></svg>'
    g = np.asarray(Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode()))).convert("RGBA")).astype(np.float32)
    rgb, a = g[..., :3], g[..., 3] / 255
    dk, hl = [np.array(c, np.float32) for c in CL[ZU.get(id_, "")]]
    r = np.sqrt((x - 0.5) ** 2 + (y - 0.47) ** 2)
    b = np.array([4, 5, 12], np.float32) + dk * np.clip(1 - r / 0.55, 0, 1)[..., None] ** 2.2 * 0.18
    helle = rgb.mean(2, keepdims=True)
    sat = np.clip(helle + (rgb - helle) * 1.3, 0, 255)
    # Konturen: dünner und weicher (schwarze Linien des Zeichens abmagern), Farbe tiefes Nachtblau
    dunkel = np.clip(1 - helle[..., 0] / 90, 0, 1) * a
    dunkel = np.clip((weich(dunkel, 1.4) - 0.40) * 2.0, 0, 1) * 0.85
    # Volumen: Höhe aus der Silhouette, Licht von links oben, kleiner Glanz
    h = weich(a, 7.0) * 1.1 + weich(a, 2.2) * 0.35
    dif, sp = licht(h, 26)
    kern = weich(a, 9)[..., None]
    mat = 0.97 + 0.025 * R(3.0)[..., None] + 0.03 * R(9)[..., None]
    f = sat * (0.30 + 0.45 * kern + 0.62 * dif[..., None]) * mat
    f += np.array([255, 240, 205], np.float32) * np.clip((helle - 165) / 90, 0, 1) * 0.32     # heiße Kerne der hellen Farben
    f += np.array([255, 240, 210], np.float32) * sp[..., None] * 0.22 * a[..., None]
    f = f * (1 - dunkel[..., None]) + np.array([9, 11, 28], np.float32) * dunkel[..., None]
    halo = weich(a, 10) * 0.7 + weich(a, 28) * 1.0
    b = b + hl * np.clip(halo, 0, 1.4)[..., None] * 0.55
    b = b * (1 - a[..., None]) + f * a[..., None]
    rim = np.clip((a - weich(a, 1.6)) * 2.4, 0, 1)
    b += hl * 0.45 * rim[..., None] + np.array([255, 235, 180], np.float32) * rim[..., None] * 0.28
    dichte = weich(a, 20)
    funk = ((rng.random((N, N)) > 0.9992) * (dichte > 0.15)).astype(np.float32)
    b += np.array([255, 235, 180], np.float32) * np.clip(weich(funk, 1.4) * 8, 0, 1)[..., None]
    rl = np.exp(-((inner - 0.04) / 0.005) ** 2)
    b += np.array([225, 185, 100], np.float32) * rl[..., None] * 0.85
    b *= (1 - 0.5 * np.clip((r - 0.35) / 0.4, 0, 1) ** 2)[..., None]
    return Image.fromarray(np.dstack([np.clip(b, 0, 255), alpha * 255]).astype(np.uint8), "RGBA")

if __name__ == "__main__":
    ziel = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "ui", "symbole")
    for i in (sys.argv[2:] or list(I)):
        magie(i).resize((256, 256), Image.LANCZOS).save(os.path.join(ziel, i + ".webp"), quality=92, method=6); print(i, end=" ")
    print()
