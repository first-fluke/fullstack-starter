# Skill Routing Map

Routing rules for Orchestrator and workflow-guide to assign tasks to the correct agent.

## Progressive Disclosure

Skills use two-stage loading to optimize context usage:

1. **Stage 1 (always loaded)**: `name` and `description` from SKILL.md frontmatter
2. **Stage 2 (on match)**: Full SKILL.md body loaded only when the description matches the user's request

Match the user's request keywords against each skill's `description`. Load full instructions only for matched skills.

---

## Keyword → Skill Mapping

| User Request Keywords | Primary Skill | Notes |
|----------------------|---------------|-------|
| API, endpoint, REST, GraphQL, database, migration | **backend-agent** | |
| auth, JWT, login, register, password | **backend-agent** | Auth UI task can also be created for frontend |
| UI, component, page, form, screen (web) | **frontend-agent** | |
| style, Tailwind, responsive, CSS | **frontend-agent** | |
| mobile, iOS, Android, Flutter, React Native, app | **mobile-agent** | |
| offline, push notification, camera, GPS | **mobile-agent** | |
| bug, error, crash, broken, slow | **debug-agent** | |
| review, security, performance | **qa-agent** | |
| accessibility, WCAG, a11y | **qa-agent** | |
| brainstorm, ideate, design, explore, idea, concept | **brainstorm** | Run before pm-agent |
| plan, breakdown, task, sprint | **pm-agent** | |
| automatic, parallel, orchestrate | **orchestrator** | |
| workflow, guide, manual, step-by-step | **workflow-guide** | |

---

## Complex Request Routing

| Request Pattern | Execution Order |
|----------------|-----------------|
| "Create a fullstack app" | pm → (backend + frontend) parallel → qa |
| "Create a mobile app" | pm → (backend + mobile) parallel → qa |
| "Fullstack + mobile" | pm → (backend + frontend + mobile) parallel → qa |
| "Fix bug and review" | debug → qa |
| "Add feature and test" | pm → relevant agent → qa |
| "I have an idea for a feature" | brainstorm → pm → relevant agents → qa |
| "Let's design something new" | brainstorm → pm → relevant agents → qa |
| "Do everything automatically" | orchestrator (internally pm → agents → qa) |
| "I'll manage manually" | workflow-guide |

---

## Inter-Agent Dependency Rules

### Parallel Execution Possible (No Dependencies)
- backend + frontend (when API contract is pre-defined)
- backend + mobile (when API contract is pre-defined)
- frontend + mobile (independent of each other)

### Sequential Execution Required
- brainstorm → pm (design comes before planning)
- pm → all other agents (planning comes first)
- implementation agent → qa (review after implementation complete)
- implementation agent → debug (debugging after implementation complete)
- backend → frontend/mobile (when executing parallel without API contract)

### QA Is Always Last
- qa-agent runs after all implementation tasks are complete
- Exception: Can run immediately if user requests review of specific files only

---

## Escalation Rules

| Situation | Escalation Target |
|-----------|------------------|
| Agent finds bug in different domain | Create task for debug-agent |
| QA finds CRITICAL issue | Re-run relevant domain agent |
| Architecture change needed | Request re-planning from pm-agent |
| Performance issue found (during implementation) | Current agent fixes, debug-agent if severe |
| API contract mismatch | Orchestrator re-runs backend agent |

---

## Turn Limit Guide by Agent

| Agent | Default Turns | Max Turns (including retries) |
|-------|--------------|------------------------------|
| pm-agent | 10 | 15 |
| backend-agent | 20 | 30 |
| frontend-agent | 20 | 30 |
| mobile-agent | 20 | 30 |
| debug-agent | 15 | 25 |
| qa-agent | 15 | 20 |
