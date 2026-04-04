const STORAGE_PREFIX = "fullstack_";
export const AUTH_STATE_CHANGE_EVENT = "fullstack-auth-state-change";

const STORAGE_KEYS = {
  ACCESS_TOKEN: `${STORAGE_PREFIX}access_token`,
  REFRESH_TOKEN: `${STORAGE_PREFIX}refresh_token`,
};

export interface AuthTokens {
  access_token: string;
  refresh_token: string;
}

function notifyAuthStateChange(): void {
  if (typeof window !== "undefined") {
    window.dispatchEvent(new Event(AUTH_STATE_CHANGE_EVENT));
  }
}

export function getAccessToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(STORAGE_KEYS.ACCESS_TOKEN);
}

export function getRefreshToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(STORAGE_KEYS.REFRESH_TOKEN);
}

export function setAccessToken(token: string): void {
  if (typeof window !== "undefined") {
    localStorage.setItem(STORAGE_KEYS.ACCESS_TOKEN, token);
    notifyAuthStateChange();
  }
}

export function setRefreshToken(token: string): void {
  if (typeof window !== "undefined") {
    localStorage.setItem(STORAGE_KEYS.REFRESH_TOKEN, token);
    notifyAuthStateChange();
  }
}

export function setTokens(tokens: AuthTokens): void {
  if (typeof window !== "undefined") {
    localStorage.setItem(STORAGE_KEYS.ACCESS_TOKEN, tokens.access_token);
    localStorage.setItem(STORAGE_KEYS.REFRESH_TOKEN, tokens.refresh_token);
    notifyAuthStateChange();
  }
}

export function clearTokens(): void {
  if (typeof window !== "undefined") {
    localStorage.removeItem(STORAGE_KEYS.ACCESS_TOKEN);
    localStorage.removeItem(STORAGE_KEYS.REFRESH_TOKEN);
    notifyAuthStateChange();
  }
}

export function hasTokens(): boolean {
  return Boolean(getAccessToken()) && Boolean(getRefreshToken());
}
