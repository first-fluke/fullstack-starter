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

## Form with React Hook Form + Zod

```tsx
"use client";

import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";

const schema = z.object({
  email: z.string().email("Invalid email"),
  password: z.string().min(8, "At least 8 characters"),
});

type FormData = z.infer<typeof schema>;

export function LoginForm({ onSubmit }: { onSubmit: (data: FormData) => void }) {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({ resolver: zodResolver(schema) });

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div>
        <label htmlFor="email" className="text-sm font-medium">
          Email
        </label>
        <input
          id="email"
          type="email"
          {...register("email")}
          className="mt-1 w-full rounded-md border px-3 py-2"
          aria-invalid={!!errors.email}
        />
        {errors.email && (
          <p className="mt-1 text-sm text-destructive">{errors.email.message}</p>
        )}
      </div>
      <div>
        <label htmlFor="password" className="text-sm font-medium">
          Password
        </label>
        <input
          id="password"
          type="password"
          {...register("password")}
          className="mt-1 w-full rounded-md border px-3 py-2"
          aria-invalid={!!errors.password}
        />
        {errors.password && (
          <p className="mt-1 text-sm text-destructive">{errors.password.message}</p>
        )}
      </div>
      <button
        type="submit"
        disabled={isSubmitting}
        className="w-full rounded-md bg-primary px-4 py-2 text-primary-foreground disabled:opacity-50"
      >
        {isSubmitting ? "Signing in..." : "Sign in"}
      </button>
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
