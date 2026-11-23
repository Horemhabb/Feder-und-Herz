#!/usr/bin/env python3
# Baut Schritte und Kampfgeräusche (audio/*.ogg) aus Rohaufnahmen von ElevenLabs (Sound Effects v2, tools/ton/roh_klang/).
# Jede Aufnahme wird so geschnitten, dass der Klang bei 0 ms einsetzt (kein Leerlauf davor), hinten weich ausgeblendet,
# von Tiefen unter 70 Hz befreit und auf eine gemeinsame Lautheit (LUFS) gebracht; die Spitze bleibt unter -2,5 dBFS (Vorbis schwingt beim Entpacken bis zu 2 dB über).
# Aufruf: python3 -I tools/ton/klang_bauen.py   (braucht numpy und ffmpeg; schreibt nach audio/ und druckt die Messwerte)
import pathlib, re, subprocess, sys
import numpy as np

HIER = pathlib.Path(__file__).resolve().parent
ROH = HIER / "roh_klang"
ZIEL = HIER.parent.parent / "audio"
SR = 44100

# (Ziel, Rohdatei, Länge s, Ausklang s, Schwelle dB für den Einsatz, Ziel-LUFS)
SCHRITT = -22.5
SPEC = [
    # Gehen: länger, weicher
    ("step_sand_geh1", "sandgeh2_2.mp3", 0.30, 0.10, -24, SCHRITT),
    ("step_sand_geh2", "sandgeh2_3.mp3", 0.30, 0.10, -24, SCHRITT),
    ("step_sand_geh3", "sandgeh_1.mp3", 0.30, 0.10, -24, SCHRITT),
    ("step_sand_geh4", "sandgeh2_1.mp3", 0.30, 0.12, -24, SCHRITT),
    ("step_stein_geh1", "steingeh_1.mp3", 0.30, 0.10, -24, SCHRITT),
    ("step_stein_geh2", "steingeh_4.mp3", 0.30, 0.10, -24, SCHRITT),
    ("step_stein_geh3", "steingeh2_4.mp3", 0.30, 0.10, -24, SCHRITT),
    ("step_stein_geh4", "steingeh_2.mp3", 0.30, 0.10, -26, SCHRITT),
    # Laufen: kürzer, härter
    ("step_sand_lauf1", "sandlauf2_2.mp3", 0.24, 0.08, -24, SCHRITT),
    ("step_sand_lauf2", "sandlauf2_3.mp3", 0.24, 0.08, -24, SCHRITT),
    ("step_sand_lauf3", "sandlauf_1.mp3", 0.24, 0.08, -24, SCHRITT),
    ("step_sand_lauf4", "sandlauf_3.mp3", 0.24, 0.08, -24, SCHRITT),
    ("step_stein_lauf1", "steinlauf2_1.mp3", 0.22, 0.08, -24, SCHRITT),
    ("step_stein_lauf2", "steinlauf_4.mp3", 0.22, 0.08, -24, SCHRITT),
    ("step_stein_lauf3", "steinlauf_1.mp3", 0.22, 0.08, -24, SCHRITT),
    ("step_stein_lauf4", "steinlauf2_4.mp3", 0.22, 0.08, -24, SCHRITT),
    # Kampf
    ("swing1", "swing_1.mp3", 0.45, 0.15, -30, -20.0),
    ("swing2", "swing_3.mp3", 0.45, 0.15, -30, -20.0),
    ("swing3", "swing_4.mp3", 0.45, 0.15, -30, -20.0),
    ("hit1", "hit_1.mp3", 0.50, 0.18, -30, -14.5),
    ("hit2", "hit_3.mp3", 0.50, 0.18, -30, -14.5),
    ("hit3", "hit_2.mp3", 0.50, 0.20, -30, -14.5),
    ("hurt1", "hurt_1.mp3", 0.45, 0.16, -30, -14.5),
    ("hurt2", "hurt_3.mp3", 0.45, 0.16, -30, -14.5),
    ("hurt3", "hurt_2.mp3", 0.45, 0.16, -30, -14.5),
    ("skel_die1", "skeldie_3.mp3", 1.10, 0.40, -34, -19.0),
    ("skel_die2", "skeldie_1.mp3", 0.85, 0.30, -34, -19.0),
    ("skel_die3", "skeldie_4.mp3", 1.10, 0.40, -34, -19.0),
    ("skel_attack1", "skelatk_1.mp3", 0.35, 0.12, -30, -19.0),
    ("skel_attack2", "skelatk_3.mp3", 0.45, 0.15, -30, -19.0),
    ("skel_attack3", "skelatk_4.mp3", 0.45, 0.15, -30, -19.0),
]

def lade(pfad):
    r = subprocess.run(["ffmpeg", "-v", "error", "-i", str(pfad), "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"], capture_output=True).stdout
    return np.frombuffer(r, np.float32).astype(np.float64)

def hochpass(x, fg=70.0):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    X *= 1.0 / (1.0 + (fg / np.maximum(f, 1e-6)) ** 4)
    return np.fft.irfft(X, len(x))

def lufs(x):
    """Lautheit mit 1,2 s Stille angehängt (ebur128 braucht mindestens 0,4 s); gleiche Messung für alle Dateien."""
    r = subprocess.run(["ffmpeg", "-nostats", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", "-",
                        "-af", "apad=whole_dur=1.2,ebur128=peak=true", "-f", "null", "-"],
                       input=x.astype(np.float32).tobytes(), capture_output=True)
    m = re.search(r"I:\s+(-?[\d.]+) LUFS", r.stderr.decode()[-900:])
    return float(m.group(1)) if m else -70.0

def schneiden(x, laenge, ausklang, schwelle_db):
    x = hochpass(x)
    sp = np.abs(x).max()
    glatt = np.convolve(np.abs(x), np.ones(int(SR * 0.002)) / int(SR * 0.002), "same")
    idx = int(np.argmax(glatt >= sp * 10 ** (schwelle_db / 20)))
    a = max(0, idx - int(SR * 0.003))
    seg = x[a:a + int(laenge * SR)].copy()
    # die ersten 1,5 ms weich einblenden gegen Klicken, der Einsatz bleibt bei 0 ms
    e = int(SR * 0.0015)
    seg[:e] *= np.linspace(0, 1, e)
    f = min(len(seg), int(ausklang * SR))
    seg[-f:] *= (0.5 + 0.5 * np.cos(np.linspace(0, np.pi, f))) ** 1.5
    return seg

def pegeln(seg, ziel_lufs):
    y = seg
    for _ in range(4):
        g = 10 ** ((ziel_lufs - lufs(y)) / 20)
        y = y * g
        sp = np.abs(y).max()
        grenze = 10 ** (-2.5 / 20)
        if sp > grenze:
            y = np.tanh(y / grenze * 0.9) / np.tanh(0.9) * grenze * 0.999  # weiche Begrenzung statt Übersteuern
    sp = np.abs(y).max()
    if sp > 10 ** (-2.5 / 20):
        y = y * (10 ** (-2.5 / 20) / sp)
    return y

def schreiben(name, y):
    pfad = ZIEL / f"{name}.ogg"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", "-",
                    "-c:a", "libvorbis", "-q:a", "4", str(pfad)], input=y.astype(np.float32).tobytes(), check=True)

if __name__ == "__main__":
    ZIEL.mkdir(exist_ok=True)
    nur = sys.argv[1:]
    for name, quelle, laenge, ausk, schw, ziel in SPEC:
        if nur and name not in nur:
            continue
        seg = schneiden(lade(ROH / quelle), laenge, ausk, schw)
        y = pegeln(seg, ziel)
        schreiben(name, y)
        # Vorbis schwingt beim Entpacken über: Spitze der fertigen Datei prüfen und bei Bedarf nachregeln
        for _ in range(3):
            sp = np.abs(lade(ZIEL / f"{name}.ogg")).max()
            if sp <= 10 ** (-1.5 / 20):
                break
            y = y * (10 ** (-2.0 / 20) / sp)
            schreiben(name, y)
        print(f"{name:18s} <- {quelle:16s} {len(y)/SR:.3f}s LUFS {lufs(lade(ZIEL / f'{name}.ogg')):.1f} Spitze {20*np.log10(np.abs(lade(ZIEL / f'{name}.ogg')).max()):.1f} dBFS")
