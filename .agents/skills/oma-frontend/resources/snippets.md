# Frontend Agent - Code Snippets

Copy-paste ready patterns. Use these as starting points, adapt to the specific task.

---

## React Component with Props

```tsx
interface CardProps {
  title: string;
  description?: string;
  onClick?: () => void;
}

export function Card({ title, description, onClick }: CardProps) {
  return (
    <button
      onClick={onClick}
      className="rounded-lg border bg-card p-4 text-left shadow-sm transition-colors hover:bg-accent"
    >
      <h3 className="text-lg font-semibold">{title}</h3>
      {description && (
        <p className="mt-1 text-sm text-muted-foreground">{description}</p>
      )}
    </button>
  );
}
```

---

## TanStack Query Hook

```tsx
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";

interface Todo {
  id: string;
  title: string;
  completed: boolean;
}

export function useTodos() {
  return useQuery<Todo[]>({
    queryKey: ["todos"],
    queryFn: async () => {
      const res = await fetch("/api/todos", {
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      if (!res.ok) throw new Error("Failed to fetch");
      return res.json();
    },
  });
}

export function useCreateTodo() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (data: { title: string }) => {
      const res = await fetch("/api/todos", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${getToken()}`,
        },
        body: JSON.stringify(data),
      });
      if (!res.ok) throw new Error("Failed to create");
      return res.json();
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["todos"] }),
  });
}
```

---

## Form with TanStack Form + Zod

```tsx
"use client";

import { useForm } from "@tanstack/react-form";
import { zodValidator } from "@tanstack/zod-form-adapter";
import { z } from "zod";

const schema = z.object({
  email: z.string().email("Invalid email"),
  password: z.string().min(8, "At least 8 characters"),
});

export function LoginForm({ onSubmit }: { onSubmit: (data: z.infer<typeof schema>) => void }) {
  const form = useForm({
    defaultValues: { email: "", password: "" },
    validatorAdapter: zodValidator(),
    validators: { onChange: schema },
    onSubmit: async ({ value }) => onSubmit(value),
  });

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        e.stopPropagation();
        form.handleSubmit();
      }}
      className="space-y-4"
    >
      <form.Field name="email">
        {(field) => (
          <div>
            <label htmlFor="email" className="text-sm font-medium">
              Email
            </label>
            <input
              id="email"
              type="email"
              value={field.state.value}
              onChange={(e) => field.handleChange(e.target.value)}
              onBlur={field.handleBlur}
              className="mt-1 w-full rounded-md border px-3 py-2"
              aria-invalid={field.state.meta.errors.length > 0}
            />
            {field.state.meta.errors.length > 0 && (
              <p className="mt-1 text-sm text-destructive">{field.state.meta.errors[0]}</p>
            )}
          </div>
        )}
      </form.Field>
      <form.Field name="password">
        {(field) => (
          <div>
            <label htmlFor="password" className="text-sm font-medium">
              Password
            </label>
            <input
              id="password"
              type="password"
              value={field.state.value}
              onChange={(e) => field.handleChange(e.target.value)}
              onBlur={field.handleBlur}
              className="mt-1 w-full rounded-md border px-3 py-2"
              aria-invalid={field.state.meta.errors.length > 0}
            />
            {field.state.meta.errors.length > 0 && (
              <p className="mt-1 text-sm text-destructive">{field.state.meta.errors[0]}</p>
            )}
          </div>
        )}
      </form.Field>
      <form.Subscribe selector={(state) => [state.canSubmit, state.isSubmitting]}>
        {([canSubmit, isSubmitting]) => (
          <button
            type="submit"
            disabled={!canSubmit}
            className="w-full rounded-md bg-primary px-4 py-2 text-primary-foreground disabled:opacity-50"
          >
            {isSubmitting ? "Signing in..." : "Sign in"}
          </button>
        )}
      </form.Subscribe>
    </form>
  );
}
```

---

## Loading / Error / Empty States

```tsx
interface AsyncStateProps<T> {
  data: T | undefined;
  isLoading: boolean;
  error: Error | null;
  empty: React.ReactNode;
  children: (data: T) => React.ReactNode;
}

export function AsyncState<T>({ data, isLoading, error, empty, children }: AsyncStateProps<T>) {
  if (isLoading) return <div className="flex justify-center p-8"><Spinner /></div>;
  if (error) return <ErrorCard message={error.message} />;
  if (!data || (Array.isArray(data) && data.length === 0)) return <>{empty}</>;
  return <>{children(data)}</>;
}
```

---

## Responsive Grid Layout

```tsx
export function StatsGrid({ children }: { children: React.ReactNode }) {
  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
      {children}
    </div>
  );
}
```

---

## Email Auth - better-auth + Resend (Server Config)

```typescript
// src/lib/auth/auth-server.ts
import { betterAuth } from "better-auth";
import { nextCookies } from "better-auth/next-js";
import { Resend } from "resend";
import { env } from "@/config/env";

const resend = new Resend(env.RESEND_API_KEY);

export const auth = betterAuth({
  baseURL: env.BETTER_AUTH_URL,
  secret: env.BETTER_AUTH_SECRET,
  emailAndPassword: {
    enabled: true,
    requireEmailVerification: true,
    sendResetPassword: async ({ user, url }) => {
      void resend.emails.send({
        from: env.EMAIL_FROM,
        to: user.email,
        subject: "비밀번호 재설정",
        html: `<a href="${url}">비밀번호 재설정하기</a>`,
      });
    },
  },
  emailVerification: {
    sendOnSignUp: true,
    sendVerificationEmail: async ({ user, url }) => {
      void resend.emails.send({
        from: env.EMAIL_FROM,
        to: user.email,
        subject: "이메일 인증",
        html: `<a href="${url}">이메일 인증하기</a>`,
      });
    },
  },
  socialProviders: {
    // ... existing OAuth providers
  },
  plugins: [nextCookies()],
  session: {
    expiresIn: 60 * 60 * 24 * 7,
    cookieCache: { enabled: true, strategy: "jwe" },
  },
  trustedOrigins: [env.BETTER_AUTH_URL],
});
```

---

## Email Auth - Client (Sign Up / Sign In / Verify)

```typescript
// src/lib/auth/auth-client.ts
import { createAuthClient } from "better-auth/react";
import { env } from "@/config/env";

export const authClient = createAuthClient({
  baseURL: env.NEXT_PUBLIC_BETTER_AUTH_URL,
});

// Sign up with email
export async function signUpWithEmail(email: string, password: string, name: string) {
  return authClient.signUp.email({
    email,
    password,
    name,
    callbackURL: "/",
  });
}

// Sign in with email
export async function signInWithEmail(email: string, password: string) {
  return authClient.signIn.email(
    { email, password },
    {
      onError: (ctx) => {
        if (ctx.error.status === 403) {
          // Email not verified - show verification prompt
        }
      },
    },
  );
}

// Resend verification email
export async function resendVerificationEmail(email: string) {
  return authClient.sendVerificationEmail({
    email,
    callbackURL: "/",
  });
}

// Request password reset
export async function requestPasswordReset(email: string) {
  return authClient.requestPasswordReset({
    email,
    redirectTo: "/reset-password",
  });
}

// Reset password with token
export async function resetPassword(token: string, newPassword: string) {
  return authClient.resetPassword({
    newPassword,
    token,
  });
}
```

---

## Email Auth - Backend Token Exchange (Bridge)

Email auth에는 OAuth provider token이 없으므로, better-auth 세션 기반으로 백엔드 JWE 토큰을 교환합니다.

```typescript
// src/lib/auth/auth-client.ts - exchangeSessionForBackendJwt 추가
export async function exchangeSessionForBackendJwt() {
  const { data: session } = await authClient.getSession();
  if (!session?.user?.email) return;

  // email auth 유저는 OAuth provider가 없음
  // better-auth 세션 토큰으로 백엔드에 직접 인증 요청
  const sessionToken = document.cookie
    .split("; ")
    .find((row) => row.startsWith("better-auth.session_token="))
    ?.split("=")[1];

  if (!sessionToken) return;

  const { data } = await apiClient.post<BackendTokenResponse>(
    "/api/auth/session-exchange",
    { session_token: sessionToken },
  );

  if (data?.access_token) setAccessToken(data.access_token);
  if (data?.refresh_token) setRefreshToken(data.refresh_token);
}
```

```typescript
// src/app/providers.tsx - BackendJwtBridge 수정
function BackendJwtBridge() {
  const { data: session, isPending } = useSession();
  const user = session?.user;

  useEffect(() => {
    if (isPending) return;
    if (!user) {
      if (hasBackendAccessToken()) clearBackendTokens();
      return;
    }
    if (hasBackendAccessToken()) return;

    // OAuth 유저는 기존 flow, email 유저는 session exchange
    exchangeOAuthForBackendJwt()
      .catch(() => exchangeSessionForBackendJwt())
      .catch(() => {});
  }, [isPending, user]);

  return null;
}
```

---

## Email Auth - Environment Variables

```typescript
// src/config/env.ts - 추가할 환경변수
server: {
  // ... existing
  RESEND_API_KEY: z.string().min(1),
  EMAIL_FROM: z.string().email().optional().default("noreply@yourdomain.com"),
},
```

---

## Vitest Component Test

```tsx
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, it, expect, vi } from "vitest";
import { Card } from "./Card";

describe("Card", () => {
  it("renders title and description", () => {
    render(<Card title="Test" description="Desc" />);
    expect(screen.getByText("Test")).toBeInTheDocument();
    expect(screen.getByText("Desc")).toBeInTheDocument();
  });

  it("calls onClick when clicked", async () => {
    const onClick = vi.fn();
    render(<Card title="Test" onClick={onClick} />);
    await userEvent.click(screen.getByText("Test"));
    expect(onClick).toHaveBeenCalledOnce();
  });
});
```
