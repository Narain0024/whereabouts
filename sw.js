/* Offline cache: after the first load the app runs without the local server. */
const VERSION = 'whereabouts-v4';
const ASSETS = ['./', 'index.html', 'manifest.webmanifest', 'css/styles.css', 'icons/icon.svg', 'icons/icon-192.png', 'icons/icon-512.png',
  'fonts/hanken-grotesk-latin-wght-normal.woff2', 'fonts/hanken-grotesk-latin-ext-wght-normal.woff2', 'fonts/jetbrains-mono-latin-wght-normal.woff2', 'fonts/fraunces-latin-wght-normal.woff2', 'fonts/fraunces-latin-wght-italic.woff2',
  'js/icons.js', 'js/util.js', 'js/db.js', 'js/expiry.js', 'js/store.js', 'js/search.js', 'js/backup.js', 'js/ui.js', 'js/items.js', 'js/notify.js',
  'js/views/dashboard.js', 'js/views/home.js', 'js/views/inventory.js', 'js/views/expiry.js', 'js/views/categories.js', 'js/views/history.js', 'js/views/reports.js', 'js/views/settings.js', 'js/views/welcome.js', 'js/app.js'];
self.addEventListener('install', e => { e.waitUntil(caches.open(VERSION).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting())); });
self.addEventListener('activate', e => { e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== VERSION).map(k => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  if (e.request.method !== 'GET' || url.origin !== location.origin || url.pathname.endsWith('__ping')) return;
  e.respondWith(caches.match(e.request, { ignoreSearch: true }).then(hit => {
    const net = fetch(e.request).then(r => { if (r.ok) { const copy = r.clone(); caches.open(VERSION).then(c => c.put(e.request, copy)); } return r; }).catch(() => hit);
    return hit || net;   /* cache first (fast + offline); refreshed in the background for next time */
  }));
});
self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(cs => {
    const c = cs[0]; if (c) { c.focus(); return c.navigate ? c.navigate(new URL('./#/expiry', self.registration.scope).href) : null; }
    return self.clients.openWindow('./#/expiry');
  }));
});
