# SPDX-License-Identifier: GPL-3.0-or-later (ruft die Blender-Schnittstelle bpy auf; siehe LIZENZ.md)
"""Malwerkzeug der Figurenfabrik: Texturtafeln aus Mustern (Schuppen, Leinenfalten, Perlenkragen ...), ohne fremde Bilder."""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SS = 2  # doppelt so groß malen, dann verkleinern: glatte Kanten


class Tafel:
    def __init__(s, groesse, felder, grund=(128, 128, 128)):
        s.n = groesse
        s.felder = felder
        s.img = Image.new("RGB", (groesse * SS, groesse * SS), grund)
        s.d = ImageDraw.Draw(s.img)
        s.rng = np.random.default_rng(7)

    def r(s, name):
        x0, y0, x1, y1 = s.felder[name]
        return x0 * SS, y0 * SS, x1 * SS, y1 * SS

    def rauschen(s, w, h, korn=1.0, weich=0.0):
        a = s.rng.random((max(1, int(h / korn)), max(1, int(w / korn))))
        im = Image.fromarray((a * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
        if weich > 0:
            im = im.filter(ImageFilter.GaussianBlur(weich))
        return np.asarray(im).astype(np.float32) / 255.0

    def fuelle(s, name, farbe, streuung=0.08, korn=3.0, hell=None):
        """Fläche in einer Farbe mit leichtem Korn; hell: Feld (h, w) mit Helligkeitsfaktoren."""
        x0, y0, x1, y1 = s.r(name)
        w, h = x1 - x0, y1 - y0
        f = 1.0 + (s.rauschen(w, h, korn * SS, 1.0) - 0.5) * 2 * streuung + (s.rauschen(w, h, 24 * SS, 6.0) - 0.5) * streuung
        if hell is not None:
            f = f * hell
        a = np.clip(np.array(farbe, np.float32)[None, None, :] * f[:, :, None], 0, 255).astype(np.uint8)
        s.img.paste(Image.fromarray(a), (x0, y0))
        s.d = ImageDraw.Draw(s.img)

    def gitter(s, name):
        x0, y0, x1, y1 = s.r(name)
        w, h = x1 - x0, y1 - y0
        yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
        return xx, yy, w, h

    def schuppen(s, name, farbe, sw=20, sh=16):
        """Schuppenpanzer: versetzte Reihen runder Plättchen, oben hell, unten dunkler Rand."""
        xx, yy, w, h = s.gitter(name)
        sw, sh = sw * SS, sh * SS
        sw = w / round(w / sw)      # geht rundum genau auf
        reihe = np.floor(yy / sh)
        lx = ((xx + (reihe % 2) * sw * 0.5) % sw) / sw
        ly = (yy % sh) / sh
        d = np.sqrt(((lx - 0.5) * 2) ** 2 + ly ** 2)
        innen = d <= 1.0
        hell = np.where(innen, 0.82 + 0.38 * (1 - ly) - 0.30 * (d > 0.8) + 0.22 * ((ly < 0.22) & (np.abs(lx - 0.5) < 0.3)), 0.42)
        hell *= 0.9 + 0.2 * s.rauschen(w, h, sw, 0)   # jedes Plättchen etwas anders
        s.fuelle(name, farbe, 0.05, 2.0, hell)

    def falten(s, name, farbe, abstand=11, saum=0.82):
        """Gefälteltes Leinen: senkrechte Falten, zum Saum hin grau und ausgefranst."""
        xx, yy, w, h = s.gitter(name)
        ab = w / round(w / (abstand * SS))
        hell = 0.88 + 0.13 * np.sin(xx / ab * 2 * math.pi) ** 3 + 0.03 * np.sin(xx / ab * 6.3 * 2.7)
        hell *= 1.0 - 0.22 * np.clip((yy / h - saum) / (1 - saum), 0, 1)
        hell *= 0.985 + 0.03 * (np.sin(yy / (1.3 * SS)) > 0.2)   # Webfäden, kaum sichtbar
        s.fuelle(name, farbe, 0.05, 2.0, hell)

    def gewebe(s, name, farbe):
        xx, yy, w, h = s.gitter(name)
        hell = 0.9 + 0.1 * (np.sin(xx / (1.6 * SS)) * np.sin(yy / (1.6 * SS)) > 0)
        s.fuelle(name, farbe, 0.1, 2.0, hell)

    def _feld(s, name):
        """Ausschnitt eines Felds zum Bemalen; mit _zurueck wieder einsetzen (so läuft nichts in Nachbarfelder)."""
        x0, y0, x1, y1 = s.r(name)
        sub = s.img.crop((x0, y0, x1, y1))
        return sub, ImageDraw.Draw(sub), x1 - x0, y1 - y0

    def _zurueck(s, name, sub):
        x0, y0, _, _ = s.r(name)
        s.img.paste(sub, (x0, y0))

    def band(s, name, v0, v1, farbe):
        sub, d, w, h = s._feld(name)
        d.rectangle([0, v0 * h, w, v1 * h], fill=farbe)
        s._zurueck(name, sub)

    def perlen(s, name, v0, v1, farben, breite=10):
        """Reihe länglicher Perlen in wechselnden Farben."""
        sub, d, w, h = s._feld(name)
        n = round(w / (breite * SS))
        bw = w / n
        for i in range(n):
            d.rounded_rectangle([i * bw + SS, v0 * h + SS, (i + 1) * bw - SS, v1 * h - SS], radius=bw * 0.35, fill=farben[i % len(farben)])
        s._zurueck(name, sub)

    def fransen(s, name, v0, farbe, breite=3):
        sub, d, w, h = s._feld(name)
        for x in range(0, w, breite * SS):
            laenge = (0.75 + 0.25 * s.rng.random()) * (1 - v0) * h
            d.line([x + SS, v0 * h, x + SS + (s.rng.random() - 0.5) * 2 * SS, v0 * h + laenge], fill=farbe, width=SS + 1)
        s._zurueck(name, sub)

    def linie(s, name, pts, farbe, breite=2.0):
        """Linienzug in Feldkoordinaten (Pixel der fertigen Tafel, vom Feld oben links aus)."""
        sub, d, w, h = s._feld(name)
        d.line([(x * SS, y * SS) for x, y in pts], fill=farbe, width=max(1, int(breite * SS)), joint="curve")
        s._zurueck(name, sub)

    def oval(s, name, cx, cy, rx, ry, farbe, rand=None, breite=1.0):
        sub, d, w, h = s._feld(name)
        d.ellipse([(cx - rx) * SS, (cy - ry) * SS, (cx + rx) * SS, (cy + ry) * SS], fill=farbe, outline=rand, width=int(breite * SS))
        s._zurueck(name, sub)

    def vieleck(s, name, pts, farbe):
        sub, d, w, h = s._feld(name)
        d.polygon([(x * SS, y * SS) for x, y in pts], fill=farbe)
        s._zurueck(name, sub)

    def udjat(s, name, cx, cy, g, farbe):
        """Das Auge des Horus, Mittelpunkt (cx, cy), Größe g (halbe Breite)."""
        def b(t0, t1, fx, fy, n=14):
            return [(cx + g * fx(t0 + (t1 - t0) * i / n), cy + g * fy(t0 + (t1 - t0) * i / n)) for i in range(n + 1)]
        br = max(1.5, g * 0.09)
        s.linie(name, b(0, math.pi, lambda t: -math.cos(t), lambda t: -0.42 * math.sin(t)), farbe, br)          # Oberlid
        s.linie(name, b(0, math.pi, lambda t: -math.cos(t) * 0.92, lambda t: 0.3 * math.sin(t)), farbe, br * 0.8)  # Unterlid
        s.linie(name, b(0, math.pi, lambda t: -math.cos(t) * 1.25 + 0.1, lambda t: -0.38 * math.sin(t) - 0.42), farbe, br * 1.2)  # Braue
        s.linie(name, [(cx + g, cy), (cx + g * 1.45, cy + g * 0.06)], farbe, br)                                 # Lidstrich
        s.oval(name, cx, cy - g * 0.04, g * 0.3, g * 0.3, farbe)                                                # Pupille
        s.linie(name, [(cx - g * 0.1, cy + g * 0.3), (cx - g * 0.12, cy + g * 0.95)], farbe, br)                 # Träne
        schweif = [(cx + g * (0.2 + 0.75 * i / 10), cy + g * (0.3 + 0.62 * (i / 10) ** 1.6)) for i in range(11)]
        mx, my = cx + g * 0.95, cy + g * 0.78                                                                   # Schweif mit Schnecke am Ende
        schweif += [(mx + g * 0.16 * (1 - j / 16) * math.cos(1.2 + j * 0.55), my + g * 0.16 * (1 - j / 16) * math.sin(1.2 + j * 0.55)) for j in range(13)]
        s.linie(name, schweif, farbe, br * 0.9)

    def schein(s, name, cx, cy, r, farbe, kraft=1.0):
        """Weicher Lichtfleck (für Leuchtkarten): in der Mitte die volle Farbe, zum Rand hin aus."""
        x0, y0, x1, y1 = s.r(name)
        a = np.asarray(s.img.crop((x0, y0, x1, y1))).astype(np.float32)
        yy, xx = np.mgrid[0:y1 - y0, 0:x1 - x0].astype(np.float32)
        d = np.sqrt((xx - cx * SS) ** 2 + (yy - cy * SS) ** 2) / (r * SS)
        f = np.clip(1 - d, 0, 1) ** 1.5 * kraft
        a = np.clip(a * (1 - f[:, :, None]) + np.array(farbe, np.float32)[None, None, :] * f[:, :, None], 0, 255)
        s.img.paste(Image.fromarray(a.astype(np.uint8)), (x0, y0))

    def risse(s, name, n, farbe, breite=1.0, laenge=60):
        """Verästelte Risse quer über ein Feld."""
        _, _, w, h = s._feld(name)
        for _ in range(n):
            x, y = s.rng.random() * w / SS, s.rng.random() * h / SS
            wi = s.rng.random() * 6.28
            pts = [(x, y)]
            for _ in range(int(laenge / 6)):
                wi += (s.rng.random() - 0.5) * 1.4
                x, y = x + math.cos(wi) * 6, y + math.sin(wi) * 6
                pts.append((x, y))
            s.linie(name, pts, farbe, breite)

    def fertig(s, pfad):
        s.img.resize((s.n, s.n), Image.LANCZOS).save(pfad)
