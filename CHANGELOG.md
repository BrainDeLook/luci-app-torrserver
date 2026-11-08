# Changelog

## TorrServer 150-r1 / LuCI 3.0.0-r3

- Update official server and embedded web UI from MatriX.147 to MatriX.150 at commit `0c48c9ac78de2864f5fc9341e8caf89d355a4850`.
- Retain OpenWrt 25.12.5 / aarch64_generic, native APKv3, Go 1.25.7, nosqlite and the non-GStreamer build.
- Keep the verified API-first installer, configuration retention and authentication backups.
- Test upgrading published 147-r2 packages to 150-r1 with a custom port and password in ARM64 OpenWrt.
- Include upstream changes to torrent caching, subtitles, API/playlist handling and the PWA web interface; GStreamer-specific features remain excluded.

## Installer network fix for 147-r2

- Download through the official GitHub asset API first, avoiding an unreachable `github.com` frontend.
- Fall back to regular release URLs and show errors instead of silently exiting after a failed download.
- Add explicit download-source selection and download-only diagnostics.
- Test blocked-frontend/API fallback cases and real GitHub API downloads with OpenWrt uclient-fetch.
- Preserve the existing APK versions and record installer source provenance separately.

## TorrServer 147-r2 / LuCI 3.0.0-r2

- Publish a version-pinned one-command installer alongside native APKs.
- Validate firmware, architecture, package manager, free space, hashes and APKv3 headers before installation.
- Back up existing configuration and authentication into a root-only persistent directory.
- Support read-only preflight, local package directories and explicit reinstallation.
- Exercise installation, corrupted-package rejection, reinstallation and backup retention in ARM64 OpenWrt CI.
- Document one-command installation and the unsigned-package trust boundary in English and Russian.

## TorrServer 147-r1 / LuCI 3.0.0-r1

- Target OpenWrt 25.12.5 / aarch64_generic with SDK-built APKv3 packages.
- Pin official TorrServer MatriX.147 sources and record provenance.
- Replace duplicated inline packaging workflows with OpenWrt package definitions.
- Stop the daemon gracefully instead of passing `--dontkill`.
- Correct Telegram and FUSE arguments; validate stream-size units.
- Use standard LuCI forms and deferred Save & Apply behavior.
- Support authentication credentials with root-only configuration files.
- Retain configured data paths and UCI configuration across upgrades.
- Add ARM64 OpenWrt installation and runtime smoke checks.
- Document installation, migration, storage, proxy boundaries and test limitations in English and Russian.
