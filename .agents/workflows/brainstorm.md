---
description: Design-first ideation workflow — explore user intent, clarify constraints, propose approaches, and produce an approved design document before planning
---

# MANDATORY RULES — VIOLATION IS FORBIDDEN

- **Response language follows `language` setting in `.agents/config/user-preferences.yaml` if configured.**
- **NEVER skip steps.** Execute from Step 1 in order.
- **Do NOT write any code.** This workflow produces a design document, not implementation.
- **You MUST use MCP tools throughout the workflow.**
  - Use code analysis tools (`get_symbols_overview`, `find_symbol`, `search_for_pattern`) to analyze the existing codebase.
  - Use memory tools (write/edit) to record design results.
  - Memory path: configurable via `memoryConfig.basePath` (default: `.serena/memories`)
  - Tool names: configurable via `memoryConfig.tools` in `mcp.json`
  - Do NOT use raw file reads or grep as substitutes.

---

> **Vendor note:** This workflow executes inline (no subagent spawning). All vendors use their native code analysis and file tools.

---

## Step 1: Explore Project Context

// turbo
Use MCP code analysis tools to understand the current codebase:
- `get_symbols_overview` for project structure and existing architecture.
- `find_symbol` and `search_for_pattern` to identify relevant modules, patterns, and conventions.
- Summarize what exists and what the user's idea would affect.

---

## Step 2: Ask Clarifying Questions

Ask the user clarifying questions **one at a time**. Prefer multiple-choice options when possible.
Key areas to clarify:
- **Intent**: What problem are they solving? Who is the target user?
- **Scope**: Must-have vs nice-to-have features
- **Constraints**: Tech stack, timeline, existing integrations
- **Success criteria**: How will they know it's done?

Do NOT proceed to Step 3 until you have a clear understanding of the user's intent.

---

## Step 3: Propose Approaches

Present **2-3 distinct approaches** to solve the problem:
- For each approach: summary, pros, cons, effort estimate (S/M/L)
- Highlight the **recommended approach** with rationale
- Include a brief trade-off comparison matrix

**You MUST get user confirmation on the chosen approach before proceeding to Step 4.**

---

## Step 4: Present Design

Present the detailed design **section by section**, getting user feedback at each step:
- Architecture overview (components, data flow)
- Key interfaces and contracts
- Integration points with existing code
- Edge cases and error handling strategy

Each section requires explicit user approval before moving to the next.

---

## Step 5: Save Design Document

// turbo
Save the approved design:
1. Write to `docs/plans/<feature-name>-design.md`
2. Use memory write tool to record design summary for future reference.

---

## Step 6: Transition to Planning

Inform the user that the design phase is complete and suggest:
> "Design approved. Run `/plan` to decompose this into actionable tasks."

The design document will be automatically loaded by the planning workflow as context.
