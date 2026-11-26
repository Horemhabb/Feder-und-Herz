#!/usr/bin/env python3
# Musik für „Feder und Herz“ (Fassung 4.3): ein kleiner Sequenzer, der aus einzelnen Instrumenttönen von ElevenLabs
# (Sound Effects v3, tools/ton/roh/instr/) Stücke spielt. Der Musik-Connector stand nicht zur Verfügung; dafür
# lassen sich so Tonleiter, Form und Schichten genau festlegen.
#
# Aufbau: Jeder Akt hat ein eigenes Thema in eigener Tonleiter, aus vier Schichten gleicher Länge, die das Spiel
# übereinanderlegt (vertikales Mischen, scripts/sfx.gd › lage()):
#   grund     Bordun (Chor), tiefe Oud, Glocke: spielt immer
#   melodie   das Thema (Ney, Rebab, Qanun, Harfe, Klagestimme): beim Erkunden
#   spannung  lange Reibetöne und ein Herzschlag aus der Darbuka: wenn Gegner wach sind
#   kampf     Trommeln (Maqsum, Saidi …), Oud-Ostinato, Mizmar: im Kampf
# Dazu Titelmusik, Hüter-Musik in drei Steigerungen und je Akt ein Nachklang nach dem Kampf.
#
#   Akt 1 „Der Abstieg“   Hidschas auf D (D Es Fis G A B C), 76 Schläge/min, Ney und Oud, geheimnisvoll
#   Akt 2 „Die Wahrheit“  Kurd/phrygisch auf A (A B C D E F G), 60/min, Rebab und Klagestimme, dunkel
#   Akt 3 „Der Morgen“    mixolydisch auf G (G A H C D E F), 88/min, Ney und Qanun, hell und aufsteigend
#   Hüter                 phrygisch-dominant auf E (E F Gis A H C D), 96/min
# Alle Themen beginnen mit demselben Kern (Grundton, Nebenton, Grundton, Quarte, Terz/Nebenton darunter): das
# Motiv der Feder, in jedem Akt in dessen Tonleiter.
#
# Notenschrift (eine Stimme, Takte mit „|“ getrennt, jeder Takt wird auf seine Länge geprüft):
#   a4/1.5   Ton a4, anderthalb Schläge      eb4  es      f#4  fis      r/2  Pause
#   ~a4/1    gleitet vom vorigen Ton her      (g4)a4/1  kurzer Vorschlag g4      a4/1+  betont   a4/1-  leise
# Trommeln: je Takt 16 Zeichen (Sechzehntel): D Dum, T Tek, K Ka, B Bendir, S Rand, G große Trommel,
#   R Sistrum, Z Zimbeln; klein geschrieben leiser, „.“ Pause.
#
# Aufruf: python3 tools/ton/musik.py [akt1 akt2 akt3 titel hueter nachklang]   (ohne Angabe: alles)
#         --probe   schreibt zusätzlich Vorführdateien in den Hörproben-Ordner
import pathlib, re, sys
import numpy as np
import werk

SR = 32000
ROH = werk.ROH / "instr"
PROBE = pathlib.Path("/tmp/claude-0/-home-user-Feder-und-Herz/43b90733-ee5e-581f-a834-89ba24d13877/scratchpad/ton")

# ---------------------------------------------------------------- Instrumente
class Instrument:
    """art: 'zupf' (klingt frei aus), 'halt' (gehaltener Ton, wird bei Bedarf verlängert), 'schlag' (ohne Tonhöhe)."""
    def __init__(self, name, dateien, art, gain=1.0, an=0.004, ab=0.15, klang_max=4.0, tief=None, hoch=None, nur=None):
        self.name, self.art, self.gain, self.an, self.ab, self.klang_max = name, art, gain, an, ab, klang_max
        self.proben = []
        for d in dateien:
            x = werk.lade(ROH / d, SR)
            x = werk.ab_anschlag(x, SR)
            x = werk.filt(x, lambda f: werk.hoch(f, hoch or 30, 2) * (werk.tief(f, tief, 2) if tief else 1.0), SR)
            if art == "schlag":
                x = x / max(1e-9, werk.spitze(x)) * 0.7
                self.proben.append((x, 0.0))
                continue
            # Grundton aus mehreren Fenstern (Mittelwert), damit die Stimmung genau stimmt
            fs = []
            for t in np.linspace(0.08, min(1.4, len(x) / SR - 0.3), 5):
                f, c = werk.grundton(x, SR, fmin=50, fmax=1600, von=t, lang=0.2)
                if c > 0.7:
                    fs.append(werk.hz_zu_midi(f))
            wurzel = float(np.median(fs))
            if art == "halt":
                a, e = int(0.15 * SR), int(min(len(x), 1.5 * SR))
                pegel = np.sqrt(np.mean(x[a:e] ** 2))
                x = x / max(1e-9, pegel) * 0.12
            else:
                x = x / max(1e-9, werk.spitze(x)) * 0.6
            self.proben.append((x, wurzel))

    def probe(self, midi, rng):
        if self.art == "schlag":
            return self.proben[rng.integers(len(self.proben))]
        abst = [abs(midi - w) for _, w in self.proben]
        beste = min(abst)
        kand = [p for p, d in zip(self.proben, abst) if d <= beste + 1.0]
        return kand[rng.integers(len(kand))]

    def ton(self, midi, dauer, vel, rng, gleit_von=None):
        """Einen Ton erzeugen: midi (float), dauer in Sekunden, vel 0–1.5."""
        x, wurzel = self.probe(midi, rng)
        if self.art == "schlag":
            k = 2 ** (rng.uniform(-0.25, 0.25) / 12)
            y = np.interp(np.arange(int(len(x) / k)) * k, np.arange(len(x)), x)
            return y * vel * self.gain
        schritt = midi - wurzel
        if self.art == "zupf":
            n_aus = int(min(self.klang_max, max(dauer * 1.6, 0.6)) * SR)
        else:
            n_aus = int((dauer + self.ab) * SR)
        # Tonhöhenverlauf je Ausgabewert (Gleiten vom vorigen Ton)
        st = np.full(n_aus, schritt)
        if gleit_von is not None:
            g = min(n_aus, int(0.12 * SR))
            st[:g] = (gleit_von - wurzel) + (schritt - (gleit_von - wurzel)) * (np.sin(np.linspace(0, np.pi / 2, g)) ** 2)
        rate = 2 ** (st / 12)
        bedarf = int(np.sum(rate)) + 2
        if bedarf > len(x):
            x = self._verlaengern(x, bedarf, rng)
        pos = np.concatenate([[0], np.cumsum(rate)[:-1]])
        y = np.interp(pos, np.arange(len(x)), x)
        # Hüllkurve: weicher Einsatz, am Ende ausblenden
        h = np.ones(n_aus)
        a = min(n_aus, int(self.an * SR))
        if a > 0:
            h[:a] = np.sin(np.linspace(0, np.pi / 2, a)) ** 2
        r = min(n_aus, int(self.ab * SR) if self.art == "halt" else int(0.25 * SR))
        h[-r:] *= np.cos(np.linspace(0, np.pi / 2, r)) ** 2
        return y * h * vel * self.gain

    def _verlaengern(self, x, bedarf, rng):
        """Gehaltene Töne länger machen: der ruhige Mittelteil wird mit Überblendungen aneinandergereiht."""
        a, e = int(0.35 * SR), int(len(x) - 0.4 * SR)
        mitte = x[a:e]
        xf = int(0.25 * SR)
        teile = [x[:e]]
        laenge = e
        while laenge < bedarf:
            s = rng.integers(0, max(1, len(mitte) - int(1.0 * SR)))
            st = mitte[s:]
            teile.append(st)
            laenge += len(st) - xf
        out = teile[0]
        for t in teile[1:]:
            k = min(xf, len(t), len(out))
            w = np.linspace(0, np.pi / 2, k)
            mix = out[-k:] * np.cos(w) + t[:k] * np.sin(w)
            out = np.concatenate([out[:-k], mix, t[k:]])
        return out

INSTR = {}

def instrumente():
    if INSTR:
        return INSTR
    I = INSTR
    I["ney"] = Instrument("ney", ["ney_1.mp3", "ney_2.mp3", "ney_3.mp3"], "halt", 1.0, an=0.07, ab=0.35, tief=9000)
    I["mizmar"] = Instrument("mizmar", ["mizmar_1.mp3", "mizmar_2.mp3", "mizmar_3.mp3"], "halt", 0.8, an=0.03, ab=0.18, tief=7000)
    I["rebab"] = Instrument("rebab", ["rebab_1.mp3", "rebab_2.mp3", "rebab_3.mp3"], "halt", 0.9, an=0.12, ab=0.4, tief=7000)
    I["frau"] = Instrument("frau", ["frau_1.mp3", "frau_2.mp3", "frau_3.mp3"], "halt", 0.8, an=0.25, ab=0.6, tief=8000)
    I["chor"] = Instrument("chor", ["chor_1.mp3", "chor_2.mp3", "chor_3.mp3"], "halt", 1.0, an=0.8, ab=1.0, tief=5000, hoch=50)
    I["arghul"] = Instrument("arghul", ["arghul_1.mp3", "arghul_3.mp3"], "halt", 0.5, an=0.4, ab=0.6, tief=5000)
    I["oud"] = Instrument("oud", ["oud_1.mp3", "oud_2.mp3", "oud_3.mp3", "oud_4.mp3"], "zupf", 1.0, klang_max=2.6, hoch=60)
    I["harfe"] = Instrument("harfe", ["harfe_1.mp3", "harfe_2.mp3", "harfe_3.mp3"], "zupf", 0.8, klang_max=3.0)
    I["qanun"] = Instrument("qanun", ["qanun_1.mp3", "qanun_2.mp3", "qanun_3.mp3"], "zupf", 0.8, klang_max=2.0)
    I["glocke"] = Instrument("glocke", ["glocke_3.mp3"], "zupf", 0.5, klang_max=4.0)
    # Trommeln und Rasseln
    I["D"] = Instrument("dum", ["dum_1.mp3", "dum_3.mp3"], "schlag", 1.0, hoch=40)
    I["T"] = Instrument("tek", ["tek_1.mp3", "tek_3.mp3"], "schlag", 0.55, hoch=200)
    I["K"] = Instrument("ka", ["tek_1.mp3", "tek_3.mp3", "rahmen_rand_3.mp3"], "schlag", 0.3, hoch=300)
    I["B"] = Instrument("bendir", ["rahmen_tief_1.mp3", "rahmen_tief_2.mp3", "rahmen_tief_3.mp3"], "schlag", 0.9, hoch=35)
    I["S"] = Instrument("rand", ["rahmen_rand_1.mp3", "rahmen_rand_2.mp3", "rahmen_rand_3.mp3"], "schlag", 0.4, hoch=150)
    I["G"] = Instrument("tempel", ["trommel_1.mp3", "trommel_2.mp3", "trommel_3.mp3"], "schlag", 1.0, hoch=28)
    I["R"] = Instrument("sistrum", ["sistrum_1.mp3", "sistrum_2.mp3", "sistrum_3.mp3"], "schlag", 0.35, hoch=500)
    I["Z"] = Instrument("zimbeln", ["zimbeln_1.mp3", "zimbeln_2.mp3", "zimbeln_3.mp3"], "schlag", 0.25, hoch=800)
    return I

# ---------------------------------------------------------------- Notenschrift
STUFEN = {"c": 0, "d": 2, "e": 4, "f": 5, "g": 7, "a": 9, "b": 11}
NOTE = re.compile(r"^(?:\((?P<vor>[a-g][#b]?\d)\))?(?P<gl>~)?(?P<n>[a-g][#b]?\d|r)/(?P<d>[\d.]+)(?P<v>[+-]?)$")

def midi(n):
    m = re.match(r"([a-g])([#b]?)(\d)", n)
    return 12 * (int(m.group(3)) + 1) + STUFEN[m.group(1)] + {"#": 1, "b": -1, "": 0}[m.group(2)]

def lies(stimme, takt=4.0):
    """Notenschrift in eine Liste (Beginn in Schlägen, Dauer, midi oder None, Lautstärke, gleiten, vorschlag)."""
    ereig, t = [], 0.0
    for i, tk in enumerate(stimme.split("|")):
        summe = 0.0
        for tok in tk.split():
            m = NOTE.match(tok)
            if not m:
                raise ValueError("unlesbar: %r (Takt %d)" % (tok, i + 1))
            d = float(m.group("d"))
            if m.group("n") != "r":
                v = {"+": 1.35, "-": 0.6, "": 1.0}[m.group("v")]
                ereig.append((t + summe, d, midi(m.group("n")), v, bool(m.group("gl")), midi(m.group("vor")) if m.group("vor") else None))
            summe += d
        if abs(summe - takt) > 1e-6:
            raise ValueError("Takt %d hat %.2f statt %.1f Schläge: %s" % (i + 1, summe, takt, tk.strip()))
        t += takt
    return ereig

def trommel(muster, takt=4.0):
    """Trommelmuster (je Takt 16 Zeichen) in Ereignisse (Beginn in Schlägen, Instrument, Lautstärke)."""
    ereig = []
    for i, tk in enumerate(muster.split("|")):
        tk = tk.strip()
        if len(tk) != 16:
            raise ValueError("Trommeltakt %d hat %d statt 16 Zeichen: %r" % (i + 1, len(tk), tk))
        for j, c in enumerate(tk):
            if c != ".":
                ereig.append((i * takt + j * takt / 16, c.upper(), 1.0 if c.isupper() else 0.45))
    return ereig

def wdh(s, n):
    return " | ".join([s] * n)

# ---------------------------------------------------------------- Spielen
class Stueck:
    def __init__(self, bpm, takte, raum=2.4, dunkel=3500, seed=1, schleife=True):
        self.bpm, self.takte, self.schleife = bpm, takte, schleife
        self.sb = 60.0 / bpm
        self.L = int(round(takte * 4 * self.sb * SR))
        self.rng = np.random.default_rng(seed)
        self.ir = werk.nachhall_impuls(raum, SR, dunkel, seed=seed)
        self.schichten = {}

    def _puffer(self, name):
        if name not in self.schichten:
            self.schichten[name] = {"trocken": np.zeros(self.L + 12 * SR), "nass": 0.0}
        return self.schichten[name]["trocken"]

    def _setze(self, buf, beginn_s, y):
        # in einer Schleife gehört ein Ton, der etwas zu früh kommt, ans Ende: er klingt über die Naht
        if beginn_s < 0:
            beginn_s = beginn_s + self.L / SR if self.schleife else 0.0
        a = int(beginn_s * SR)
        e = min(len(buf), a + len(y))
        if a < len(buf):
            buf[a:e] += y[:e - a]

    def stimme(self, schicht, instr, noten, gain=1.0, oktave=0, menschlich=0.012, takt_ab=0):
        I = instrumente()[instr]
        buf = self._puffer(schicht)
        vorher = None
        for beg, dauer, m, v, gl, vor in lies(noten):
            m += 12 * oktave
            t = (beg + takt_ab * 4) * self.sb + self.rng.normal(0, menschlich)
            vel = v * self.rng.uniform(0.9, 1.05) * gain
            if vor is not None:
                kurz = 0.07
                self._setze(buf, t - kurz, I.ton(vor + 12 * oktave, kurz, vel * 0.7, self.rng))
            y = I.ton(m, dauer * self.sb, vel, self.rng, gleit_von=(vorher if gl else None))
            self._setze(buf, t, y)
            vorher = m

    def trommeln(self, schicht, muster, gain=1.0, menschlich=0.006, takt_ab=0, nur=None):
        I = instrumente()
        buf = self._puffer(schicht)
        for beg, c, v in trommel(muster):
            if nur and c not in nur:
                continue
            t = (beg + takt_ab * 4) * self.sb + self.rng.normal(0, menschlich)
            y = I[c].ton(0, 0.5, v * self.rng.uniform(0.85, 1.05) * gain, self.rng)
            self._setze(buf, t, y)

    def bordun(self, schicht, tonhoehen, gain=1.0, instr="chor", atem=0.12):
        """Durchgehender Halteton (oder mehrere) über das ganze Stück, nahtlos, mit langsamem Atmen."""
        I = instrumente()[instr]
        buf = self._puffer(schicht)
        n = self.L
        for k, m in enumerate(tonhoehen):
            lang = n / SR + 3.0
            y = I.ton(m, lang, 1.0, self.rng)
            y = y[: n + int(2.0 * SR)]
            y = werk.nahtlos(y, 2.0, SR)[:n] if self.schleife else y[:n]
            if len(y) < n:
                y = np.pad(y, (0, n - len(y)))
            # langsames Atmen, ganzzahlig viele Perioden je Schleife (damit die Naht bleibt)
            per = max(1, int(round(n / SR / 11.0)))
            t = np.arange(n) / n
            y *= 1.0 - atem + atem * np.sin(2 * np.pi * per * t + k * 1.7)
            buf[:n] += y * gain / max(1, len(tonhoehen)) ** 0.5

    def fertig(self, schicht, nass=0.28, hp=40, tp=None):
        """Schicht abmischen: Nachhall um den Kreis (nahtlos), Filter."""
        buf = self.schichten[schicht]["trocken"]
        if self.schleife:
            x = buf[:self.L].copy()
            rest = buf[self.L:]
            # was über das Ende hinausklingt, klingt am Anfang weiter
            for i in range(0, len(rest), self.L):
                s = rest[i:i + self.L]
                x[:len(s)] += s
            y = werk.hall(x, self.ir, nass, kreis=True)
        else:
            x = np.trim_zeros(buf, "b")
            y = werk.hall(x, self.ir, nass)
            y = werk.ausblenden(y, 1.5, SR)
        y = werk.filt(y, lambda f: werk.hoch(f, hp, 2) * (werk.tief(f, tp, 2) if tp else 1.0), SR, kreis=self.schleife)
        return y

# ---------------------------------------------------------------- Ausgabe
def ausgeben(stueck, plan, ziel_lufs, name_vorn, decke=-1.5):
    """plan: {schicht: (nass, hp, tp)}. Alle Schichten bekommen dieselbe Verstärkung, damit das Verhältnis bleibt:
    Grund und Melodie zusammen treffen ziel_lufs."""
    fertig = {s: stueck.fertig(s, *plan[s][:3]) for s in plan}
    bezug = sum(fertig[s] for s in fertig if s in ("grund", "melodie", "voll"))
    g = 10 ** ((ziel_lufs - werk.lufs(bezug, SR)) / 20)
    out = {}
    for s, y in fertig.items():
        extra = 10 ** ((plan[s][3] if len(plan[s]) > 3 else 0.0) / 20)
        y = werk.begrenzen(y * g * extra, decke, SR)
        if stueck.schleife:
            y = y[:stueck.L]
        name = "%s_%s" % (name_vorn, s) if s != "voll" else name_vorn
        werk.schreibe(name, y, SR, q=3)
        out[s] = y
        print("  %-24s %5.1f s  %5.1f LUFS  Spitze %5.1f dB" % (name, len(y) / SR, werk.lufs(y, SR), werk.db(werk.spitze(y))))
    return out

def probe_schreiben(name, stuecke):
    """Vorführdatei: mehrere Mischungen hintereinander, mit Blenden."""
    PROBE.mkdir(parents=True, exist_ok=True)
    teile = []
    for y in stuecke:
        teile.append(werk.ausblenden(werk.einblenden(y, 0.5, SR), 2.0, SR))
        teile.append(np.zeros(int(0.8 * SR)))
    werk.schreibe(name, np.concatenate(teile), SR, q=5, ordner=PROBE)

# ---------------------------------------------------------------- Akt 1: Der Abstieg (Hidschas auf D)
def akt1():
    s = Stueck(76, 16, raum=2.6, dunkel=3200, seed=11)
    # Melodie der Ney. Takt 13: das Motiv der Feder (D Es D G Fis)
    s.stimme("melodie", "ney", """
        r/2 a4/1.5 (c5)bb4/.5 | a4/1 g4/.5 f#4/.5 g4/2 | r/1 f#4/.5 g4/.5 a4/1 g4/.5 f#4/.5 | (f#4)eb4/1 d4/3 |
        r/2 a4/1 c5/1 | bb4/1.5 a4/.5 bb4/1 c5/1 | d5/2+ c5/.5 bb4/.5 a4/1 | ~a4/4 |
        r/4 | r/4 | r/2 g4/1 a4/1 | bb4/1 a4/.5 g4/.5 f#4/1 eb4/1 |
        d4/1 eb4/.5 d4/.5 g4/1.5 f#4/.5 | f#4/1 eb4/.5 f#4/.5 d4/2 | r/4 | r/4""", gain=1.0)
    # Antwort der Oud (Takt 9–10), ebenfalls mit dem Motiv
    s.stimme("melodie", "oud", wdh("r/4", 8) + """ |
        d3/1 eb3/.5 d3/.5 g3/1 f#3/1 | f#3/.5 g3/.5 a3/1 g3/.5 f#3/.5 eb3/.5 d3/.5 | """ + wdh("r/4", 6), gain=0.55)
    s.stimme("melodie", "harfe", """
        d4/.25 a4/.25 d5/3.5 | r/4 | r/4 | r/4 | f#4/.25 a4/.25 c5/3.5 | r/4 | r/4 |
        r/2 a4/.5- g4/.5- f#4/.5- eb4/.5- | r/4 | r/4 | r/4 | r/4 | d4/.25 f#4/.25 a4/3.5 | r/4 | r/4 | r/4""", gain=0.55)
    # Grund: Chor auf D und A, Oud im Abstand, eine Glocke am Anfang, ein ferner Bendir
    s.bordun("grund", [midi("d3"), midi("a3")], gain=0.5)
    s.stimme("grund", "oud", wdh("d3/2- r/2 | r/4", 3) + " | d3/2- r/2 | a2/2- r/2 | " + wdh("d3/2- r/2 | r/4", 3) + " | d3/2- r/2 | a2/2- r/2", gain=0.55)
    s.stimme("grund", "glocke", "d6/4- | " + wdh("r/4", 7) + " | d6/4- | " + wdh("r/4", 7), gain=0.5)
    s.trommeln("grund", wdh("b..............." + " | " + "................", 8), gain=0.5)
    # Spannung: Rebab reibt Halbtöne (D gegen Es), die Darbuka schlägt wie ein Herz, das Sistrum raschelt
    s.stimme("spannung", "rebab", """
        d4/4- | ~d4/4- | eb4/4- | ~eb4/4- | d4/4- | ~d4/4- | c4/4- | d4/4- |
        d4/4- | ~d4/4- | eb4/4- | ~eb4/4- | f#4/4- | eb4/4- | d4/4- | ~d4/4-""", gain=0.75)
    s.trommeln("spannung", wdh("D..d............", 16), gain=0.7)
    s.trommeln("spannung", wdh("................ | ............r...", 8), gain=0.8)
    # Kampf: Maqsum, Oud-Ostinato, Mizmar, große Trommel
    maqsum, fuell = "D.T.k.T.D.k.T.k.", "D.TkTkT.DkTkTkTk"
    s.trommeln("kampf", wdh(" | ".join([maqsum] * 3 + [fuell]), 4), gain=1.0)
    s.trommeln("kampf", wdh("B.......B.......", 16), gain=0.8)
    s.trommeln("kampf", wdh("G............... | ................", 7) + " | G............... | G.......G...G.G.", gain=0.9)
    s.trommeln("kampf", wdh("R............... | ................ | ................ | ................", 4), gain=0.9)
    s.trommeln("kampf", wdh("................", 8) + " | " + wdh("..z...z...z...z.", 4) + " | " + wdh("................", 4), gain=0.8)
    riff = "d3/.5 d3/.5 eb3/.5 d3/.5 c3/.5 d3/.5 r/1"
    riff2 = "d3/.5 eb3/.5 f#3/.5 g3/.5 f#3/.5 eb3/.5 d3/1"
    s.stimme("kampf", "oud", wdh(" | ".join([riff] * 3 + [riff2]), 4), gain=0.8, menschlich=0.006)
    s.stimme("kampf", "mizmar", wdh("r/4", 4) + """ |
        a4/1+ bb4/.5 a4/.5 g4/1 f#4/1 | g4/2 f#4/1 eb4/1 | d4/4 | r/4 | """ + wdh("r/4", 4) + """ |
        a4/.5 bb4/.5 c5/.5 d5/.5 c5/1 bb4/1 | a4/4 | r/4 | r/4""", gain=0.6)
    plan = {"grund": (0.30, 40, 9000, 2.0), "melodie": (0.32, 120, None), "spannung": (0.28, 60, 8000), "kampf": (0.18, 35, None, -2.5)}
    return s, ausgeben(s, plan, -19.0, "mus_a1")

# ---------------------------------------------------------------- Akt 2: Die Wahrheit (Kurd auf A)
def akt2():
    s = Stueck(60, 16, raum=3.6, dunkel=2600, seed=22)
    s.stimme("melodie", "rebab", """
        r/1 a3/1 bb3/.5 a3/.5 d4/1 | c4/3 r/1 | r/1 c4/1 d4/.5 c4/.5 bb3/1 | a3/4 |
        r/2 e4/1 f4/1 | e4/1.5 d4/.5 c4/1 d4/1 | bb3/2 c4/1 bb3/1 | ~a3/4 |
        r/4 | r/4 | r/4 | r/4 |
        r/1 a3/1 bb3/.5 a3/.5 f4/1 | e4/2 d4/1 c4/1 | bb3/1 a3/.5 bb3/.5 a3/2 | r/4""", gain=1.0)
    # Die Klagestimme übernimmt in der Mitte
    s.stimme("melodie", "frau", wdh("r/4", 8) + """ |
        r/1 e4/3 | d4/2 c4/1 d4/1 | bb3/2 ~c4/2 | a3/4 | """ + wdh("r/4", 4), gain=0.85)
    s.stimme("melodie", "harfe", """
        a3/.25 e4/.25 a4/3.5 | r/4 | r/4 | r/4 | f3/.25 c4/.25 f4/3.5 | r/4 | r/4 | r/4 |
        d4/.25 a4/.25 f5/3.5 | r/4 | r/4 | r/4 | a3/.25 e4/.25 a4/3.5 | r/4 | r/4 | r/4""", gain=0.5)
    s.bordun("grund", [midi("a2"), midi("e3")], gain=0.55)
    s.stimme("grund", "oud", wdh("a2/2- r/2 | r/4", 7) + " | bb2/2- r/2 | r/4", gain=0.5)
    s.trommeln("grund", wdh("g............... | ................ | ................ | ................", 4), gain=0.45)
    s.stimme("spannung", "rebab", """
        a3/4- | ~a3/4- | bb3/4- | ~bb3/4- | a3/4- | ~a3/4- | g3/4- | a3/4- |
        a3/4- | ~a3/4- | bb3/4- | ~bb3/4- | c4/4- | bb3/4- | a3/4- | ~a3/4-""", gain=0.7, oktave=0)
    s.trommeln("spannung", wdh("B.......b.......", 16), gain=0.6)
    s.trommeln("spannung", wdh("................ | ................ | ............r... | ................", 4), gain=0.7)
    s.trommeln("kampf", wdh("G.......G....... | G.......G.....g.", 8), gain=1.0)
    s.trommeln("kampf", wdh(" | ".join(["D..kT.k.D.kkT.k."] * 3 + ["D.kkT.kkD.TkTkTk"]), 4), gain=0.9)
    s.trommeln("kampf", wdh("B..B....B..B....", 16), gain=0.7)
    riff = "a2/.5 bb2/.5 a2/.5 r/.5 a2/.25 a2/.25 c3/.5 bb2/1"
    s.stimme("kampf", "oud", wdh(riff, 16), gain=0.8, menschlich=0.006)
    s.stimme("kampf", "mizmar", wdh("r/4", 8) + " | a4/2+ bb4/2 | a4/1 g4/1 f4/1 e4/1 | f4/2 e4/2 | a4/4 | " + wdh("r/4", 4), gain=0.55)
    s.bordun("kampf", [midi("a3")], gain=0.25, instr="chor")
    plan = {"grund": (0.38, 40, 7000, 2.0), "melodie": (0.36, 100, None), "spannung": (0.32, 50, 7000, 3.5), "kampf": (0.22, 30, None, -2.5)}
    return s, ausgeben(s, plan, -19.5, "mus_a2")

# ---------------------------------------------------------------- Akt 3: Der Morgen (mixolydisch auf G)
def akt3():
    s = Stueck(88, 16, raum=2.0, dunkel=4500, seed=33)
    s.stimme("melodie", "ney", """
        g4/1 a4/.5 g4/.5 c5/1 b4/1 | a4/1 b4/.5 c5/.5 d5/2 | e5/1 d5/.5 c5/.5 b4/1 a4/1 | g4/3 r/1 |
        g4/1 a4/.5 g4/.5 d5/1 c5/1 | b4/1 c5/.5 d5/.5 e5/1 f5/1 | g5/2+ f5/.5 e5/.5 d5/1 | ~d5/4 |
        r/4 | r/4 | r/2 d5/1 e5/1 | f5/1 e5/.5 d5/.5 c5/1 b4/1 |
        c5/1.5 b4/.5 a4/1 g4/1 | a4/1 b4/.5 a4/.5 g4/2 | r/4 | r/4""", gain=1.0)
    s.stimme("melodie", "qanun", wdh("r/4", 8) + """ |
        g3/.5 b3/.5 d4/.5 g4/.5 a4/.5 g4/.5 e4/.5 d4/.5 | c4/.5 d4/.5 e4/.5 d4/.5 b3/1 g3/1 | """ + wdh("r/4", 6), gain=0.9)
    s.stimme("melodie", "harfe", """
        g3/.25 d4/.25 g4/.25 b4/3.25 | r/4 | r/4 | r/4 | c4/.25 e4/.25 g4/.25 c5/3.25 | r/4 | r/4 |
        d4/.5- e4/.5- f4/.5- a4/.5- c5/.5- d5/1.5- | r/4 | r/4 | r/4 | r/4 | f4/.25 a4/.25 c5/3.5 | r/4 |
        g3/.25 d4/.25 g4/.25 b4/3.25 | r/4""", gain=0.55)
    s.bordun("grund", [midi("g2"), midi("d3")], gain=0.5)
    s.stimme("grund", "oud", wdh("g2/1- r/1 d3/1- r/1", 16), gain=0.45)
    s.trommeln("grund", "Z............... | " + wdh("................", 7) + " | z............... | " + wdh("................", 7), gain=0.7)
    s.trommeln("grund", wdh("................ | ................ | ................ | ............r...", 4), gain=0.5)
    s.stimme("spannung", "rebab", """
        g3/4- | ~g3/4- | ab3/4- | ~ab3/4- | g3/4- | ~g3/4- | f3/4- | g3/4- |
        g3/4- | ~g3/4- | ab3/4- | ~ab3/4- | bb3/4- | ab3/4- | g3/4- | ~g3/4-""", gain=0.7)
    s.trommeln("spannung", wdh("D...d...D...d...", 16), gain=0.6)
    s.trommeln("spannung", wdh("................ | ........r.......", 8), gain=0.7)
    saidi, fuell = "D.T...D.D...T.k.", "D.TkT.DkD.TkTkTk"
    s.trommeln("kampf", wdh(" | ".join([saidi] * 3 + [fuell]), 4), gain=1.0)
    s.trommeln("kampf", wdh("B.....B.B.......", 16), gain=0.8)
    s.trommeln("kampf", wdh("G............... | ................ | G............... | ........G.......", 4), gain=0.9)
    s.trommeln("kampf", wdh("R.......r....... | ................", 8), gain=0.8)
    riff = "g2/.5 g2/.5 a2/.5 g2/.5 f2/.5 g2/.5 b2/.5 c3/.5"
    s.stimme("kampf", "oud", wdh(riff, 16), gain=0.75, menschlich=0.006)
    s.stimme("kampf", "mizmar", wdh("r/4", 4) + """ |
        g4/1+ a4/.5 b4/.5 c5/1 b4/1 | a4/2 g4/2 | d5/2+ c5/1 b4/1 | a4/4 | """ + wdh("r/4", 4) + """ |
        d5/1+ e5/.5 d5/.5 c5/1 b4/1 | a4/1 b4/.5 a4/.5 g4/2 | f4/2 g4/2 | ~g4/4""", gain=0.55)
    plan = {"grund": (0.26, 40, 10000, 2.0), "melodie": (0.26, 110, None), "spannung": (0.24, 60, 8000), "kampf": (0.16, 35, None, -2.5)}
    return s, ausgeben(s, plan, -19.0, "mus_a3")

# ---------------------------------------------------------------- Titel (Hidschas auf D, ruhiger, alles in einer Datei)
def titel():
    s = Stueck(66, 16, raum=3.0, dunkel=3400, seed=44)
    akkorde = ["d", "d", "eb", "d", "g", "g", "a", "a", "d", "d", "eb", "d", "c", "bb", "a", "d"]
    terz = {"d": "f#", "eb": "g", "g": "bb", "a": "c#", "c": "eb", "bb": "d"}
    harfe = []
    for a in akkorde:
        g = a + "3" if a in ("g", "a", "bb", "c") else a + "4"
        if a in ("g", "a", "bb", "c"):
            hoch = {"g": "d4", "a": "e4", "bb": "f4", "c": "g4"}[a]
            okt = {"g": "g4", "a": "a4", "bb": "bb4", "c": "c5"}[a]
            t = {"g": "bb4", "a": "c#5", "bb": "d5", "c": "eb5"}[a]
        else:
            hoch = {"d": "a4", "eb": "bb4"}[a]
            okt = {"d": "d5", "eb": "eb5"}[a]
            t = {"d": "f#5", "eb": "g5"}[a]
        harfe.append("%s/.5- %s/.5- %s/.5- %s/.5- %s/.5- %s/.5- %s/.5- %s/.5-" % (g, hoch, okt, hoch, t, hoch, okt, hoch))
    s.stimme("voll", "harfe", " | ".join(harfe), gain=0.4)
    s.stimme("voll", "ney", """
        r/4 | r/4 | r/2 a4/1.5 (c5)bb4/.5 | a4/1 g4/.5 f#4/.5 g4/2 |
        r/1 bb4/.5 a4/.5 g4/1 f#4/1 | g4/3 r/1 | r/1 a4/.5 bb4/.5 c#5/1 bb4/1 | ~a4/4 |
        d4/1 eb4/.5 d4/.5 g4/1.5 f#4/.5 | f#4/1 eb4/.5 f#4/.5 d4/2 | r/2 a4/1 c5/1 | bb4/1.5 a4/.5 g4/1 f#4/1 |
        g4/1 f#4/.5 eb4/.5 d4/2 | d4/1 c4/1 bb3/2 | a3/2 bb3/1 c#4/1 | d4/4""", gain=1.0)
    s.stimme("voll", "frau", wdh("r/4", 8) + """ |
        d4/4 | ~d4/4 | r/2 a3/2 | bb3/4 | r/4 | r/4 | a3/4 | ~a3/4""", gain=0.5)
    s.bordun("voll", [midi("d3"), midi("a3")], gain=0.45)
    s.stimme("voll", "glocke", "d6/4- | " + wdh("r/4", 7) + " | d6/4- | " + wdh("r/4", 7), gain=0.45)
    s.trommeln("voll", wdh("b.......b....... | ................", 4) + " | " + wdh("B.......b.......", 6) + " | " + wdh("b...............", 2), gain=0.5)
    plan = {"voll": (0.34, 40, None)}
    return s, ausgeben(s, plan, -18.5, "mus_titel")

# ---------------------------------------------------------------- Hüter (phrygisch-dominant auf E), drei Steigerungen
def hueter():
    s = Stueck(96, 16, raum=2.4, dunkel=3000, seed=55)
    s.bordun("grund", [midi("e2"), midi("b2")], gain=0.6)
    s.bordun("grund", [midi("f3")], gain=0.12, instr="chor")
    s.trommeln("grund", wdh("B...b...........", 16), gain=0.8)
    s.trommeln("grund", wdh("G............... | ................ | ................ | ................", 4), gain=0.8)
    # Phase 1: Maqsum und eine Oud, die kreist
    s.trommeln("p1", wdh(" | ".join(["D.T.k.T.D.k.T.k."] * 3 + ["D.TkTkT.DkTkTkTk"]), 4), gain=0.9)
    riff = "e3/.5 f3/.5 e3/.5 r/.5 e3/.5 f3/.5 g#3/.5 f3/.5"
    s.stimme("p1", "oud", wdh(riff, 16), gain=0.75, menschlich=0.006)
    # Phase 2: die Mizmar ruft, der Bendir treibt, Zimbeln auf den Zwischenschlägen
    s.stimme("p2", "mizmar", """
        e4/2+ f4/1 e4/1 | g#4/1 a4/1 g#4/1 f4/1 | e4/4 | r/4 |
        e4/2+ f4/1 g#4/1 | a4/1 b4/1 a4/1 g#4/1 | f4/2 e4/2 | r/4 |
        b4/2+ c5/1 b4/1 | a4/1 g#4/1 f4/1 g#4/1 | a4/2 g#4/1 f4/1 | e4/4 |
        r/4 | e4/1 f4/1 g#4/1 a4/1 | b4/1+ a4/1 g#4/1 f4/1 | e4/4""", gain=0.6)
    s.trommeln("p2", wdh("B.b.B.b.B.b.B.b.", 16), gain=0.6)
    s.trommeln("p2", wdh("..z...z...z...z.", 16), gain=0.6)
    # Phase 3: große Trommeln in Achteln, der Chor steigt, das Sistrum rasselt ohne Pause
    s.trommeln("p3", wdh("G.g.G.g.G.g.G.g. | G.g.G.g.G.g.GgGg", 8), gain=0.85)
    s.trommeln("p3", wdh("R.r.R.r.R.r.R.r.", 16), gain=0.5)
    s.stimme("p3", "chor", wdh("e3/4 | ~e3/4 | f3/4 | ~f3/4", 4), gain=0.7)
    s.stimme("p3", "rebab", wdh("r/4", 8) + " | e4/4 | f4/4 | g#4/4 | f4/4 | e4/4 | f4/4 | e4/4 | ~e4/4", gain=0.6)
    plan = {"grund": (0.26, 35, 8000), "p1": (0.18, 40, None, -3.0), "p2": (0.22, 60, None), "p3": (0.2, 30, None, -4.0)}
    fertig = ausgeben(s, plan, -23.0, "mus_hueter")
    return s, fertig

# ---------------------------------------------------------------- Nachklang nach dem Kampf (einmalig, je Akt)
def nachklang():
    erg = {}
    for akt, bpm, instr, noten, bord, seed in [
            (1, 70, "ney", "a4/2 g4/1 f#4/1 | (f#4)eb4/1 d4/3 | r/4", ["d3", "a3"], 61),
            (2, 56, "rebab", "e4/2 d4/1 c4/1 | bb3/1 a3/3 | r/4", ["a2", "e3"], 62),
            (3, 80, "ney", "d5/2 c5/1 b4/1 | a4/1 g4/3 | r/4", ["g2", "d3"], 63)]:
        s = Stueck(bpm, 3, raum=3.0, dunkel=3200, seed=seed, schleife=False)
        s.stimme("voll", instr, noten, gain=1.0)
        s.stimme("voll", "harfe", "r/1 %s/3- | r/4 | r/4" % {1: "d5", 2: "a4", 3: "g4"}[akt], gain=0.4)
        I = instrumente()["chor"]
        buf = s._puffer("voll")
        for m in bord:
            y = I.ton(midi(m), s.L / SR, 0.35, s.rng)
            y = werk.ausblenden(werk.einblenden(y, 1.2, SR), 3.0, SR)
            buf[:len(y)] += y
        erg[akt] = ausgeben(s, {"voll": (0.4, 60, None)}, -21.0, "mus_a%d_nachklang" % akt)
    return erg

# ---------------------------------------------------------------- Hauptprogramm
def mischung(*teile):
    return sum(teile)

if __name__ == "__main__":
    was = [a for a in sys.argv[1:] if not a.startswith("--")] or ["akt1", "akt2", "akt3", "titel", "hueter", "nachklang"]
    probe = "--probe" in sys.argv
    for w in was:
        print(w)
        erg = globals()[w]()
        if not probe or w == "nachklang":
            continue
        s, f = erg
        if not probe:
            continue
        if w.startswith("akt"):
            n = w[-1]
            erk = mischung(f["grund"], f["melodie"])
            sp = mischung(f["grund"], f["spannung"])
            ka = mischung(f["grund"], f["spannung"] * 0.6, f["kampf"])
            # Vorführung: Erkunden, Spannung, Kampf, dann wieder Erkunden (je eine Schleife)
            probe_schreiben("musik_akt%s" % n, [erk, sp, ka, f["grund"]])
        elif w == "hueter":
            g = f["grund"]
            probe_schreiben("musik_hueter", [g + f["p1"], g + f["p1"] + f["p2"], g + f["p1"] + f["p2"] + f["p3"]])
