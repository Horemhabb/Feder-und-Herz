#!/usr/bin/env python3
# Misst Tondateien, weil hier niemand zuhört: Dauer, Kanäle, Lautheit (LUFS nach EBU R128, von ffmpeg), Spitze,
# Übersteuerung, Stille am Anfang und Ende, Klangfarbe (Schwerpunkt und Anteile in fünf Bändern) und bei Schleifen
# die Naht (Sprung zwischen letztem und erstem Abtastwert, Lautstärke der letzten und ersten halben Sekunde).
# Aufruf: python3 tools/ton/messen.py [Dateien …]     ohne Dateien: alles in audio/
#         python3 tools/ton/messen.py --md  …         Ausgabe als Markdown-Tabelle
import json, pathlib, re, subprocess, sys
import numpy as np

HIER = pathlib.Path(__file__).resolve().parent
AUDIO = HIER.parent.parent / "audio"
SR = 44100
SCHLEIFE = re.compile(r"^(amb_|mus_|src_|lage_|torch|feuer_brennt)")
BAENDER = [(20, 150), (150, 500), (500, 2000), (2000, 6000), (6000, 20000)]

def roh(p):
    r = subprocess.run(["ffmpeg", "-v", "error", "-i", str(p), "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"], capture_output=True)
    return np.frombuffer(r.stdout, np.float32).astype(np.float64)

def lufs(p):
    r = subprocess.run(["ffmpeg", "-nostats", "-i", str(p), "-af", "ebur128=peak=true", "-f", "null", "-"], capture_output=True, text=True)
    t = r.stderr
    i = re.findall(r"I:\s+(-?[\d.]+|-inf) LUFS", t)
    pk = re.findall(r"Peak:\s+(-?[\d.]+|-inf) dBFS", t)
    f = lambda s: -99.0 if s == "-inf" else float(s)
    return (f(i[-1]) if i else -99.0), (f(pk[-1]) if pk else -99.0)

def info(p):
    r = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "stream=channels,sample_rate", "-of", "json", str(p)], capture_output=True, text=True)
    s = json.loads(r.stdout)["streams"][0]
    return int(s["channels"]), int(s["sample_rate"])

def db(x):
    return 20 * np.log10(max(x, 1e-9))

def messe(p):
    p = pathlib.Path(p)
    x = roh(p)
    ch, sr = info(p)
    d = {"datei": p.name, "dauer": len(x) / SR, "kanaele": ch, "rate": sr, "kb": p.stat().st_size / 1024}
    if len(x) == 0:
        return d
    d["lufs"], d["spitze"] = lufs(p)
    d["rms"] = float(db(np.sqrt(np.mean(x ** 2))))
    d["clip"] = int(np.sum(np.abs(x) >= 0.999))
    schwelle = np.abs(x).max() * 10 ** (-40 / 20)
    laut = np.nonzero(np.abs(x) > schwelle)[0]
    d["stille_vorn"] = laut[0] / SR if len(laut) else 0.0
    d["stille_hinten"] = (len(x) - laut[-1]) / SR if len(laut) else 0.0
    X = np.abs(np.fft.rfft(x * np.hanning(len(x)))) ** 2
    f = np.fft.rfftfreq(len(x), 1 / SR)
    ges = X.sum() + 1e-12
    d["schwerpunkt"] = float((X * f).sum() / ges)
    d["baender"] = [float(X[(f >= a) & (f < b)].sum() / ges * 100) for a, b in BAENDER]
    if SCHLEIFE.match(p.name):
        h = int(0.5 * SR)
        r_end, r_anf = np.sqrt(np.mean(x[-h:] ** 2)), np.sqrt(np.mean(x[:h] ** 2))
        ges_rms = np.sqrt(np.mean(x ** 2)) + 1e-9
        # Sprung an der Naht im Verhältnis zur üblichen Änderung von Abtastwert zu Abtastwert
        sprung = abs(x[-1] - x[0])
        ueblich = np.percentile(np.abs(np.diff(x)), 99) + 1e-9
        d["naht_db"] = db(r_anf) - db(r_end)
        d["naht_sprung"] = float(sprung / ueblich)
        if min(r_end, r_anf) < 1e-3 * ges_rms:   # ein Ende ist still (Melodie mit Pause): kein Pegelsprung
            d["naht_db"] = 0.0
        d["naht_ok"] = bool(abs(d["naht_db"]) < 3.0 and d["naht_sprung"] < 1.0)
    return d

def zeile(d):
    b = d.get("baender", [0] * 5)
    naht = ""
    if "naht_db" in d:
        naht = "%+.1f dB / %.2f %s" % (d["naht_db"], d["naht_sprung"], "ok" if d["naht_ok"] else "**prüfen**")
    return "| %s | %.2f | %d×%dk | %.0f | %.1f | %.1f | %d | %.2f/%.2f | %.0f | %s | %s |" % (
        d["datei"], d["dauer"], d["kanaele"], d["rate"] // 1000, d["kb"], d.get("lufs", -99), d.get("spitze", -99), d.get("clip", 0),
        d.get("stille_vorn", 0), d.get("stille_hinten", 0), d.get("schwerpunkt", 0), " ".join("%.0f" % v for v in b), naht)

KOPF = ("| Datei | s | Kan.×Rate | KB | LUFS | Spitze dB | Clip | Stille v/h s | Schwerp. Hz | Bänder % (<150/-500/-2k/-6k/>6k) | Naht (Pegel/Sprung) |\n"
        "|---|---|---|---|---|---|---|---|---|---|---|")

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dateien = [pathlib.Path(a) for a in args] or sorted(AUDIO.glob("*.ogg"))
    erg = [messe(p) for p in dateien]
    if "--json" in sys.argv:
        print(json.dumps(erg, indent=1))
    elif "--md" in sys.argv:
        print(KOPF)
        for d in erg:
            print(zeile(d))
    else:
        for d in erg:
            print(zeile(d))
