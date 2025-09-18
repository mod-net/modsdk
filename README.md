# ModNet Monorepo (modsdk)

Central umbrella repository that consolidates all ModNet components via Git submodules, with a Nix flake providing unified developer environments for Rust/Substrate, Python, and TypeScript.

## Components

The following repositories are included as submodules at the repo root:

- `chain/` – Substrate blockchain (Rust)
- `mcp-registrar/` – Module registrar (Rust)
- `bridge/` – Substrate↔Ethereum/Base bridge contracts and scripts (TypeScript)
- `ipfs-service/` – IPFS node service and off-chain worker (Python)
- `docs/` – Obsidian-style documentation (Markdown)
- `module-pallet/` – Pallet for module registration and communication (Rust)

The `modsdk/` top-level also houses a Rust CLI/SDK (planned) and this coordination layer.

## Prerequisites

- Nix and flakes support
  - On NixOS/macOS/Linux: install from https://nixos.org or use the CI-pinned installer steps below.
- direnv (optional but recommended) – https://direnv.net/

## Quick Start

1. Clone the repo (you can add submodules later with the script):

   ```bash
   git clone https://github.com/mod-net/modsdk.git
   cd modsdk
   ```

2. Enable direnv (optional):

   ```bash
   direnv allow
   ```

3. Add and update submodules (defaults to `main` branch for each subrepo):

   ```bash
   bash scripts/update-submodules.sh
   # or specify a branch (e.g. master) used consistently across repos
   bash scripts/update-submodules.sh master
   ```

4. Enter the unified dev shell:

   ```bash
+  nix develop
   # or targeted shells
   nix develop .#rust
   nix develop .#python
   nix develop .#node
   nix develop .#substrate
   ```

If direnv is enabled, the shell will auto-load on `cd` into the repo.

## Dev Shells (Nix Flake)

The `flake.nix` provides multiple dev shells with all necessary tools:

- `default` – Rust (nightly + wasm), Python 3.13, Node 20 + pnpm
- `rust` – Rust toolchain focused shell
- `substrate` – Rust toolchain with Substrate/WASM helpers
- `python` – Python 3.13 toolchain
- `node` – Node 20 + pnpm toolchain

Common tools include: `git`, `jq`, `curl`, `rustfmt`, `clippy`, `cmake`, `pkg-config`, `openssl`, `protobuf`, `wasm-pack`, `binaryen`, `clang/llvm`, `pnpm`, `python` with `pip/setuptools/wheel`.

## Build and Lint

Use the provided `Makefile` targets from within `nix develop`:

- `make fmt` – Format Rust, Python (ruff), and TS (prettier) where available
- `make lint` – Clippy for Rust, ruff for Python, eslint for TS (if projects are configured)
- `make build-rust` – Build Rust workspaces (`chain`, `module-pallet`, `mcp-registrar`)
- `make build-bridge` – PNPM build for `bridge`
- `make build-ipfs` – Editable install for `ipfs-service`
- `make check` – `fmt` + `lint`
- `make ci` – Runs check + builds for all

Note: some subrepos may define their own commands and scripts. The above are convenience wrappers.

## CI

GitHub Actions workflow `.github/workflows/ci.yml` uses Nix to create the same dev shell and runs `make ci`. It checks out submodules recursively.

## Submodule Management

Use `scripts/update-submodules.sh` to add or update submodules. It sets `.gitmodules` entries and updates recursively. Default branch is `main`; you can pass another branch name if your repositories use `master` or a release branch.

```bash
bash scripts/update-submodules.sh            # uses main
bash scripts/update-submodules.sh master     # uses master
```

To initialize submodules after cloning an already-configured repo:

```bash
git submodule update --init --recursive
```

## Bootstrap

The `scripts/bootstrap.sh` script will:

- Ensure `.envrc` exists and remind to `direnv allow`.
- Warm up flake inputs.
- Initialize and update submodules if `.gitmodules` exists.

```bash
make bootstrap
```

## Notes and Gotchas

- Ensure you have the same default branch across subrepos (`main` vs `master`). Pass the desired branch to the update script if needed.
- Scripts are committed as text; if you need to ensure executable bits locally: `chmod +x scripts/*.sh`.
- If you change submodule commit pointers, commit the updated submodule state in this repo.

## Roadmap

- Add Rust CLI/SDK under `./cli/` and `./sdk/` (or similar) with workspace integration.
- Expand Nix `packages` to build the Rust crates and bridge scripts directly from the flake.

