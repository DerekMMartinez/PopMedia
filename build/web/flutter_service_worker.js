'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "ab4cf54a2d4c2d6a4c9064e5a211f823",
"version.json": "cd9a95af811ff59a92d6b307a132654e",
"index.html": "22ba54be6c23207b5a5d4a011c072167",
"/": "22ba54be6c23207b5a5d4a011c072167",
"main.dart.js": "dff3cfba2579205ba5500053a72cabd2",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"favicon.png": "78da5926474836e02411033a0e92c4b5",
"manifest.json": "0ee118dc7a172fc29a60b0c9f525e4a9",
"assets/AssetManifest.json": "803d377b7f0438593ff8fcf08a9c2d73",
"assets/NOTICES": "792851eee3adbb05f931430ef9ddb183",
"assets/FontManifest.json": "b257cdaeadf5e75a3d23eeadb1dfa29f",
"assets/AssetManifest.bin.json": "515b2a956a82ee93e48a443ded78b994",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/flutter_arc_text/assets/README.md": "fbaed1ae60d80596d99545ef45d72803",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "d98b2ddbb214f05924f2e9091bafece2",
"assets/fonts/MaterialIcons-Regular.otf": "28449080d68c27f8531a51a58d3a3262",
"assets/assets/recaps/Recap2024.png": "bd4e9223607134fce3e3ef0edebaec32",
"assets/assets/recaps/Recap2025.png": "3b8dc67e08c26511bdade00efbd8a4f7",
"assets/assets/wheels/paint_wheel.png": "01a2fd19d43e2242c3e69d3605424c26",
"assets/assets/wheels/popArt_wheel.png": "0c1389baf5fd4eadfaa3ce1ed889b02a",
"assets/assets/wheels/simple_wheel.png": "1ca28549a4b66e997dde6930fe1d377d",
"assets/assets/wheels/noir_wheel.png": "1caa2bc21d3fb82b617fd963e71765d7",
"assets/assets/backgrounds/thought_bubble.png": "0472437a444498be520cb9587d2cba86",
"assets/assets/backgrounds/noir/noir_detective.jpg": "20cfb930a2ac100ccc0d312dcfecd675",
"assets/assets/backgrounds/noir/noir_pop.jpg": "5e79d9fc1402accec8cea7ca479f304d",
"assets/assets/backgrounds/noir/noir_city.png": "ce12f15b15cad9545cfe02f4e576c856",
"assets/assets/backgrounds/noir/noir_fog.jpg": "4e3df0db47c4d1a49a84d94abf415ab5",
"assets/assets/backgrounds/noir/noir_spiral.jpg": "980e8761a68cfdd9be41fd82534b6108",
"assets/assets/backgrounds/noir/noir_vibes.jpg": "fb055106bb1306e0853423f8476ef916",
"assets/assets/backgrounds/simple/simple_background.jpg": "0b77ee694fff2daf05ae747c37f5ca09",
"assets/assets/backgrounds/simple/simple_vibes.png": "c990f118ed7e41f6a513e8a5a5d396f3",
"assets/assets/backgrounds/login_screen.png": "179788ecc6b57544d3df42d0cd651e6d",
"assets/assets/backgrounds/popArt/vibey_background.png": "64fb79b71eed152d9094a3467bc81b26",
"assets/assets/backgrounds/popArt/g&w_background_vertical.jpg": "ea3c631996dd14309037407ffa650530",
"assets/assets/backgrounds/popArt/verticalBackground.png": "e6a5b79673e29d407e0492116696ce9a",
"assets/assets/backgrounds/popArt/b&w_background_vertical.jpg": "90d31502e9aace109938fca55d9cb44b",
"assets/assets/backgrounds/popArt/blue_background.jpg": "93d3f039f7ad1d04d918608cd2e23a17",
"assets/assets/backgrounds/popArt/yellow_background.jpg": "6d6c1581c1dadc9d38e5310c99c7675c",
"assets/assets/backgrounds/popArt/red_background.jpg": "70680bd6b2d97f2ef169cc3ae07812db",
"assets/assets/backgrounds/popArt/popBackground.png": "a5f35be06b387c8531f0955c8cd83b7d",
"assets/assets/backgrounds/waterColor/watercolor_blue.jpg": "e3dba839cfc9be6d1ed8f17c5ef52afb",
"assets/assets/backgrounds/waterColor/watercolor_yellow.jpg": "a0ed679cd684aaeddd7f1d244bc56431",
"assets/assets/backgrounds/waterColor/book_store.png": "fbe1404325d0b659d4d6d8d6d2439f06",
"assets/assets/backgrounds/waterColor/watercolor_mix.jpg": "7c3f623ab2efc6c225917e09122e89f1",
"assets/assets/backgrounds/waterColor/watercolor_red.jpg": "2b67ca2b1d4e3be2613e8438ffaa9380",
"assets/assets/backgrounds/waterColor/watercolor_grey.jpg": "88331c4866da8684ced6a838b0f875a3",
"assets/assets/profile/profilePic.jpg": "84e49b425df0efddbc13d736a7ae24f9",
"assets/assets/logo/logo_bw.png": "4787272b55c8fa4b0751763522feb398",
"assets/assets/logo/popLogo.png": "aa821b695221074c84900e2b980c9f33",
"assets/assets/logo/watercolor_logo.png": "8ef73e25c30149597359639dbc2d26d3",
"assets/assets/icons/book.png": "11c125c2453bcaf4dbb0fece4ed6bea9",
"assets/assets/icons/tv.png": "df3e4033fcf820eeac9b815b2895d0fd",
"assets/assets/icons/movie.png": "db9cce573e3668e4888326bc48433fc0",
"assets/assets/icons/friends_only_icon.png": "4601f773e41c094849e10288a7aec5e8",
"assets/assets/icons/private_icon.png": "5be2a56acb526b3e6d4e77e30fec4d81",
"assets/assets/icons/public_icon.png": "a9c80472b9ae3218f9747552a525e675",
"assets/assets/fonts/Bellerose.ttf": "ab35240db23f82a8bdd7390c34ab6174",
"assets/assets/fonts/ComicSansMS.ttf": "a50f9c96a76356e3d01013e0b042989f",
"assets/assets/fonts/times.ttf": "fcb8965acd0e90c50138958a2a7e0421",
"assets/assets/fonts/ARIALLGT.TTF": "f42d7a6765fb2bec8aaa344fe7340e59",
"assets/assets/fonts/FontdinerSwanky-Regular.ttf": "9445e59e97188921b871b45eed4b0086",
"assets/assets/badges/FriendBadge.png": "2f24765a21adc8e1972110b316419615",
"assets/assets/badges/OnTheTeamBadge.png": "5f2f44d9579bc021512f560a8926e662",
"assets/assets/badges/10BooksBadge.png": "4c7d54f654a68f62a2d7a6014f6e89de",
"assets/assets/badges/10MoviesBadge.png": "84595de781ff99e007bbc26694b83a22",
"assets/assets/badges/AllThreeBadge.png": "67ad4502fc0b7c6519c5599fd950cde2",
"assets/assets/badges/popBadge.png": "07ef960d50bdd0697e83b7d8f802f7e9",
"assets/assets/badges/blankBadge.png": "d03b68f3d64b0ec6c64df07899d591ad",
"assets/assets/badges/10TVBadge.png": "702b1be777b0c1a4e9407b880e9f4de5",
"assets/assets/badges/pinkBadge.png": "278890c6ae6d991a4666e6e45d73f4f1",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b"};
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
