"use client";

import { useParams, useRouter, useSearchParams } from "next/navigation";
import { useTranslations } from "next-intl";
import { Suspense, useEffect, useState } from "react";
import { exchangeOAuthCode } from "@/lib/auth/auth-client";

export default function OAuthCallbackPage() {
  const t = useTranslations("common");
  return (
    <Suspense fallback={<CallbackStatus message={t("loading")} />}>
      <OAuthCallback />
    </Suspense>
  );
}

function OAuthCallback() {
  const router = useRouter();
  const params = useParams<{ locale: string }>();
  const searchParams = useSearchParams();
  const t = useTranslations("common");
  const [error, setError] = useState<string | null>(null);
  const code = searchParams.get("code");
  const providerError = searchParams.get("error");

  useEffect(() => {
    const returnTo = searchParams.get("return_to") ?? "/";
    if (!code || providerError) return;
    let cancelled = false;
    exchangeOAuthCode(code)
      .then(() => {
        if (!cancelled) router.replace(`/${params.locale}${returnTo === "/" ? "" : returnTo}`);
      })
      .catch(() => {
        if (!cancelled) setError(t("error"));
      });
    return () => {
      cancelled = true;
    };
  }, [code, params.locale, providerError, router, searchParams, t]);

  const message = !code || providerError ? t("error") : (error ?? t("loading"));

  return <CallbackStatus message={message} alert={Boolean(!code || providerError || error)} />;
}

function CallbackStatus({ message, alert = false }: { message: string; alert?: boolean }) {
  return (
    <main className="flex min-h-screen items-center justify-center p-6">
      <p role={alert ? "alert" : "status"} className="text-sm text-muted-foreground">
        {message}
      </p>
    </main>
  );
}
