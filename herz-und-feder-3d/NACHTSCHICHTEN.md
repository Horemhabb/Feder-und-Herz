# Nachtschichten für ComfyUI

Stand 26.11.2026, Bildwerk 5.4.0. Was der PC in den nächsten Nächten rechnet, und was du abends und morgens tust. Hintergrund und Regeln: `BILDWERK.md`.

**Reihenfolge:** erst Nacht 0 (knapp eine Stunde, Proben). Die Tafeln schickst du Claude. Erst wenn Claude „trägt“ sagt, laufen die großen Nächte, zuerst die Szenen.

| Nacht | Zweck | Bilder | Dauer | Am nächsten Tag |
|---|---|---|---|---|
| 0 Proben | Bleiben Hauptfigur, Laterne und Nebet erkennbar? Tragen die neuen Stile? | 21 | knapp 1 h | Tafeln schicken, Claude entscheidet |
| 1 Szenen | alle 26 Bilder der Zwischensequenzen, Porträts von Nebet, Haremhab und dem Ba, gemalter Grund für Menü, Karte und Papyrus | 134 | 6 h 15 (Reserve bis 7 h 30) | Szenen und Oberfläche **sofort im Spiel** |
| 2 Dinge | alle 36 Gegenstände der Tasche ägyptisch, Zeichen der Champions, Flächen für Truhen und Särge | 156 | 6 h 20 | Gegenstände **sofort im Spiel** |
| 3 Welt | eigene Wände und Böden für die Stunden 6 bis 12, zweite Wandart, neuer Sand, Wasser | 78 | 4 h (nahtlos 6 h 50) + Reserve | Sand sofort, Rest braucht Code |
| 4 Boden und Wand | Risse, Sand, Blut, Scherben auf dem Boden; Reliefs, Tore, Teppiche, Säulen | 108 | 5 h 30 + Reserve | braucht Code |
| 5 Erzählung | Titelbild, Hüter 9 bis 12, ein Bild je Stunde, Lexikon | 110 | 4 h 40 + Reserve | Titel sofort, Hüter fast sofort |

Jede Nacht hört nach 7 Stunden 30 auf, neue Reserve-Bilder zu beginnen (Reserve sind u. a. die Fellmuster der Tiere). Fertige Bilder werden nie doppelt gerechnet: Bricht eine Nacht ab, startest du sie einfach noch einmal.

## Einmal vorher: die neuen Dateien holen

Claude nennt dir den Stand (eine lange Buchstabenfolge). Setze ihn überall für `<STAND>` ein. In **PowerShell**, Zeile für Zeile:

```
cd C:\CF
```
```
curl.exe -L -o bildwerk.bat https://raw.githubusercontent.com/Horemhabb/Feder-und-Herz/<STAND>/herz-und-feder-3d/tools/bildwerk/bildwerk.bat
```
```
curl.exe -L -o bildwerk_plan.json https://raw.githubusercontent.com/Horemhabb/Feder-und-Herz/<STAND>/herz-und-feder-3d/tools/bildwerk/bildwerk_plan.json
```
```
curl.exe -L -o einbauen.bat https://raw.githubusercontent.com/Horemhabb/Feder-und-Herz/<STAND>/herz-und-feder-3d/tools/bildwerk/einbauen.bat
```
Prüfen, ob alle drei passen (es müssen **drei** Zeilen mit `5.4.0` erscheinen):
```
Select-String -Path .\bildwerk.bat, .\einbauen.bat, .\bildwerk_plan.json -Pattern '"5.4.0"'
```
Erscheinen weniger als drei Zeilen: die fehlende Datei noch einmal laden. Wichtig: immer zuerst `cd C:\CF`, sonst landet die Datei im falschen Ordner.

## Freiwillig: nahtlose Texturen

Alle Nächte laufen **auch ohne** diesen Schritt; dann rechnen die Flächen gewöhnlich, und `einbauen.bat` glättet die Naht hinterher. Mit dem Schritt werden Böden und Wände von Anfang an nahtlos (und können keine schräge Perspektive mehr haben).

Es ist eine **fremde Erweiterung** für ComfyUI („Seamless Latent Tiling“ von mikemojen, Lizenz Apache 2.0). Claude hat genau den Stand `b4cba00b22817ab0ac48ba0d4af7eb1a325c4602` (10.03.2026) gelesen: drei Dateien, zusammen etwa 520 Zeilen. Sie braucht nur `torch` und `math`, die ComfyUI ohnehin hat. Sie greift weder aufs Netz noch auf Dateien zu und startet keine Programme. Sie legt beim Rechnen nur den Bildrand ringsum an die Gegenseite. `bildwerk.bat` lädt genau diese drei Dateien und vergleicht jede mit ihrer hinterlegten Prüfsumme (SHA-256). Weicht eine ab, richtet es nichts ein.

Wenn du es willst (ComfyUI muss dafür nicht laufen):
```
cd C:\CF
```
```
.\bildwerk.bat kachel_einrichten
```
Danach das schwarze Fenster von ComfyUI schließen und ComfyUI wie gewohnt neu starten (`.\start.bat`), warten bis dort „To see the GUI“ steht.

Wenn nicht: Fragt eine Nacht nach dem „Knoten SeamlessLatentTiling“, einfach Enter drücken (das heißt: ohne Kacheln rechnen). Oder die Nacht gleich so starten: `.\bildwerk.bat nacht 3 --ohne-kachel`.

## Nacht 0: Proben

```
cd C:\CF
```
```
.\bildwerk.bat nacht 0
```
Rückfragen: Falls „im Ordner liegen schon Bilder“ kommt, Enter (Fehlende nachholen). Falls „es fehlt der Knoten SeamlessLatentTiling“ kommt, Enter (ohne Kacheln).

Morgens: Am Ende steht im Fenster eine Liste „Tafeln (diese Bilder an Claude schicken)“, dieselbe Liste liegt in `C:\CF\ComfyUI\output\bildwerk\zusammenfassung_proben_<datum>.txt`. Diese Tafeln schickst du Claude.

**Was Nacht 0 klärt:**
- `probe_szene`: Die Hauptfigur mit ihrer Laterne am Tor und im Fieberhaus neben Nebet. Ist es eine alte Bronzelaterne (keine moderne Sturmlaterne)? Sind Nebets blaue Finger zu sehen?
- `probe_lichter`: Seelenlichter auf reinem Schwarz (eine Ebene, die das Spiel über das Torbild legt).
- `probe_zier`: dunkler Grund aus Lapislazuli für die Fenster der Oberfläche.
- `probe_kachel` gegen `probe_flaeche`: Flächen mit und ohne nahtloses Rechnen (nur, wenn du den freiwilligen Schritt gemacht hast).
- `probe_ding`, `probe_abzieh`: Dinge und Flecken auf grauem Grund, freistellbar?
- `probe_frei`: ein Champion-Zeichen im Symbolstil ohne fremde Spielnamen.
- `probe_relief`, `probe_ansicht`, `probe_buchbild`: Wandrelief, Tor, Malerei auf Papyrus (ohne Schrift?).

## Nacht 1: Szenen

```
cd C:\CF
```
```
.\bildwerk.bat nacht 1 --trocken
```
(zeigt nur, was kommt: 134 Bilder, etwa 6 h 15). Dann starten:
```
.\bildwerk.bat nacht 1
```
Morgens die Tafeln aus der Zusammenfassung schicken (Szenen, Porträts, Oberfläche). Claude trägt die Auswahl ein und nennt dir einen neuen `<STAND>`. Dann:
```
cd C:\CF
```
```
curl.exe -L -o bildwerk_plan.json https://raw.githubusercontent.com/Horemhabb/Feder-und-Herz/<STAND>/herz-und-feder-3d/tools/bildwerk/bildwerk_plan.json
```
```
.\einbauen.bat szenen
```
```
.\einbauen.bat zier
```
```
.\einbauen.bat portraets
```
Beim letzten fragt es „Jetzt gleich mit sync.bat hochladen?“: `j` und Enter. Die Szenenbilder und die gemalte Oberfläche erscheinen dann ohne Code im Spiel (Menü „Erinnerungen“ zeigt alle Sequenzen).

## Nächte 2 bis 5

Wie Nacht 1, nur mit anderer Zahl:
```
cd C:\CF
```
```
.\bildwerk.bat nacht 2
```
Golden umrandet ist auf den Tafeln die Variante, die nach den Messwerten am besten ist; das ist nur ein Vorschlag. Danach nennt dir Claude die Einbau-Befehle (z. B. `.\einbauen.bat gegenstaende`, `.\einbauen.bat titel`, `.\einbauen.bat hueter`).

Nur nachsehen, ohne etwas zu schreiben:
```
.\einbauen.bat pruefen
```

## Schon heute möglich (ohne ComfyUI)

Die Texturen der Stunden 6 bis 12 aus Stufe 4 sind gerechnet, aber nie gemessen worden. Das baut ihre Tafeln neu, 2 × 2 gekachelt und mit Messwerten:
```
cd C:\CF
```
```
.\bildwerk.bat tafeln texturen_stunden
```
Die Tafeln liegen in `C:\CF\ComfyUI\output\bildwerk\texturen_stunden\`. Schick sie Claude.

## Wenn etwas schiefgeht

| Was du siehst | Was du tust |
|---|---|
| „Skript und Plan passen nicht zusammen“ | Beide Dateien neu laden (mit `<STAND>`, nicht mit `main`), dann die Prüfzeile |
| „ComfyUI läuft nicht“ | `.\start.bat` starten, warten bis „To see the GUI“ steht, Befehl wiederholen |
| „es fehlt der Knoten SeamlessLatentTiling“ | Enter (ohne Kacheln). Nur wenn du die Erweiterung willst: `E`, ComfyUI neu starten, Befehl wiederholen |
| „ABBRUCH: … nicht die erwartete Prüfsumme“ | Nichts tun, nichts ist eingerichtet. Claude Bescheid geben; die Nächte laufen mit `--ohne-kachel` |
| „3 Bilder hintereinander fehlgeschlagen“ gleich am Anfang einer nahtlosen Stufe | Die Erweiterung verträgt sich nicht. Nacht mit `--ohne-kachel` neu starten, Claude Bescheid geben |
| ComfyUI stürzt ab | Das Skript startet es bis zu dreimal selbst neu. Danach: Befehl wiederholen, Fertiges wird übersprungen |
| Fenster steht still | Jemand hat hineingeklickt: `Esc` drücken |
| Abbrechen | `Strg+C`. Später denselben Befehl wieder starten |
| Keine Tafeln | `.\bildwerk.bat tafeln <stufe>` baut sie aus den fertigen Bildern neu |

## Einbau im Spiel, offen (für Claude)

Ohne Code: Szenenbilder (`ui/szenen/<name>.webp`, Namen wie `scripts/szenen.gd`, alle 26 geprüft), gemalte Oberfläche (`ui/zier/gemalt/<name>.webp`, `Zier.tex`), Gegenstände (`ui/icons.webp`, `Daten.icon` teilt den Bogen selbst), Titel (`ui/titel.webp`), Sand (`textures/t09_sand.jpg`). Alles andere braucht Code:

1. **Porträts P25 Nebet, P26 Haremhab, P27 Ba** (`ui/portraits/P25.webp` …): in `scripts/szenen.gd` bei den Einstellungen mit Nebet, Haremhab und dem Vogel im Feld `ersatz` vorn `"portrait:P25"` usw. ergänzen; wo die beiden sprechen (Gespräche in `geschichte.gd`/`hud.gd › bild`), das Kürzel setzen.
2. **Fellmuster der Tiere** (`bilder/lebewesen/<name>.webp`): `python3 tools/figurenfabrik/kleintiere_tafel.py`, dann Godot-Import; `eidechse_dornen` und `falke_brust` sind in `FELD_MUSTER` noch keinem Feld zugeordnet (Agent C).
3. **Hüter 9 bis 12** (`ui/hueter/h09`–`h12.webp`): `stunden.gd › OPEN` bei „Die Ruderer“, „Die Ertrunkenen im Nun“, „Die Feuergruben“, „Das Tor des Ostens“ je `"bild": "h09"` … `"h12"`.
4. **Oberflächen der Stunden 6 bis 12** (`textures/w06_osiris.jpg` … `t12_osten.jpg`, mit `_n`): `main.gd › SURF` je Datei ein Eintrag; `welt.gd › LOOK` nach der Stunde wählen. Helligkeit ist schon gedämpft (`texturen_hell` 0,24).
5. **Zweite Wandart** (`w01_sandstein_b` …): `welt.gd`, je Mauerabschnitt (`FELD`) zwischen `look.wall` und einer zweiten `SURF`-Oberfläche wechseln.
6. **Kies und Lehmboden** (`t13_kies`, `t14_lehmboden`): `SURF["sand_aussen"]` auf `t13_kies`, `t14_lehmboden` als Raumboden der Felder.
7. **Wasser** (`x01_nil`, `x02_nun`): `deko.gd › becken`, Stunde 10.
8. **Requisiten** (`r01_holz_bemalt` … `r07_matte`): `deko.gd › tex_mat` in `truhe()`, `sarkophag()`, `requisit()`.
9. **Champion-Zeichen** (`ui/affixe/<id>.webp`): `hud.gd › _affix_zeichnen`, Bild statt Form, wenn vorhanden.
10. **Abziehbilder** (`textures/abzieh/<id>.webp`, RGBA): flache Vierecke knapp über dem Boden in `welt.gd` (keine Decal-Knoten in GL Compatibility), je Stunde eine Auswahl.
11. **Wandbilder** (`textures/wand/<id>.jpg` und `_n`): Vierecke auf langen Raummauern.
12. **Tore** (`textures/tor/<id>.jpg` und `_n`): `deko.gd › pforte`.
13. **Teppiche** (`textures/k01_lotos.jpg` …): `welt.gd › _rug_bild`, Bild als Innenfläche.
14. **Säulen** (`textures/saeule/<id>.jpg`): `deko.gd › stumpf`.
15. **Ladebilder** (`ui/laden/lade01` … `lade12.webp`): `Stunden.lade_bild(n)` wie `akt_bild`, bei `hud.show_chapter` in `main.gd`.
16. **Lexikon** (`ui/lexikon/lx_<id>.webp`, `<id>` wie `lexikon.gd › W`): Lexikon-Seite im Menü.
17. **Bodenzeichen** (Stufe 15, `ui/zeichen/`), **Effektbilder** (Stufe 16, `textures/fx/`), **Friese** (Stufe 17, `textures/fries/`): additiv auf dem Arenaboden, als Teilchen-Textur, als Band an den Grabmauern.

Die drei alten „Enden“ (Stufe `enden` aus dem ersten Entwurf) sind gestrichen: Die neue Geschichte hat eigene Schlussbilder (`sz_finale_leicht`, `sz_finale_schwebe`, `sz_finale_schwer`).
