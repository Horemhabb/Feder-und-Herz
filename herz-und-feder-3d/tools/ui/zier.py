# Zierwerk der Oberfläche (Fassung 4.3): Rahmen, Knöpfe, Kartusche, Zierleisten, Kugelfassung, Fähnchen und Kleinteile.
# Alles wird hier gezeichnet und plastisch beleuchtet: Jede Form ist eine Höhenkarte (Fase durch Weichzeichnen),
# daraus entstehen Flächenneigung, Licht von links oben, Glanz, eine dunkle Patina in den Vertiefungen und ein
# weicher Schatten. Gravuren sind feine Rillen in der Höhenkarte. Gezeichnet wird vierfach groß und dann verkleinert.
#
# Aufruf (braucht nur Pillow und numpy):   python3 tools/ui/zier.py [ausgabeordner]
# Ergebnis: ui/zier/*.webp. Die Ränder der 9-Feld-Rahmen stehen in scripts/zier.gd (RAND) und müssen dazu passen.
import math, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

SS = 4                                   # Überabtastung
AUS = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "..", "ui", "zier")
SCHRIFT = os.path.join(os.path.dirname(__file__), "..", "..", "ui", "fonts", "almendra_fett.woff")
rng = np.random.default_rng(1924)        # das Jahr, in dem Carter den Sarg öffnete
os.makedirs(AUS, exist_ok=True)
GROESSEN = {}

# ---------------------------------------------------------------- Grundwerkzeug
def box(a, r):
    """Kastenfilter mit Radius r (Pixel), Ränder fortgesetzt."""
    r = int(r)
    if r < 1:
        return a
    for ax in (0, 1):
        p = np.pad(a, [(r + 1, r) if i == ax else (0, 0) for i in range(2)], mode="edge")
        c = np.cumsum(p, axis=ax, dtype=np.float64)
        if ax == 0:
            a = (c[2 * r + 1:] - c[:-2 * r - 1]) / (2 * r + 1)
        else:
            a = (c[:, 2 * r + 1:] - c[:, :-2 * r - 1]) / (2 * r + 1)
    return a.astype(np.float32)

def weich(a, sigma):
    """annähernd gaußsch: drei Kastenfilter"""
    if sigma <= 0.3:
        return a
    w = math.sqrt(12.0 * sigma * sigma / 3.0 + 1.0)
    r = max(1, int((w - 1) / 2))
    return box(box(box(a, r), r), r)

def rausch(h, w, skala, wrap=False):
    """weiches Rauschen 0..1 in Strukturgröße skala"""
    if wrap:
        n = rng.random((h, w)).astype(np.float32)
        f = np.fft.fft2(n)
        ky = np.fft.fftfreq(h)[:, None]
        kx = np.fft.fftfreq(w)[None, :]
        g = np.exp(-(kx * kx + ky * ky) * (math.pi * skala) ** 2 * 2.0)
        n = np.real(np.fft.ifft2(f * g)).astype(np.float32)
    else:
        n = weich(rng.random((h, w)).astype(np.float32), skala)
    n -= n.min()
    return n / max(1e-6, n.max())

def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)

class Blatt:
    """Zeichenfläche in Ausgabegröße w×h; intern SS-fach. Masken: erhaben (Metall), Rillen (Gravur)."""
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.W, self.H = w * SS, h * SS
        self.m = Image.new("L", (self.W, self.H), 0)
        self.g = Image.new("L", (self.W, self.H), 0)
        self.dm = ImageDraw.Draw(self.m)
        self.dg = ImageDraw.Draw(self.g)

    def P(self, pts):
        return [(x * SS, y * SS) for x, y in pts]

    def poly(self, pts, fill=255, rille=False):
        (self.dg if rille else self.dm).polygon(self.P(pts), fill=fill)

    def linie(self, pts, breite, rille=False, fill=255):
        d = self.dg if rille else self.dm
        d.line(self.P(pts), fill=fill, width=max(1, int(breite * SS)), joint="curve")
        r = breite * SS / 2
        for x, y in self.P([pts[0], pts[-1]]):
            d.ellipse([x - r, y - r, x + r, y + r], fill=fill)

    def kreis(self, cx, cy, r, fill=255, rille=False):
        d = self.dg if rille else self.dm
        d.ellipse([(cx - r) * SS, (cy - r) * SS, (cx + r) * SS, (cy + r) * SS], fill=fill)

    def ring(self, cx, cy, r, breite, rille=False):
        d = self.dg if rille else self.dm
        d.ellipse([(cx - r) * SS, (cy - r) * SS, (cx + r) * SS, (cy + r) * SS], outline=255, width=max(1, int(breite * SS)))

    def rrect(self, x0, y0, x1, y1, rad, fill=255, rille=False, breite=None):
        d = self.dg if rille else self.dm
        if breite is None:
            d.rounded_rectangle([x0 * SS, y0 * SS, x1 * SS, y1 * SS], radius=rad * SS, fill=fill)
        else:
            d.rounded_rectangle([x0 * SS, y0 * SS, x1 * SS, y1 * SS], radius=rad * SS, outline=fill, width=max(1, int(breite * SS)))

    def maske(self):
        return np.asarray(self.m, dtype=np.float32) / 255.0

    def rillen(self):
        return np.asarray(self.g, dtype=np.float32) / 255.0

def bez(p0, p1, p2, p3, n=28):
    out = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        out.append((u * u * u * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t * t * t * p3[0],
                    u * u * u * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t * t * t * p3[1]))
    return out

def tf(pts, cx, cy, s, rot=0.0, sx=1.0):
    """lokale Punkte (Einheit 1) drehen, skalieren und verschieben"""
    c, si = math.cos(rot), math.sin(rot)
    return [(cx + (x * sx * c - y * si) * s, cy + (x * sx * si + y * c) * s) for x, y in pts]

# ---------------------------------------------------------------- Licht und Werkstoff
LICHT = np.array([-0.42, -0.62, 0.66], dtype=np.float32)
LICHT /= np.linalg.norm(LICHT)

GOLD = [(0.00, (38, 22, 8)), (0.30, (102, 64, 22)), (0.52, (170, 120, 48)), (0.70, (214, 168, 82)),
        (0.86, (240, 208, 128)), (1.00, (255, 242, 196))]
BRONZE = [(0.00, (22, 15, 10)), (0.35, (66, 46, 26)), (0.6, (118, 84, 46)), (0.85, (168, 128, 74)), (1.0, (214, 180, 120))]
SILBERGOLD = [(0.0, (30, 24, 16)), (0.4, (120, 98, 60)), (0.7, (200, 176, 120)), (1.0, (250, 240, 210))]

def rampe(stops, t):
    t = np.clip(t, 0, 1)
    out = np.zeros(t.shape + (3,), np.float32)
    for (a, ca), (b, cb) in zip(stops[:-1], stops[1:]):
        k = ((t >= a) & (t <= b))[..., None]
        u = ((t - a) / (b - a))[..., None]
        out = np.where(k, np.array(ca, np.float32) * (1 - u) + np.array(cb, np.float32) * u, out)
    return out

def metall(hoehe, stops=GOLD, staerke=1.0, glanz=0.55, patina=0.35, band=0.18):
    """Höhenkarte (SS-Auflösung, 0..1) → Farbe. staerke: wie steil die Fasen wirken"""
    gy, gx = np.gradient(hoehe * staerke * SS * 2.2)
    n = np.dstack([-gx, -gy, np.ones_like(gx)])
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    diff = np.clip((n * LICHT).sum(2), 0, 1)
    hv = LICHT + np.array([0, 0, 1], np.float32)
    hv /= np.linalg.norm(hv)
    spec = np.clip((n * hv).sum(2), 0, 1) ** 28
    # Metall spiegelt die Umgebung: flache Flächen bekommen ein weiches Band von hell oben nach dunkel unten
    yy = np.linspace(0, 1, hoehe.shape[0], dtype=np.float32)[:, None]
    env = (0.5 - yy) * band
    t = diff * 0.95 + env + (rausch(*hoehe.shape, 3 * SS) - 0.5) * 0.06
    col = rampe(stops, t)
    col += np.array([255, 244, 214], np.float32) * spec[..., None] * glanz
    # Patina: in Vertiefungen dunkler, leicht grünlich-braun
    hol = np.clip(weich(hoehe, 3 * SS) - hoehe, 0, 1) * 4.0
    fleck = rausch(*hoehe.shape, 6 * SS)
    p = np.clip(hol * 0.8 + (fleck - 0.55) * 0.6, 0, 1) * patina
    col = col * (1 - p[..., None]) + np.array([48, 40, 22], np.float32) * p[..., None]
    return col

def relief(maske, fase, rillen=None, tiefe=0.55, rille_breite=0.6):
    """Höhe: Fase am Rand (fase in Ausgabepixeln), Rillen als Vertiefungen"""
    h = weich(maske, fase * SS * 0.6)
    h = smooth(0.0, 1.0, h * 1.6 - 0.15) * maske
    if rillen is not None:
        h = h - weich(rillen, rille_breite * SS) * tiefe
    return np.clip(h, -1, 1)

def leder(h, w, grund=(26, 19, 16), wrap=False):
    """dunkles, genarbtes Leder mit leichten Flecken (Ausgabe in SS-Auflösung)"""
    a = rausch(h, w, 1.2 * SS, wrap) - 0.5
    b = rausch(h, w, 5 * SS, wrap) - 0.5
    c = rausch(h, w, 30 * SS, wrap) - 0.5
    narbe = np.abs(rausch(h, w, 2.5 * SS, wrap) - 0.5)
    v = 1.0 + a * 0.18 + b * 0.22 + c * 0.35 - narbe * 0.35
    col = np.array(grund, np.float32)[None, None, :] * v[..., None]
    return col

def schatten(alpha, versatz=(1.5, 2.5), r=3.0, kraft=0.75):
    s = weich(alpha, r * SS)
    dx, dy = int(versatz[0] * SS), int(versatz[1] * SS)
    s = np.roll(np.roll(s, dy, axis=0), dx, axis=1)
    return np.clip(s * kraft, 0, 1)

def ueber(unten, oben):
    """RGBA-Felder (float, Farbe 0..255, Alpha 0..1) übereinanderlegen"""
    ca, aa = oben[..., :3], oben[..., 3:4]
    cb, ab = unten[..., :3], unten[..., 3:4]
    ao = aa + ab * (1 - aa)
    co = (ca * aa + cb * ab * (1 - aa)) / np.maximum(ao, 1e-6)
    return np.concatenate([co, ao], axis=2)

def rgba(col, alpha):
    return np.concatenate([col, alpha[..., None]], axis=2).astype(np.float32)

def leer(H, W):
    return np.zeros((H, W, 4), np.float32)

def speichern(feld, name, w, h, q=90, lossless=False):
    img = Image.fromarray(np.dstack([np.clip(feld[..., :3], 0, 255), np.clip(feld[..., 3] * 255, 0, 255)]).astype(np.uint8), "RGBA")
    img = img.resize((w, h), Image.LANCZOS)
    pfad = os.path.join(AUS, name + ".webp")
    img.save(pfad, "WEBP", quality=q, method=6, lossless=lossless)
    GROESSEN[name] = os.path.getsize(pfad)
    return img

def gold_teil(bl, fase=1.6, stops=GOLD, tiefe=0.55, patina=0.35, schatten_kraft=0.7, sch_r=2.5, versatz=(1.2, 2.0), glanz=0.55):
    """Metall aus der Maske eines Blatts, mit Schatten darunter"""
    m = bl.maske()
    h = relief(m, fase, bl.rillen(), tiefe)
    col = metall(h, stops, patina=patina, glanz=glanz)
    feld = rgba(col, m)
    if schatten_kraft > 0:
        s = schatten(m, versatz, sch_r, schatten_kraft)
        feld = ueber(rgba(np.zeros_like(col), s), feld)
    return feld

# ---------------------------------------------------------------- Ornamente (lokale Einheiten, Mitte 0/0)
def lotos(bl, cx, cy, s, rot=0.0):
    """Lotosblüte von der Seite: breites Mittelblatt, zwei Paar Seitenblätter, Kelch und Stiel. Spitze zeigt nach -y."""
    T = lambda p: tf(p, cx, cy, s, rot)
    for sx in (-1, 1):
        # äußere Blätter, weit ausgestellt
        bl.poly(T(bez((sx * 0.05, 0.42), (sx * 0.45, 0.25), (sx * 0.85, -0.2), (sx * 0.98, -0.72)) + bez((sx * 0.98, -0.72), (sx * 0.62, -0.5), (sx * 0.3, -0.2), (sx * 0.02, 0.1))))
        # innere Blätter
        bl.poly(T(bez((0.0, 0.3), (sx * 0.3, 0.05), (sx * 0.5, -0.5), (sx * 0.5, -0.92)) + bez((sx * 0.5, -0.92), (sx * 0.25, -0.62), (sx * 0.08, -0.3), (0.0, 0.0))))
    # Mittelblatt
    bl.poly(T(bez((0, 0.3), (-0.3, 0.0), (-0.2, -0.7), (0, -1.0)) + bez((0, -1.0), (0.2, -0.7), (0.3, 0.0), (0, 0.3))))
    # Kelch und Stiel
    bl.poly(T(bez((-0.42, 0.28), (-0.3, 0.52), (0.3, 0.52), (0.42, 0.28)) + [(0.1, 0.62), (-0.1, 0.62)]))
    bl.poly(T([(-0.08, 0.6), (0.08, 0.6), (0.06, 1.0), (-0.06, 1.0)]))
    # Gravur: Mittelrippen und Kelchrand
    bl.linie(T([(0, 0.18), (0, -0.8)]), 0.05 * s, rille=True)
    for sx in (-1, 1):
        bl.linie(T(bez((sx * 0.06, 0.25), (sx * 0.35, 0.0), (sx * 0.62, -0.3), (sx * 0.86, -0.62), 10)), 0.045 * s, rille=True)
        bl.linie(T(bez((sx * 0.03, 0.15), (sx * 0.2, -0.1), (sx * 0.35, -0.45), (sx * 0.42, -0.8), 10)), 0.04 * s, rille=True)
    bl.linie(T(bez((-0.38, 0.33), (-0.2, 0.42), (0.2, 0.42), (0.38, 0.33), 10)), 0.045 * s, rille=True)

def papyrusdolde(bl, cx, cy, s, rot=0.0):
    """Papyrusdolde: Glocke aus Strahlen auf einem Stiel"""
    T = lambda p: tf(p, cx, cy, s, rot)
    bl.poly(T(bez((-0.12, 0.2), (-0.5, -0.1), (-0.75, -0.6), (-0.6, -0.9)) + bez((-0.6, -0.9), (-0.2, -1.05), (0.2, -1.05), (0.6, -0.9)) + bez((0.6, -0.9), (0.75, -0.6), (0.5, -0.1), (0.12, 0.2))))
    bl.poly(T([(-0.1, 0.18), (0.1, 0.18), (0.06, 1.0), (-0.06, 1.0)]))
    for i in range(-3, 4):
        bl.linie(T([(0, 0.1), (i * 0.17, -0.92)]), 0.045 * s, rille=True)
    bl.linie(T(bez((-0.6, -0.9), (-0.2, -1.02), (0.2, -1.02), (0.6, -0.9), 12)), 0.05 * s, rille=True)

def feder(bl, cx, cy, s, rot=0.0):
    """Feder der Maat: aufrecht, oben nach außen gebogen"""
    T = lambda p: tf(p, cx, cy, s, rot)
    bl.poly(T(bez((0.0, 1.0), (-0.28, 0.4), (-0.3, -0.5), (0.05, -1.0)) + bez((0.05, -1.0), (0.32, -0.75), (0.26, 0.2), (0.0, 1.0))))
    bl.linie(T(bez((0.0, 1.0), (-0.05, 0.3), (-0.02, -0.4), (0.05, -0.95), 14)), 0.05 * s, rille=True)
    for i in range(1, 9):
        y = 0.85 - i * 0.2
        bl.linie(T([(0.0 - 0.01 * i, y), (-0.2, y - 0.12)]), 0.035 * s, rille=True)
        bl.linie(T([(0.0 - 0.01 * i, y), (0.2, y - 0.12)]), 0.035 * s, rille=True)

def udjat(bl, cx, cy, s):
    """Auge des Horus"""
    T = lambda p: tf(p, cx, cy, s)
    # Braue
    bl.poly(T(bez((-1.0, -0.55), (-0.5, -0.85), (0.4, -0.85), (1.05, -0.55)) + bez((1.05, -0.55), (0.4, -0.7), (-0.5, -0.7), (-1.0, -0.42))))
    # Auge als Ring (Umriss erhaben, innen offen)
    oben = bez((-0.95, 0.0), (-0.5, -0.45), (0.45, -0.45), (0.95, -0.02))
    unten = bez((0.95, -0.02), (0.45, 0.3), (-0.5, 0.3), (-0.95, 0.0))
    bl.linie(T(oben + unten), 0.12 * s)
    bl.kreis(cx + 0.0 * s, cy - 0.06 * s, 0.22 * s)
    # Schminkstrich nach außen, Träne und Spirale
    bl.linie(T([(0.9, -0.02), (1.35, -0.02)]), 0.1 * s)
    bl.linie(T([(-0.25, 0.22), (-0.3, 0.85)]), 0.1 * s)
    sp = [(0.05 + 0.32 * math.cos(a) * (1 - a / 9), 0.62 + 0.28 * math.sin(a) * (1 - a / 9)) for a in np.linspace(-math.pi * 0.9, math.pi * 1.6, 26)]
    bl.linie(T([(-0.05, 0.22)] + sp), 0.09 * s)

def skarabaeus(bl, cx, cy, s):
    T = lambda p: tf(p, cx, cy, s)
    bl.kreis(cx, cy + 0.15 * s, 0.62 * s)                      # Leib
    bl.poly(T(bez((-0.35, -0.45), (-0.3, -0.95), (0.3, -0.95), (0.35, -0.45))))   # Kopf
    for sx in (-1, 1):
        for i, yy in enumerate((-0.2, 0.15, 0.5)):
            bl.linie(T([(sx * 0.5, yy), (sx * 0.85, yy - 0.15 + i * 0.12), (sx * 1.0, yy + 0.05 + i * 0.12)]), 0.08 * s)
    bl.linie(T([(0, -0.4), (0, 0.75)]), 0.05 * s, rille=True)
    bl.linie(T(bez((-0.55, -0.35), (-0.2, -0.28), (0.2, -0.28), (0.55, -0.35), 10)), 0.05 * s, rille=True)

def uraeus(bl, cx, cy, s, sx=1):
    """aufgerichtete Kobra mit Schild, von der Seite"""
    T = lambda p: tf(p, cx, cy, s, 0.0, sx)
    bl.poly(T(bez((0.0, 1.0), (-0.45, 0.6), (-0.4, 0.0), (-0.1, -0.35)) + bez((-0.1, -0.35), (-0.35, -0.75), (0.1, -1.05), (0.25, -0.75)) + bez((0.25, -0.75), (0.35, -0.5), (0.2, -0.3), (0.05, -0.1)) + bez((0.05, -0.1), (-0.15, 0.3), (0.15, 0.7), (0.35, 1.0))))
    bl.linie(T(bez((0.25, -0.75), (0.1, -0.6), (-0.05, -0.4), (0.0, -0.2), 10)), 0.05 * s, rille=True)

def fluegelsonne(bl, cx, cy, s, breite=3.2, kobras=True):
    """Geflügelte Sonnenscheibe: Scheibe mit zwei Kobras, Schwingen nach beiden Seiten mit Federreihen"""
    for sx in (-1, 1):
        T = lambda p: tf(p, cx, cy, s, 0.0, sx)
        # Schwinge: oben gerade, unten in Federn auslaufend
        top = [(0.45, -0.18), (breite * 0.55, -0.3), (breite, -0.12)]
        unten = bez((breite, -0.12), (breite * 0.8, 0.05), (breite * 0.55, 0.42), (0.45, 0.32))
        bl.poly(T(top + unten))
        # Federreihen als Rillen
        for k in range(3):
            y0 = -0.12 + k * 0.14
            bl.linie(T(bez((0.55, y0), (breite * 0.4, y0 - 0.06), (breite * 0.7, y0 - 0.06 + k * 0.03), (breite * (0.95 - k * 0.12), y0 - 0.02 + k * 0.06), 16)), 0.035 * s, rille=True)
        for i in range(1, 12):
            x = 0.5 + i * (breite - 0.6) / 12.0
            yb = 0.32 - (x - 0.45) / (breite - 0.45) * 0.44
            bl.linie(T([(x, -0.05), (x + 0.06, yb + 0.02)]), 0.03 * s, rille=True)
        if kobras:
            uraeus(bl, cx + sx * 0.52 * s, cy + 0.25 * s, 0.34 * s, -sx)
    bl.kreis(cx, cy, 0.48 * s)
    bl.ring(cx, cy, 0.34 * s, 0.05 * s, rille=True)

# ---------------------------------------------------------------- 1. dunkle Tafel (9 Felder, Rand 60)
def tafel_dunkel():
    W = H = 192
    rand = 60
    bl = Blatt(W, H)
    # Fassung: kräftiger Außenring, feiner Innenring
    bl.rrect(5, 5, W - 5, H - 5, 9, breite=4.2)
    bl.rrect(13, 13, W - 13, H - 13, 5, breite=1.3)
    # Ecken: Winkelbeschlag entlang beider Kanten, Knauf in der Ecke, Lotos, der schräg ins Feld weist
    for (ex, ey, rot) in ((0, 0, math.pi * 0.75), (W, 0, math.pi * 1.25), (W, H, -math.pi * 0.25), (0, H, math.pi * 0.25)):
        sx = 1 if ex == 0 else -1
        sy = 1 if ey == 0 else -1
        X = lambda v: ex + sx * v
        Y = lambda v: ey + sy * v
        bl.poly([(X(3), Y(3)), (X(44), Y(3)), (X(52), Y(9)), (X(44), Y(15)), (X(15), Y(15)), (X(15), Y(44)), (X(9), Y(52)), (X(3), Y(44))])
        bl.linie([(X(20), Y(9)), (X(42), Y(9))], 0.9, rille=True)
        bl.linie([(X(9), Y(20)), (X(9), Y(42))], 0.9, rille=True)
        bl.kreis(X(12), Y(12), 9.5)
        bl.ring(X(12), Y(12), 6.2, 1.0, rille=True)
        bl.kreis(X(12), Y(12), 2.2, rille=True)
        lotos(bl, X(28), Y(28), 15, rot)
    m = bl.maske()
    h = relief(m, 1.8, bl.rillen(), 0.6)
    gold = metall(h, GOLD)
    # Grund: dunkles Leder, zur Mitte leicht heller, am Rand dunkel
    grund = np.zeros((bl.H, bl.W), np.float32)
    gimg = Image.new("L", (bl.W, bl.H), 0)
    ImageDraw.Draw(gimg).rounded_rectangle([7 * SS, 7 * SS, (W - 7) * SS, (H - 7) * SS], radius=8 * SS, fill=255)
    grund = np.asarray(gimg, np.float32) / 255
    yy, xx = np.mgrid[0:bl.H, 0:bl.W].astype(np.float32)
    d = np.minimum(np.minimum(xx, bl.W - xx), np.minimum(yy, bl.H - yy)) / SS
    vig = 0.62 + 0.38 * smooth(4, 34, d)
    lc = leder(bl.H, bl.W, (30, 22, 18)) * vig[..., None]
    # Prägung: eine feine Linie parallel zur Fassung, nur als Schatten und Licht
    pr = Image.new("L", (bl.W, bl.H), 0)
    ImageDraw.Draw(pr).rounded_rectangle([20 * SS, 20 * SS, (W - 20) * SS, (H - 20) * SS], radius=3 * SS, outline=255, width=int(0.8 * SS))
    pr = weich(np.asarray(pr, np.float32) / 255, 0.6 * SS)
    gy, gx = np.gradient(pr)
    lc *= (1.0 + np.clip((-gx * LICHT[0] - gy * LICHT[1]) * 6.0, -0.35, 0.35))[..., None]
    feld = rgba(lc, grund * 0.97)
    feld = ueber(feld, rgba(np.zeros_like(gold), schatten(m, (1.0, 1.8), 2.2, 0.8) * grund))
    feld = ueber(feld, rgba(gold, m))
    speichern(feld, "tafel_dunkel", W, H)
    # dieselbe Fassung ohne Grund: für gemalte Hintergründe (ui/zier/gemalt/…)
    rahmen = ueber(rgba(np.zeros_like(gold), schatten(m, (1.0, 1.8), 2.2, 0.8)), rgba(gold, m))
    speichern(rahmen, "rahmen_dunkel", W, H)

# ---------------------------------------------------------------- 2. schlanke Tafel (Meldungen, Hinweise, Einlagen; Rand 22)
def tafel_klein():
    W = H = 96
    bl = Blatt(W, H)
    bl.rrect(3, 3, W - 3, H - 3, 6, breite=2.0)
    for (ex, ey) in ((0, 0), (W, 0), (W, H), (0, H)):
        sx = 1 if ex == 0 else -1
        sy = 1 if ey == 0 else -1
        cx, cy = ex + sx * 7, ey + sy * 7
        bl.poly([(cx, cy - 6), (cx + 6, cy), (cx, cy + 6), (cx - 6, cy)])
        bl.kreis(cx, cy, 1.4, rille=True)
    m = bl.maske()
    gold = metall(relief(m, 1.0, bl.rillen(), 0.5), GOLD, patina=0.25)
    gimg = Image.new("L", (bl.W, bl.H), 0)
    ImageDraw.Draw(gimg).rounded_rectangle([4 * SS, 4 * SS, (W - 4) * SS, (H - 4) * SS], radius=5 * SS, fill=255)
    grund = np.asarray(gimg, np.float32) / 255
    yy = np.linspace(0, 1, bl.H, dtype=np.float32)[:, None] * np.ones((1, bl.W), np.float32)
    lc = leder(bl.H, bl.W, (24, 19, 18)) * (1.08 - yy * 0.25)[..., None]
    feld = rgba(lc, grund * 0.93)
    feld = ueber(feld, rgba(gold, m))
    speichern(feld, "tafel_klein", W, H)

# ---------------------------------------------------------------- 3. Knöpfe (Bogen: Spalten haupt | zweit, Zeilen ruhe, hover, gedrückt, gesperrt)
KW, KH = 128, 52
def knopf(art, zustand):
    bl = Blatt(KW, KH)
    if art == "haupt":
        bl.rrect(3, 3, KW - 3, KH - 3, 9)
        bl.rrect(8, 8, KW - 8, KH - 8, 6, rille=True, breite=0.9)
        for sx in (1, -1):
            x = 14 if sx == 1 else KW - 14
            bl.poly([(x, KH / 2 - 4.5), (x + 4.5, KH / 2), (x, KH / 2 + 4.5), (x - 4.5, KH / 2)], rille=True)
        m = bl.maske()
        h = relief(m, 2.4, bl.rillen(), 0.45)
        if zustand == "gedrueckt":
            h = relief(m, 2.4, bl.rillen(), 0.45) * 0.6
        stops = {"ruhe": GOLD, "hover": [(a, tuple(min(255, int(c * 1.12 + 10)) for c in col)) for a, col in GOLD],
                 "gedrueckt": [(a, tuple(int(c * 0.82) for c in col)) for a, col in GOLD], "gesperrt": BRONZE}[zustand]
        col = metall(h, stops, glanz=0.35 if zustand != "gesperrt" else 0.1, patina=0.25)
        if zustand == "gesperrt":
            g = col.mean(2, keepdims=True)
            col = col * 0.35 + g * 0.65
        feld = rgba(col, m * (0.75 if zustand == "gesperrt" else 1.0))
        feld = ueber(rgba(np.zeros_like(col), schatten(m, (0.8, 1.6) if zustand != "gedrueckt" else (0.3, 0.6), 1.8, 0.7)), feld)
    else:
        bl.rrect(3, 3, KW - 3, KH - 3, 8, breite=1.8)
        for sx in (1, -1):
            x = 3 if sx == 1 else KW - 3
            bl.poly([(x, KH / 2 - 7), (x + sx * 7, KH / 2), (x, KH / 2 + 7), (x - sx * 7, KH / 2)])
            bl.kreis(x + sx * 0.5, KH / 2, 1.3, rille=True)
        m = bl.maske()
        stops = {"ruhe": GOLD, "hover": [(a, tuple(min(255, int(c * 1.15 + 14)) for c in col)) for a, col in GOLD], "gedrueckt": GOLD, "gesperrt": BRONZE}[zustand]
        gold = metall(relief(m, 1.0, bl.rillen(), 0.5), stops, patina=0.25)
        if zustand == "gesperrt":
            gold = gold * 0.45 + gold.mean(2, keepdims=True) * 0.25
        gimg = Image.new("L", (bl.W, bl.H), 0)
        ImageDraw.Draw(gimg).rounded_rectangle([4 * SS, 4 * SS, (KW - 4) * SS, (KH - 4) * SS], radius=7 * SS, fill=255)
        grund = np.asarray(gimg, np.float32) / 255
        yy = np.linspace(0, 1, bl.H, dtype=np.float32)[:, None] * np.ones((1, bl.W), np.float32)
        basis = {"ruhe": (30, 23, 20), "hover": (52, 38, 26), "gedrueckt": (16, 12, 11), "gesperrt": (24, 22, 22)}[zustand]
        lc = leder(bl.H, bl.W, basis) * ((1.12 - yy * 0.3) if zustand != "gedrueckt" else (0.8 + yy * 0.3))[..., None]
        if zustand == "hover":
            # warmer Schein von innen
            yy2, xx2 = np.mgrid[0:bl.H, 0:bl.W].astype(np.float32)
            e = np.exp(-(((xx2 - bl.W / 2) / (bl.W * 0.42)) ** 2 + ((yy2 - bl.H / 2) / (bl.H * 0.6)) ** 2))
            lc += np.array([110, 70, 24], np.float32) * e[..., None] * 0.55
        feld = rgba(lc, grund * (0.94 if zustand != "gesperrt" else 0.7))
        feld = ueber(feld, rgba(gold, m * (0.6 if zustand == "gesperrt" else 1.0)))
    return feld

def knoepfe():
    reihen = []
    for z in ("ruhe", "hover", "gedrueckt", "gesperrt"):
        reihen.append(np.concatenate([knopf("haupt", z), knopf("zweit", z)], axis=1))
    speichern(np.concatenate(reihen, axis=0), "knoepfe", KW * 2, KH * 4)

# ---------------------------------------------------------------- 4. Kartusche für Titel (9 Felder waagrecht, Rand 44)
def kartusche():
    W, H = 256, 72
    bl = Blatt(W, H)
    # Ring mit runden Enden: außen kräftig, innen fein, rechts der Querbalken (das Band, das den Namen schützt)
    bl.rrect(10, 8, W - 18, H - 8, 28, breite=3.6)
    bl.rrect(16, 14, W - 24, H - 14, 22, breite=1.2)
    bl.rrect(W - 15, 6, W - 7, H - 6, 2)
    bl.linie([(W - 11, 10), (W - 11, H - 10)], 0.9, rille=True)
    # links ein kleiner Lotos als Abschluss
    lotos(bl, 10, H / 2, 10, -math.pi / 2)
    m = bl.maske()
    gold = metall(relief(m, 1.4, bl.rillen(), 0.5), GOLD)
    feld = rgba(np.zeros_like(gold), schatten(m, (1.0, 1.6), 2.0, 0.7))
    feld = ueber(feld, rgba(gold, m))
    speichern(feld, "kartusche", W, H)

# ---------------------------------------------------------------- 5. Zierleiste: Linie (verjüngt) und Mittelstück (Flügelsonne)
def trenner():
    W, H = 256, 12
    bl = Blatt(W, H)
    pts = [(0, H / 2), (W * 0.15, H / 2 - 1.4), (W, H / 2 - 1.6), (W, H / 2 + 1.6), (W * 0.15, H / 2 + 1.4)]
    bl.poly(pts)
    bl.linie([(W * 0.25, H / 2), (W - 2, H / 2)], 0.5, rille=True)
    for x in range(30, W, 26):
        bl.poly([(x, H / 2 - 3.2), (x + 3.2, H / 2), (x, H / 2 + 3.2), (x - 3.2, H / 2)])
    feld = gold_teil(bl, 0.6, sch_r=1.2, versatz=(0.5, 1.0), schatten_kraft=0.6)
    speichern(feld, "trenner_linie", W, H)
    W, H = 200, 48
    bl = Blatt(W, H)
    fluegelsonne(bl, W / 2, H / 2 + 2, 26, 3.6, True)
    speichern(gold_teil(bl, 1.0), "fluegelsonne", W, H)

# ---------------------------------------------------------------- 6. Fähnchen für Banner (9 Felder waagrecht, Rand 70)
def faehnchen():
    W, H = 384, 72
    bl = Blatt(W, H)
    band = Image.new("L", (bl.W, bl.H), 0)
    d = ImageDraw.Draw(band)
    # Mittelband und eingeschlagene Enden mit Schwalbenschwanz
    d.polygon([(x * SS, y * SS) for x, y in [(24, 10), (W - 24, 10), (W - 24, H - 10), (24, H - 10)]], fill=255)
    for sx in (1, -1):
        x0 = 0 if sx == 1 else W
        d.polygon([(x * SS, y * SS) for x, y in [(x0 + sx * 30, 16), (x0 + sx * 2, 18), (x0 + sx * 16, H / 2), (x0 + sx * 2, H - 18), (x0 + sx * 30, H - 16)]], fill=200)
    a = np.asarray(band, np.float32) / 255
    yy = np.linspace(0, 1, bl.H, dtype=np.float32)[:, None] * np.ones((1, bl.W), np.float32)
    rot = np.array([74, 22, 14], np.float32)
    col = rot[None, None, :] * (0.65 + 0.5 * np.sin(yy * math.pi))[..., None] * (0.9 + 0.2 * rausch(bl.H, bl.W, 8 * SS))[..., None]
    col = np.where((a < 0.9)[..., None], col * 0.55, col)        # Enden liegen im Schatten
    feld = rgba(col, np.clip(a / 0.78, 0, 1) * 0.92)
    # Goldkanten oben und unten
    for y in (11.5, H - 11.5):
        bl.linie([(26, y), (W - 26, y)], 1.6)
    bl.linie([(30, 15), (W - 30, 15)], 0.6)
    bl.linie([(30, H - 15), (W - 30, H - 15)], 0.6)
    for sx in (1, -1):
        x = 26 if sx == 1 else W - 26
        bl.poly([(x, H / 2 - 7), (x + sx * 6, H / 2), (x, H / 2 + 7), (x - sx * 6, H / 2)])
    m = bl.maske()
    gold = metall(relief(m, 0.8, None), GOLD, patina=0.2)
    feld = ueber(rgba(np.zeros_like(col), schatten(a, (1.5, 2.5), 3.0, 0.5)), feld)
    feld = ueber(feld, rgba(gold, m))
    speichern(feld, "faehnchen", W, H)

# ---------------------------------------------------------------- 7. Fassung der Kugeln (Leben, Kraft)
def kugel_fassung():
    W = H = 288
    c = W / 2
    bl = Blatt(W, H)
    bl.ring(c, c, 112, 12)
    bl.ring(c, c, 100, 2.0)
    bl.ring(c, c, 106, 0.9, rille=True)
    for i in range(24):
        a = i / 24 * math.tau
        if i % 6 in (0, 5, 1):
            continue
        bl.kreis(c + math.cos(a) * 112, c + math.sin(a) * 112, 2.0, rille=True)
    # oben ein Lotos, links und rechts eine Feder der Maat, unten ein Skarabäus auf seinem Sockel
    lotos(bl, c, c - 124, 21, 0.0)
    for sx in (-1, 1):
        feder(bl, c + sx * 127, c, 17, sx * (math.pi / 2 - 0.2))
        bl.kreis(c + sx * 112, c, 7)
    bl.rrect(c - 30, c + 106, c + 30, c + 120, 4)
    skarabaeus(bl, c, c + 124, 17)
    m = bl.maske()
    feld = rgba(np.zeros((bl.H, bl.W, 3), np.float32), schatten(m, (1.5, 3.0), 3.5, 0.8))
    feld = ueber(feld, rgba(metall(relief(m, 2.0, bl.rillen(), 0.6), GOLD), m))
    # innen ein dunkler Glasrand, der die Kugel in die Fassung setzt
    yy, xx = np.mgrid[0:bl.H, 0:bl.W].astype(np.float32)
    r = np.hypot(xx - c * SS, yy - c * SS) / SS
    innen = smooth(88, 99, r) * (1 - smooth(99, 102, r))
    feld = ueber(feld, rgba(np.zeros((bl.H, bl.W, 3), np.float32), innen * 0.7))
    speichern(feld, "kugel_fassung", W, H)

# ---------------------------------------------------------------- 8. Platz für Fähigkeiten und Gegenstände (vertieft, mit Fassung)
def platz():
    W = H = 96
    bl = Blatt(W, H)
    bl.rrect(2, 2, W - 2, H - 2, 9, breite=5.0)
    bl.rrect(10, 10, W - 10, H - 10, 4, breite=0.9, rille=True)
    for (ex, ey) in ((0, 0), (W, 0), (W, H), (0, H)):
        sx = 1 if ex == 0 else -1
        sy = 1 if ey == 0 else -1
        bl.kreis(ex + sx * 9, ey + sy * 9, 4.6)
        bl.kreis(ex + sx * 9, ey + sy * 9, 1.4, rille=True)
    for sx in (1, -1):   # Zierkerben in den Kantenmitten
        x = 4.5 if sx == 1 else W - 4.5
        bl.linie([(x, H / 2 - 7), (x, H / 2 + 7)], 0.8, rille=True)
        bl.linie([(W / 2 - 7, x), (W / 2 + 7, x)], 0.8, rille=True)
    m = bl.maske()
    gold = metall(relief(m, 1.6, bl.rillen(), 0.55), GOLD)
    gimg = Image.new("L", (bl.W, bl.H), 0)
    ImageDraw.Draw(gimg).rounded_rectangle([5 * SS, 5 * SS, (W - 5) * SS, (H - 5) * SS], radius=7 * SS, fill=255)
    grund = np.asarray(gimg, np.float32) / 255
    yy, xx = np.mgrid[0:bl.H, 0:bl.W].astype(np.float32)
    d = np.minimum(np.minimum(xx, bl.W - xx), np.minimum(yy, bl.H - yy)) / SS
    tief = 0.45 + 0.55 * smooth(5, 26, d)          # Vertiefung: zum Rand hin im Schatten
    lc = leder(bl.H, bl.W, (34, 28, 30)) * tief[..., None]
    feld = rgba(lc, grund)
    feld = ueber(feld, rgba(np.zeros_like(gold), schatten(m, (1.0, 1.6), 2.0, 0.7) * grund))
    feld = ueber(feld, rgba(gold, m))
    speichern(feld, "platz", W, H)
    # nur die Fassung, um sie über ein Bild zu legen (Fähigkeiten: das Zeichen füllt den Platz)
    rahmen = ueber(rgba(np.zeros_like(gold), schatten(m, (0.6, 1.0), 1.5, 0.8) * (1 - m)), rgba(gold, m))
    speichern(rahmen, "platz_rahmen", W, H)

# ---------------------------------------------------------------- 9. Platte der Leiste unten (9 Felder waagrecht, Rand 72)
def leiste_platte():
    W, H = 320, 96
    bl = Blatt(W, H)
    bl.rrect(26, 10, W - 26, H - 6, 6, breite=2.4)
    bl.linie([(30, 16), (W - 30, 16)], 0.8, rille=True)
    for sx in (1, -1):
        x0 = 0 if sx == 1 else W
        # Abschluss: Papyrusdolde, die zur Kugel hin geneigt ist
        papyrusdolde(bl, x0 + sx * 20, H / 2 + 4, 20, -sx * math.pi / 2)
        bl.kreis(x0 + sx * 30, 12, 4)
        bl.kreis(x0 + sx * 30, H - 8, 4)
    m = bl.maske()
    gold = metall(relief(m, 1.4, bl.rillen(), 0.55), GOLD)
    gimg = Image.new("L", (bl.W, bl.H), 0)
    ImageDraw.Draw(gimg).rounded_rectangle([28 * SS, 12 * SS, (W - 28) * SS, (H - 8) * SS], radius=5 * SS, fill=255)
    grund = np.asarray(gimg, np.float32) / 255
    yy = np.linspace(0, 1, bl.H, dtype=np.float32)[:, None] * np.ones((1, bl.W), np.float32)
    lc = leder(bl.H, bl.W, (26, 21, 20)) * (1.15 - yy * 0.45)[..., None]
    feld = rgba(lc, grund * 0.94)
    feld = ueber(rgba(np.zeros_like(gold), schatten(grund, (0, 3), 5, 0.6)), feld)
    feld = ueber(feld, rgba(gold, m))
    speichern(feld, "leiste_platte", W, H)

# ---------------------------------------------------------------- 10. Bildrahmen (Porträts; innen durchsichtig, Rand 30)
def bildrahmen():
    W = H = 128
    bl = Blatt(W, H)
    bl.rrect(2, 2, W - 2, H - 2, 6, breite=7)
    bl.rrect(11, 11, W - 11, H - 11, 3, breite=1.6)
    bl.rrect(5.5, 5.5, W - 5.5, H - 5.5, 4, breite=0.9, rille=True)
    for (ex, ey) in ((0, 0), (W, 0), (W, H), (0, H)):
        sx = 1 if ex == 0 else -1
        sy = 1 if ey == 0 else -1
        cx, cy = ex + sx * 11, ey + sy * 11
        bl.poly([(cx, cy - 10), (cx + 10, cy), (cx, cy + 10), (cx - 10, cy)])
        bl.kreis(cx, cy, 3.5, rille=True)
        bl.kreis(cx, cy, 1.6)
    feld = gold_teil(bl, 1.8, sch_r=2.0)
    # innen ein schmaler Schatten auf dem Bild
    yy, xx = np.mgrid[0:bl.H, 0:bl.W].astype(np.float32)
    d = np.minimum(np.minimum(xx, bl.W - xx), np.minimum(yy, bl.H - yy)) / SS
    inn = (1 - smooth(12, 20, d)) * smooth(10, 12.5, d)
    feld = ueber(rgba(np.zeros((bl.H, bl.W, 3), np.float32), inn * 0.6), feld)
    speichern(feld, "bildrahmen", W, H)

# ---------------------------------------------------------------- 11. Kleinteile: Udjat, Skarabäus, Feder, Lotos (frei stehend)
def kleinteile():
    for name, w, h, f in (
            ("udjat", 96, 64, lambda bl: udjat(bl, 46, 34, 26)),
            ("skarabaeus", 64, 64, lambda bl: skarabaeus(bl, 32, 32, 24)),
            ("feder", 32, 96, lambda bl: feder(bl, 16, 48, 42)),
            ("lotos", 64, 64, lambda bl: lotos(bl, 32, 34, 28)),
            ("papyrusdolde", 64, 80, lambda bl: papyrusdolde(bl, 32, 42, 34))):
        bl = Blatt(w, h)
        f(bl)
        speichern(gold_teil(bl, 1.2), name, w, h)

# ---------------------------------------------------------------- 12. Regler, Kästchen, Bildlaufleiste (Bogen 128 × 128)
def bedienteile():
    # Feld 0/0 (40×40): Reglerknopf; 40/0: Kästchen leer; 80/0: Kästchen mit Haken
    # 0/48 (64×16): Bahn des Reglers; 0/72 (16×48): Griff der Bildlaufleiste; 24/72 (16×48): Bahn der Bildlaufleiste
    W = H = 128
    feld = leer(H * SS, W * SS)
    bl = Blatt(W, H)
    bl.kreis(20, 20, 13)
    bl.ring(20, 20, 9, 1.0, rille=True)
    lotos(bl, 20, 21, 7)
    bl.rrect(44, 6, 74, 36, 5, breite=2.6)
    bl.rrect(84, 6, 114, 36, 5, breite=2.6)
    bl.linie([(90, 21), (97, 29), (109, 12)], 3.4)
    bl.rrect(2, 74, 14, 118, 5)
    bl.linie([(8, 84), (8, 108)], 0.8, rille=True)
    bl.rrect(1, 50, 63, 58, 4, breite=1.2)
    feld = gold_teil(bl, 1.2, sch_r=1.6, schatten_kraft=0.6)
    # dunkle Füllungen: Kästchen, Bahnen
    gimg = Image.new("L", (bl.W, bl.H), 0)
    d = ImageDraw.Draw(gimg)
    for r in ((45.5, 7.5, 72.5, 34.5), (85.5, 7.5, 112.5, 34.5), (2, 51, 62, 57), (26, 72, 38, 120)):
        d.rounded_rectangle([v * SS for v in r], radius=3 * SS, fill=255)
    g = np.asarray(gimg, np.float32) / 255
    feld = ueber(rgba(leder(bl.H, bl.W, (20, 16, 15)), g * 0.95), feld)
    speichern(feld, "bedienteile", W, H, lossless=True)

# ---------------------------------------------------------------- 13. Sternenhimmel der Nut (Fähigkeitenbaum, kachelbar)
def sterne():
    W = H = 256
    n = rausch(H, W, 40, wrap=True)
    n2 = rausch(H, W, 12, wrap=True)
    col = np.array([10, 12, 26], np.float32)[None, None, :] + (np.array([30, 22, 48], np.float32) * (n ** 2.2)[..., None]) + np.array([8, 14, 22], np.float32) * (n2 ** 3)[..., None]
    img = Image.fromarray(col.clip(0, 255).astype(np.uint8), "RGB")
    d = ImageDraw.Draw(img)
    for i in range(170):
        x, y = rng.random() * W, rng.random() * H
        h = rng.random() ** 3
        r = 0.4 + h * 1.4
        c = (int(200 + 55 * h), int(190 + 50 * h), int(150 + 70 * rng.random()))
        for ox in (-W, 0, W):
            for oy in (-H, 0, H):
                d.ellipse([x + ox - r, y + oy - r, x + ox + r, y + oy + r], fill=c)
    pfad = os.path.join(AUS, "sterne.webp")
    img.save(pfad, "WEBP", quality=82, method=6)
    GROESSEN["sterne"] = os.path.getsize(pfad)

# ---------------------------------------------------------------- 14. Schriftzug des Titels in getriebenem Gold
def schriftzug():
    text = "Herz und Feder"
    f = ImageFont.truetype(SCHRIFT, 118 * SS)
    x0, y0, x1, y1 = f.getbbox(text)
    W, H = (x1 - x0) // SS + 40, (y1 - y0) // SS + 40
    bl = Blatt(W, H)
    bl.dm.text((20 * SS - x0, 20 * SS - y0), text, font=f, fill=255)
    m = bl.maske()
    h = relief(m, 2.2, None)
    # Gravur: eine feine Linie innen entlang der Buchstaben
    innen = np.clip(weich(m, 2.2 * SS), 0, 1)
    rille = smooth(0.78, 0.84, innen) * (1 - smooth(0.86, 0.92, innen))
    h -= weich(rille, 0.5 * SS) * 0.35
    gold = metall(h, GOLD, staerke=1.2, glanz=0.7)
    glut = weich(m, 9 * SS)
    feld = rgba(np.tile(np.array([255, 190, 90], np.float32), (bl.H, bl.W, 1)), np.clip(glut * 0.35, 0, 1))
    feld = ueber(feld, rgba(np.zeros_like(gold), schatten(m, (2.5, 4.0), 3.0, 0.95)))
    feld = ueber(feld, rgba(gold, m))
    speichern(feld, "schriftzug", W, H, q=92)

# ---------------------------------------------------------------- Medaillon und Raute (Knoten im Fähigkeitenbaum)
def medaillons():
    W = H = 80
    c = W / 2
    bl = Blatt(W, H)
    bl.ring(c, c, 33, 6)
    bl.ring(c, c, 27.5, 1.0)
    for i in range(12):
        a = i / 12 * math.tau
        bl.kreis(c + math.cos(a) * 33, c + math.sin(a) * 33, 1.0, rille=True)
    speichern(gold_teil(bl, 1.2, sch_r=1.6), "medaillon", W, H)
    bl = Blatt(W, H)
    aussen = [(c, 3), (W - 3, c), (c, H - 3), (3, c)]
    innen = [(c, 11), (W - 11, c), (c, H - 11), (11, c)]
    bl.poly(aussen)
    bl.poly(innen, fill=0)
    bl.linie([(c, 14.5), (W - 14.5, c), (c, H - 14.5), (14.5, c), (c, 14.5)], 1.0)
    for p in aussen:
        bl.kreis(p[0] + (c - p[0]) * 0.1, p[1] + (c - p[1]) * 0.1, 3.2)
    speichern(gold_teil(bl, 1.2, sch_r=1.6), "raute", W, H)

# ---------------------------------------------------------------- 15. Windrose für die große Karte
def windrose():
    W = H = 96
    c = W / 2
    bl = Blatt(W, H)
    bl.ring(c, c, 30, 2.0)
    bl.ring(c, c, 22, 0.8, rille=True)
    for i in range(8):
        a = i / 8 * math.tau - math.pi / 2
        lang = 44 if i % 2 == 0 else 28
        q = (math.cos(a + math.pi / 2), math.sin(a + math.pi / 2))
        p = (c + math.cos(a) * lang, c + math.sin(a) * lang)
        bl.poly([p, (c + q[0] * 6, c + q[1] * 6), (c - q[0] * 6, c - q[1] * 6)])
        bl.linie([(c, c), p], 0.6, rille=True)
    bl.kreis(c, c, 6)
    speichern(gold_teil(bl, 1.0), "windrose", W, H)

if __name__ == "__main__":
    for f in (tafel_dunkel, tafel_klein, knoepfe, kartusche, trenner, faehnchen, kugel_fassung, platz, leiste_platte,
              bildrahmen, kleinteile, bedienteile, sterne, schriftzug, windrose, medaillons):
        f()
        print("fertig:", f.__name__)
    print("Größen (Bytes):")
    for k, v in sorted(GROESSEN.items()):
        print("  %-16s %7d" % (k, v))
    print("  %-16s %7d" % ("zusammen", sum(GROESSEN.values())))
