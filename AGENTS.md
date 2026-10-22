# Development

Target OpenWrt 25.12.5 and aarch64_generic unless a change explicitly adds another target.
Use the OpenWrt SDK to produce APKv3 packages. Do not use nFPM or an Alpine APKv2 packager.
Keep the upstream TorrServer tag, commit, Go build and package version consistent.
Use POSIX shell and BusyBox-compatible commands in router files; Bash is allowed in build scripts.
Keep rpcd as a lightweight executable shell backend. Use jshn for JSON encoding.
Keep credentials out of RPC status responses and diagnostic output.
Preserve the configured data directory and user configuration during upgrade and removal.
Use standard LuCI forms and Save & Apply. Configuration edits must not immediately execute service actions.
Before release, require a successful build and ARM64 OpenWrt smoke test. Clearly distinguish emulation from physical-router testing.
Update both README.md and README.ru.md for installation or behavior changes.
