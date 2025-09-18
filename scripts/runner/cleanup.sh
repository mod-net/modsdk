#!/usr/bin/env bash
set -euo pipefail
# Cleanup a partially configured runner: stop/uninstall service and remove registration
# Usage: scripts/runner/cleanup.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF_FILE="${CONF_FILE:-$SCRIPT_DIR/runner.conf}"
[ -f "$CONF_FILE" ] && source "$CONF_FILE"

RUNNER_INSTALL_DIR=${RUNNER_INSTALL_DIR:-"/opt/github/modsdk-runner"}

cd "$RUNNER_INSTALL_DIR" 2>/dev/null || { echo "[warn] Runner dir not found: $RUNNER_INSTALL_DIR"; exit 0; }

# Try to stop/uninstall service
sudo ./svc.sh stop || true
sudo ./svc.sh uninstall || true

# Try to remove config with a fresh token if gh is authenticated
if command -v gh >/dev/null 2>&1 && gh auth status -h github.com >/dev/null 2>&1; then
  owner=${GITHUB_REPO_URL:-"https://github.com/mod-net/modsdk"}
  owner=$(echo "$owner" | awk -F'github.com/' '{print $2}' | awk -F'/' '{print $1}')
  repo=${GITHUB_REPO_URL:-"https://github.com/mod-net/modsdk"}
  repo=$(echo "$repo" | awk -F'github.com/' '{print $2}' | awk -F'/' '{print $2}')
  TOKEN=$(gh api -X POST "/repos/$owner/$repo/actions/runners/registration-token" -q .token | tr -d '\r\n')
  sudo ./config.sh remove --token "$TOKEN" || true
else
  echo "[info] gh not authenticated; skipping config removal. You can pass RUNNER_REG_TOKEN and run:"
  echo "      sudo ./config.sh remove --token \"<token>\""
fi

echo "[done] Cleanup attempted for $RUNNER_INSTALL_DIR"
