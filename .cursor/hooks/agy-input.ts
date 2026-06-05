/**
 * Shared stdin parsing for the Antigravity CLI (agy) hook contract.
 *
 * agy's hooks (PreInvocation / PreToolUse / PostInvocation / Stop) deliver a
 * common envelope — `conversationId`, `workspacePaths`, `transcriptPath`,
 * `artifactDirectoryPath` — and, unlike every other vendor, DO NOT include the
 * user prompt or a `hook_event_name` field on stdin. The prompt must be
 * recovered from the transcript. Field names are camelCase.
 *
 * Ref: antigravity.google/docs/hooks — "Input/Output Contract".
 */
import { existsSync, readFileSync } from "node:fs";

/**
 * agy is identified by its stdin shape (no hook_event_name to key off): a
 * `workspacePaths` array plus a `conversationId` string. No other supported
 * vendor sends this pair.
 */
export function isAgyInput(input: Record<string, unknown>): boolean {
  return (
    Array.isArray(input.workspacePaths) &&
    typeof input.conversationId === "string"
  );
}

/** agy's project dir is the first mounted workspace path. */
export function agyProjectDir(input: Record<string, unknown>): string | null {
  const ws = input.workspacePaths;
  if (Array.isArray(ws) && typeof ws[0] === "string") return ws[0];
  return null;
}

/** agy's stable session identifier is the conversation UUID. */
export function agyConversationId(
  input: Record<string, unknown>,
): string | null {
  return typeof input.conversationId === "string" ? input.conversationId : null;
}

/**
 * Recover the latest user prompt from an agy transcript.jsonl.
 *
 * Each transcript line is a JSON step; user turns have `type === "USER_INPUT"`
 * with the request wrapped as `<USER_REQUEST>…</USER_REQUEST>` inside `content`
 * (alongside metadata blocks we strip). Returns the most recent request text,
 * or "" when the transcript is missing/unreadable.
 */
export function readAgyPrompt(transcriptPath: unknown): string {
  if (typeof transcriptPath !== "string" || !existsSync(transcriptPath)) {
    return "";
  }
  let content = "";
  try {
    for (const line of readFileSync(transcriptPath, "utf-8").split("\n")) {
      const trimmed = line.trim();
      if (!trimmed) continue;
      try {
        const step = JSON.parse(trimmed) as Record<string, unknown>;
        if (step.type === "USER_INPUT" && typeof step.content === "string") {
          content = step.content; // keep the last USER_INPUT
        }
      } catch {
        // skip malformed transcript line
      }
    }
  } catch {
    return "";
  }
  const match = content.match(/<USER_REQUEST>\s*([\s\S]*?)\s*<\/USER_REQUEST>/);
  return (match?.[1] ?? content).trim();
}
