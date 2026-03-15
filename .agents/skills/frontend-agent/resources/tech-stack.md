# Frontend Agent - Tech Stack Reference

## Core Stack
- **Framework**: Next.js 14+ (App Router), React 18+
- **Language**: TypeScript (strict mode)
- **Styling**: Tailwind CSS 3+ (NO inline styles)
- **Components**: shadcn/ui, Radix UI
- **State**: React Context, Zustand, or Redux Toolkit
- **Forms**: React Hook Form + Zod
- **API Client**: TanStack Query
- **Testing**: Vitest, React Testing Library, Playwright

## Code Standards
- Explicit TypeScript interfaces for props
- Tailwind classes only (no inline styles)
- Semantic HTML with ARIA labels
- Keyboard navigation support

## Project Structure

```
src/
  app/           # Next.js App Router pages
  components/
    ui/          # Reusable primitives (button, card)
    [feature]/   # Feature components
  lib/
    api/         # API clients (TanStack Query hooks)
    hooks/       # Custom hooks
  types/         # TypeScript types
```

## Serena MCP Shortcuts
- `find_symbol("ComponentName")`: Locate existing component
- `get_symbols_overview("src/components")`: List all components
- `find_referencing_symbols("Button")`: Find usages before changes
