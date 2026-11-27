#!/usr/bin/env python3
# Werkzeugkasten für den Ton (nur numpy und ffmpeg): laden, schreiben, filtern, Hall, Tonhöhe erkennen und
# verschieben, Lautheit nach EBU R128 messen und angleichen, Spitzen begrenzen, Schleifen nahtlos machen.
# Die anderen Werkzeuge (musik.py, klaenge.py, stimme.py) bauen darauf auf.
import pathlib, subprocess
import numpy as np

HIER = pathlib.Path(__file__).resolve().parent
ROH = HIER / "roh"
AUDIO = HIER.parent.parent / "audio"

# ---------------------------------------------------------------- Ein und aus
def lade(pfad, sr=44100):
    r = subprocess.run(["ffmpeg", "-v", "error", "-i", str(pfad), "-ac", "1", "-ar", str(sr), "-f", "f32le", "-"], capture_output=True)
    return np.frombuffer(r.stdout, np.float32).astype(np.float64)

def schreibe(name, x, sr=44100, q=4, ordner=None, wav=False, aus_sr=None):
    """Mono als Ogg Vorbis nach audio/<name>.ogg (oder in einen anderen Ordner). q: Vorbis-Güte 0 bis 10.
    aus_sr: Abtastrate der Datei, wenn sie von der Rechenrate abweichen soll (32 kHz spart im Browser Rechenzeit)."""
    ordner = pathlib.Path(ordner) if ordner else AUDIO
    ordner.mkdir(parents=True, exist_ok=True)
    x = np.clip(np.nan_to_num(x), -1.0, 1.0)
    # leichtes Dithering gegen Stufen in sehr leisen Ausklängen
    roh = np.round(x * 32766 + np.random.default_rng(7).uniform(-0.5, 0.5, len(x))).astype("<i2").tobytes()
    ziel = ordner / (name + (".wav" if wav else ".ogg"))
    codec = ["-c:a", "pcm_s16le"] if wav else ["-c:a", "libvorbis", "-q:a", str(q)]
    rate = ["-ar", str(aus_sr)] if aus_sr and aus_sr != sr else []
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "s16le", "-ar", str(sr), "-ac", "1", "-i", "-"] + rate + codec + [str(ziel)], input=roh, check=True)
    return ziel

# ---------------------------------------------------------------- Filter im Frequenzbereich
def filt(x, fn, sr=44100, kreis=False):
    """Filter im Frequenzbereich. kreis=True: das Signal gilt als Schleife (Ende geht in den Anfang über).
    Sonst wird mit Stille aufgefüllt, damit nichts vom Ende an den Anfang gerät."""
    n = len(x)
    pad = 0 if kreis else max(int(0.5 * sr), n // 4)
    N = n + pad
    X = np.fft.rfft(x, N)
    f = np.fft.rfftfreq(N, 1 / sr)
    return np.fft.irfft(X * fn(f), N)[:n]

def hoch(f, grenze, ordnung=2):
    return 1 / np.sqrt(1 + (grenze / np.maximum(f, 1e-3)) ** (2 * ordnung))

def tief(f, grenze, ordnung=2):
    return 1 / np.sqrt(1 + (f / grenze) ** (2 * ordnung))

def glocke(f, mitte, breite, db):
    """Glocke in Oktaven: breite ist die Standardabweichung in Oktaven."""
    return 10 ** (db / 20 * np.exp(-0.5 * (np.log2(np.maximum(f, 1) / mitte) / breite) ** 2))

def regal_hoch(f, grenze, db):
    """Höhenregal: über der Grenze um db angehoben (weicher Übergang über eine Oktave)."""
    s = 1 / (1 + (grenze / np.maximum(f, 1)) ** 2)
    return 10 ** (db / 20 * s)

def regal_tief(f, grenze, db):
    s = 1 / (1 + (np.maximum(f, 1) / grenze) ** 2)
    return 10 ** (db / 20 * s)

# ---------------------------------------------------------------- Pegel
def db(x):
    return 20 * np.log10(np.maximum(x, 1e-12))

def spitze(x):
    return float(np.abs(x).max()) if len(x) else 0.0

def norm(x, ziel=1.0):
    return x / max(1e-9, spitze(x)) * ziel

def lufs(x, sr=44100):
    """Lautheit nach ITU-R BS.1770 (K-Bewertung, Blöcke von 400 ms, absolute und relative Schwelle)."""
    if len(x) < int(0.4 * sr):
        x = np.pad(x, (0, int(0.4 * sr) - len(x) + 1))
    k = filt(x, lambda f: regal_hoch(f, 1500, 4.0) * hoch(f, 38, 1), sr)
    blk, hop = int(0.4 * sr), int(0.1 * sr)
    n = 1 + (len(k) - blk) // hop
    if n < 1:
        return -70.0
    q = np.square(k)
    c = np.concatenate([[0], np.cumsum(q)])
    m = (c[np.arange(n) * hop + blk] - c[np.arange(n) * hop]) / blk
    l = -0.691 + 10 * np.log10(np.maximum(m, 1e-12))
    m = m[l > -70]
    if len(m) == 0:
        return -70.0
    rel = -0.691 + 10 * np.log10(m.mean()) - 10
    l2 = -0.691 + 10 * np.log10(np.maximum(m, 1e-12))
    m = m[l2 > rel]
    return float(-0.691 + 10 * np.log10(m.mean())) if len(m) else -70.0

def auf_lufs(x, ziel, sr=44100, spitze_max=-1.0):
    """Auf eine Lautheit bringen, danach Spitzen weich begrenzen."""
    g = 10 ** ((ziel - lufs(x, sr)) / 20)
    return begrenzen(x * g, spitze_max, sr)

def begrenzen(x, decke_db=-1.0, sr=44100, vorlauf=0.004, loslassen=0.08):
    """Spitzenbegrenzer mit Vorausschau: hält alles unter decke_db, ohne zu knacken."""
    decke = 10 ** (decke_db / 20)
    a = np.abs(x)
    if a.max() <= decke:
        return x
    w = max(1, int(vorlauf * sr))
    # gleitendes Maximum über das Vorausschau-Fenster
    pad = np.pad(a, (0, w), mode="edge")
    from numpy.lib.stride_tricks import sliding_window_view
    mx = sliding_window_view(pad, w + 1).max(axis=1)[: len(x)]
    g = np.minimum(1.0, decke / np.maximum(mx, 1e-9))
    # weich loslassen: Verstärkung steigt nur langsam wieder (einseitiges Glätten, rückwärts und vorwärts)
    r = np.exp(-1 / (loslassen * sr))
    out = g.copy()
    for i in range(1, len(out)):
        if out[i] > out[i - 1]:
            out[i] = out[i - 1] * r + out[i] * (1 - r)
    # Anstieg glätten, damit die Absenkung nicht hart einsetzt
    k = np.hanning(2 * w + 1)
    k /= k.sum()
    out = np.minimum(out, np.convolve(out, k, mode="same"))
    return x * out

# ---------------------------------------------------------------- Hüllkurven und Schnitt
def einblenden(x, sek, sr=44100):
    n = min(len(x), int(sek * sr))
    if n > 0:
        x = x.copy()
        x[:n] *= np.sin(np.linspace(0, np.pi / 2, n)) ** 2
    return x

def ausblenden(x, sek, sr=44100):
    n = min(len(x), int(sek * sr))
    if n > 0:
        x = x.copy()
        x[-n:] *= np.cos(np.linspace(0, np.pi / 2, n)) ** 2
    return x

def stille_weg(x, schwelle_db=-45.0, sr=44100, vorn=0.004, hinten=0.05):
    """Stille am Anfang und Ende abschneiden (bezogen auf die Spitze), mit kurzen Blenden."""
    s = spitze(x) * 10 ** (schwelle_db / 20)
    laut = np.nonzero(np.abs(x) > s)[0]
    if len(laut) == 0:
        return x
    a = max(0, laut[0] - int(vorn * sr))
    e = min(len(x), laut[-1] + int(hinten * sr))
    return ausblenden(einblenden(x[a:e], vorn, sr), hinten, sr)

def ab_anschlag(x, sr=44100, vor=0.003):
    """Beginnt kurz vor dem ersten deutlichen Anschlag (für Instrumenttöne)."""
    e = np.abs(x)
    s = spitze(x) * 0.08
    i = int(np.argmax(e > s))
    return x[max(0, i - int(vor * sr)):]

# ---------------------------------------------------------------- Raum
def nachhall_impuls(sek, sr=44100, dunkel=3000.0, dichte_ms=12.0, seed=1):
    """Künstlicher Raum: Rauschen, das exponentiell abklingt und dabei dunkler wird."""
    rng = np.random.default_rng(seed)
    n = int(sek * sr)
    t = np.arange(n) / sr
    roh = rng.normal(0, 1, n) * np.exp(-6.9 * t / sek)
    # zeitabhängiges Dunkelwerden: zwei Fassungen mischen
    hell = filt(roh, lambda f: tief(f, dunkel * 2.5, 1), sr)
    dumpf = filt(roh, lambda f: tief(f, dunkel * 0.5, 1), sr)
    m = np.clip(t / sek * 1.6, 0, 1)
    ir = hell * (1 - m) + dumpf * m
    # weiches Einsetzen (frühe Reflexionen fehlen absichtlich: klingt weiter weg)
    ein = int(dichte_ms / 1000 * sr)
    ir[:ein] *= np.linspace(0, 1, ein) ** 2
    return ir / np.sqrt(np.sum(ir ** 2))

def hall(x, ir, mix=0.25, kreis=False):
    """Faltung mit einem Raum. kreis=True faltet ringförmig: der Nachhall vom Ende klingt am Anfang weiter,
    so bleibt eine Schleife nahtlos."""
    if kreis:
        n = len(x)
        h = ir[:n] if len(ir) >= n else np.pad(ir, (0, n - len(ir)))
        nass = np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(h), n)
        return x * (1 - mix) + nass * mix * 1.0
    n = len(x) + len(ir) - 1
    N = 1 << int(np.ceil(np.log2(n)))
    nass = np.fft.irfft(np.fft.rfft(x, N) * np.fft.rfft(ir, N), N)[:n]
    y = np.pad(x, (0, len(ir) - 1)) * (1 - mix) + nass * mix
    return y

# ---------------------------------------------------------------- Tonhöhe
def grundton(x, sr=44100, fmin=60.0, fmax=1500.0, von=0.05, lang=0.25):
    """Grundfrequenz nach YIN in einem Ausschnitt (von, lang in Sekunden). Gibt (Hz, Sicherheit 0–1)."""
    a = int(von * sr)
    w = x[a:a + int(lang * sr)]
    if len(w) < int(0.05 * sr):
        w = x[: int(lang * sr)]
    W = len(w) // 2
    tmax = min(int(sr / fmin), W - 1)
    tmin = max(2, int(sr / fmax))
    # Differenzfunktion über FFT
    xx = w[:W + tmax]
    c = np.concatenate([[0], np.cumsum(xx ** 2)])
    e0 = c[W] - c[0]
    et = c[np.arange(tmax) + W] - c[np.arange(tmax)]
    N = 1 << int(np.ceil(np.log2(len(xx) * 2)))
    F = np.fft.rfft(xx, N)
    K = np.fft.rfft(w[:W][::-1], N)
    r = np.fft.irfft(F * K, N)[W - 1: W - 1 + tmax]
    d = e0 + et - 2 * r
    d[0] = 0
    cm = np.cumsum(d[1:])
    dn = np.ones_like(d)
    dn[1:] = d[1:] * np.arange(1, tmax) / np.maximum(cm, 1e-12)
    kand = np.nonzero(dn[tmin:] < 0.15)[0]
    if len(kand):
        t = tmin + kand[0]
        while t + 1 < tmax and dn[t + 1] < dn[t]:
            t += 1
    else:
        t = tmin + int(np.argmin(dn[tmin:]))
    # parabolisch verfeinern
    t0 = t
    if 1 <= t < tmax - 1:
        a_, b_, c_ = dn[t - 1], dn[t], dn[t + 1]
        nenner = a_ - 2 * b_ + c_
        if nenner > 1e-12:
            t = t + float(np.clip(0.5 * (a_ - c_) / nenner, -1.0, 1.0))
    return sr / max(1.0, t), float(max(0.0, 1.0 - dn[t0]))

def hz_zu_midi(f):
    return 69 + 12 * np.log2(f / 440.0)

def midi_zu_hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)

NAMEN = ["C", "Cis", "D", "Es", "E", "F", "Fis", "G", "Gis", "A", "B", "H"]

def notenname(m):
    m = int(round(m))
    return "%s%d" % (NAMEN[m % 12], m // 12 - 1)

def verschieben(x, halbtoene):
    """Tonhöhe ändern durch schnelleres oder langsameres Abspielen (wie ein Sampler): Länge ändert sich mit."""
    if abs(halbtoene) < 1e-4:
        return x.copy()
    k = 2 ** (halbtoene / 12)
    n = int(len(x) / k)
    return np.interp(np.arange(n) * k, np.arange(len(x)), x)

# ---------------------------------------------------------------- Schleifen
def nahtlos(x, blende, sr=44100):
    """Macht aus einem Stück eine Schleife: das Ende wird über `blende` Sekunden in den Anfang geblendet
    (gleiche Leistung), das Ergebnis ist um die Blende kürzer."""
    n = int(blende * sr)
    if n * 2 >= len(x):
        n = len(x) // 3
    kopf, rumpf, schwanz = x[:n], x[n:len(x) - n], x[len(x) - n:]
    t = np.linspace(0, np.pi / 2, n)
    misch = schwanz * np.cos(t) + kopf * np.sin(t)
    return np.concatenate([rumpf, misch])

def naht(x, sr=44100):
    """Prüft eine Schleife: Pegelunterschied der Ränder in dB und Sprung an der Naht (relativ, < 1 ist unauffällig)."""
    h = int(0.5 * sr)
    d = db(np.sqrt(np.mean(x[:h] ** 2))) - db(np.sqrt(np.mean(x[-h:] ** 2)))
    sprung = abs(x[-1] - x[0]) / (np.percentile(np.abs(np.diff(x)), 99) + 1e-9)
    return float(d), float(sprung)

# ---------------------------------------------------------------- Bild (Spektrogramm, zum Ansehen statt Hören)
def spektrogramm(pfad, png, breite=1000, hoehe=300):
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(pfad), "-lavfi",
                    "showspectrumpic=s=%dx%d:legend=1:fscale=log:color=intensity:scale=log" % (breite, hoehe), str(png)], check=True)
