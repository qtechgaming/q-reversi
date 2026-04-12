'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "e38d8109457132335bd416bad842fe13",
"assets/AssetManifest.bin.json": "8dfee51f6e77de1e07f46bde84ba284f",
"assets/assets/AllGate.png": "8fe99f285aea02f37e5fded559326d05",
"assets/assets/AndroidApp_icon.png": "1fa3e1967de72617ddd5d77323bd55fb",
"assets/assets/App_icon.png": "37915c629fe57837b7299ba6f93c6778",
"assets/assets/blackCNOT_all.png": "d492e0169d99cc37c45a1ada89155bc4",
"assets/assets/CNOT3.png": "8cf17fade1760362ab666c309eeda4f7",
"assets/assets/CNOTgray.png": "23b74f6dbc24dcefa28955c751442ee5",
"assets/assets/coinToss.gif": "9d2840c44469d5846cd51189e9f2f985",
"assets/assets/coinToss.mp4": "bef95fddc468a2caf3f18cbe9421d5d2",
"assets/assets/entanglement.png": "f19a7f7d73f41ace3b25f2db05ead1d2",
"assets/assets/GateCheckpng.png": "dea01a265899726c1f59c0163f3356a4",
"assets/assets/gateCNOT.png": "23e51eeeab5d2d6c102af603383614a0",
"assets/assets/gateExample.png": "0bd4fdd720d18b88f7c95bcaaddd92f4",
"assets/assets/gateH.png": "f11e3fd9907e3123b5c30a626d83bcac",
"assets/assets/gateSWAP.png": "513880cde1a2bbd2b1576bf81f732a09",
"assets/assets/gateX.png": "0e60fe43edbe769d35f58f4c3b98c676",
"assets/assets/gateY.png": "f5e6e74e56b5d462c67d181009a7aff5",
"assets/assets/gateZ.png": "0625cade83033e88ed68b66adb68a85a",
"assets/assets/hand.png": "3659cd4d832cd04685ffbcdb7f9709bb",
"assets/assets/home_background.jpg": "a77b0d5cc0d5049adc9a9c5c9647fbad",
"assets/assets/home_background.png": "258055fbd5a8c3d1cc0531209e569824",
"assets/assets/home_background2.png": "4142f44142ded0bb24088426c2c3f24d",
"assets/assets/mesurement.png": "8cbb95f17cec2dfb409fb99063014618",
"assets/assets/PC_img.png": "01aafe001b49dedbd06a38177db6b4dd",
"assets/assets/QC_and_Othello.png": "b8fa78650b2f6c2c3755cc5a71efbbd8",
"assets/assets/QC_Gate.png": "4c4b81701e039cef16068b16d90be6d0",
"assets/assets/QC_img.png": "d9008cbe9fdf61673c88768fcb27457d",
"assets/assets/QReversi_FeatureGraphic.jpg": "247d876415a984f3a1bf40698da3418b",
"assets/assets/Quantum.png": "7023bb2374a43ee7432c712373b8ce8a",
"assets/assets/QuantumComputer.png": "95cda731e54c0907f42b0f851f426daf",
"assets/assets/whiteCNOT_all.png": "b9ec9e33f792b4e99fb70772c57bebe8",
"assets/assets/whiteDotArrow.png": "1303dff04c09074bba92eb4e05d73e3c",
"assets/assets/whiteLine.png": "9d4d7fae1e6520f9c0e138cf72e0e346",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/fonts/MaterialIcons-Regular.otf": "85fec98706779060099b0d0c25ce00fb",
"assets/NOTICES": "3d031b9bd65b0ba24bd288bf46c9e302",
"assets/q-reversi_challange-mode.csv": "9f7f8f51962f0a90917400f4ee263b00",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "3378c9790c1dc40687fdd83a28f66edb",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "2fa4b6cbd93d9476f6bcc06a72be11d8",
"icons/Icon-192.png": "46b293d7bf2314a483d9d6f1f3de686b",
"icons/Icon-512.png": "d3a6249403fbfe923cc5c6c718cb1b43",
"icons/Icon-maskable-192.png": "46b293d7bf2314a483d9d6f1f3de686b",
"icons/Icon-maskable-512.png": "d3a6249403fbfe923cc5c6c718cb1b43",
"index.html": "4692d10073d9725483bc61b9f2e0186c",
"/": "4692d10073d9725483bc61b9f2e0186c",
"main.dart.js": "78971b323cbc8bc7db25d2f6e3e93601",
"manifest.json": "889a4c7f1e6ee3eda09812e55e1b0cb0",
"version.json": "b783993880f8f986a021efb1ca28ed25"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
