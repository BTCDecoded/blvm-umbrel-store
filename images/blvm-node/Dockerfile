# syntax=docker/dockerfile:1.7
#
# BLVM node for the Bitcoin Commons Umbrel store.
# Build context = this folder after ./fetch-sources.sh has filled ./src with the
# BTCDecoded repos at the commits in sources.txt. `blvm` finds its sibling crates
# through the [patch.crates-io] paths in its own Cargo.toml (../blvm-node, ...).

FROM rust:1.88-bookworm AS build
# heed3/LMDB and friends compile C code; bindgen needs libclang.
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential cmake pkg-config libssl-dev clang libclang-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY src/ ./
WORKDIR /src/blvm
RUN --mount=type=cache,target=/usr/local/cargo/registry,sharing=locked \
    --mount=type=cache,target=/usr/local/cargo/git,sharing=locked \
    cargo build --release --bin blvm \
    && cp target/release/blvm /blvm

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates libssl3 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /data && chown 1000:1000 /data
COPY --from=build /blvm /usr/local/bin/blvm
COPY entrypoint.sh /usr/local/bin/blvm-umbrel
COPY sources.txt /usr/local/share/blvm/sources.txt
ENV BLVM_NETWORK=testnet \
    BLVM_DATA_DIR=/data \
    BLVM_RPC_PORT=18332 \
    BLVM_P2P_PORT=18333
VOLUME /data
EXPOSE 18332 18333
USER 1000:1000
ENTRYPOINT ["/usr/local/bin/blvm-umbrel"]
