#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

stage="${1:-}"
case "${stage}" in
  code)
    command -v codex >/dev/null 2>&1
    ;;
  cursor)
    command -v cursor-agent >/dev/null 2>&1
    ;;
  security)
    command -v cursor-agent >/dev/null 2>&1
    command -v semgrep >/dev/null 2>&1
    ;;
  design)
    command -v claude >/dev/null 2>&1
    ;;
  *)
    echo "Usage: scripts/ai-review-preflight.sh <code|cursor|security|design>" >&2
    exit 2
    ;;
esac
