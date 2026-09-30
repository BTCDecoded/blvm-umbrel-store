#!/bin/sh
# Writes the node config from env on every start, then runs blvm.
#
#   BLVM_NETWORK     testnet (testnet3) | testnet4 | signet | regtest | mainnet   default testnet
#   BLVM_DATA_DIR    chain data                                                  default /data
#   BLVM_RPC_PORT    RPC port, listens on all interfaces                         default 18332
#   BLVM_P2P_PORT    P2P port, listens on all interfaces                         default 18333
#   BLVM_RPC_USER    RPC username (Bitcoin Core style HTTP Basic)                 optional
#   BLVM_RPC_PASS    RPC password; when set, RPC requires this login              optional
#   BLVM_MAX_PEERS   peer limit                                                  default 40
set -eu

conf=/tmp/blvm.toml
{
  echo "max_peers = ${BLVM_MAX_PEERS:-40}"
  echo 'transport_preference = "tcponly"'
  echo
  echo '[modules]'
  echo 'enabled = false'
  if [ -n "${BLVM_RPC_PASS:-}" ]; then
    echo
    echo '[rpc_auth]'
    echo 'required = true'
    echo "username = \"${BLVM_RPC_USER:-umbrel}\""
    echo "password = \"${BLVM_RPC_PASS}\""
  fi
} > "$conf"
chmod 600 "$conf"

mkdir -p "${BLVM_DATA_DIR:=/data}"
echo "blvm-umbrel: network=${BLVM_NETWORK:=testnet} rpc=0.0.0.0:${BLVM_RPC_PORT:=18332} p2p=0.0.0.0:${BLVM_P2P_PORT:=18333} data=${BLVM_DATA_DIR}"
exec /usr/local/bin/blvm \
  --config "$conf" \
  --network "$BLVM_NETWORK" \
  --data-dir "$BLVM_DATA_DIR" \
  --rpc-addr "0.0.0.0:${BLVM_RPC_PORT}" \
  --listen-addr "0.0.0.0:${BLVM_P2P_PORT}" \
  "$@"
