# Lessons Learned

A repository for accumulated lessons across sessions. All agents reference this file at execution start.
QA Agent and Orchestrator add new lessons after session completion.

---

## How to Use

### Reading (All Agents)
- At Complex task start: Read your domain section to prevent same mistakes
- Medium tasks: Reference if related items exist
- Simple tasks: Can skip

### Writing (QA Agent, Orchestrator)
Add in the following format after session completion:
```markdown
### {YYYY-MM-DD}: {agent-type} - {one-line summary}
- **Problem**: {what went wrong}
- **Cause**: {why it happened}
- **Solution**: {how it was fixed}
- **Prevention**: {how to prevent in future}
```

---

## Backend Lessons

> This section is referenced by backend-agent, debug-agent (for backend bugs).

### Initial Lessons (Recorded at project setup)
- **Use SQLAlchemy 2.0 style only**: Use `select()` instead of `query()`. Legacy style causes warnings.
- **Always review after Alembic autogenerate**: Auto-generated migrations may have missing indexes or incorrect types.
- **FastAPI Depends chain**: Calling other Depends inside dependency functions can cause order issues. Verify with tests.
- **async/await consistency**: Don't mix sync/async in one router. Unify all to async.

---

## Frontend Lessons

> This section is referenced by frontend-agent, debug-agent (for frontend bugs).

### Initial Lessons
- **Next.js App Router**: `useSearchParams()` must be used inside a `<Suspense>` boundary. Otherwise, build error.
- **shadcn/ui components**: Import path is `@/components/ui/button`, not `shadcn/ui`.
- **TanStack Query v5**: First argument of `useQuery` is object form `{ queryKey, queryFn }`. Cannot use v4's `useQuery(key, fn)` form.
- **Tailwind dark mode**: `dark:` prefix only works with `darkMode: 'class'` setting.

---

## Mobile Lessons

> This section is referenced by mobile-agent, debug-agent (for mobile bugs).

### Initial Lessons
- **Riverpod 2.4+ code generation**: When using `@riverpod` annotation, `build_runner` execution required. Run `dart run build_runner build` before build.
- **GoRouter redirect**: Returning current path in redirect function causes infinite loop. Must return `null` to indicate no redirect.
- **Flutter 3.19+ Material 3**: `useMaterial3: true` is default. M3 applies even without explicit setting in ThemeData.
- **Network on iOS simulator**: Use `127.0.0.1` instead of localhost. Or for Android use `10.0.2.2`.

---

## QA / Security Lessons

> This section is referenced by qa-agent.

### Initial Lessons
- **Rate limiting verification method**: Send continuous requests with `curl` and verify 429 response. Code review alone is insufficient.
- **CORS wildcard**: Using `*` in development environment is OK, but production build must restrict to specific domains.
- **bun audit vs safety**: Use `bun audit` for frontend, `pip-audit` or `safety check` for backend (Python).

---

## Debug Lessons

> This section is referenced by debug-agent.

### Initial Lessons
- **React hydration error**: Caused by code with different server/client values like `Date.now()`, `Math.random()`, `window.innerWidth`. Wrap with `useEffect` + `useState`.
- **N+1 query detection**: Setting `echo=True` in SQLAlchemy logs all queries. If same pattern queries repeat, it's N+1.
- **State loss after Flutter hot reload**: StatefulWidget's initState doesn't re-run on hot reload. Put state initialization logic in didChangeDependencies.

---

## Cross-Domain Lessons

> Referenced by all agents.

### Initial Lessons
- **API contract mismatch**: Parsing fails when backend uses `snake_case` and frontend expects `camelCase`. Must specify casing in contract.
- **Timezone issues**: Backend stores in UTC, frontend displays in local timezone. Unify to ISO 8601 format.
- **Auth token passing**: Watch for mistakes where backend expects `Authorization: Bearer {token}` but frontend sends `token` header.

---

## Lesson Addition Protocol

### When QA Agent Adds
When finding repeated issues during review:
1. Add lesson to corresponding domain section
2. Format: `### {date}: {one-line summary}` + problem/cause/solution/prevention
3. Serena: `edit_memory("lessons-learned.md", additional content)`

### When Orchestrator Adds
When there are failed tasks at session end:
1. Analyze failure cause
2. Add lesson to corresponding domain section
3. Prevent same mistake in next session

### When Lessons Become Too Many (50+)
- Archive old lessons (6+ months)
- Delete lessons invalidated by framework version upgrades
- This cleanup is done manually (agents should not delete arbitrarily)
