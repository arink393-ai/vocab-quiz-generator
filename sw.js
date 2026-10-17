/* 單字測驗生成器 Service Worker — 離線可用
   HTML 採 network-first（確保更新即時），靜態資源 cache-first，
   跨網域（Gemini / Google）一律走網路、不快取。 */
const CACHE = 'vqg-v3';
const ASSETS = ['./', './index.html', './manifest.json', './icon.svg'];

self.addEventListener('install', e=>{
  e.waitUntil(caches.open(CACHE).then(c=>c.addAll(ASSETS)).then(()=>self.skipWaiting()));
});

self.addEventListener('activate', e=>{
  e.waitUntil(
    caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==CACHE).map(k=>caches.delete(k))))
      .then(()=>self.clients.claim())
  );
});

self.addEventListener('fetch', e=>{
  const req = e.request;
  if(req.method !== 'GET') return;
  const url = new URL(req.url);
  if(url.origin !== location.origin) return; // 讓 API 請求直接走網路

  const isDoc = req.mode === 'navigate'
    || url.pathname.endsWith('/')
    || url.pathname.endsWith('index.html');

  if(isDoc){
    // network-first：有網拿最新並更新快取，離線時回退快取
    e.respondWith(
      fetch(req).then(res=>{ const copy=res.clone(); caches.open(CACHE).then(c=>c.put(req,copy)); return res; })
        .catch(()=>caches.match(req).then(r=>r || caches.match('./index.html')))
    );
  }else{
    // cache-first：靜態資源
    e.respondWith(
      caches.match(req).then(r=>r || fetch(req).then(res=>{ const copy=res.clone(); caches.open(CACHE).then(c=>c.put(req,copy)); return res; }))
    );
  }
});
