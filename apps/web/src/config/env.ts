import { createEnv } from "@t3-oss/env-nextjs";
import { z } from "zod";

export const env = createEnv({
  server: {
    RESEND_API_KEY: z.string().optional().or(z.literal("")),
    EMAIL_FROM: z.string().optional().default("noreply@example.com"),
    MOBILE_ANDROID_PACKAGE_NAME: z.string().min(1).default("com.example.mobile"),
    MOBILE_ANDROID_SHA256_CERT_FINGERPRINTS: z.string().optional().default(""),
    MOBILE_APPLE_APP_IDS: z.string().optional().default(""),
    OTEL_SERVICE_NAME: z.string().optional().default("web"),
    OTEL_SAMPLE_RATE: z
      .string()
      .optional()
      .default("0.1")
      .transform((val) => Number.parseFloat(val)),
  },

  client: {
    NEXT_PUBLIC_API_URL: z.string().url().optional().default("http://localhost:8000"),
    NEXT_PUBLIC_SITE_URL: z.string().url().optional().default("https://example.com"),
    NEXT_PUBLIC_ENABLE_DEVTOOLS: z.enum(["true", "false"]).optional().default("false"),
    NEXT_PUBLIC_GIT_COMMIT: z.string().optional(),
  },

  runtimeEnv: {
    RESEND_API_KEY: process.env.RESEND_API_KEY,
    EMAIL_FROM: process.env.EMAIL_FROM,
    MOBILE_ANDROID_PACKAGE_NAME: process.env.MOBILE_ANDROID_PACKAGE_NAME,
    MOBILE_ANDROID_SHA256_CERT_FINGERPRINTS: process.env.MOBILE_ANDROID_SHA256_CERT_FINGERPRINTS,
    MOBILE_APPLE_APP_IDS: process.env.MOBILE_APPLE_APP_IDS,
    OTEL_SERVICE_NAME: process.env.OTEL_SERVICE_NAME,
    OTEL_SAMPLE_RATE: process.env.OTEL_SAMPLE_RATE,
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
    NEXT_PUBLIC_SITE_URL: process.env.NEXT_PUBLIC_SITE_URL,
    NEXT_PUBLIC_ENABLE_DEVTOOLS: process.env.NEXT_PUBLIC_ENABLE_DEVTOOLS,
    NEXT_PUBLIC_GIT_COMMIT: process.env.NEXT_PUBLIC_GIT_COMMIT,
  },

  skipValidation: !!process.env.SKIP_ENV_VALIDATION,
});
