"use client";

import { useEffect, useState } from "react";
import { env } from "@/config/env";
import { apiClient } from "@/lib/api-client";
import {
  AUTH_STATE_CHANGE_EVENT,
  type AuthTokens,
  clearTokens,
  getAccessToken,
  getRefreshToken,
  hasTokens,
  setTokens,
} from "@/lib/auth/token";

export type OAuthProviderId = "google" | "github" | "facebook";

interface BackendUser {
  id: string;
  email: string;
  name?: string | null;
  image?: string | null;
  email_verified: boolean;
}

interface BackendSession {
  user: BackendUser;
}

interface PasskeyOptionsResponse {
  ceremony_id: string;
  public_key: Record<string, unknown>;
}

function base64UrlToArrayBuffer(value: string): ArrayBuffer {
  const padding = "=".repeat((4 - (value.length % 4)) % 4);
  const binary = atob(value.replaceAll("-", "+").replaceAll("_", "/") + padding);
  const bytes = Uint8Array.from(binary, (character) => character.charCodeAt(0));
  return bytes.buffer;
}

function arrayBufferToBase64Url(value: ArrayBuffer | null): string | null {
  if (value === null) return null;
  const binary = Array.from(new Uint8Array(value), (byte) => String.fromCharCode(byte)).join("");
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

function parseCreationOptions(value: Record<string, unknown>): PublicKeyCredentialCreationOptions {
  const user = value.user as Record<string, unknown>;
  const excludeCredentials = (value.excludeCredentials ?? []) as Record<string, unknown>[];
  return {
    ...value,
    challenge: base64UrlToArrayBuffer(value.challenge as string),
    user: { ...user, id: base64UrlToArrayBuffer(user.id as string) },
    excludeCredentials: excludeCredentials.map((credential) => ({
      ...credential,
      id: base64UrlToArrayBuffer(credential.id as string),
    })),
  } as PublicKeyCredentialCreationOptions;
}

function parseRequestOptions(value: Record<string, unknown>): PublicKeyCredentialRequestOptions {
  const allowCredentials = (value.allowCredentials ?? []) as Record<string, unknown>[];
  return {
    ...value,
    challenge: base64UrlToArrayBuffer(value.challenge as string),
    allowCredentials: allowCredentials.map((credential) => ({
      ...credential,
      id: base64UrlToArrayBuffer(credential.id as string),
    })),
  } as PublicKeyCredentialRequestOptions;
}

function serializeRegistrationCredential(credential: PublicKeyCredential) {
  const response = credential.response as AuthenticatorAttestationResponse;
  return {
    id: credential.id,
    rawId: arrayBufferToBase64Url(credential.rawId),
    type: credential.type,
    response: {
      attestationObject: arrayBufferToBase64Url(response.attestationObject),
      clientDataJSON: arrayBufferToBase64Url(response.clientDataJSON),
      transports: response.getTransports?.() ?? [],
    },
    clientExtensionResults: credential.getClientExtensionResults(),
    authenticatorAttachment: credential.authenticatorAttachment,
  };
}

function serializeAuthenticationCredential(credential: PublicKeyCredential) {
  const response = credential.response as AuthenticatorAssertionResponse;
  return {
    id: credential.id,
    rawId: arrayBufferToBase64Url(credential.rawId),
    type: credential.type,
    response: {
      authenticatorData: arrayBufferToBase64Url(response.authenticatorData),
      clientDataJSON: arrayBufferToBase64Url(response.clientDataJSON),
      signature: arrayBufferToBase64Url(response.signature),
      userHandle: arrayBufferToBase64Url(response.userHandle),
    },
    clientExtensionResults: credential.getClientExtensionResults(),
    authenticatorAttachment: credential.authenticatorAttachment,
  };
}

export async function signUpWithEmail(email: string, password: string, name: string) {
  const { data } = await apiClient.post<AuthTokens>("/api/auth/register", {
    email,
    password,
    name,
  });
  setTokens(data);
  return data;
}

export async function signInWithEmail(email: string, password: string) {
  const { data } = await apiClient.post<AuthTokens>("/api/auth/login", { email, password });
  setTokens(data);
  return data;
}

export function startOAuthSignIn(
  provider: OAuthProviderId,
  callbackPath: string,
  returnTo = "/"
): void {
  const redirectUri = new URL(callbackPath, window.location.origin).toString();
  const url = new URL(`/api/auth/oauth/${provider}/authorize`, env.NEXT_PUBLIC_API_URL);
  url.searchParams.set("redirect_uri", redirectUri);
  url.searchParams.set("return_to", returnTo);
  window.location.assign(url);
}

export async function exchangeOAuthCode(code: string): Promise<AuthTokens> {
  const { data } = await apiClient.post<AuthTokens>("/api/auth/oauth/exchange", { code });
  setTokens(data);
  return data;
}

export async function registerPasskey(): Promise<void> {
  if (!window.PublicKeyCredential) throw new Error("Passkeys are not supported by this browser");
  const { data } = await apiClient.post<PasskeyOptionsResponse>(
    "/api/auth/passkeys/register/options"
  );
  const credential = (await navigator.credentials.create({
    publicKey: parseCreationOptions(data.public_key),
  })) as PublicKeyCredential | null;
  if (!credential) throw new Error("Passkey registration was cancelled");
  await apiClient.post("/api/auth/passkeys/register/verify", {
    ceremony_id: data.ceremony_id,
    credential: serializeRegistrationCredential(credential),
  });
}

export async function signInWithPasskey(email: string): Promise<AuthTokens> {
  if (!window.PublicKeyCredential) throw new Error("Passkeys are not supported by this browser");
  const { data } = await apiClient.post<PasskeyOptionsResponse>(
    "/api/auth/passkeys/authenticate/options",
    { email }
  );
  const credential = (await navigator.credentials.get({
    publicKey: parseRequestOptions(data.public_key),
  })) as PublicKeyCredential | null;
  if (!credential) throw new Error("Passkey authentication was cancelled");
  const response = await apiClient.post<AuthTokens>("/api/auth/passkeys/authenticate/verify", {
    ceremony_id: data.ceremony_id,
    credential: serializeAuthenticationCredential(credential),
  });
  setTokens(response.data);
  return response.data;
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
      const session = await loadBackendSession();
      if (!cancelled) {
        setData(session);
        setIsPending(false);
      }
    };
    void syncSession();
    const handleAuthStateChange = () => void syncSession();
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

export async function signOut(): Promise<void> {
  const refreshToken = getRefreshToken();
  try {
    if (refreshToken) {
      await apiClient.post("/api/auth/logout", { refresh_token: refreshToken });
    }
  } catch {
    // Local logout must still complete if server-side revocation is unavailable.
  } finally {
    clearTokens();
  }
}

export function hasBackendAccessToken(): boolean {
  return Boolean(getAccessToken());
}
