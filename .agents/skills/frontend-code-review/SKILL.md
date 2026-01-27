---
name: frontend-code-review
description: Standardized checklist and process for reviewing frontend code (.tsx, .ts, .js).
---

# Frontend Code Review Skill

**Intent**: Use whenever requested to review frontend code (React, Next.js, TypeScript).

**Supports**:
- **Pending-change review**: Reviewing `git diff` or staged files.
- **File-targeted review**: Reviewing specific existing files.

## Review Process

1. **Scan**: Read the code to identify architectural patterns, hooks usage, and component structure.
2. **Check**: Apply the [Review Checklist](#review-checklist).
3. **Report**: Output findings in the [Required Output Format](#required-output-format).

## Review Checklist

### 1. Code Quality & Style
- [ ] **Naming**: Are variables/functions named descriptively? (e.g., `isLoading` vs `flag`)
- [ ] **Type Safety**: Is `any` avoided? are interfaces defined clearly?
- [ ] **Constants**: Are magic numbers/strings extracted to constants?
- [ ] **Destructuring**: Is consistent destructuring used for props?

### 2. React & Next.js Best Practices
- [ ] **Hooks**: Are hooks used correctly (dependency arrays, rules of hooks)?
- [ ] **Server/Client**: Is `'use client'` used only when necessary?
- [ ] **Memoization**: Are `useMemo`/`useCallback` used appropriately (not prematurely)?
- [ ] **Keys**: Do lists have stable, unique keys?

### 3. Performance
- [ ] **Bundle Size**: Are large libraries imported entirely when tree-shaking is possible?
- [ ] **Images**: Is `next/image` used with proper sizing?
- [ ] **Renders**: Are there obvious unnecessary re-renders?

### 4. Accessibility (a11y)
- [ ] **Semantic HTML**: Are `div`s used where `button`, `section`, etc., are needed?
- [ ] **Attributes**: Do images have `alt` text? Do inputs have labels?

## Required Output Format

```markdown
# Code Review

Found <N> urgent issues:
## 1. <Issue Title>
**File**: `<path>` line `<line>`

```typescript
<snippet of problematic code>
```

**Reason**: <Why is this urgent?>
**Suggested Fix**:
```typescript
<snippet of fixed code>
```

---

Found <M> suggestions:
- **<Refactor/Style>**: <Description>
- **<Optimization>**: <Description>
```
