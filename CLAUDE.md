# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A [Chocolatey](https://chocolatey.org/) package that installs the prebuilt `gocore.exe` — the official Go client for the CORE blockchain ([core-coin/go-core](https://github.com/core-coin/go-core)) — on 64-bit Windows. This is a **packaging shell only**: no `gocore` source, no build system, no tests, no language toolchain. The `gocore` source lives in the separate `core-coin/go-core` repo, which is not checked out here.

> The parent workspace `../CLAUDE.md` describes an older "embed the binary + commit the `.nupkg`" flow. That is **out of date** — this repo no longer commits `tools/gocore.exe` or any `go-core.*.nupkg`. The current flow is download-based (see below). Trust this file for the gocore-chocolatey specifics.

## How install actually works (download-based)

`tools/chocolateyinstall.ps1` runs on the end user's machine at `choco install` time. It does **not** ship the binary inside the package. Instead it calls `Get-ChocolateyWebFile` to download `gocore-windows-x86_64.exe` from the matching GitHub release and verifies its SHA-256 against a checksum hardcoded in the script. Chocolatey auto-generates a shim so `gocore` is on PATH. 32-bit Windows is rejected up front.

The three values that must stay in sync for a given release:
- `<version>` in `go-core.nuspec`
- the `vX.Y.Z` in the `Url64bit` download URL in `chocolateyinstall.ps1`
- `Checksum64` in `chocolateyinstall.ps1` — must equal the upstream `gocore-windows-x86_64.exe.checksum`

`tools/VERIFICATION.txt` documents this verification path for Chocolatey moderators and must be updated to point at the same release URL + checksum.

## Updating to a new gocore release

1. In `go-core.nuspec`: bump `<version>` and refresh `<releaseNotes>`.
2. In `tools/chocolateyinstall.ps1`: bump the version in `Url64bit` and set `Checksum64` to the new release's published `.checksum` value.
3. In `tools/VERIFICATION.txt`: update the URL and checksum to match.
4. Tag the commit `vX.Y.Z` and push the tag — CI publishes (see below). Do not run `choco push` by hand unless CI is unavailable.

There is no Linux way to *test* the actual install (`Get-ChocolateyWebFile` is Windows/`choco`-only), but all the edits above are plain text and can be made anywhere. Always confirm `Checksum64` against the real upstream `.checksum` before tagging — a mismatch makes every user's install fail.

## CI / release

- `.github/workflows/build.yml` — on push to `master` and on PRs: runs `choco pack` on `windows-latest` and uploads the `.nupkg` as a build artifact (does not publish).
- `.github/workflows/release.yml` — on pushing a `v*` tag: `choco pack` then `choco push` to https://push.chocolatey.org/ using the `CHOCO_API_KEY` secret. **Pushing a `v*` tag is what publishes to the Chocolatey community repo.**

## Constraints

- `<dependencies>` in the nuspec requires `mingw` (`11.2.0.07112021`, i.e. that version or higher — a bare version is a minimum, brackets would mean an exact pin) — a runtime dependency Chocolatey installs alongside gocore. Don't drop it without a reason; gocore links against it. Keep the leading zero: the actual published mingw version in the Chocolatey feed is `11.2.0.07112021` (verify via `curl "https://community.chocolatey.org/api/v2/FindPackagesById()?id='mingw'"`). Moderation tooling may *display* it normalized as `11.2.0.7112021`, but that form is not the canonical version and its package page URL 404s — match the feed's `07112021`.
- Do not commit `tools/gocore.exe` or `go-core.*.nupkg` — the package is download-based and the artifact is built by CI. Committing them reintroduces the stale embed-the-binary model.
- `go-core.nuspec` line 2 has an intentional UTF-8 sentinel comment — keep the file UTF-8 encoded.
