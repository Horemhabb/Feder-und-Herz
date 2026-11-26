# Wunschliste für ComfyUI: Musterkacheln für Tiere (Fassung 4.3)

Die Kleintiere und Vögel teilen eine gemalte Farbtafel: `models/tiere/tiere_tafel.webp` (1024 × 1024, rund 60 KB).
Sie wird von `tools/figurenfabrik/kleintiere_tafel.py` gerechnet: Grundfarben und Zeichnung (Bänder, Flecken,
Federreihen) als Formel, darüber ein feines Korn (Schuppen, Haare, Federn).

**Wie ein Bild aus der Nacht hineinkommt:** Liegt unter `bilder/lebewesen/<name>.webp` (oder `.png`) eine Kachel mit
dem Namen aus der Tabelle, nimmt das Skript ihre Helligkeit als Korn für dieses Feld. Die Zeichnung (wo die Bänder
liegen, wo der Bauch hell ist) bleibt; die Oberfläche kommt aus dem Bild. Fehlt die Datei, bleibt die Formel. Danach
einmal `python3 tools/figurenfabrik/kleintiere_tafel.py` und den Import laufen lassen (Claude macht das).
Die Zuordnung Feld → Kachel steht in `kleintiere_tafel.py › FELD_MUSTER` (die Eidechse liest `eidechse_schuppen` beim
Malen). `eidechse_dornen` und `falke_brust` sind vorgemerkt, aber noch keinem Feld zugeordnet.

Regeln aus `BILDWERK.md`: keine Ziffern, Licht nur als Farbe, das Tier bzw. den Stoff zuerst nennen, dunkler oder
neutraler Grund. Gewünscht sind **flache Musterkacheln**, gerade von oben, ohne Tier-Umriss, ohne Schatten, nahtlos
kachelbar. 1024 × 1024 genügt (wird verkleinert).

| Name (Datei) | Zweck | Größe | Prompt (englisch) |
|---|---|---|---|
| `eidechse_schuppen` | Rücken der Dornschwanzagame | 1024² | `seamless texture of reptile skin, small round granular scales of a desert spiny-tailed lizard, olive brown and ochre, flat top view, even soft warm light colour, no shadows, painted, fine detail` |
| `eidechse_dornen` | Schwanzringe (Dornenwirtel) | 1024² | `seamless texture of reptile tail, rows of spiny keeled scales in rings, grey brown and dark umber, flat side view, even soft light colour, painted` |
| `kaefer_panzer` | Flügeldecken des Skarabäus | 1024² | `seamless texture of black beetle wing case, fine parallel grooves, glossy black with faint blue green sheen, flat top view, dark neutral ground, painted` |
| `schwarzkaefer_panzer` | Schwarzkäfer in Gräbern | 1024² | `seamless texture of matte black beetle shell covered in small round bumps, desert darkling beetle, flat top view, painted` |
| `maus_fell` | Rücken der Rennmaus | 1024² | `seamless texture of short sandy orange fur of a desert gerbil, soft fine hairs, flat top view, even warm light colour, painted` |
| `falke_gefieder` | Oberseite des Falken (Flügel, Rücken) | 1024² | `seamless texture of falcon back feathers, slate grey and brown with darker bars and pale edges, overlapping rows, flat top view, painted in the style of an egyptian tomb painting` |
| `falke_brust` | Brust des sitzenden Falken | 1024² | `seamless texture of pale cream bird breast feathers with small dark brown drop shaped spots, flat, painted` |
| `ibis_gefieder` | weißes Gefieder des Ibis | 1024² | `seamless texture of white ibis feathers, soft overlapping layers, faint warm grey shading, flat top view, painted` |
| `fisch_schuppen` | Nilbuntbarsch | 1024² | `seamless texture of fish scales, nile tilapia, olive grey with faint vertical bars and a pale belly tint, flat side view, painted` |
| `esel_fell` | Esel, Rumpf | 1024² | `seamless texture of short grey donkey hair, slight brownish tint, flat, even soft light colour, painted` |
| `schaf_vlies` | Schaf | 1024² | `seamless texture of curly cream coloured sheep wool, small tight locks, flat top view, painted` |
| `ziege_fell` | Ziege | 1024² | `seamless texture of dark brown goat hair, long straight strands, flat, painted` |
| `katze_fell` | Katze der Grabbilder | 1024² | `seamless texture of sandy tabby cat fur with faint darker stripes, egyptian cat, flat top view, painted` |

Vorschlag für die Stufe im Plan (Agent E entscheidet über `bildwerk_plan.json`): Stil wie `texturen`, je Motiv vier
Seeds, rund 50 Bilder, etwa zweieinhalb Stunden. Auswahl: die ruhigste Kachel, ohne große helle oder dunkle Flecken.
