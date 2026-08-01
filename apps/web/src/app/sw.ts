import { defaultCache } from "@serwist/turbopack/worker";
import type { PrecacheEntry, SerwistGlobalConfig } from "serwist";
import { Serwist } from "serwist";

const sameOriginCache = defaultCache.filter((rule) => {
  if (typeof rule.handler !== "object" || !("cacheName" in rule.handler)) {
    return true;
  }
  return rule.handler.cacheName !== "cross-origin";
});

declare global {
  interface WorkerGlobalScope extends SerwistGlobalConfig {
    __SW_MANIFEST: (PrecacheEntry | string)[] | undefined;
  }
}

declare const self: ServiceWorkerGlobalScope;

// Precache the offline fallback only. `__SW_MANIFEST` otherwise pulls in every
// build asset, which is not what this service worker is for.
const precacheEntries = (self.__SW_MANIFEST ?? []).filter(
  (entry) => (typeof entry === "string" ? entry : entry.url) === "/offline"
);

const serwist = new Serwist({
  clientsClaim: true,
  fallbacks: {
    entries: [
      {
        matcher({ request }) {
          return request.destination === "document";
        },
        url: "/offline",
      },
    ],
  },
  navigationPreload: true,
  precacheEntries,
  runtimeCaching: sameOriginCache,
  skipWaiting: true,
});

serwist.addEventListeners();
