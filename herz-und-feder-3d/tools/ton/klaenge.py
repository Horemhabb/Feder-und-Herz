#!/usr/bin/env python3
# Geräusche für das Spiel aufbereiten (Fassung 4.3): aus den Rohaufnahmen von ElevenLabs (Sound Effects v3,
# tools/ton/roh/…) werden die Dateien in audio/. Jede Datei wird gleich behandelt:
#   mono, Stille vorn weg (2 ms Vorlauf), hinten nur bis zum Verklingen, Rumpeln unter 35–60 Hz weg,
#   auf eine Lautheit je Gruppe gebracht (LUFS, Spitzen höchstens −1 dB), weich ausgeblendet.
# Schleifen (Klangkulisse, Sandsturm) werden zusätzlich nahtlos gemacht (Ende in den Anfang geblendet).
# Varianten heißen name1 … nameN; Sfx.VARIANTS in scripts/sfx.gd nennt ihre Zahl.
# Dazu kommt die Nacharbeit an älteren Dateien (übersteuerte Spitzen, Nähte von Schleifen, Stereo → mono).
#
# Aufruf: python3 tools/ton/klaenge.py [neu] [alt]     (ohne Angabe: beides)
import sys
import numpy as np
import werk

SR = 44100

# Gruppe: (Ziel-LUFS, Hochpass Hz, Abtastrate der Datei, Vorbis-Güte)
GRUPPE = {
    "kampf":   (-14.0, 45, 44100, 4),
    "stimme":  (-16.0, 70, 44100, 4),
    "gegner":  (-16.0, 40, 44100, 4),
    "affix":   (-16.0, 35, 44100, 4),
    "hueter":  (-14.0, 30, 44100, 4),
    "ui":      (-20.0, 80, 44100, 4),
    "welt":    (-20.0, 40, 32000, 4),
    "kulisse": (-22.0, 30, 32000, 3),
}

# Ziel ← [Rohdateien] (mehrere: Varianten 1 … N), Gruppe, Sonderwünsche
NEU = [
    # Held je Klasse
    ("hieb", ["kampf/hieb_1", "kampf/hieb_2", "kampf/hieb_3"], "kampf", {}),
    ("klinge", ["kampf/klinge_1", "kampf/klinge_2", "kampf/klinge_3"], "kampf", {}),
    ("faust", ["kampf/faust_1", "kampf/faust_2", "kampf/faust_3"], "kampf", {"db": -2}),
    ("faustschlag", ["kampf/faustt_1", "kampf/faustt_2", "kampf/faustt_3"], "kampf", {"hp": 70, "glanz": 4}),
    ("armbrust", ["kampf/armbrust_1", "kampf/armbrust_3"], "kampf", {"db": -2}),
    ("bolzen", ["kampf/bolzen_1", "kampf/bolzen_2", "kampf/bolzen_3"], "kampf", {"hp": 70, "glanz": 3}),
    ("sternfunke", ["kampf/funke_1", "kampf/funke_2", "kampf/funke_3"], "kampf", {"db": -3}),
    ("sterntreffer", ["kampf/stern_1", "kampf/stern_2", "kampf/stern_3"], "kampf", {"db": -2}),
    ("meteor", ["kampf/meteor_1"], "kampf", {"einschlag": 0.7}),
    ("windstoss", ["kampf/wind_2", "kampf/wind_1"], "kampf", {"hp": 80}),
    ("koerper_fall", ["kampf/fall_1", "kampf/fall_2", "kampf/fall_3"], "kampf", {"db": -3, "hp": 55}),
    ("scherben", ["kampf/scherben_1", "kampf/scherben_3"], "kampf", {"db": -2}),
    ("schmerz_m", ["kampf/schmerz_m_1", "kampf/schmerz_m_2", "kampf/schmerz_m_3"], "stimme", {}),
    ("schmerz_w", ["kampf/schmerz_w_1", "kampf/schmerz_w_2", "kampf/schmerz_w_3"], "stimme", {}),
    ("tod_w", ["kampf/tod_w_1"], "stimme", {}),
    # Gegner je Art
    ("krieger_wach", ["gegner/krieger_wach_1", "gegner/krieger_wach_2"], "gegner", {}),
    ("krieger_tod", ["gegner/krieger_tod_1", "gegner/krieger_tod_2"], "gegner", {}),
    ("priesterin_wach", ["gegner/priesterin_wach_1", "gegner/priesterin_wach_2"], "gegner", {}),
    ("priesterin_tod", ["gegner/priesterin_tod_1", "gegner/priesterin_tod_2"], "gegner", {}),
    ("koloss_wach", ["gegner/koloss_wach_1", "gegner/koloss_wach_2"], "gegner", {"db": 1}),
    ("koloss_tod", ["gegner/koloss_tod_1", "gegner/koloss_tod_2"], "gegner", {"db": 1}),
    ("erloschen_wach", ["gegner/erloschen_wach_1", "gegner/erloschen_wach_2"], "gegner", {"db": -2}),
    ("erloschen_tod", ["gegner/erloschen_tod_1", "gegner/erloschen_tod_2"], "gegner", {"db": -2}),
    ("hohl_wach", ["gegner/hohl_wach_1", "gegner/hohl_wach_2"], "gegner", {}),
    ("hohl_tod", ["gegner/hohl_tod_1", "gegner/hohl_tod_2"], "gegner", {}),
    ("hueter_ansage", ["gegner/hueter_ansage_1"], "hueter", {"glanz": 3}),
    ("hueter_schlag", ["gegner/hueter_schlag_2"], "hueter", {"glanz": 4}),
    # Champions
    ("aff_auftritt", ["affix/auftritt_2"], "affix", {"glanz": 3}),
    ("aff_glut", ["affix/glut_2"], "affix", {"db": -3}),
    ("aff_sturm", ["affix/sturm_1"], "affix", {"schleife": 1.0, "db": -4}),
    ("aff_feder", ["affix/feder_2"], "affix", {}),
    ("aff_feder_bruch", ["affix/feder_bruch_1"], "affix", {}),
    ("aff_ruf", ["affix/ruf_2"], "affix", {}),
    ("aff_sprung", ["affix/sprung_1"], "affix", {}),
    ("aff_klage", ["affix/klage_1"], "affix", {"db": -2}),
    ("aff_fessel", ["affix/fessel_1"], "affix", {}),
    ("aff_spalt", ["affix/spalt_2"], "affix", {}),
    ("aff_kette", ["affix/kette_2"], "affix", {"db": -2}),
    # Oberfläche (ui.ogg ist der Klick aller Knöpfe: der neue Holzklick ersetzt ihn)
    ("ui", ["ui/knopf_1"], "ui", {}),
    ("knopf", ["ui/knopf_1"], "ui", {}),
    ("fenster_auf", ["ui/fenster_auf_1"], "ui", {}),
    ("fenster_zu", ["ui/fenster_zu_1"], "ui", {}),
    ("belohnung", ["ui/belohnung_2"], "ui", {"db": 2}),
    ("stufe", ["ui/stufe_2"], "ui", {"db": 3}),
    ("anlegen", ["ui/anlegen_1"], "ui", {}),
    ("legendary", ["ui/legendaer_2"], "ui", {"db": 4}),
    ("knopf_gold", ["ui/knopf_gold_1", "ui/knopf_gold_2"], "ui", {}),
    ("herzschlag", ["ui/herzschlag_1"], "ui", {"hp": 30, "db": 2}),
    # Ereignisse der Klangkulisse
    ("ev_flamme", ["welt/flamme_2"], "welt", {}),
    ("ev_platsch", ["welt/platsch_2"], "welt", {}),
    ("ev_boe", ["welt/boe_1"], "welt", {}),
    ("ev_vogel", ["welt/vogel_2"], "welt", {"db": -2}),
    ("ev_knochen", ["welt/knochen_1"], "welt", {}),
    ("ev_gong", ["welt/gong_1"], "welt", {"db": -2}),
    ("ev_fluestern", ["welt/fluestern_1"], "welt", {"db": -2}),
    # Klangkulisse: Teppiche je Ort (nahtlose Schleifen)
    ("amb_grab", ["kulisse/grab"], "kulisse", {"schleife": 2.0}),
    ("amb_hoehle", ["kulisse/hoehle"], "kulisse", {"schleife": 2.0}),
    ("amb_nun", ["kulisse/nun"], "kulisse", {"schleife": 2.0}),
    ("amb_feuergrube", ["kulisse/feuergrube"], "kulisse", {"schleife": 2.0}),
    ("amb_morgen", ["kulisse/morgen"], "kulisse", {"schleife": 2.0}),
    ("amb_wind", ["kulisse/wind"], "kulisse", {"schleife": 2.0, "db": -2}),
    ("amb_sandbank", ["kulisse/sandbank"], "kulisse", {"schleife": 2.0}),
]

# Ältere Dateien, die bleiben, aber nachgearbeitet werden: Spitzen auf −1 dB (sie lagen bis +3,9 dB über
# Vollaussteuerung), Schleifen nahtlos, Stereo zu mono. Der Pegel bleibt sonst, wie er war (VOL ist darauf eingestellt).
ALT_SPITZEN = ["hit1", "hit2", "hit3", "boss_appear", "gate", "oath", "dash", "bolt", "potion", "ev_fluegel", "ev_tropfen",
               "hero_die", "skel_attack", "skel_wake", "aufheben", "krug_bricht", "beam", "udjat", "truhe", "ev_stein"]
ALT_SCHLEIFEN = {"src_schrein": 1.5, "src_werkstatt": 1.5, "src_herz": 1.0, "amb_rosetau": 2.0, "torch": 1.0}
# Unbenutzt oder ersetzt (Klassenklänge, neue Musik): werden gelöscht
WEG = ["step1", "step2", "step3", "swing1", "swing2", "swing3", "hurt1", "hurt2", "hurt3", "amb_drone",
       "mus_duat", "mus_felder", "mus_grab", "mus_hoehle", "mus_kampf", "mus_rosetau", "mus_wueste"]

def roh(name):
    return werk.lade(werk.ROH / (name + ".mp3"), SR)

def aufbereiten(x, gruppe, opt):
    ziel, hp, aus_sr, q = GRUPPE[gruppe]
    hp = opt.get("hp", hp)
    glanz = opt.get("glanz", 0.0)
    fn = lambda f: werk.hoch(f, hp, 2) * werk.glocke(f, 2500, 1.0, glanz) * werk.tief(f, 15000 if aus_sr > 40000 else 14000, 2)
    if "schleife" in opt:
        x = werk.filt(x, fn, SR, kreis=True)
        x = werk.nahtlos(x, opt["schleife"], SR)
        y = werk.auf_lufs(x, ziel + opt.get("db", 0.0), SR, -2.0)
        return y, aus_sr, q
    x = werk.filt(x, fn, SR)
    if "einschlag" in opt:
        # der Einschlag soll nach opt["einschlag"] Sekunden kommen (main.gd › meteor wartet 0,7 s)
        h = int(0.02 * SR)
        e = np.array([np.sqrt(np.mean(x[i:i + h] ** 2)) for i in range(0, len(x) - h, h)])
        spitze_t = int(np.argmax(e)) * 0.02
        x = x[max(0, int((spitze_t - opt["einschlag"]) * SR)):]
        x = werk.einblenden(x, 0.05, SR)
    else:
        x = werk.stille_weg(x, -50.0, SR, vorn=0.002, hinten=0.06)
    y = werk.auf_lufs(x, ziel + opt.get("db", 0.0), SR, -1.0)
    return werk.ausblenden(y, 0.03, SR), aus_sr, q

def neu():
    for ziel, quellen, gruppe, opt in NEU:
        mehrere = len(quellen) > 1
        for i, q in enumerate(quellen):
            y, aus_sr, guete = aufbereiten(roh(q), gruppe, opt)
            name = "%s%d" % (ziel, i + 1) if mehrere else ziel
            werk.schreibe(name, y, SR, q=guete, aus_sr=aus_sr)
            n = werk.naht(y, SR) if "schleife" in opt else None
            print("  %-20s %5.2f s %6.1f LUFS  Spitze %5.1f dB%s" % (name, len(y) / SR, werk.lufs(y, SR), werk.db(werk.spitze(y)),
                  "  Naht %+.1f dB / %.2f" % n if n else ""))

def alt():
    for name in ALT_SPITZEN:
        p = werk.AUDIO / (name + ".ogg")
        x = werk.lade(p, SR)
        y = werk.begrenzen(x, -1.0, SR)
        werk.schreibe(name, y, SR, q=4)
        print("  %-20s Spitze %5.1f → %5.1f dB" % (name, werk.db(werk.spitze(x)), werk.db(werk.spitze(y))))
    for name, blende in ALT_SCHLEIFEN.items():
        p = werk.AUDIO / (name + ".ogg")
        x = werk.lade(p, SR)
        y = werk.nahtlos(x, blende, SR)
        y = werk.begrenzen(y, -1.0, SR)
        rate = 32000 if name != "torch" else 44100
        werk.schreibe(name, y, SR, q=4, aus_sr=rate)
        print("  %-20s Naht vorher %+.1f dB / %.2f, nachher %+.1f dB / %.2f" % ((name,) + werk.naht(x, SR) + werk.naht(y, SR)))
    for name in WEG:
        for endung in (".ogg", ".ogg.import"):
            p = werk.AUDIO / (name + endung)
            if p.exists():
                p.unlink()
    print("  gelöscht:", " ".join(WEG))

if __name__ == "__main__":
    was = sys.argv[1:] or ["neu", "alt"]
    if "neu" in was:
        print("neu")
        neu()
    if "alt" in was:
        print("alt")
        alt()
