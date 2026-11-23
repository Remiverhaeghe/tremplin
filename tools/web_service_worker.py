"""Écrit mobile/build/web/sw.js : garde la version web en cache pour réviser sans réseau.

Le nom du cache suit le contenu construit : une nouvelle version remplace l'ancienne au
prochain lancement en ligne. Les appels à l'API du PC ne passent jamais par le cache.
"""

import hashlib
import json
import sys
from pathlib import Path


def build_script(pCache, pFiles):
    """Retourne le service worker qui met pFiles en cache sous le nom pCache."""

    rScript = f"""// Écrit par tools/web_service_worker.py à chaque construction.
const CACHE = {json.dumps(pCache)};
const FILES = {json.dumps(["./"] + pFiles)};

self.addEventListener('install', (event) => {{
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(FILES)));
  self.skipWaiting();
}});

self.addEventListener('activate', (event) => {{
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key))),
    ),
  );
  self.clients.claim();
}});

// Fichiers du site : le cache d'abord, pour s'ouvrir sans réseau. Le reste (l'API du PC,
// sur une autre origine) va toujours au réseau.
self.addEventListener('fetch', (event) => {{
  const url = new URL(event.request.url);
  if (event.request.method !== 'GET' || url.origin !== self.location.origin) {{
    return;
  }}
  event.respondWith(
    caches.match(event.request, {{ignoreSearch: true}}).then((hit) => hit || fetch(event.request)),
  );
}});
"""

    return rScript


def main(pFolder):
    """Liste les fichiers construits et écrit le service worker à côté."""

    vRoot = Path(pFolder)
    vFiles = sorted(
        vPath.relative_to(vRoot).as_posix()
        for vPath in vRoot.rglob("*")
        if vPath.is_file() and vPath.name != "sw.js"
    )
    vDigest = hashlib.sha256()

    for vName in vFiles:
        vDigest.update(vName.encode())
        vDigest.update((vRoot / vName).read_bytes())

    vCache = "tremplin-" + vDigest.hexdigest()[:12]
    (vRoot / "sw.js").write_text(build_script(vCache, vFiles), encoding="utf-8")
    print(f"{len(vFiles)} fichiers mis en cache dans {vCache}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "mobile/build/web")
