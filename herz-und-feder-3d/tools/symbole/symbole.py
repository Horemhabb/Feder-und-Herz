#!/usr/bin/env python3
"""Symbole der Fähigkeiten als Reliefs (Fassung 2.7.1): Steintafel in der Farbe der Klasse, darauf die Hieroglyphe
erhaben in Gold, die dunklen Linien eingeritzt. Kein 3D-Programm nötig: Aus den Masken (tools/symbole/masken.gd)
wird ein Höhenfeld, daraus Normalen, daraus Licht (Streulicht, Glanz, Spiegelung, Schlagschatten, Umgebungsverdeckung).
Die Steinmaserung stammt aus den Higgsfield-Texturen des Spiels.
Aufruf: python symbole.py <Maskenordner> <Zielordner> [Größe]"""
import os
import sys
import numpy as np
from PIL import Image, ImageFilter

MASKEN, ZIEL = sys.argv[1], sys.argv[2]
GROESSE = int(sys.argv[3]) if len(sys.argv) > 3 else 256
WURZEL = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
N = 512

# Tafelfarbe hell / dunkel und Farbe des Scheins je Klasse
TAFEL = {"ermittler": ((52, 84, 140), (10, 16, 34), (120, 170, 255)), "moench": ((36, 112, 108), (6, 26, 28), (110, 230, 210)),
         "jaegerin": ((122, 74, 36), (26, 14, 6), (255, 170, 90)), "forensiker": ((90, 62, 140), (18, 10, 34), (200, 140, 255)),
         "basalt": ((78, 70, 60), (14, 12, 10), (255, 210, 130)), "": ((128, 40, 36), (28, 8, 8), (255, 120, 90))}


def lade(pfad, n=N):
    return np.asarray(Image.open(pfad).convert("L").resize((n, n), Image.LANCZOS)).astype(np.float32) / 255.0


def weich(a, r):
    im = Image.fromarray(np.clip(a * 255, 0, 255).astype(np.uint8))
    return np.asarray(im.filter(ImageFilter.GaussianBlur(r))).astype(np.float32) / 255.0


def weich_f(a, r):
    """Weichzeichnen für Werte außerhalb 0..1 (über Umskalieren)."""
    lo, hi = float(a.min()), float(a.max())
    if hi - lo < 1e-6:
        return a
    return weich((a - lo) / (hi - lo), r) * (hi - lo) + lo


def normalen(h, kraft):
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * kraft
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * kraft
    n = np.dstack([-dx, -dy, np.ones_like(h)])
    return n / np.linalg.norm(n, axis=2, keepdims=True)


def abgerundet(n, rand, radius):
    y, x = np.mgrid[0:n, 0:n].astype(np.float32)
    lo, hi = rand + radius, n - 1 - rand - radius
    dx = np.maximum(np.maximum(lo - x, x - hi), 0)
    dy = np.maximum(np.maximum(lo - y, y - hi), 0)
    d = np.sqrt(dx * dx + dy * dy) - radius        # < 0 innen
    inner = np.minimum(np.minimum(x - rand, n - 1 - rand - x), np.minimum(y - rand, n - 1 - rand - y))
    return d, inner


# Steinmaserung: Wolken in mehreren Größen, dazu feines Korn und Adern (keine Mauerfugen wie in den Wandtexturen)
rng = np.random.default_rng(3)
korn = weich(rng.random((N, N)).astype(np.float32), 0.8)
granit = sum(weich(rng.random((N, N)).astype(np.float32), r) * w for r, w in ((3, 0.25), (10, 0.35), (28, 0.4)))
ader = np.abs(weich(rng.random((N, N)).astype(np.float32), 18) - 0.5)
granit = granit + np.clip(0.02 - ader, 0, None) * 12
granit = (granit - granit.mean()) / (granit.std() + 1e-6)


def symbol(id_, cls):
    hell, dunkel, schein = [np.array(c, np.float32) for c in TAFEL.get(cls, TAFEL[""])]
    gold = lade(os.path.join(MASKEN, id_ + "_gold.png"))
    ritz = lade(os.path.join(MASKEN, id_ + "_ritz.png"))
    # Platz für den Rahmen: Zeichen etwas kleiner in die Mitte
    def schrumpf(m, f=0.8):
        k = int(N * f)
        im = Image.fromarray((m * 255).astype(np.uint8)).resize((k, k), Image.LANCZOS)
        out = Image.new("L", (N, N))
        out.paste(im, ((N - k) // 2, (N - k) // 2))
        return np.asarray(out).astype(np.float32) / 255.0
    gold, ritz = schrumpf(gold), schrumpf(ritz)

    d, inner = abgerundet(N, 6, 64)
    tafel = np.clip(-d / 2.0, 0, 1)                                   # Deckmaske der Tafel, weiche Kante
    fase = np.clip(inner / 34.0, 0, 1)                                # schräge Kante nach außen
    rahmen = np.exp(-((inner - 46) / 5.0) ** 2)                       # erhabene Goldlinie innen
    # Höhenfeld: Tafel mit Fase, Goldrahmen, erhabenes Zeichen (gewölbt), Ritzung vertieft, Abnutzung
    hz = weich(gold, 3.0) * 0.55 + weich(gold, 9.0) * 0.45
    h = fase * 0.6 + rahmen * 0.35 + hz * 1.6 - weich(ritz, 1.5) * 0.7 + granit * 0.012 + (korn - 0.5) * 0.02
    nrm = normalen(h, 12.0)
    L = np.array([-0.45, -0.6, 0.66]); L /= np.linalg.norm(L)
    V = np.array([0.0, 0.0, 1.0])
    H = (L + V); H /= np.linalg.norm(H)
    diff = np.clip((nrm * L).sum(2), 0, 1)
    spec = np.clip((nrm * H).sum(2), 0, 1)
    # Schlagschatten des Zeichens und des Rahmens nach rechts unten, Umgebungsverdeckung
    erhaben = np.clip(hz * 1.4 + rahmen * 0.6, 0, 1)
    schatten = np.roll(np.roll(weich(erhaben, 6), 9, 0), 7, 1)
    ao = np.clip(weich_f(h, 14) - h, 0, None)
    licht = 1.0 - 0.55 * np.clip(schatten - erhaben, 0, 1) - 1.6 * ao

    # Stein: Farbe der Klasse, von der Mitte zum Rand dunkler, Maserung, feine Risse
    y, x = np.mgrid[0:N, 0:N].astype(np.float32) / N
    rad = np.sqrt((x - 0.45) ** 2 + (y - 0.4) ** 2) / 0.75
    stein = hell[None, None, :] * (1 - rad[..., None]) + dunkel[None, None, :] * rad[..., None]
    stein = stein * (0.82 + 0.12 * granit[..., None] + 0.1 * (korn[..., None] - 0.5))
    stein_l = stein * (0.35 + 0.85 * diff[..., None]) * licht[..., None] + 255 * 0.08 * spec[..., None] ** 30
    # Gold: gebürstet, mit Glanz und einer Spiegelung des Himmels oben, abgerieben an den Kanten der Ritzung
    au_basis = np.array([206, 150, 62], np.float32)
    abrieb = 0.85 + 0.25 * weich(rng.random((N, N)).astype(np.float32), 2.5)
    himmel = np.clip(-nrm[..., 1] * 0.8 + 0.35, 0, 1)[..., None]
    au = au_basis * abrieb[..., None] * (0.3 + 0.8 * diff[..., None]) * licht[..., None]
    au = au + np.array([255, 236, 190]) * (spec[..., None] ** 24) * 0.9 + np.array([255, 220, 150]) * himmel * 0.25
    # Gold in den Senken dunkler (Patina), auf den Kuppen hell
    au = au * (0.7 + 0.45 * np.clip(hz * 1.3, 0, 1))[..., None]
    goldanteil = np.clip(gold * 1.15 + rahmen * 0.9, 0, 1)[..., None]
    farbe = stein_l * (1 - goldanteil) + au * goldanteil
    # Ritzung: dunkel, mit hellem Grat an der Lichtseite
    farbe = farbe * (1 - 0.65 * ritz[..., None])
    # leiser Schein der Klasse hinter dem Zeichen
    glow = weich(gold, 22) * (1 - goldanteil[..., 0])
    farbe = farbe + schein[None, None, :] * glow[..., None] * 0.35
    # Rand der Tafel: dunkle Kante, kleine Abplatzer
    kante = np.clip(1 - fase, 0, 1)
    farbe = farbe * (1 - 0.35 * kante[..., None])
    # Vignette: Ecken der Tafel tiefer im Schatten
    vig = np.clip(np.sqrt((x - 0.5) ** 2 + (y - 0.5) ** 2) / 0.72, 0, 1) ** 2
    farbe = farbe * (1 - 0.45 * vig[..., None])
    rgba = np.dstack([np.clip(farbe, 0, 255), tafel * 255]).astype(np.uint8)
    out = Image.fromarray(rgba, "RGBA").resize((GROESSE, GROESSE), Image.LANCZOS)
    out.save(os.path.join(ZIEL, id_ + ".webp"), quality=90, method=6)


os.makedirs(ZIEL, exist_ok=True)
for zeile in open(os.path.join(MASKEN, "liste.txt")).read().splitlines():
    teile = zeile.split()
    id_, cls = teile[0], (teile[1] if len(teile) > 1 else "")
    symbol(id_, cls)
    print(id_, end=" ")
print()
