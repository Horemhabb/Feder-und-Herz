# Bestand des Tons (Fassung 4.3)

**Wichtig:** Hier hört niemand zu. Alle Urteile stehen auf Messwerten (`tools/ton/messen.py`) und auf Spektrogrammen,
nicht auf dem Gehör. Wo ein Messwert unauffällig ist, kann eine Datei trotzdem schlecht klingen – Höraufträge stehen
in `HOERPROBEN.md`.

Spalten: Dauer, Kanäle × Abtastrate, Größe, Lautheit (LUFS nach EBU R128; „−70“ heißt: kürzer als 0,4 s, nicht
messbar), Spitze (über 0 dB = übersteuert beim Entpacken), Zahl übersteuerter Werte, Stille vorn/hinten, spektraler
Schwerpunkt, Energieanteile in fünf Bändern, bei Schleifen die Naht (Pegelunterschied der ersten zur letzten halben
Sekunde / Sprung am Übergang im Verhältnis zur üblichen Änderung; unter 1 ist unauffällig).

## Zusammenfassung

- **Vorher:** 140 Dateien, 8,05 MB (Ogg), 8,6 MB mit `.import`.
- **Nachher:** 234 Dateien, 13,3 MB (Ogg), 15 MB mit `.import` (×1,65; Ziel war höchstens ×2).
- **Bleibt unverändert:** 53 Dateien (u. a. alle 16 Schritte, die 36 Ansagen des Erzählers bis zum zweiten
  Durchgang, Tiere, die meisten Ereignisse der Kulisse, Feuerschale, Thot, Segen …).
- **Nachbearbeitet:** 25 Dateien (übersteuerte Spitzen auf −1 dB begrenzt; vier Schleifen nahtlos überblendet;
  Fackel von Stereo auf Mono).
- **Unter altem Namen neu:** Titelmusik, `amb_grab`, `amb_hoehle`, `amb_wind`, `ui`; dazu 99 neue Dateien.
- **Gelöscht:** 17 (alte Musik von Gomo, Brummen, unbenutzte oder ersetzte Schritte, Hiebe, Schmerzlaute).

Die alte Musik bestand aus 30-Sekunden-Stücken mit Ein- und Ausblende (Naht bis +26 dB, bis 3 s Stille am Ende): das
waren keine Schleifen, darum lief bisher eine Pause zwischen den Stücken. Die neue Musik besteht aus echten Schleifen;
der „Pegelsprung“ an ihrer Naht in der zweiten Tabelle ist jeweils der betonte erste Schlag des Taktes (Trommel,
Glocke), kein Knacken: der Sprung am Übergang selbst liegt überall unter 1, nur beim Titel bei 1,6 (die Harfe setzt
genau auf dem Anfang ein).

## Vorher: alle 140 Dateien

| Datei | s | Kan.×Rate | KB | LUFS | Spitze dB | Clip | Stille v/h s | Schwerp. Hz | Bänder % (<150/-500/-2k/-6k/>6k) | Naht | Urteil | Grund |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| akt_ende.ogg | 4.46 | 1×32k | 28 | -20.6 | -8.8 | 0 | 0.00/0.18 | 294 | 32 50 18 0 0 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| amb_drone.ogg | 30.00 | 1×44k | 178 | -23.4 | -6.0 | 0 | 0.00/0.00 | 51 | 96 0 0 0 0 | -3.6 dB / 1.99 **prüfen** | **gelöscht** | Brummen bei 51 Hz, Naht springt; die Musik hat jetzt einen eigenen Grund |
| amb_felder.ogg | 15.00 | 1×32k | 107 | -20.9 | -5.4 | 0 | 0.00/0.00 | 354 | 60 9 19 1 1 | -1.3 dB / 0.59 ok | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| amb_freiland.ogg | 15.00 | 1×32k | 122 | -23.1 | -1.2 | 0 | 0.00/0.00 | 4185 | 11 7 48 2 31 | -1.5 dB / 0.48 ok | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| amb_grab.ogg | 15.00 | 1×32k | 93 | -20.0 | 1.3 | 4057 | 0.00/0.00 | 20 | 38 0 0 0 0 | -2.3 dB / 3.76 **prüfen** | **neu** | 4057 übersteuerte Werte, Schwerpunkt 20 Hz, Naht springt |
| amb_hoehle.ogg | 15.00 | 1×32k | 82 | -19.9 | 0.1 | 39 | 0.00/0.00 | 62 | 97 1 0 0 0 | +2.6 dB / 0.46 ok | **neu** | 97 % unter 150 Hz (Rumpeln), 39 übersteuerte Werte |
| amb_rosetau.ogg | 15.00 | 1×32k | 96 | -21.8 | -7.7 | 0 | 0.00/0.00 | 559 | 1 1 96 2 0 | +2.7 dB / 1.11 **prüfen** | nachbearbeitet | Naht ungleich: nahtlos überblendet, Spitzen −1 dB |
| amb_wind.ogg | 22.00 | 1×44k | 159 | -40.8 | -4.0 | 0 | 0.00/0.00 | 11 | 3 0 0 0 0 | +2.1 dB / 1.33 **prüfen** | **neu** | −41 LUFS, Schwerpunkt 11 Hz: praktisch unhörbarer Infraschall |
| aufheben.ogg | 1.99 | 1×44k | 23 | -17.7 | 1.7 | 2 | 0.01/0.00 | 11746 | 0 0 0 7 93 |  | nachbearbeitet | Spitzen über 0 dB → −1 dB, sonst unverändert |
| aufstieg.ogg | 2.56 | 1×44k | 23 | -13.3 | -0.8 | 0 | 0.00/0.02 | 555 | 3 39 58 0 0 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| ausweichen.ogg | 1.96 | 1×44k | 20 | -18.4 | -0.8 | 0 | 0.00/0.01 | 1532 | 3 32 45 14 6 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| beam.ogg | 0.90 | 1×44k | 13 | -14.7 | 0.1 | 0 | 0.00/0.22 | 7468 | 0 0 3 30 67 |  | nachbearbeitet | Spitzen über 0 dB → −1 dB, sonst unverändert |
| bolt.ogg | 0.80 | 1×44k | 12 | -14.0 | 2.3 | 19 | 0.00/0.17 | 2868 | 15 9 32 27 18 |  | nachbearbeitet | Spitzen über 0 dB → −1 dB, sonst unverändert |
| boss_appear.ogg | 4.00 | 1×44k | 35 | -8.4 | 1.8 | 1715 | 0.00/1.32 | 429 | 5 58 37 0 0 |  | nachbearbeitet | Spitzen über 0 dB → −1 dB, sonst unverändert |
| boss_phase.ogg | 2.52 | 1×32k | 18 | -18.2 | -5.0 | 0 | 0.00/0.25 | 86 | 92 5 2 0 0 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| boss_stern.ogg | 2.48 | 1×32k | 18 | -18.1 | -4.2 | 0 | 0.00/0.78 | 71 | 75 1 1 0 0 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| dash.ogg | 1.00 | 1×44k | 13 | -15.8 | 2.1 | 70 | 0.00/0.30 | 70 | 89 9 0 0 0 |  | nachbearbeitet | Spitzen über 0 dB → −1 dB, sonst unverändert |
| esel.ogg | 3.16 | 1×44k | 29 | -12.5 | -0.5 | 0 | 0.00/0.02 | 956 | 0 12 85 3 0 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| ev_esel.ogg | 2.15 | 1×32k | 16 | -18.3 | -6.2 | 0 | 0.00/0.09 | 1077 | 0 0 96 3 0 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| ev_falke.ogg | 1.50 | 1×32k | 13 | -18.6 | -4.4 | 0 | 0.00/0.02 | 2690 | 0 0 0 99 0 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| ev_fisch.ogg | 1.19 | 1×32k | 14 | -19.1 | -0.6 | 0 | 0.00/0.03 | 1963 | 0 15 59 20 7 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| ev_fledermaus.ogg | 1.73 | 1×32k | 16 | -17.9 | -3.7 | 0 | 0.00/0.05 | 5738 | 0 0 0 62 38 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| ev_fluegel.ogg | 1.36 | 1×32k | 15 | -21.4 | 0.7 | 6 | 0.01/0.06 | 504 | 55 7 26 5 1 |  | nachbearbeitet | Spitzen über 0 dB → −1 dB, sonst unverändert |
| ev_glas.ogg | 1.95 | 1×32k | 18 | -18.8 | -4.3 | 0 | 0.00/0.05 | 8996 | 0 0 0 4 96 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| ev_kaefer.ogg | 1.34 | 1×32k | 15 | -25.6 | -2.8 | 0 | 0.00/0.01 | 11375 | 1 0 1 11 87 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| ev_maus.ogg | 1.24 | 1×32k | 13 | -18.7 | -2.4 | 0 | 0.00/0.00 | 6181 | 0 0 2 27 71 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| ev_sand.ogg | 2.44 | 1×32k | 23 | -26.6 | -0.6 | 0 | 0.05/0.05 | 8966 | 0 0 2 14 84 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| ev_schakal.ogg | 1.64 | 1×32k | 12 | -18.2 | -6.1 | 0 | 0.00/0.02 | 684 | 0 0 100 0 0 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| ev_seufzer.ogg | 0.97 | 1×32k | 10 | -18.3 | -7.7 | 0 | 0.00/0.00 | 1162 | 0 1 98 0 0 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| ev_stein.ogg | 1.53 | 1×32k | 17 | -24.8 | 0.1 | 1 | 0.04/0.22 | 6690 | 0 0 1 38 61 |  | nachbearbeitet | Spitzen über 0 dB → −1 dB, sonst unverändert |
| ev_tor_fern.ogg | 2.74 | 1×32k | 21 | -18.8 | -5.9 | 0 | 0.00/0.10 | 231 | 60 30 9 1 0 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| ev_tropfen.ogg | 0.79 | 1×32k | 9 | -20.3 | 0.8 | 8 | 0.00/0.06 | 3928 | 0 0 64 2 34 |  | nachbearbeitet | Spitzen über 0 dB → −1 dB, sonst unverändert |
| feuer_an.ogg | 2.25 | 1×44k | 22 | -16.2 | -0.9 | 0 | 0.00/0.02 | 159 | 71 27 2 0 0 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| feuer_brennt.ogg | 6.00 | 1×44k | 60 | -23.0 | -4.7 | 0 | 0.00/0.00 | 185 | 79 18 1 1 0 | +0.4 dB / 0.09 ok | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| gate.ogg | 4.00 | 1×44k | 42 | -12.7 | 2.1 | 239 | 0.00/0.60 | 242 | 62 32 4 0 1 |  | nachbearbeitet | Spitzen über 0 dB → −1 dB, sonst unverändert |
| hero_die.ogg | 1.60 | 1×44k | 17 | -21.3 | 1.6 | 7 | 0.00/1.09 | 678 | 76 5 10 5 3 |  | nachbearbeitet | Spitzen über 0 dB → −1 dB, sonst unverändert |
| herz_frei.ogg | 2.41 | 1×44k | 23 | -13.5 | 0.0 | 0 | 0.00/0.01 | 4697 | 0 0 17 58 24 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| hit1.ogg | 0.68 | 1×44k | 11 | -10.7 | 3.9 | 706 | 0.00/0.00 | 4694 | 5 0 2 57 29 |  | nachbearbeitet | Spitzen bis +3,9 dB (bis 751 übersteuerte Werte) → −1 dB; bleiben für Treffer der Gegner, der Held hat eigene je Klasse |
| hit2.ogg | 0.68 | 1×44k | 11 | -13.1 | 3.2 | 238 | 0.00/0.00 | 4636 | 10 1 1 36 37 |  | nachbearbeitet | Spitzen bis +3,9 dB (bis 751 übersteuerte Werte) → −1 dB; bleiben für Treffer der Gegner, der Held hat eigene je Klasse |
| hit3.ogg | 0.68 | 1×44k | 11 | -10.2 | 3.8 | 751 | 0.00/0.00 | 3476 | 18 0 5 35 25 |  | nachbearbeitet | Spitzen bis +3,9 dB (bis 751 übersteuerte Werte) → −1 dB; bleiben für Treffer der Gegner, der Held hat eigene je Klasse |
| hurt1.ogg | 0.69 | 1×44k | 11 | -10.2 | 2.6 | 323 | 0.00/0.17 | 1260 | 0 18 73 4 5 |  | **gelöscht** | bis 1222 übersteuerte Werte; ersetzt durch Schmerzlaute je Geschlecht |
| hurt2.ogg | 0.68 | 1×44k | 10 | -9.4 | 2.9 | 561 | 0.00/0.20 | 1074 | 1 42 49 4 4 |  | **gelöscht** | bis 1222 übersteuerte Werte; ersetzt durch Schmerzlaute je Geschlecht |
| hurt3.ogg | 0.68 | 1×44k | 11 | -7.0 | 3.1 | 1222 | 0.00/0.09 | 1087 | 0 11 83 3 2 |  | **gelöscht** | bis 1222 übersteuerte Werte; ersetzt durch Schmerzlaute je Geschlecht |
| irrlicht.ogg | 2.01 | 1×44k | 19 | -14.9 | -1.3 | 0 | 0.00/0.01 | 193 | 79 11 9 0 0 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| katze.ogg | 1.70 | 1×44k | 19 | -10.7 | -1.3 | 0 | 0.00/0.02 | 2062 | 0 0 21 79 0 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| krug_bricht.ogg | 2.08 | 1×44k | 24 | -15.4 | 1.1 | 1 | 0.01/0.00 | 4783 | 1 2 23 48 27 |  | nachbearbeitet | Spitzen über 0 dB → −1 dB, sonst unverändert |
| mus_duat.ogg | 30.00 | 2×48k | 348 | -16.1 | -3.7 | 0 | 0.01/2.53 | 144 | 71 26 3 0 0 | +20.1 dB / 0.03 **prüfen** | **gelöscht** | 30-s-Stück von Gomo mit Ein-/Ausblende (Naht +3 bis +20 dB, bis 2,5 s Stille am Ende): keine Schleife; ersetzt durch eigene Musik je Akt |
| mus_felder.ogg | 30.00 | 2×48k | 363 | -18.0 | -1.5 | 0 | 0.00/0.00 | 514 | 65 24 4 3 3 | +6.8 dB / 0.01 **prüfen** | **gelöscht** | 30-s-Stück von Gomo mit Ein-/Ausblende (Naht +3 bis +20 dB, bis 2,5 s Stille am Ende): keine Schleife; ersetzt durch eigene Musik je Akt |
| mus_grab.ogg | 30.00 | 2×48k | 348 | -24.0 | -2.9 | 0 | 0.02/1.41 | 330 | 26 59 14 1 0 | +7.0 dB / 0.00 **prüfen** | **gelöscht** | 30-s-Stück von Gomo mit Ein-/Ausblende (Naht +3 bis +20 dB, bis 2,5 s Stille am Ende): keine Schleife; ersetzt durch eigene Musik je Akt |
| mus_hoehle.ogg | 30.00 | 2×48k | 367 | -19.3 | -8.3 | 0 | 0.00/0.00 | 77 | 99 1 0 0 0 | +13.0 dB / 0.08 **prüfen** | **gelöscht** | 30-s-Stück von Gomo mit Ein-/Ausblende (Naht +3 bis +20 dB, bis 2,5 s Stille am Ende): keine Schleife; ersetzt durch eigene Musik je Akt |
| mus_kampf.ogg | 30.00 | 2×48k | 375 | -19.6 | -1.9 | 1 | 0.05/1.72 | 554 | 75 10 9 4 2 | +14.3 dB / 0.01 **prüfen** | **gelöscht** | 30-s-Stück von Gomo mit Ein-/Ausblende (Naht +3 bis +20 dB, bis 2,5 s Stille am Ende): keine Schleife; ersetzt durch eigene Musik je Akt |
| mus_rosetau.ogg | 30.00 | 2×48k | 357 | -12.0 | -2.0 | 25 | 0.00/0.00 | 485 | 42 6 52 0 0 | +4.5 dB / 0.05 **prüfen** | **gelöscht** | 30-s-Stück von Gomo mit Ein-/Ausblende (Naht +3 bis +20 dB, bis 2,5 s Stille am Ende): keine Schleife; ersetzt durch eigene Musik je Akt |
| mus_titel.ogg | 30.00 | 2×48k | 356 | -9.4 | 0.1 | 441 | 0.02/3.15 | 624 | 34 10 53 1 1 | +26.0 dB / 0.00 **prüfen** | **neu** | wie oben, dazu 441 übersteuerte Werte; neues Titelstück (musik.py) |
| mus_wueste.ogg | 30.00 | 2×48k | 326 | -19.6 | -5.0 | 0 | 0.00/0.00 | 90 | 90 4 1 0 0 | +2.8 dB / 0.23 ok | **gelöscht** | 30-s-Stück von Gomo mit Ein-/Ausblende (Naht +3 bis +20 dB, bis 2,5 s Stille am Ende): keine Schleife; ersetzt durch eigene Musik je Akt |
| oath.ogg | 2.48 | 1×44k | 22 | -12.1 | 2.0 | 481 | 0.00/0.15 | 195 | 60 31 9 0 0 |  | nachbearbeitet | Spitzen über 0 dB → −1 dB, sonst unverändert |
| papyrus.ogg | 1.85 | 1×44k | 24 | -16.4 | -0.1 | 0 | 0.00/0.01 | 5300 | 0 0 7 59 34 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| potion.ogg | 1.50 | 1×44k | 18 | -19.6 | 1.7 | 25 | 0.00/0.36 | 1461 | 17 28 43 2 10 |  | nachbearbeitet | Spitzen über 0 dB → −1 dB, sonst unverändert |
| rueckkehr.ogg | 1.94 | 1×32k | 17 | -18.0 | -5.9 | 0 | 0.00/0.02 | 8470 | 0 0 0 16 83 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| schaf.ogg | 1.59 | 1×44k | 17 | -11.0 | 0.2 | 1 | 0.00/0.02 | 1481 | 0 7 67 26 0 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| segen.ogg | 1.84 | 1×44k | 19 | -11.7 | 0.1 | 1 | 0.00/0.01 | 2149 | 0 0 4 96 0 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| skel_attack.ogg | 0.90 | 1×44k | 13 | -9.4 | 1.5 | 66 | 0.00/0.07 | 2348 | 13 3 56 19 10 |  | nachbearbeitet | Spitzen über 0 dB → −1 dB, sonst unverändert |
| skel_die.ogg | 1.60 | 1×44k | 18 | -22.3 | 0.4 | 2 | 0.00/0.66 | 3604 | 0 1 30 55 15 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| skel_wake.ogg | 2.00 | 1×44k | 27 | -18.4 | 1.8 | 8 | 0.00/0.79 | 7083 | 0 0 1 36 63 |  | nachbearbeitet | Spitzen über 0 dB → −1 dB, sonst unverändert |
| skorpion.ogg | 1.47 | 1×44k | 16 | -19.8 | 0.5 | 1 | 0.01/0.01 | 848 | 19 8 66 5 1 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| src_herz.ogg | 6.00 | 1×32k | 38 | -20.4 | 0.8 | 71 | 0.00/0.01 | 170 | 54 46 0 0 0 | -5.1 dB / 0.08 **prüfen** | nachbearbeitet | Naht ungleich: nahtlos überblendet, Spitzen −1 dB |
| src_reigen.ogg | 8.00 | 1×32k | 55 | -16.8 | -2.7 | 0 | 0.00/0.00 | 680 | 0 42 57 1 0 | -0.4 dB / 0.01 ok | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| src_schrein.ogg | 8.00 | 1×32k | 56 | -22.9 | -3.8 | 0 | 0.00/0.00 | 219 | 61 32 5 0 0 | +16.9 dB / 10.61 **prüfen** | nachbearbeitet | Naht sprang (+17 dB, Sprung 10,6): nahtlos überblendet |
| src_wasser.ogg | 8.00 | 1×32k | 65 | -19.9 | 0.8 | 13 | 0.00/0.00 | 632 | 2 1 19 10 1 | -0.3 dB / 0.04 ok | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| src_werkstatt.ogg | 8.00 | 1×32k | 53 | -21.2 | -2.0 | 0 | 0.00/0.00 | 7024 | 0 0 0 8 92 | +8.5 dB / 0.28 **prüfen** | nachbearbeitet | Naht ungleich: nahtlos überblendet, Spitzen −1 dB |
| step1.ogg | 0.48 | 1×44k | 8 | -15.7 | -0.5 | 0 | 0.00/0.04 | 44 | 99 0 0 0 0 |  | **gelöscht** | unbenutzt (Schritte laufen über step_sand/stein/erde/glas) |
| step2.ogg | 0.48 | 1×44k | 8 | -22.5 | -4.2 | 0 | 0.00/0.05 | 44 | 100 0 0 0 0 |  | **gelöscht** | unbenutzt (Schritte laufen über step_sand/stein/erde/glas) |
| step3.ogg | 0.48 | 1×44k | 8 | -19.9 | -0.2 | 0 | 0.00/0.04 | 42 | 98 0 0 0 0 |  | **gelöscht** | unbenutzt (Schritte laufen über step_sand/stein/erde/glas) |
| step_erde1.ogg | 0.34 | 1×44k | 6 | -70.0 | -3.1 | 0 | 0.02/0.12 | 128 | 92 6 1 0 0 |  | bleibt | vom Auftraggeber für gut befunden (LUFS −70 heißt nur: kürzer als 0,4 s, nicht messbar) |
| step_erde2.ogg | 0.32 | 1×44k | 6 | -70.0 | -1.7 | 0 | 0.02/0.10 | 226 | 88 8 2 2 1 |  | bleibt | vom Auftraggeber für gut befunden (LUFS −70 heißt nur: kürzer als 0,4 s, nicht messbar) |
| step_erde3.ogg | 0.29 | 1×44k | 6 | -70.0 | -1.3 | 0 | 0.01/0.14 | 240 | 78 18 1 2 0 |  | bleibt | vom Auftraggeber für gut befunden (LUFS −70 heißt nur: kürzer als 0,4 s, nicht messbar) |
| step_erde4.ogg | 0.32 | 1×44k | 6 | -70.0 | -1.5 | 0 | 0.02/0.07 | 292 | 83 9 2 3 1 |  | bleibt | vom Auftraggeber für gut befunden (LUFS −70 heißt nur: kürzer als 0,4 s, nicht messbar) |
| step_glas1.ogg | 0.32 | 1×44k | 7 | -70.0 | -0.5 | 0 | 0.01/0.04 | 5697 | 0 1 18 32 48 |  | bleibt | vom Auftraggeber für gut befunden (LUFS −70 heißt nur: kürzer als 0,4 s, nicht messbar) |
| step_glas2.ogg | 0.32 | 1×44k | 7 | -70.0 | -1.5 | 0 | 0.01/0.03 | 5732 | 0 1 26 16 56 |  | bleibt | vom Auftraggeber für gut befunden (LUFS −70 heißt nur: kürzer als 0,4 s, nicht messbar) |
| step_glas3.ogg | 0.34 | 1×44k | 7 | -70.0 | -2.3 | 0 | 0.02/0.07 | 5030 | 0 1 26 31 41 |  | bleibt | vom Auftraggeber für gut befunden (LUFS −70 heißt nur: kürzer als 0,4 s, nicht messbar) |
| step_glas4.ogg | 0.32 | 1×44k | 7 | -70.0 | -0.9 | 0 | 0.02/0.02 | 4604 | 2 1 34 24 39 |  | bleibt | vom Auftraggeber für gut befunden (LUFS −70 heißt nur: kürzer als 0,4 s, nicht messbar) |
| step_sand1.ogg | 0.32 | 1×44k | 6 | -70.0 | -3.0 | 0 | 0.03/0.00 | 1057 | 30 4 48 11 1 |  | bleibt | vom Auftraggeber für gut befunden (LUFS −70 heißt nur: kürzer als 0,4 s, nicht messbar) |
| step_sand2.ogg | 0.32 | 1×44k | 7 | -70.0 | -2.5 | 0 | 0.03/0.00 | 891 | 42 2 39 8 1 |  | bleibt | vom Auftraggeber für gut befunden (LUFS −70 heißt nur: kürzer als 0,4 s, nicht messbar) |
| step_sand3.ogg | 0.32 | 1×44k | 6 | -70.0 | -3.3 | 0 | 0.02/0.00 | 1240 | 20 4 64 9 1 |  | bleibt | vom Auftraggeber für gut befunden (LUFS −70 heißt nur: kürzer als 0,4 s, nicht messbar) |
| step_sand4.ogg | 0.32 | 1×44k | 6 | -70.0 | -1.0 | 0 | 0.03/0.00 | 1725 | 1 6 71 19 2 |  | bleibt | vom Auftraggeber für gut befunden (LUFS −70 heißt nur: kürzer als 0,4 s, nicht messbar) |
| step_stein1.ogg | 0.34 | 1×44k | 7 | -70.0 | -1.9 | 0 | 0.01/0.09 | 2711 | 1 3 38 44 8 |  | bleibt | vom Auftraggeber für gut befunden (LUFS −70 heißt nur: kürzer als 0,4 s, nicht messbar) |
| step_stein2.ogg | 0.32 | 1×44k | 6 | -70.0 | -3.4 | 0 | 0.02/0.02 | 2561 | 11 9 28 40 9 |  | bleibt | vom Auftraggeber für gut befunden (LUFS −70 heißt nur: kürzer als 0,4 s, nicht messbar) |
| step_stein3.ogg | 0.32 | 1×44k | 7 | -70.0 | -1.4 | 0 | 0.02/0.05 | 1421 | 8 21 47 20 3 |  | bleibt | vom Auftraggeber für gut befunden (LUFS −70 heißt nur: kürzer als 0,4 s, nicht messbar) |
| step_stein4.ogg | 0.32 | 1×44k | 6 | -70.0 | -1.2 | 0 | 0.03/0.05 | 714 | 6 19 66 2 1 |  | bleibt | vom Auftraggeber für gut befunden (LUFS −70 heißt nur: kürzer als 0,4 s, nicht messbar) |
| swing1.ogg | 0.60 | 1×44k | 9 | -23.2 | 1.8 | 702 | 0.01/0.25 | 23 | 16 2 0 0 0 |  | **gelöscht** | Schwerpunkt 23–56 Hz (fast nur Tiefbass), bis 1228 übersteuerte Werte; ersetzt durch Klänge je Klasse |
| swing2.ogg | 0.60 | 1×44k | 9 | -18.6 | 1.5 | 179 | 0.00/0.23 | 39 | 27 4 0 0 0 |  | **gelöscht** | Schwerpunkt 23–56 Hz (fast nur Tiefbass), bis 1228 übersteuerte Werte; ersetzt durch Klänge je Klasse |
| swing3.ogg | 0.62 | 1×44k | 9 | -17.7 | 2.1 | 1228 | 0.00/0.31 | 56 | 38 11 0 0 0 |  | **gelöscht** | Schwerpunkt 23–56 Hz (fast nur Tiefbass), bis 1228 übersteuerte Werte; ersetzt durch Klänge je Klasse |
| thot.ogg | 1.70 | 1×32k | 15 | -19.0 | 0.4 | 1 | 0.00/0.01 | 8003 | 0 3 13 17 67 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| tor_auf.ogg | 4.39 | 1×32k | 30 | -24.4 | -7.6 | 0 | 0.01/0.24 | 1019 | 88 1 0 0 8 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| torch.ogg | 8.00 | 2×44k | 146 | -20.7 | -5.9 | 0 | 0.00/0.00 | 411 | 22 67 10 0 1 | -0.6 dB / 0.06 ok | nachbearbeitet | stereo → mono (halbe Größe), nahtlos |
| truhe.ogg | 2.00 | 1×44k | 21 | -20.3 | 0.2 | 1 | 0.01/0.00 | 1413 | 14 32 30 20 4 |  | nachbearbeitet | Spitzen über 0 dB → −1 dB, sonst unverändert |
| udjat.ogg | 1.60 | 1×44k | 14 | -19.2 | -0.7 | 0 | 0.00/0.00 | 65 | 99 1 0 0 0 |  | nachbearbeitet | Spitzen über 0 dB → −1 dB, sonst unverändert |
| ui.ogg | 0.68 | 1×44k | 11 | -23.4 | 1.9 | 5 | 0.00/0.31 | 1508 | 2 1 77 19 0 |  | **neu** | ersetzt durch einen weichen Holzklick (gleicher Name, alle Knöpfe) |
| victory.ogg | 3.00 | 1×44k | 34 | -13.1 | -0.0 | 0 | 0.00/0.00 | 7819 | 0 0 0 29 71 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| vo_boss.ogg | 7.03 | 1×44k | 57 | -19.2 | -1.0 | 0 | 0.00/0.30 | 710 | 74 11 6 5 4 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_chapter.ogg | 20.27 | 1×44k | 168 | -21.3 | -1.3 | 0 | 0.00/0.21 | 560 | 66 24 3 3 3 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_death.ogg | 4.38 | 1×44k | 38 | -17.6 | -1.0 | 0 | 0.00/0.12 | 715 | 81 6 4 4 4 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_epi.ogg | 12.41 | 1×44k | 102 | -21.1 | -1.0 | 0 | 0.00/0.19 | 695 | 52 32 9 3 4 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h01_epi.ogg | 15.19 | 1×32k | 127 | -17.6 | -1.3 | 0 | 0.00/0.25 | 732 | 73 15 4 3 5 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h01_lead.ogg | 5.96 | 1×32k | 51 | -17.3 | -1.1 | 0 | 0.00/0.25 | 838 | 73 18 1 2 7 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h01_say.ogg | 6.23 | 1×32k | 53 | -17.1 | -1.5 | 0 | 0.00/0.25 | 696 | 76 12 5 2 5 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h02_epi.ogg | 16.08 | 1×32k | 132 | -17.5 | -1.2 | 0 | 0.00/0.25 | 570 | 71 19 4 2 4 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h02_lead.ogg | 7.32 | 1×32k | 60 | -18.0 | -1.4 | 0 | 0.00/0.25 | 892 | 63 23 4 3 7 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h02_say.ogg | 3.76 | 1×32k | 34 | -16.9 | -1.1 | 0 | 0.00/0.25 | 813 | 64 24 4 3 6 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h03_epi.ogg | 16.80 | 1×32k | 137 | -17.4 | -1.2 | 0 | 0.00/0.25 | 663 | 73 16 5 2 5 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h03_lead.ogg | 9.74 | 1×32k | 83 | -17.7 | -1.3 | 0 | 0.00/0.25 | 840 | 75 9 4 6 5 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h03_say.ogg | 3.74 | 1×32k | 31 | -17.2 | -1.3 | 0 | 0.00/0.25 | 953 | 79 4 5 4 8 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h04_epi.ogg | 14.83 | 1×32k | 122 | -17.3 | -1.3 | 0 | 0.00/0.25 | 967 | 70 18 2 2 8 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h04_lead.ogg | 11.17 | 1×32k | 92 | -17.9 | -0.8 | 0 | 0.00/0.25 | 941 | 60 27 4 3 7 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h04_say.ogg | 3.54 | 1×32k | 32 | -17.8 | -1.5 | 0 | 0.00/0.25 | 500 | 68 22 5 3 2 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h05_epi.ogg | 18.53 | 1×32k | 153 | -17.6 | -1.2 | 0 | 0.00/0.24 | 510 | 73 19 3 2 3 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h05_lead.ogg | 7.30 | 1×32k | 61 | -17.4 | -1.3 | 0 | 0.00/0.25 | 368 | 72 22 2 2 2 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h05_say.ogg | 1.88 | 1×32k | 17 | -18.9 | -1.5 | 0 | 0.00/0.25 | 327 | 74 19 4 3 1 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h06_epi.ogg | 7.74 | 1×32k | 65 | -17.4 | -1.3 | 0 | 0.00/0.25 | 823 | 69 19 4 3 6 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h06_lead.ogg | 8.24 | 1×32k | 67 | -16.9 | -1.4 | 0 | 0.00/0.25 | 530 | 73 20 2 2 4 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h06_say.ogg | 2.25 | 1×32k | 22 | -20.0 | -1.5 | 0 | 0.00/0.25 | 269 | 75 19 3 1 1 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h07_epi.ogg | 11.32 | 1×32k | 93 | -17.4 | -1.2 | 0 | 0.00/0.25 | 803 | 73 17 2 2 7 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h07_lead.ogg | 5.60 | 1×32k | 47 | -18.0 | -1.4 | 0 | 0.00/0.25 | 1302 | 71 9 4 5 11 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h07_say.ogg | 3.26 | 1×32k | 30 | -17.2 | -1.4 | 0 | 0.00/0.25 | 736 | 68 18 5 3 5 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h08_epi.ogg | 4.91 | 1×32k | 42 | -17.8 | -1.0 | 0 | 0.00/0.25 | 444 | 49 39 8 3 1 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h08_lead.ogg | 5.58 | 1×32k | 48 | -17.9 | -1.3 | 0 | 0.00/0.24 | 495 | 76 15 3 3 3 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h08_say.ogg | 1.99 | 1×32k | 19 | -21.0 | -1.6 | 0 | 0.00/0.25 | 383 | 76 12 8 4 1 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h09_epi.ogg | 4.81 | 1×32k | 42 | -17.6 | -1.5 | 0 | 0.00/0.25 | 838 | 60 24 7 3 6 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h09_lead.ogg | 4.20 | 1×32k | 37 | -17.9 | -1.3 | 0 | 0.00/0.25 | 852 | 60 23 8 2 6 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h09_say.ogg | 2.17 | 1×32k | 21 | -21.2 | -1.7 | 0 | 0.00/0.25 | 369 | 84 9 3 3 2 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h10_epi.ogg | 4.60 | 1×32k | 39 | -17.9 | -1.3 | 0 | 0.00/0.25 | 694 | 69 18 7 2 4 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h10_lead.ogg | 6.50 | 1×32k | 54 | -18.0 | -1.3 | 0 | 0.00/0.25 | 932 | 65 23 4 2 7 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h10_say.ogg | 1.61 | 1×32k | 14 | -19.0 | -1.8 | 0 | 0.00/0.25 | 737 | 79 10 4 2 6 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h11_epi.ogg | 3.87 | 1×32k | 32 | -17.5 | -1.5 | 0 | 0.00/0.25 | 590 | 75 13 6 1 4 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h11_lead.ogg | 8.06 | 1×32k | 69 | -17.7 | -1.6 | 0 | 0.00/0.25 | 381 | 64 30 3 1 2 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h11_say.ogg | 1.84 | 1×32k | 18 | -19.0 | -1.9 | 0 | 0.00/0.25 | 314 | 74 21 3 1 1 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h12_epi.ogg | 13.95 | 1×32k | 117 | -17.2 | -1.1 | 0 | 0.00/0.25 | 402 | 73 20 4 2 2 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h12_lead.ogg | 10.41 | 1×32k | 89 | -17.3 | -1.2 | 0 | 0.00/0.25 | 406 | 74 18 3 3 2 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| vo_h12_say.ogg | 3.51 | 1×32k | 30 | -17.0 | -1.2 | 0 | 0.00/0.25 | 1115 | 69 14 4 6 8 |  | bleibt (vorerst) | Erzähler Samuel Storm, gleichmäßig −17…−21 LUFS, 0,25 s Ausklang; Texte schreibt Agent D neu → zweiter Durchgang |
| whirl.ogg | 1.20 | 1×44k | 15 | -12.9 | -0.9 | 0 | 0.00/0.41 | 4526 | 0 0 13 67 20 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |
| ziege.ogg | 0.85 | 1×44k | 11 | -13.9 | -1.1 | 0 | 0.00/0.02 | 1513 | 0 5 57 38 0 |  | bleibt | unauffällig (Pegel, Spitzen, Klangfarbe plausibel) |

## Nachher: neue und unter altem Namen ersetzte Dateien (gemessen nach dem Schreiben)

Alle neuen Geräusche: mono, Spitze höchstens −1 dB, keine übersteuerten Werte, Stille vorn höchstens wenige
Millisekunden. Kurze Schläge erreichen ihr Lautheitsziel nicht ganz, weil der Begrenzer die Spitze hält – bei
Einschlägen gewollt (kurz und spitz, nicht dauerhaft laut).

| Datei | s | Kan.×Rate | KB | LUFS | Spitze dB | Clip | Stille v/h s | Schwerp. Hz | Bänder % (<150/-500/-2k/-6k/>6k) | Naht (Pegel/Sprung) |
|---|---|---|---|---|---|---|---|---|---|---|
| aff_auftritt.ogg | 1.82 | 1×44k | 16 | -17.1 | -1.3 | 0 | 0.04/0.16 | 163 | 85 12 1 1 0 |  |
| aff_feder.ogg | 0.69 | 1×44k | 10 | -16.1 | -0.6 | 0 | 0.01/0.10 | 2128 | 31 17 8 42 1 |  |
| aff_feder_bruch.ogg | 1.19 | 1×44k | 15 | -17.1 | -0.5 | 0 | 0.00/0.11 | 4021 | 48 1 2 17 32 |  |
| aff_fessel.ogg | 0.89 | 1×44k | 12 | -18.7 | -1.3 | 0 | 0.20/0.07 | 8879 | 0 1 2 27 70 |  |
| aff_glut.ogg | 1.48 | 1×44k | 17 | -19.2 | -1.3 | 0 | 0.00/0.16 | 7854 | 1 1 5 31 63 |  |
| aff_kette.ogg | 1.28 | 1×44k | 15 | -22.6 | -0.4 | 0 | 0.00/0.03 | 4503 | 36 9 2 13 40 |  |
| aff_klage.ogg | 1.93 | 1×44k | 19 | -18.4 | -5.6 | 0 | 0.03/0.15 | 744 | 0 0 100 0 0 |  |
| aff_ruf.ogg | 1.90 | 1×44k | 16 | -16.2 | -6.3 | 0 | 0.00/0.22 | 265 | 6 88 6 0 0 |  |
| aff_spalt.ogg | 0.79 | 1×44k | 10 | -17.8 | -0.7 | 0 | 0.01/0.15 | 3686 | 6 3 31 39 22 |  |
| aff_sprung.ogg | 0.92 | 1×44k | 11 | -16.1 | -2.4 | 0 | 0.05/0.25 | 1992 | 0 2 75 19 5 |  |
| aff_sturm.ogg | 4.00 | 1×44k | 37 | -20.4 | -6.2 | 0 | 0.00/0.00 | 961 | 8 9 76 4 2 |  |
| amb_feuergrube.ogg | 18.00 | 1×32k | 142 | -22.5 | -2.4 | 0 | 0.00/0.00 | 206 | 64 34 1 1 0 | +0.8 dB / 0.17 ok |
| amb_grab.ogg | 18.00 | 1×32k | 132 | -22.8 | -3.3 | 0 | 0.00/0.00 | 135 | 88 11 0 0 0 | -2.6 dB / 0.79 ok |
| amb_hoehle.ogg | 18.00 | 1×32k | 134 | -22.9 | -2.2 | 0 | 0.00/0.00 | 1361 | 1 3 88 5 3 | -4.0 dB / 0.02 **prüfen** |
| amb_morgen.ogg | 18.00 | 1×32k | 137 | -22.5 | -6.2 | 0 | 0.00/0.00 | 448 | 51 32 15 1 2 | -0.1 dB / 0.07 ok |
| amb_nun.ogg | 18.00 | 1×32k | 135 | -22.3 | -4.9 | 0 | 0.00/0.00 | 1123 | 2 18 72 8 1 | +0.3 dB / 0.40 ok |
| amb_sandbank.ogg | 18.00 | 1×32k | 126 | -22.5 | -5.6 | 0 | 0.00/0.00 | 585 | 16 26 56 1 0 | -0.8 dB / 0.08 ok |
| amb_wind.ogg | 18.00 | 1×32k | 133 | -24.5 | -8.5 | 0 | 0.00/0.00 | 509 | 11 42 47 0 0 | -0.4 dB / 0.41 ok |
| anlegen.ogg | 0.46 | 1×44k | 8 | -28.8 | -1.1 | 0 | 0.00/0.08 | 8119 | 1 1 1 31 66 |  |
| armbrust1.ogg | 0.36 | 1×44k | 7 | -70.0 | -0.9 | 0 | 0.00/0.06 | 1285 | 18 41 22 16 2 |  |
| armbrust2.ogg | 0.22 | 1×44k | 6 | -70.0 | -1.5 | 0 | 0.00/0.06 | 850 | 11 53 25 8 3 |  |
| belohnung.ogg | 0.92 | 1×44k | 12 | -18.3 | -0.7 | 0 | 0.17/0.20 | 11063 | 0 0 0 5 94 |  |
| bolzen1.ogg | 0.24 | 1×44k | 5 | -70.0 | -0.8 | 0 | 0.00/0.05 | 360 | 38 54 5 2 1 |  |
| bolzen2.ogg | 0.29 | 1×44k | 6 | -70.0 | -1.4 | 0 | 0.00/0.05 | 333 | 56 37 3 3 1 |  |
| bolzen3.ogg | 0.30 | 1×44k | 6 | -70.0 | -0.8 | 0 | 0.00/0.08 | 470 | 54 34 6 3 2 |  |
| erloschen_tod1.ogg | 1.36 | 1×44k | 16 | -18.3 | -1.8 | 0 | 0.06/0.06 | 1193 | 0 18 74 8 0 |  |
| erloschen_tod2.ogg | 1.44 | 1×44k | 16 | -18.3 | -1.8 | 0 | 0.06/0.20 | 1336 | 0 4 88 8 0 |  |
| erloschen_wach1.ogg | 1.17 | 1×44k | 13 | -17.8 | -5.4 | 0 | 0.00/0.05 | 3244 | 0 0 1 98 1 |  |
| erloschen_wach2.ogg | 1.19 | 1×44k | 14 | -17.7 | -4.9 | 0 | 0.00/0.11 | 3407 | 0 0 2 91 7 |  |
| ev_boe.ogg | 2.97 | 1×32k | 27 | -19.9 | -4.1 | 0 | 0.02/0.06 | 4191 | 12 3 19 38 28 |  |
| ev_flamme.ogg | 1.84 | 1×32k | 17 | -20.4 | -5.7 | 0 | 0.01/0.30 | 242 | 38 56 5 0 0 |  |
| ev_fluestern.ogg | 1.78 | 1×32k | 16 | -21.8 | -6.9 | 0 | 0.05/0.19 | 1920 | 0 0 50 49 1 |  |
| ev_gong.ogg | 2.69 | 1×32k | 23 | -24.0 | -1.4 | 0 | 0.07/0.70 | 677 | 2 28 68 2 0 |  |
| ev_knochen.ogg | 1.11 | 1×32k | 12 | -21.3 | -0.7 | 0 | 0.02/0.06 | 2741 | 0 2 23 68 7 |  |
| ev_platsch.ogg | 1.48 | 1×32k | 15 | -20.5 | -0.5 | 0 | 0.00/0.25 | 2084 | 1 20 37 37 5 |  |
| ev_vogel.ogg | 1.45 | 1×32k | 15 | -21.5 | -10.8 | 0 | 0.00/0.03 | 3026 | 0 0 0 100 0 |  |
| faust1.ogg | 0.39 | 1×44k | 7 | -70.0 | -0.4 | 0 | 0.03/0.06 | 690 | 26 48 17 8 1 |  |
| faust2.ogg | 0.41 | 1×44k | 7 | -23.3 | -1.4 | 0 | 0.00/0.08 | 485 | 44 41 9 5 1 |  |
| faust3.ogg | 0.43 | 1×44k | 7 | -23.6 | -1.5 | 0 | 0.01/0.05 | 787 | 24 47 17 10 2 |  |
| faustschlag1.ogg | 0.29 | 1×44k | 6 | -70.0 | -0.8 | 0 | 0.00/0.05 | 677 | 68 2 20 10 0 |  |
| faustschlag2.ogg | 0.24 | 1×44k | 6 | -70.0 | -1.1 | 0 | 0.00/0.04 | 353 | 66 18 13 3 1 |  |
| faustschlag3.ogg | 0.20 | 1×44k | 5 | -70.0 | -1.1 | 0 | 0.00/0.03 | 1365 | 33 4 33 29 1 |  |
| fenster_auf.ogg | 0.77 | 1×44k | 10 | -19.9 | -4.6 | 0 | 0.01/0.10 | 4134 | 0 2 23 53 22 |  |
| fenster_zu.ogg | 0.57 | 1×44k | 9 | -21.4 | -1.7 | 0 | 0.00/0.03 | 2542 | 11 14 42 18 15 |  |
| herzschlag.ogg | 0.85 | 1×44k | 10 | -20.8 | -1.0 | 0 | 0.00/0.10 | 81 | 99 0 0 0 0 |  |
| hieb1.ogg | 0.47 | 1×44k | 7 | -19.1 | -1.0 | 0 | 0.01/0.17 | 391 | 1 90 4 4 0 |  |
| hieb2.ogg | 0.60 | 1×44k | 9 | -19.0 | -1.3 | 0 | 0.00/0.11 | 697 | 2 74 15 9 1 |  |
| hieb3.ogg | 0.57 | 1×44k | 8 | -19.2 | -1.0 | 0 | 0.01/0.09 | 536 | 1 85 9 4 1 |  |
| hohl_tod1.ogg | 1.18 | 1×44k | 14 | -16.3 | -2.7 | 0 | 0.00/0.07 | 1301 | 10 17 60 7 7 |  |
| hohl_tod2.ogg | 1.44 | 1×44k | 17 | -16.8 | -0.8 | 0 | 0.00/0.09 | 2400 | 20 7 44 11 18 |  |
| hohl_wach1.ogg | 1.20 | 1×44k | 14 | -16.3 | -1.3 | 0 | 0.00/0.05 | 1076 | 20 20 45 13 2 |  |
| hohl_wach2.ogg | 1.15 | 1×44k | 14 | -16.2 | -2.1 | 0 | 0.03/0.04 | 1273 | 29 15 33 19 4 |  |
| hueter_ansage.ogg | 1.60 | 1×44k | 13 | -14.8 | -0.9 | 0 | 0.00/0.04 | 123 | 73 25 2 0 0 |  |
| hueter_schlag.ogg | 1.30 | 1×44k | 14 | -18.4 | -1.0 | 0 | 0.00/0.06 | 105 | 96 1 1 1 0 |  |
| klinge1.ogg | 0.56 | 1×44k | 9 | -15.2 | -0.4 | 0 | 0.00/0.09 | 5019 | 0 0 4 61 35 |  |
| klinge2.ogg | 0.72 | 1×44k | 10 | -17.6 | -0.9 | 0 | 0.00/0.06 | 3736 | 0 0 0 97 2 |  |
| klinge3.ogg | 0.80 | 1×44k | 11 | -16.1 | -0.6 | 0 | 0.00/0.27 | 4253 | 0 0 3 84 13 |  |
| knopf.ogg | 0.42 | 1×44k | 7 | -24.7 | -1.2 | 0 | 0.00/0.25 | 1442 | 6 3 78 13 0 |  |
| knopf_gold1.ogg | 0.48 | 1×44k | 8 | -22.0 | -0.9 | 0 | 0.00/0.11 | 5678 | 7 2 12 33 47 |  |
| knopf_gold2.ogg | 0.38 | 1×44k | 7 | -70.0 | -0.7 | 0 | 0.01/0.23 | 6359 | 2 1 14 26 58 |  |
| koerper_fall1.ogg | 0.57 | 1×44k | 9 | -20.0 | -1.3 | 0 | 0.07/0.14 | 404 | 46 42 7 5 0 |  |
| koerper_fall2.ogg | 0.65 | 1×44k | 9 | -23.5 | -1.0 | 0 | 0.01/0.21 | 783 | 30 43 14 12 1 |  |
| koerper_fall3.ogg | 0.90 | 1×44k | 11 | -26.2 | -1.1 | 0 | 0.00/0.16 | 1934 | 12 28 26 28 6 |  |
| koloss_tod1.ogg | 1.19 | 1×44k | 13 | -21.8 | -1.1 | 0 | 0.00/0.06 | 915 | 4 25 61 9 0 |  |
| koloss_tod2.ogg | 1.34 | 1×44k | 15 | -17.5 | -1.0 | 0 | 0.02/0.06 | 591 | 53 17 20 9 1 |  |
| koloss_wach1.ogg | 1.76 | 1×44k | 18 | -15.4 | -2.6 | 0 | 0.00/0.04 | 479 | 19 29 51 0 0 |  |
| koloss_wach2.ogg | 1.76 | 1×44k | 18 | -15.4 | -0.7 | 0 | 0.00/0.17 | 444 | 20 63 15 1 1 |  |
| krieger_tod1.ogg | 1.15 | 1×44k | 14 | -16.4 | -2.6 | 0 | 0.02/0.13 | 1068 | 6 25 62 6 1 |  |
| krieger_tod2.ogg | 1.34 | 1×44k | 15 | -16.4 | -2.2 | 0 | 0.12/0.21 | 1073 | 5 16 74 4 1 |  |
| krieger_wach1.ogg | 1.18 | 1×44k | 14 | -17.4 | -0.9 | 0 | 0.17/0.10 | 1418 | 2 12 64 21 1 |  |
| krieger_wach2.ogg | 1.10 | 1×44k | 13 | -16.8 | -1.0 | 0 | 0.02/0.07 | 1302 | 1 10 73 16 0 |  |
| legendary.ogg | 2.46 | 1×44k | 22 | -16.1 | -1.6 | 0 | 0.00/0.30 | 2815 | 0 55 0 34 10 |  |
| meteor.ogg | 2.22 | 1×44k | 21 | -13.6 | -4.2 | 0 | 0.01/0.36 | 3639 | 0 0 0 92 8 |  |
| mus_a1_grund.ogg | 50.53 | 1×32k | 362 | -24.0 | -8.9 | 0 | 0.00/0.00 | 802 | 7 12 80 1 0 | +7.0 dB / 0.15 **prüfen** |
| mus_a1_kampf.ogg | 50.53 | 1×32k | 409 | -19.0 | -1.3 | 0 | 0.00/0.00 | 271 | 61 24 15 0 0 | +3.0 dB / 0.22 ok |
| mus_a1_melodie.ogg | 50.53 | 1×32k | 350 | -19.5 | -6.4 | 0 | 0.02/4.90 | 497 | 1 76 22 1 0 | +0.0 dB / 0.00 ok |
| mus_a1_nachklang.ogg | 14.29 | 1×32k | 100 | -21.2 | -7.9 | 0 | 0.02/2.86 | 448 | 1 75 24 0 0 | +0.0 dB / 0.00 ok |
| mus_a1_spannung.ogg | 50.53 | 1×32k | 378 | -24.2 | -5.9 | 0 | 0.00/0.00 | 407 | 54 15 28 3 0 | +10.8 dB / 0.65 **prüfen** |
| mus_a2_grund.ogg | 64.00 | 1×32k | 443 | -23.4 | -8.7 | 0 | 0.00/0.00 | 648 | 4 25 69 1 0 | +3.2 dB / 0.11 **prüfen** |
| mus_a2_kampf.ogg | 64.00 | 1×32k | 496 | -19.1 | -1.1 | 0 | 0.00/0.00 | 266 | 62 24 13 0 0 | +9.7 dB / 0.45 **prüfen** |
| mus_a2_melodie.ogg | 64.00 | 1×32k | 471 | -20.6 | -4.9 | 0 | 0.01/2.20 | 700 | 0 48 47 4 0 | +0.0 dB / 0.00 ok |
| mus_a2_nachklang.ogg | 16.86 | 1×32k | 119 | -21.2 | -6.3 | 0 | 0.03/2.97 | 565 | 2 56 40 3 0 | +0.0 dB / 0.00 ok |
| mus_a2_spannung.ogg | 64.00 | 1×32k | 454 | -24.8 | -5.8 | 0 | 0.00/0.00 | 390 | 30 50 18 2 0 | +19.3 dB / 0.04 **prüfen** |
| mus_a3_grund.ogg | 43.64 | 1×32k | 306 | -24.5 | -9.1 | 0 | 0.00/0.00 | 463 | 7 56 36 1 0 | +5.2 dB / 0.13 **prüfen** |
| mus_a3_kampf.ogg | 43.64 | 1×32k | 357 | -17.7 | -1.2 | 0 | 0.00/0.00 | 236 | 64 24 12 0 0 | +7.0 dB / 0.20 **prüfen** |
| mus_a3_melodie.ogg | 43.64 | 1×32k | 330 | -19.6 | -6.5 | 0 | 0.00/2.70 | 675 | 0 24 74 2 0 | +0.0 dB / 0.00 ok |
| mus_a3_nachklang.ogg | 13.00 | 1×32k | 92 | -21.3 | -6.8 | 0 | 0.03/2.83 | 497 | 1 75 23 1 0 | +0.0 dB / 0.00 ok |
| mus_a3_spannung.ogg | 43.64 | 1×32k | 322 | -23.7 | -7.7 | 0 | 0.00/0.00 | 275 | 57 22 20 1 0 | +10.6 dB / 0.19 **prüfen** |
| mus_hueter_grund.ogg | 40.00 | 1×32k | 273 | -23.5 | -2.5 | 0 | 0.00/0.00 | 316 | 33 51 16 0 0 | +11.7 dB / 0.09 **prüfen** |
| mus_hueter_p1.ogg | 40.00 | 1×32k | 327 | -21.1 | -3.4 | 0 | 0.00/0.00 | 257 | 49 37 14 0 0 | +7.3 dB / 0.35 **prüfen** |
| mus_hueter_p2.ogg | 40.00 | 1×32k | 305 | -23.1 | -6.3 | 0 | 0.00/0.00 | 847 | 35 6 56 2 0 | +2.9 dB / 0.90 ok |
| mus_hueter_p3.ogg | 40.00 | 1×32k | 326 | -21.5 | -4.8 | 0 | 0.00/0.00 | 271 | 72 15 12 1 0 | -1.3 dB / 0.16 ok |
| mus_titel.ogg | 58.18 | 1×32k | 427 | -18.8 | -4.8 | 0 | 0.00/0.00 | 511 | 1 71 27 1 0 | -3.5 dB / 1.63 **prüfen** |
| priesterin_tod1.ogg | 1.46 | 1×44k | 15 | -16.2 | -3.8 | 0 | 0.00/0.26 | 1547 | 0 1 91 8 0 |  |
| priesterin_tod2.ogg | 1.48 | 1×44k | 15 | -16.5 | -3.5 | 0 | 0.00/0.12 | 1239 | 0 1 95 3 0 |  |
| priesterin_wach1.ogg | 1.17 | 1×44k | 14 | -16.1 | -1.4 | 0 | 0.02/0.16 | 2269 | 0 1 55 43 2 |  |
| priesterin_wach2.ogg | 1.20 | 1×44k | 14 | -16.0 | -3.2 | 0 | 0.03/0.08 | 2163 | 0 1 44 55 0 |  |
| scherben1.ogg | 0.57 | 1×44k | 9 | -22.0 | -1.0 | 0 | 0.00/0.06 | 5309 | 1 3 3 68 26 |  |
| scherben2.ogg | 0.55 | 1×44k | 8 | -24.4 | -1.3 | 0 | 0.00/0.09 | 5110 | 1 2 4 65 28 |  |
| schmerz_m1.ogg | 0.39 | 1×44k | 7 | -70.0 | -1.0 | 0 | 0.00/0.11 | 1076 | 1 44 44 9 2 |  |
| schmerz_m2.ogg | 0.42 | 1×44k | 7 | -16.5 | -0.9 | 0 | 0.01/0.08 | 1163 | 1 18 69 9 2 |  |
| schmerz_m3.ogg | 0.31 | 1×44k | 6 | -70.0 | -1.1 | 0 | 0.00/0.07 | 1085 | 1 26 63 9 2 |  |
| schmerz_w1.ogg | 0.62 | 1×44k | 9 | -18.3 | -1.2 | 0 | 0.00/0.30 | 2065 | 0 8 53 35 4 |  |
| schmerz_w2.ogg | 0.60 | 1×44k | 9 | -19.1 | -0.9 | 0 | 0.00/0.05 | 1367 | 1 41 43 14 2 |  |
| schmerz_w3.ogg | 0.32 | 1×44k | 7 | -70.0 | -1.0 | 0 | 0.00/0.08 | 953 | 0 45 48 6 1 |  |
| sternfunke1.ogg | 0.80 | 1×44k | 11 | -17.5 | -1.0 | 0 | 0.00/0.11 | 10467 | 0 0 0 11 88 |  |
| sternfunke2.ogg | 0.80 | 1×44k | 11 | -16.9 | -1.1 | 0 | 0.00/0.06 | 6366 | 0 0 0 69 31 |  |
| sternfunke3.ogg | 0.80 | 1×44k | 11 | -18.7 | -1.0 | 0 | 0.00/0.15 | 8298 | 0 0 0 29 71 |  |
| sterntreffer1.ogg | 0.80 | 1×44k | 11 | -16.4 | -0.1 | 0 | 0.00/0.07 | 8686 | 0 0 0 40 59 |  |
| sterntreffer2.ogg | 0.80 | 1×44k | 11 | -16.5 | 0.5 | 0 | 0.00/0.07 | 10517 | 0 0 0 17 83 |  |
| sterntreffer3.ogg | 0.80 | 1×44k | 12 | -16.0 | -1.2 | 0 | 0.00/0.07 | 10506 | 0 0 0 16 84 |  |
| stufe.ogg | 2.27 | 1×44k | 24 | -17.2 | -4.6 | 0 | 0.01/0.40 | 1428 | 0 0 92 5 3 |  |
| tod_w.ogg | 1.48 | 1×44k | 16 | -17.1 | -1.1 | 0 | 0.00/0.14 | 1419 | 0 8 81 10 1 |  |
| ui.ogg | 0.42 | 1×44k | 7 | -24.7 | -1.2 | 0 | 0.00/0.25 | 1442 | 6 3 78 13 0 |  |
| windstoss1.ogg | 0.93 | 1×44k | 11 | -19.7 | -0.9 | 0 | 0.03/0.05 | 741 | 0 8 90 1 0 |  |
| windstoss2.ogg | 1.00 | 1×44k | 11 | -20.0 | -1.0 | 0 | 0.00/0.05 | 791 | 19 20 56 4 1 |  |
