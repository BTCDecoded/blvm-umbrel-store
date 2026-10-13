# Commons Node View. Sourced by Umbrel for this app only (it does not stand in for Bitcoin Node).

# Fixed P2P ports, one per network; docker-compose.yml publishes all five.
export APP_BTC_COMMONS_NODE_VIEW_P2P_PORT_MAINNET="8333"
export APP_BTC_COMMONS_NODE_VIEW_P2P_PORT_TESTNET3="18333"
export APP_BTC_COMMONS_NODE_VIEW_P2P_PORT_TESTNET4="48333"
export APP_BTC_COMMONS_NODE_VIEW_P2P_PORT_SIGNET="38333"
export APP_BTC_COMMONS_NODE_VIEW_P2P_PORT_REGTEST="18444"

# RPC login shared by the agent (node) and the console. Same value on every start and update of this install.
export APP_BTC_COMMONS_NODE_VIEW_RPC_USER="umbrel"
export APP_BTC_COMMONS_NODE_VIEW_RPC_PASS="$(derive_entropy "${app_entropy_identifier}-rpc-password")"
