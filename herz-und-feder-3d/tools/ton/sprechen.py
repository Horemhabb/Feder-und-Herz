#!/usr/bin/env python3
# Sprechzeilen der Geschichte (Fassung 4.3, zweiter Durchgang). Liest tools/ton/sprechzeilen.json (von Agent D) und
#   plan       fasst die Zeilen zu Gruppen zusammen (ein Sprecher, eine Szene, Prio 1 zuerst, dann Prio 2 Akt für Akt)
#              und schreibt den Plan mit Stimme, Regie-Tags und Kosten nach …/scratchpad/ton/sprechplan.json.
#              Eine Gruppe ist EINE Erzeugung bei ElevenLabs (Eleven v3, eine Fassung): die Zeilen stehen darin mit
#              einer langen Pause dazwischen. Das spart Aufrufe und hält Stimme und Ton über eine Szene gleich.
#   schneiden <gruppe> <aufnahme.mp3>
#              zerlegt die Aufnahme an den längsten Pausen wieder in ihre Zeilen, bearbeitet jede wie stimme.py
#              (Rolle je Sprecher) und schreibt audio/<id>.ogg.
#
# Stimmen (alle aus creative_list_voices, Modell Eleven v3, Regie über Tags in eckigen Klammern):
#   Erzähler            Samuel Storm (wie die bisherigen 36 Ansagen, damit eine Stimme durch das Spiel führt)
#   Der alte Priester   Gottlob Harder (alt, eindringlich)
#   Nebet, Nebet als Ba Jule (jung, leise, nah)
#   Haremhab            Joerg (tief, hart)
#   Thot                Leander (ruhig, gemessen)
#   Isis                Irene (warm, reif)
#   Mahaf, Türhüter     Brako (tief, fremd; viel Raum)
#   Der Sammler         M. Danisch (alt, müde, höflich); aus der Tiefe und als Schatten mit großem Raum
import json, pathlib, re, sys
import numpy as np
import werk, stimme

HIER = pathlib.Path(__file__).resolve().parent
PLAN = pathlib.Path("/tmp/claude-0/-home-user-Feder-und-Herz/43b90733-ee5e-581f-a834-89ba24d13877/scratchpad/ton/sprechplan.json")
BUDGET = 6650          # Credits für diesen Durchgang (10.000 insgesamt minus erster Durchgang, mit kleiner Reserve)
TRENNER = "\n\n[long pause]\n\n"
GEWICHT = float(__import__("os").environ.get("PAUSENGEWICHT", "8"))   # wie sehr lange Pausen beim Schneiden zählen

STIMME = {
    "erzaehler": ("NV8D9kv4W21bIe2GkOiE", "erzaehler"),
    "figur:Der alte Priester": ("RnVAN9DGdCSnZtC49Y3N", "leute"),
    "figur:Nebet (als Ba)": ("VU8IqX1jR115XHqBQttd", "ba"),
    "figur:Nebet": ("VU8IqX1jR115XHqBQttd", "leute"),
    "figur:Haremhab": ("4LGl9vcIlBA26XGSPOpo", "leute"),
    "figur:Thot": ("LdH3BDLqhNcq7kil2o2r", "gott"),
    "figur:Isis": ("5bVYvsqKAWO1hDgOO72l", "gott"),
    "hueter:Mahaf": ("1m6iR8iVpwOGuiSZS2DT", "hueter"),
    "hueter:Der Stumme Türhüter": ("1m6iR8iVpwOGuiSZS2DT", "hueter"),
    "hueter:Der Sammler": ("1KGG4Q8LqRdNII9xBurw", "sammler"),
    "hueter:Der Sammler (aus der Tiefe)": ("1KGG4Q8LqRdNII9xBurw", "hueter"),
    "hueter:Der Schatten des Sammlers": ("1KGG4Q8LqRdNII9xBurw", "hueter"),
}
# Stimmung (Regie von D) → Tags für Eleven v3 (englisch, so versteht das Modell sie)
TAGS = {
    "ruhig, erzählend": "",
    "ruhig, erzählend, mit Haken am Ende": "",
    "frech, leicht, später ängstlich": "[playful] ",
    "hart, knapp, soldatisch": "[firm] ",
    "trocken, gütig, gemessen": "[calm] ",
    "warm, wissend, langsam": "[warmly] ",
    "alt, eindringlich, gedämpft": "[hushed] ",
    "sanft, müde, überzeugt": "[tired] [softly] ",
    "leise, ertappt, kindlich": "[softly] [shy] ",
    "tonlos, hallend, ohne Mund": "[monotone] ",
    "flüsternd, freundlich, unheimlich": "[whispers] ",
    "fern, verwundert": "[softly] [curious] ",
    "flüsternd, hohl": "[whispers] ",
}

def akt_von(z):
    w = z["id"]
    m = re.search(r"_h(\d\d)", w)
    if m:
        return (int(m.group(1)) - 1) // 4 + 1
    for k, a in (("auftakt", 1), ("akt1", 1), ("mitte", 2), ("akt2", 2), ("finale", 3)):
        if k in w:
            return a
    return 3

def szene_von(z):
    return z["wo"]

def text_fuer(z):
    t = z["text"].strip().strip("„“\"”")
    t = t.replace("„", "").replace("“", "").replace("”", "")
    return TAGS.get(z["stimmung"], "") + t

def plan():
    daten = json.load(open(HIER / "sprechzeilen.json"))["zeilen"]
    for i, z in enumerate(daten):
        z["_i"] = i
    reihen = [z for z in daten if z["prio"] == 1] + sorted([z for z in daten if z["prio"] == 2], key=lambda z: (akt_von(z), z["_i"]))
    gruppen = []
    for z in reihen:
        g = gruppen[-1] if gruppen else None
        passt = g and g["prio"] == z["prio"] and g["sprecher"] == z["sprecher"] and g["szene"] == szene_von(z) \
            and len(g["prompt"]) + len(text_fuer(z)) < 700
        if not passt:
            # gleiche Szene und gleicher Sprecher weiter oben? Dort anhängen (eine Szene, eine Aufnahme je Sprecher)
            for h in gruppen:
                if h["prio"] == z["prio"] and h["sprecher"] == z["sprecher"] and h["szene"] == szene_von(z) and len(h["prompt"]) + len(text_fuer(z)) < 700:
                    g, passt = h, True
                    break
        if passt:
            g["zeilen"].append(z["id"])
            g["prompt"] += TRENNER + text_fuer(z)
        else:
            vid, rolle = STIMME[z["sprecher"]]
            gruppen.append({"nr": len(gruppen) + 1, "prio": z["prio"], "akt": akt_von(z), "sprecher": z["sprecher"], "szene": szene_von(z),
                            "stimme": vid, "rolle": rolle, "zeilen": [z["id"]], "prompt": text_fuer(z)})
    summe = 0
    for g in gruppen:
        g["kosten"] = len(g["prompt"])
        summe += g["kosten"]
        g["im_budget"] = summe <= BUDGET
        g["summe"] = summe
    PLAN.write_text(json.dumps(gruppen, ensure_ascii=False, indent=1))
    for g in gruppen:
        print("%3d P%d A%d %-38s %-26s %2d Zeilen %4d Zeichen  Summe %5d %s" % (g["nr"], g["prio"], g["akt"], g["szene"][:38], g["sprecher"][:26],
              len(g["zeilen"]), g["kosten"], g["summe"], "" if g["im_budget"] else "ÜBER BUDGET"))

def schneiden(nr, quelle):
    gruppen = json.loads(PLAN.read_text())
    # mehrere Gruppen desselben Sprechers in einer Aufnahme: „20,22,24“ (in dieser Reihenfolge gesprochen)
    nrn = [int(s) for s in str(nr).split(",")]
    g = dict(gruppen[nrn[0] - 1])
    g["zeilen"] = sum((gruppen[k - 1]["zeilen"] for k in nrn), [])
    SR = stimme.SR
    x = werk.lade(quelle, SR)
    n = len(g["zeilen"])
    if n == 1:
        teile = [x]
    else:
        # Pausen finden: 20-ms-Fenster unter −45 dB (bezogen auf die Spitze), zusammenhängend
        h = int(0.02 * SR)
        e = np.array([np.sqrt(np.mean(x[i:i + h] ** 2)) for i in range(0, len(x) - h, h)])
        still = werk.db(e) < werk.db(werk.spitze(x)) - 45
        laeufe, a = [], None
        for i, s in enumerate(still):
            if s and a is None:
                a = i
            if not s and a is not None:
                laeufe.append((i - a, a, i))
                a = None
        laeufe = [l for l in laeufe if l[1] > 0 and l[0] >= 12]     # ab 0,24 s kommt eine Pause in Frage
        if len(laeufe) < n - 1:
            raise SystemExit("zu wenige Pausen gefunden: %d statt %d" % (len(laeufe), n - 1))
        # Schnitte wählen: lange Pausen bevorzugt, aber nahe der Stelle, an der die Zeile nach ihrer Zeichenzahl enden
        # sollte (sonst gewinnt eine lange Atempause mitten im Satz gegen eine kurze Trennpause). Kleinste Kosten über
        # alle geordneten Auswahlen (dynamische Programmierung).
        laeufe.sort(key=lambda l: l[1])
        daten0 = {z["id"]: z for z in json.load(open(HIER / "sprechzeilen.json"))["zeilen"]}
        zeichen = np.array([len(daten0[z]["text"]) for z in g["zeilen"]], float)
        laut = np.nonzero(~still)[0]
        a0, a1 = laut[0], laut[-1]
        soll = a0 + (a1 - a0) * np.cumsum(zeichen)[:-1] / zeichen.sum()
        sigma = 0.12 * (a1 - a0)
        lmax = max(l[0] for l in laeufe)
        def kosten(k, j):
            l = laeufe[j]
            return (((l[1] + l[2]) / 2 - soll[k]) / sigma) ** 2 - GEWICHT * np.log(l[0] / lmax)
        m = len(laeufe)
        best = np.full((n - 1, m), np.inf)
        zur = np.zeros((n - 1, m), int)
        for j in range(m):
            best[0, j] = kosten(0, j)
        for k in range(1, n - 1):
            for j in range(k, m):
                i = int(np.argmin(best[k - 1, :j]))
                best[k, j] = best[k - 1, i] + kosten(k, j)
                zur[k, j] = i
        j = int(np.argmin(best[n - 2]))
        wahl = [j]
        for k in range(n - 2, 0, -1):
            j = zur[k, j]
            wahl.append(j)
        wahl = sorted(wahl)
        schnitte = [((laeufe[j][1] + laeufe[j][2]) // 2) * h for j in wahl]
        teile = np.split(x, schnitte)
        print("  Trennpausen " + ", ".join("%.2f s" % (laeufe[j][0] * 0.02) for j in wahl))
    daten = {z["id"]: z for z in json.load(open(HIER / "sprechzeilen.json"))["zeilen"]}
    for zid, t in zip(g["zeilen"], teile):
        y = stimme.bearbeite(t, g["rolle"])
        werk.schreibe(zid, y, SR, q=4, aus_sr=stimme.AUS_SR)
        zeichen = len(daten[zid]["text"])
        print("  %-22s %5.2f s  %4d Zeichen  %4.1f Zeichen/s  %5.1f LUFS" % (zid, len(y) / SR, zeichen, zeichen / max(0.1, len(y) / SR - 0.6), werk.lufs(y, SR)))

if __name__ == "__main__":
    if sys.argv[1] == "plan":
        plan()
    elif sys.argv[1] == "schneiden":
        schneiden(sys.argv[2], sys.argv[3])
