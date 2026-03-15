# Frontend Agent - Examples

## Example 1: Feature Component

**Input**: "Create a todo list page with add, toggle, and delete"

**Output**:
```
## Task: Todo List Page

### Implementation
- Components: TodoList, TodoItem, AddTodoForm
- Routes: /todos (page)
- State: TanStack Query for server state, local state for form

### Files Created/Modified
- src/types/todo.ts (NEW) - Todo interface
- src/lib/api/todos.ts (NEW) - API client with TanStack Query hooks
- src/components/todo/TodoItem.tsx (NEW) - Single todo display
- src/components/todo/AddTodoForm.tsx (NEW) - Form with validation
- src/components/todo/TodoList.tsx (NEW) - List container
- src/app/todos/page.tsx (NEW) - Page component
- tests/components/TodoList.test.tsx (NEW)

### Testing
- Unit tests: 5 passing
- Keyboard navigation: verified
- Responsive: tested at 4 breakpoints
```

## Example 2: Form with Validation

**Input**: "Create a user profile edit form"

**Output**:
```
## Task: Profile Edit Form

### Implementation
- Components: ProfileForm (React Hook Form + Zod)
- Validation: name (required, 2-50 chars), email (valid format), bio (optional, max 500)
- API: PATCH /api/users/me via TanStack Query mutation
- UX: optimistic update, error toast, success redirect

### Files Created
- src/types/user.ts
- src/lib/api/users.ts
- src/components/profile/ProfileForm.tsx
- src/app/profile/edit/page.tsx
- tests/components/ProfileForm.test.tsx
```

## Example 3: Responsive Dashboard

**Input**: "Build a dashboard with stats cards and a chart"

**Output**:
```
## Task: Dashboard Page

### Implementation
- Components: StatCard, StatsGrid, ActivityChart
- Layout: CSS Grid - 1 col (mobile), 2 col (tablet), 4 col (desktop)
- Chart: recharts with responsive container
- Data: TanStack Query with 30s refetch interval

### Accessibility
- [x] All cards have aria-label with stat value
- [x] Chart has aria-describedby with text summary
- [x] Color contrast 4.5:1 on all text

### Files Created
- src/components/dashboard/StatCard.tsx
- src/components/dashboard/StatsGrid.tsx
- src/components/dashboard/ActivityChart.tsx
- src/app/dashboard/page.tsx
```
