#!/usr/bin/env python3
# Baut die Schrittgeräusche (audio/step_sand1–4.ogg, audio/step_stein1–4.ogg) aus vier Rohaufnahmen von ElevenLabs
# (Sound Effects v2, tools/ton/roh/). Die alten Schritte klangen hohl: fast die ganze Energie lag zwischen 500 und
# 2000 Hz, wie in einer Kiste. Hier wird jeder Schritt aus drei Schichten gemischt:
#   Körper   kurzer, tiefer Stoß (Fuß setzt auf)
#   Sohle    das eigentliche Geräusch aus der Aufnahme, in den Mitten ausgedünnt
#   Körner   feines Rieseln obenauf (Sand knirscht, Staub auf Stein)
# Aufruf: python3 tools/ton/schritte.py   (braucht numpy und ffmpeg)
import pathlib, subprocess
import numpy as np

HIER = pathlib.Path(__file__).resolve().parent
ZIEL = HIER.parent.parent / "audio"
SR = 44100

def lade(name):
    r = subprocess.run(["ffmpeg", "-v", "error", "-i", str(HIER / "roh" / name), "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"], capture_output=True).stdout
    return np.frombuffer(r, np.float32).astype(np.float64)

def stueck(x, von, lang):
    a = int(von * SR)
    return x[a:a + int(lang * SR)].copy()

def filt(x, fn):
    """Filter im Frequenzbereich: fn(f) gibt die Verstärkung je Frequenz."""
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    return np.fft.irfft(X * fn(f), len(x))

def glocke(f, mitte, breite, db):
    return 10 ** (db / 20 * np.exp(-0.5 * (np.log2(np.maximum(f, 1) / mitte) / breite) ** 2))

def hoch(f, grenze):
    return 1 / np.sqrt(1 + (grenze / np.maximum(f, 1)) ** 4)

def tief(f, grenze):
    return 1 / np.sqrt(1 + (f / grenze) ** 4)

def norm(x, spitze=1.0):
    return x / max(1e-9, np.abs(x).max()) * spitze

def huelle(n, an=0.003, ab=0.12, kurve=2.2):
    t = np.arange(n) / SR
    return np.minimum(1, t / an) * np.exp(-np.maximum(0, t - an) / ab * kurve)

def tempo(x, faktor):
    """Etwas höher oder tiefer abspielen, damit keine zwei Schritte gleich klingen."""
    n = int(len(x) / faktor)
    return np.interp(np.linspace(0, len(x) - 1, n), np.arange(len(x)), x)

def stoss(n, freq, rng):
    t = np.arange(n) / SR
    f = freq * (1 + 0.6 * np.exp(-t / 0.012))          # fällt in den ersten Millisekunden ab wie ein dumpfer Schlag
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.035)
    return s + 0.15 * filt(rng.normal(0, 1, n), lambda q: tief(q, 220)) * np.exp(-t / 0.02)

def schreibe(name, x):
    x = norm(x, 0.89)
    x[-int(0.02 * SR):] *= np.linspace(1, 0, int(0.02 * SR))
    roh = (x * 32767).astype("<i2").tobytes()
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "s16le", "-ar", str(SR), "-ac", "1", "-i", "-", "-c:a", "libvorbis", "-q:a", "5",
                    str(ZIEL / (name + ".ogg"))], input=roh, check=True)

def main():
    rng = np.random.default_rng(3)
    sand_a, sand_b, stein_a, stein_b = lade("sand_a.mp3"), lade("sand_b.mp3"), lade("stein_a.mp3"), lade("stein_b.mp3")
    N = int(0.36 * SR)
    def auf(x):
        return np.pad(x, (0, max(0, N - len(x))))[:N]
    # ---- Sand: weiches Knirschen, darunter ein leiser Tritt
    knirsch = [stueck(sand_a, 0.02, 0.32), stueck(sand_a, 0.05, 0.32), stueck(sand_a, 0.0, 0.32), stueck(sand_a, 0.08, 0.32)]
    for i in range(4):
        sohle = auf(tempo(knirsch[i], [1.0, 0.88, 1.1, 0.94][i]))
        sohle = filt(sohle, lambda f: hoch(f, 180) * glocke(f, 900, 0.9, -5) * tief(f, 9000))
        sohle = norm(sohle) * huelle(N, 0.004, 0.16)
        koerner = auf(stueck(sand_b, 0.05 + 0.17 * i, 0.34))
        koerner = norm(filt(koerner, lambda f: hoch(f, 2500) * tief(f, 11000))) * huelle(N, 0.03, 0.2, 1.6)
        tritt = norm(stoss(N, 82 + 6 * i, rng))
        schreibe("step_sand%d" % (i + 1), 1.0 * sohle + 0.22 * koerner + 0.3 * tritt)
    # ---- Stein: fester, trockener Tritt mit etwas Staub unter der Sohle
    schlag = [stueck(stein_a, 0.355, 0.3), stueck(stein_a, 0.985, 0.3), stueck(stein_a, 1.545, 0.3), stueck(stein_a, 0.985, 0.3)]
    tipp = stueck(stein_b, 0.05, 0.25)
    for i in range(4):
        sohle = auf(tempo(schlag[i], [1.0, 1.05, 0.95, 1.12][i]))
        # die Aufnahme ist dumpf und dröhnt um 300 bis 800 Hz: dort ausdünnen, Tiefe behalten
        sohle = filt(sohle, lambda f: hoch(f, 70) * glocke(f, 520, 0.7, -6) * glocke(f, 300, 0.6, -3 if i == 2 else 0) * glocke(f, 110, 0.7, 2) * glocke(f, 1500, 1.0, 4))
        sohle = norm(sohle) * huelle(N, 0.002, 0.11)
        klick = auf(tempo(tipp, [1.0, 0.9, 1.12, 1.04][i]))
        klick = norm(filt(klick, lambda f: hoch(f, 900) * tief(f, 6500))) * huelle(N, 0.001, 0.05)
        staub = auf(stueck(sand_b, 0.1 + 0.2 * i, 0.3))
        staub = norm(filt(staub, lambda f: hoch(f, 2500) * tief(f, 8000))) * huelle(N, 0.015, 0.09, 1.8)
        schreibe("step_stein%d" % (i + 1), 1.0 * sohle + 0.2 * klick + 0.08 * staub)

if __name__ == "__main__":
    main()
