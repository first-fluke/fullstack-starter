import type { NextRequest } from "next/server";

import createMiddleware from "next-intl/middleware";
import { routing } from "@/lib/i18n/routing";

const intlMiddleware = createMiddleware(routing);

export async function proxy(request: NextRequest) {
  const { nextUrl } = request;

  const response = intlMiddleware(request);

  response.headers.set("x-pathname", nextUrl.pathname);

  return response;
}

export const config = {
  matcher: [
    // Match all pathnames except for:
    // - api routes
    // - _next (Next.js internals)
    // - _vercel (Vercel internals)
    // - .well-known (native app association files)
    // - static files (images, fonts, etc.)
    "/((?!api|_next|_vercel|\\.well-known|.*\\..*).*)",
  ],
};
