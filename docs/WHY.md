# Why This Tech Stack?

[English](./WHY.md) | [한국어](./WHY.ko.md)

This document explains the reasoning behind each technology choice in this fullstack starter template.

## Frontend

### Next.js 16 + React 19

- **Server Components**: Reduces client-side JavaScript bundle, improves initial load time
- **App Router**: File-based routing with layouts, loading states, and error boundaries built-in
- **Turbopack**: Faster dev server and builds compared to Webpack
- **React 19**: Improved performance with concurrent features, Actions, and `use()` hook

### TailwindCSS v4

- **Zero runtime**: All styles compiled at build time
- **Lightning CSS**: 100x faster than PostCSS-based v3
- **CSS-first config**: Native CSS syntax instead of JavaScript config
- **Smaller bundles**: Automatic unused style removal

### shadcn/ui

- **Copy-paste components**: No npm dependency, full ownership of code
- **Radix primitives**: Accessible by default (ARIA, keyboard navigation)
- **Tailwind-native**: Consistent with project styling approach
- **Customizable**: Easy to modify without fighting a design system

### TanStack Query

- **Automatic caching**: Deduplication, background refetching, stale-while-revalidate
- **DevTools**: Built-in query inspector for debugging
- **Framework agnostic**: Same mental model works in React Native if needed
- **Optimistic updates**: First-class support for responsive UIs

### Jotai

- **Bottom-up atomic model**: Build state by combining atoms, optimize renders based on atom dependency
- **No extra re-renders**: Only components subscribed to changed atoms re-render
- **TypeScript-first**: Excellent type inference
- **Lightweight**: ~3KB, no providers required for basic usage

### TanStack Form

- **Headless & composable**: `withForm` HOC pattern for modular form composition with type safety
- **Type-safe**: Full TypeScript inference for form values and validation
- **Simple interface**: Cleaner API compared to React Hook Form or Formik

## Backend

### FastAPI

- **AI/ML ecosystem**: Direct access to Python's AI libraries (LangChain, Transformers, etc.)
- **Async-first**: Built on Starlette with native async/await support
- **Auto-generated docs**: OpenAPI (Swagger) and ReDoc out of the box
- **Pydantic validation**: Request/response validation with type hints
- **Scalability**: Easy horizontal scaling with stateless design

### SQLAlchemy (async)

- **ORM flexibility**: Can write raw SQL when needed, ORM when convenient
- **Async support**: Native asyncio with asyncpg driver
- **Migration-friendly**: Alembic integration for schema versioning
- **Mature ecosystem**: Battle-tested in production for decades

### PostgreSQL 16

- **ACID compliance**: Data integrity guaranteed
- **JSON support**: JSONB for flexible semi-structured data
- **Vector extension**: pgvector for AI embeddings and similarity search
- **Performance**: Advanced query planner, parallel queries, partitioning
- **Extensions**: PostGIS, full-text search built-in

### Redis 7

- **Sub-millisecond latency**: In-memory data structure store
- **Versatile**: Cache, session store, pub/sub, rate limiting
- **Persistence options**: RDB snapshots or AOF for durability
- **Cluster support**: Horizontal scaling when needed

## Mobile

### Flutter 3.38

- **Korea eGovFrame v5**: Selected as the official mobile framework by Korea e-Government Standard Framework
- **Flexible versioning**: Easy to pin and upgrade Flutter/Dart versions per project
- **Hot reload**: Sub-second UI iteration during development
- **Native performance**: Compiled to ARM, no JavaScript bridge

### Riverpod 3

- **Compile-safe**: Dependencies checked at compile time
- **Testable**: Easy to mock and test in isolation
- **No context required**: Access state from anywhere without BuildContext
- **Code generation**: Reduces boilerplate with riverpod_generator

### go_router 17

- **Declarative routing**: URL-based navigation like web
- **Deep linking**: Works out of the box for iOS/Android
- **Type-safe**: Code-generated route parameters
- **Nested navigation**: Shell routes for bottom nav, tabs

### Forui

- **shadcn/ui for Flutter**: Consistent design language with web (shadcn/ui)
- **Customizable**: Themeable components with Tailwind-like token system
- **Accessible**: ARIA-equivalent semantics for mobile
- **Lightweight**: No heavy dependencies, just widgets

### Firebase Crashlytics

- **Real-time crash reporting**: Immediate visibility into production issues
- **Breadcrumbs**: User actions leading to crash
- **Stack deobfuscation**: Readable stack traces for Flutter
- **Free tier**: Generous limits for most apps

### Fastlane

- **Automated releases**: One command to build, sign, and deploy
- **Cross-platform**: iOS and Android with same workflow
- **CI integration**: Works seamlessly with GitHub Actions
- **Metadata management**: Screenshots, descriptions, changelogs

## Infrastructure

### Terraform

- **Infrastructure as Code**: Version-controlled, reviewable infra changes
- **Declarative**: Describe desired state, let Terraform handle the rest
- **State management**: Track what's deployed, plan before apply
- **Modules**: Reusable, shareable infrastructure components

### GCP (Cloud Run, Cloud SQL, Cloud Storage)

- **Generous free tier**: $300 credit for new accounts, always-free tier for many services
- **Serverless containers**: No server management, scales to zero
- **Pay-per-use**: Only charged when handling requests
- **Managed database**: Automated backups, HA, maintenance
- **Global CDN**: Cloud CDN for static assets and API caching

### GitHub Actions + Workload Identity Federation

- **Keyless deployment**: No service account keys to manage or rotate
- **Native GitHub integration**: Triggered on push, PR, scheduled
- **Matrix builds**: Parallel testing across versions/platforms
- **Marketplace**: Thousands of community actions

## Developer Experience

### Rust-based Toolchain

We prioritize **speed** across the entire development workflow by choosing Rust-based tools:

- **Biome**: Linter + formatter in one tool, 100x faster than ESLint + Prettier
- **uv**: Python package manager, 10-100x faster than pip/poetry
- **Turbopack**: Next.js bundler, faster than Webpack
- **Lightning CSS**: TailwindCSS v4 compiler, 100x faster than PostCSS

### mise

- **Polyglot monorepo support**: Node, Python, Flutter, Terraform — different ecosystems, one tool
- **Project-local versions**: `.mise.toml` ensures consistent environments across OS during developer onboarding
- **Task runner**: Replace Makefile, npm scripts, shell scripts with unified `mise` commands
- **Written in Rust**: Instant tool switching, no startup overhead

### Polyglot Monorepo

- **Single repository**: Web (TypeScript), API (Python), Mobile (Dart), Infra (HCL) in one place
- **Bounded contexts**: Each language ecosystem is scoped to its directory, preventing cross-contamination
- **Atomic changes**: Frontend + backend changes in single PR
- **Unified tooling**: Same `mise` commands across all apps

## Trade-offs

| Choice | Trade-off | Why We Accept It |
|--------|-----------|------------------|
| Next.js over Remix/SvelteKit | Larger bundle, more complexity | Ecosystem, React 19 compatibility |
| FastAPI over Node.js | Two runtimes (Node + Python) | Python AI/ML ecosystem, scalability |
| Flutter over React Native | Larger app size, custom rendering | Korea eGovFrame v5, flexible versioning |

## Summary

This stack optimizes for:

1. **Developer velocity**: Hot reload, type safety, auto-generated clients
2. **Production readiness**: Managed services, serverless scaling, CI/CD
3. **Team scalability**: Clear boundaries, shared tooling, documentation
4. **Long-term maintainability**: Proven technologies, active communities
