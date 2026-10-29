// Primero la red (para recibir siempre la última versión) y la caché si no hay conexión
const CACHE = 'calca-v3';
// Caché temporal donde se deja lo que llega desde el menú «Compartir» hasta que la app lo recoge
const SHARE = 'calca-share';
const FILES = ['./', 'index.html', 'manifest.json', 'icon.svg', 'icon-192.png', 'icon-512.png'];
self.addEventListener('install', e => {
  self.skipWaiting();
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(FILES)));
});
self.addEventListener('activate', e => e.waitUntil(
  caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE && k !== SHARE).map(k => caches.delete(k))))
    .then(() => self.clients.claim())));

// Recibe una imagen o un enlace compartido desde otra app y abre la app para cargarlo
async function receiveShare(request) {
  const form = await request.formData();
  const cache = await caches.open(SHARE);
  await Promise.all([cache.delete('shared-file'), cache.delete('shared-text')]);
  const file = form.getAll('image').find(f => f && f.type && f.type.startsWith('image/'));
  if (file) await cache.put('shared-file', new Response(file, { headers:{ 'content-type':file.type } }));
  else await cache.put('shared-text', new Response(['url', 'text', 'title'].map(k => form.get(k)).filter(Boolean).join(' ')));
  return Response.redirect(new URL('./?shared=1', self.registration.scope).href, 303);
}

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  if (url.origin !== location.origin) return;
  if (e.request.method === 'POST' && url.pathname.endsWith('/share')) { e.respondWith(receiveShare(e.request)); return; }
  if (e.request.method !== 'GET') return;
  e.respondWith(fetch(e.request).then(res => {
    if (res.ok) { const copy = res.clone(); caches.open(CACHE).then(c => c.put(e.request, copy)); }
    return res;
  }).catch(() => caches.match(e.request)));
});
