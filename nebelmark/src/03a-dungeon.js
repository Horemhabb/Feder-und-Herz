// 03a · Gelände auf einem Raster: Dungeons (Räume, Hallen, Gänge) und Freiland mit Gebäuden, Ruinen, Mauer und Türmen.
// Jede Zelle ist frei oder Mauer; Mauern haben eine Höhe. Niedrige Reste versperren den Weg, aber nicht die Sicht.
const CELL = 50, GW = WORLD.w / CELL, GH = WORLD.h / CELL, WALLH = 96, TOWER = 255;
const gi = (cx, cy) => cy * GW + cx, inGrid = (cx, cy) => cx >= 0 && cy >= 0 && cx < GW && cy < GH;
const cellWall = (cx, cy) => !!st.grid && (!inGrid(cx, cy) || st.grid[gi(cx, cy)] === 1);
const cellH = (cx, cy) => inGrid(cx, cy) ? st.wh[gi(cx, cy)] : 0;
const wallAt = (x, y) => cellWall(Math.floor(x / CELL), Math.floor(y / CELL));
const blindAt = (x, y) => { const cx = Math.floor(x / CELL), cy = Math.floor(y / CELL); return !!st.grid && (!inGrid(cx, cy) || st.wh[gi(cx, cy)] >= 50); };
// freie Sicht zwischen zwei Punkten? Mit walk: freier Weg zu Fuß (dann versperren auch niedrige Mauerreste)
function los(a, b, walk) {
  if (!st.grid) return true;
  const d = Math.hypot(b.x - a.x, b.y - a.y), n = Math.ceil(d / 20), high = walk ? cellWall : (cx, cy) => !inGrid(cx, cy) || st.wh[gi(cx, cy)] >= 50;
  let pcx = Math.floor(a.x / CELL), pcy = Math.floor(a.y / CELL);
  for (let i = 1; i <= n; i++) {
    const cx = Math.floor((a.x + (b.x - a.x) * i / n) / CELL), cy = Math.floor((a.y + (b.y - a.y) * i / n) / CELL);
    if (i < n && high(cx, cy)) return false;
    if (cx !== pcx && cy !== pcy && high(cx, pcy) && high(pcx, cy)) return false;   // kein Blick durch die Fuge zwischen zwei über Eck stehenden Mauern
    pcx = cx; pcy = cy;
  }
  return true;
}
// weitester freier Punkt auf dem Weg: Sprünge und Rollen enden vor der Mauer
function freePath(x0, y0, x1, y1) {
  if (!st.grid) return { x: x1, y: y1 };
  const d = Math.hypot(x1 - x0, y1 - y0), n = Math.max(1, Math.ceil(d / 12)); let x = x0, y = y0;
  for (let i = 1; i <= n; i++) { const nx = x0 + (x1 - x0) * i / n, ny = y0 + (y1 - y0) * i / n; if (wallAt(nx, ny)) break; x = nx; y = ny; }
  return { x, y };
}
function pushWalls(o) {
  if (!st.grid) return;
  const ccx = Math.floor(o.x / CELL), ccy = Math.floor(o.y / CELL);
  if (cellWall(ccx, ccy)) {   // der Mittelpunkt steckt in der Mauer: hinaus in die nächste freie Zelle, auch aus dicken Mauern
    const m = Math.min(o.r, CELL / 2 - 1); let best = null, bd = 1e9;
    for (let k = 1; k <= 5 && !best; k++) for (let ay = ccy - k; ay <= ccy + k; ay++) for (let ax = ccx - k; ax <= ccx + k; ax++) {
      if (Math.max(Math.abs(ax - ccx), Math.abs(ay - ccy)) !== k || cellWall(ax, ay)) continue;
      const qx = clamp(o.x, ax * CELL + m, (ax + 1) * CELL - m), qy = clamp(o.y, ay * CELL + m, (ay + 1) * CELL - m), d = (qx - o.x) ** 2 + (qy - o.y) ** 2;
      if (d < bd) { bd = d; best = [qx, qy]; }
    }
    if (best) { o.x = best[0]; o.y = best[1]; }
  }
  const r = o.r, x0 = Math.floor((o.x - r) / CELL), x1 = Math.floor((o.x + r) / CELL), y0 = Math.floor((o.y - r) / CELL), y1 = Math.floor((o.y + r) / CELL);
  for (let cy = y0; cy <= y1; cy++) for (let cx = x0; cx <= x1; cx++) {
    if (!cellWall(cx, cy)) continue;
    const nx = clamp(o.x, cx * CELL, (cx + 1) * CELL), ny = clamp(o.y, cy * CELL, (cy + 1) * CELL), dx = o.x - nx, dy = o.y - ny, d2 = dx * dx + dy * dy;
    if (d2 >= r * r) continue;
    if (d2 > 1e-6) { const d = Math.sqrt(d2); o.x = nx + dx / d * r; o.y = ny + dy / d * r; }
    else { const l = o.x - cx * CELL, rr = (cx + 1) * CELL - o.x, t = o.y - cy * CELL, b = (cy + 1) * CELL - o.y, m = Math.min(l, rr, t, b); if (m === l) o.x = cx * CELL - r; else if (m === rr) o.x = (cx + 1) * CELL + r; else if (m === t) o.y = cy * CELL - r; else o.y = (cy + 1) * CELL + r; }
  }
}
// Breitensuche über freie Zellen ab einer Zielzelle; liefert die Entfernung jeder Zelle in Schritten
function flood(tx, ty, soft) {
  const f = new Int16Array(GW * GH).fill(-1), q = [gi(tx, ty)], B = soft ? null : st.block; if (cellWall(tx, ty)) return f; f[q[0]] = 0;
  for (let i = 0; i < q.length; i++) {
    const c = q[i], cx = c % GW, cy = (c - cx) / GW;
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) { const nx = cx + dx, ny = cy + dy, n = gi(nx, ny); if (!cellWall(nx, ny) && f[n] < 0 && !(B && B[n])) { f[n] = f[c] + 1; q.push(n); } }
  }
  return f;
}
function fieldDir(f, o, fallback) {
  const cx = Math.floor(o.x / CELL), cy = Math.floor(o.y / CELL); let best = null, bd = inGrid(cx, cy) ? f[gi(cx, cy)] : -1; if (bd < 0) bd = 1e9;
  for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
    if (!dx && !dy) continue; const nx = cx + dx, ny = cy + dy; if (cellWall(nx, ny)) continue;
    if (dx && dy && (cellWall(cx + dx, cy) || cellWall(cx, cy + dy))) continue;   // nicht diagonal um Ecken
    const v = f[gi(nx, ny)]; if (v >= 0 && v < bd) { bd = v; best = [nx, ny]; }
  }
  return best ? Math.atan2((best[1] + 0.5) * CELL - o.y, (best[0] + 0.5) * CELL - o.x) : fallback;
}
// Richtung vom Helden zu einem Ziel um die Mauern herum (für Wegweiser und Tests)
function wayTo(tx, ty) {
  const a = Math.atan2(ty - hero.y, tx - hero.x); if (!st.grid || los(hero, { x: tx, y: ty }, true)) return a;   // gerade Linie nur, wenn auch kein niedriger Mauerrest im Weg steht
  let cx = Math.floor(tx / CELL), cy = Math.floor(ty / CELL); const hc = gi(Math.floor(hero.x / CELL), Math.floor(hero.y / CELL));
  if (cellWall(cx, cy)) { const n = [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [-1, 1], [1, -1], [-1, -1]].find(([dx, dy]) => !cellWall(cx + dx, cy + dy)); if (n) { cx += n[0]; cy += n[1]; } }   // Ziel an oder in der Mauer: die freie Zelle daneben zählt
  let f = flood(cx, cy); if (f[hc] < 0) f = flood(cx, cy, true);   // versperrt Einrichtung jeden Weg, zählt sie nicht als Hindernis
  return fieldDir(f, hero, a);
}

// Feste Einrichtung (Truhen, Sarkophage, Säulen, Felsen) versperrt Zellen für die Wegsuche: Figuren und Gegner laufen darum herum
function blockObst(o) { if (o.brk || !st.block) return; const rr = Math.max(0, o.r - 12), x0 = Math.floor((o.x - rr) / CELL), x1 = Math.floor((o.x + rr) / CELL), y0 = Math.floor((o.y - rr) / CELL), y1 = Math.floor((o.y + rr) / CELL); for (let cy = y0; cy <= y1; cy++) for (let cx = x0; cx <= x1; cx++) if (inGrid(cx, cy)) st.block[gi(cx, cy)] = 1; }
// ---------- Bauen ----------
function newGrid(solid) {
  st.grid = new Uint8Array(GW * GH).fill(solid ? 1 : 0); st.wh = new Uint8Array(GW * GH).fill(solid ? WALLH : 0); st.floor = new Uint8Array(GW * GH); st.deco = new Uint8Array(GW * GH);
  st.seen = new Uint8Array(GW * GH); st.sconces = []; st.rugs = []; st.stains = []; st.towers = []; st.chests = []; st.spots = []; st.rooms = [];
}
function setOpen(cx, cy, floor) { if (cx > 0 && cy > 0 && cx < GW - 1 && cy < GH - 1) { const i = gi(cx, cy); st.grid[i] = 0; st.wh[i] = 0; if (floor !== undefined) st.floor[i] = floor; } }
function setWall(cx, cy, h) { if (inGrid(cx, cy)) { const i = gi(cx, cy); st.grid[i] = 1; st.wh[i] = h; } }
const cc = (cx, cy) => ({ x: (cx + 0.5) * CELL, y: (cy + 0.5) * CELL });
const wallNbrs = (cx, cy) => (cellWall(cx + 1, cy) ? 1 : 0) + (cellWall(cx - 1, cy) ? 1 : 0) + (cellWall(cx, cy + 1) ? 1 : 0) + (cellWall(cx, cy - 1) ? 1 : 0);
function addObst(o) { if (wallAt(o.x, o.y) || st.obst.some((q) => dist(q, o) < q.r + o.r + 6)) return null; st.obst.push(o); return o; }
function addChest(x, y, tier) { const c = addObst({ x, y, r: tier === 2 ? 24 : 20, kind: "chest", v: 0, tier, open: false }); if (c) st.chests.push(c); return c; }
// Fässer und Kisten: stehen in Grüppchen an der Wand und lassen sich zerschlagen
function addCasks(x, y) { for (let k = 0; k < ri(2, 4); k++) addObst({ x: x + rnd(-20, 20), y: y + rnd(-20, 20), r: 13, kind: Math.random() < 0.6 ? "barrel" : "crate", v: ri(0, 2), brk: true }); }
// Wandfackeln und Banner: an Mauern, deren Seite zum Betrachter zeigt (Mauer nördlich oder westlich einer freien Zelle)
function dressWalls(every, banners) {
  for (let cy = 1; cy < GH - 1; cy++) for (let cx = 1; cx < GW - 1; cx++) {
    if (cellWall(cx, cy)) continue; const hsh = (cx * 73 + cy * 151) % 97;
    if (cellH(cx, cy - 1) >= 80 && cellH(cx, cy - 1) !== TOWER) { if (hsh % every === 0) st.sconces.push({ x: (cx + 0.5) * CELL, y: cy * CELL + 3, r: 150 }); else if (banners && hsh % 13 === 5) st.deco[gi(cx, cy - 1)] |= 1; }
    if (cellH(cx - 1, cy) >= 80 && cellH(cx - 1, cy) !== TOWER) { if (hsh % every === 3) st.sconces.push({ x: cx * CELL + 3, y: (cy + 0.5) * CELL, r: 150 }); else if (banners && hsh % 13 === 9) st.deco[gi(cx - 1, cy)] |= 2; }
  }
}
const isCorner = (x, y) => (cellWall(x - 1, y) || cellWall(x + 1, y)) && (cellWall(x, y - 1) || cellWall(x, y + 1)) && !(cellWall(x - 1, y) && cellWall(x + 1, y)) && !(cellWall(x, y - 1) && cellWall(x, y + 1));
const nooks = (r) => { const out = []; for (let y = r.y; y < r.y + r.h; y++) for (let x = r.x; x < r.x + r.w; x++) if (!cellWall(x, y) && isCorner(x, y)) out.push(cc(x, y)); return out.sort(() => Math.random() - 0.5); };
const sides = (r) => { const out = []; for (let y = r.y; y < r.y + r.h; y++) for (let x = r.x; x < r.x + r.w; x++) if (!cellWall(x, y) && wallNbrs(x, y) === 1) out.push(cc(x, y)); return out.sort(() => Math.random() - 0.5); };
const DPROPS = { tomb: [0, 1, 0, 2, 3, 6, 7, 9, 12], ruin: [8, 9, 9, 10, 11, 12, 14, 3], glass: [15, 15, 9, 8, 11, 12, 14, 2], vault: [15, 0, 3, 7, 2, 12, 10, 6], dorf: [3, 14, 8, 7, 3] };
const STYLES = ["ruhe", "lager", "wache", "hinterhalt", "streife"];

function genDungeon(def) {
  newGrid(true); st.indoor = true; const rooms = st.rooms;
  for (let t = 0; t < 4000 && rooms.length < 11; t++) {
    const shape = wpick([["rect", 4], ["hall", 3], ["cross", 2], ["round", 2]]), w = shape === "hall" ? ri(11, 14) : ri(7, 11), h = shape === "hall" ? ri(7, 8) : ri(6, 9), x = ri(2, GW - w - 2), y = ri(2, GH - h - 2);
    if (rooms.some((r) => x < r.x + r.w + 2 && x + w + 2 > r.x && y < r.y + r.h + 2 && y + h + 2 > r.y)) continue;
    rooms.push({ x, y, w, h, shape, cx: (x + w / 2) * CELL, cy: (y + h / 2) * CELL, kind: "" });
  }
  rooms.sort((a, b) => a.cx - b.cx); rooms[0].kind = "start";
  const boss = rooms.slice(-4).sort((a, b) => b.w * b.h - a.w * a.h)[0]; boss.kind = "boss"; if (boss.shape !== "hall") boss.shape = "rect";
  const rest = rooms.filter((r) => !r.kind).sort((a, b) => a.w * a.h - b.w * b.h); if (rest.length > 3) rest[0].kind = "schatz";
  for (const r of rooms) for (let y = r.y; y < r.y + r.h; y++) for (let x = r.x; x < r.x + r.w; x++) {
    const dx = (x + 0.5 - r.x - r.w / 2) / (r.w / 2), dy = (y + 0.5 - r.y - r.h / 2) / (r.h / 2);
    if (r.shape === "round" && dx * dx + dy * dy > 1.02) continue;
    if (r.shape === "cross" && Math.abs(dx) > 0.45 && Math.abs(dy) > 0.45) continue;
    setOpen(x, y, 0);
  }
  for (const r of rooms) if (r.shape === "hall") for (let x = r.x + 2; x < r.x + r.w - 2; x += 3) { setWall(x, r.y + 2, WALLH); setWall(x, r.y + r.h - 3, WALLH); }   // zwei Reihen Pfeiler
  const links = [], link = (a, b) => {   // Gang, zwei bis drei Zellen breit, erst waagrecht, dann senkrecht (oder umgekehrt)
    const ax = Math.floor(a.cx / CELL), ay = Math.floor(a.cy / CELL), bx = Math.floor(b.cx / CELL), by = Math.floor(b.cy / CELL), hFirst = Math.random() < 0.5, my = hFirst ? ay : by, mx = hFirst ? bx : ax, wd = ri(2, 3);
    const dig = (x, y) => { if (cellWall(x, y)) setOpen(x, y, 1); };
    for (let x = Math.min(ax, bx); x <= Math.max(ax, bx) + wd - 1; x++) for (let k = 0; k < wd; k++) dig(x, my + k);
    for (let y = Math.min(ay, by); y <= Math.max(ay, by) + wd - 1; y++) for (let k = 0; k < wd; k++) dig(mx + k, y);
    links.push([a, b]);
  };
  const dc = (a, b) => Math.hypot(a.cx - b.cx, a.cy - b.cy);
  for (let i = 1; i < rooms.length; i++) { let best = rooms[0]; for (let j = 0; j < i; j++) if (dc(rooms[j], rooms[i]) < dc(best, rooms[i])) best = rooms[j]; link(best, rooms[i]); }
  for (let k = 0; k < 2 && rooms.length > 3; k++) { const a = pick(rooms), b = pick(rooms); if (a !== b) link(a, b); }
  st.start = { x: rooms[0].cx, y: rooms[0].cy }; st.lair = { x: boss.cx, y: boss.cy };
  dressWalls(7, true);
  const mix = DPROPS[def.dungeon] || DPROPS.tomb;
  rooms.forEach((r, i) => {
    const nk = nooks(r), sd = sides(r), n = r.kind === "start" ? 2 : ri(2, 4);
    for (let k = 0; k < n && nk.length; k++) { const p = nk.pop(); addObst({ x: p.x, y: p.y, r: 22, kind: "d", v: pick(mix) }); }
    for (let k = 0; k < ri(1, 2) && sd.length; k++) { const p = sd.pop(); addCasks(p.x, p.y); }
    if (r.kind === "boss") { st.rugs.push({ x: (r.x + 2) * CELL, y: r.cy - CELL, w: (r.w - 4) * CELL, h: 2 * CELL, col: "#5c1f1c" }); const p = nk.pop(); if (p) addChest(p.x, p.y, 1); }
    else if (r.kind === "schatz") { st.rugs.push({ x: r.cx - 75, y: r.cy - 75, w: 150, h: 150, col: "#3d2a52" }); addChest(r.cx, r.cy, 2); st.spots.push({ x: r.cx, y: r.cy, style: "wache", elite: true }); }
    else if (r.kind !== "start") {
      if (Math.random() < 0.6) { const p = nk.pop(); if (p) addChest(p.x, p.y, 0); }
      if (r.shape === "rect" && Math.random() < 0.4) st.rugs.push({ x: r.cx - 100, y: r.cy - 60, w: 200, h: 120, col: pick(["#4a2420", "#2c3a4a", "#3f3520"]) });
      const style = r.shape === "round" ? "lager" : r.shape === "hall" ? "streife" : pick(["ruhe", "lager", "wache", "hinterhalt"]);
      st.spots.push({ x: r.cx + rnd(-40, 40), y: r.cy + rnd(-40, 40), style, way: [{ x: (r.x + 2) * CELL, y: r.cy }, { x: (r.x + r.w - 2) * CELL, y: r.cy }] });
      if (r.w * r.h >= 80) st.spots.push({ x: (r.x + 2) * CELL, y: (r.y + 2) * CELL, style: "ruhe", extra: true });
    }
    for (let k = 0; k < 2; k++) st.stains.push({ x: (r.x + rnd(1, r.w - 1)) * CELL, y: (r.y + rnd(1, r.h - 1)) * CELL, r: rnd(18, 46), rot: rnd(0, 3), blood: Math.random() < 0.5 });
  });
  links.filter(([a, b]) => a.kind !== "start" && b.kind !== "start" && a.kind !== "boss" && b.kind !== "boss").sort(() => Math.random() - 0.5).slice(0, 2).forEach(([a, b]) => st.spots.push({ x: (a.cx + b.cx) / 2, y: (a.cy + b.cy) / 2, style: "streife", way: [{ x: a.cx, y: a.cy }, { x: b.cx, y: b.cy }], snap: true }));
}

// Freiland: Ruinen einer Siedlung mit Kapelle, eine alte Wehrmauer mit Tor, zwei Türme
function genOutdoor(def) {
  newGrid(false); st.indoor = false; st.start = { x: 240, y: WORLD.h / 2 };
  const B = [], sx = Math.floor(st.start.x / CELL), sy = Math.floor(st.start.y / CELL);
  for (let t = 0; t < 3000 && B.length < 6; t++) {
    const w = ri(8, 12), h = ri(6, 9), x = ri(9, GW - w - 3), y = ri(3, GH - h - 3);
    if (B.some((b) => x < b.x + b.w + 3 && x + w + 3 > b.x && y < b.y + b.h + 3 && y + h + 3 > b.y) || (x < sx + 9 && Math.abs(y + h / 2 - sy) < 9)) continue;
    B.push({ x, y, w, h, ruin: rnd(0.25, 0.85), cx: (x + w / 2) * CELL, cy: (y + h / 2) * CELL });
  }
  B.sort((a, b) => a.cx - b.cx); const chapel = B[B.length - 1]; chapel.ruin = 0.3; chapel.kind = "kapelle";
  // Wehrmauer quer durchs Gelände, mit Tor und Breschen
  const wx = Math.floor(GW * 0.36), gate = ri(8, GH - 12);
  if (!B.some((b) => wx >= b.x - 2 && wx <= b.x + b.w + 1)) for (let y = 2; y < GH - 2; y++) {
    if ((y >= gate && y < gate + 4) || Math.random() < 0.07) continue;
    const hgt = Math.random() < 0.2 ? ri(14, 60) : WALLH; setWall(wx, y, hgt); if (hgt === WALLH) st.deco[gi(wx, y)] |= 4;
    if (y === gate - 1 || y === gate + 4) { setWall(wx, y, WALLH + 30); st.deco[gi(wx, y)] |= 4; }   // Torpfeiler
  }
  for (const b of B) {
    const side = ri(0, 3), dpos = side < 2 ? ri(b.x + 2, b.x + b.w - 4) : ri(b.y + 2, b.y + b.h - 4);
    for (let y = b.y; y < b.y + b.h; y++) for (let x = b.x; x < b.x + b.w; x++) {
      const edge = x === b.x || y === b.y || x === b.x + b.w - 1 || y === b.y + b.h - 1; st.floor[gi(x, y)] = 2; if (!edge) continue;
      const door = (side === 0 && y === b.y && x >= dpos && x < dpos + 2) || (side === 1 && y === b.y + b.h - 1 && x >= dpos && x < dpos + 2) || (side === 2 && x === b.x && y >= dpos && y < dpos + 2) || (side === 3 && x === b.x + b.w - 1 && y >= dpos && y < dpos + 2);
      if (door || Math.random() < b.ruin * 0.1) continue;
      setWall(x, y, Math.random() < b.ruin * 0.55 ? ri(12, 44) : Math.random() < b.ruin * 0.5 ? ri(54, 80) : WALLH);
    }
    if (b.kind !== "kapelle" && b.w >= 10 && Math.random() < 0.6) { const px2 = b.x + Math.floor(b.w / 2), gap = ri(b.y + 2, b.y + b.h - 4); for (let y = b.y + 1; y < b.y + b.h - 1; y++) if (y < gap || y > gap + 1) setWall(px2, y, Math.random() < 0.3 ? ri(14, 50) : WALLH); }   // Zwischenwand
    const r = { x: b.x + 1, y: b.y + 1, w: b.w - 2, h: b.h - 2 }, nk = nooks(r), sd = sides(r);
    if (b.kind === "kapelle") {
      st.lair = { x: b.cx, y: b.cy }; st.rugs.push({ x: (b.x + 2) * CELL, y: b.cy - 40, w: (b.w - 4) * CELL, h: 80, col: "#5c1f1c" });
      addObst({ x: (b.x + b.w - 2.5) * CELL, y: b.cy, r: 24, kind: "d", v: 6 });
      for (let x = b.x + 2; x < b.x + b.w - 3; x += 3) { addObst({ x: (x + 0.5) * CELL, y: (b.y + 2) * CELL, r: 14, kind: "d", v: 9 }); addObst({ x: (x + 0.5) * CELL, y: (b.y + b.h - 2) * CELL, r: 14, kind: "d", v: 9 }); }
      const p = nk.pop(); if (p) addChest(p.x, p.y, 1);
    } else {
      for (let k = 0; k < ri(1, 3) && nk.length; k++) { const p = nk.pop(); addObst({ x: p.x, y: p.y, r: 20, kind: "d", v: pick(DPROPS.dorf) }); }
      for (let k = 0; k < ri(1, 2) && sd.length; k++) { const p = sd.pop(); addCasks(p.x, p.y); }
      if (Math.random() < 0.7) { const p = nk.pop(); if (p) addChest(p.x, p.y, Math.random() < 0.25 ? 1 : 0); }
      st.spots.push({ x: b.cx, y: b.cy, style: pick(["lager", "ruhe", "hinterhalt", "wache"]) });
    }
    st.rooms.push({ ...r, cx: b.cx, cy: b.cy, kind: b.kind || "haus" });
  }
  if (!st.lair) st.lair = { x: WORLD.w - 300, y: WORLD.h / 2 };
  // zwei Türme als Landmarken
  for (let t = 0, n = 0; t < 200 && n < 2; t++) {
    const x = ri(4, GW - 9), y = ri(3, GH - 8); let free = true;
    for (let yy = y - 2; yy < y + 6 && free; yy++) for (let xx = x - 2; xx < x + 6; xx++) if (cellWall(xx, yy) || st.floor[gi(xx, yy)] || (Math.abs(xx - sx) < 7 && Math.abs(yy - sy) < 7)) { free = false; break; }
    if (!free || st.towers.some((q) => Math.hypot(q.cx - x, q.cy - y) < 14)) continue;
    for (let yy = y; yy < y + 4; yy++) for (let xx = x; xx < x + 4; xx++) setWall(xx, yy, TOWER);
    st.towers.push({ cx: x, cy: y, n: 4, h: 200, x: (x + 2) * CELL, y: (y + 2) * CELL }); n++;
  }
  dressWalls(11, true);
  // Felsen, Glasnadeln und Wracks im offenen Land
  for (let i = 0; i < 110; i++) {
    const o = { x: rnd(120, WORLD.w - 120), y: rnd(120, WORLD.h - 120), r: rnd(16, 40), kind: wpick(def.mix) }; o.v = o.kind === "needle" ? ri(0, 1) : pick([0, 0, 1, 1, 2, 3, 4, 5]);
    const cx = Math.floor(o.x / CELL), cy = Math.floor(o.y / CELL); let clear = true;
    for (let dy = -1; dy <= 1 && clear; dy++) for (let dx = -1; dx <= 1; dx++) if (cellWall(cx + dx, cy + dy) || st.floor[gi(cx + dx, cy + dy)]) { clear = false; break; }
    if (clear && Math.hypot(o.x - st.start.x, o.y - st.start.y) > 240 && !st.obst.some((q) => dist(o, q) < o.r + q.r + 44)) st.obst.push(o);
  }
  // Rudel im offenen Land: lagern, streifen umher oder liegen im Sand auf der Lauer
  for (let t = 0, n = 0; t < 400 && n < 9; t++) {
    const p = { x: rnd(200, WORLD.w - 200), y: rnd(200, WORLD.h - 200) };
    if (wallAt(p.x, p.y) || st.floor[gi(Math.floor(p.x / CELL), Math.floor(p.y / CELL))] || Math.hypot(p.x - st.start.x, p.y - st.start.y) < 520 || st.spots.some((q) => dist(p, q) < 330)) continue;
    const style = pick(["streife", "streife", "lager", "ruhe", "hinterhalt"]), a = rnd(0, TAU), q = freePath(p.x, p.y, clamp(p.x + Math.cos(a) * 420, 150, WORLD.w - 150), clamp(p.y + Math.sin(a) * 420, 150, WORLD.h - 150));
    st.spots.push({ ...p, style, way: [{ x: p.x, y: p.y }, q] }); n++;
  }
}
const CHEST = [{ name: "Truhe", col: "#c9a24e" }, { name: "Eisentruhe", col: "#aab3bd" }, { name: "Prunktruhe", col: "#ffd75e" }];
// Truhe: der Inhalt erscheint in einem Fenster. „Alles nehmen“ legt ihn in die Tasche, sonst bleibt er neben der Truhe liegen.
function openChest(c) {
  c.open = true; SFX.legend(); st.shake = Math.max(st.shake, 3 + c.tier * 2); burst(c.x, c.y, "#ffd75e", 20 + c.tier * 14, 220);
  const h = hero, T = c.tier, n = T === 0 ? ri(1, 2) : T === 1 ? ri(2, 3) : 3, got = [];
  for (let k = 0; k < n; k++) got.push({ item: makeItem(st.fall + (T === 2 ? 1 : 0), T === 2 ? (k === 0 && Math.random() < 0.45 ? 3 : 2) : k === 0 && T === 1 ? 2 : 1) });
  got.push({ shard: [ri(6, 14), ri(15, 30), ri(40, 60)][T] * (h.leg.shards ? 2 : 1) });
  got.push({ mat: "staub", n: ri(1, 3) + T * 2 });
  if (T > 0 || Math.random() < 0.3) got.push({ mat: T === 2 ? "stern" : pick(["leder", "eisen"]), n: 1 });
  if (got.some((g) => g.item && g.item.rar === 3)) SFX.legend();
  showChest(c, got);
}
// Fässer und Kisten zerschlagen: alles im Umkreis, das sich zerschlagen lässt
function smashAround(x, y, r) {
  if (!st.obst.some((o) => o.brk)) return;
  st.obst = st.obst.filter((o) => {
    if (!o.brk || Math.hypot(o.x - x, o.y - y) > r + o.r) return true;
    burst(o.x, o.y, "#8a6a44", 9, 150); tone(180, 0.09, "square", 0.05, -90);
    const q = Math.random();
    if (q < 0.34) st.loot.push({ x: o.x, y: o.y, shard: ri(1, 3) * (hero.leg.shards ? 2 : 1), t: 0 }); else if (q < 0.46) dropMat(o.x, o.y, "staub", 1); else if (q < 0.52) st.loot.push({ x: o.x, y: o.y, globe: true, t: 0 });
    return false;
  });
}
