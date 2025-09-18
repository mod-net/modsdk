#!/usr/bin/env bash
set -euo pipefail

# Setup multiple GitHub self-hosted runners for this repository.
# Reads defaults from scripts/runner/runner.conf (copy runner.conf.sample).
# You can override any var via environment or CLI args.
#
# Usage:
#   scripts/runner/setup-github-runner-multi.sh <count>
#   COUNT=3 scripts/runner/setup-github-runner-multi.sh
#
# Each runner will be named: ${RUNNER_NAME}-${i} if RUNNER_NAME provided, else <hostname>-runner-${i}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF_FILE="${CONF_FILE:-$SCRIPT_DIR/runner.conf}"

# shellcheck disable=SC1090
[ -f "$CONF_FILE" ] && source "$CONF_FILE"

COUNT=${1:-${COUNT:-2}}
if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || [ "$COUNT" -le 0 ]; then
  echo "Usage: $0 <count>" >&2
  exit 1
fi

BASE_NAME=${RUNNER_NAME:-"$(hostname)-runner"}
for i in $(seq 1 "$COUNT"); do
  export RUNNER_NAME="${BASE_NAME}-${i}"
  export RUNNER_INSTALL_DIR="${RUNNER_INSTALL_DIR:-/opt/github/modsdk-runner}-${i}"
  echo "[info] Setting up runner $RUNNER_NAME in $RUNNER_INSTALL_DIR"
  bash "$SCRIPT_DIR/setup-github-runner.sh"
  echo "[info] Runner $RUNNER_NAME setup complete"
  echo
done

echo "[done] $COUNT runners configured."
