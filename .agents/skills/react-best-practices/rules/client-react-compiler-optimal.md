---
title: Use useMemo/useCallback Only When React Compiler is Disabled
impact: LOW
impactDescription: React Compiler handles most memoization automatically
tags: client, react-compiler, performance, memoization
---

## Use useMemo/useCallback Only When React Compiler is Disabled

**IMPORTANT:** React Compiler (enabled in this project) automatically handles memoization for `useMemo`, `useCallback`, `React.memo`. You only need these hooks when React Compiler is disabled.

### React Compiler vs Manual Memoization

| Feature | React Compiler (Enabled) | Manual Memoization |
|----------|----------------------|-------------------|
| Function memoization | Automatic | Redundant |
| Prop memoization | Automatic | Redundant |
| Dependency analysis | Automatic | Redundant |
| Bailout optimization | Automatic | Redundant |

### When to Still Use useMemo/useCallback

Even with React Compiler enabled, there are **rare cases** where manual memoization might help:

#### 1. Expensive Computations NOT in Render Path

```tsx
// Correct: Memoize expensive computation
function ExpensiveChart({ data }: { data: DataPoint[] }) {
  const processedData = useMemo(() => {
    return data.map(point => ({
      x: point.x * 1000, // Expensive transform
      y: Math.log(point.y) // Expensive calculation
    }))
  }, [data])

  return <Chart data={processedData} />
}
```

```tsx
// Incorrect: Memoize cheap props (redundant with React Compiler)
function SimpleChart({ data }: { data: DataPoint[] }) {
  const processedData = useMemo(() => {
    return data.map(point => point) // Too simple, not worth memoizing
  }, [data])

  return <Chart data={processedData} />
}
```

#### 2. Memoizing Values Used Across Renders

```tsx
// Correct: Memoize value reused in multiple renders
function Dashboard() {
  const { data } = useHeavyData() // Expensive computation

  return (
    <>
      <Card title="Summary">
        <SummaryWidget value={data} />
      </Card>
      <Card title="Details">
        <DetailsWidget value={data} />
      </Card>
    </>
  )
}
```

#### 3. Referential Stability for Custom Hooks

```tsx
// Correct: Use useMemo for derived state
function useDerivedState(base: number) {
  const doubled = useMemo(() => base * 2, [base])
  const squared = useMemo(() => base * base, [base])

  return { doubled, squared }
}
```

### Anti-Patterns (AVOID with React Compiler)

```tsx
// DON'T: Wrap simple callbacks in useCallback
function Button({ onClick }: { onClick: () => void }) {
  const handleClick = useCallback(() => onClick(), []) // Redundant
  return <button onClick={handleClick}>Click</button>
}
```

```tsx
// DON'T: Memoize render-return values
function Component({ props }: Props) {
  const memoizedProps = useMemo(() => props, [props]) // Useless
  return <div>{memoizedProps.text}</div>
}
```

### React Compiler Project Note

This project has React Compiler enabled (`reactCompiler: true` in next.config.ts). The compiler automatically:
- Optimizes `useMemo` and `useCallback` dependencies
- Inlines memoized values
- Eliminates unnecessary re-renders

**Bottom line:** Trust React Compiler first. Only add manual memoization when:
1. You profile a performance bottleneck
2. The computation is genuinely expensive
3. React Compiler optimization is not sufficient for your use case

### For Projects Without React Compiler

If React Compiler is disabled (removed from config or disabled flag), refer to `client-tanstack-query-dedup` for general data fetching optimization.
