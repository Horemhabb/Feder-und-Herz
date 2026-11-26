# SPDX-License-Identifier: GPL-3.0-or-later
"""Vorlagenbogen teilen: Die Bildstufe `gegner_vorlagen` malt dieselbe Figur zweimal nebeneinander (links von vorn,
rechts von hinten; bei Tieren rechts von der Seite). Dieses Skript schneidet die beiden Ansichten aus, stellt sie frei
(Alphakanal) und schreibt sie als <name>_vorn.png und <name>_hinten.png.

Braucht nur Pillow und NumPy (beides ist im Python von ComfyUI und von Blender-als-Modul dabei).
  python bogen.py <bogen.png> [<zielordner>]
"""
import os
import sys
import numpy as np
from PIL import Image


def freistellen(im):
    """Hintergrund wegnehmen: die Farbe des Bildrands gilt als Hintergrund (die Vorlagen haben schlichten grauen Grund)."""
    im = im.convert("RGB")
    a = np.asarray(im).astype(np.float32)
    rand = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]])
    grund = np.median(rand, 0)
    d = np.sqrt(((a - grund) ** 2).sum(2))
    schwelle = max(24.0, np.percentile(np.sqrt(((rand - grund) ** 2).sum(1)), 98) * 1.6)
    maske = d > schwelle
    # Löcher schließen und Krümel entfernen (einfaches Öffnen/Schließen mit 3×3)
    def dehnen(m):
        return m | np.roll(m, 1, 0) | np.roll(m, -1, 0) | np.roll(m, 1, 1) | np.roll(m, -1, 1)

    def schrumpfen(m):
        return m & np.roll(m, 1, 0) & np.roll(m, -1, 0) & np.roll(m, 1, 1) & np.roll(m, -1, 1)
    maske = schrumpfen(dehnen(dehnen(maske)))
    maske = dehnen(schrumpfen(schrumpfen(maske)))
    return Image.fromarray(np.dstack([a.astype(np.uint8), maske.astype(np.uint8) * 255]), "RGBA")


def zuschneiden(im, rand=0.06):
    a = np.asarray(im)[..., 3] > 127
    ys, xs = np.nonzero(a)
    if len(xs) == 0:
        return im
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    r = int(rand * max(x1 - x0, y1 - y0))
    return im.crop((max(0, x0 - r), max(0, y0 - r), min(im.width, x1 + r + 1), min(im.height, y1 + r + 1)))


def teilen(pfad, ziel=None):
    """Bogen → (Pfad links, Pfad rechts). Die Trennlinie liegt in der leersten Spalte nahe der Mitte."""
    ziel = ziel or os.path.dirname(os.path.abspath(pfad))
    os.makedirs(ziel, exist_ok=True)
    name = os.path.splitext(os.path.basename(pfad))[0]
    frei = freistellen(Image.open(pfad))
    spalten = (np.asarray(frei)[..., 3] > 127).sum(0)
    w = frei.width
    lo, hi = int(0.3 * w), int(0.7 * w)
    schnitt = lo + int(np.argmin(spalten[lo:hi]))
    links = zuschneiden(frei.crop((0, 0, schnitt, frei.height)))
    rechts = zuschneiden(frei.crop((schnitt, 0, w, frei.height)))
    pl, pr = os.path.join(ziel, name + "_vorn.png"), os.path.join(ziel, name + "_hinten.png")
    links.save(pl)
    rechts.save(pr)
    return pl, pr


if __name__ == "__main__":
    for p in teilen(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None):
        print(p)
