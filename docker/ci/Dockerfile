# CI image for ModNet monorepo workflows
# Includes: Nix (single-user), common build deps (Rust builds, Node builds), and utilities.

FROM debian:bookworm-slim

LABEL org.opencontainers.image.source="https://github.com/mod-net/modsdk"
LABEL org.opencontainers.image.description="CI image for ModNet (Nix + build deps)"
LABEL org.opencontainers.image.licenses="Apache-2.0"

ENV DEBIAN_FRONTEND=noninteractive

# Base deps for builds and Nix install
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        xz-utils \
        git \
        build-essential \
        pkg-config \
        libssl-dev \
        protobuf-compiler \
        cmake \
        clang \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# Install Nix (single-user) for root in container
# Note: we intentionally use non-daemon mode in containers
RUN sh -c "\
    set -eux; \
    curl -L https://nixos.org/nix/install -o /tmp/nix-install.sh; \
    sh /tmp/nix-install.sh --no-daemon; \
    echo '. /root/.nix-profile/etc/profile.d/nix.sh' >> /etc/profile; \
    echo '. /root/.nix-profile/etc/profile.d/nix.sh' >> /root/.bashrc; \
    . /root/.nix-profile/etc/profile.d/nix.sh; \
    nix --version \
  "

# Optional: Node 20 + pnpm preinstall to speed up JS tasks if needed outside Nix
# You can rely solely on Nix if preferred; keeping these for convenience
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && npm i -g pnpm \
    && rm -rf /var/lib/apt/lists/*

# Set default shell to bash and ensure nix is in PATH for RUN and container sessions
SHELL ["/bin/bash", "-lc"]
ENV PATH=/root/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Warm up nix by showing version (already done) and creating a minimal store path
RUN nix --version && true

WORKDIR /workspace
