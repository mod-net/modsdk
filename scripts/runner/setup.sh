#!/usr/bin/env bash
set -euo pipefail
# Wrapper to run local runner setup scripts, falling back to chain repo's scripts if needed
# Usage: scripts/runner/setup.sh [--multi]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

LOCAL_SINGLE="$SCRIPT_DIR/setup-github-runner.sh"
LOCAL_MULTI="$SCRIPT_DIR/setup-github-runner-multi.sh"
CHAIN_SCRIPTS="$REPO_ROOT/chain/scripts"

if [[ "${1:-}" == "--multi" ]]; then
  if [ -x "$LOCAL_MULTI" ]; then
    exec bash "$LOCAL_MULTI" "${@:2}"
  elif [ -x "$CHAIN_SCRIPTS/setup-github-runner-multi.sh" ]; then
    exec bash "$CHAIN_SCRIPTS/setup-github-runner-multi.sh" "${@:2}"
  else
    echo "[error] No multi-runner setup script found." >&2
    exit 1
  fi
else
  if [ -x "$LOCAL_SINGLE" ]; then
    exec bash "$LOCAL_SINGLE" "$@"
  elif [ -x "$CHAIN_SCRIPTS/setup-github-runner.sh" ]; then
    exec bash "$CHAIN_SCRIPTS/setup-github-runner.sh" "$@"
  else
    echo "[error] No runner setup script found." >&2
    exit 1
  fi
fi
