# Ausgaben bei ElevenLabs (Fassung 4.3, Ton)

Freigegeben: **10.000 Credits** für beide Durchgänge (erster Durchgang höchstens 6.500, der Rest für die
Sprechzeilen der Geschichte).

**Kontostand:** Der Connector verweigert `account_get_usage` („requires additional permissions … reconnect it“).
Anfangs- und Endstand sind darum unbekannt. Gezählt wird hier nach den Preisen, die ElevenLabs für jede einzelne
Erzeugung meldet (`price.credits` im Ergebnis von `creative_get_flow_run_status`). Bitte den echten Stand einmal im
Konto nachsehen (elevenlabs.io → Abrechnung) und hier eintragen.

**Preise, gemessen:** Geräusche (Sound Effects v3) kosten **3,33 Credits je Sekunde und Fassung**; die Schätzung
(`estimate_only`) nennt das Dreifache (10 je Sekunde) – sie liegt zu hoch. Sprache (Eleven v3) kostet 1 Credit je
Zeichen und Fassung (Regie-Tags und Pausenzeichen zählen mit).

Ab vier gleichzeitigen Fassungen je Knoten lehnt ElevenLabs die vierte ab (zu viele Erzeugungen in der Warteschlange,
nicht berechnet). Darum hat jeder Geräuschknoten höchstens drei Fassungen. Keine Erzeugung wurde wiederholt.

## Erster Durchgang (Musik-Instrumente, Geräusche, Stimmproben)

| Block | Was | Modell | Fassungen | Credits | Dateien (tools/ton/roh/…) |
|---|---|---|---|---|---|
| 0 | Probe: Oud-Ton | Sound Effects v3 | 4 × 3 s | 40 | instr/oud_1–4 |
| 1 | 16 Instrumente (Ney, Harfe, Rahmentrommel tief/Rand, Darbuka Dum/Tek, Sistrum, Mizmar, Chor, Zimbeln, Tempeltrommel, Rebab, Glocke, Arghul, Qanun, Frauenstimme) | Sound Effects v3 | je 3 | 504 | instr/… |
| 2 | Kampf: Hieb, Klinge, Faust, Faustschlag, Armbrust, Bolzen, Sternfunke, Sterntreffer, Meteor, Windstoß, Scherben, Körperfall, Schmerz m/w, Tod w | Sound Effects v3 | je 3 | 142 | kampf/… |
| 3 | Gegner (Krieger, Priesterin, Koloss, Erloschene, Hohle: Erwachen und Tod) und Hüter (Ansage, Schlag) | Sound Effects v3 | je 2 | 119 | gegner/… |
| 4 | Eigenschaften der Champions (Auftritt, Ruf, Sprung, Klage, Fessel, Feder, Federbruch, Spalt, Glut, Kette, Sturm) | Sound Effects v3 | je 2 | 133 | affix/… |
| 5 | Oberfläche und Welt (Knopf, Fenster auf/zu, Anlegen, Belohnung, Legendär, Stufe; Böe, Flamme, Flüstern, Gong, Knochen, Platschen, Vogel) | Sound Effects v3 | je 2 | 153 | ui/…, welt/… |
| 6 | Kulissen je Ort (Wind, Grab, Höhle, Sandbank, Nun, Feuergrube, Morgen), je etwa 20 s | Sound Effects v3 | je 1 | 467 | kulisse/… |
| 7 | Wünsche der Oberfläche: Goldknopf (metallisch), Herzschlag | Sound Effects v3 | je 2, kurz | 10 | ui/knopf_gold_*, ui/herzschlag_* |
| 8 | Stimmproben, erste Runde (Nils Parler, Samuel Storm, Leander, Brako, Moreana, Piero, Mona) | Eleven v3 | je 2 | 684 | stimme/… |
| 9 | Stimmproben, zweite Runde (Nils mit Regie, Leander, Brako) | Eleven v3 | je 2 | 982 | stimme/… |
| | **Summe erster Durchgang** | | | **3.234** | |

## Zweiter Durchgang (Sprechzeilen der Geschichte, `sprechzeilen.json` von Agent D)

Eine Erzeugung je Sprecher und Szene, eine einzige Fassung (`generations_count` 1, bewusst, für das Budget), die
Zeilen darin mit `[long pause]` getrennt; `sprechen.py schneiden` zerlegt sie wieder. Gruppen desselben Sprechers
wurden teils zu einer Erzeugung zusammengelegt (Namen `c…`).

| Datei (roh/sprech/) | Gruppen (sprechplan) | Sprecher | Credits |
|---|---|---|---|
| g01–g08, g10–g14 | 1–8, 10–14 (Prio 1: Auftakt, Stunden 1–5, Akt 1, Mitte) | verschieden | 2.703 |
| g15 | 15 | Nebet (Jule) | 239 |
| g16 | 16 | Erzähler | 380 |
| g17 | 17 | Haremhab (Joerg) | 40 |
| g18 | 18 | Erzähler | 191 |
| g19 | 19 | Thot (Leander) | 418 |
| c20 | 20, 22, 24, 26, 28, 30 | Erzähler | 759 |
| c21 | 21, 23, 25, 29, 31, 37 | Nebet als Ba (Jule) | 493 |
| c27 | 27, 40 | Haremhab | 229 |
| c32 | 32–35 (Epiloge 1–4) | Erzähler | 742 |
| c36 | 36 | Der Sammler (M. Danisch) | 206 |
| c38 | 38, 39, 41 | Erzähler | 475 |
| | **Summe zweiter Durchgang** | | **6.875** |

Gruppe 9 (vo_sz_akt1_02, „Wie heißt du?“ des Türhüters) ist derselbe Text wie Gruppe 7 und nutzt deren Aufnahme
(keine eigene Erzeugung).

## Gesamt

**3.234 + 6.875 = 10.109 Credits**, also **109 über** den freigegebenen 10.000 (gut 1 %). Ursache: Die Planung zählte
nur die Zeichen der Texte (6.643); die Regie-Tags in eckigen Klammern und die Pausenzeichen zwischen den Zeilen
werden mitberechnet. Weitere Erzeugungen gab es danach nicht.

Nicht vertont (Budget erschöpft, 39 von 120 Zeilen): siehe `HOERPROBEN.md`, Abschnitt „Was fehlt“.
