#!/usr/bin/env bash
# Preserve distinct Qwen events; the shared primer deduplicates by session.
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
  "$__oma_bin" hook run "$@" || true
fi
exit 0
