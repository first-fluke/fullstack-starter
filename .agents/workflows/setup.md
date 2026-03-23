---
description: Initial setup workflow — verify CLI installations, check MCP connections, configure language and agent-CLI mapping
---

# MANDATORY RULES — VIOLATION IS FORBIDDEN

- **Response language follows `language` setting in `.agents/config/user-preferences.yaml` if configured.**
- **NEVER skip steps.** Execute from Step 1 in order.
- **Read configuration files BEFORE making changes.**

---

> **Vendor note:** This workflow executes inline (no subagent spawning). All vendors use their native shell and file tools for CLI detection and configuration.

---

## Step 1: Language Settings

1. Check if `.agents/config/user-preferences.yaml` exists
2. If not:
   - Ask user for preferred language (ko, en, ja, zh, ...)
   - Create default configuration file
3. If exists:
   - Display current language setting
   - Ask if user wants to change

---

## Step 2: CLI Installation Status

Check each CLI installation:

```bash
which gemini && gemini --version
which claude && claude --version
which codex && codex --version
```

Display results:

```
🔍 CLI Installation Status
┌─────────┬───────────┬─────────────┐
│ CLI     │ Status    │ Version     │
├─────────┼───────────┼─────────────┤
│ gemini  │ ✅ Installed │ v2.1.0   │
│ claude  │ ✅ Installed │ v1.0.30  │
│ codex   │ ❌ Not Found │ -        │
└─────────┴───────────┴─────────────┘
```

Provide installation guide for missing CLIs:

- **gemini**: `npm install -g @google/gemini-cli`
- **claude**: `npm install -g @anthropic-ai/claude-code`
- **codex**: `npm install -g @openai/codex-cli`

---

## Step 3: MCP Connection Status

1. Check `.agents/mcp.json` existence and configuration
2. Check MCP settings for each CLI:
   - Gemini CLI: `~/.gemini/settings.json`
   - Claude CLI: `~/.claude.json` or `--mcp-config`
   - Codex CLI: `~/.codex/config.toml`
   - Antigravity IDE: `~/.gemini/antigravity/mcp_config.json`
3. Test Serena MCP connection

Display results:

```
🔗 MCP Connection Status
┌─────────────────┬────────────┬─────────────────────┐
│ Environment     │ MCP Config │ Server              │
├─────────────────┼────────────┼─────────────────────┤
│ gemini CLI      │ ✅ Set     │ serena              │
│ claude CLI      │ ✅ Set     │ serena              │
│ Antigravity IDE │ ⚠️ Check   │ see Step 3.1        │
│ codex CLI       │ ❌ Not Set │ -                   │
└─────────────────┴────────────┴─────────────────────┘
```

For missing MCP settings:

- Display configuration instructions
- Offer automatic setup option

---

## Step 3.1: Serena MCP Configuration (Optional)

> **Ask the user**: "Do you use Serena MCP server? (y/n)"
> Skip this step if user answers "no".

### Option A: Command Mode (Simple)

Serena runs as a subprocess for each session. No separate server needed.

**Gemini CLI** (`~/.gemini/settings.json`):

```json
{
  "mcpServers": {
    "serena": {
      "command": "uv",
      "args": ["run", "serena", "--project", "/path/to/your/project"]
    }
  }
}
```

**Antigravity IDE** (`~/.gemini/antigravity/mcp_config.json`):

```json
{
  "mcpServers": {
    "serena": {
      "command": "uv",
      "args": ["run", "serena", "--project", "/path/to/your/project"],
      "disabled": false
    }
  }
}
```

### Option B: SSE Mode (Shared Server)

Serena runs as a shared SSE server. Multiple sessions can share one server instance.

**1. Start Serena server:**

```bash
serena-mcp-server --port 12341
```

**2. Gemini CLI** (`~/.gemini/settings.json`):

```json
{
  "mcpServers": {
    "serena": {
      "url": "http://localhost:12341/sse"
    }
  }
}
```

**3. Antigravity IDE** — requires bridge:

> **Important**: Antigravity IDE doesn't support SSE directly.
> You need the `bridge` command to connect.

**Configure** (`~/.gemini/antigravity/mcp_config.json`):

```json
{
  "mcpServers": {
    "serena": {
      "command": "npx",
      "args": ["-y", "oh-my-agent@latest", "bridge", "http://localhost:12341/sse"],
      "disabled": false
    }
  }
}
```

**Bridge Architecture:**

```
┌─────────────────┐     stdio      ┌──────────────────┐     HTTP/SSE     ┌─────────────────┐
│ Antigravity IDE │ ◄────────────► │  oh-my-ag bridge │ ◄──────────────► │ Serena SSE      │
└─────────────────┘                └──────────────────┘                  └─────────────────┘
                                                                          (localhost:12341)
```

### Comparison

| Mode    | Memory Usage | Setup Complexity | Multiple Sessions |
|---------|--------------|------------------|-------------------|
| Command | Higher       | Simple           | Each has own process |
| SSE     | Lower        | Requires server  | Share one server |

---

## Step 4: Agent-CLI Mapping

1. Display current mapping
2. Ask if user wants to change:

   ```
   Current Agent-CLI Mapping:
   ┌──────────┬─────────┐
   │ Agent    │ CLI     │
   ├──────────┼─────────┤
   │ frontend │ gemini  │
   │ backend  │ gemini  │
   │ mobile   │ gemini  │
   │ pm       │ gemini  │
   │ qa       │ gemini  │
   │ debug    │ gemini  │
   └──────────┴─────────┘

   Do you want to change? (e.g., "backend to codex", "pm to claude")
   ```

3. Update `.agents/config/user-preferences.yaml` if changes requested

---

## Step 5: Setup Complete Summary

```
✅ Setup Complete!

📝 Configuration Summary:
- Response Language: English (en)
- Timezone: UTC
- Installed CLIs: gemini ✅, claude ✅, codex ❌
- MCP Status: Configured

📋 Agent-CLI Mapping:
- frontend → gemini
- backend  → gemini
- mobile   → gemini
- pm       → gemini
- qa       → gemini
- debug    → gemini

🚀 Get Started:
- /plan: Create project plan
- /orchestrate: Automated multi-agent execution
- /coordinate: Interactive multi-agent coordination
```

If Antigravity IDE with SSE mode:

```
💡 For Antigravity IDE (SSE mode):
- Start Serena server: serena-mcp-server --port 12341
- Restart IDE to apply changes
```

---

## Step 6: Ask About Starring Repository

First, check if `gh` CLI is available and authenticated:

```bash
gh auth status &>/dev/null
```

### If gh is available and authenticated

**Before prompting, check if the repository is already starred:**

```bash
gh api user/starred/first-fluke/oh-my-ag &>/dev/null
```

**If already starred (exit code 0):**

- Skip the prompt entirely

**If NOT starred (exit code non-zero):**

> **Ask the user**: "If you're enjoying oh-my-agent, would you like to support the project by starring it on GitHub?"
>
> **Options:**
>
> 1. Yes, star it!
> 2. Maybe later

If user chooses "Yes, star it!":

```bash
gh api -X PUT /user/starred/first-fluke/oh-my-ag 2>/dev/null && echo "Thanks for starring! ⭐" || true
```

**Note:** Fail silently if the API call doesn't work - never block setup completion.

### If gh is NOT available or not authenticated

```bash
echo ""
echo "If you enjoy oh-my-agent, consider starring the repo:"
echo "  https://github.com/first-fluke/oh-my-ag"
echo ""
```
