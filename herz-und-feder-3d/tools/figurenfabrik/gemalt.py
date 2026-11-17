# SPDX-License-Identifier: GPL-3.0-or-later (Teil der Figurenfabrik; siehe LIZENZ.md)
"""Gemalte Texturen: überträgt Flecken aus einem gemalten Figurenbogen (z. B. K11) in die Felder einer Texturtafel.

Die Fabrik malt zuerst alles selbst (Muster). Danach ersetzt dieses Modul Feld für Feld, was die Vorlage hergibt:
Schuppen, Leinen, Haut und Tuch werden aus einem Ausschnitt gekachelt (abwechselnd gespiegelt, damit keine Naht
entsteht), der Perlenkragen wird aus dem Bogen „abgerollt“, das Gesicht wird aus einer Halbseite gespiegelt und mit
weichem Rand eingesetzt. Die Beleuchtung der Malerei bleibt in den Flecken: das gibt den Figuren Tiefe, die das
Licht im Spiel allein nicht hergibt.
"""
import math
import numpy as np
from PIL import Image, ImageFilter


def _np(im):
    return np.asarray(im.convert("RGB")).astype(np.float32)


def kachel(fleck, w, h, hoehe=None, senkrecht_spiegeln=False):
    """Fleck auf hoehe (Pixel) bringen und waagrecht abwechselnd gespiegelt aneinanderlegen, bis w × h gefüllt ist."""
    if hoehe:
        f = hoehe / fleck.height
        fleck = fleck.resize((max(1, int(fleck.width * f)), hoehe), Image.LANCZOS)
    out = Image.new("RGB", (w, h))
    y, j = 0, 0
    while y < h:
        x, i = 0, 0
        zeile = fleck.transpose(Image.FLIP_TOP_BOTTOM) if senkrecht_spiegeln and j % 2 else fleck
        while x < w:
            out.paste(zeile.transpose(Image.FLIP_LEFT_RIGHT) if i % 2 else zeile, (x, y))
            x += fleck.width
            i += 1
        y += fleck.height
        j += 1
    if not senkrecht_spiegeln and fleck.height < h:
        # senkrechte Wiederholung: Übergänge weich überblenden
        a = _np(out)
        b = _np(out.transpose(Image.FLIP_TOP_BOTTOM).transpose(Image.FLIP_TOP_BOTTOM))
        out = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))
    return out


def angleichen(fleck, ziel_mittel):
    """Helligkeit eines Flecks auf einen Mittelwert ziehen (Malerei ist an manchen Stellen sehr dunkel)."""
    a = _np(fleck)
    m = a.mean()
    return Image.fromarray(np.clip(a * (ziel_mittel / max(1.0, m)), 0, 255).astype(np.uint8))


def flach(fleck, staerke=0.6, radius=18):
    """Großflächiges Licht der Malerei zum Teil herausnehmen, damit sich beim Kacheln keine hellen Flecken wiederholen."""
    a = _np(fleck)
    blur = _np(fleck.filter(ImageFilter.GaussianBlur(radius)))
    m = blur.mean(axis=(0, 1), keepdims=True)
    return Image.fromarray(np.clip(a - (blur - m) * staerke, 0, 255).astype(np.uint8))


def abrollen(bild, mitte, r_innen, r_aussen, w_von, w_bis, w, h):
    """Bogenförmiges Band (Kragen) in ein gerades Band umrechnen: oben innen, unten außen."""
    src = _np(bild)
    us = np.linspace(math.radians(w_von), math.radians(w_bis), w)
    vs = np.linspace(r_innen, r_aussen, h)
    U, V = np.meshgrid(us, vs)
    X = (mitte[0] + V * np.cos(U)).astype(int).clip(0, src.shape[1] - 1)
    Y = (mitte[1] + V * np.sin(U)).astype(int).clip(0, src.shape[0] - 1)
    return Image.fromarray(src[Y, X].astype(np.uint8))


def gesicht(bild, box, nase_x, ziel_w, ziel_h):
    """Halbes Gesicht (vom Ohr bis zur Nase) spiegeln: ergibt eine Vorderansicht für den Kopf."""
    x0, y0, x1, y1 = box
    halb = bild.crop((x0, y0, nase_x, y1))
    voll = Image.new("RGB", (halb.width * 2, halb.height))
    voll.paste(halb, (0, 0))
    voll.paste(halb.transpose(Image.FLIP_LEFT_RIGHT), (halb.width, 0))
    return voll.resize((ziel_w, ziel_h), Image.LANCZOS)


def einsetzen(tafel, feld, fleck, ab=(0, 0), maske_rand=0.0):
    """Fleck in ein Feld der Tafel setzen; mit maske_rand > 0 als weiche Ellipse (Anteil des Randes)."""
    x0, y0, x1, y1 = feld
    if maske_rand <= 0:
        tafel.paste(fleck, (x0 + ab[0], y0 + ab[1]))
        return
    w, h = fleck.size
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.sqrt(((xx - w / 2) / (w / 2)) ** 2 + ((yy - h / 2) / (h / 2)) ** 2)
    m = np.clip((1.0 - d) / maske_rand, 0, 1)
    maske = Image.fromarray((m * 255).astype(np.uint8))
    tafel.paste(fleck, (x0 + ab[0], y0 + ab[1]), maske)


def feld_aus(tafel, feld):
    x0, y0, x1, y1 = feld
    return tafel.crop((x0, y0, x1, y1))


def haut(bild, box, w, h, seed=3, hell=1.0):
    """Haut ohne Kachelmuster: Farbe aus einem gemalten Fleck (Mittelwert), darüber feines Korn und leichte Flecken."""
    farbe = _np(bild.crop(box)).reshape(-1, 3).mean(axis=0) * hell
    farbe = farbe * np.array([1.08, 0.97, 0.82])   # wärmer: das kühle Spiellicht nimmt der Haut sonst das Braun
    rng = np.random.default_rng(seed)
    fein = np.asarray(Image.fromarray((rng.random((h // 2, w // 2)) * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)).astype(np.float32) / 255
    grob = np.asarray(Image.fromarray((rng.random((h // 24 + 1, w // 24 + 1)) * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)).astype(np.float32) / 255
    f = 1.0 + (fein - 0.5) * 0.16 + (grob - 0.5) * 0.14
    return Image.fromarray(np.clip(farbe[None, None, :] * f[:, :, None], 0, 255).astype(np.uint8))


# ---------------------------------------------------------------- Gesichter: mehrere Wege
def stuetz(z, punkte):
    """Stückweise lineare Zuordnung Höhe → Bildzeile über Stützpunkte [(z, y), …] (z absteigend), außen verlängert."""
    zs = np.array([p[0] for p in punkte], dtype=np.float64)[::-1]
    ys = np.array([p[1] for p in punkte], dtype=np.float64)[::-1]
    z = np.asarray(z, dtype=np.float64)
    y = np.interp(z, zs, ys)
    lo, hi = z < zs[0], z > zs[-1]
    y[lo] = ys[0] + (z[lo] - zs[0]) * (ys[1] - ys[0]) / (zs[1] - zs[0])
    y[hi] = ys[-1] + (z[hi] - zs[-1]) * (ys[-1] - ys[-2]) / (zs[-1] - zs[-2])
    return y


def projektion(bild, w, h, z_von_v, breite_von_z, cx, R, theta, y_punkte, spiegeln=True, rand=0.15):
    """Projektionsmalerei ohne 3D-Programm: Der Kopf ist eine Drehfläche. Für jeden Punkt der Tafel (Winkel φ, Höhe z)
    wird berechnet, wo er im gemalten Bild liegt, wenn der Kopf dort um θ gedreht dargestellt ist:
    x = cx + R·b(z)·sin(φ + θ), y aus den Stützpunkten (Haaransatz, Augen, Mund, Bart).
    Was der Maler nicht sehen konnte (Rückseite der Drehung), kommt aus der Gegenseite (−φ). Gibt RGBA zurück."""
    src = _np(bild)
    us = (np.arange(w) + 0.5) / w
    phi = np.radians((us - 0.5) * 360.0)
    z = np.array([z_von_v(v) for v in range(h)])
    yy = stuetz(z, y_punkte)
    bz = np.array([breite_von_z(zz) for zz in z])
    t = math.radians(theta)

    def probe(ph):
        X = cx + R * bz[:, None] * np.sin(ph[None, :] + t)
        Y = np.repeat(yy[:, None], w, axis=1)
        c = np.cos(ph[None, :] + t).repeat(h, axis=0)
        wgt = np.clip((c - rand) / 0.35, 0, 1)
        Xi = X.clip(0, src.shape[1] - 1).astype(int)
        Yi = Y.clip(0, src.shape[0] - 1).astype(int)
        return src[Yi, Xi], wgt
    c1, w1 = probe(phi)
    if spiegeln:
        c2, w2 = probe(-phi)
        col = c1 * w1[..., None] + c2 * (1 - w1[..., None])
        a = np.maximum(w1, w2)
    else:
        col, a = c1, w1
    return np.dstack([col, a * 255]).astype(np.uint8)


def farbe_angleichen(rgba, ziel_rgba):
    """Mittelwert und Streuung jeder Farbe an eine andere Quelle angleichen (nur wo beide sichtbar sind)."""
    a = rgba[..., :3].astype(np.float32)
    b = ziel_rgba[..., :3].astype(np.float32)
    m = (rgba[..., 3] > 128) & (ziel_rgba[..., 3] > 128)
    if m.sum() < 50:
        return rgba
    for i in range(3):
        sa, sb = a[..., i][m], b[..., i][m]
        a[..., i] = (a[..., i] - sa.mean()) / (sa.std() + 1e-3) * sb.std() + sb.mean()
    out = rgba.copy()
    out[..., :3] = np.clip(a, 0, 255).astype(np.uint8)
    return out


def ueberblenden(unten, oben, gewicht):
    """Zwei RGBA-Bilder mit einem Gewicht (0 = unten, 1 = oben) mischen; Deckkraft = größere der beiden."""
    g = gewicht[..., None]
    col = unten[..., :3] * (1 - g) + oben[..., :3] * g
    a = np.maximum(unten[..., 3], oben[..., 3])
    return np.dstack([col, a]).astype(np.uint8)


def rand_weich(rgba, oben=0.08, unten=0.08):
    """Deckkraft oben und unten auslaufen lassen."""
    h = rgba.shape[0]
    v = np.linspace(0, 1, h)
    f = np.clip(v / max(1e-3, oben), 0, 1) * np.clip((1 - v) / max(1e-3, unten), 0, 1)
    out = rgba.copy()
    out[..., 3] = (out[..., 3] * f[:, None]).astype(np.uint8)
    return out


def vereinfachen(rgb_img, faktor=5, farben=20):
    """Wie mit dem Pinsel vereinfacht: verkleinern, Flächen zusammenfassen, Farbzahl senken, wieder vergrößern."""
    w, h = rgb_img.size
    klein = rgb_img.resize((max(8, w // faktor), max(8, h // faktor)), Image.LANCZOS).filter(ImageFilter.MedianFilter(3))
    klein = klein.quantize(farben, method=Image.Quantize.MEDIANCUT).convert("RGB")
    return klein.resize((w, h), Image.BICUBIC)
