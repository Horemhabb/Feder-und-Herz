// 08 · Start und Bildschleife
hero = freshHero();
const saved = restore();
st = { fall: 1 }; calcStats(); hero.hp = hero.maxHp;
newFall(saved ? saved.fall : 1);
$("bannerBox").innerHTML = "";
$("muteBtn").textContent = muted ? "Ton aus" : "Ton an";
buildSkills(); showIntro(!saved);
if (ART.title) $("intro").style.background = `linear-gradient(rgba(5,5,10,.5), rgba(5,5,10,.86)), url("${ART.title}") center / cover no-repeat`;
resize();
let last = performance.now(), miniT = 0;
function frame(now) {
  const dt = Math.min(0.05, (now - last) / 1000); last = now;
  if (!paused) update(dt);
  adapt(dt);
  if (!$("fps").hidden && (frame.f = (frame.f || 0) + 1) % 15 === 0) $("fps").textContent = `${FPS} Bilder/s · Grafik ${GFX[GQ].name}${GMODE === "auto" ? " (auto)" : ""} · Schärfe ${Math.round(view.dpr * 100)} %`;
  draw(); hud();
  if ((miniT -= dt) <= 0) { miniT = 0.2; drawMini(); }
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
// Für Tests: Zustand und Zeitschritte von außen
window.__nm = { CLS, ET, ACT, LEGS, ART, sk: () => skIds, st: () => st, hero: () => hero, update, cast, ptr, view, makeItem, newFall, calcStats, kill, spawn, buildSkills, showGate, gateGo, enterChapter, caseDef, caseNo,
  PF, wayTo, wallAt, los, flood, flowDir: (tx, ty) => wayTo(tx, ty), toScreen: (x, y) => ({ x: (px(x, y) - view.ox) * view.zoom, y: (py(x, y) - view.oy) * view.zoom }), setPaused: (p) => { paused = p; } };
