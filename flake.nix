{
  description = "ModNet monorepo dev shells (Rust/Substrate, Python, TypeScript)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        rustToolchain = pkgs.rust-bin.nightly.latest.default.override {
          targets = [ "wasm32-unknown-unknown" ];
        };

        python = pkgs.python313; # aligns with pyproject.toml requires-python >=3.13

        node = pkgs.nodejs_20;
        pnpm = pkgs.pnpm;
        eslint = pkgs.nodePackages_latest.eslint;
        prettier = pkgs.nodePackages_latest.prettier;

        commonBuildPkgs = with pkgs; [
          # Core tooling
          git
          jq
          curl
          wget

          # Rust/Substrate toolchain
          rustToolchain
          cargo
          rustfmt
          clippy
          cmake
          pkg-config
          openssl
          protobuf
          binaryen
          llvmPackages.clang
          llvmPackages.llvm
          wasm-pack

          # Node/TS
          node
          pnpm
          eslint
          prettier

          # Python
          python
          python.pkgs.pip
          python.pkgs.setuptools
          python.pkgs.wheel

          # Python linting/formatting
          ruff

          # Solidity / Foundry
          foundry-bin
          solc

          # Repo tooling
          pre-commit
        ];

        shellEnv = {
          RUSTUP_TOOLCHAIN = "nightly";
          # Helpful env for Substrate builds
          CARGO_TERM_COLOR = "always";
          # Speed up wasm builds sometimes
          WASM_BUILD_TYPE = "release";
        };

      in {
        devShells = {
          default = pkgs.mkShell {
            name = "modnet-dev";
            buildInputs = commonBuildPkgs;
            shellHook = ''
              echo "Loaded dev shell: default (Rust/Substrate + Node + Python)"
              export ${pkgs.lib.concatStringsSep " " (pkgs.lib.mapAttrsToList (k: v: "${k}=${v}") shellEnv)}
            '';
          };

          rust = pkgs.mkShell {
            name = "modnet-rust";
            buildInputs = with pkgs; [
              rustToolchain cargo rustfmt clippy cmake pkg-config openssl protobuf binaryen llvmPackages.clang llvmPackages.llvm wasm-pack git jq
            ];
            shellHook = ''
              echo "Loaded dev shell: rust"
              export RUSTUP_TOOLCHAIN=nightly
              export CARGO_TERM_COLOR=always
            '';
          };

          substrate = pkgs.mkShell {
            name = "modnet-substrate";
            buildInputs = with pkgs; [
              rustToolchain cargo rustfmt clippy cmake pkg-config openssl protobuf binaryen llvmPackages.clang llvmPackages.llvm wasm-pack git jq
            ];
            shellHook = ''
              echo "Loaded dev shell: substrate"
              export RUSTUP_TOOLCHAIN=nightly
              export CARGO_TERM_COLOR=always
              export WASM_BUILD_TYPE=release
            '';
          };

          python = pkgs.mkShell {
            name = "modnet-py";
            buildInputs = with pkgs; [ python python.pkgs.pip python.pkgs.setuptools python.pkgs.wheel git jq ];
            shellHook = ''
              echo "Loaded dev shell: python (3.13)"
              python --version
            '';
          };

          node = pkgs.mkShell {
            name = "modnet-node";
            buildInputs = with pkgs; [ node pnpm git jq ];
            shellHook = ''
              echo "Loaded dev shell: node (pnpm)"
              node --version
              pnpm --version || true
            '';
          };
        };

        packages = {};
        apps = {};
      }
    );
}
