---
name: cache-components
description: Expert guidance for Next.js Cache Components and Partial Prerendering (PPR). PROACTIVE ACTIVATION when cacheComponents config is detected.
---

Expert guidance for Next.js Cache Components and Partial Prerendering (PPR).

**PROACTIVE ACTIVATION**: Use this skill automatically when working in Next.js projects that have `cacheComponents: true` in their `next.config.ts` or `next.config.js`.

**DETECTION**: At the start of a session in a Next.js project, check for `cacheComponents: true` in `next.config`. If enabled, this skill's patterns should guide all component authoring, data fetching, and caching decisions.

**USE CASES**:
- Implementing `'use cache'` directive
- Configuring cache lifetimes with `cacheLife()`
- Tagging cached data with `cacheTag()`
- Invalidating caches with `updateTag()` / `revalidateTag()`
- Optimizing static vs dynamic content boundaries
- Debugging cache issues
- Reviewing Cache Component implementations

## Project Detection

When starting work in a Next.js project, check if Cache Components are enabled:

```bash
# Check next.config.ts or next.config.js for cacheComponents
grep -r "cacheComponents" next.config.* 2>/dev/null
```

If `cacheComponents: true` is found, apply this skill's patterns proactively when:
- Writing React Server Components
- Implementing data fetching
- Creating Server Actions with mutations
- Optimizing page performance
- Reviewing existing component code

## Core Concept: The Caching Decision Tree

When writing a **React Server Component**, ask:

1. **Does it depend on request context?** (cookies, headers, searchParams)
2. **Can this be cached?** (Is the output the same for all users?)
   - **YES** -> `'use cache'` + `cacheTag()` + `cacheLife()`
   - **NO** -> Wrap in `<Suspense>` (dynamic streaming)

## Philosophy: Code Over Configuration

Cache Components represents a shift from segment-based configuration to compositional code:

- **Before (Deprecated)**: `export const revalidate = 3600`
- **After**: `cacheLife('hours')` inside `'use cache'`

- **Before (Deprecated)**: `export const dynamic = 'force-static'`
- **After**: Use `'use cache'` and Suspense boundaries

## Quick Start

### 1. Enable Configuration
```typescript
// next.config.ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  experimental: {
    ppr: true,
    dynamicIO: true, // often correlated features
  },
  // Ensure basic cache components flag if required by your version
};

export default nextConfig;
```

### 2. Basic Usage

```typescript
import { cacheLife } from 'next/cache';

async function CachedPosts() {
  'use cache'
  cacheLife('hours'); // Cache for hours

  const posts = await db.posts.findMany();
  return <PostList posts={posts} />;
}
```

## Core APIs

### `'use cache'`
Marks a function, component, or file as cacheable. The return value is cached and shared across requests.

### `cacheLife(profile)`
Control cache duration using semantic profiles:
- `'seconds'`: Short-lived
- `'minutes'`: Medium-lived
- `'hours'`: Long-lived
- `'days'`: Very long-lived
- `'weeks'`: Static-like content
- `'max'`: Permanent cache

### `cacheTag(...tags)`
Tag cached data for on-demand invalidation.

```typescript
import { cacheTag } from 'next/cache';

async function getUserProfile(id: string) {
  'use cache'
  cacheTag('user-profile', `user-${id}`);
  // ... fetch logic
}
```

### `revalidateTag(tag)` / `expireTag(tag)`
Invalidate cached data in background or immediately.

```typescript
'use server'
import { expireTag } from 'next/cache';

export async function updateUser(id: string, data: any) {
  await db.user.update({ where: { id }, data });
  expireTag(`user-${id}`); // Invalidate specific cache
}
```
