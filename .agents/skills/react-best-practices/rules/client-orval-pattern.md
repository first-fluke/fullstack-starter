---
title: Use Orval-Generated Hooks for API Data Fetching
impact: HIGH
impactDescription: consistent API layer, type-safe, debuggable
tags: client, orval, react-query, api, data-fetching
---

## Use Orval-Generated Hooks for API Data Fetching

This project uses Orval to generate type-safe React Query hooks from OpenAPI specs. **Always use these generated hooks instead of RSC data fetching or manual fetch calls.**

### Why NOT to use RSC data fetching in this project:

1. **Duplicate API layer** - Orval already generates a complete, type-safe API client
2. **Debugging difficulty** - Server-side errors in RSC are harder to trace than client-side React Query errors
3. **Inconsistent patterns** - Mixing RSC fetch with React Query creates confusion
4. **Lost features** - React Query's caching, deduplication, optimistic updates, and devtools are unavailable in RSC

### Correct Pattern:

```tsx
// Use Orval-generated hooks in Client Components
"use client";

import { useGetUsers, useCreateUser } from "@/lib/api/generated";

export function UserList() {
  const { data: users, isLoading, error } = useGetUsers();
  
  if (isLoading) return <Skeleton />;
  if (error) return <ErrorMessage error={error} />;
  
  return <ul>{users?.map(user => <UserItem key={user.id} user={user} />)}</ul>;
}
```

### Incorrect Patterns:

```tsx
// Don't use RSC async data fetching
async function UserList() {
  const users = await fetch("/api/users").then(r => r.json());
  return <ul>{users.map(user => <UserItem key={user.id} user={user} />)}</ul>;
}

// Don't use manual fetch in useEffect
function UserList() {
  const [users, setUsers] = useState([]);
  useEffect(() => {
    fetch("/api/users").then(r => r.json()).then(setUsers);
  }, []);
  return <ul>{users.map(user => ...)}</ul>;
}

// Don't bypass Orval with direct axios calls
function UserList() {
  const { data } = useQuery({
    queryKey: ["users"],
    queryFn: () => axios.get("/api/users"), // Use generated hooks instead
  });
}
```

### For Mutations:

```tsx
"use client";

import { useCreateUser } from "@/lib/api/generated";

export function CreateUserForm() {
  const { mutate, isPending } = useCreateUser();
  
  const handleSubmit = (data: CreateUserInput) => {
    mutate({ data }, {
      onSuccess: () => toast.success("User created"),
      onError: (error) => toast.error(error.message),
    });
  };
  
  return <form onSubmit={handleSubmit}>...</form>;
}
```

### For Suspense:

Use the generated Suspense hooks (if `useSuspenseQuery: true` in orval.config.ts):

```tsx
"use client";

import { useGetUsersSuspense } from "@/lib/api/generated";
import { Suspense } from "react";

function UserListContent() {
  const { data: users } = useGetUsersSuspense();
  return <ul>{users.map(user => <UserItem key={user.id} user={user} />)}</ul>;
}

export function UserList() {
  return (
    <Suspense fallback={<Skeleton />}>
      <UserListContent />
    </Suspense>
  );
}
```

### Server Components Role:

Server Components should handle:
- Layout and static content
- SEO metadata
- Passing static props to Client Components

**NOT** data fetching that goes through the API layer.
