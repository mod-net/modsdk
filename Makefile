SHELL := /usr/bin/env bash
.ONESHELL:

.DEFAULT_GOAL := help

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-24s\033[0m %s\n", $$1, $$2}'

bootstrap: ## Bootstrap repo: direnv + nix flake show + init submodules
	bash scripts/bootstrap.sh

submodules: ## Configure and update git submodules
	bash scripts/update-submodules.sh

build-all: ## Build all subprojects (Rust, TS, Python)
	bash scripts/build/build-all.sh

runner-setup: ## Run self-hosted runner setup (wraps chain/scripts/setup-github-runner*.sh)
	bash scripts/runner/setup.sh

fmt: ## Format Rust, Python and TypeScript projects if present
	@if [ -d chain ] || [ -d module-pallet ] || [ -d mcp-registrar ]; then \
		echo "[fmt] rust"; \
		cargo fmt --all || true; \
	fi
	@if command -v ruff >/dev/null 2>&1; then \
		if [ -d ipfs-service ]; then echo "[fmt] python"; ruff format ipfs-service || true; fi; \
	fi
	@if command -v prettier >/dev/null 2>&1; then \
		if [ -d bridge ]; then echo "[fmt] ts"; prettier -w "bridge/**/*.{ts,tsx,js,jsx,json,md}" || true; fi; \
	fi

lint: ## Lint Rust, Python and TypeScript projects if present
	@if [ -d chain ] || [ -d module-pallet ] || [ -d mcp-registrar ]; then \
		echo "[lint] rust"; \
		cargo clippy --all-targets --all-features -D warnings || true; \
	fi
	@if command -v ruff >/dev/null 2>&1; then \
		if [ -d ipfs-service ]; then echo "[lint] python"; ruff check ipfs-service || true; fi; \
	fi
	@if command -v eslint >/dev/null 2>&1; then \
		if [ -d bridge ]; then echo "[lint] ts"; (cd bridge && pnpm install && pnpm run lint) || true; fi; \
	fi

pre-commit-install: ## Install pre-commit hooks
	pre-commit install -t pre-commit -t commit-msg -t pre-push

pre-commit-run: ## Run pre-commit on all files
	pre-commit run --all-files

build-rust: ## Build Rust workspaces (if present)
	@if [ -f chain/Cargo.toml ]; then echo "[build] chain"; (cd chain && cargo build --release); fi
	@if [ -f module-pallet/Cargo.toml ]; then echo "[build] module-pallet"; (cd module-pallet && cargo build --release); fi
	@if [ -f mcp-registrar/Cargo.toml ]; then echo "[build] mcp-registrar"; (cd mcp-registrar && cargo build --release); fi

build-bridge: ## Build TypeScript bridge (pnpm)
	@if [ -f bridge/package.json ]; then echo "[build] bridge"; (cd bridge && pnpm install && pnpm run build); fi

build-ipfs: ## Build/prepare Python ipfs-service (pip install -e)
	@if [ -f ipfs-service/pyproject.toml ]; then echo "[build] ipfs-service"; (cd ipfs-service && python -m pip install -U pip && pip install -e .); fi

check: fmt lint ## Run formatters and linters

ci: ## CI entrypoint
	@echo "Running CI tasks via Nix dev shell..."
	@$(MAKE) check
	@$(MAKE) build-rust build-bridge build-ipfs
