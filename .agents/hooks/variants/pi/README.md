# pi hook variant

`pi` (Earendil's [pi-coding-agent](https://github.com/earendil-works/pi)) does
**not** use the JSON hook-variant mechanism the other vendors share. Those
vendors register hook commands in a settings file (`installHooksFromVariant`),
and each hook runs as a `bun <script>` subprocess that reads stdin JSON and
writes stdout JSON.

pi instead **auto-loads in-process TypeScript extensions** and dispatches
`pi.on(event, handler)`. So pi gets a bespoke install path,
`installPiExtension`, which copies the core hook scripts plus `index.ts` (the
bridge in this directory) into `.pi/extensions/oma/`.

## Discovery

pi auto-discovers extensions from (official docs):

- `~/.pi/agent/extensions/*.ts` / `*/index.ts` (global)
- `.pi/extensions/*.ts` / `*/index.ts` (project-local)

`oma` installs the bridge as a **directory extension**:
`.pi/extensions/oma/index.ts`. The sibling `*.ts` files in that directory
(`keyword-detector.ts`, `skill-injector.ts`, `test-filter.ts`, deps) are NOT
auto-loaded — pi only treats `index.ts` as the entry point — they are spawned
as subprocesses by the bridge.

## Event mapping

| oma concern | other vendors | pi event | bridge action |
|---|---|---|---|
| keyword-detector + skill-injector | `UserPromptSubmit` | `before_agent_start` | spawn both, append their `additionalContext` to `event.systemPrompt` |
| test-filter | `PreToolUse` (Bash) | `tool_call` (bash) | spawn test-filter, rewrite `event.input.command` in place |
| persistent-mode | `Stop` (block) | `agent_settled` | spawn persistent-mode; on a `block` decision, re-enter via `pi.sendUserMessage(reason)` |
| hud / status line | `statusLine` | `ctx.ui.setStatus` (RPC only) | not wired |

## Persistent workflows

`agent_settled` fires once a run has **fully settled** — no automatic retry,
compaction, or queued continuation remains. That is pi's analog of a Stop hook,
so the bridge spawns `persistent-mode.ts` there and, if a persistent workflow
(`orchestrate`, `ultrawork`, `work`) is still active, re-enters the loop by
re-injecting the reinforcement text through `pi.sendUserMessage(reason)` (which
**always triggers a fresh turn**).

Loop safety:

- **Session-scoped state.** The bridge threads `ctx.sessionManager.getSessionId()`
  into both the `before_agent_start` payload (so keyword-detector's `activateMode`
  actually writes the workflow state file — it refuses to write under an unknown
  session) and the `agent_settled` payload (so persistent-mode reads the matching
  file). Without a session id the whole loop is inert.
- **Primary terminator.** persistent-mode's own state file caps reinforcements
  (5) and expires on staleness — after that it returns no `block` and the loop
  ends. The re-injected reason begins with `[OMA PERSISTENT MODE:`; the bridge
  detects that sentinel in `before_agent_start` and **skips** re-injection for
  its own re-entry turns, so keyword-detector never re-activates the workflow and
  never resets that cap.
- **Backstop.** A hard ceiling of 50 consecutive re-entries per process (reset on
  every genuine user turn) guards against a pathological state file.
- **Pending input / idle.** Re-entry is skipped when `ctx.hasPendingMessages()`
  is true, and the whole handler is best-effort (`try/catch`) so a broken hook
  can never wedge pi.

### Version compatibility

`agent_settled` was added to pi **after 0.78.1**. Registration is
capability-guarded (the `pi.on` call is wrapped in `try/catch`, and
`pi.sendUserMessage` is feature-checked before use). On older pi builds the
handler is simply never emitted and persistent workflows degrade to
**re-injection on the next user turn** via `before_agent_start` — the historical
behavior. The `before_agent_start` / `tool_call` mappings are unchanged.

## Vendor identity

`"pi"` is present in the **hook-layer** `VENDORS`
(`.agents/hooks/core/constants.ts`) so the `Vendor` dialect in `hook-output.ts`
can emit pi-native shapes. It is intentionally **absent** from the cli-runtime
`VENDORS` (`cli/constants/vendors.ts`), which drives the settings-file install
that does not apply to pi. The CLI spawn path still supports `-m pi` through the
runtime-dispatch external CLI config; it invokes `pi -p` as a subprocess rather
than a native subagent API.

## Enabling

Add `pi` to the `vendors:` block in `.agents/oma-config.yaml`, then run
`oma link` (or `oma install` / `oma update`). The bridge is regenerated into
`.pi/extensions/oma/` and workflow prompt wrappers are regenerated into
`.pi/prompts/` on every link. pi picks up extension changes on `/reload` or next
launch.
