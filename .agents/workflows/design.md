---
description: Design workflow — create design systems, DESIGN.md, and design tokens with anti-pattern enforcement and accessibility checks
---

# MANDATORY RULES — VIOLATION IS FORBIDDEN

- **Response language follows `language` setting in `.agents/config/user-preferences.yaml` if configured.**
- **NEVER skip phases.** Execute from Phase 1 in order.
- **Do NOT write implementation code.** This workflow produces DESIGN.md, design tokens, and design guidance — not application code.
- **You MUST use MCP tools throughout the workflow.**
  - Use code analysis tools (`get_symbols_overview`, `find_symbol`, `search_for_pattern`) to analyze the existing codebase.
  - Use memory tools (write/edit) to record design results.
  - Memory path: configurable via `memoryConfig.basePath` (default: `.serena/memories`)
  - Tool names: configurable via `memoryConfig.tools` in `mcp.json`
  - Do NOT use raw file reads or grep as substitutes.

---

> **Vendor note:** This workflow executes inline (no subagent spawning). All vendors use their native code analysis and file tools.

---

## Phase 1: SETUP (Context Gathering)

Read `.design-context.md` in the project root.

If it does not exist:
1. Scan codebase for existing design signals:
   - `package.json` — font packages, UI libraries, CSS framework
   - Tailwind config — existing theme, colors, fonts
   - Existing CSS/SCSS — design tokens, custom properties
   - `DESIGN.md` — if already present, use as starting point
2. Ask the user (one question at a time, prefer multiple-choice):
   - What languages does the service support? (determines font strategy)
   - Who is the target audience? (B2B/B2C, age range, tech level)
   - What is the brand personality? (professional / casual / premium / playful)
   - What aesthetic direction? (dark premium / clean minimal / colorful / brutalist / other)
   - Any reference sites or designs to draw from?
   - Accessibility requirements? (WCAG AA / AAA / none specified)
3. Save answers to `.design-context.md`

**Do NOT proceed until design context is established.**

---

## Phase 2: EXTRACT (Optional)

If a reference URL or Stitch project exists:
- Load `resources/stitch-integration.md` if Stitch MCP is available
- Extract design tokens from source → DESIGN.md draft
- Follow the 5-stage pipeline: Retrieval → Extraction → Translation → Synthesis → Alignment

If no reference: skip to Phase 3.

---

## Phase 3: ENHANCE (Prompt Augmentation)

If the user request is vague (< 3 sentences, no section details):
- Load `resources/prompt-enhancement.md`
- Transform into section-by-section specification
- Present enhanced prompt to user for confirmation

If already detailed: skip to Phase 4.

---

## Phase 4: PROPOSE (Multi-Concept)

// turbo
Present 2-3 distinct design directions. Each direction includes:
- Color palette (5-7 colors with semantic names and functional roles)
- Typography pairing (system fonts default, custom only with justification)
- Layout approach (chess / grid / bento / full-bleed / mixed)
- Motion strategy (scroll-driven / hover-based / entrance-only / minimal)
- Recommended component libraries (shadcn base + Aceternity / React Bits accents)

**You MUST get user confirmation on the chosen direction before proceeding.**

---

## Phase 5: GENERATE

// turbo
Based on the chosen direction:
1. Write `DESIGN.md` following `resources/design-md-spec.md` (6 sections)
2. Output design tokens:
   - CSS Custom Properties
   - Tailwind config extensions
   - shadcn/ui theme variables (if applicable)
3. Generate component code if requested

### Responsive-First Rule (MANDATORY)
ALL output must be responsive by default. Never produce desktop-only layouts.
- Mobile (default): 320px-639px
- Tablet (md): 768px+
- Desktop (lg): 1024px+

---

## Phase 6: AUDIT

Load `resources/checklist.md` and run all checks in order:

1. **Responsive** (MANDATORY — run first)
2. **WCAG 2.2 Accessibility**
3. **Nielsen's 10 Heuristics**
4. **AI Slop Check** (anti-patterns.md)
5. **Design System Consistency**

Fix violations or report to user with recommendations.

---

## Phase 7: HANDOFF

1. Save `DESIGN.md` to the project root
2. Update `.design-context.md` if new decisions were made
3. Write design token files if not already written
4. Inform the user:
   > "Design complete. DESIGN.md has been created. To implement, delegate to oma-frontend or run /orchestrate."
