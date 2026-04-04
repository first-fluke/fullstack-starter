"use client";

import { SerwistProvider } from "@serwist/turbopack/react";
import { QueryClientProvider } from "@tanstack/react-query";
import { Provider as JotaiProvider } from "jotai";
import dynamic from "next/dynamic";
import { type AbstractIntlMessages, NextIntlClientProvider } from "next-intl";
import { NuqsAdapter } from "nuqs/adapters/next/app";
import type { ReactNode } from "react";
import { useEffect } from "react";
import { env } from "@/config/env";
import {
  exchangeOAuthForBackendJwt,
  exchangeSessionForBackendJwt,
  hasBackendAccessToken,
  useOAuthSession,
  useSession,
} from "@/lib/auth/auth-client";
import { getQueryClient } from "@/lib/get-query-client";

const TanStackDevTools =
  env.NEXT_PUBLIC_ENABLE_DEVTOOLS === "true"
    ? dynamic(
        () => import("@/components/devtools/tanstack-devtools").then((mod) => mod.TanStackDevTools),
        { ssr: false }
      )
    : () => null;

interface ProvidersProps {
  children: ReactNode;
  locale: string;
  messages: AbstractIntlMessages;
}

function BackendJwtBridge() {
  const { data: session, isPending } = useSession();
  const { data: oauthSession, isPending: isOAuthPending } = useOAuthSession();

  const user = session?.user;
  const oauthUser = oauthSession?.user;

  useEffect(() => {
    if (isPending || isOAuthPending) return;

    if (user) return;

    if (!oauthUser) return;

    if (hasBackendAccessToken()) return;

    exchangeOAuthForBackendJwt()
      .catch(() => exchangeSessionForBackendJwt())
      .catch(() => {});
  }, [isOAuthPending, isPending, oauthUser, user]);

  return null;
}

export function Providers({ children, locale, messages }: ProvidersProps) {
  const queryClient = getQueryClient();

  return (
    <SerwistProvider swUrl="/serwist/sw.js">
      <QueryClientProvider client={queryClient}>
        <NuqsAdapter>
          <JotaiProvider>
            <BackendJwtBridge />
            <NextIntlClientProvider locale={locale} messages={messages} timeZone="Asia/Seoul">
              {children}
            </NextIntlClientProvider>
          </JotaiProvider>
          <TanStackDevTools />
        </NuqsAdapter>
      </QueryClientProvider>
    </SerwistProvider>
  );
}
