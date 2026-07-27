#!/usr/bin/env bash
# oma-hook self-dedup — suppresses double-fire of the SAME event when both project and global installs register it.
# The lock key includes the event args ("$@") so DIFFERENT events (e.g. PreToolUse right after UserPromptSubmit) never suppress each other.
__oma_evt="$(printf '%s' "$*" | tr -c 'A-Za-z0-9' '_')"
__oma_dedup_lock="/tmp/oma-hook-${UID:-${EUID:-0}}-${OMA_SESSION_ID:-default}-${__oma_evt}.lock"
if [ -f "$__oma_dedup_lock" ]; then
  __oma_age=$(( $(date +%s) - $(stat -f %m "$__oma_dedup_lock" 2>/dev/null || stat -c %Y "$__oma_dedup_lock" 2>/dev/null || echo 0) ))
  if [ "$__oma_age" -lt 2 ]; then
    exit 0
  fi
fi
echo "$$" > "$__oma_dedup_lock"
__oma_bin=""
if [ -n "${OMA_BIN:-}" ] && [ -x "${OMA_BIN}" ]; then
  __oma_bin="${OMA_BIN}"
elif command -v oma >/dev/null 2>&1; then
  __oma_bin="$(command -v oma)"
else
  # PATH is minimal under GUI-launched agents; check the usual install dirs.
  for __oma_candidate in "$HOME/.bun/bin/oma" "$HOME/.local/bin/oma" "$HOME/.local/share/mise/shims/oma" "$HOME"/.local/share/mise/installs/node/*/bin/oma "$HOME/.volta/bin/oma" "$HOME/.npm-global/bin/oma" "/opt/homebrew/bin/oma" "/usr/local/bin/oma"; do
    if [ -x "$__oma_candidate" ]; then
      __oma_bin="$__oma_candidate"
      break
    fi
  done
fi
if [ -n "$__oma_bin" ]; then
  # Run oma hook; swallow a non-zero exit so the wrapper is always fail-open.
  "$__oma_bin" hook "$@" || true
fi
exit 0
