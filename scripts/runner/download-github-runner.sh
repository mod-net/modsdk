#!/usr/bin/env bash
set -euo pipefail

# Download latest GitHub Actions runner for Linux x64 into $RUNNER_INSTALL_DIR
# Requires RUNNER_INSTALL_DIR env var or runner.conf

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF_FILE="${CONF_FILE:-$SCRIPT_DIR/runner.conf}"

# shellcheck disable=SC1090
[ -f "$CONF_FILE" ] && source "$CONF_FILE"

: "${RUNNER_INSTALL_DIR:?RUNNER_INSTALL_DIR is required (set in runner.conf)}"

mkdir -p "$RUNNER_INSTALL_DIR"
cd "$RUNNER_INSTALL_DIR"

if [ -x ./run.sh ]; then
  echo "[info] Runner already present at $RUNNER_INSTALL_DIR"
  exit 0
fi

LATEST_URL="https://api.github.com/repos/actions/runner/releases/latest"
TAG=$(curl -fsSL "$LATEST_URL" | jq -r '.tag_name')
PKG="actions-runner-linux-x64-${TAG#v}.tar.gz"
URL="https://github.com/actions/runner/releases/download/${TAG}/${PKG}"

echo "[info] Downloading $PKG ..."
curl -fsSL -o "$PKG" "$URL"

echo "[info] Extracting ..."
tar xzf "$PKG"
rm -f "$PKG"

echo "[done] Runner downloaded to $RUNNER_INSTALL_DIR"
