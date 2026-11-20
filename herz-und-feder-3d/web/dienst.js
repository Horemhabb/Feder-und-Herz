// Ersatz für den Service Worker, den der Godot-Export anlegt (4.0.3).
// Der ursprüngliche hielt Seite, Programm und Spieldaten im Zwischenspeicher und lieferte sie von dort aus: Eine neue
// Fassung kam erst an, wenn alle Tabs des Spiels geschlossen waren. Dieser hier speichert nichts. Sobald ein Browser
// ihn abholt, übernimmt er sofort, leert die alten Speicher und lädt offene Seiten einmal neu. Danach kommt jede
// Fassung ganz normal über das Netz. Die Installation auf dem Home-Bildschirm (Manifest) bleibt davon unberührt.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
	event.waitUntil((async () => {
		const keys = await caches.keys();
		const alt = keys.length > 0;
		await Promise.all(keys.map((k) => caches.delete(k)));
		await self.clients.claim();
		if (alt) {
			const alle = await self.clients.matchAll({ type: 'window' });
			alle.forEach((c) => c.navigate(c.url));
		}
	})());
});
self.addEventListener('message', () => {});
