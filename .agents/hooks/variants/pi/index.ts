/**
 * oh-my-agent — pi (Earendil pi-coding-agent) hook bridge.
 *
 * SSOT source. At install time `installPiExtension` copies this file to
 * `.pi/extensions/oma/index.ts` alongside the core hook scripts. pi
 * auto-discovers it as a directory extension (`.pi/extensions/*​/index.ts`).
 *
 * Why a bridge instead of a `variants/*.json` entry: pi does NOT register
 * settings-file hooks like the other vendors. It loads in-process TS
 * extensions and dispatches `pi.on(event, handler)`. So rather than the
 * generic `installHooksFromVariant` path (events → settings file → `bun
 * <script>` subprocess), pi gets this thin shim that maps pi lifecycle events
 * onto oma's existing, vendor-agnostic core scripts via subprocess. All
 * matching logic stays in the core scripts; the per-vendor output dialect for
 * `"pi"` lives in `hook-output.ts`.
 *
 * Event mapping (see README.md):
 *   before_agent_start  ← UserPromptSubmit  (keyword-detector + skill-injector)
 *   tool_call (bash)    ← PreToolUse        (test-filter)
 *   — persistent-mode has NO pi analog: pi's only post-turn event (agent_end)
 *     is notification-only and cannot re-enter the loop. Persistent workflows
 *     degrade to re-injection on the next turn via before_agent_start.
 */

import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/** Absolute path to a core script copied next to this bridge at install time. */
function corePath(script: string): string {
  return fileURLToPath(new URL(`./${script}`, import.meta.url));
}

/**
 * Run an oma core hook script as a subprocess: feed it JSON on stdin, parse
 * its JSON stdout. Fail-open (returns null) on any error — a broken hook must
 * never block the agent. Spawns with `cwd` = pi's working directory so the
 * core scripts resolve the project (git) root the same way they do for every
 * other vendor.
 */
function runCore(
  script: string,
  payload: Record<string, unknown>,
): Record<string, unknown> | null {
  try {
    const res = spawnSync("bun", [corePath(script)], {
      input: JSON.stringify(payload),
      cwd: process.cwd(),
      encoding: "utf-8",
      timeout: 5000,
      env: process.env,
    });
    const out = (res.stdout ?? "").trim();
    if (!out) return null;
    return JSON.parse(out) as Record<string, unknown>;
  } catch {
    return null;
  }
}

// Dedup: pi auto-discovers extensions from BOTH `~/.pi/agent/extensions/`
// (global) and `.pi/extensions/` (project). When oma is installed in both
// global and project mode, this module loads twice in the SAME pi process —
// a single globalThis guard registers handlers exactly once. (The shell
// HOOK_DEDUP_PREAMBLE other vendors use does not apply here: pi loads
// extensions in-process, not as shell-wrapped subprocesses.)
const guard = globalThis as { __OMA_PI_EXT_REGISTERED?: boolean };

export default function omaHooks(pi: ExtensionAPI): void {
  if (guard.__OMA_PI_EXT_REGISTERED) return;
  guard.__OMA_PI_EXT_REGISTERED = true;

  // before_agent_start ← UserPromptSubmit.
  // Inject workflow + skill context into the system prompt for this turn.
  pi.on("before_agent_start", async (event) => {
    const payload = {
      prompt: event.prompt ?? "",
      cwd: process.cwd(),
      hook_event_name: "UserPromptSubmit",
    };

    // Order matches the Claude chain: keyword-detector first (it may activate
    // a persistent workflow), then skill-injector (it skips when one is
    // already active for the session).
    const parts: string[] = [];
    const kd = runCore("keyword-detector.ts", payload);
    if (kd && typeof kd.additionalContext === "string") {
      parts.push(kd.additionalContext);
    }
    const si = runCore("skill-injector.ts", payload);
    if (si && typeof si.additionalContext === "string") {
      parts.push(si.additionalContext);
    }

    if (parts.length === 0) return undefined;
    return { systemPrompt: `${event.systemPrompt}\n\n${parts.join("\n\n")}` };
  });

  // tool_call ← PreToolUse (Bash). test-filter rewrites test-runner commands
  // so only failures reach the model. pi exposes `event.input` as mutable, so
  // we rewrite the command in place.
  pi.on("tool_call", async (event) => {
    if (event.toolName !== "bash") return undefined;
    const input = event.input as { command?: string } | undefined;
    const command = input?.command;
    if (!command) return undefined;

    const tf = runCore("test-filter.ts", {
      tool_name: "Bash",
      tool_input: { command },
      cwd: process.cwd(),
      hook_event_name: "PreToolUse",
    });

    const updated = (tf?.updatedInput as { command?: string } | undefined)
      ?.command;
    if (updated && input) input.command = updated;
    return undefined;
  });
}
