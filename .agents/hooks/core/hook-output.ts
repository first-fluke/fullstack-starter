// Vendor-specific hook output builders.
// Each runtime (Claude Code, Codex CLI, Cursor, Gemini CLI, Qwen Code)
// expects a slightly different stdout JSON shape; centralize the dialect
// translation here so individual hooks can stay vendor-agnostic.

import type { Vendor } from "./types.ts";

export function makePromptOutput(
  vendor: Vendor,
  additionalContext: string,
): string {
  switch (vendor) {
    case "antigravity":
      return JSON.stringify({ additionalContext });
    case "claude":
      return JSON.stringify({ additionalContext });
    case "codex":
      return JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "UserPromptSubmit",
          additionalContext,
        },
      });
    case "cursor":
      return JSON.stringify({
        additionalContext,
        additional_context: additionalContext,
        hookSpecificOutput: {
          hookEventName: "UserPromptSubmit",
          additionalContext,
        },
      });
    case "gemini":
      return JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "BeforeAgent",
          additionalContext,
        },
      });
    case "grok":
      // Grok hook context injection: return additionalContext; Grok may surface
      // it via hook annotations or ignore for prompt events. State side-effects
      // (mode activation, L1 events) are the primary mechanism.
      return JSON.stringify({ additionalContext });
    case "qwen":
      // Qwen Code fork uses hookSpecificOutput (same as Codex)
      return JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "UserPromptSubmit",
          additionalContext,
        },
      });
  }
}

export function makeBlockOutput(vendor: Vendor, reason: string): string {
  switch (vendor) {
    case "claude":
    case "antigravity":
    case "codex":
    case "cursor":
    case "qwen":
      return JSON.stringify({ decision: "block", reason });
    case "gemini":
      // Gemini AfterAgent uses "deny" to reject response and force retry
      return JSON.stringify({ decision: "deny", reason });
    case "grok":
      // Grok Stop hooks are generally advisory. Emit block decision + rich
      // stderr message (persistent-mode already prints the reason to stderr).
      return JSON.stringify({ decision: "block", reason });
  }
}

export function makePreToolOutput(
  vendor: Vendor,
  updatedInput: Record<string, unknown>,
): string {
  switch (vendor) {
    case "gemini":
      return JSON.stringify({
        decision: "rewrite",
        tool_input: updatedInput,
      });
    case "cursor":
      return JSON.stringify({
        updated_input: updatedInput,
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          updatedInput,
        },
      });
    case "claude":
    case "antigravity":
    case "codex":
    case "qwen":
      return JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          updatedInput,
        },
      });
    case "grok":
      // Grok PreToolUse uses decision + possibly updated tool input
      return JSON.stringify({
        decision: "allow",
        toolInput: updatedInput,
      });
  }
}
