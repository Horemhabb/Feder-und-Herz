# Nachtschichten für ComfyUI

Stand 26.11.2026, Bildwerk 5.3.0. Was der PC in den nächsten Nächten rechnet, und was du abends und morgens tust. Hintergrund und Regeln: `BILDWERK.md`.

**Reihenfolge:** erst Nacht 0 (unter einer Stunde, Proben). Die Tafeln schickst du Claude. Erst wenn Claude „trägt“ sagt, laufen die großen Nächte 1 bis 4.

| Nacht | Zweck | Bilder | Dauer | Am nächsten Tag |
|---|---|---|---|---|
| 0 Proben | Tragen die neuen Stile? Läuft das nahtlose Rechnen auf deiner Karte? | 19 | knapp 1 h | Tafeln schicken, Claude entscheidet |
| 1 Dinge | alle 36 Gegenstände der Tasche ägyptisch, Zeichen der Champions, Flächen für Truhen und Särge | 156 | 6 h 20 (Rest bis 7 h 30 füllt Reserve) | Gegenstände **sofort im Spiel** |
| 2 Welt | eigene Wände und Böden für die Stunden 6 bis 12, zweite Wandart, neuer Sand, Wasser | 78 | 6 h 50 (nahtlos) | Sand sofort, Rest braucht Code |
| 3 Boden und Wand | Risse, Sand, Blut, Scherben auf dem Boden; Reliefs, Tore, Teppiche, Säulen | 108 | 5 h 30 + Reserve | braucht Code |
| 4 Erzählung | Titelbild, Hüter 9 bis 12, ein Bild je Stunde, drei Enden, Lexikon | 119 | 5 h + Reserve | Titel sofort, Hüter fast sofort |

Jede Nacht hört nach 7 Stunden 30 auf, neue Reserve-Bilder zu beginnen. Fertige Bilder werden nie doppelt gerechnet: Bricht eine Nacht ab, startest du sie einfach noch einmal.

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
Prüfen, ob alle drei passen (es müssen **drei** Zeilen mit `5.3.0` erscheinen):
```
Select-String -Path .\bildwerk.bat, .\einbauen.bat, .\bildwerk_plan.json -Pattern '"5.3.0"'
```
Erscheinen weniger als drei Zeilen: die fehlende Datei noch einmal laden. Wichtig: immer zuerst `cd C:\CF`, sonst landet die Datei im falschen Ordner.

## Einmal vorher: nahtlose Texturen einrichten (für Nacht 0 und 2)

ComfyUI muss dafür nicht laufen.
```
cd C:\CF
```
```
.\bildwerk.bat kachel_einrichten
```
Danach das schwarze Fenster von ComfyUI schließen und ComfyUI wie gewohnt neu starten (`.\start.bat`), warten bis dort „To see the GUI“ steht.

## Nacht 0: Proben

```
cd C:\CF
```
```
.\bildwerk.bat nacht 0
```
Rückfragen: Falls „im Ordner liegen schon Bilder“ kommt, einfach Enter (Fehlende nachholen). Falls „es fehlt der Knoten SeamlessLatentTiling“ kommt: `E` tippen und Enter, dann ComfyUI neu starten und denselben Befehl noch einmal.

Morgens: Am Ende steht im Fenster eine Liste „Tafeln (diese Bilder an Claude schicken)“, dieselbe Liste liegt in `C:\CF\ComfyUI\output\bildwerk\zusammenfassung_proben_<datum>.txt`. Diese Tafeln schickst du Claude.

**Was Nacht 0 klärt:**
- `probe_kachel` gegen `probe_flaeche`: dieselben drei Flächen mit und ohne nahtloses Rechnen. Läuft es überhaupt, und ist es besser?
- `probe_ding`, `probe_abzieh`: Dinge und Flecken auf grauem Grund, freistellbar?
- `probe_frei`: das Symbol einer Champion-Eigenschaft im bewährten Stil und im neuen ohne fremde Spielnamen.
- `probe_relief`, `probe_ansicht`, `probe_buchbild`: Wandrelief, Tor, Malerei auf Papyrus (ohne Schrift?).

## Nächte 1 bis 4

Abends (Beispiel Nacht 1; für die anderen die Zahl tauschen):
```
cd C:\CF
```
```
.\bildwerk.bat nacht 1
```
Erst ansehen, was kommt (rechnet nichts):
```
.\bildwerk.bat nacht 1 --trocken
```
Hat das nahtlose Rechnen in Nacht 0 nicht getragen, sagt Claude dir, die Nacht so zu starten:
```
.\bildwerk.bat nacht 2 --ohne-kachel
```
Morgens: die Tafeln aus der Zusammenfassung schicken. Golden umrandet ist die Variante, die nach den Messwerten am besten ist; das ist nur ein Vorschlag.

**Danach einbauen** (Claude trägt die Auswahl in den Plan ein und nennt dir den neuen `<STAND>`; nur `bildwerk_plan.json` neu laden):
```
cd C:\CF
```
```
curl.exe -L -o bildwerk_plan.json https://raw.githubusercontent.com/Horemhabb/Feder-und-Herz/<STAND>/herz-und-feder-3d/tools/bildwerk/bildwerk_plan.json
```
```
.\einbauen.bat gegenstaende
```
Claude nennt dir die Art (`gegenstaende`, `titel`, `hueter`, `texturen t09_sand` …). Am Ende fragt es „Jetzt gleich mit sync.bat hochladen?“: `j` und Enter.

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
Die Tafeln liegen in `C:\CF\ComfyUI\output\bildwerk\texturen_stunden\`. Schick sie Claude: Vielleicht ist ein Teil davon schon brauchbar.

## Wenn etwas schiefgeht

| Was du siehst | Was du tust |
|---|---|
| „Skript und Plan passen nicht zusammen“ | Beide Dateien neu laden (mit `<STAND>`, nicht mit `main`), dann die Prüfzeile |
| „ComfyUI läuft nicht“ | `.\start.bat` starten, warten bis „To see the GUI“ steht, Befehl wiederholen |
| „es fehlt der Knoten SeamlessLatentTiling“ | `E`, ComfyUI neu starten, Befehl wiederholen. Klappt es nicht: `O` (ohne Kacheln rechnen) |
| „3 Bilder hintereinander fehlgeschlagen“ gleich am Anfang einer nahtlosen Stufe | Die Erweiterung verträgt sich nicht. Nacht mit `--ohne-kachel` neu starten, Claude Bescheid geben |
| ComfyUI stürzt ab | Das Skript startet es bis zu dreimal selbst neu. Danach: Befehl einfach wiederholen, Fertiges wird übersprungen |
| Fenster steht still | Jemand hat hineingeklickt: `Esc` drücken |
| Abbrechen | `Strg+C`. Später denselben Befehl wieder starten |
| Keine Tafeln | `.\bildwerk.bat tafeln <stufe>` baut sie aus den fertigen Bildern neu |

## Einbau im Spiel, offen (für Claude)

Was ohne Code geht: Gegenstände (`ui/icons.webp`, `Daten.icon` teilt den Bogen selbst, jede Größe), Titel (`ui/titel.webp`), Sand (`textures/t09_sand.jpg`). Alles andere braucht Code an diesen Stellen:

1. **Hüter 9 bis 12** (`ui/hueter/h09`–`h12.webp`): `stunden.gd › OPEN`, bei „Die Ruderer“, „Die Ertrunkenen im Nun“, „Die Feuergruben“, „Das Tor des Ostens“ je `"bild": "h09"` … `"h12"` ergänzen; `hueter_bild()` lädt sie dann.
2. **Oberflächen der Stunden 6 bis 12** (`textures/w06_osiris.jpg` … `t12_osten.jpg`, mit `_n`): `main.gd › SURF` je Datei ein Eintrag (Tönung `Color.WHITE`, Ersatz die heutige Fläche der Stunde); `welt.gd › LOOK` nach der Stunde statt nur nach `k.kind` wählen (z. B. `LOOK_STUNDE[Stunden.hour_of(Spiel.fall)]`, sonst wie bisher). Helligkeit ist schon gedämpft (`texturen_hell` 0,24): kein `HELL`-Eintrag nötig.
3. **Zweite Wandart** (`w01_sandstein_b`, `w03_lehm_b`, `w04_grab_b`, `w05_hoehle_b`, `w02_glas_b`): in `welt.gd`, wo Mauern je Abschnitt (`FELD`) zusammengefasst werden, per Zufall des Abschnitts zwischen `look.wall` und einer zweiten `SURF`-Oberfläche wechseln (`cut_mat(name_b)`).
4. **Kies und Lehmboden** (`t13_kies`, `t14_lehmboden`): `SURF["sand_aussen"]` auf `t13_kies`, `t14_lehmboden` als Raumboden der Felder (Stunde 2).
5. **Wasser** (`x01_nil`, `x02_nun`): `deko.gd › becken` als Albedo mit langsam laufender UV; Stunde 10. Decke und Himmel (`x03_decke`, `x04_himmel`): wenig Nutzen bei der Sicht von oben, nur wenn eine Gruft eine Decke zeigt.
6. **Requisiten** (`r01_holz_bemalt` … `r07_matte`): `deko.gd › tex_mat(key, datei)` in `truhe()`, `sarkophag()`, `requisit()` (Kisten, Korb, Statuen in Blattgold).
7. **Champion-Zeichen** (`ui/affixe/<id>.webp`, 256 px, Ids wie `Affixe.LISTE`): `hud.gd › _affix_zeichnen(c, id)`: wenn die Datei da ist, `draw_texture_rect` statt der gezeichneten Form.
8. **Abziehbilder** (`textures/abzieh/<id>.webp`, RGBA 512 px): neue Funktion in `welt.gd` nach `_rugs()`: flache `QuadMesh` (1 bis 3 m) knapp über dem Boden (y = 0,02), `StandardMaterial3D` mit `TRANSPARENCY_ALPHA`, zufällig gedreht; je Stunde eine Auswahl (draußen Sand und Risse, Gräber Scherben und Knochen, Feuergruben Glut und Ruß, Nun Algen und Pfützen). Ein Material je Bild, `MultiMeshInstance3D` für die Webfassung. GL Compatibility hat keine `Decal`-Knoten.
9. **Wandbilder** (`textures/wand/<id>.jpg` und `_n`, 1024 × 768): in `welt.gd` auf langen geraden Raummauern ein Viereck knapp vor der Wand, Tönung wie die Mauer.
10. **Tore** (`textures/tor/<id>.jpg` und `_n`, 768 × 1024): `deko.gd › pforte` für die Türflügel, Grabeingänge.
11. **Teppiche** (`textures/k01_lotos.jpg` …): `welt.gd › _rug_bild` malt heute das Muster selbst; das Bild als Innenfläche nehmen, die goldene Borte bleibt.
12. **Säulen** (`textures/saeule/<id>.jpg` und `_n`, waagrecht kachelbar): `deko.gd › stumpf` (Säulenstümpfe) als Mantel.
13. **Ladebilder** (`ui/laden/lade01` … `lade12.webp`, 1280 × 720): `Stunden.lade_bild(n)` wie `akt_bild`; in `main.gd` bei `hud.show_chapter(...)` (Zeile um 183) als Bild übergeben, wenn kein Aktbild dran ist.
14. **Enden** (`ui/enden/ende_leicht|ende_schwer|ende_schwebe.webp`): beim Schluss der Nacht nach `Geschichte.urteil_art()` als Hintergrund wie `akt_bild`.
15. **Lexikon** (`ui/lexikon/lx_<id>.webp`, 800 × 600, `<id>` = Id aus `lexikon.gd › W`, z. B. `lx_duat`, `lx_krug`, `lx_geb`): auf der Lexikon-Seite im Menü (`hud.gd`) neben dem Text, wenn die Datei da ist.
16. **Bodenzeichen** (Stufe 15, `ui/zeichen/z1` … `z8.webp`, RGB auf Schwarz): Viereck auf dem Arenaboden, `BLEND_MODE_ADD`, unbeleuchtet, langsam drehend.
17. **Effektbilder** (Stufe 16, `textures/fx/e1` … `e6.webp`): `affixe.gd › _funken` und Trefferfunken: Material mit Textur, Billboard; `add` mischt additiv, `alpha` (Rauch, Staub, Dunst) normal.
18. **Friese** (Stufe 17, `textures/fries/<id>.jpg` und `_n`, 1024 × 512, waagrecht kachelbar): Band oben an den Grabmauern, u läuft mit der Mauerlänge.
