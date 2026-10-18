# Surge Downloader Manager

A fast, native downloader for the Mac. Every file is fetched over up to 32 parallel connections; it
resumes after a quit or a crash, takes over downloads from your browser, and runs big ones on a schedule.

This repository holds the app (**Releases**) and its installer. The source is private.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/manu-tech-code/surge-releases/HEAD/scripts/install.sh | bash
```

Run the same command again to update.

It downloads the latest release with `curl`, checks that the app is signed by the developer's team,
copies it to `/Applications` (or `~/Applications`), and opens it. Because `curl` doesn't mark the file as
"downloaded from the internet", macOS doesn't block the first launch.

**Needs:** an Apple silicon Mac (M1 or later) on macOS 15 or later.

Options, as environment variables in front of `bash`:

```sh
curl -fsSL https://raw.githubusercontent.com/manu-tech-code/surge-releases/HEAD/scripts/install.sh | SURGE_INSTALL_DIR=~/Applications SURGE_NO_OPEN=1 bash
```

| Variable | Does |
|---|---|
| `SURGE_INSTALL_DIR=<folder>` | Install there instead of `/Applications` |
| `SURGE_NO_OPEN=1` | Don't open the app afterwards |

## Uninstall

```sh
rm -rf /Applications/Surge.app ~/Library/Application\ Support/Surge
defaults delete com.amalitech.Surge
```
