// Hook-runtime types shared across Claude Code, Codex CLI, Cursor,
// Gemini CLI, and Qwen Code. Functions live in `fs-utils.ts` and
// `hook-output.ts`; this file is types-only. The `Vendor` type is derived
// from the `VENDORS` runtime constant in `constants.ts` so the two stay
// in sync.

import type { VENDORS } from "./constants.ts";

export type Vendor = (typeof VENDORS)[number];

export interface HookInput {
  prompt?: string;
  sessionId?: string;
  session_id?: string;
  hook_event_name?: string;
  cwd?: string;
  workspace_roots?: string[];
  // Gemini: AfterAgent fields
  prompt_response?: string;
  stop_hook_active?: boolean;
  // Claude/Qwen: Stop fields
  stopReason?: string;
}

export interface ModeState {
  workflow: string;
  sessionId: string;
  activatedAt: string;
  reinforcementCount: number;
}
