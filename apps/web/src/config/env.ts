import { createEnv } from "@t3-oss/env-nextjs";
import { z } from "zod";

export const env = createEnv({
  server: {
    BETTER_AUTH_SECRET: z.string().min(32, "Secret must be at least 32 characters"),
    BETTER_AUTH_URL: z.string().url().optional().default("http://localhost:3000"),
    GOOGLE_CLIENT_ID: z.string().optional().or(z.literal("")),
    GOOGLE_CLIENT_SECRET: z.string().optional().or(z.literal("")),
    GITHUB_CLIENT_ID: z.string().optional().or(z.literal("")),
    GITHUB_CLIENT_SECRET: z.string().optional().or(z.literal("")),
    FACEBOOK_CLIENT_ID: z.string().optional().or(z.literal("")),
    FACEBOOK_CLIENT_SECRET: z.string().optional().or(z.literal("")),
    RESEND_API_KEY: z.string().optional().or(z.literal("")),
    EMAIL_FROM: z.string().optional().default("noreply@example.com"),
    OTEL_SERVICE_NAME: z.string().optional().default("web"),
    OTEL_SAMPLE_RATE: z
      .string()
      .optional()
      .default("0.1")
      .transform((val) => Number.parseFloat(val)),
  },

  client: {
    NEXT_PUBLIC_BETTER_AUTH_URL: z.string().url().optional().default("http://localhost:3000"),
    NEXT_PUBLIC_API_URL: z.string().url().optional().default("http://localhost:8000"),
    NEXT_PUBLIC_SITE_URL: z.string().url().optional().default("https://example.com"),
    NEXT_PUBLIC_ENABLE_DEVTOOLS: z.enum(["true", "false"]).optional().default("false"),
    NEXT_PUBLIC_GIT_COMMIT: z.string().optional(),
  },

  runtimeEnv: {
    BETTER_AUTH_SECRET: process.env.BETTER_AUTH_SECRET,
    BETTER_AUTH_URL: process.env.BETTER_AUTH_URL,
    GOOGLE_CLIENT_ID: process.env.GOOGLE_CLIENT_ID,
    GOOGLE_CLIENT_SECRET: process.env.GOOGLE_CLIENT_SECRET,
    GITHUB_CLIENT_ID: process.env.GITHUB_CLIENT_ID,
    GITHUB_CLIENT_SECRET: process.env.GITHUB_CLIENT_SECRET,
    FACEBOOK_CLIENT_ID: process.env.FACEBOOK_CLIENT_ID,
    FACEBOOK_CLIENT_SECRET: process.env.FACEBOOK_CLIENT_SECRET,
    RESEND_API_KEY: process.env.RESEND_API_KEY,
    EMAIL_FROM: process.env.EMAIL_FROM,
    OTEL_SERVICE_NAME: process.env.OTEL_SERVICE_NAME,
    OTEL_SAMPLE_RATE: process.env.OTEL_SAMPLE_RATE,
    NEXT_PUBLIC_BETTER_AUTH_URL: process.env.NEXT_PUBLIC_BETTER_AUTH_URL,
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
    NEXT_PUBLIC_SITE_URL: process.env.NEXT_PUBLIC_SITE_URL,
    NEXT_PUBLIC_ENABLE_DEVTOOLS: process.env.NEXT_PUBLIC_ENABLE_DEVTOOLS,
    NEXT_PUBLIC_GIT_COMMIT: process.env.NEXT_PUBLIC_GIT_COMMIT,
  },

  skipValidation: !!process.env.SKIP_ENV_VALIDATION,
});
