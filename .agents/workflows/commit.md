---
description: Generate Conventional Commits spec git commits (auto-separate by feature)
---

# MANDATORY RULES — VIOLATION IS FORBIDDEN

- **Response language follows `language` setting in `.agents/oma-config.yaml` if configured.**
- **NEVER skip steps.** Execute from Step 1 in order.

---

> **Vendor note:** This workflow executes inline (no subagent spawning). All vendors use native git tooling available in their environment.

---

## Commit Types

| Type | Description |
|:-----|:-----------|
| feat | New feature |
| fix | Bug fix |
| refactor | Refactoring |
| docs | Documentation changes |
| test | Test additions/modifications |
| chore | Build/configuration |
| style | Code style |
| perf | Performance improvements |

## Commit Format

```
<type>(<scope>): <description>

[optional body]

Co-Authored-By: First Fluke <our.first.fluke@gmail.com>
```

## Workflow

### Step 1: Analyze Changes

Run `git status` and `git diff --staged` to understand staged changes.
If nothing is staged, run `git diff` to see unstaged changes and suggest what to stage.

### Step 2: Separate Features

If changes span different scope/type combinations AND more than 5 files are involved, separate into multiple commits. Otherwise, commit together.

### Step 3: Determine Type

Based on the changes, select the appropriate commit type from the table above.

### Step 4: Determine Scope

Identify the changed module/component to use as the scope.

### Step 5: Write Description

- Imperative mood
- Max 72 characters
- Lowercase
- No trailing period

### Step 6: Execute Commit

Show the commit message and commit immediately (no confirmation questions).
Pass multi-line commit messages using HEREDOC.

## Absolute Rules

- Do NOT use `git add -A` / `git add .` — always specify files
- Do NOT commit secrets files (.env, credentials)
- Pass commit messages using HEREDOC
- Co-Author: `First Fluke <our.first.fluke@gmail.com>`
