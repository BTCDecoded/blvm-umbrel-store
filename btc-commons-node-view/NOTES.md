# Umbrel constraints check for Commons Node View

Checked 2026-10-13 against the official guidance in `getumbrel/umbrel-apps` (`.agents/skills/umbrel-package-app` and
`umbrel-test-app`, the `bitcoin` package as the reference for ports and exports) and the umbreld source in
`getumbrel/umbrel` (`apps/legacy-compat/app-script`, `app-environment.ts`, `app-gateway/app-gateway.ts`).
"Verified" means read in those sources or run; "not verified" means it needs a real Umbrel.

This file is copied onto every Umbrel that installs the app (everything in an app folder is). It is documentation only.

## Verified

| Topic | Result |
|---|---|
| Ports | Manifest `port: 3849` is the app_proxy port and is unique across the official store (the Umbrel linter's `ports.unique` check passes for it). The container also listens on 3849 (`APP_PORT: 3849`); the two numbers are independent. The web page is not published with `ports:`. Only the agent publishes ports: the five P2P ports, with the container port equal to the host port. Mainnet is **8334**, because the official Bitcoin Node publishes 8333 (checked 2026-10-13 against a fresh clone of `getumbrel/umbrel-apps`: no app publishes 8334, 18333, 48333, 38333 or 18444; `bitcoin` and `bitcoin-knots` only name 8334 as their in-container Tor port, and `bitcoin-knots` publishes 9333 and 9332, so those two were not candidates). The node is told to listen on the published port: the compose file gives the agent `BLVM_AGENT_P2P_PORT_<NET>` (`MAINNET`, `TESTNET4`, `TESTNET` for Testnet3, `SIGNET`, `REGTEST`), the agent starts the node with `--listen-addr 0.0.0.0:<port>`, and the web container gets the same variables only to print the port. The RPC ports are not published. |
| `app_proxy` | Environment only, `APP_HOST: btc-commons-node-view_web_1` (`<app-id>_<service>_1`), `APP_PORT: 3849`. Umbrel login stays on (default). umbrelOS 2.0 serves the same port over HTTPS too, so the console is reached over http or https. |
| Host header | The gateway proxies with `changeOrigin: false`, so the console sees the **original** `Host` the browser typed (`umbrel.local:3849`, an IP address, a `.onion` name, a Tailscale name). `BLVM_UI_ALLOWED_HOSTS` lists `APP_DOMAIN`, `DEVICE_DOMAIN_NAME`, `DEVICE_HOSTNAME` and the web container name. Note the variable is `DEVICE_DOMAIN_NAME`; `DEVICE_DOMAIN` does not exist in Umbrel. IP-address and `.onion` hosts are accepted once `BLVM_UI_ALLOWED_HOSTS` lists a name (`src/http.rs:76-86` in `blvm-ui`). |
| Data folder | Both services mount `${APP_DATA_DIR}/data:/data`. `data/.gitkeep` is committed so the folder exists. Umbrel creates committed package folders owned by 1000:1000, which matches `user: "1000:1000"`. `storage: dataRoot: data` lets the user move the data folder (and the chain) to an external drive on umbrelOS 2.0; older versions ignore it. |
| Non-root writes | The image runs as UID 1000 (Ubuntu's built-in `ubuntu` user) and `HOME=/data`. Tested with a bind-mounted throwaway folder: `touch /data/x` works. Not tested against Umbrel's own ownership of `app-data/`. |
| Update flow | An Umbrel update copies only `docker-compose.yml`, `exports.sh`, top-level `*.template` and `hooks/` into the installed app, and `umbrel-app.yml` separately, then recreates the containers from the new pinned image. This file is not copied on update (harmless). The digest script is not in the app folder, so Umbrel does not copy it onto the device. Everything the app needs at run time is in `/data`, so an update never loses the node binary, the chain or `console.json`. The node program is independent of the app version: the console downloads new node releases itself. |
| Stop grace | umbreld's `stop` runs `docker compose rm --force --stop` with no `-t`, so each service's `stop_grace_period` applies. Umbrel's own Bitcoin Node uses `15m30s`, so long periods are accepted. The agent waits up to 200 s for the node to flush (30 s drain + 180 s watchdog, per the design), so the compose value is **240 s**, not 200 s: Docker must not SIGKILL the agent while it is still waiting. The web container needs 30 s. |
| Image pinning | Both services are pinned to `ghcr.io/btcdecoded/blvm-ui:0.2.3@sha256:cf77f454d5835846b57a7af9c95e9c34417143fed65c4db479f989790b8aa3a1`, the multi-arch index for tag `0.2.3` (`linux/amd64` + `linux/arm64`). The app version in `umbrel-app.yml` is separate from the image tag. `scripts/pin-digest.sh` in the store repository (not this app folder) writes the digest. It refuses a digest that is not `sha256:` plus 64 hex digits. With no argument it keeps the tag already in `docker-compose.yml`. `DIGEST` overrides the registry lookup. |
| `dependencies: []` | Correct. The node is a compose service of this app, not another Umbrel app, and the app does not use `implements: bitcoin` (it exports no `APP_BITCOIN_*` values and has no ZMQ or Tor), so no dependent app (Electrs, Mempool) can use it. |
| `exports.sh` | Only P2P ports and the RPC login (`derive_entropy` with `${app_entropy_identifier}`, stable across restarts and updates). The shared Docker network is treated as untrusted by Umbrel, so the RPC is password protected even though it is not published. The password reaches the node through its config file, not an environment variable: the agent writes `<data>/networks/<network>/blvm.toml` (mode 0600, `[rpc_auth] required = true`, `username`, `password` from `BLVM_RPC_USER` / `BLVM_RPC_PASS`) before every start and runs the node with `--config`; the console sends the same login (`BLVM_UI_RPC_USER` / `BLVM_UI_RPC_PASS`). Checked against the real `blvm` on regtest: a request with no login or a wrong one gets 401, the right one is answered. The agent also checks once after each start that the node really asks for the password and stops it if not. |
| Capabilities | No Docker socket, no privileged mode, no host network, no devices. |
| Lint | The official linter (`.tools/lint-apps.mjs` from `getumbrel/umbrel-apps`, run with `--root` pointing at this store; `npx @umbrel/app-store-lint` does not exist) reports **no issues** for the pinned compose file, also with `--check-images`. Run with the app copied into a clone of the official store, there is no `ports.unique` finding: since the mainnet port moved to 8334 no published port of this app is published by an official app. Community stores are not linted by Umbrel. |

## Needs a decision

1. ~~Port 8333 conflict.~~ Resolved: Mainnet is published on **8334** (the official Bitcoin Node holds 8333), so both apps can run at the same time. The other four ports are standard and no official app publishes them. Still open: inbound peers need the user's router to forward 8334 (Umbrel opens nothing on the router), and a port another community app might publish is not checked.
2. ~~Host header for IP and Tor access.~~ Resolved: the console accepts IP-address and `.onion` hosts once `BLVM_UI_ALLOWED_HOSTS` is set (the compose file sets it).
3. **Environment names the host must honour.** This compose file passes `BLVM_UI_NODE_HOST` (web: where the node RPC is),
   `BLVM_AGENT_RPC_BIND` (agent: bind RPC on 0.0.0.0), `BLVM_RPC_USER`/`BLVM_RPC_PASS` (agent) and
   `BLVM_UI_RPC_USER`/`BLVM_UI_RPC_PASS` (web), and `BLVM_UI_UPDATES=1`. They match what `blvm-ui` 0.2.3 reads (`src/settings.rs`, `src/agent_daemon.rs`).
   The five `BLVM_AGENT_P2P_PORT_<NET>` variables (both containers) are read by image `0.2.3` (`src/networks.rs` `p2p_env_name`, `src/agent.rs` `build_args`). Images older than the one after 0.2.2 ignore
   them and the node then listens on 8333, which this compose file does not publish. **Do not replace this pin with an image older than 0.2.3.**

## Not verified (needs a real Umbrel)

- Install, open through the proxy, restart, update from a previous version, data kept: not run (no umbrelOS available in this session).
- That umbrelOS 1.x accepts the unknown `storage` key with `manifestVersion: 1`.
- Firewall behaviour: Umbrel does not open ports on the user's router.
