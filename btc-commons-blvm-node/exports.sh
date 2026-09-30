# BLVM Node on testnet3. Sourced by Umbrel for this app and for apps that depend on `bitcoin`
# and picked BLVM Node as their provider (for example Commons UI).

export APP_BTC_COMMONS_BLVM_NODE_NODE_IP="btc-commons-blvm-node_node_1"
export APP_BTC_COMMONS_BLVM_NODE_RPC_PORT="18332"
export APP_BTC_COMMONS_BLVM_NODE_P2P_PORT="18333"
export APP_BTC_COMMONS_BLVM_NODE_NETWORK="testnet"
export APP_BTC_COMMONS_BLVM_NODE_NETWORK_ELECTRS="testnet"
export APP_BTC_COMMONS_BLVM_NODE_DATA_DIR="${EXPORTS_APP_DATA_DIR}/blvm"
export APP_BTC_COMMONS_BLVM_NODE_RPC_USER="umbrel"
export APP_BTC_COMMONS_BLVM_NODE_RPC_PASS="$(derive_entropy "app-btc-commons-blvm-node-seed-rpc-password")"

# The `bitcoin` contract, for apps that use BLVM Node in place of Bitcoin Node.
# Only RPC and P2P are provided; there is no ZMQ or Tor yet.
for var in NODE_IP RPC_PORT P2P_PORT NETWORK NETWORK_ELECTRS DATA_DIR RPC_USER RPC_PASS; do
  bitcoin_var="APP_BITCOIN_${var}"
  blvm_var="APP_BTC_COMMONS_BLVM_NODE_${var}"
  export "$bitcoin_var"="${!bitcoin_var:=${!blvm_var}}"
done
