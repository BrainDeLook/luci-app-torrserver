# Changelog

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
