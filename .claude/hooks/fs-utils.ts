import { existsSync } from "node:fs";
import { dirname, join, sep } from "node:path";

/**
 * Normalize a filesystem path to POSIX (forward-slash) form so output
 * shown to the model and string comparisons stay platform-independent
 * on Windows. Mirrors `cli/utils/fs-utils.ts#toPosixPath`.
 */
export function toPosixPath(p: string): string {
  return sep === "/" ? p : p.split(sep).join("/");
}

/**
 * Walk up from startDir to find the git repository root.
 * This prevents CLAUDE_PROJECT_DIR pointing to a subdirectory
 * (e.g. packages/i18n during a build) from creating state files
 * in the wrong location.
 */
const MAX_DEPTH = 20;

export function resolveGitRoot(startDir: string): string {
  let dir = startDir;
  for (let i = 0; i < MAX_DEPTH; i++) {
    if (existsSync(join(dir, ".git"))) return dir;
    const parent = dirname(dir);
    if (parent === dir) return startDir;
    dir = parent;
  }
  return startDir;
}
