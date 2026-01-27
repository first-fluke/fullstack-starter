---
name: frontend-engineer
description: Develop production-grade frontend code using shadcn/ui, best practices, and strict design alignment.
---

Guidelines for maintainable, accessible, and system-compliant frontend development.

# Core Principles
1.  **Component Reuse**: Use `shadcn/ui` components first. Extend via `cva` variants or composition. Avoid custom CSS.
2.  **Design Fidelity**: Code must map 1:1 to Design Tokens. Resolve discrepancies before implementation.
3.  **Rendering Strategy**: Default to Server Components for performance. Use Client Components only for interactivity and API integration.
4.  **Accessibility**: Semantic HTML and screen reader compatibility are mandatory.
5.  **Tool First**: Check for existing solutions and tools before coding.

# 1. Tooling & Performance
-   **Reference**: Consult `react-best-practices` skill for deep dives.
-   **Metrics**: Target First Contentful Paint (FCP) < 1s.
-   **Optimization**: Use `next/dynamic` for heavy components, `next/image` for media, and parallel routes.
-   **Shadcn Workflow**:
    1.  Search: `shadcn_search_items_in_registries`
    2.  Review: `shadcn_get_item_examples_from_registries`
    3.  Install: `shadcn_get_add_command_for_items`

# 2. Architecture (FSD-lite)
-   **Root (`src/`)**: Shared logic (components, lib, types). Hoist common code here.
-   **Feature (`src/features/*/`)**: Feature-specific logic. **No cross-feature imports.** Unidirectional flow only.
-   **Libraries**:
    -   Date: `luxon`
    -   Styling: `TailwindCSS v4` + `shadcn/ui`
    -   Hooks: `ahooks` (Pre-made hooks preferred)
    -   Utils: `es-toolkit` (First choice)

# 3. Standards
-   **Utilities**: Check `es-toolkit` first. If implementing custom logic, **>90% Unit Test Coverage** is MANDATORY.
-   **Design Tokens**: Source of Truth is `packages/design-tokens` (OKLCH). Never hardcode colors. Run `mise tokens:build` after updates.
-   **i18n**: Source of Truth is `packages/i18n`. Never hardcode strings. Run `mise i18n:build` after updates.

# 4. Component Strategy
-   **Server Components**: Use for Layouts, Marketing pages, and SEO metadata (`generateMetadata`, `sitemap`).
-   **Client Components**: Use for interactive features and `useQuery` (Orval) hooks.
-   **Structure**: **One Component Per File**.
-   **Naming**:
    -   Files: `kebab-case.tsx` (Name MUST clearly indicate purpose/functionality).
    -   Components/Types/Interfaces: `PascalCase`
    -   Functions/Vars/Hooks: `camelCase`
    -   Constants: `SCREAMING_SNAKE_CASE`
-   **Skeletons**: Must be placed in `src/features/[feature]/components/skeleton/`.
-   **Imports**: Standard > 3rd Party > Local (Absolute `@/` is MANDATORY; No relative paths like `../../`). **MUST use `import type`** for interfaces/types.
-   **State Management**:
    -   URL: `jotai-location`
    -   Server: `TanStack Query`
    -   Client Global: `Jotai` (Minimize use)
    -   Forms: `@tanstack/react-form` + `zod` (Refer to v4 docs; NO deprecated APIs)

# 5. UI Implementation (Shadcn/UI)
-   **Patterns**: Review `.agent/skills/frontend-engineer/examples/` for mandated implementation patterns.
-   **Usage**: Prefer strict shadcn primitives (`Card`, `Sheet`, `Typography`, `Table`) over `div` or generic classes.
-   **Responsiveness**: Use `Drawer` (Mobile) vs `Dialog` (Desktop) via `useResponsive`.
-   **Customization Rule**: Treat `components/ui/*` as read-only. Do not modify directly.
    -   **Correct**: create a wrapper (e.g., `components/common/ProductButton.tsx`) or use `cva` composition.
    -   **Incorrect**: Editing `components/ui/button.tsx`.

# 6. Designer Collaboration
-   **Sync**: Map code variables to Figma layer names.
-   **UX**: Ensure key actions are visible "Above the Fold". Verify clarity of usage.

# 7. Review Checklist
-   [ ] **A11y**: Interactive elements have `aria-label`. Semantic headings (`h1`-`h6`).
-   [ ] **Mobile**: functionality verified on mobile viewports.
-   [ ] **Performance**: No CLS, fast load.
-   [ ] **Resilience**: Error Boundaries and Loading Skeletons implemented.
-   [ ] **Tests**: Logic covered by Vitest where complex.
-   [ ] **Quality**: Refactor until Typecheck and Lint (`pnpm lint`) pass.
