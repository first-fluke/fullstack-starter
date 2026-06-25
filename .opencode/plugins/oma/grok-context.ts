/**
 * Grok context channel.
 *
 * Grok ignores the stdout of passive prompt hooks (UserPromptSubmit etc.), so
 * OMA cannot inject context the way it does for Claude/agy. Grok's only
 * model-facing channel is files it appends to the system prompt AT SESSION
 * START. We use a DEDICATED, OMA-owned file under the project rules directory
 * (`.grok/rules/oma-state.md`) — never a user instruction file like
 * AGENTS.md/CLAUDE.md. Per Grok's docs (Project Rules) `.grok/rules/*.md` is
 * "always scanned" and appended to the system prompt.
 *
 * GITIGNORE: Grok skips gitignored files during rules discovery, so this file
 * must NOT be gitignored. OMA does not add `.grok/` to a user project's
 * .gitignore (it only ignores `.antigravitycli/`, `.agents/results/`,
 * `.agents/state/` — see OMA_PROJECT_GITIGNORE_PATTERNS), so in a real install
 * `.grok/rules/oma-state.md` is visible to Grok. NOTE: this source repo
 * gitignores the whole generated `.grok/` dir, so the mirror does NOT load when
 * dogfooding HERE — a source-repo-only quirk, not a user-install limitation.
 *
 * LIMITATIONS:
 *  - SESSION-START channel only (not per-turn): powers the close-reopen resume
 *    snapshot (written one session, read when the next opens); it cannot inject
 *    mid-session context. Per-turn workflow injection is impossible on Grok.
 *  - Loading is doc-asserted but could not be confirmed via headless tooling
 *    (`grok inspect` lists only AGENTS.md-family, so it is blind to
 *    `.grok/rules/`; model self-report is unreliable). Confirm in real
 *    interactive use. If a Grok build does not honor `.grok/rules/`, this is a
 *    harmless no-op — L1 events remain the SSOT and the side-effecting hooks
 *    (state, persistent mode, boundary tracking) still work.
 */
import { existsSync, mkdirSync, unlinkSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";

// Dedicated OMA-owned rules file (not a shared user instruction file).
const GROK_CONTEXT_FILE = join(".grok", "rules", "oma-state.md");

function contextPath(projectDir: string): string {
  return join(projectDir, GROK_CONTEXT_FILE);
}

/**
 * Write the OMA context to Grok's dedicated rules file. Best-effort — failures
 * are swallowed (the L1 state write is the SSOT; this mirror is secondary).
 */
export function syncGrokContext(projectDir: string, content: string): void {
  const path = contextPath(projectDir);
  try {
    mkdirSync(dirname(path), { recursive: true });
    writeFileSync(path, `${content.trim()}\n`);
  } catch {
    // best-effort mirror
  }
}

/** Remove the OMA context file (e.g. on "workflow done"). */
export function clearGrokContext(projectDir: string): void {
  const path = contextPath(projectDir);
  try {
    if (existsSync(path)) unlinkSync(path);
  } catch {
    // best-effort
  }
}
