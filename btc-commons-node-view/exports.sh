# Commons Node View. Sourced by Umbrel for this app only (it does not stand in for Bitcoin Node).

# Fixed P2P ports, one per network; docker-compose.yml publishes all five and tells the node to listen on them.
# Mainnet is 8334, not 8333: Umbrel's own Bitcoin Node publishes 8333, and no app of Umbrel's official store publishes
# 8334 (Bitcoin Node and Bitcoin Knots only use it inside their own containers, for Tor), so both apps can run at the
# same time. Inbound peers need a router rule to 8334 on the Umbrel; syncing outbound works without one.
export APP_BTC_COMMONS_NODE_VIEW_P2P_PORT_MAINNET="8334"
export APP_BTC_COMMONS_NODE_VIEW_P2P_PORT_TESTNET3="18333"
export APP_BTC_COMMONS_NODE_VIEW_P2P_PORT_TESTNET4="48333"
export APP_BTC_COMMONS_NODE_VIEW_P2P_PORT_SIGNET="38333"
export APP_BTC_COMMONS_NODE_VIEW_P2P_PORT_REGTEST="18444"

# RPC login shared by the agent (node) and the console. Same value on every start and update of this install.
# The agent puts it into the node's config file ([rpc_auth]); the console sends it with every request.
export APP_BTC_COMMONS_NODE_VIEW_RPC_USER="umbrel"
export APP_BTC_COMMONS_NODE_VIEW_RPC_PASS="$(derive_entropy "${app_entropy_identifier}-rpc-password")"
