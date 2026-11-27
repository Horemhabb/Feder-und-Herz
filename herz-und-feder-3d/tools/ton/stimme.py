#!/usr/bin/env python3
# Nachbearbeitung der Sprechstimmen (Fassung 4.3). Aus einer Aufnahme von ElevenLabs (tools/ton/roh/stimme/…) wird
# eine Spieldatei audio/<name>.ogg: Stille vorn kurz, hinten nichts abgeschnitten (der letzte Laut klingt aus, dazu
# eine halbe Sekunde Raum), Rumpeln weg, ein wenig Klarheit, je Rolle ein Raum, einheitlich −17 LUFS, Spitze −1 dB.
#
# Rollen (Stimmen aus creative_list_voices, Modell Eleven v3, Standard-Einstellungen, Regie über Tags):
#   erzaehler  Nils Parler – Storyteller (uhAMuGA4NQtQQxKrLO3p): tief, erzählend, packend. Kleiner Raum.
#              Ersatz: Samuel Storm (NV8D9kv4W21bIe2GkOiE, bisherige Stimme) oder Leander (LdH3BDLqhNcq7kil2o2r).
#   hueter     Brako – Contemplative deep devouring (1m6iR8iVpwOGuiSZS2DT) für männliche Hüter,
#   hueterin   Moreana – Dark & Charismatic (DRU8LC80huhCKDeU8h2X) für Hüterinnen (Mutter der Häute, die Entronnene):
#              großer, dunkler Raum, etwas Tiefe dazu.
#   leute      Piero (9aLXbGY4BEHhMWw0SgDi) und Mona (sa2Ndyhs1V7h8EXKT9mV): warm, nah, fast trocken.
#
# Aufruf: python3 tools/ton/stimme.py <rolle> <rohdatei.mp3> <zielname> [--probe]
#         --probe schreibt in den Hörproben-Ordner statt nach audio/
import pathlib, sys
import numpy as np
import werk

SR = 44100
AUS_SR = 32000
PROBE = pathlib.Path("/tmp/claude-0/-home-user-Feder-und-Herz/43b90733-ee5e-581f-a834-89ba24d13877/scratchpad/ton/stimmen")

ROLLEN = {
    #            Raum s, Mischung, Dunkelheit Hz, Tiefe +dB bei 120 Hz, Klarheit +dB bei 3,5 kHz
    "erzaehler": (0.7, 0.07, 4000, 0.0, 1.5),
    "hueter":    (2.2, 0.20, 2200, 2.5, 0.5),
    "hueterin":  (2.0, 0.18, 2800, 1.0, 1.0),
    "leute":     (0.4, 0.05, 5000, 0.0, 1.0),
    "ba":        (1.4, 0.16, 5000, -1.0, 1.5),   # Nebet als Ba: nah, aber mit einem Hauch Weite, nicht von dieser Welt
    "gott":      (1.6, 0.12, 4000, 0.5, 1.0),    # Thot, Isis
    "sammler":   (1.2, 0.10, 3500, 1.0, 0.5),
}

def bearbeite(x, rolle):
    raum, mix, dunkel, tiefe, klar = ROLLEN[rolle]
    # 1. Rumpeln und Gleichanteil weg, Mitten leicht entschlackt, etwas Präsenz
    x = werk.filt(x, lambda f: werk.hoch(f, 70, 2) * werk.glocke(f, 260, 0.8, -1.5) * werk.glocke(f, 3500, 0.9, klar)
                  * werk.glocke(f, 120, 0.7, tiefe) * werk.tief(f, 12000, 2), SR)
    # 2. Anfang: 60 ms vor dem ersten Laut. Ende: bis der Laut unter −55 dB gefallen ist, nichts abschneiden
    s = werk.spitze(x)
    laut = np.nonzero(np.abs(x) > s * 10 ** (-45 / 20))[0]
    a = max(0, laut[0] - int(0.06 * SR))
    leise = np.nonzero(np.abs(x) > s * 10 ** (-55 / 20))[0]
    e = min(len(x), leise[-1] + int(0.08 * SR))
    x = x[a:e]
    x = werk.einblenden(x, 0.01, SR)
    # 3. Raum (mit Nachklang am Ende) und eine halbe Sekunde Ausklang
    ir = werk.nachhall_impuls(raum, SR, dunkel, seed=5)
    y = werk.hall(np.pad(x, (0, int(0.5 * SR))), ir, mix)
    y = y[: len(x) + int(max(0.5, raum * 0.6) * SR)]
    y = werk.ausblenden(y, 0.35, SR)
    # 4. Lautheit und Spitzen
    return werk.auf_lufs(y, -17.0, SR, -1.0)

def main():
    rolle, quelle, ziel = sys.argv[1], sys.argv[2], sys.argv[3]
    x = werk.lade(quelle, SR)
    y = bearbeite(x, rolle)
    ordner = PROBE if "--probe" in sys.argv else None
    p = werk.schreibe(ziel, y, SR, q=4, ordner=ordner, aus_sr=AUS_SR)
    print("%-28s %5.2f s  %5.1f LUFS  Spitze %5.1f dB" % (p.name, len(y) / SR, werk.lufs(y, SR), werk.db(werk.spitze(y))))

if __name__ == "__main__":
    main()
