#!/usr/bin/env python3
"""Baut herz-und-feder.html (Seite für das Artifact, ohne <html>-Gerüst) aus src/.
Aufruf:  python3 make.py            schreibt herz-und-feder.html
         python3 make.py --test P   schreibt zusätzlich eine eigenständige Testseite nach P
Die Bildliste art/manifest.json (falls vorhanden) wird als ART eingesetzt.
"""
import json, os, pathlib, re, sys

HERE = pathlib.Path(__file__).parent
page = (HERE / "src" / "page.html").read_text(encoding="utf-8")
js = "\n".join(p.read_text(encoding="utf-8").rstrip() for p in sorted((HERE / "src").glob("[0-9]*.js")))
man = pathlib.Path(os.environ.get("NM_MANIFEST", HERE / "art" / "manifest.json"))
if man.exists():
    art = json.dumps(json.loads(man.read_text(encoding="utf-8")), ensure_ascii=False, separators=(",", ":"))
    js, n = re.subn(r"/\*ART\*/.*?/\*ART\*/", lambda m: art, js, count=1, flags=re.S)
    assert n == 1
assert page.count("/*JS*/") == 1
out = page.replace("/*JS*/", js)
(HERE / "herz-und-feder.html").write_text(out, encoding="utf-8")
print("herz-und-feder.html:", len(out.encode("utf-8")) // 1024, "KB")
if "--test" in sys.argv:
    target = pathlib.Path(sys.argv[sys.argv.index("--test") + 1])
    target.write_text('<!doctype html><html lang="de"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">'
                      '<style>html{color-scheme:light}body{margin:0;font:14px system-ui}[hidden]{display:none!important}img{max-width:100%}</style></head><body>' + out + "</body></html>", encoding="utf-8")
    print("Testseite:", target)
