import { createSerwistRoute } from "@serwist/turbopack";
import { env } from "@/config/env";

const revision = env.NEXT_PUBLIC_GIT_COMMIT ?? crypto.randomUUID();

export const { dynamic, dynamicParams, revalidate, generateStaticParams, GET } = createSerwistRoute(
  {
    additionalPrecacheEntries: [{ revision, url: "/offline" }],
    nextConfig: {},
    swSrc: "src/app/sw.ts",
  }
);
