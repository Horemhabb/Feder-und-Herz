#!/usr/bin/env python3
# Hörproben für den Auftraggeber (nicht im Spiel): je Akt eine Vorführung, wie das Spiel mischt (Kulisse,
# Erkunden → Spannung → Kampf mit Hieben und Treffern → Nachklang → Erkunden), dazu je Gruppe eine Reihe
# aller neuen Geräusche mit kurzen Pausen. Die Pegel folgen Sfx.VOL (Musik, Teppich, Geräusche), am Ende wird
# alles gemeinsam auf eine angenehme Abhörlautstärke gebracht.
# Aufruf: python3 tools/ton/hoerproben.py      Ausgabe: …/scratchpad/ton/
import pathlib
import numpy as np
import werk

SR = 32000
A = werk.AUDIO
ZIEL = pathlib.Path("/tmp/claude-0/-home-user-Feder-und-Herz/43b90733-ee5e-581f-a834-89ba24d13877/scratchpad/ton")

def l(name):
    return werk.lade(A / (name + ".ogg"), SR)

def db(x, d):
    return x * 10 ** (d / 20)

def schleife(x, n):
    r = int(np.ceil(n / len(x)))
    return np.tile(x, r)[:n]

def setze(buf, t, x):
    a = int(t * SR)
    e = min(len(buf), a + len(x))
    buf[a:e] += x[:e - a]

def vorfuehrung(akt, teppich, schlag, treffer, schmerz, gegner):
    g, m, s, k = (l("mus_a%d_%s" % (akt, n)) for n in ("grund", "melodie", "spannung", "kampf"))
    L = len(g)
    # Abschnitte: Erkunden (eine Runde), Spannung (halbe), Kampf (eine), Stille mit Nachklang (20 s), Erkunden (halbe)
    teile = []
    teile.append(g + m)
    teile.append((g + s)[: L // 2])
    teile.append(g * 0.8 + s * 0.6 + k)
    nk = l("mus_a%d_nachklang" % akt)
    still = schleife(g, 20 * SR)
    still[: len(nk)] += nk
    teile.append(still)
    teile.append((g + m)[: L // 2])
    musik = np.concatenate([werk.ausblenden(werk.einblenden(t, 1.5, SR), 1.5, SR) for t in teile])
    n = len(musik)
    out = db(musik, -17)
    out += db(schleife(l(teppich), n), -21)
    # Kampf: Hiebe und Treffer im Abschnitt Kampf, ein Gegnerschrei am Anfang, Schmerz dazwischen
    k0 = (len(teile[0]) + len(teile[1])) / SR
    rng = np.random.default_rng(akt)
    setze(out, k0 + 0.5, db(l(gegner), -10))
    t = k0 + 2.0
    while t < k0 + L / SR - 2:
        setze(out, t, db(l(schlag + str(rng.integers(1, 3))), -9))
        setze(out, t + 0.18, db(l(treffer + str(rng.integers(1, 3))), -7))
        if rng.random() < 0.2:
            setze(out, t + 0.5, db(l(schmerz + str(rng.integers(1, 3))), -9))
        t += rng.uniform(0.7, 1.6)
    out = werk.auf_lufs(out, -18, SR, -1.0)
    werk.schreibe("vorfuehrung_akt%d" % akt, out, SR, q=5, ordner=ZIEL)
    print("vorfuehrung_akt%d  %.0f s" % (akt, len(out) / SR))

def reihe(name, namen, pause=0.6):
    teile = []
    for n in namen:
        p = A / (n + ".ogg")
        if not p.exists():
            continue
        x = werk.lade(p, SR)
        if len(x) > 8 * SR:
            x = werk.ausblenden(x[: 8 * SR], 1.0, SR)
        teile += [x, np.zeros(int(pause * SR))]
    out = werk.auf_lufs(np.concatenate(teile), -18, SR, -1.0)
    werk.schreibe(name, out, SR, q=5, ordner=ZIEL)
    print("%-22s %d Klänge, %.0f s" % (name, len(namen), len(out) / SR))

def v(n, k):
    return ["%s%d" % (n, i) for i in range(1, k + 1)]

if __name__ == "__main__":
    vorfuehrung(1, "amb_freiland", "hieb", "klinge", "schmerz_m", "krieger_wach1")
    vorfuehrung(2, "amb_hoehle", "faust", "faustschlag", "schmerz_m", "koloss_wach1")
    vorfuehrung(3, "amb_feuergrube", "armbrust", "bolzen", "schmerz_w", "hohl_wach1")
    reihe("reihe_klassen", v("hieb", 3) + v("klinge", 3) + v("faust", 3) + v("faustschlag", 3) + v("armbrust", 2) + v("bolzen", 3)
          + v("sternfunke", 3) + v("sterntreffer", 3) + ["meteor"] + v("windstoss", 2) + v("schmerz_m", 3) + v("schmerz_w", 3) + ["tod_w"])
    reihe("reihe_gegner", sum((v(g + "_" + a, 2) for g in ("krieger", "priesterin", "koloss", "erloschen", "hohl") for a in ("wach", "tod")), [])
          + ["hueter_ansage", "hueter_schlag"])
    reihe("reihe_champions", ["aff_auftritt", "aff_glut", "aff_sturm", "aff_feder", "aff_feder_bruch", "aff_ruf", "aff_sprung", "aff_klage",
                              "aff_fessel", "aff_spalt", "aff_kette"])
    reihe("reihe_welt_oberflaeche", v("koerper_fall", 3) + v("scherben", 2) + ["ui", "knopf_gold1", "fenster_auf", "fenster_zu", "belohnung",
          "stufe", "anlegen", "legendary", "herzschlag", "ev_flamme", "ev_platsch", "ev_boe", "ev_vogel", "ev_knochen", "ev_gong", "ev_fluestern"])
    reihe("reihe_kulisse", ["amb_wind", "amb_freiland", "amb_sandbank", "amb_grab", "amb_hoehle", "amb_nun", "amb_feuergrube", "amb_morgen"], 1.0)
    reihe("reihe_musik_titel_nachklang", ["mus_titel", "mus_a1_nachklang", "mus_a2_nachklang", "mus_a3_nachklang"], 1.5)
