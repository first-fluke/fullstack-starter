import type { NextRequest } from "next/server";

import { NextResponse } from "next/server";
import createMiddleware from "next-intl/middleware";
import { routing } from "@/lib/i18n/routing";

const intlMiddleware = createMiddleware(routing);

/**
 * Security headers for the application
 * @see https://nextjs.org/docs/advanced-features/security-headers
 */
function getSecurityHeaders(): Record<string, string> {
  return {
    // Prevent clickjacking attacks
    "X-Frame-Options": "DENY",

    // Prevent MIME type sniffing
    "X-Content-Type-Options": "nosniff",

    // Control referrer information
    "Referrer-Policy": "strict-origin-when-cross-origin",

    // Disable browser features that are not needed
    "Permissions-Policy": "camera=(), microphone=(), geolocation=(), interest-cohort=()",

    // Force HTTPS (only in production)
    ...(process.env.NODE_ENV === "production" && {
      "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
    }),

    // Content Security Policy
    "Content-Security-Policy": [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: blob: https:",
      "font-src 'self' data:",
      "connect-src 'self' https:",
      "frame-ancestors 'none'",
      "base-uri 'self'",
      "form-action 'self'",
    ].join("; "),
  };
}

export async function proxy(request: NextRequest) {
  const { nextUrl } = request;

  // Apply i18n middleware
  const response = intlMiddleware(request);

  // Add security headers to response
  const securityHeaders = getSecurityHeaders();
  for (const [key, value] of Object.entries(securityHeaders)) {
    response.headers.set(key, value);
  }

  // Add pathname header for layout to extract locale
  response.headers.set("x-pathname", nextUrl.pathname);

  return response;
}

export const config = {
  matcher: [
    // Match all pathnames except for:
    // - api routes
    // - _next (Next.js internals)
    // - _vercel (Vercel internals)
    // - static files (images, fonts, etc.)
    "/((?!api|_next|_vercel|.*\\..*).*)",
  ],
};
