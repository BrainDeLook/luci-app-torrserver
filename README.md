# TorrServer for OpenWrt

Native OpenWrt packages for **TorrServer MatriX.147**, with a LuCI management page.

[Русская документация](README.ru.md) · [Downloads](https://github.com/BrainDeLook/luci-app-torrserver/releases) · [Build checks](https://github.com/BrainDeLook/luci-app-torrserver/actions)

This is a maintained fork of [Medvedolog/luci-app-torrserver](https://github.com/Medvedolog/luci-app-torrserver). The server is built from the official [YouROK/TorrServer](https://github.com/YouROK/TorrServer) sources. It runs directly on OpenWrt: no Docker or Entware is required on the router.

## Supported platform

| Component | Version / target |
| --- | --- |
| OpenWrt | 25.12.5, APK package manager |
| Architecture | `aarch64_generic` / Linux ARM64 |
| Server | MatriX.147, pinned upstream commit `a86d8fa7fd4e07605f240fe69bf299392f7cb023` |
| LuCI | 3.0.0 |
| Package format | APKv3, built by the OpenWrt SDK |

Other architectures and older OpenWrt releases are not currently built. An ARM64 CPU alone does not guarantee that the package architecture matches your firmware.

## Packages

- `torrserver`: static ARM64 server, procd service, UCI configuration and CA certificate dependency.
- `luci-app-torrserver`: LuCI settings, service controls, version, memory use and system log. Installs the server as a dependency.

Settings use standard LuCI Save / Save & Apply / Reset behavior. Changing a checkbox does not immediately modify the running service. Authentication credentials can be configured in LuCI. The server shuts down through SIGTERM; the incompatible `--dontkill` option is not used.

## Install

Check the firmware first:

```sh
cat /etc/openwrt_release
```

Download both APKs from the same release and upload them to `/tmp` on the router. Verify their SHA256 checksums against the release's `SHA256SUMS`. Install the downloaded local files:

```sh
apk update
apk add --allow-untrusted /tmp/torrserver-147-r1.apk /tmp/luci-app-torrserver-3.0.0-r1.apk
```

The release lists the exact filenames. `--allow-untrusted` is required for these standalone packages; a signed package feed is not provided. Standard dependencies come from your configured OpenWrt feeds.

Open **Services → TorrServer** in LuCI. TorrServer's own web interface is available at `http://ROUTER-IP:8090`. Authentication is initially off. No WAN firewall rules are created. Configure a bind address and authentication as appropriate for your network.

The default data directory is `/opt/torrserver`. Ensure enough free storage for the binary, package installation and your chosen cache. Cache configuration belongs to TorrServer's own web interface; the maximum stream size field is in bytes and is not a RAM cache limit. High bitrate streams may need substantially more RAM and CPU than basic router workloads.

The upstream web UI is included. This self-build does not embed the upstream maintainer's private TMDB API key; enter your own key in TorrServer's settings if you use TMDB lookups.

## Upgrade and migrate

Back up `/etc/config/torrserver` and the configured data directory before migration. Install both new packages together. The UCI file is marked as a configuration file and is preserved on upgrade; the service keeps the configured data path. Existing databases are not deleted by the package.

For users of the original fork:

- Keep the existing `path`, port and proxy settings.
- The old `dontkill` option is ignored so procd can stop the process normally.
- Legacy `tg` and `fuse` UCI options map to upstream `-T` and `-f`.
- An existing `accs.db` can still be used if no new credentials are configured. Fill both authentication fields in LuCI to manage credentials there.
- `torrserver-upx` and `torrserver-official` are not provided. Remove an old alternative daemon package before installing `torrserver`, preserving its data first.
- A previous APKv2 package may not be accepted by your APKv3 package manager. Do not force an incompatible package database conversion.

New credentials replace `accs.db` with the configured single user. Credentials are stored as plaintext in root-readable files, not password hashes; `/etc/config/torrserver` and `accs.db` are restricted to mode `0600`. Disabling authentication keeps the credential file for later use.

## Diagnostics

```sh
/etc/init.d/torrserver status
ubus call luci.torrserver status
logread -e torrserver
/usr/bin/torrserver --version
```

Stopping the server manually does not disable startup. To keep it stopped after reboot or settings reload:

```sh
uci set torrserver.main.enabled='0'
uci commit torrserver
/etc/init.d/torrserver restart
```

Uninstall with `apk del luci-app-torrserver torrserver`. The data directory is retained; back it up before any manual removal. Keeping data on external storage requires that storage to be mounted before the service starts.

## Build and verification

GitHub Actions builds the upstream web UI and static ARM64 Go binary using `CGO_ENABLED=0`, packages both components with the pinned OpenWrt 25.12.5 SDK, and tests the packages in an emulated ARM64 OpenWrt container. No UPX compression or GStreamer variant is used.

The smoke test covers installation, version, HTTP API and web UI, rpcd registration, stopping, authentication, reinstallation with retained configuration, disabling and removal. The container test does not establish real router streaming performance, external-storage startup behavior, or VPN compatibility.

Each successful artifact includes `BUILDINFO.txt`, the upstream GPL license, SHA256 checksums and a smoke-test report. Failed checks do not automatically publish a release. Build artifacts are available from Actions; releases are published after reviewing a successful run.

Maintainers can run **Publish verified release** with the successful build run ID. It accepts only successful builds of this repository's `main`, checks hashes and the smoke-test result, verifies APKv3 headers, and publishes the exact tested commit. The first release defaults to prerelease status pending physical-router testing.

For a local Linux build, install Go as specified in upstream `server/go.mod`, Node.js 20, Yarn 1.22.22 and the OpenWrt SDK prerequisites. Clone the pinned upstream commit into `.build/upstream`, then run:

```sh
bash scripts/build-upstream.sh .build/upstream .build
bash scripts/build-packages.sh /absolute/path/to/openwrt-sdk .build/torrserver
```

This repository packages TorrServer; it does not maintain a divergent server implementation. TorrServer is GPL-3.0 licensed. The original LuCI repository did not include a standalone license file at the fork point; its authorship and repository history are retained.
