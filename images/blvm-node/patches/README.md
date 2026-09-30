# Store-only patches

Applied by `fetch-sources.sh` on top of the pinned upstream commits, one folder per repo: `patches/<repo>/<topic>.patch`.
Drop a patch once the fix is in the upstream commit pinned in `sources.txt`.

| Patch | Why |
|---|---|
| `blvm-node/arm64-c_char.patch` | `blvm-node` declares jemalloc's `mallctl` with `name: *const i8`. On aarch64 Linux `c_char` is `u8`, so `c"…".as_ptr()` does not type-check and the node does not build for Raspberry Pi / ARM. Uses `c_char`, which is `i8` on x86_64, so nothing changes there. |
