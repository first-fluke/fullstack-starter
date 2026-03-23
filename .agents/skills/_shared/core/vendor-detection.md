# Vendor Detection Protocol

When executing a workflow, determine your runtime environment using this priority order:

## Detection Order (use first match)

1. **Claude Code**: Your system prompt contains "You are Claude Code" OR the `Agent` tool is available
2. **Codex CLI**: Your system prompt contains "Codex CLI" OR the `apply_patch` tool is available
3. **Gemini CLI**: This file was auto-loaded from `.agents/skills/` AND `@` subagent syntax is available
4. **Antigravity IDE**: This file was auto-loaded from `.agents/skills/` AND no `@` subagent syntax
5. **CLI Fallback**: None of the above matched → use `oh-my-ag agent:spawn`

## Vendor-Specific Spawn Methods

| Vendor | Spawn Method | Result Handling |
|:---|:---|:---|
| Claude Code | `Agent` tool with `.claude/agents/{name}.md` | Synchronous return |
| Codex CLI | Model-mediated parallel subagent request | JSON output |
| Gemini CLI | `@{agent-name}` delegation or `oh-my-ag agent:spawn` | MCP memory poll |
| Antigravity | `oh-my-ag agent:spawn` only (custom subagents not available) | MCP memory poll |
| CLI Fallback | `oh-my-ag agent:spawn {agent} {prompt} {session} -w {workspace}` | Result file poll |
