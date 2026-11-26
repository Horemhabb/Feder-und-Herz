# Prueft bildwerk_plan.json, bildwerk.bat und einbauen.bat gegen die Regeln aus den bisherigen Laeufen (BILDWERK.md, Abschnitt 2).
# Fuer Claude und jeden, der den Plan aendert. Laeuft ohne ComfyUI, nur mit Python 3 (unter Linux und Windows):
#     python3 pruefe_plan.py            (im Ordner tools/bildwerk)
# Fehler (FEHLER) muessen weg, bevor der Plan zum PC geht; Hinweise (HINWEIS) betreffen meist alte Stufen, die schon gerechnet sind.
# Rueckgabewert 0 = alles gruen.
import json, os, re, sys

HIER = os.path.dirname(os.path.abspath(__file__))
PLAN = os.path.join(HIER, "bildwerk_plan.json")
BW = os.path.join(HIER, "bildwerk.bat")
EB = os.path.join(HIER, "einbauen.bat")

# Die Stufen 1 bis 17 sind gerechnet oder laufen: ihre Motive bleiben, wie sie sind (nur Hinweise, keine Fehler).
ALTE_STUFEN = {"symbole_neu", "portraets_figuren", "portraets_leute", "texturen_stunden", "astzeichen", "gegner_lexikon", "portraets_leute_nah",
               "portraets_figuren_nah", "texturen_neu", "hueter", "akttafeln", "sand_neu", "gegner_vorlagen", "gegner_vorlagen_tiere",
               "bodenzeichen", "effektbilder", "friese"}
ALTE_STILE = {"alt", "positiv", "aegypt", "frei", "portraet", "textur", "lexikon", "portraet_nah", "portraet_nah_figur", "hueter", "szene",
              "vorlage3d", "vorlage3d_tier", "zeichen", "funke", "fries"}

# Regeln als Muster (ganze Woerter, ohne Gross/Klein). Eine Ausnahme je Motiv steht im Feld "ausnahme" (Liste von Woertern).
ZIFFERN = re.compile(r"\d|%")
TAFEL = re.compile(r"\b(square|squares|plaque|plaques|tile|tiles|tiled|coin|coins|medallion|medallions|frame|framed|frames|border|borders|bordered)\b", re.I)
LICHT = re.compile(r"\b(moon|moonlight|moonlit|lamp|lamps|lantern|lanterns|torch|torches|candle|candles|oil-lamp|sunlight|spotlight|flashlight)\b", re.I)
SCHRIFT = re.compile(r"\b(text|letter|letters|lettering|writing|written|word|words|inscription|inscriptions|label|labels|sign|signs|name|names|"
                     r"title|titles|scroll|scrolls|book|books|hieroglyph|hieroglyphs|hieroglyphic|cartouche|cartouches|caption|captions|font|logo)\b", re.I)
MARKEN = re.compile(r"\b(diablo|baldur|blizzard|larian|path of exile|zelda|hades)\b", re.I)

fehler, hinweise = [], []


def F(t):
    if t not in fehler:
        fehler.append(t)


def H(t):
    if t not in hinweise:
        hinweise.append(t)


def lade_bat(pfad):
    """Den Python-Teil einer .bat laden, ohne main() auszufuehren (die erste Zeile ist der Batch-Start)."""
    src = open(pfad, encoding="utf-8").read()
    zeilen = src.split("\n")
    assert zeilen[0].startswith("@python_embeded"), pfad
    rumpf = "\n".join(zeilen[1:])
    rumpf = re.sub(r"\nmain\(\)\s*$", "\n", rumpf)
    ns = {"__name__": "pruefung", "__file__": pfad}
    alt = sys.argv
    sys.argv = [pfad]
    try:
        exec(compile(rumpf, pfad, "exec"), ns)
    finally:
        sys.argv = alt
    return src, ns


def block(src, name):
    a = src.find("# ---------------------------------------------------------------- gemeinsam")
    b = src.find("# ---------------------------------------------------------------- Ende gemeinsam")
    if a < 0 or b < 0:
        F("%s: gemeinsamer Block (Messwerte und Freistellen) fehlt" % name)
        return ""
    return src[a:b]


def woerter(text, muster, ausnahme):
    return sorted({w.lower() for w in muster.findall(text)} - {w.lower() for w in ausnahme})


def main():
    plan = json.load(open(PLAN, encoding="utf-8"))
    bw_src, bw = lade_bat(BW)
    eb_src, eb = lade_bat(EB)

    # ---- Fassungen
    v = plan.get("version")
    if bw["VERSION"] != v or eb["VERSION"] != v:
        F("Fassungen passen nicht: Plan %s, bildwerk.bat %s, einbauen.bat %s" % (v, bw["VERSION"], eb["VERSION"]))
    if block(bw_src, "bildwerk.bat") != block(eb_src, "einbauen.bat"):
        F("Der gemeinsame Block in bildwerk.bat und einbauen.bat ist nicht mehr gleich")
    for name, src in (("bildwerk.bat", bw_src), ("einbauen.bat", eb_src)):
        for muster in ("/home/", "/tmp/", "/usr/"):
            if muster in src:
                F("%s enthaelt einen Linux-Pfad (%s)" % (name, muster))
        for m in re.finditer(r"(?<![\w.])open\(([^\n]*)", src):   # Textdateien unter Windows immer mit encoding="utf-8"
            if "encoding" not in m.group(1):
                F("%s: open() ohne encoding: %s" % (name, m.group(0)[:70]))

    # ---- Stile
    for sname, st in plan["stile"].items():
        t = st["text"]
        if "{MOTIV}" not in t:
            F("Stil %s: {MOTIV} fehlt" % sname)
        if sname not in ALTE_STILE:
            for muster, was in ((ZIFFERN, "Ziffern"), (LICHT, "Lichtquelle als Wort"), (MARKEN, "fremder Markenname")):
                if muster.search(t):
                    F("Stil %s (neu): %s im Text: %s" % (sname, was, ", ".join(sorted(set(x if isinstance(x, str) else x[0] for x in muster.findall(t))))))
            if "nothing written" not in t:
                F("Stil %s (neu): der Satz 'nothing written anywhere' fehlt" % sname)
        elif ZIFFERN.search(t):
            H("Stil %s (alt, bewaehrt): Ziffern im Text (Markennamen); neue Stufen sollen ihn nicht verwenden" % sname)

    # ---- Motive
    nach_id = {}
    alte_gruppen = {g for s in ALTE_STUFEN if s in plan["stufen"] for g in plan["stufen"][s].get("gruppen", [])}
    for m in plan["motive"]:
        if m["id"] in nach_id:
            if m["gruppe"] in alte_gruppen and nach_id[m["id"]]["gruppe"] in alte_gruppen:
                H("Motiv-ID doppelt in alten Gruppen (geht, weil die Stufen nach Gruppen waehlen): %s" % m["id"])
            else:
                F("Motiv-ID doppelt: %s" % m["id"])
        nach_id[m["id"]] = m
        for feld in ("id", "name", "gruppe", "motiv"):
            if feld not in m:
                F("Motiv %s: Feld %s fehlt" % (m.get("id"), feld))

    # ---- Stufen
    benutzt = set()
    neue_bilder = 0
    for name, st in plan["stufen"].items():
        alt = name in ALTE_STUFEN
        melde = H if alt else F
        for feld in ("titel", "stile", "varianten", "im_spiel"):
            if feld not in st:
                F("Stufe %s: Feld %s fehlt" % (name, feld))
        for s in st["stile"]:
            if s != "@standard" and s not in plan["stile"]:
                F("Stufe %s: Stil %s fehlt" % (name, s))
        if st.get("ansichten", "emblem") not in plan["ansichten"]:
            F("Stufe %s: Ansichten %s fehlen" % (name, st.get("ansichten")))
        for va in st["varianten"]:
            if va not in plan["seeds"]:
                F("Stufe %s: kein Seed fuer Variante %s" % (name, va))
        b, h = st.get("breite", 1024), st.get("hoehe", 1024)
        if b % 16 or h % 16:
            F("Stufe %s: %d x %d ist kein Vielfaches von 16" % (name, b, h))
        if b * h > 1.1 * 1024 * 1024:
            F("Stufe %s: %d x %d ist mehr als etwa ein Megapixel (AMD-Treiber)" % (name, b, h))
        if st.get("kachel") not in (None, "xy", "x", "y", True):
            F("Stufe %s: kachel muss xy, x oder y sein" % name)
        for s in st["stile"]:
            if s in ("aegypt", "alt", "positiv") and not alt and not st.get("probe"):
                F("Stufe %s (neu): Stil %s nennt fremde Spiele mit Ziffern; 'frei' nehmen" % (name, s))
        if "motive" in st:
            for i in st["motive"]:
                if i not in nach_id:
                    F("Stufe %s: Motiv %s fehlt" % (name, i))
        else:
            if not any(m["gruppe"] in st["gruppen"] for m in plan["motive"]):
                F("Stufe %s: keine Motive in den Gruppen %s" % (name, st["gruppen"]))
        try:
            jobs = bw["auftraege"](plan, name, os.path.join(HIER, "_pruefung", name))
        except Exception as e:
            F("Stufe %s: Auftraege lassen sich nicht bauen: %s" % (name, e))
            continue
        if not alt:
            neue_bilder += len(jobs)
        for a in jobs:
            benutzt.add(a["id"])
            m = nach_id[a["id"]]
            aus = m.get("ausnahme", [])
            teil = " ".join([m["motiv"], m.get("hinweis", ""), m.get("tex", "")])
            if ZIFFERN.search(a["prompt"]) and not (alt or a["stil"] in ALTE_STILE and not ZIFFERN.search(teil)):
                melde("Stufe %s, %s: Ziffern im Prompt" % (name, a["id"]))
            if ZIFFERN.search(teil):
                melde("Motiv %s: Ziffern im Motiv" % a["id"])
            for muster, was in ((TAFEL, "lockt Tafel oder Rahmen an"), (LICHT, "Licht als Gegenstand (wird gemalt)"), (SCHRIFT, "legt Schrift nahe")):
                w = woerter(teil, muster, aus)
                if w:
                    melde("Motiv %s (%s): %s: %s" % (a["id"], name, was, ", ".join(w)))
            n = len(a["prompt"].split())
            if n > 175:
                melde("Stufe %s: Prompts mit mehr als 175 Woertern (kostet Zeit beim Text-Encoder)" % name)
            if a["stil"] in ("aegypt", "frei") and "dark" not in m.get("tex", ""):
                melde("Motiv %s: Hintergrund (tex) ohne 'dark' gibt hellen Grund" % a["id"])
        if "einbau" not in st and not alt:
            F("Stufe %s (neu): Feld einbau fehlt (welche Einbau-Art)" % name)
    for m in plan["motive"]:
        if m["id"] not in benutzt:
            H("Motiv %s gehoert zu keiner Stufe" % m["id"])

    # ---- Naechte
    sek_mp = bw["SEK_JE_MEGAPIXEL"]
    tabelle = []
    for nacht, nd in plan.get("naechte", {}).items():
        for feld in ("titel", "zweck", "stufen", "stunden"):
            if feld not in nd:
                F("Nacht %s: Feld %s fehlt" % (nacht, feld))
        alle = nd.get("stufen", []) + nd.get("fuellen", [])
        for s in alle:
            if s not in plan["stufen"]:
                F("Nacht %s: Stufe %s fehlt" % (nacht, s))
        if any(s not in plan["stufen"] for s in alle):
            continue
        jobs = [a for s in nd["stufen"] for a in bw["auftraege"](plan, s, os.path.join(HIER, "_pruefung", s))]
        reserve = [a for s in nd.get("fuellen", []) for a in bw["auftraege"](plan, s, os.path.join(HIER, "_pruefung", s))]
        sek, sek0 = bw["schaetzung"](jobs), sum(sek_mp * a["breite"] * a["hoehe"] / (1024 * 1024) for a in jobs)
        tabelle.append((nacht, len(jobs), sek, sek0, len(reserve), bw["schaetzung"](reserve), nd["stunden"]))
        if all(plan["stufen"][s].get("probe") for s in nd["stufen"]):
            if sek > 3600:
                F("Nacht %s (Proben) dauert %s, mehr als eine Stunde" % (nacht, bw["dauer"](sek)))
        else:
            if sek > nd["stunden"] * 3600 * 1.05:
                F("Nacht %s: %s passen nicht in den Rahmen von %.1f Stunden" % (nacht, bw["dauer"](sek), nd["stunden"]))
            if sek + bw["schaetzung"](reserve) < 6 * 3600:
                F("Nacht %s: mit Reserve nur %s, eine volle Nacht sind sechs bis acht Stunden" % (nacht, bw["dauer"](sek + bw["schaetzung"](reserve))))

    # ---- Einbau: neue Arten zeigen auf Bilder, die der Plan auch rechnet
    einbau = plan.get("einbau", {})
    praefixe = {}
    for name in plan["stufen"]:
        for ohne in (False, True):
            for a in bw["auftraege"](plan, name, os.path.join(HIER, "_pruefung", name), ohne):
                praefixe.setdefault(name, set()).add(a["praefix"])
    for art, (schluessel, _, _) in eb["NEUE_ARTEN"].items():
        if schluessel not in einbau:
            F("einbau.%s fehlt (Art %s)" % (schluessel, art))
            continue
        for id_, rel in einbau[schluessel].items():
            teile = rel.split("/")
            if len(teile) == 3 and teile[0] == "bildwerk":
                if teile[1] not in praefixe or teile[2] not in praefixe[teile[1]]:
                    F("einbau.%s.%s: %s rechnet der Plan nicht" % (schluessel, id_, rel))
            if art == "gegenstaende" and not (id_.isdigit() and 0 <= int(id_) < 36):
                F("einbau.gegenstaende: Feld %s ist keine Zahl von 0 bis 35" % id_)
    for name in ("texturen", "hueter"):
        for id_, rel in einbau.get(name, {}).items():
            teile = rel.split("/")
            if len(teile) == 3 and teile[0] == "bildwerk" and teile[1] in praefixe and teile[2] not in praefixe[teile[1]]:
                F("einbau.%s.%s: %s rechnet der Plan nicht" % (name, id_, rel))

    # ---- Bericht
    print("Plan %s: %d Stile, %d Stufen, %d Motive; neue Stufen zusammen %d Bilder." % (v, len(plan["stile"]), len(plan["stufen"]), len(plan["motive"]), neue_bilder))
    if tabelle:
        print("\n%-12s %6s %14s %14s %8s %12s %7s" % ("Nacht", "Bilder", "Dauer", "ohne Kacheln", "Reserve", "Reserve-Zeit", "Rahmen"))
        for nacht, n, sek, sek0, nr, sekr, std in tabelle:
            print("%-12s %6d %14s %14s %8d %12s %6.1fh" % (nacht, n, bw["dauer"](sek), bw["dauer"](sek0), nr, bw["dauer"](sekr), std))
    for t in hinweise:
        print("HINWEIS", t)
    for t in fehler:
        print("FEHLER ", t)
    print("\n%s: %d Fehler, %d Hinweise" % ("GRUEN" if not fehler else "ROT", len(fehler), len(hinweise)))
    return 1 if fehler else 0


if __name__ == "__main__":
    sys.exit(main())
