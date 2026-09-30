# Bitcoin Commons App Store for Umbrel

A community app store for [umbrelOS](https://umbrel.com) with apps from [Bitcoin Commons](https://thebitcoincommons.org).

## Add it to your Umbrel

1. Open the **App Store** in umbrelOS.
2. Click **⋯** (top right) → **Community App Stores**.
3. Paste `https://github.com/BTCDecoded/blvm-umbrel-store` and click **Add**.
4. Open **Bitcoin Commons App Store** and install an app.

## Apps

| App | What it is |
|---|---|
| [BLVM Node](btc-commons-blvm-node/) | The BLVM full node on testnet3, built from the latest BTCDecoded source, with Commons UI as its page. Can stand in for Bitcoin Node (`implements: bitcoin`, RPC and P2P only). |
| [Commons UI](btc-commons-blvm-ui/) | Live console for the Bitcoin node on your Umbrel: sync, peers on a globe, new blocks, health, disk use, and peer controls. Works with Bitcoin Node, Knots, or BLVM Node. |

## Layout

```
umbrel-app-store.yml              store ID ("btc-commons") and name
btc-commons-<app>/                one folder per app; the folder name is the app ID
  umbrel-app.yml                  store listing: name, tagline, description, icon, gallery, port
  docker-compose.yml              containers Umbrel runs for the app
  data/.gitkeep                   persistent data folder, mounted from ${APP_DATA_DIR}/data
assets/btc-commons-<app>/         icon and gallery images (linked from umbrel-app.yml)
images/blvm-node/                 how the BLVM Node image is built (see below)
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

## Releasing a new version of Commons UI

1. Tag the console: in `BTCDecoded/blvm-ui`, push a tag like `v0.1.1`. The **Docker image** workflow builds
   `linux/amd64` + `linux/arm64` and pushes `ghcr.io/btcdecoded/blvm-ui:0.1.1`. The run summary shows the digest.
2. In `btc-commons-blvm-ui/docker-compose.yml`, set `image: ghcr.io/btcdecoded/blvm-ui:0.1.1@sha256:<digest>`.
3. In `btc-commons-blvm-ui/umbrel-app.yml`, set `version: "0.1.1"` and write `releaseNotes`.
4. Commit and push. Umbrels that added the store will offer the update.

You can check the digest and both architectures with:

```bash
docker buildx imagetools inspect ghcr.io/btcdecoded/blvm-ui:0.1.1
```

## Building the BLVM Node image

The node image is built here, not in the BLVM repos. `images/blvm-node/sources.txt` pins one commit per
BTCDecoded repo (`blvm`, `blvm-node`, `blvm-consensus`, …); `fetch-sources.sh` checks them out into
`images/blvm-node/src/` and applies any store-only fixes from `images/blvm-node/patches/<repo>/`.

The **BLVM Node image** workflow runs on every push that touches `images/blvm-node/`. It builds amd64 and arm64
natively on separate runners and pushes `ghcr.io/btcdecoded/blvm-umbrel-node:main-<blvm commit>`. The run summary
prints the image and digest to paste into `btc-commons-blvm-node/docker-compose.yml`.

To update the node: change the commits in `sources.txt` (`git ls-remote https://github.com/BTCDecoded/<repo>
refs/heads/main`), push, wait for the workflow, then pin the new digest and bump `version` in the app's
`umbrel-app.yml`.

Local build (Docker or OrbStack):

```bash
cd images/blvm-node && ./fetch-sources.sh && docker build -t blvm-umbrel-node:local .
```

## Testing on a device

After pushing, open the Community App Store in umbrelOS and refresh it. Over SSH you can also drive installs and
read logs:

```bash
ssh umbrel@umbrel.local
umbreld client apps.install.mutate --appId btc-commons-blvm-ui
umbreld client apps.logs.query --appId btc-commons-blvm-ui
```
