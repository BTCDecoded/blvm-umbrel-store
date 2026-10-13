# Umbrel constraints check for Commons Node View

Checked 2026-10-13 against the official guidance in `getumbrel/umbrel-apps` (`.agents/skills/umbrel-package-app` and
`umbrel-test-app`, the `bitcoin` package as the reference for ports and exports) and the umbreld source in
`getumbrel/umbrel` (`apps/legacy-compat/app-script`, `app-environment.ts`, `app-gateway/app-gateway.ts`).
"Verified" means read in those sources or run; "not verified" means it needs a real Umbrel.

This file is copied onto every Umbrel that installs the app (everything in an app folder is). It is documentation only.

## Verified

| Topic | Result |
|---|---|
| Ports | Manifest `port: 3849` is the app_proxy port and is unique across the official store (the Umbrel linter's `ports.unique` check passes for it). The container also listens on 3849 (`APP_PORT: 3849`); the two numbers are independent. The web page is not published with `ports:`. Only the agent publishes ports: the five P2P ports. The RPC ports are not published. |
| `app_proxy` | Environment only, `APP_HOST: btc-commons-node-view_web_1` (`<app-id>_<service>_1`), `APP_PORT: 3849`. Umbrel login stays on (default). umbrelOS 2.0 serves the same port over HTTPS too, so the console is reached over http or https. |
| Host header | The gateway proxies with `changeOrigin: false`, so the console sees the **original** `Host` the browser typed (`umbrel.local:3849`, an IP address, a `.onion` name, a Tailscale name). `BLVM_UI_ALLOWED_HOSTS` lists `APP_DOMAIN`, `DEVICE_DOMAIN_NAME`, `DEVICE_HOSTNAME` and the web container name. Note the variable is `DEVICE_DOMAIN_NAME`; `DEVICE_DOMAIN` does not exist in Umbrel. IP-address and `.onion` hosts are accepted once `BLVM_UI_ALLOWED_HOSTS` lists a name (`src/http.rs:76-86` in `blvm-ui`). |
| Data folder | Both services mount `${APP_DATA_DIR}/data:/data`. `data/.gitkeep` is committed so the folder exists. Umbrel creates committed package folders owned by 1000:1000, which matches `user: "1000:1000"`. `storage: dataRoot: data` lets the user move the data folder (and the chain) to an external drive on umbrelOS 2.0; older versions ignore it. |
| Non-root writes | The image runs as UID 1000 (Ubuntu's built-in `ubuntu` user) and `HOME=/data`. Tested with a bind-mounted throwaway folder: `touch /data/x` works. Not tested against Umbrel's own ownership of `app-data/`. |
| Update flow | An Umbrel update copies only `docker-compose.yml`, `exports.sh`, top-level `*.template` and `hooks/` into the installed app, and `umbrel-app.yml` separately, then recreates the containers from the new pinned image. `scripts/` and this file are not copied on update (harmless). Everything the app needs at run time is in `/data`, so an update never loses the node binary, the chain or `console.json`. The node program is independent of the Umbrel version: the console downloads new node releases itself, so Umbrel's "version" only says which console image is installed. |
| Stop grace | umbreld's `stop` runs `docker compose rm --force --stop` with no `-t`, so each service's `stop_grace_period` applies. Umbrel's own Bitcoin Node uses `15m30s`, so long periods are accepted. The agent waits up to 200 s for the node to flush (30 s drain + 180 s watchdog, per the design), so the compose value is **240 s**, not 200 s: Docker must not SIGKILL the agent while it is still waiting. The web container needs 30 s. |
| Image pinning | The linter requires `tag@sha256:<multi-arch index digest>` on every image and `linux/amd64` + `linux/arm64`. The image does not exist until `BTCDecoded/blvm-ui` publishes `0.2.0`, so `docker-compose.yml` carries the tag only plus a comment; `scripts/pin-digest.sh` writes the digest into both services (the `DIGEST` environment variable overrides the lookup, which is how it was tested here). **Until it is run, the linter reports `image.pinned` twice and the store must not be merged.** |
| `dependencies: []` | Correct. The node is a compose service of this app, not another Umbrel app, and the app does not use `implements: bitcoin` (it exports no `APP_BITCOIN_*` values and has no ZMQ or Tor), so no dependent app (Electrs, Mempool) can use it. |
| `exports.sh` | Only P2P ports and the RPC login (`derive_entropy` with `${app_entropy_identifier}`, stable across restarts and updates). The shared Docker network is treated as untrusted by Umbrel, so the RPC is password protected even though it is not published. The password reaches the node through its config file, not an environment variable: the agent writes `<data>/networks/<network>/blvm.toml` (mode 0600, `[rpc_auth] required = true`, `username`, `password` from `BLVM_RPC_USER` / `BLVM_RPC_PASS`) before every start and runs the node with `--config`; the console sends the same login (`BLVM_UI_RPC_USER` / `BLVM_UI_RPC_PASS`). Checked against the real `blvm` on regtest: a request with no login or a wrong one gets 401, the right one is answered. The agent also checks once after each start that the node really asks for the password and stops it if not. |
| Capabilities | No Docker socket, no privileged mode, no host network, no devices. |
| Lint | The official linter (`.tools/lint-apps.mjs` from `getumbrel/umbrel-apps`, run with `--root` pointing at this store; `npx @umbrel/app-store-lint` does not exist) reports, with a placeholder digest: **one error, `ports.unique`: the agent publishes host port 8333, which the official Bitcoin Node also publishes.** Without the placeholder digest it reports the two `image.pinned` errors above. Manifest shape, `storage`, app_proxy wiring, persistence paths and `exports.sh` pass. `--check-images` was not run (the image is not published). This only matters on a device that has both apps; community stores are not linted by Umbrel. |

## Needs a decision

1. **Port 8333 conflict.** The official Bitcoin Node publishes 8333. If it is running, this app's agent cannot start at
   all (it publishes all five P2P ports, so even a Signet user is blocked) until it is stopped (Docker refuses to bind twice). The same would apply to any other app using 18333, 48333, 38333 or
   18444. Options: keep the standard ports (current, documented in the description), or publish mainnet on another host
   port (inbound peers then need a router rule to that port and the node would still advertise 8333).
2. ~~Host header for IP and Tor access.~~ Resolved: the console accepts IP-address and `.onion` hosts once `BLVM_UI_ALLOWED_HOSTS` is set (the compose file sets it).
3. **Environment names the host must honour.** This compose file passes `BLVM_UI_NODE_HOST` (web: where the node RPC is),
   `BLVM_AGENT_RPC_BIND` (agent: bind RPC on 0.0.0.0), `BLVM_RPC_USER`/`BLVM_RPC_PASS` (agent) and
   `BLVM_UI_RPC_USER`/`BLVM_UI_RPC_PASS` (web), and `BLVM_UI_UPDATES=1`. They match what `blvm-ui` 0.2.0 reads (`src/settings.rs`, `src/agent_daemon.rs`).

## Not verified (needs a real Umbrel)

- Install, open through the proxy, restart, update from a previous version, data kept: not run (no umbrelOS available in this session).
- That umbrelOS 1.x accepts the unknown `storage` key with `manifestVersion: 1`.
- Firewall behaviour: Umbrel does not open ports on the user's router.
