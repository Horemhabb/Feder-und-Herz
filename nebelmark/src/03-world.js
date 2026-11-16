// 03 · Ein Fall: Gelände, Rudel, Fortschritt
const wpick = (m) => { let t = rnd(0, m.reduce((s, x) => s + x[1], 0)); for (const [k, w] of m) if ((t -= w) <= 0) return k; return m[0][0]; };
function freeSpot(x, y, r) { return !st.obst.some((o) => Math.hypot(o.x - x, o.y - y) < o.r + r + 4); }
function spawn(type, x, y, pack, opts = {}) {
  const T = ET[type], F = st.fall, D = DIFF[hero.diff], k = Math.pow(1.28, F - 1) * D.hp, kd = Math.pow(1.2, F - 1) * D.dmg;
  const e = { type, x, y, ox: x, oy: y, r: T.r, hp: T.hp * 1.55 * k, dmg: T.dmg * 1.25 * kd, spd: T.spd, xp: T.xp * Math.pow(1.22, F - 1) * D.xp, w: T.w, active: false, cdT: rnd(0.2, 1), stun: 0, flash: 0, pack, wind: 0, pre: 0, strike: 0, slow: 0, fear: 0, mark: 0, name: T.name, kx: 0, ky: 0, dx: 0, dy: 0, face: rnd(0, TAU), ...opts };
  if (e.elite) {
    e.hp *= 3.4; e.dmg *= 1.35; e.r *= 1.25; e.w *= 3; e.xp *= 4; e.name = `${T.name}, ${e.elite.name}`;
    if (e.elite.id === "flink") e.spd *= 1.5; if (e.elite.id === "zaeh") e.hp *= 1.7; if (e.elite.id === "wild") e.dmg *= 1.4;
  }
  e.maxHp = e.hp;
  for (let i = 0; i < 12 && !freeSpot(e.x, e.y, e.r); i++) { e.x += rnd(-30, 30); e.y += rnd(-30, 30); }
  e.x = clamp(e.x, 30, WORLD.w - 30); e.y = clamp(e.y, 30, WORLD.h - 30); pushWalls(e); e.ox = e.x; e.oy = e.y;
  st.en.push(e); return e;
}
function newFall(n, quiet) {
  const def = caseDef(n);
  hero.maxFall = Math.max(hero.maxFall, n);
  st = { fall: n, def, pal: def.pal, grid: null, block: null, indoor: false, rooms: [], chests: [], spots: [], sconces: [], rugs: [], stains: [], towers: [], lair: null, flowT: 0, flow: null, en: [], shots: [], fx: [], nums: [], loot: [], obst: [], decor: [], packs: [], zones: [], late: [], dead: [], mist: [], pet: null, progress: 0, need: 1, boss: null, bossRef: null, bossSpawned: true, portal: null, t: 0, kills: 0, deaths: 0, shake: 0, start: { x: 240, y: WORLD.h / 2 }, fullT: 0 };
  for (let i = 0; i < 150; i++) st.decor.push({ x: rnd(0, WORLD.w), y: rnd(0, WORLD.h), r: rnd(40, 130), a: rnd(0.2, 0.55), rot: rnd(0.5, 1.1) });
  if (def.dungeon) genDungeon(def); else genOutdoor(def);
  for (let i = 0; i < 38; i++) st.mist.push({ x: rnd(0, WORLD.w), y: rnd(0, WORLD.h), r: rnd(160, 340), vx: rnd(6, 22), a: rnd(0.05, 0.13) });
  // Rudel: jedes hat eine Art, sich aufzuhalten. Lager sitzen ums Feuer, Wachen stehen in Reihe, Streifen laufen ihre Strecke ab,
  // manche liegen im Hinterhalt und zeigen sich erst, wenn man nah ist.
  st.block = new Uint8Array(GW * GH); st.obst.forEach(blockObst);
  // nur was vom Startpunkt aus zu Fuß erreichbar ist, wird bevölkert
  let reach = flood(Math.floor(st.start.x / CELL), Math.floor(st.start.y / CELL));
  const near = (o) => { const cx = Math.floor(o.x / CELL), cy = Math.floor(o.y / CELL); for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) if (inGrid(cx + dx, cy + dy) && reach[gi(cx + dx, cy + dy)] >= 0) return true; return false; };
  if (!near(st.lair)) {   // Einrichtung versperrt den Weg zum Bau des Endgegners: sie wird dort weggeräumt
    st.obst = st.obst.filter((o) => o.kind === "chest" || dist(o, st.lair) > 320); st.block = new Uint8Array(GW * GH); st.obst.forEach(blockObst); reach = flood(Math.floor(st.start.x / CELL), Math.floor(st.start.y / CELL));
  }
  if (!near(st.lair) && (newFall.tries = (newFall.tries || 0) + 1) < 6) return newFall(n);   // sehr selten bleibt der Bau abgeschnitten: dann wird die Karte neu ausgewürfelt
  newFall.tries = 0;
  const reachable = (o) => { const cx = Math.floor(o.x / CELL), cy = Math.floor(o.y / CELL); for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) if (inGrid(cx + dx, cy + dy) && reach[gi(cx + dx, cy + dy)] >= 0 && !cellWall(cx, cy)) return true; return false; };   // die Zelle selbst oder eine Nachbarzelle (Einrichtung versperrt nur die eigene Zelle)
  for (const sp of st.spots) {
    const p = { x: sp.x, y: sp.y, alive: 0, id: st.packs.length, style: sp.style, way: sp.way, wi: 1, awake: false, alarm: 0, field: null };
    const DF = DIFF[hero.diff];
    if (wallAt(p.x, p.y) || !reachable(p) || (sp.extra && DF.pack < 0.8)) continue;
    st.packs.push(p);
    const all = pk(pick(def.packs)), types = all.slice(0, Math.max(2, Math.round(all.length * DF.pack))), cnt = types.length, face = rnd(0, TAU);
    if (sp.style === "lager") { const fo = { x: p.x, y: p.y, r: 12, kind: "fire", v: 0 }; st.obst.push(fo); st.block[gi(Math.floor(p.x / CELL), Math.floor(p.y / CELL))] = 1; }
    types.forEach((type, i) => {
      const elite = i === 0 && (sp.elite || Math.random() < 0.2) ? pick(ELITE) : null; let ox, oy, fa = rnd(0, TAU);
      if (sp.style === "lager") { const a = i / cnt * TAU + face; ox = Math.cos(a) * rnd(58, 82); oy = Math.sin(a) * rnd(58, 82); fa = a + Math.PI; }
      else if (sp.style === "wache") { const k = (i - (cnt - 1) / 2) * 38; ox = Math.cos(face + Math.PI / 2) * k + Math.cos(face) * 46; oy = Math.sin(face + Math.PI / 2) * k + Math.sin(face) * 46; fa = face; }
      else if (sp.style === "streife") { ox = -(i % 2 ? 1 : -1) * 22 - Math.floor(i / 2) * 6; oy = -Math.floor(i / 2) * 40; }
      else { const a = i / cnt * TAU + face, rr = rnd(60, 125); ox = Math.cos(a) * rr; oy = Math.sin(a) * rr; }   // locker verteilt statt auf einem Haufen
      const fp = freePath(p.x, p.y, p.x + ox, p.y + oy), e = spawn(type, fp.x, fp.y, p.id, elite ? { elite } : {});
      if (!reachable(e)) { e.x = e.ox = p.x; e.y = e.oy = p.y; }
      e.face = fa; e.idle = sp.style === "streife" ? "patrol" : sp.style === "ruhe" ? "wander" : "stand"; e.hidden = sp.style === "hinterhalt"; e.wt = rnd(0, 3); p.alive++;
    });
  }
  st.need = st.en.reduce((s, e) => s + e.w, 0) * 0.7;
  // Der Endgegner wartet von Anfang an in seinem Bau: in der größten Halle oder in der Kapelle
  const B = def.boss, bp = freePath(st.lair.x, st.lair.y, st.lair.x + 1, st.lair.y), b = spawn("boss", bp.x, bp.y, -1, { t1: 2, t2: 6, t3: 4, charge: null, look: B.look, col: B.col, undead: B.undead });
  b.name = B.name; b.r = B.r; b.hp = b.maxHp = b.hp * B.hp; b.idle = "stand"; b.face = Math.atan2(st.start.y - b.y, st.start.x - b.x); pushOut(b); b.ox = b.x; b.oy = b.y; st.bossRef = b;
  for (const m of st.decor) if (wallAt(m.x, m.y) || (st.floor && st.floor[gi(Math.floor(m.x / CELL), Math.floor(m.y / CELL))])) m.a = 0;
  hero.x = st.start.x; hero.y = st.start.y; hero.inv = 1.5; hero.tgt = null; hero.buff = {}; hero.flurry = null; pushOut(hero);
  calcStats(); hero.hp = hero.maxHp; hero.pots = Math.min(POTS, hero.pots + 2);
  if (CLS[hero.cls].pet) st.pet = { x: hero.x - 30, y: hero.y + 20, r: 8, cd: 0, rage: 0, tgt: null, bite: 0, mv: false, face: 0 };
  const no = caseNo(n);
  $("caseNo").textContent = no; $("caseName").textContent = def.name;
  $("boss").hidden = true;
  if (!quiet) banner(def.name, no, def.lead);
  persist();
}
function bossWake() {
  const b = st.bossRef; if (!b || st.boss || !st.en.includes(b)) return;
  st.boss = b; b.active = true; $("boss").hidden = false; $("bossN").textContent = b.name; st.shake = 12; SFX.boss(); banner(st.def.boss.say, b.name.toUpperCase());
}
function banner(text, small, sub) {
  const el = document.createElement("div"); el.className = "banner"; el.setAttribute("role", "status");
  if (small) { const s = document.createElement("small"); s.textContent = small; el.append(s); }
  el.append(document.createTextNode(text));
  if (sub) { const s = document.createElement("small"); s.textContent = sub; s.style.cssText = "letter-spacing:0;color:var(--parch);margin-top:6px;font-size:.85rem"; el.append(s); el.style.animationDuration = "5.5s"; }
  const box = $("bannerBox"); box.innerHTML = ""; box.append(el);
  setTimeout(() => { if (el.parentNode) el.remove(); }, sub ? 5600 : 3300);
}
