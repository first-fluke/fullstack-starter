# JUDGE Protocol — Independent Verifier

This protocol governs how the JUDGE phase operates in the ralph workflow.
The verifier MUST be independent from the implementer — evaluate only evidence, not intent.

---

## Core Principles

1. **Evidence-based only**: Every judgment must cite concrete evidence (test output, build log, file path, command result)
2. **No subjective assessment**: "Looks correct" or "should work" is NOT valid evidence
3. **Mechanical verification**: Use the verification method defined in the criterion, not alternative methods
4. **Independent perspective**: Judge as if you did not implement the code — verify what IS, not what was intended

---

## Verification Methods

For each criterion, execute the defined verification method:

| Verification Type | How to Execute | PASS Condition | FAIL Condition |
|-------------------|----------------|----------------|----------------|
| `tests pass` | Run test command via Bash | Exit code 0, all tests pass | Any test failure or exit code != 0 |
| `build succeeds` | Run build command via Bash | Exit code 0, no errors | Build errors present |
| `file exists` | Check file path | File exists at specified path | File not found |
| `command output` | Run specified command | Output matches expected pattern | Output does not match |
| `lint passes` | Run lint command via Bash | Zero errors (warnings OK) | Any lint error |
| `type check passes` | Run type-check command | Exit code 0 | Type errors present |

---

## JUDGE Result Format

```markdown
## JUDGE Result — Iteration {N}

| Criterion | Status  | Evidence                          |
|-----------|---------|-----------------------------------|
| C1        | PASS    | `bun test` exit 0, 13/13 passed   |
| C2        | FAIL    | `bun build` exit 1, TypeError in Form.tsx:42 |
| C3        | BLOCKED | Failed 3x: same import resolution error |

verdict: PASS | FAIL
```

### Status Definitions

- **PASS**: Verification method executed successfully, evidence confirms criterion is met
- **FAIL**: Verification method executed, evidence shows criterion is NOT met
- **BLOCKED**: Criterion has failed 3 consecutive times across iterations — no further retries

### Verdict Rules

- `PASS`: ALL criteria are PASS or BLOCKED (no FAIL remaining)
- `FAIL`: ANY criterion has status FAIL

---

## Remaining Items (on FAIL verdict)

When verdict is FAIL, output remaining work for REPLAN:

```markdown
remaining:
  - id: C{N}
    reason: "<specific failure evidence>"
    suggested_action: "<concrete next step>"
    fail_count: {N}
```

### Suggested Action Guidelines

- Be specific: "Fix TypeError in Form.tsx:42 — `props.onChange` is undefined" not "fix the error"
- Reference exact files and line numbers when available
- If the same failure recurred, suggest a DIFFERENT approach than the previous iteration
- If approaching BLOCKED threshold (fail_count = 2), flag it:
  `⚠️ Next failure will BLOCK this criterion`

---

## BLOCKED Marking Rules

A criterion is marked BLOCKED when:

1. It has `fail_count >= 3` (failed in 3 consecutive iterations)
2. The same root cause persists despite different approaches

When marking BLOCKED:
- Record the 3 failure evidences for reference
- Do NOT retry in subsequent iterations
- Report in the final summary as unresolved

---

## Verification Execution Order

1. Run all verification commands in parallel when possible
2. Collect all results before producing the JUDGE result
3. Do NOT stop at the first failure — verify ALL criteria every iteration
4. Record raw command output as evidence (not summaries)
