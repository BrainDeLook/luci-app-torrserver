# Changelog

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
