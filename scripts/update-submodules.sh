#!/usr/bin/env bash
set -euo pipefail

# Add or update submodules for the ModNet platform
# Usage: scripts/update-submodules.sh [branch]
# Default branch is main

BRANCH=${1:-main}

REPO_ROOT="$(cd "$(dirname "$0")"/.. && pwd)"
cd "$REPO_ROOT"

function ensure_submodule() {
  local path="$1"; shift
  local url="$1"; shift
  local branch="$1"; shift

  if git config --file .gitmodules --name-only --get-regexp "submodule\\.${path//\//\\/}\\.path" >/dev/null 2>&1; then
    echo "[info] Submodule exists: ${path} -> ${url} (branch ${branch})"
    git submodule set-url "$path" "$url" || true
    git config -f .gitmodules "submodule.${path}.branch" "$branch" || true
  else
    echo "[info] Adding submodule: $path"
    git submodule add -b "$branch" "$url" "$path"
    git config -f .gitmodules "submodule.${path}.branch" "$branch"
  fi
}

ensure_submodule "chain"          "https://github.com/mod-net/chain.git"          "$BRANCH"
ensure_submodule "mcp-registrar"  "https://github.com/mod-net/mcp-registrar.git" "$BRANCH"
ensure_submodule "bridge"         "https://github.com/mod-net/bridge.git"         "$BRANCH"
ensure_submodule "ipfs-service"   "https://github.com/mod-net/ipfs-service.git"   "$BRANCH"
ensure_submodule "docs"           "https://github.com/mod-net/docs.git"           "$BRANCH"
ensure_submodule "module-pallet"  "https://github.com/mod-net/module-pallet.git"  "$BRANCH"
ensure_submodule "cli"            "https://github.com/mod-net/cli.git"            "$BRANCH"

# Initialize and update

echo "[info] Initializing and updating submodules recursively..."
git submodule update --init --recursive

echo "[done] Submodules are configured. Commit .gitmodules and submodule entries."
