#!/usr/bin/env bash
set -euo pipefail

# Setup a single GitHub self-hosted runner for this repository.
# Reads defaults from scripts/runner/runner.conf (copy runner.conf.sample).
# You can override any var via environment or CLI args.
#
# CLI usage examples:
#   scripts/runner/setup-github-runner.sh
#   GITHUB_REPO_URL=https://github.com/mod-net/modsdk RUNNER_NAME=modsdk-runner-1 scripts/runner/setup-github-runner.sh
#
# Requirements on host:
# - Linux x64
# - Docker installed (if runners will use containers)
# - sudo privileges
# - curl, jq

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF_FILE="${CONF_FILE:-$SCRIPT_DIR/runner.conf}"

# shellcheck disable=SC1090
[ -f "$CONF_FILE" ] && source "$CONF_FILE"

# Defaults
GITHUB_REPO_URL=${GITHUB_REPO_URL:-"https://github.com/mod-net/modsdk"}
RUNNER_NAME=${RUNNER_NAME:-"$(hostname)-runner"}
RUNNER_LABELS=${RUNNER_LABELS:-"self-hosted,linux,x64,modnet-runner"}
RUNNER_WORK_DIR=${RUNNER_WORK_DIR:-"_work"}
RUNNER_INSTALL_DIR=${RUNNER_INSTALL_DIR:-"/opt/github/modsdk-runner"}
RUNNER_USER=${RUNNER_USER:-"githubrunner"}
RUNNER_REG_TOKEN=${RUNNER_REG_TOKEN:-""}
GITHUB_PAT=${GITHUB_PAT:-""}
USE_GH_CLI=${USE_GH_CLI:-"true"}

if ! command -v curl >/dev/null 2>&1; then echo "[error] curl is required" >&2; exit 1; fi
if ! command -v jq >/dev/null 2>&1; then echo "[error] jq is required" >&2; exit 1; fi

# Ensure user exists
if ! id -u "$RUNNER_USER" >/dev/null 2>&1; then
  echo "[info] Creating user $RUNNER_USER"
  sudo useradd -m -s /bin/bash "$RUNNER_USER" || true
  if getent group docker >/dev/null; then sudo usermod -aG docker "$RUNNER_USER" || true; fi
fi

# Create install dir and set ownership
sudo mkdir -p "$RUNNER_INSTALL_DIR"
sudo chown -R "$RUNNER_USER":"$RUNNER_USER" "$RUNNER_INSTALL_DIR"

# Download runner if missing
RUNNER_BIN="$RUNNER_INSTALL_DIR/run.sh"
if [ ! -x "$RUNNER_BIN" ]; then
  echo "[info] Downloading GitHub runner to $RUNNER_INSTALL_DIR"
  RUNNER_INSTALL_DIR="$RUNNER_INSTALL_DIR" bash "$SCRIPT_DIR/download-github-runner.sh"
fi

# Ensure ownership of all files (download may have created root-owned files)
sudo chown -R "$RUNNER_USER":"$RUNNER_USER" "$RUNNER_INSTALL_DIR"

# Ensure work dir exists and is owned by runner user
sudo -u "$RUNNER_USER" bash -lc "mkdir -p '$RUNNER_INSTALL_DIR/$RUNNER_WORK_DIR'"

# Obtain registration token
get_reg_token() {
  if [ -n "$RUNNER_REG_TOKEN" ]; then
    echo "$RUNNER_REG_TOKEN"
    return 0
  fi
  # Parse owner/repo from URL
  # e.g. https://github.com/mod-net/modsdk -> owner=mod-net repo=modsdk
  local owner repo
  owner=$(echo "$GITHUB_REPO_URL" | awk -F'github.com/' '{print $2}' | awk -F'/' '{print $1}')
  repo=$(echo "$GITHUB_REPO_URL" | awk -F'github.com/' '{print $2}' | awk -F'/' '{print $2}')
  if [ -z "$owner" ] || [ -z "$repo" ]; then
    echo "[error] Could not parse owner/repo from GITHUB_REPO_URL=$GITHUB_REPO_URL" >&2
    return 1
  fi
  if [ "$USE_GH_CLI" = "true" ] && command -v gh >/dev/null 2>&1; then
    if gh auth status -h github.com >/dev/null 2>&1; then
      echo "[info] Using gh CLI to create registration token"
      gh api -X POST "/repos/$owner/$repo/actions/runners" | jq -r '.token'
      return 0
    else
      echo "[warn] gh CLI found but not authenticated; falling back to PAT or RUNNER_REG_TOKEN"
    fi
  fi
  if [ -n "$GITHUB_PAT" ]; then
    echo "[info] Using PAT to create registration token"
    curl -fsSL -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_PAT" \
      "https://api.github.com/repos/$owner/$repo/actions/runners/registration-token" | jq -r '.token'
    return 0
  fi
  echo "[error] No RUNNER_REG_TOKEN provided and no authenticated gh CLI or GITHUB_PAT available." >&2
  echo "        Provide RUNNER_REG_TOKEN in runner.conf, or authenticate 'gh auth login', or set GITHUB_PAT." >&2
  return 1
}

# Obtain token and trim any trailing newlines/CR characters
TOKEN=$(get_reg_token | tr -d '\r\n')

# Defensive: remove any leading/trailing whitespace just in case
TOKEN=$(printf '%s' "$TOKEN" | awk '{$1=$1;print}')

# Validate token contains no forbidden whitespace/newlines
if printf '%s' "$TOKEN" | grep -qE '[[:space:]]'; then
  echo "[warn] Token contains whitespace; sanitizing"
  TOKEN=$(printf '%s' "$TOKEN" | tr -d '[:space:]')
fi

echo "[info] Registration token acquired (length: ${#TOKEN})"

# Heuristic: a valid registration token is typically ~70 chars. If it's short, try gh CLI fallback.
if [ ${#TOKEN} -lt 60 ] && command -v gh >/dev/null 2>&1 && gh auth status -h github.com >/dev/null 2>&1; then
  echo "[warn] Token length looks suspicious (${#TOKEN}). Attempting to fetch a fresh token via gh CLI..."
  owner=$(echo "$GITHUB_REPO_URL" | awk -F'github.com/' '{print $2}' | awk -F'/' '{print $1}')
  repo=$(echo "$GITHUB_REPO_URL" | awk -F'github.com/' '{print $2}' | awk -F'/' '{print $2}')
  FRESH=$(gh api -X POST "/repos/$owner/$repo/actions/runners/registration-token" -q .token 2>/dev/null | tr -d '\r\n')
  if [ -n "$FRESH" ]; then
    TOKEN="$FRESH"
    echo "[info] Replaced with fresh token (length: ${#TOKEN})"
  else
    echo "[warn] Failed to fetch fresh token via gh CLI; proceeding with existing token"
  fi
fi

# Configure runner (unattended)
configure_runner() {
  sudo -u "$RUNNER_USER" bash -lc "cd '$RUNNER_INSTALL_DIR' && ./config.sh --unattended --replace \
    --url '$GITHUB_REPO_URL' \
    --name '$RUNNER_NAME' \
    --labels '$RUNNER_LABELS' \
    --work '$RUNNER_WORK_DIR' \
    --token '$TOKEN'"
}

echo "[info] Configuring runner $RUNNER_NAME for $GITHUB_REPO_URL"
configure_runner

# Install and start as service using provided svc.sh
sudo bash -lc "cd '$RUNNER_INSTALL_DIR' && ./svc.sh install '$RUNNER_USER' || true"
sudo bash -lc "cd '$RUNNER_INSTALL_DIR' && ./svc.sh start || true"

systemctl status actions.runner.* --no-pager || true

echo "[done] Runner installed and started. Labels: $RUNNER_LABELS"
