// 06 · Zeichnen in Schrägansicht. Boden und Bodenmarken liegen in der Weltebene (GT),
// alles Stehende (Figuren, Felsen, Beute) wird am Fußpunkt aufgerichtet gezeichnet (UT) und nach Tiefe sortiert.
let VIG = null, VIGK = "";
function vignette() {
  const mood = st.def.mood, k = mood + view.w + "x" + view.h; if (VIG && VIGK === k) return VIG;
  const c = VIG || document.createElement("canvas"); c.width = Math.round(view.w / 2); c.height = Math.round(view.h / 2); const x = c.getContext("2d"), w = c.width, h = c.height;
  x.clearRect(0, 0, w, h); x.fillStyle = `rgba(${{ dust: "60,95,160", ember: "190,95,30", glass: "30,160,150" }[mood] || "60,95,160"},0.1)`; x.fillRect(0, 0, w, h);
  const vg = x.createRadialGradient(w / 2, h * 0.47, Math.min(w, h) * 0.3, w / 2, h * 0.47, Math.hypot(w, h) * 0.6); vg.addColorStop(0, "rgba(0,0,0,0)"); vg.addColorStop(1, "rgba(2,3,8,0.62)"); x.fillStyle = vg; x.fillRect(0, 0, w, h);
  VIG = c; VIGK = k; return c;
}
// Auflösung passt sich an: ruckelt es, wird mit weniger Bildpunkten gezeichnet, läuft es flüssig, wieder mit mehr
// Grafikstufen: 2 hoch, 1 mittel, 0 niedrig. „Automatisch“ misst die Bildzeit und stuft selbst ab oder auf.
// Niedrig spart alles, was auf schwachen oder ohne Grafikkarte zeichnenden Rechnern teuer ist: Nebel, Schein, Staub, Mauertextur, Bildschärfe.
const GFX = [{ name: "Niedrig", rs: 0.6, lq: 0.3, motes: 0, mist: false, bloom: false, walls: false },
             { name: "Mittel", rs: 0.8, lq: 0.4, motes: 25, mist: false, bloom: true, walls: true },
             { name: "Hoch", rs: 1, lq: 0.5, motes: 70, mist: true, bloom: true, walls: true }];
let GQ = 2, GMODE = "auto", LQ = 0.5, RS = 1, FT = 16, FPS = 60;
try { const v = localStorage.getItem("akte-nebelmark-gfx"); if (v && (v === "auto" || GFX[+v])) GMODE = v; } catch (e) { /* ohne Speicher */ }
function setGfx(mode) { GMODE = mode; if (mode !== "auto") GQ = +mode; RS = GFX[GQ].rs; LQ = GFX[GQ].lq; try { localStorage.setItem("akte-nebelmark-gfx", mode); } catch (e) { /* egal */ } resize(); }
function adapt(dt) {
  FT = FT * 0.95 + dt * 1000 * 0.05; FPS = Math.round(1000 / FT);
  if ((adapt.cool = (adapt.cool || 0) - dt) > 0 || paused) return;
  if (FT > 26) {   // zu langsam: erst schärfe runter, dann Effekte weg
    if (RS > GFX[GQ].rs * 0.75 + 0.01) { RS = Math.max(GFX[GQ].rs * 0.75, RS - 0.15); adapt.cool = 0.7; resize(); }
    else if (GMODE === "auto" && GQ > 0) { GQ--; RS = GFX[GQ].rs; LQ = GFX[GQ].lq; adapt.cool = 1.2; resize(); }
  } else if (FT < 17.5) {
    if (RS < GFX[GQ].rs - 0.01) { RS = Math.min(GFX[GQ].rs, RS + 0.05); adapt.cool = 2; resize(); }
    else if (GMODE === "auto" && GQ < 2 && (adapt.calm = (adapt.calm || 0) + 1) > 4) { GQ++; RS = GFX[GQ].rs * 0.8; LQ = GFX[GQ].lq; adapt.calm = 0; adapt.cool = 3; resize(); }
  }
}
if (GMODE !== "auto") { GQ = +GMODE; RS = GFX[GQ].rs; LQ = GFX[GQ].lq; }
function resize() {
  const r = cv.getBoundingClientRect(); view.w = Math.max(200, r.width); view.h = Math.max(200, r.height); view.dpr = Math.min(1.5, window.devicePixelRatio || 1) * RS;
  view.zoom = clamp(Math.min(view.w / 900, view.h / 620), 0.62, 1.2);
  cv.width = Math.round(view.w * view.dpr); cv.height = Math.round(view.h * view.dpr); lc.width = Math.round(cv.width * LQ); lc.height = Math.round(cv.height * LQ);
}
const GT = (c, z, sx, sy) => c.setTransform(ISO * z, ISO * 0.5 * z, -ISO * z, ISO * 0.5 * z, -view.ox * z + sx, -view.oy * z + sy);
const UT = (c, z, sx, sy) => c.setTransform(z, 0, 0, z, -view.ox * z + sx, -view.oy * z + sy);
function poly(c, x, y, r, n, rot) { c.beginPath(); for (let i = 0; i < n; i++) { const a = rot + i / n * TAU; c[i ? "lineTo" : "moveTo"](x + Math.cos(a) * r, y + Math.sin(a) * r); } c.closePath(); }
function shape(col, pts) { g.fillStyle = col; g.beginPath(); for (let i = 0; i < pts.length; i += 2) g[i ? "lineTo" : "moveTo"](pts[i], pts[i + 1]); g.closePath(); g.fill(); }
// Weiche Flecken werden einmal vorgezeichnet und danach nur noch gestempelt: das spart in jedem Bild Dutzende Farbverläufe
const BLOBS = {};
function blob(col, stops) {
  const key = col + stops; if (BLOBS[key]) return BLOBS[key];
  const c = document.createElement("canvas"); c.width = c.height = 128; const x = c.getContext("2d"), gr = x.createRadialGradient(64, 64, 0, 64, 64, 64);
  (stops || [[0, 1], [1, 0]]).forEach(([o, a]) => gr.addColorStop(o, `rgba(${col},${a})`)); x.fillStyle = gr; x.fillRect(0, 0, 128, 128); return (BLOBS[key] = c);
}
const hexRgb = (h) => { const n = parseInt(h.slice(1), 16); return `${n >> 16},${n >> 8 & 255},${n & 255}`; };
function light(x, y, r, a) { lg.globalAlpha = Math.min(1, a); lg.drawImage(blob("0,0,0"), x - r, y - r, 2 * r, 2 * r); lg.globalAlpha = 1; }
const shadeCache = {};
function shade(hex, k) { const key = hex + k; if (shadeCache[key]) return shadeCache[key]; const n = parseInt(hex.slice(1), 16), f = (v) => Math.round(clamp(k < 1 ? v * k : v + (255 - v) * (k - 1), 0, 255)); return (shadeCache[key] = `rgb(${f(n >> 16)},${f(n >> 8 & 255)},${f(n & 255)})`); }
// Blickrichtung im Bild aus einem Winkel in der Welt
function faceOf(a) { const c = Math.cos(a), s = Math.sin(a), x = c - s, y = (c + s) * 0.5, l = Math.hypot(x, y) || 1; return { x: x / l, y: y / l }; }

// ---------- Bilder ----------
const IMG = {};
function img(src) { let m = IMG[src]; if (!m) { m = IMG[src] = new Image(); m.src = src; } return m.complete && m.naturalWidth ? m : null; }
// Lebendigkeit ohne zusätzliche Bilder: beim Gehen wiegt sich die Figur im Schritt und neigt sich in die Laufrichtung,
// im Stand atmet sie, beim Angriff lehnt sie sich nach vorn. Alles um den Fußpunkt, damit die Füße stehen bleiben.
function pose(bx, by, f, state, phase, speed) {
  let rot = 0, sy = 1, sx = 1, dy = 0;
  if (state === "walk") { const s = Math.sin(phase * Math.PI); rot = f.x * 0.06 * speed + Math.sin(phase * Math.PI * 2) * 0.025; dy = -Math.abs(s) * 2.2; sy = 1 + Math.abs(s) * 0.02; sx = 1 - Math.abs(s) * 0.012; }
  else if (state === "attack") { rot = f.x * 0.08; sx = 1.03; }
  else { sy = 1 + Math.sin(st.t * 2.2 + bx * 0.01) * 0.012; }
  g.translate(bx, by + dy); g.rotate(rot); g.scale(sx, sy); g.translate(-bx, -by);
}
// Figur aus einem Bildbogen: Zelle je nach Blick und Zustand, Füße auf (bx, by). Liefert false, wenn das Bild fehlt.
function sprite(key, bx, by, tall, f, state, white, phase, speed) {
  const S = ART.sprite[key]; if (!S) return false; const m = img(S.src); if (!m) return false;
  const C = S.cells, away = f.y < -0.2 && C.back;
  const ph = phase === undefined ? st.t * 2.6 : phase, cell = state === "down" && C.down ? C.down : away ? C.back : state === "attack" && C.attack ? C.attack : state === "walk" && C.walk && Math.floor(ph) % 2 ? C.walk : C.front;
  const k = tall / S.tall, w = cell[2] * k, hh = cell[3] * k, ax = cell[4] === undefined ? 0.5 : cell[4];
  g.save(); if (state !== "down") pose(bx, by, f, state, ph, speed === undefined ? 1 : speed); g.translate(bx, by); if (f.x < 0) g.scale(-1, 1);
  g.drawImage(m, cell[0], cell[1], cell[2], cell[3], -w * ax, -hh, w, hh);
  if (white) { g.globalCompositeOperation = "lighter"; g.globalAlpha *= 0.7; g.drawImage(m, cell[0], cell[1], cell[2], cell[3], -w * ax, -hh, w, hh); g.globalCompositeOperation = "source-over"; }
  g.restore(); return true;
}
function prop(key, bx, by, wide) {
  const P = ART.prop[key]; if (!P) return false; const m = img(P.src); if (!m) return false;
  const k = wide / P.box[2], w = P.box[2] * k, hh = P.box[3] * k;
  g.drawImage(m, P.box[0], P.box[1], P.box[2], P.box[3], bx - w / 2, by - hh * (P.foot || 0.88), w, hh); return true;
}
const GLOW = { needle0: ["#5fe0d6", 120, 1.1], needle1: ["#5fe0d6", 70, 0.4], tomb2: ["#ff9a3c", 150, 0.9], tomb5: ["#ffd070", 90, 0.5], star1: ["#4fe6dc", 130, 1], star2: ["#6fd6ff", 110, 1], star3: ["#8fe3e0", 140, 0.8], star4: ["#5fe0d6", 100, 0.2], star6: ["#9ff0e0", 90, 0.4], camp5: ["#ffb060", 130, 1.2], camp4: ["#ff9a3c", 120, 0.4] };
Object.assign(GLOW, { fire0: ["#ff9a3c", 210, 0.5], d2: ["#ff9a3c", 190, 1.1], d12: ["#ffb060", 170, 1.6], d15: ["#4fe6dc", 130, 1], d5: ["#ffd070", 110, 0.5] });
const glowOf = (o) => o.kind === "chest" ? (o.open || o.tier === 2 ? GLOW.d5 : null) : GLOW[o.kind + o.v];
// Mauern: jede Mauerzelle am Rand eines Raums ist ein Block mit Deckfläche und bis zu zwei sichtbaren Seiten
let DZ = 1, DSX = 0, DSY = 0;
const PATS = {};
function wallFill() {
  const key = st.def.wall || "T03", src = GFX[GQ].walls && ART.tex[key], m = src && img(src); if (!m) return st.pal.rock;
  if (!PATS[key]) { PATS[key] = g.createPattern(m, "repeat"); try { PATS[key].setTransform(new DOMMatrix().scale(200 / m.naturalWidth)); } catch (e) { /* ohne Skalierung */ } }
  return PATS[key];
}
// Eine Mauerseite als Parallelogramm: dir 1 = Seite nach vorn links (entlang +x), dir -1 = Seite nach vorn rechts (entlang -y)
function wallFace(wx, wy, dir, off, H, base, w, deco) {
  g.setTransform(DZ * ISO, dir * DZ * ISO * 0.5, 0, DZ, (px(wx, wy) - view.ox) * DZ + DSX, (py(wx, wy) - view.oy) * DZ + DSY);
  g.translate(-off, 0); g.fillStyle = wallFill(); g.fillRect(off, -H, w, H - base); g.fillStyle = dir > 0 ? (st.indoor ? "rgba(3,4,10,.42)" : "rgba(3,4,10,.26)") : (st.indoor ? "rgba(3,4,10,.12)" : "rgba(3,4,10,0)"); g.fillRect(off, -H, w, H - base);
  if (!base) { g.fillStyle = "rgba(0,0,0,.4)"; g.fillRect(off, -7, w, 7); } g.fillStyle = "rgba(255,255,255,.07)"; g.fillRect(off, -H, w, 2);
  if (deco === "banner" && H > 70) {   // Tempelbanner: dunkelrotes Tuch mit goldenem Auge, unten gezackt
    const x = off + w * 0.2, bw = w * 0.6, y = -H + 10; g.fillStyle = "#3a2a16"; g.fillRect(x - 3, y - 3, bw + 6, 3);
    g.fillStyle = st.indoor ? "#5e1c1a" : "#6a2420"; g.beginPath(); g.moveTo(x, y); g.lineTo(x + bw, y); g.lineTo(x + bw, y + 46); g.lineTo(x + bw / 2, y + 36); g.lineTo(x, y + 46); g.closePath(); g.fill();
    g.strokeStyle = "#d8b04a"; g.lineWidth = 1.5; g.beginPath(); g.ellipse(x + bw / 2, y + 17, bw * 0.26, 5, 0, 0, TAU); g.stroke(); g.fillStyle = "#d8b04a"; g.beginPath(); g.arc(x + bw / 2, y + 17, 2.2, 0, TAU); g.fill();
  } else if (deco === "slit" && H > 70) { g.fillStyle = "rgba(0,0,0,.75)"; g.fillRect(off + w / 2 - 3, -H + 26, 6, 30); }
}
function wallTop(x, y, w, d, H, dark) {
  g.setTransform(ISO * DZ, ISO * 0.5 * DZ, -ISO * DZ, ISO * 0.5 * DZ, -view.ox * DZ + DSX, (-view.oy - H) * DZ + DSY);
  g.fillStyle = wallFill(); g.fillRect(x, y, w, d); g.fillStyle = `rgba(3,4,10,${dark})`; g.fillRect(x, y, w, d);
}
function drawWall(o) {
  const cx = o.cx, cy = o.cy, i = gi(cx, cy), h = hero, C = CELL, H0 = st.wh[i], dk = st.deco[i], dy = py(o.x, o.y) - py(h.x, h.y);
  // hohe Mauern, hinter denen die Figur steht, schrumpfen auf einen Sockel, damit sie sichtbar bleibt
  const low = H0 > 30 && (cx + cy + 1) * C > h.x + h.y && Math.abs(px(o.x, o.y) - px(h.x, h.y)) < 150 && dy < 180 && dy > -40, H = low ? 18 : H0;
  const nl = Math.min(H, cellH(cx, cy + 1) === TOWER ? H : cellH(cx, cy + 1)), nr = Math.min(H, cellH(cx + 1, cy) === TOWER ? H : cellH(cx + 1, cy));
  if (nl < H) wallFace(cx * C, (cy + 1) * C, 1, (cx % 4) * C, H, nl, C, dk & 1 ? "banner" : !st.indoor && (cx * 7 + cy) % 5 === 0 ? "slit" : "");
  if (nr < H) wallFace((cx + 1) * C, (cy + 1) * C, -1, ((GH - cy) % 4) * C, H, nr, C, dk & 2 ? "banner" : !st.indoor && (cy * 7 + cx) % 5 === 0 ? "slit" : "");
  if (st.indoor) { g.setTransform(ISO * DZ, ISO * 0.5 * DZ, -ISO * DZ, ISO * 0.5 * DZ, -view.ox * DZ + DSX, (-view.oy - H) * DZ + DSY); g.fillStyle = "#15131a"; g.fillRect(cx * C, cy * C, C + 0.5, C + 0.5); }
  else wallTop(cx * C, cy * C, C, C, H, 0.34);
  if (dk & 4 && !low && (cx + cy) % 2 === 0) {   // Zinne
    const m = 9, Z = H + 15; wallFace(cx * C + m, (cy + 1) * C - m, 1, 0, Z, H, C - 2 * m, ""); wallFace((cx + 1) * C - m, (cy + 1) * C - m, -1, 0, Z, H, C - 2 * m, ""); wallTop(cx * C + m, cy * C + m, C - 2 * m, C - 2 * m, Z, 0.3);
  }
  UT(g, DZ, DSX, DSY);
}
// Turm: vier Zellen breit, mit Zinnenkranz und spitzem Dach. Steht die Figur dahinter, wird er durchscheinend.
function drawTower(t) {
  const C = CELL, x0 = t.cx * C, y0 = t.cy * C, n = t.n * C, H = t.h, h = hero, behind = h.x + h.y < t.x + t.y + n && Math.abs(px(h.x, h.y) - px(t.x, t.y)) < 190 && py(t.x, t.y) - py(h.x, h.y) < 320 && py(t.x, t.y) - py(h.x, h.y) > -60;
  g.globalAlpha = behind ? 0.35 : 1;
  wallFace(x0, y0 + n, 1, 0, H, 0, n, "slit"); wallFace(x0 + n, y0 + n, -1, 0, H, 0, n, "slit"); wallTop(x0, y0, n, n, H, 0.4);
  for (let k = 0; k < t.n; k += 2) { wallFace(x0 + k * C, y0 + n, 1, 0, H + 16, H, C, ""); wallFace(x0 + n, y0 + n - k * C, -1, 0, H + 16, H, C, ""); }
  UT(g, DZ, DSX, DSY);
  const L = [px(x0 + 20, y0 + n - 20), py(x0 + 20, y0 + n - 20) - H - 4], F = [px(x0 + n - 20, y0 + n - 20), py(x0 + n - 20, y0 + n - 20) - H - 4], R = [px(x0 + n - 20, y0 + 20), py(x0 + n - 20, y0 + 20) - H - 4], A = [px(t.x, t.y), py(t.x, t.y) - H - 150];
  shape("#232836", [L[0], L[1], F[0], F[1], A[0], A[1]]); shape("#343c50", [F[0], F[1], R[0], R[1], A[0], A[1]]);
  g.strokeStyle = "#d8b04a"; g.lineWidth = 2; g.beginPath(); g.moveTo(A[0], A[1]); g.lineTo(A[0], A[1] - 16); g.stroke(); shape("#6a2420", [A[0], A[1] - 16, A[0] + 16, A[1] - 11, A[0], A[1] - 6]);
  g.globalAlpha = 1;
}
function flame(x, y, s, seed) {
  const f = 0.85 + 0.15 * Math.sin(st.t * 11 + seed) + 0.06 * Math.sin(st.t * 23 + seed * 2), gr = g.createRadialGradient(x, y, 0, x, y - s * 0.5, s * 1.5 * f);
  gr.addColorStop(0, "#fff4c4"); gr.addColorStop(0.35, "#ffb23e"); gr.addColorStop(0.75, "rgba(214,72,24,.75)"); gr.addColorStop(1, "rgba(120,20,10,0)");
  g.fillStyle = gr; g.beginPath(); g.moveTo(x - s * 0.55, y); g.quadraticCurveTo(x - s * 0.7, y - s * 0.9 * f, x + Math.sin(st.t * 7 + seed) * s * 0.25, y - s * 2.1 * f); g.quadraticCurveTo(x + s * 0.7, y - s * 0.9 * f, x + s * 0.55, y); g.closePath(); g.fill();
}
// Wandfackel: Eisenhalter an der Mauer, Flamme darüber
// Scheintür: Durch sie gehen die Toten zwischen den Welten. Sie wächst aus dem Boden, sobald der Hüter der Stunde gefallen ist.
function drawGate(p, bx, by) {
  const k = clamp(p.t / 1.4, 0, 1), w = 30, hh = 108 * k, top = by - hh; if (hh < 4) return;
  const gr = g.createLinearGradient(0, top, 0, by); gr.addColorStop(0, "#f4fffd"); gr.addColorStop(0.55, "#8fe3e0"); gr.addColorStop(1, "rgba(143,227,224,.3)");
  g.globalAlpha = 0.72 + 0.2 * Math.sin(st.t * 3) ** 2; g.fillStyle = gr; g.fillRect(bx - w, top, w * 2, hh);
  g.save(); g.beginPath(); g.rect(bx - w, top, w * 2, hh); g.clip(); g.strokeStyle = "#fff"; g.lineWidth = 2;
  for (let i = 0; i < 3; i++) { g.globalAlpha = 0.55 - i * 0.15; g.beginPath(); g.ellipse(bx, by - hh * 0.46, 7 + i * 8 + Math.sin(st.t * 4 + i) * 3, hh * (0.2 + i * 0.11), 0, 0, TAU); g.stroke(); }
  g.restore(); g.globalAlpha = 1;
  g.fillStyle = "#4d483e"; g.fillRect(bx - w - 14, top, 14, hh); g.fillRect(bx + w, top, 14, hh);                 // Pfosten
  g.fillStyle = "#38342c"; g.fillRect(bx - w - 5, top, 5, hh); g.fillRect(bx + w, top, 5, hh);                    // innere Laibung
  g.fillStyle = "#5b554a"; g.fillRect(bx - w - 14, top - 15, w * 2 + 28, 15);                                    // Sturz
  g.fillStyle = "#70695b"; g.beginPath(); g.moveTo(bx - w - 14, top - 15); g.lineTo(bx - w - 22, top - 27); g.lineTo(bx + w + 22, top - 27); g.lineTo(bx + w + 14, top - 15); g.fill();   // Hohlkehle
  g.fillStyle = "#e8b04a"; g.beginPath(); g.arc(bx, top - 8, 4.5, 0, TAU); g.fill();                              // geflügelte Sonnenscheibe
  g.beginPath(); g.moveTo(bx - 6, top - 9); g.lineTo(bx - 27, top - 11); g.lineTo(bx - 20, top - 5); g.lineTo(bx - 6, top - 6); g.moveTo(bx + 6, top - 9); g.lineTo(bx + 27, top - 11); g.lineTo(bx + 20, top - 5); g.lineTo(bx + 6, top - 6); g.fill();
}
function drawSconce(o, bx, by) {
  const y = by - 52; g.strokeStyle = "#1b1c22"; g.lineWidth = 3; g.lineCap = "round"; g.beginPath(); g.moveTo(bx - 5, y + 16); g.lineTo(bx + 2, y + 9); g.lineTo(bx + 2, y - 2); g.stroke();
  g.fillStyle = "#2a2b33"; g.fillRect(bx - 3, y - 6, 10, 7); flame(bx + 2, y - 6, 8, o.x + o.y);
}
let texPat = null, texKey = null;
function groundFill() {
  let key = st.def.tex, src = ART.tex[key]; if (!src) { key = "T01"; src = ART.tex[key]; }
  const m = src && img(src); if (!m) return st.pal.ground; st.tint = key !== st.def.tex;
  if (texKey !== key) { texPat = g.createPattern(m, "repeat"); try { texPat.setTransform(new DOMMatrix().scale(560 / m.naturalWidth)); } catch (e) { /* ältere Browser: ohne Skalierung */ } texKey = key; }
  return texPat;
}

// ---------- Platzhalter-Figuren aus wenigen Flächen ----------
// weicher Schatten: Licht fällt von links oben, darum liegt er leicht nach rechts unten versetzt und läuft nach außen aus
function shadow(bx, by, r) { const R = r * 1.35, ga = g.globalAlpha; g.drawImage(blob("0,0,0", [[0, 0.55], [0.55, 0.28], [1, 0]]), bx + r * 0.3 - R, by - R * 0.42, 2 * R, 2 * R * 0.42); g.globalAlpha = ga; }
// Platzhalter-Mensch: Kopf, Rumpf, Arme und Beine. Die Beine schreiten, die Arme schwingen mit, der vordere Arm hält die Waffe.
function pawn(bx, by, r, col, o = {}) {
  const H = r * (o.tall || 2.9), w = r * (o.w || 0.78) * 0.72, f = o.f || { x: 0.7, y: 0.7 }, hr = r * (o.head || 0.44) * 0.8, shY = by - H * 0.74, hipY = by - H * 0.42, hy = shY - hr * 1.05, hipW = w * 0.62;
  const skin = o.skin || "#d6ad88", hair = o.hair || shade(col, 0.5), dark = shade(col, 0.6), ph = o.walk ? Math.sin(st.t * 10 + (o.seed || 0)) : 0, stride = H * 0.13 * ph, side = f.x >= 0 ? 1 : -1;
  g.lineCap = "round"; g.lineJoin = "round";
  g.strokeStyle = shade(col, 0.42); g.lineWidth = Math.max(2.5, w * 0.44);
  for (const s of [-1, 1]) {   // Beine mit Knie
    const k = s * stride, lift = Math.max(0, -s * ph) * H * 0.05;
    g.beginPath(); g.moveTo(bx + s * hipW * 0.5, hipY); g.lineTo(bx + s * hipW * 0.5 + f.x * (k * 0.5 + Math.abs(k) * 0.35), hipY + (by - hipY) * 0.5 + f.y * k * 0.25); g.lineTo(bx + s * hipW * 0.45 + f.x * k, by + f.y * k * 0.5 - lift); g.stroke();
  }
  const arm = (s, hx, hy2) => { g.strokeStyle = s > 0 ? dark : shade(col, 0.85); g.lineWidth = Math.max(2.2, w * 0.38); g.beginPath(); g.moveTo(bx + s * w * 0.95, shY + 2); g.lineTo(hx, hy2); g.stroke(); g.fillStyle = skin; g.beginPath(); g.arc(hx, hy2, Math.max(1.6, w * 0.22), 0, TAU); g.fill(); };
  arm(-side, bx - side * w * 1.1 - f.x * stride * 0.7, hipY + 1 - f.y * stride * 0.35);
  shape(col, [bx - w, shY, bx, shY - 1.5, bx, hipY + H * 0.1, bx - hipW, hipY + H * 0.08]);   // Rumpf mit kurzem Rock, rechte Seite im Schatten
  shape(dark, [bx, shY - 1.5, bx + w, shY, bx + hipW, hipY + H * 0.08, bx, hipY + H * 0.1]);
  g.fillStyle = shade(col, 0.38); g.fillRect(bx - hipW * 0.95, hipY - 2, hipW * 1.9, 2.5);
  arm(side, bx + f.x * w * 1.25, hipY + f.y * r * 0.3);
  g.fillStyle = f.y < -0.2 ? hair : skin; g.beginPath(); g.arc(bx, hy, hr, 0, TAU); g.fill();
  if (f.y >= -0.2) {   // Gesicht zum Betrachter: Haar oder Haube oben, zwei Augen
    g.fillStyle = hair; g.beginPath(); g.arc(bx, hy, hr, Math.PI * 1.02 - f.x * 0.5, Math.PI * 1.98 - f.x * 0.5); g.closePath(); g.fill();
    g.fillStyle = o.eyes || "#1a1410"; g.fillRect(bx + f.x * hr * 0.4 - hr * 0.42, hy + hr * 0.1, 1.4, 1.4); g.fillRect(bx + f.x * hr * 0.4 + hr * 0.22, hy + hr * 0.1, 1.4, 1.4);
  }
  return { H, top: shY, hy, hr, w: w * 1.25 };
}
const foeTall = (e) => e.r * (e.type === "boss" ? 4.4 : ({ skorp: 5.2, giant: 5.6 })[e.look || ET[e.type].look] || 6.2);
const SPRITE_OF = { skorp: "G07", snake: "G01", seer: "G02", giant: "G03", guard: "G04", grey: "G05", demon: "G06", sammler: "B01", mutter: "B02", koenig: "B03" };
const spriteKey = (e) => SPRITE_OF[e.look || ET[e.type].look];
function drawDead(d, bx, by) { g.globalAlpha = clamp(9 - d.t, 0, 1) * 0.9; sprite(d.key, bx, by + 4, d.tall, faceOf(d.face), "down"); g.globalAlpha = 1; }
function drawFoe(e, bx, by, h) {
  const T = ET[e.type], look = e.look || T.look, fl = e.flash > 0, col = fl ? "#ffffff" : (e.col || T.col), f = faceOf(e.face), r = e.r, boss = e.type === "boss";
  const state = e.strike > 0 || e.pre > 0 || e.wind > 0 || (e.charge && e.charge.wind > 0) ? "attack" : (e.dx || e.dy) ? "walk" : "idle", bob = state === "walk" ? Math.abs(Math.sin(st.t * 10 + e.ox)) * 1.2 : 0;
  if (look !== "wisp") shadow(bx, by, r);
  if (e.elite) { g.strokeStyle = C.elite; g.lineWidth = 2; g.beginPath(); g.ellipse(bx, by, r * 1.5, r * 0.75, 0, 0, TAU); g.stroke(); }
  if (e.mark > 0) { g.strokeStyle = "#efe6cf"; g.lineWidth = 1.5; g.setLineDash([3, 4]); g.beginPath(); g.ellipse(bx, by, r * 1.25, r * 0.62, 0, 0, TAU); g.stroke(); g.setLineDash([]); }
  const key = SPRITE_OF[look];
  if (key && sprite(key, bx, by, foeTall(e), f, state, fl, st.t * 2.4 + e.ox * 0.01, state === "walk" ? 0.8 : 0)) return;
  const y = by - bob;
  if (look === "wisp") {
    const fy = y - 20 - Math.sin(st.t * 3 + e.ox) * 4 - (boss ? 26 : 0); g.fillStyle = "rgba(0,0,0,.22)"; g.beginPath(); g.ellipse(bx, by, r * 0.8, r * 0.36, 0, 0, TAU); g.fill();
    g.fillStyle = col; g.globalAlpha *= 0.25; g.beginPath(); g.arc(bx, fy, r * 2, 0, TAU); g.fill(); g.globalAlpha /= 0.25; poly(g, bx, fy, r, 6, st.t * 2); g.fill(); g.fillStyle = "#ffffff"; poly(g, bx, fy, r * 0.45, 4, -st.t * 3); g.fill(); return;
  }
  if (look === "skorp") {
    shape(col, [bx - r * 1.2, y - 3, bx, y + r * 0.45, bx + r * 1.2, y - 3, bx, y - r * 0.75]); shape(shade(col, 0.6), [bx, y + r * 0.45, bx + r * 1.2, y - 3, bx, y - r * 0.2]);
    g.strokeStyle = shade(col, 0.75); g.lineWidth = 3; g.beginPath(); g.moveTo(bx - f.x * r * 0.8, y - r * 0.4); g.quadraticCurveTo(bx - f.x * r * 1.6, y - r * 2.2, bx + f.x * r * 0.2, y - r * 1.9); g.stroke();
    g.fillStyle = C.wisp; poly(g, bx + f.x * r * 0.3, y - r * 1.9, 3.5, 3, st.t); g.fill(); return;
  }
  const o = look === "giant" ? { tall: 3.3, w: 0.95, head: 0.4 } : look === "grey" ? { tall: 3.3, w: 0.5, head: 0.62 } : look === "seer" ? { tall: 2.6, w: 0.7 } : look === "sammler" ? { tall: 3.4, w: 0.7, head: 0.34 } : look === "mutter" ? { tall: 2.9, w: 0.85 } : look === "koenig" ? { tall: 3.2, w: 0.8 } : {};
  if (look === "mutter" || look === "snake") { g.strokeStyle = shade(col, 0.7); g.lineWidth = r * (look === "mutter" ? 0.7 : 0.3); g.lineCap = "round"; g.beginPath(); g.moveTo(bx, y - 2); g.quadraticCurveTo(bx - f.x * r * 1.6, y + r * 0.5, bx - f.x * r * 2.1, y - r * 0.4); g.stroke(); }
  const bare = { snake: 1.1, mutter: 1.1, giant: 1, grey: 1.15, demon: 0.6, sammler: 1.6 }[look];
  Object.assign(o, { f, walk: state === "walk", seed: e.ox }, bare ? { skin: shade(col, bare), hair: shade(col, bare) } : look === "guard" || look === "koenig" ? { skin: "#b8b39a", hair: "#6f6a55", eyes: "#c9fffb" } : { skin: "#e6dfc8" });
  const P = pawn(bx, y, r, col, o), ax = bx + f.x * P.w, ay = y - P.H * 0.42 + f.y * r * 0.3, reach = state === "attack" ? 1.9 : 1.2;
  if (look === "snake" || look === "mutter") { shape(shade(col, 0.85), [bx - P.hr * 1.7, P.hy - P.hr * 0.4, bx, P.hy - P.hr * 1.5, bx + P.hr * 1.7, P.hy - P.hr * 0.4, bx, P.hy + P.hr]); g.fillStyle = shade(col, 1.25); poly(g, bx, P.hy, P.hr * 0.8, 6, 0.52); g.fill(); }
  if (look === "snake" || look === "seer") { g.strokeStyle = look === "seer" ? "#6d5a3c" : "#9a8a66"; g.lineWidth = 2.5; g.beginPath(); g.moveTo(ax - f.x * r * 0.4, ay + r * 0.9); g.lineTo(ax + f.x * r * reach, ay - r * (look === "seer" ? 1.5 : 0.3) + f.y * r * 0.5); g.stroke(); g.fillStyle = look === "seer" ? "#9be06b" : C.wisp; poly(g, ax + f.x * r * reach, ay - r * (look === "seer" ? 1.5 : 0.3) + f.y * r * 0.5, 4, 3, 0); g.fill(); }
  if (look === "giant") { g.fillStyle = C.wisp; poly(g, bx - P.w * 0.7, P.top + 3, r * 0.34, 3, -0.5); g.fill(); poly(g, bx + P.w * 0.6, P.top + 1, r * 0.28, 3, -0.2); g.fill(); g.fillStyle = shade(col, 0.7); g.beginPath(); g.arc(ax + f.x * r * 0.3, ay + (state === "attack" ? -r * 0.9 : r * 0.2), r * 0.42, 0, TAU); g.fill(); }
  if (look === "guard" || look === "koenig") { g.fillStyle = "#c9fffb"; g.fillRect(bx + f.x * P.hr * 0.3 - 3, P.hy - 1, 2.5, 2.5); g.fillRect(bx + f.x * P.hr * 0.3 + 2, P.hy - 1, 2.5, 2.5); g.strokeStyle = "#b9b08a"; g.lineWidth = 3; g.beginPath(); g.moveTo(ax, ay + r * 0.5); g.lineTo(ax + f.x * r * reach, ay - r * 0.9); g.stroke(); }
  if (look === "guard") { g.fillStyle = shade(col, 0.55); poly(g, bx - f.x * P.w * 0.9, ay + r * 0.2, r * 0.55, 6, 0); g.fill(); }
  if (look === "koenig") { g.fillStyle = "#d8b04a"; for (let i = -1; i <= 1; i++) { g.beginPath(); g.moveTo(bx + i * P.hr * 0.6 - 3, P.hy - P.hr * 0.8); g.lineTo(bx + i * P.hr * 0.6, P.hy - P.hr * 1.9); g.lineTo(bx + i * P.hr * 0.6 + 3, P.hy - P.hr * 0.8); g.fill(); } }
  if (look === "grey") { g.fillStyle = "#0b0d12"; g.beginPath(); g.ellipse(bx + f.x * P.hr * 0.35 - P.hr * 0.3, P.hy + 1, P.hr * 0.22, P.hr * 0.34, 0.4, 0, TAU); g.ellipse(bx + f.x * P.hr * 0.35 + P.hr * 0.3, P.hy + 1, P.hr * 0.22, P.hr * 0.34, -0.4, 0, TAU); g.fill(); g.fillStyle = "#e06bd0"; poly(g, ax + f.x * r * 0.5, ay - r * 0.6 - Math.sin(st.t * 4) * 2, state === "attack" ? 6 : 4, 4, st.t * 2); g.fill(); }
  if (look === "demon") { g.strokeStyle = "#1c1212"; g.lineWidth = 3; g.beginPath(); g.moveTo(bx - P.hr * 0.6, P.hy - P.hr * 0.6); g.lineTo(bx - P.hr * 1.2, P.hy - P.hr * 1.8); g.moveTo(bx + P.hr * 0.6, P.hy - P.hr * 0.6); g.lineTo(bx + P.hr * 1.2, P.hy - P.hr * 1.8); g.stroke(); g.fillStyle = "#ff8a3c"; poly(g, bx, y - P.H * 0.4, r * (0.3 + 0.06 * Math.sin(st.t * 6)), 6, 0); g.fill(); }
  if (look === "sammler") { g.fillStyle = "#dfe9f0"; poly(g, bx + f.x * 2, P.hy, P.hr * 0.8, 6, 0.52); g.fill(); for (let i = 0; i < 5; i++) { const a = st.t * 0.8 + i * TAU / 5; g.fillStyle = i % 2 ? C.wisp : "#ffd75e"; g.beginPath(); g.arc(bx + Math.cos(a) * r * 1.3, y - P.H * 0.5 + Math.sin(a) * r * 0.45, 3.5, 0, TAU); g.fill(); } }
}
function drawHero(h, bx, by) {
  const c = CLS[h.cls], f = faceOf(h.ang), moving = h.mvx || h.mvy, state = h.atkA > 0 ? "attack" : moving ? "walk" : "idle", bob = moving ? Math.abs(Math.sin(st.t * 10)) * 1.5 : 0, y = by - bob;
  shadow(bx, by, h.r);
  g.globalAlpha = h.inv > 0 ? 0.6 : 1;
  if (!sprite(c.art, bx, by, 96, f, state, h.hurtT > 0, h.step || 0, Math.min(1, Math.hypot(h.mvx, h.mvy)))) {
    const P = pawn(bx, y, h.r, h.hurtT > 0 ? "#ffffff" : c.col, { tall: 3.5, f, walk: !!moving, ...({ ermittler: { hair: "#a9a9a4" }, moench: { hair: "#d6ad88" }, jaegerin: { hair: "#8a4a2a" }, forensiker: { skin: "#8a5a3c", hair: "#e8e8f0" } })[h.cls] }), ax = bx + f.x * P.w * 0.9, ay = y - P.H * 0.44 + f.y * 4, sw = h.atkA > 0 ? 1 - h.atkA / 0.22 : 0;
    g.lineCap = "round";
    if (h.cls === "ermittler") {   // Zweihänder: ruht an der Schulter, beim Hieb fährt er im Bogen nach vorn
      const a0 = Math.atan2(f.y, f.x) - 1.3 + sw * 2.6, L = 32, ex = h.atkA > 0 ? ax + Math.cos(a0) * L : ax + f.x * 7, ey = h.atkA > 0 ? ay + Math.sin(a0) * L * 0.6 : ay - 30;
      g.strokeStyle = "#e9edf2"; g.lineWidth = 4; g.beginPath(); g.moveTo(ax, ay); g.lineTo(ex, ey); g.stroke();
      g.fillStyle = C.wisp; g.beginPath(); g.arc(bx - f.x * P.w, y - P.H * 0.3, 3, 0, TAU); g.fill();
    }
    else if (h.cls === "moench") { const p = h.atkA > 0 ? 14 : 5; g.fillStyle = "#cfc4a8"; g.beginPath(); g.arc(ax + f.x * p, ay + f.y * p * 0.5, 4, 0, TAU); g.arc(ax - f.x * 3 - f.y * 6, ay + 3, 3.5, 0, TAU); g.fill(); g.fillStyle = "#3d4a8a"; g.fillRect(bx - P.w * 0.8, y - P.H * 0.36, P.w * 1.6, 3); }
    else if (h.cls === "jaegerin") { const a = Math.atan2(f.y, f.x); g.strokeStyle = "#d8ffd8"; g.lineWidth = 3; g.beginPath(); g.arc(ax, ay, 14, a - 1, a + 1); g.stroke(); g.lineWidth = 1; g.beginPath(); g.moveTo(ax + Math.cos(a - 1) * 14, ay + Math.sin(a - 1) * 14); g.lineTo(ax + Math.cos(a + 1) * 14, ay + Math.sin(a + 1) * 14); g.stroke(); }
    else { g.strokeStyle = "#b9a06a"; g.lineWidth = 3; g.beginPath(); g.moveTo(ax, y - 2); g.lineTo(ax + f.x * 4, P.hy - 12); g.stroke(); g.fillStyle = C.wisp; poly(g, ax + f.x * 4, P.hy - 20 - Math.sin(st.t * 4) * 2, h.atkA > 0 ? 7 : 5, 4, st.t * 2); g.fill(); }
  }
  g.globalAlpha = 1;
}
function drawPet(p, bx, by) {
  const f = faceOf(p.face), y = by - (p.mv ? Math.abs(Math.sin(st.t * 14)) * 3 : 0) - (p.bite > 0 ? 5 : 0), col = p.rage > 0 ? "#ffb35e" : "#e2c08a";
  shadow(bx, by, 7);
  shape(col, [bx - 9, y - 4, bx, y, bx + 9, y - 4, bx + 6, y - 11, bx - 6, y - 11]); shape(shade(col, 0.7), [bx, y, bx + 9, y - 4, bx + 6, y - 11, bx, y - 11]);
  const hx = bx + f.x * 8, hy = y - 13 + f.y * 3; g.fillStyle = shade(col, 1.15); poly(g, hx, hy, 5.5, 6, 0.5); g.fill();
  shape(col, [hx - 5, hy - 3, hx - 7, hy - 14, hx - 1, hy - 5]); shape(col, [hx + 5, hy - 3, hx + 7, hy - 14, hx + 1, hy - 5]);
  g.strokeStyle = col; g.lineWidth = 4; g.lineCap = "round"; g.beginPath(); g.moveTo(bx - f.x * 8, y - 7); g.lineTo(bx - f.x * 16, y - 12); g.stroke();
}
function drawObst(o, bx, by) {
  const r = o.r, P = st.pal;
  if (o.kind === "chest") {   // drei Arten: Holztruhe, Eisentruhe, Prunktruhe (größer, mit Goldschein und Funkeln)
    const T = o.tier || 0, w = [84, 96, 118][T]; shadow(bx, by + 2, w * 0.32);
    if (!prop(o.open ? "d5" : "d4", bx, by, w)) { shape("#5a4028", [bx - 22, by - 8, bx, by + 4, bx + 22, by - 8, bx + 22, by - 26, bx, by - 14, bx - 22, by - 26]); shape("#7a5836", [bx - 22, by - 26, bx, by - 14, bx + 22, by - 26, bx, by - 38]); g.fillStyle = o.open ? "#ffd75e" : "#c9a24e"; g.fillRect(bx - 3, by - 16, 6, 8); }
    if (!o.open && T) for (let k = 0; k < 2 + T; k++) { const ph = (st.t * 0.7 + k * 0.37 + o.x) % 1, sx = bx + Math.sin(k * 2.4 + o.x) * w * 0.3, sy = by - 20 - ph * 46; g.globalAlpha = Math.sin(ph * Math.PI); g.fillStyle = CHEST[T].col; poly(g, sx, sy, 2.4 + T, 4, st.t * 2 + k); g.fill(); }
    g.globalAlpha = 1; return;
  }
  if (o.kind === "barrel") {
    shadow(bx, by + 2, 15); const w = 13, hh = 30, gr = g.createLinearGradient(bx - w, 0, bx + w, 0); gr.addColorStop(0, "#2e2015"); gr.addColorStop(0.35, "#7a5a38"); gr.addColorStop(0.7, "#5a4028"); gr.addColorStop(1, "#22170f");
    g.fillStyle = gr; g.beginPath(); g.moveTo(bx - w, by - 4); g.quadraticCurveTo(bx - w - 3, by - hh / 2 - 4, bx - w, by - hh); g.lineTo(bx + w, by - hh); g.quadraticCurveTo(bx + w + 3, by - hh / 2 - 4, bx + w, by - 4); g.quadraticCurveTo(bx, by + 4, bx - w, by - 4); g.fill();
    g.fillStyle = "#6a5034"; g.beginPath(); g.ellipse(bx, by - hh, w, w * 0.45, 0, 0, TAU); g.fill(); g.strokeStyle = "#17181c"; g.lineWidth = 2.5; for (const k of [0.25, 0.75]) { g.beginPath(); g.ellipse(bx, by - 4 - (hh - 4) * k, w + 1.5, w * 0.45, 0, 0, Math.PI); g.stroke(); }
    return;
  }
  if (o.kind === "crate") {
    shadow(bx, by + 2, 16); const w = 15, hh = 20; shape("#4a3622", [bx - w, by - w * 0.5, bx, by, bx, by - hh, bx - w, by - hh - w * 0.5]); shape("#33261a", [bx, by, bx + w, by - w * 0.5, bx + w, by - hh - w * 0.5, bx, by - hh]); shape("#6e5334", [bx - w, by - hh - w * 0.5, bx, by - hh, bx + w, by - hh - w * 0.5, bx, by - hh - w]);
    g.strokeStyle = "rgba(0,0,0,.45)"; g.lineWidth = 1.5; g.beginPath(); g.moveTo(bx - w, by - hh / 2 - w * 0.5); g.lineTo(bx, by - hh / 2); g.lineTo(bx + w, by - hh / 2 - w * 0.5); g.moveTo(bx - w, by - hh - w * 0.5); g.lineTo(bx, by - hh); g.lineTo(bx + w, by - hh - w * 0.5); g.moveTo(bx, by); g.lineTo(bx, by - hh); g.stroke();
    return;
  }
  if (o.kind === "fire") {   // Lagerfeuer: Steinkreis, Scheite, Flamme
    g.fillStyle = "rgba(0,0,0,.4)"; g.beginPath(); g.ellipse(bx, by, 20, 9, 0, 0, TAU); g.fill();
    for (let k = 0; k < 7; k++) { const a = k / 7 * TAU; g.fillStyle = k % 2 ? "#55504a" : "#6a645c"; g.beginPath(); g.ellipse(bx + Math.cos(a) * 17, by + Math.sin(a) * 7.5, 5, 3.4, 0, 0, TAU); g.fill(); }
    g.strokeStyle = "#3a2616"; g.lineWidth = 5; g.lineCap = "round"; g.beginPath(); g.moveTo(bx - 10, by + 2); g.lineTo(bx + 8, by - 5); g.moveTo(bx + 10, by + 2); g.lineTo(bx - 8, by - 5); g.stroke();
    flame(bx, by - 2, 11, o.x); return;
  }
  if (o.kind === "d") {
    const PR = ART.prop["d" + o.v], w = 96 * clamp(PR ? PR.rel : 1, 0.55, 1.5);
    shadow(bx, by + 2, 30); if (PR && prop("d" + o.v, bx, by, w)) return;
    shape(shade(P.rock, 0.62), [bx - 16, by, bx, by + 8, bx, by - 58, bx - 12, by - 52]); shape(P.rockL, [bx, by + 8, bx + 16, by, bx + 12, by - 52, bx, by - 58]);
    if (GLOW["d" + o.v]) { g.fillStyle = GLOW["d" + o.v][0]; poly(g, bx, by - 66 - Math.sin(st.t * 9 + o.x) * 2, 8, 3, -Math.PI / 2); g.fill(); }
    return;
  }
  const PR = ART.prop[o.kind + o.v];
  if (PR) { const w = r * (o.kind === "needle" ? 2.2 : 2.4) * clamp(PR.rel || 1, 0.6, 1.7); shadow(bx, by + 2, w * 0.42); if (prop(o.kind + o.v, bx, by, w)) return; }
  if (o.kind === "star") o = { ...o, kind: "needle" };
  if (o.kind === "needle") {
    const H = r * 3 + 22, lean = (o.v - 1) * r * 0.25;
    for (const [dx, k] of r > 26 ? [[-r * 0.55, 0.5], [r * 0.5, 0.38], [0, 1]] : [[0, 1]]) {
      const x = bx + dx, hh = H * k, w = r * 0.5 * (0.6 + k * 0.4), tx = x + lean * k;
      shape("#3f6d69", [x - w, by, tx, by - hh, x, by + w * 0.5]); shape("#79bdb6", [x, by + w * 0.5, tx, by - hh, x + w, by - w * 0.1]);
      g.strokeStyle = "#d4fffa"; g.lineWidth = 1; g.beginPath(); g.moveTo(x, by + w * 0.5); g.lineTo(tx, by - hh); g.stroke();
    }
    return;
  }
  const top = by - r * (0.85 + (o.v % 3) * 0.22), mx = bx + r * 0.15, my = by - r * 0.3;
  shadow(bx, by + r * 0.1, r);
  shape(shade(P.rock, 0.62), [bx - r, by - r * 0.1, bx - r * 0.45, top + r * 0.2, mx, my, bx + r * 0.1, by + r * 0.45, bx - r * 0.6, by + r * 0.3]);
  shape(P.rockL, [bx - r * 0.45, top + r * 0.2, bx + r * 0.1, top, bx + r * 0.6, top + r * 0.3, mx, my]);
  shape(P.rock, [mx, my, bx + r * 0.6, top + r * 0.3, bx + r, by - r * 0.15, bx + r * 0.1, by + r * 0.45]);
}
function drawLoot(l, bx, by) {
  const pop = Math.min(1, l.t / 0.25), y = by - 8 - Math.sin(pop * Math.PI) * 18, IM = ART.icons && img(ART.icons.src);
  const ic = (i, sz) => g.drawImage(IM, (i % 6) * 112, Math.floor(i / 6) * 112, 112, 112, bx - sz / 2, y - sz * 0.62, sz, sz);
  g.fillStyle = "rgba(0,0,0,.3)"; g.beginPath(); g.ellipse(bx, by, 9, 4, 0, 0, TAU); g.fill();
  if (l.globe) { g.fillStyle = C.blood; g.beginPath(); g.arc(bx, y, 8, 0, TAU); g.fill(); g.strokeStyle = "#ffb0a8"; g.lineWidth = 1.5; g.stroke(); }
  else if (l.mat) { if (IM) ic(ICON[l.mat], 26); else { g.fillStyle = MATS[l.mat].col; poly(g, bx, y, 6.5, 6, 0.5); g.fill(); } }
  else if (l.shard) { if (IM) ic(ICON.shard, 18 + Math.min(10, l.shard)); else { g.fillStyle = C.wisp; poly(g, bx, y, 5 + Math.min(4, l.shard / 6), 4, 0); g.fill(); } }
  else if (l.evid !== undefined) { if (IM) ic(ICON.evid, 30); else { g.fillStyle = "#f4ecd2"; g.fillRect(bx - 7, y - 9, 14, 18); g.fillStyle = "#b5442a"; g.fillRect(bx - 7, y - 9, 14, 4); } }
  else {
    const col = RAR[l.item.rar].col; g.strokeStyle = col; g.lineWidth = 2; g.beginPath(); g.ellipse(bx, by, 13, 6, 0, 0, TAU); g.stroke();
    if (IM) ic(iconOf(l.item), 34); else { g.fillStyle = col; g.save(); g.translate(bx, y); g.rotate(Math.PI / 4); g.fillRect(-7, -7, 14, 14); g.restore(); }
  }
}

// Zeitmessung je Abschnitt (für Tests; kostet fast nichts)
const PF = {}; let PT0 = 0;
function PT(n) { const t = performance.now(); if (n !== "start") PF[n] = (PF[n] || 0) * 0.9 + (t - PT0) * 0.1; PT0 = t; }
function draw() {
  const h = hero, z = view.zoom * view.dpr, vw = view.w / view.zoom, vh = view.h / view.zoom, hbx = px(h.x, h.y), hby = py(h.x, h.y), P = st.pal;
  view.ox = hbx - vw / 2; view.oy = hby - vh * 0.47;
  const sh = st.shake * view.dpr, sx = sh ? rnd(-sh, sh) : 0, sy = sh ? rnd(-sh, sh) : 0;
  const on = (o, m = 90) => { const bx = px(o.x, o.y), by = py(o.x, o.y); return bx > view.ox - m && bx < view.ox + vw + m && by > view.oy - m && by < view.oy + vh + m + 70; };
  g.setTransform(1, 0, 0, 1, 0, 0); g.globalAlpha = 1; g.fillStyle = "#05060a"; g.fillRect(0, 0, cv.width, cv.height);

  PT("start");
  // ----- Boden und alles, was flach darauf liegt -----
  GT(g, z, sx, sy);
  DZ = z; DSX = sx; DSY = sy;
  const cs = [toWorld(view.ox, view.oy), toWorld(view.ox + vw, view.oy), toWorld(view.ox, view.oy + vh + 120), toWorld(view.ox + vw, view.oy + vh + 120)], cell = (v) => Math.floor(v / CELL);
  const vx0 = Math.max(0, cell(Math.min(...cs.map((c) => c.x))) - 1), vx1 = Math.min(GW - 1, cell(Math.max(...cs.map((c) => c.x))) + 1), vy0 = Math.max(0, cell(Math.min(...cs.map((c) => c.y))) - 1), vy1 = Math.min(GH - 1, cell(Math.max(...cs.map((c) => c.y))) + 1);
  g.fillStyle = groundFill(); g.fillRect(0, 0, WORLD.w, WORLD.h);
  if (st.tint) { g.globalCompositeOperation = "multiply"; g.globalAlpha = 0.7; g.fillStyle = P.ground; g.fillRect(0, 0, WORLD.w, WORLD.h); g.globalCompositeOperation = "source-over"; g.globalAlpha = 1; }
  const dk = texPat ? 0.4 : 1;
  for (const d of st.decor) if (on(d, d.r * 2)) { g.globalAlpha = d.a * dk; g.fillStyle = P.dune; g.beginPath(); g.ellipse(d.x, d.y, d.r * 1.7, d.r * 0.5, d.rot, 0, TAU); g.fill(); }   // Dünenkämme
  g.globalAlpha = 1; if (!st.indoor) { g.strokeStyle = shade(P.ground, 1.35); g.lineWidth = 5; g.strokeRect(0, 0, WORLD.w, WORLD.h); }
  if (GFX[GQ].mist) for (const m of st.mist) { const mx = (m.x + m.vx * st.t) % (WORLD.w + 400) - 200; if (!on({ x: mx, y: m.y }, m.r)) continue; g.globalAlpha = m.a; g.drawImage(blob("190,205,225"), mx - m.r, m.y - m.r, 2 * m.r, 2 * m.r); g.globalAlpha = 1; }
  for (let cy = vy0; cy <= vy1; cy++) for (let cx = vx0; cx <= vx1; cx++) {
    const i = gi(cx, cy), fl = st.floor[i];
    if (st.grid[i] === 1) { if (st.indoor) { g.fillStyle = "#04050a"; g.fillRect(cx * CELL - 0.5, cy * CELL - 0.5, CELL + 1, CELL + 1); } }
    else if (fl === 1) { g.fillStyle = "rgba(0,0,0,.22)"; g.fillRect(cx * CELL, cy * CELL, CELL, CELL); }
    else if (fl === 2) { g.fillStyle = wallFill(); g.fillRect(cx * CELL - 0.5, cy * CELL - 0.5, CELL + 1, CELL + 1); g.fillStyle = "rgba(10,12,20,.3)"; g.fillRect(cx * CELL - 0.5, cy * CELL - 0.5, CELL + 1, CELL + 1); }
  }
  for (const r of st.rugs) { g.fillStyle = r.col; g.fillRect(r.x, r.y, r.w, r.h); g.strokeStyle = "rgba(216,176,74,.55)"; g.lineWidth = 3; g.strokeRect(r.x + 7, r.y + 7, r.w - 14, r.h - 14); g.strokeStyle = "rgba(0,0,0,.35)"; g.lineWidth = 2; g.strokeRect(r.x + 1, r.y + 1, r.w - 2, r.h - 2); }
  for (const q of st.stains) if (on(q, 80)) { g.fillStyle = q.blood ? "rgba(70,12,10,.5)" : "rgba(0,0,0,.35)"; g.beginPath(); g.ellipse(q.x, q.y, q.r, q.r * 0.6, q.rot, 0, TAU); g.fill(); }
  if (h.buff.mantra > 0) { g.globalAlpha = 0.12; g.fillStyle = "#efe6cf"; g.beginPath(); g.arc(h.x, h.y, 180, 0, TAU); g.fill(); g.globalAlpha = 0.6; g.strokeStyle = "#efe6cf"; g.lineWidth = 2; g.setLineDash([6, 8]); g.lineDashOffset = -st.t * 20; g.stroke(); g.setLineDash([]); g.globalAlpha = 1; }
  for (const zn of st.zones) { g.globalAlpha = 0.16; g.fillStyle = zn.col; g.beginPath(); g.arc(zn.x, zn.y, zn.r, 0, TAU); g.fill(); g.globalAlpha = 0.8; g.strokeStyle = zn.col; g.lineWidth = 2; g.stroke(); g.globalAlpha = 1; }
  for (const m of st.late) { const k = 1 - m.t / m.max; g.globalAlpha = 0.2; g.fillStyle = "#ffd75e"; g.beginPath(); g.arc(m.x, m.y, m.r, 0, TAU); g.fill(); g.globalAlpha = 1; g.strokeStyle = "#ffd75e"; g.lineWidth = 2; g.stroke(); g.beginPath(); g.arc(m.x, m.y, m.r * k, 0, TAU); g.stroke(); }
  for (const e of st.en) {   // Ansagen der Gegner: Aufschlag, Ansturm, Ausholen
    if (e.wind > 0) { g.fillStyle = "rgba(200,68,58,.22)"; g.strokeStyle = C.blood; g.lineWidth = 2; g.beginPath(); g.arc(e.x, e.y, 92, 0, TAU); g.fill(); g.stroke(); g.beginPath(); g.arc(e.x, e.y, 92 * (1 - e.wind / 0.8), 0, TAU); g.stroke(); }
    if (e.pre > 0) { const R = e.r + h.r + 30; g.fillStyle = `rgba(200,68,58,${0.15 + 0.3 * (1 - e.pre / 0.5)})`; g.beginPath(); g.moveTo(e.x, e.y); g.arc(e.x, e.y, R, e.face - 0.8, e.face + 0.8); g.closePath(); g.fill(); }
    if (e.charge && e.charge.wind > 0) { g.save(); g.translate(e.x, e.y); g.rotate(e.charge.ang); g.fillStyle = `rgba(200,68,58,${0.18 + 0.2 * Math.sin(st.t * 30) ** 2})`; g.fillRect(0, -e.r, 540, e.r * 2); g.restore(); }
  }
  g.strokeStyle = "rgba(232,176,74,.75)"; g.lineWidth = 3; g.beginPath(); g.arc(h.x, h.y, 26, 0, TAU); g.stroke(); g.strokeStyle = "rgba(232,176,74,.3)"; g.lineWidth = 7; g.stroke();   // Ring unter der eigenen Figur: im Getümmel immer zu finden
  if (h.swing) { const sr = h.swing.r, gr = g.createRadialGradient(h.x, h.y, sr * 0.25, h.x, h.y, sr); gr.addColorStop(0, "rgba(255,233,168,0)"); gr.addColorStop(0.75, "rgba(255,233,168,.28)"); gr.addColorStop(1, "rgba(255,246,214,.6)"); g.fillStyle = gr; g.beginPath(); g.moveTo(h.x, h.y); g.arc(h.x, h.y, sr, h.swing.ang - h.swing.arc, h.swing.ang + h.swing.arc); g.closePath(); g.fill(); }
  for (const f of st.fx) if (f.k === "ring") { const k = f.life / f.max; g.globalAlpha = k; g.strokeStyle = f.col; g.lineWidth = 5 * k + 1; g.beginPath(); g.arc(f.x, f.y, f.r * (1 - k * 0.35), 0, TAU); g.stroke(); }
  g.globalAlpha = 1;
  if (st.portal) { g.fillStyle = "rgba(143,227,224,.18)"; g.beginPath(); g.arc(st.portal.x, st.portal.y, 46 + Math.sin(st.t * 3) * 4, 0, TAU); g.fill(); }

  PT("boden");
  // ----- alles Stehende, von hinten nach vorn -----
  UT(g, z, sx, sy);
  const list = [];
  const put = (o, fn) => { if (on(o, 120)) list.push({ d: o.x + o.y, fn, o }); };
  for (const d of st.dead) put(d, drawDead);
  for (const o of st.obst) put(o, drawObst);
  for (let cy = vy0; cy <= vy1; cy++) for (let cx = vx0; cx <= vx1; cx++) {
    const wh = st.wh[gi(cx, cy)]; if (!wh || wh === TOWER) continue; let edge = !st.indoor;
    for (let dy = -1; dy <= 1 && !edge; dy++) for (let dx = -1; dx <= 1; dx++) if ((dx || dy) && inGrid(cx + dx, cy + dy) && !cellWall(cx + dx, cy + dy)) { edge = true; break; }
    if (edge) list.push({ d: (cx + cy + 1) * CELL, fn: drawWall, o: { cx, cy, x: (cx + 0.5) * CELL, y: (cy + 0.5) * CELL } });
  }
  for (const t of st.towers) if (on(t, 420)) list.push({ d: t.x + t.y + t.n * CELL * 0.5, fn: drawTower, o: t });
  for (const q of st.sconces) if (on(q, 120)) list.push({ d: q.x + q.y + 4, fn: drawSconce, o: q });
  for (const l of st.loot) put(l, drawLoot);
  for (const e of st.en) if (!e.hidden) put(e, drawFoe);
  if (st.pet) put(st.pet, drawPet);
  put(h, drawHero);
  if (st.portal) list.push({ d: st.portal.x + st.portal.y - 24, fn: drawGate, o: st.portal });
  list.sort((a, b) => a.d - b.d || (a.fn === drawDead ? -1 : b.fn === drawDead ? 1 : 0));
  for (const it of list) it.fn(it.o, px(it.o.x, it.o.y), py(it.o.x, it.o.y), h);
  g.globalAlpha = 1;
  // Geschosse fliegen in Brusthöhe, darunter ihr Schatten
  for (const p of st.shots) { const bx = px(p.x, p.y), by = py(p.x, p.y); g.fillStyle = "rgba(0,0,0,.3)"; g.beginPath(); g.ellipse(bx, by, p.r, p.r * 0.45, 0, 0, TAU); g.fill(); g.fillStyle = p.col || (p.hero ? C.shotH : C.shotE); g.beginPath(); g.arc(bx, by - 20, p.r, 0, TAU); g.fill(); }
  for (const zn of st.zones) if (zn.rain) for (let i = 0; i < 7; i++) { const a = i * 2.4 + Math.floor(st.t * 9) * 1.7, d = (i * 37 % 100) / 100 * zn.r, wx = zn.x + Math.cos(a) * d, wy = zn.y + Math.sin(a) * d; g.fillStyle = "#d8ffd8"; g.fillRect(px(wx, wy) - 1, py(wx, wy) - 16, 2, 14); }
  for (const m of st.late) { const k = 1 - m.t / m.max; g.fillStyle = "#fff3cf"; g.beginPath(); g.arc(px(m.x, m.y) + (1 - k) * 120, py(m.x, m.y) - (1 - k) * 420, 9, 0, TAU); g.fill(); }
  for (const f of st.fx) {
    const k = f.max ? f.life / f.max : f.life * 2;
    if (f.k === "p") { g.globalAlpha = clamp(k, 0, 1); g.fillStyle = f.col; g.fillRect(px(f.x, f.y) - 2, py(f.x, f.y) - f.lift - 2, 4, 4); }
    else if (f.k === "line") { g.globalAlpha = k; g.strokeStyle = f.col; g.lineWidth = 9 * k; g.lineCap = "round"; g.beginPath(); g.moveTo(px(f.x, f.y), py(f.x, f.y) - 18); g.lineTo(px(f.x2, f.y2), py(f.x2, f.y2) - 18); g.stroke(); }
  }
  g.globalAlpha = 1;

  PT("stehend");
  // ----- Dunkelheit: alles schwarz, nur Laterne, Lichtkegel und was selbst leuchtet schneidet Löcher hinein -----
  lg.setTransform(1, 0, 0, 1, 0, 0); lg.globalCompositeOperation = "source-over"; lg.clearRect(0, 0, lc.width, lc.height);
  lg.fillStyle = st.indoor ? "rgba(3,3,8,0.82)" : "rgba(4,5,12,0.66)"; lg.fillRect(0, 0, lc.width, lc.height);
  lg.globalCompositeOperation = "destination-out"; GT(lg, z * LQ, sx * LQ, sy * LQ);
  light(h.x, h.y, 215, 0.95);
  const R = 480 * h.cone;
  for (const [half, al] of [[0.62, 0.55], [0.42, 0.75]]) {
    const gr = lg.createRadialGradient(h.x, h.y, 20, h.x, h.y, R); gr.addColorStop(0, `rgba(0,0,0,${al})`); gr.addColorStop(1, "rgba(0,0,0,0)");
    lg.fillStyle = gr; lg.beginPath(); lg.moveTo(h.x, h.y); lg.arc(h.x, h.y, R, h.ang - half, h.ang + half); lg.closePath(); lg.fill();
  }
  for (const e of st.en) if (on(e)) { const gl = e.type === "boss" ? 190 : ET[e.type].glow; if (gl) light(e.x, e.y, gl * 1.3, 0.65); }
  for (const q of st.sconces) if (on(q, 200)) light(q.x + 16, q.y + 16, q.r * (0.92 + 0.08 * Math.sin(st.t * 9 + q.x)), 0.6);
  for (const o of st.obst) if (on(o, 160)) { const G = glowOf(o); if (G) light(o.x, o.y, G[1] * (0.9 + 0.1 * Math.sin(st.t * 5 + o.x)), 0.55); else if (o.kind === "needle" || o.kind === "star") light(o.x, o.y, o.r * 3, 0.42); }   // leuchtende Teile dienen als Wegmarken
  for (const p of st.shots) light(p.x, p.y, p.hero ? 80 : 40, p.hero ? 0.8 : 0.6);
  for (const zn of st.zones) light(zn.x, zn.y, zn.r * 1.3, 0.55);
  for (const m of st.late) light(m.x, m.y, m.r * 1.6, 0.4 + 0.5 * (1 - m.t / m.max));
  for (const l of st.loot) { if (l.item && l.item.rar >= 2) light(l.x, l.y, 70, 0.6); else if (l.evid !== undefined) light(l.x, l.y, 80, 0.7); else if (l.shard || l.mat) light(l.x, l.y, 28, 0.5); }
  if (st.portal) light(st.portal.x, st.portal.y, 190, 0.85);
  if (h.buff.mantra > 0) light(h.x, h.y, 230, 0.5);
  for (const f of st.fx) if (f.k === "ring") light(f.x, f.y, f.r * 1.2, 0.5 * f.life / f.max);
  UT(lg, z * LQ, sx * LQ, sy * LQ); light(hbx, hby - 30, 70, 0.9);   // die Figur selbst steht im Licht ihrer Laterne
  lg.globalCompositeOperation = "source-over";
  g.setTransform(1, 0, 0, 1, 0, 0); g.imageSmoothingEnabled = true; g.drawImage(lc, 0, 0, cv.width, cv.height);
  UT(g, z, sx, sy);

  PT("dunkel");
  // ----- Schein und Stimmung: leuchtende Teile strahlen additiv, Staub und Glut treiben durchs Bild -----
  g.globalCompositeOperation = "lighter";
  const bloom = (x, y, r, col, a) => { if (!GFX[GQ].bloom) return; g.globalAlpha = Math.min(1, a); g.drawImage(blob(hexRgb(col)), x - r, y - r, 2 * r, 2 * r); g.globalAlpha = 1; };
  for (const q of st.sconces) if (on(q, 200)) bloom(px(q.x, q.y), py(q.x, q.y) - 60, 70 * (0.9 + 0.1 * Math.sin(st.t * 10 + q.y)), "#ffb060", 0.3);
  for (const o of st.obst) if (on(o, 160)) { const G = glowOf(o); if (G) bloom(px(o.x, o.y), py(o.x, o.y) - o.r * G[2] * 1.4, G[1] * 0.55 * (0.92 + 0.08 * Math.sin(st.t * 6 + o.y)), G[0], 0.34); }
  bloom(hbx, hby - 40, 150, "#ffb060", 0.12 + 0.02 * Math.sin(st.t * 7));   // Laterne der eigenen Figur
  for (const e of st.en) if (e.type === "wisp" && on(e)) bloom(px(e.x, e.y), py(e.x, e.y) - 24, 52, "#8fe3e0", 0.12);
  const mood = st.def.mood, mc = st.def.mote || "#cccccc", W2 = vw + 120, H2 = vh + 120;
  for (let i = 0; i < GFX[GQ].motes; i++) {
    const k = i * 0.618034, sp = mood === "ember" ? 28 : mood === "glass" ? 9 : 18, x = view.ox - 60 + ((k * 977 + st.t * sp * (0.4 + (i % 5) * 0.15) + i * 53) % W2 + W2) % W2, rise = mood === "ember" ? -1 : 0.25;
    const y = view.oy - 60 + ((k * 613 + st.t * sp * rise * (0.5 + (i % 3) * 0.3) + i * 31) % H2 + H2) % H2, tw = 0.5 + 0.5 * Math.sin(st.t * (1 + i % 4) + i);
    g.globalAlpha = (mood === "ember" ? 0.8 : 0.5) * tw; g.fillStyle = mc; g.beginPath(); g.arc(x + Math.sin(st.t * 0.7 + i) * 10, y, 0.8 + (i % 3) * 0.5, 0, TAU); g.fill();
  }
  g.globalAlpha = 1; g.globalCompositeOperation = "source-over";

  PT("schein");
  // ----- über der Dunkelheit: Lebensbalken, Namen, Beutestrahlen, Zahlen, Wegweiser -----
  const FONT = "600 11px 'IBM Plex Mono', monospace";
  for (const e of st.en) if (e.active && on(e)) {
    const bx = px(e.x, e.y), top = py(e.x, e.y) - (spriteKey(e) && ART.sprite[spriteKey(e)] ? foeTall(e) : e.r * 3.4) - 8;
    if (e.hp < e.maxHp && e.type !== "boss") { const w = e.r * 2.2; g.fillStyle = "rgba(0,0,0,.6)"; g.fillRect(bx - w / 2, top, w, 4); g.fillStyle = e.elite ? C.elite : C.blood; g.fillRect(bx - w / 2, top, w * clamp(e.hp / e.maxHp, 0, 1), 4); }
    if (e.elite) { g.fillStyle = C.elite; g.font = FONT; g.textAlign = "center"; g.fillText(e.name, bx, top - 6); }
    if (e.seenT > 0) { g.fillStyle = "#ff6b5e"; g.font = "700 20px 'IBM Plex Mono', monospace"; g.textAlign = "center"; g.globalAlpha = clamp(e.seenT * 2, 0, 1); g.fillText("!", bx, top - 16); g.globalAlpha = 1; }
    if (e.stun > 0) { g.strokeStyle = "#c06be0"; g.lineWidth = 2; g.beginPath(); g.arc(bx, top - 4, 5, st.t * 8, st.t * 8 + 4.5); g.stroke(); }
  }
  for (const e of st.en) if (!e.active && !e.hidden && e.alert > 0 && on(e)) { g.fillStyle = "#ffd75e"; g.font = "700 18px 'IBM Plex Mono', monospace"; g.textAlign = "center"; g.fillText("?", px(e.x, e.y), py(e.x, e.y) - foeTall(e) - 12); }
  g.font = FONT; g.textAlign = "center";
  for (const c of st.chests) if (!c.open && dist(c, h) < 260 && los(h, c)) { g.fillStyle = CHEST[c.tier].col; g.fillText(CHEST[c.tier].name, px(c.x, c.y), py(c.x, c.y) - 62 - c.tier * 10); }
  g.font = FONT; g.textAlign = "center";
  for (const l of st.loot) if (l.evid !== undefined && on(l)) { g.fillStyle = "#f4ecd2"; g.fillText("Buchseite", px(l.x, l.y), py(l.x, l.y) + 18); }
  if (st.portal && st.portal.t > 1.4 && on(st.portal)) { g.fillStyle = "#e9fffd"; g.fillText("Pforte", px(st.portal.x, st.portal.y), py(st.portal.x, st.portal.y) + 20); }
  for (const l of st.loot) if (l.item && l.item.rar >= 2 && on(l, 300)) {
    const bx = px(l.x, l.y), by = py(l.x, l.y), col = RAR[l.item.rar].col, gr = g.createLinearGradient(0, by - 200, 0, by); gr.addColorStop(0, "rgba(0,0,0,0)"); gr.addColorStop(1, col);
    g.globalAlpha = 0.75; g.fillStyle = gr; g.fillRect(bx - (l.item.rar === 3 ? 5 : 3), by - 200, l.item.rar === 3 ? 10 : 6, 200); g.globalAlpha = 1;
    g.fillStyle = col; g.fillText(l.item.name, bx, by + 18);
  }
  for (const n of st.nums) { const bx = px(n.x, n.y), by = py(n.x, n.y) - n.lift; g.globalAlpha = clamp(n.life * 2, 0, 1); g.font = `600 ${n.big ? 19 : 13}px 'IBM Plex Mono', monospace`; g.lineWidth = 3; g.strokeStyle = "rgba(0,0,0,.75)"; g.strokeText(n.txt, bx, by); g.fillStyle = n.col; g.fillText(n.txt, bx, by); }
  g.globalAlpha = 1;
  // Wegweiser zur Pforte oder zum nächsten Rudel, wenn sie nicht im Bild ist
  const goal = st.portal || (st.boss ? null : (st.progress < st.need && st.packs.filter((p) => p.alive > 0).sort((p, q) => dist(p, h) - dist(q, h))[0]) || st.bossRef);
  if (goal && (!on(goal, -60) || !los(h, goal))) { const wf = faceOf(wayTo(goal.x, goal.y)), a = Math.atan2(wf.y, wf.x), ax = hbx + Math.cos(a) * 120, ay = hby - 24 + Math.sin(a) * 120; g.fillStyle = st.portal ? C.wisp : "rgba(232,176,74,.8)"; poly(g, ax, ay, 9, 3, a); g.fill(); }
  PT("oben");
  // Vignette mit Farbhauch je Fall: einmal vorgezeichnet, danach nur noch aufgelegt
  g.setTransform(1, 0, 0, 1, 0, 0); g.drawImage(vignette(), 0, 0, cv.width, cv.height);
  PT("rest");
}
// Karte: dieselbe Schrägansicht wie das Spielfeld, damit „oben“ auf beiden dasselbe ist
function drawMini() {
  const w = mini.width, hh = mini.height, k = w / ((WORLD.w + WORLD.h) * ISO), x0 = WORLD.h * ISO * k, y0 = (hh - (WORLD.w + WORLD.h) * ISO * 0.5 * k) / 2;
  const mx = (o) => x0 + px(o.x, o.y) * k, my = (o) => y0 + py(o.x, o.y) * k;
  mg.clearRect(0, 0, w, hh);
  if (st.indoor) {   // Dungeon: nur was die Figur schon gesehen hat, erscheint auf der Karte
    const hx = Math.floor(hero.x / CELL), hy = Math.floor(hero.y / CELL);
    for (let cy = Math.max(0, hy - 10); cy <= Math.min(GH - 1, hy + 10); cy++) for (let cx = Math.max(0, hx - 10); cx <= Math.min(GW - 1, hx + 10); cx++) if (!st.seen[cy * GW + cx] && !cellWall(cx, cy) && Math.hypot(cx - hx, cy - hy) < 10.2 && los(hero, { x: (cx + 0.5) * CELL, y: (cy + 0.5) * CELL })) st.seen[cy * GW + cx] = 1;
    mg.fillStyle = "rgba(236,227,203,.3)";
    for (let cy = 0; cy < GH; cy++) for (let cx = 0; cx < GW; cx++) if (st.seen[cy * GW + cx]) { const c = (x, y) => ({ x: x * CELL, y: y * CELL }); mg.beginPath(); [c(cx, cy), c(cx + 1, cy), c(cx + 1, cy + 1), c(cx, cy + 1)].forEach((q, n) => mg[n ? "lineTo" : "moveTo"](mx(q), my(q))); mg.closePath(); mg.fill(); }
  } else {
  mg.fillStyle = "rgba(236,227,203,.45)"; for (let cy = 0; cy < GH; cy++) for (let cx = 0; cx < GW; cx++) if (st.grid[gi(cx, cy)]) mg.fillRect(mx({ x: (cx + 0.5) * CELL, y: (cy + 0.5) * CELL }) - 1.5, my({ x: (cx + 0.5) * CELL, y: (cy + 0.5) * CELL }) - 1, 3, 2);
  mg.strokeStyle = "rgba(236,227,203,.28)"; mg.lineWidth = 1.5; mg.beginPath();
  [[0, 0], [WORLD.w, 0], [WORLD.w, WORLD.h], [0, WORLD.h]].forEach(([x, y], i) => mg[i ? "lineTo" : "moveTo"](mx({ x, y }), my({ x, y }))); mg.closePath(); mg.stroke();
  }
  mg.fillStyle = "rgba(232,176,74,.55)"; for (const p of st.packs) if (p.alive > 0 && (!st.indoor || st.seen[Math.floor(p.y / CELL) * GW + Math.floor(p.x / CELL)])) { mg.beginPath(); mg.arc(mx(p), my(p), 4, 0, TAU); mg.fill(); }
  mg.fillStyle = "#ffd75e"; for (const c of st.chests) if (!c.open && (!st.indoor || st.seen[Math.floor(c.y / CELL) * GW + Math.floor(c.x / CELL)])) mg.fillRect(mx(c) - 2.5, my(c) - 2.5, 5, 5);
  mg.fillStyle = "#e0705f"; for (const e of st.en) if (e.active && e.type !== "boss") mg.fillRect(mx(e) - 1.5, my(e) - 1.5, 3, 3);
  if (st.boss) { mg.fillStyle = C.boss; mg.beginPath(); mg.arc(mx(st.boss), my(st.boss), 7, 0, TAU); mg.fill(); }
  if (st.portal) { mg.strokeStyle = C.wisp; mg.lineWidth = 3; mg.beginPath(); mg.arc(mx(st.portal), my(st.portal), 7, 0, TAU); mg.stroke(); }
  mg.fillStyle = "#fff"; mg.beginPath(); mg.arc(mx(hero), my(hero), 4.5, 0, TAU); mg.fill();
}
