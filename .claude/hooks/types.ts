// Hook-runtime types shared across Claude Code, Codex CLI, Cursor,
// Gemini CLI, and Qwen Code. Functions live in `fs-utils.ts` and
// `hook-output.ts`; this file is types-only. The `Vendor` type is derived
// from the `VENDORS` runtime constant in `constants.ts` so the two stay
// in sync.
//
// This file is the SSOT for canonical handler contracts (HookInput,
// HandlerResult, HandlerCtx, HookHandler). It is self-contained — no imports
// from `cli/` — so that both `cli/` and the `.agents/hooks/core/` standalone
// scripts can import from here without creating a circular dependency.
// `cli/commands/hook/types.ts` re-exports these symbols plus the transport
// envelope types (HookRequest, HookResponse, HookTransport).

import type { VENDORS } from "./constants.ts";

export type Vendor = (typeof VENDORS)[number];

/**
 * Raw stdin shape delivered by the vendor hook registration.
 * Handlers receive this as `Record<string, unknown>` from stdin; this
 * interface documents the common fields. Not to be confused with the
 * canonical normalized `HookInput` below.
 */
export interface RawHookInput {
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

// ---------------------------------------------------------------------------
// Canonical handler contracts — design 019 (hook → oma hook canonical ABI).
// These are the types every centralized handler must use. They are canonical
// here (not in cli/) so that the standalone pi subprocess scripts can import
// them without depending on cli/.
// ---------------------------------------------------------------------------

/**
 * HookInput — normalised event payload delivered to each handler.
 * Discriminated on `kind`; produced by adapters.ts normalizeInput().
 */
export type HookInput =
  | { kind: "prompt"; prompt: string; cwd: string }
  | {
      kind: "pre_tool";
      toolName: string;
      toolInput: Record<string, unknown>;
      cwd: string;
    }
  | {
      kind: "stop";
      cwd: string;
      /**
       * Assistant response / transcript text from the stop payload, if any.
       * Carries deactivation phrases ("workflow done") so persistent-mode can
       * deactivate via the central `oma hook` path, matching the standalone path.
       */
      responseText?: string;
    };

/**
 * HandlerResult — what a single handler may return.
 *
 * Forward-compatible with pi's .on() interception result:
 *   context  ↔  systemPrompt inject  (pi: before_agent_start → { systemPrompt })
 *   mutate   ↔  event.input rewrite  (pi: tool_call event.input mutation)
 *   block    ↔  block                (pi: block decision on tool_call / stop)
 */
export type HandlerResult =
  | { type: "context"; additionalContext: string }
  | { type: "mutate"; updatedInput: Record<string, unknown> }
  | { type: "block"; reason: string };

/** Context passed to every handler alongside the normalized HookInput. */
export interface HandlerCtx {
  vendor: Vendor;
  cwd: string;
  sid?: string;
}

/** Interface every centralized handler must implement. */
export interface HookHandler {
  id: string;
  run(input: HookInput, ctx: HandlerCtx): Promise<HandlerResult | null>;
}
