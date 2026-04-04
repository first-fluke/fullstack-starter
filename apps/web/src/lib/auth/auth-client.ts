"use client";

import { createAuthClient } from "better-auth/react";
import { useEffect, useState } from "react";
import { env } from "@/config/env";
import { apiClient } from "@/lib/api-client";
import {
  AUTH_STATE_CHANGE_EVENT,
  clearTokens,
  getAccessToken,
  hasTokens,
  setTokens,
} from "@/lib/auth/token";

export type OAuthProviderId = "google" | "github" | "facebook";

type BackendOAuthLoginRequest = {
  provider: OAuthProviderId;
  access_token: string;
  email: string;
  name?: string | null;
};

type BackendTokenResponse = {
  access_token: string;
  refresh_token: string;
  token_type?: string;
};

type BackendUser = {
  id: string;
  email: string;
  name?: string | null;
  image?: string | null;
  email_verified: boolean;
};

type BackendSession = {
  user: BackendUser;
};

const authClient = createAuthClient({
  baseURL: env.NEXT_PUBLIC_BETTER_AUTH_URL,
});

export const { useSession: useOAuthSession, signIn, signUp } = authClient;
export const signOut = authClient.signOut;

export async function signUpWithEmail(email: string, password: string, name: string) {
  const { data } = await apiClient.post<BackendTokenResponse>("/api/auth/register", {
    email,
    password,
    name,
  });

  if (data?.access_token && data?.refresh_token) {
    setTokens(data);
  }

  return data;
}

export async function signInWithEmail(email: string, password: string) {
  const { data } = await apiClient.post<BackendTokenResponse>("/api/auth/login", {
    email,
    password,
  });

  if (data?.access_token && data?.refresh_token) {
    setTokens(data);
  }

  return data;
}

function normalizeProviderId(providerId: string): OAuthProviderId | null {
  if (providerId === "google" || providerId === "github" || providerId === "facebook") {
    return providerId;
  }
  return null;
}

async function resolveProviderFromAccounts(): Promise<OAuthProviderId | null> {
  const result = await authClient.listAccounts();
  const accounts = result.data;
  if (!accounts || result.error) return null;

  for (const account of accounts) {
    const providerId = normalizeProviderId((account as { providerId?: string }).providerId ?? "");
    if (providerId) return providerId;
  }
  return null;
}

async function loadBackendSession(): Promise<BackendSession | null> {
  if (!hasTokens()) return null;

  try {
    const { data } = await apiClient.get<BackendUser>("/api/auth/me");
    return { user: data };
  } catch {
    clearTokens();
    return null;
  }
}

export function useSession() {
  const [data, setData] = useState<BackendSession | null>(null);
  const [isPending, setIsPending] = useState(true);

  useEffect(() => {
    let cancelled = false;

    const syncSession = async () => {
      setIsPending(true);
      const session = await loadBackendSession();

      if (!cancelled) {
        setData(session);
        setIsPending(false);
      }
    };

    void syncSession();

    const handleAuthStateChange = () => {
      void syncSession();
    };

    window.addEventListener(AUTH_STATE_CHANGE_EVENT, handleAuthStateChange);
    window.addEventListener("storage", handleAuthStateChange);

    return () => {
      cancelled = true;
      window.removeEventListener(AUTH_STATE_CHANGE_EVENT, handleAuthStateChange);
      window.removeEventListener("storage", handleAuthStateChange);
    };
  }, []);

  return { data, isPending };
}

export async function exchangeOAuthForBackendJwt(providerId?: OAuthProviderId) {
  const { data: session } = await authClient.getSession();

  const email = session?.user?.email ?? null;
  if (!session?.user || !email) return;

  const resolvedProviderId = providerId ?? (await resolveProviderFromAccounts());
  if (!resolvedProviderId) return;

  const tokenResult = await authClient.getAccessToken({ providerId: resolvedProviderId });
  const accessToken = tokenResult.data?.accessToken;
  if (!accessToken || tokenResult.error) return;

  const body: BackendOAuthLoginRequest = {
    provider: resolvedProviderId,
    access_token: accessToken,
    email,
    name: session.user.name,
  };

  const { data } = await apiClient.post<BackendTokenResponse>("/api/auth/login", body);

  if (data?.access_token && data?.refresh_token) {
    setTokens(data);
  }
}

export async function exchangeSessionForBackendJwt() {
  const { data: session } = await authClient.getSession();
  if (!session?.user?.email) return;

  const sessionToken = document.cookie
    .split("; ")
    .find((row) => row.startsWith("better-auth.session_token="))
    ?.split("=")[1];

  if (!sessionToken) return;

  const { data } = await apiClient.post<BackendTokenResponse>("/api/auth/session-exchange", {
    session_token: sessionToken,
  });

  if (data?.access_token && data?.refresh_token) {
    setTokens(data);
  }
}

export async function signOutAndClearBackendTokens() {
  await authClient.signOut().catch(() => undefined);
  clearTokens();
}

export function clearBackendTokens() {
  clearTokens();
}

export function hasBackendAccessToken() {
  return Boolean(getAccessToken());
}
