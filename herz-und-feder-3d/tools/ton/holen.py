#!/usr/bin/env python3
# Lädt fertige Erzeugungen von ElevenLabs nach tools/ton/roh/<gruppe>/ (die Adressen stehen im Ergebnis von
# creative_get_flow_run_status und gelten nur einige Stunden). Rohdateien kommen nicht ins Spiel: der Ordner hat
# eine .gdignore, und tools/ ist vom Export ausgenommen.
# Aufruf: python3 tools/ton/holen.py <gruppe> name1=URL1 name2=URL2 …
import pathlib, sys, urllib.request

HIER = pathlib.Path(__file__).resolve().parent

def main():
    gruppe = sys.argv[1]
    ziel = HIER / "roh" / gruppe
    ziel.mkdir(parents=True, exist_ok=True)
    for arg in sys.argv[2:]:
        name, url = arg.split("=", 1)
        if not url.startswith("http"):
            # Kurzform: Sitzung/Erzeugung/Signatur/Ablauf (Arbeitsbereich und Rest der Adresse sind immer gleich)
            s, g, sig, ab = url.split("/", 3)
            url = ("https://elevenlabsusercontent.com/database/workspace/91539815c30f4ad9b5197de5a42dcc3a/content_generation/"
                   "%s/%s/content.mp3?Expires=%s&KeyName=assets-cdn-key-1&Signature=%s" % (s, g, ab, sig))
        pfad = ziel / (name + ".mp3")
        try:
            with urllib.request.urlopen(url, timeout=60) as r:
                pfad.write_bytes(r.read())
        except Exception as e:
            print(name, "FEHLER", e)
            continue
        print(pfad.relative_to(HIER), pfad.stat().st_size // 1024, "KB")

if __name__ == "__main__":
    main()
