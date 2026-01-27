---
name: component-refactoring
description: Refactor high-complexity React components. Use when complexity metrics are high or to split monolithic UI.
---

# Component Refactoring Skill

Refactor high-complexity React components with proven patterns and workflows.

**Complexity Threshold**: Components with **cyclomatic complexity > 50** or **line count > 300** should be candidates for refactoring.

**Use When**:
- `pnpm analyze-component` shows high complexity.
- Users ask for "code splitting", "hook extraction", or "cleanup".
- A component file exceeds 300 lines of code.

## Core Refactoring Patterns

### 1. Extract Custom Hooks
**Goal**: Separate UI from State/Logic.

**Before**:
```tsx
function UserList() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    setLoading(true);
    fetch('/api/users').then(data => {
      setUsers(data);
      setLoading(false);
    });
  }, []);

  if (loading) return <Spinner />;
  return <ul>{users.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}
```

**After**:
```tsx
// hooks/useUsers.ts
function useUsers() {
  return useQuery({ queryKey: ['users'], queryFn: fetchUsers });
}

// UserList.tsx
function UserList() {
  const { data: users, isLoading } = useUsers();
  if (isLoading) return <Spinner />;
  return <UserListView users={users} />;
}
```

### 2. Extract Sub-Components
**Goal**: Break down monolithic JSX.

**Before**:
```tsx
function Dashboard() {
  return (
    <div>
      <header>...</header>
      <aside>...</aside>
      <main>
        <section className="stats">...</section>
        <section className="feed">...</section>
      </main>
    </div>
  );
}
```

**After**:
```tsx
function Dashboard() {
  return (
    <Layout>
      <DashboardHeader />
      <DashboardSidebar />
      <DashboardContent>
        <StatsWidget />
        <ActivityFeed />
      </DashboardContent>
    </Layout>
  );
}
```

### 3. Simplify Conditional Logic
**Goal**: Reduce nesting and `if/else` checks implementation details.

- Use **Lookup Tables** (Maps/Objects) instead of Switch/If-Else chains.
- Use **Guard Clauses** (Early Returns) to avoid deep nesting.

### 4. Extract Modal Management
**Goal**: Centralize modal state and logic.

- Move modal definitions to a generic `<ModalManager />` or context if reused globally.
- Keep the `isOpen` state locally if specific to a single component, but extract the Modal content to a separate file.

## Workflow

1. **Analyze**: Run complexity analysis or review the file manually.
2. **Plan**: Identify seam lines (Logic vs UI, Section vs Section).
3. **Extract**: Create new files for hooks or components.
4. **Integrate**: Replace original code with imports.
5. **Verify**: Ensure functionality remains identical and tests pass.
