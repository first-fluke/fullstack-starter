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
  clearBackendTokens,
  exchangeOAuthForBackendJwt,
  exchangeSessionForBackendJwt,
  hasBackendAccessToken,
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

  const user = session?.user;

  useEffect(() => {
    if (isPending) return;

    if (!user) {
      if (hasBackendAccessToken()) {
        clearBackendTokens();
      }
      return;
    }

    if (hasBackendAccessToken()) return;

    exchangeOAuthForBackendJwt()
      .catch(() => exchangeSessionForBackendJwt())
      .catch(() => {});
  }, [isPending, user]);

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
