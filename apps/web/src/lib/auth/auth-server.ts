import { betterAuth } from "better-auth";
import { nextCookies } from "better-auth/next-js";
import { env } from "@/config/env";

export const auth = betterAuth({
  baseURL: env.BETTER_AUTH_URL,
  secret: env.BETTER_AUTH_SECRET,
  socialProviders: {
    google: env.GOOGLE_CLIENT_ID
      ? {
          clientId: env.GOOGLE_CLIENT_ID,
          clientSecret: env.GOOGLE_CLIENT_SECRET,
        }
      : undefined,
    github: env.GITHUB_CLIENT_ID
      ? {
          clientId: env.GITHUB_CLIENT_ID,
          clientSecret: env.GITHUB_CLIENT_SECRET,
        }
      : undefined,
    facebook: env.FACEBOOK_CLIENT_ID
      ? {
          clientId: env.FACEBOOK_CLIENT_ID,
          clientSecret: env.FACEBOOK_CLIENT_SECRET,
        }
      : undefined,
  },
  plugins: [nextCookies()],
  session: {
    expiresIn: 60 * 60 * 24 * 7,
    cookieCache: {
      enabled: true,
      strategy: "jwe",
    },
  },
  trustedOrigins: [env.BETTER_AUTH_URL],
});

export type Session = typeof auth.$Infer.Session;
export type Auth = typeof auth;
