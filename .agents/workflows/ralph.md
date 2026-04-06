---
description: Ralph - persistent self-referential execution loop wrapping ultrawork with independent verifier verification
---

# MANDATORY RULES — VIOLATION IS FORBIDDEN

- **Response language follows `language` setting in `.agents/oma-config.yaml` if configured.**
- **NEVER skip phases.** Execute from Phase 0 in order. Explicitly report completion of each phase to the user before proceeding to the next.
- **You MUST use MCP tools throughout the entire workflow.** This is NOT optional.
  - Use code analysis tools (`get_symbols_overview`, `find_symbol`, `find_referencing_symbols`, `search_for_pattern`) for code exploration.
  - Use memory tools (read/write/edit) for progress tracking.
  - Memory path: configurable via `memoryConfig.basePath` (default: `.serena/memories`)
  - Tool names: configurable via `memoryConfig.tools` in `mcp.json`
  - Do NOT use raw file reads or grep as substitutes. MCP tools are the primary interface for code and memory operations.
- **This workflow does NOT stop until all completion criteria pass or safeguards trigger.**
- **Follow the context-loading guide.** Read `.agents/skills/_shared/core/context-loading.md` and load only task-relevant resources.

---

## Vendor Detection

Before starting, determine your runtime environment by following `.agents/skills/_shared/core/vendor-detection.md`.
The detected vendor determines how ultrawork spawns agents internally.

---

## Phase 0: INIT (DO NOT SKIP)

### Step 0.1: Load Prerequisites

1. Read `.agents/skills/_shared/core/context-loading.md` for resource loading strategy.
2. Read `.agents/skills/_shared/runtime/memory-protocol.md` for memory protocol.
3. Read `.agents/workflows/ralph/resources/judge-protocol.md` for JUDGE rules.

### Step 0.2: Define Completion Criteria

Analyze the user's request and define **verifiable** completion criteria. Each criterion MUST have:

```markdown
criteria:
  - id: C{N}
    description: "<what to achieve>"
    verification: "<how to verify — test result, build output, file existence, command output>"
    status: PENDING
    fail_count: 0
```

**Rules:**
- Every criterion must be mechanically verifiable (test pass, build success, file exists, command output)
- Reject subjective criteria ("looks good", "feels right") — ask the user to rephrase
- Present criteria to the user for confirmation before proceeding

### Step 0.3: Initialize Session

1. Set `max_iterations: 5` (default safeguard)
2. Set `current_iteration: 0`
3. Record session start using memory write tool:
   - Create `session-ralph.md` in the memory base path
   - Include: session start time, user request summary, completion criteria, max_iterations

---

## Phase 1: EXEC

// turbo

### Step 1.1: Prepare Ultrawork Input

Compose the ultrawork input based on current iteration:

- **Iteration 1**: Full user request with all PENDING criteria
- **Iteration 2+**: Only REMAINING criteria from previous JUDGE result, with:
  - Previous JUDGE results as context (what failed and why)
  - Suggested actions from JUDGE
  - Already-PASSED criteria explicitly excluded from scope

### Step 1.2: Execute Ultrawork

Delegate to the ultrawork workflow:

1. Read and follow `.agents/workflows/ultrawork.md` step by step.
2. Pass the prepared input as the task description.
3. Ultrawork handles all vendor-specific agent spawning internally.
4. Wait for ultrawork to complete all 5 phases (PLAN → IMPL → VERIFY → REFINE → SHIP).

### Step 1.3: Record EXEC Completion

1. Increment `current_iteration`
2. Use memory edit tool to record iteration start in `session-ralph.md`

---

## Phase 2: JUDGE

### Step 2.1: Independent Verification

**You are now the independent verifier, NOT the implementer.**

For each criterion with status PENDING or FAIL, execute the verification method defined in Phase 0:

- Run tests → check pass/fail count
- Run build → check exit code
- Check file existence → verify path
- Run specific commands → check output

**Follow `.agents/workflows/ralph/resources/judge-protocol.md` for the full protocol.**

### Step 2.2: Produce JUDGE Result

Output the JUDGE result in this exact format:

```markdown
## JUDGE Result — Iteration {N}

| Criterion | Status  | Evidence                          |
|-----------|---------|-----------------------------------|
| C1        | PASS    | <concrete evidence>               |
| C2        | FAIL    | <concrete evidence of failure>    |
| C3        | BLOCKED | <failed 3x: reason>               |

verdict: PASS | FAIL
```

If verdict is FAIL, also output:

```markdown
remaining:
  - id: C{N}
    reason: "<why it failed>"
    suggested_action: "<what to try next>"
    fail_count: {N}
```

### Step 2.3: Apply JUDGE Result

Update each criterion's status in `session-ralph.md`:

- Test passed → `PASS`
- Test failed, fail_count < 3 → `FAIL` (increment fail_count)
- Test failed, fail_count >= 3 → `BLOCKED`

---

## Phase 2 → Decision Gate

Evaluate the JUDGE result:

### → DONE (All criteria PASS or BLOCKED)

If all criteria are either PASS or BLOCKED:

1. **If any BLOCKED exists**: Report partial completion with BLOCKED items listed
2. **If all PASS**: Report full completion
3. Use memory edit tool to record final results in `session-ralph.md`
4. Output completion summary:
   ```
   ## Ralph Complete — Iteration {N}/{max}

   PASSED: C1, C2, ...
   BLOCKED: C3 (if any)

   Total iterations: {N}
   ```
5. Workflow ends.

### → REPLAN (Any criterion is FAIL)

If any criterion has status FAIL, proceed to Phase 3.

### → SAFEGUARD (max_iterations reached)

If `current_iteration >= max_iterations`:

1. Force stop regardless of FAIL criteria
2. Report partial completion:
   ```
   ## Ralph Safeguard — Max Iterations Reached ({max})

   PASSED: C1, ...
   FAILED: C2, ... (still unresolved)
   BLOCKED: C3, ... (if any)

   Recommendation: Review FAILED criteria manually or increase max_iterations.
   ```
3. Use memory edit tool to record safeguard trigger in `session-ralph.md`
4. Workflow ends.

---

## Phase 3: REPLAN

// turbo

### Step 3.1: Extract Remaining Work

From the JUDGE result, collect only criteria with status `FAIL`:

1. List each FAIL criterion with its reason and suggested_action
2. Include previous iteration's JUDGE evidence as context
3. Explicitly state which criteria are PASS (do not re-implement)
4. Explicitly state which criteria are BLOCKED (do not retry)

### Step 3.2: Narrow Scope

Compose a focused task description containing ONLY the remaining work:

```markdown
## Ralph Iteration {N+1} — Remaining Work

### Already Complete (DO NOT modify)
- C1: <description> ✅

### Blocked (DO NOT retry)
- C3: <description> 🚫 (failed 3x)

### To Fix
- C2: <description>
  - Previous failure: <evidence>
  - Suggested action: <action>
```

### Step 3.3: Loop Back

1. Use memory edit tool to record REPLAN in `session-ralph.md`
2. Return to **Phase 1: EXEC** with the narrowed scope

---

## Summary

```
Phase 0: INIT → Define criteria, initialize session
    ↓
Phase 1: EXEC → Run ultrawork (full or narrowed scope)
    ↓
Phase 2: JUDGE → Independent verification of each criterion
    ↓
Decision: DONE? → End
          SAFEGUARD? → Force end
          FAIL? → Phase 3
    ↓
Phase 3: REPLAN → Extract remaining, narrow scope
    ↓
    └──→ Phase 1 (loop)
```

| Phase   | Purpose                    | Key Action                        |
|---------|----------------------------|-----------------------------------|
| INIT    | Define success criteria     | Verifiable criteria + session init |
| EXEC    | Implementation             | Delegate to ultrawork             |
| JUDGE   | Independent verification   | Evidence-based pass/fail per criterion |
| REPLAN  | Scope narrowing            | Extract FAIL items only           |
