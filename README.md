# Bitcoin Commons App Store for Umbrel

A community app store for [umbrelOS](https://umbrel.com) with apps from [Bitcoin Commons](https://thebitcoincommons.org).

## Add it to your Umbrel

1. Open the **App Store** in umbrelOS.
2. Click **⋯** (top right) → **Community App Stores**.
3. Paste `https://github.com/BTCDecoded/blvm-umbrel-store` and click **Add**.
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
└─ agent  runs the node: downloads, starts, stops, switches networks      publishes the five P2P ports
        shared:  ${APP_DATA_DIR}/data  ->  /data
```

- The **node program is not in the image.** When you pick a network in the setup, the console asks the agent to download
  the official `blvm` release for your CPU (Linux x86_64 or aarch64) from `github.com/BTCDecoded/blvm`, checks it against
  the release's `checksums.sha256`, and installs it under `/data/bin`. New releases are installed the same way, when you
  click, so Umbrel's app version and the node version are independent.
- **Everything that must survive** (your choices, each network's chain data and logs, node binaries, modules) lives in
  `/data`, which is Umbrel's app data folder. App updates and restarts replace the containers, never the data.
- The web container can restart or update without stopping the node, and the node can crash without taking the console
  down. Stopping the app stops the agent, which asks the node to finish saving first (up to 4 minutes).
- Only the P2P ports are open to the network (8333 mainnet, 18333 testnet3, 48333 testnet4, 38333 signet, 18444 regtest),
  because Umbrel fixes ports in `docker-compose.yml` and the network is chosen later in the app. The node's RPC port is
  not published; only the console reaches it, with a password derived from your Umbrel's seed.
- If another app already uses one of those ports (Umbrel's Bitcoin Node uses 8333), stop it before starting this app.

Source of the image: [`BTCDecoded/blvm-ui`](https://github.com/BTCDecoded/blvm-ui) (`Dockerfile`, one multi-arch build).
More notes on what was checked against Umbrel's rules: [`btc-commons-node-view/NOTES.md`](btc-commons-node-view/NOTES.md).

## Previous apps

This store used to list **Commons UI** (`btc-commons-blvm-ui`, a console for another node) and **BLVM Node**
(`btc-commons-blvm-node`, testnet3 only, built from source in this repository). Both were replaced by Commons Node View
and removed from the store. Their files, the node image build and its workflow are in this repository's git history.
An Umbrel that already has either app keeps it running, but it receives no updates and its data does not carry over to
the new app (a different app ID means a different data folder).

## Layout

```
umbrel-app-store.yml              store ID ("btc-commons") and name
btc-commons-<app>/                one folder per app; the folder name is the app ID
  umbrel-app.yml                  store listing: name, tagline, description, icon, gallery, port
  docker-compose.yml              containers Umbrel runs for the app
  exports.sh                      values Umbrel computes for the app (ports, derived RPC password)
  data/.gitkeep                   persistent data folder, mounted from ${APP_DATA_DIR}/data
  scripts/pin-digest.sh           fills in the image digest after a release
assets/btc-commons-<app>/         icon and gallery images (linked from umbrel-app.yml)
```

Everything under an app folder is copied onto every Umbrel that installs it, which is why images live in
`assets/` instead.

## Editing a listing

All user-facing text and images are in the app's `umbrel-app.yml`:

- `name`, `tagline`, `description`, `releaseNotes`: text. `description` and `releaseNotes` use `>-`, so single line
  breaks are joined. Leave **two** blank lines for a new paragraph, and a blank line before and between list items.
- `icon`: square SVG (or PNG), 256×256, square corners. Umbrel rounds them.
- `gallery`: 3–5 screenshots, 1440×900 JPG or PNG, in the order shown.
- `version`: bump it together with the image tag in `docker-compose.yml`, and fill in `releaseNotes`.

Images are linked with `raw.githubusercontent.com` URLs, so this repository must be **public** for them (and the
store itself) to load.

## Releasing a new version of Commons Node View

1. Tag the console: in `BTCDecoded/blvm-ui`, push a tag like `v0.2.0`. The **Docker image** workflow builds
   `linux/amd64` + `linux/arm64` and pushes `ghcr.io/btcdecoded/blvm-ui:0.2.0`. The run summary shows the digest.
2. In this repository, run `btc-commons-node-view/scripts/pin-digest.sh` (or `pin-digest.sh 0.2.1`). It sets both
   services to `image: ghcr.io/btcdecoded/blvm-ui:<version>@sha256:<digest>` (the multi-arch index digest).
3. In `btc-commons-node-view/umbrel-app.yml`, set `version` to match and write `releaseNotes`.
4. Commit and push. Umbrels that added the store will offer the update.

You can check the digest and both architectures by hand with:

```bash
docker buildx imagetools inspect ghcr.io/btcdecoded/blvm-ui:0.2.0
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
