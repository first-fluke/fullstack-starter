---
name: react-best-practices
description: React and Next.js performance optimization guidelines tuned by gracefullight, forked from Vercel Engineering. This skill should be used when writing, reviewing, or refactoring React/Next.js code to ensure optimal performance patterns. Triggers on tasks involving React components, Next.js pages, data fetching, bundle optimization, or performance improvements.
license: MIT
metadata:
  author: gracefullight
  version: "2.0.0"
  forked_from: vercel
---

# React Best Practices

Comprehensive performance optimization guide for React and Next.js applications, tuned by gracefullight (forked from Vercel Engineering). Contains 42 rules across 8 categories (some rules are enforced by Biome linter), prioritized by impact to guide automated refactoring and code generation.

## Project-Specific Notes

This project uses **Orval + React Query (@tanstack/react-query)** for API layer:
- Orval generates type-safe React Query hooks from OpenAPI specs
- **Always use Orval-generated hooks in Client Components** instead of RSC data fetching
- React Query handles caching, deduplication, and devtools
- RSC Components should handle layout, SEO metadata, and pass static props only

**React Compiler is enabled** (`reactCompiler: true` in next.config.ts):
- React Compiler automatically handles memoization (useMemo, useCallback, React.memo)
- Only use manual memoization when profiling a bottleneck or for genuinely expensive computations

## When to Apply

Reference these guidelines when:
- Writing new React components or Next.js pages
- Implementing data fetching (client or server-side)
- Reviewing code for performance issues
- Refactoring existing React/Next.js code
- Optimizing bundle size or load times

## Rule Categories by Priority

| Priority | Category | Impact | Prefix |
|----------|----------|--------|--------|
| 1 | Eliminating Waterfalls | CRITICAL | `async-` |
| 2 | Bundle Size Optimization | CRITICAL | `bundle-` |
| 3 | Server-Side Performance | HIGH | `server-` |
| 4 | Client-Side Data Fetching | MEDIUM-HIGH | `client-` |
| 5 | Re-render Optimization | MEDIUM | `rerender-` |
| 6 | Rendering Performance | MEDIUM | `rendering-` |
| 7 | JavaScript Performance | LOW-MEDIUM | `js-` |
| 8 | Advanced Patterns | LOW | `advanced-` |

## Quick Reference

### 1. Eliminating Waterfalls (CRITICAL)

- `async-defer-await` - Move await into branches where actually used
- `async-parallel` - Use Promise.all() for independent operations
- `async-dependencies` - Use better-all for partial dependencies
- `async-api-routes` - Start promises early, await late in API routes
- `async-suspense-boundaries` - Use Suspense to stream content

### 2. Bundle Size Optimization (CRITICAL)

- `bundle-dynamic-imports` - Use next/dynamic for heavy components
- `bundle-defer-third-party` - Load analytics/logging after hydration
- `bundle-conditional` - Load modules only when feature is activated
- `bundle-preload` - Preload on hover/focus for perceived speed

> Note: Barrel file imports are enforced by Biome linter (`noBarrelFile`, `noReExportAll`)

### 3. Server-Side Performance (HIGH)

- `server-after-nonblocking` - Use after() for non-blocking operations

> Note: RSC data fetching rules are excluded. This project uses Orval + React Query for API integration.

### 4. Client-Side Data Fetching (MEDIUM-HIGH)

- `client-react-compiler-optimal` - React Compiler handles memoization, only use useMemo/useCallback when profiling bottlenecks
- `client-orval-pattern` - **Always use Orval-generated hooks for API data fetching**
- `client-tanstack-query-dedup` - Use @tanstack/query for automatic request deduplication
- `client-event-listeners` - Deduplicate global event listeners

> **IMPORTANT**: Do NOT use RSC async data fetching in this project. Use Orval-generated React Query hooks instead.

### 5. Re-render Optimization (MEDIUM)

- `rerender-defer-reads` - Don't subscribe to state only used in callbacks
- `rerender-memo` - Extract expensive work into memoized components
- `rerender-dependencies` - Use primitive dependencies in effects
- `rerender-derived-state` - Subscribe to derived booleans, not raw values
- `rerender-functional-setstate` - Use functional setState for stable callbacks
- `rerender-lazy-state-init` - Pass function to useState for expensive values
- `rerender-transitions` - Use startTransition for non-urgent updates

### 6. Rendering Performance (MEDIUM)

- `rendering-animate-svg-wrapper` - Animate div wrapper, not SVG element
- `rendering-content-visibility` - Use content-visibility for long lists
- `rendering-hoist-jsx` - Extract static JSX outside components
- `rendering-svg-precision` - Reduce SVG coordinate precision
- `rendering-hydration-no-flicker` - Use inline script for client-only data
- `rendering-activity` - Use Activity component for show/hide

> Note: Conditional rendering with `&&` is enforced by Biome linter (`noLeakedRender`)

### 7. JavaScript Performance (LOW-MEDIUM)

- `js-batch-dom-css` - Group CSS changes via classes or cssText
- `js-index-maps` - Build Map for repeated lookups
- `js-cache-property-access` - Cache object properties in loops
- `js-cache-function-results` - Cache function results in module-level Map
- `js-cache-storage` - Cache localStorage/sessionStorage reads
- `js-combine-iterations` - Combine multiple filter/map into one loop
- `js-length-check-first` - Check array length before expensive comparison
- `js-early-exit` - Return early from functions
- `js-min-max-loop` - Use loop for min/max instead of sort
- `js-set-map-lookups` - Use Set/Map for O(1) lookups
- `js-tosorted-immutable` - Use toSorted() for immutability

> Note: RegExp hoisting is enforced by Biome linter (`useTopLevelRegex`)

### 8. Advanced Patterns (LOW)

- `advanced-event-handler-refs` - Store event handlers in refs
- `advanced-use-latest` - useLatest for stable callback refs

## How to Use

Read individual rule files for detailed explanations and code examples:

```
rules/async-parallel.md
rules/bundle-dynamic-imports.md
rules/_sections.md
```

Each rule file contains:
- Brief explanation of why it matters
- Incorrect code example with explanation
- Correct code example with explanation
- Additional context and references

## Full Compiled Document

For complete guide with all rules expanded: `AGENTS.md`
