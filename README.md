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
| [BLVM UI](btc-commons-blvm-ui/) | Live console for the Bitcoin node on your Umbrel: sync, peers on a globe, new blocks, health, disk use, and peer controls. Needs the Bitcoin Node app (or another app that provides `bitcoin`). |

## Layout

```
umbrel-app-store.yml              store ID ("btc-commons") and name
btc-commons-<app>/                one folder per app; the folder name is the app ID
  umbrel-app.yml                  store listing: name, tagline, description, icon, gallery, port
  docker-compose.yml              containers Umbrel runs for the app
  data/.gitkeep                   persistent data folder, mounted from ${APP_DATA_DIR}/data
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

## Releasing a new version of BLVM UI

1. Tag the console: in `BTCDecoded/blvm-ui`, push a tag like `v0.1.1`. The **Docker image** workflow builds
   `linux/amd64` + `linux/arm64` and pushes `ghcr.io/btcdecoded/blvm-ui:0.1.1`. The run summary shows the digest.
2. In `btc-commons-blvm-ui/docker-compose.yml`, set `image: ghcr.io/btcdecoded/blvm-ui:0.1.1@sha256:<digest>`.
3. In `btc-commons-blvm-ui/umbrel-app.yml`, set `version: "0.1.1"` and write `releaseNotes`.
4. Commit and push. Umbrels that added the store will offer the update.

You can check the digest and both architectures with:

```bash
docker buildx imagetools inspect ghcr.io/btcdecoded/blvm-ui:0.1.1
```

## Testing on a device

After pushing, open the Community App Store in umbrelOS and refresh it. Over SSH you can also drive installs and
read logs:

```bash
ssh umbrel@umbrel.local
umbreld client apps.install.mutate --appId btc-commons-blvm-ui
umbreld client apps.logs.query --appId btc-commons-blvm-ui
```
