# Bitcoin Commons App Store for Umbrel

A community app store for [umbrelOS](https://umbrel.com) with apps from [Bitcoin Commons](https://thebitcoincommons.org).

## Add it to your Umbrel

1. Open the **App Store** in umbrelOS.
2. Click **⋯** (top right) → **Community App Stores**.
3. Paste `https://github.com/BTCDecoded/commons-umbrel-store` and click **Add**.
4. Open **Bitcoin Commons App Store** and install **Commons Node View**.

## Apps

| App | What it is |
|---|---|
| [Commons Node View](btc-commons-node-view/) | A Bitcoin full node (BLVM) and its console in one app. A guided setup lets you pick a network, downloads the official Bitcoin Commons node release, starts it, and shows sync, peers on a globe, new blocks, logs and settings. Switch networks any time with each network's data kept. It never touches your wallet or funds. |

## How Commons Node View works

One app, two containers started from the same image (`ghcr.io/btcdecoded/blvm-ui`), sharing one data folder:

```
Umbrel app  btc-commons-node-view
├─ web    the console (setup walkthrough, status, settings, logs)         port 3849 behind Umbrel's login
└─ agent  runs the node: starts, stops, switches networks                publishes the five P2P ports
        shared:  ${APP_DATA_DIR}/data  ->  /data
```

- The **node program is not in the image.** When you pick a network in the setup, the console (the web container)
  downloads the official `blvm` release for your CPU (Linux x86_64 or aarch64) from `github.com/BTCDecoded/blvm`, checks
  it against the release's published `checksums.sha256` (releases are not signed yet), and installs it under
  `/data/bin`; the agent then runs it. New releases are installed the same way, when you
  click, so Umbrel's app version and the node version are independent.
- **Everything that must survive** (your choices, each network's chain data and logs, node binaries, modules) lives in
  `/data`, which is Umbrel's app data folder. App updates and restarts replace the containers, never the data.
- The web container can restart or update without stopping the node, and the node can crash without taking the console
  down. Stopping the app stops the agent, which asks the node to finish saving first (up to 4 minutes).
- Only the P2P ports are open to the network (8334 mainnet, 18333 testnet3, 48333 testnet4, 38333 signet, 18444 regtest),
  because Umbrel fixes ports in `docker-compose.yml` and the network is chosen later in the app. The agent passes each
  port to the node (`BLVM_AGENT_P2P_PORT_<NET>`, set in the compose file from `exports.sh`), so the node listens on the
  port that is published. The node's RPC port is
  not published, and it answers only with a password derived from your Umbrel's seed: the agent writes it into the
  node's own config file before every start, and the console sends the same password.
- The node runs **inside the agent container**. Restarting that container (or stopping the app) restarts the node, and
  a node that was already running is only taken over again when the agent process restarts inside a running container.
  If you stop the node in the app, it stays stopped after an app restart, an app update or a reboot.
- Mainnet is on **8334**, not 8333, because Umbrel's own Bitcoin Node publishes 8333; both apps can run at the same time.
  No app of Umbrel's official store publishes any of the five ports (checked 2026-10-13). If another app you installed
  from somewhere else already uses one of them, this app cannot start until you stop that app, whichever network you
  pick (Docker refuses to bind a port twice).

Source of the image: [`BTCDecoded/blvm-ui`](https://github.com/BTCDecoded/blvm-ui) (`Dockerfile`, one multi-arch build).
More notes on what was checked against Umbrel's rules: [`btc-commons-node-view/NOTES.md`](btc-commons-node-view/NOTES.md).

## Previous apps

This store used to list **Commons UI** (`btc-commons-blvm-ui`, a console for another node) and **BLVM Node**
(`btc-commons-blvm-node`, testnet3 only, built from source in this repository). Both were replaced by Commons Node View
and removed from the store. Their files, the node image build and its workflow are in this repository's git history.
**If you have Commons UI installed, uninstall it before you install Commons Node View:** both use port 3849. An Umbrel
that has BLVM Node keeps it running, but it receives no updates and its data does not carry over to the new app (a
different app ID means a different data folder).

## Running the image without Umbrel

The 0.2.3 console checks the `Host` header of every request. The old Commons UI 0.1.1 did not, so a compose file written
for it answers 403 on every request until `BLVM_UI_ALLOWED_HOSTS` lists the names you use to open it. Umbrel users are
not affected: the old apps stay pinned to 0.1.1. The current pin is `ghcr.io/btcdecoded/blvm-ui:0.2.3@sha256:cf77f454d5835846b57a7af9c95e9c34417143fed65c4db479f989790b8aa3a1`.

## Layout

```
umbrel-app-store.yml              store ID ("btc-commons") and name
btc-commons-<app>/                one folder per app; the folder name is the app ID
  umbrel-app.yml                  store listing: name, tagline, description, icon, gallery, port
  docker-compose.yml              containers Umbrel runs for the app
  exports.sh                      values Umbrel computes for the app (ports, derived RPC password)
  data/.gitkeep                   persistent data folder, mounted from ${APP_DATA_DIR}/data
scripts/pin-digest.sh             fills in the image digest after a release (not inside the app folder)
assets/btc-commons-<app>/         icon and gallery images (linked from umbrel-app.yml)
```

Everything under an app folder is copied onto every Umbrel that installs it, which is why images live in
`assets/` and `scripts/pin-digest.sh` lives next to this README.

## Editing a listing

All user-facing text and images are in the app's `umbrel-app.yml`:

- `name`, `tagline`, `description`, `releaseNotes`: text. `description` and `releaseNotes` use `>-`, so single line
  breaks are joined. Leave **two** blank lines for a new paragraph, and a blank line before and between list items.
- `icon`: square SVG (or PNG), 256×256, square corners. Umbrel rounds them.
- `gallery`: 3–5 screenshots, 1440×900 JPG or PNG, in the order shown.
- `version`: the app version Umbrel compares when it offers an update. Bump it for a new image and for a manifest-only change, and fill in `releaseNotes`. The image tag in `docker-compose.yml` stays on the console release that was actually published.

Images are linked with `raw.githubusercontent.com` URLs, so this repository must be **public** for them (and the
store itself) to load.

## Releasing a new version of Commons Node View

1. Tag the console: in `BTCDecoded/blvm-ui`, push a tag like `v0.2.3`. The **Docker image** workflow builds
   `linux/amd64` + `linux/arm64` and pushes `ghcr.io/btcdecoded/blvm-ui:0.2.3`. The run summary shows the digest.
2. In this repository, run `scripts/pin-digest.sh 0.2.3`. It sets both
   services to `image: ghcr.io/btcdecoded/blvm-ui:<tag>@sha256:<digest>` (the multi-arch index digest) and exits
   if that digest is not `sha256:` plus 64 hex digits. With no argument it keeps the tag already in
   `docker-compose.yml`.
3. In `btc-commons-node-view/umbrel-app.yml`, set `version` and write `releaseNotes`. `version` is the app
   version. It can move without a new image tag.
4. Commit and push. Umbrels that added the store will offer the update.

You can check the digest and both architectures by hand with:

```bash
docker buildx imagetools inspect ghcr.io/btcdecoded/blvm-ui:0.2.3
```

A new BLVM node release does **not** need a store release: the app downloads it when you ask.

## Testing on a device

After pushing, open the Community App Store in umbrelOS and refresh it. Over SSH you can also drive installs and
read logs:

```bash
ssh umbrel@umbrel.local
sudo umbreld client apps.install.mutate --appId btc-commons-node-view
sudo umbreld client apps.logs.query --appId btc-commons-node-view
```
