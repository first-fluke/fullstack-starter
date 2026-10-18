#!/usr/bin/env bash
# Pre-push entry. hk.pkl lists the gates. This file caches a clean pass by
# the git tree of the paths that gate reads.
#
#   scripts/pre-push.sh
#   scripts/pre-push.sh gate api
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

CACHE_DIR="$(cd "$(git rev-parse --git-common-dir)" && pwd)/pre-push-cache"
mkdir -p "$CACHE_DIR"

cached_gate() {
  local name=$1 deps=$2
  shift 2
  local key marker
  # shellcheck disable=SC2086
  key=$(
    {
      echo "$name"
      for p in mise.toml hk.pkl scripts/pre-push.sh $deps; do
        git rev-parse --verify -q "HEAD:$p" || echo "absent $p"
      done
    } | git hash-object --stdin
  )
  marker="$CACHE_DIR/$key"
  if [ -f "$marker" ]; then
    echo "[pre-push] $name: unchanged since it last passed, skipping."
    return 0
  fi
  echo "[pre-push] $name: running..."
  "$@" || return 1
  # shellcheck disable=SC2086
  if [ -n "$(git status --porcelain -- mise.toml hk.pkl scripts/pre-push.sh $deps)" ]; then
    echo "[pre-push] $name: passed but not cached (uncommitted changes present)."
  else
    : > "$marker"
  fi
}

run_gate() {
  case "$1" in
    branch)
      ./node_modules/.bin/validate-branch
      ;;
    api)
      cached_gate api "apps/api" mise //apps/api:test
      ;;
    web)
      cached_gate web "apps/web packages/design-tokens packages/i18n" mise //apps/web:test
      ;;
    worker)
      cached_gate worker "apps/worker" mise //apps/worker:test
      ;;
    mobile)
      cached_gate mobile "apps/mobile packages/design-tokens packages/i18n" \
        env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE mise //apps/mobile:test
      ;;
    *)
      echo "pre-push: unknown gate $1" >&2
      exit 2
      ;;
  esac
}

if [ "${1:-}" = "gate" ]; then
  run_gate "${2:?gate name}"
  exit
fi

find "$CACHE_DIR" -type f -mtime +14 -delete 2>/dev/null || true
hk run pre-push
