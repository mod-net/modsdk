#!/usr/bin/env bash
set -euo pipefail
# Wrapper to run the chain repo's runner setup script from this monorepo
# Usage: scripts/runner/setup.sh [--multi]

REPO_ROOT="$(cd "$(dirname "$0")"/../.. && pwd)"
CHAIN_SCRIPTS="$REPO_ROOT/chain/scripts"

if [ ! -d "$CHAIN_SCRIPTS" ]; then
  echo "[error] chain submodule not found at $CHAIN_SCRIPTS. Run: bash scripts/update-submodules.sh" >&2
  exit 1
fi

if [[ "${1:-}" == "--multi" ]]; then
  exec bash "$CHAIN_SCRIPTS/setup-github-runner-multi.sh" "${@:2}"
else
  exec bash "$CHAIN_SCRIPTS/setup-github-runner.sh" "$@"
fi
