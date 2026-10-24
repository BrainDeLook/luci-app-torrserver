#!/bin/sh
set -eu

RELEASE_TAG=v147-r2
SERVER_PACKAGE=torrserver-147-r2.apk
LUCI_PACKAGE=luci-app-torrserver-3.0.0-r2.apk
BASE_URL="https://github.com/BrainDeLook/luci-app-torrserver/releases/download/$RELEASE_TAG"
API_URL=https://api.github.com/repos/BrainDeLook/luci-app-torrserver
source_dir=''
download_source=auto
api_attempted=0
api_ready=0
check_only=0
download_only=0
reinstall=0

fail() {
	printf 'ERROR: %s\n' "$1" >&2
	exit 1
}

usage() {
	printf '%s\n' 'TorrServer installer for OpenWrt 25.12.5 / aarch64_generic' \
		'Usage: sh install.sh [--check] [--download-only] [--reinstall] [--from-dir DIRECTORY] [--download-source auto|api|github]' \
		'--check: validate compatibility and free space without changing the router' \
		'--download-only: download and verify packages without installing them' \
		'--reinstall: reinstall the same package versions, retaining configuration' \
		'--from-dir: use downloaded APKs and SHA256SUMS; dependencies still use OpenWrt feeds' \
		'--download-source: auto tries the official GitHub API first, then github.com'
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		--help|-h) usage; exit 0 ;;
		--check) check_only=1 ;;
		--download-only) download_only=1 ;;
		--reinstall) reinstall=1 ;;
		--download-source)
			[ "$#" -ge 2 ] || fail '--download-source requires auto, api or github'
			case "$2" in auto|api|github) download_source="$2" ;; *) fail 'Invalid download source' ;; esac
			shift ;;
		--from-dir)
			[ "$#" -ge 2 ] || fail '--from-dir requires a directory'
			source_dir="$2"
			[ -d "$source_dir" ] || fail 'Package directory does not exist'
			source_dir="$(cd "$source_dir" && pwd)"
			shift ;;
		*) fail "Unknown option: $1" ;;
	esac
	shift
done

[ "$(id -u)" -eq 0 ] || fail 'Run this installer as root'
[ -r /etc/openwrt_release ] || fail 'This system is not OpenWrt'
. /etc/openwrt_release
[ "${DISTRIB_RELEASE:-}" = 25.12.5 ] || fail 'Only OpenWrt 25.12.5 is supported'
[ "${DISTRIB_ARCH:-}" = aarch64_generic ] || fail 'Only aarch64_generic is supported'
for utility in apk sha256sum mktemp awk df uci; do
	command -v "$utility" >/dev/null 2>&1 || fail "Missing utility: $utility"
done
for incompatible in torrserver-upx torrserver-official; do
	if apk info -e "$incompatible" >/dev/null 2>&1; then
		fail "Back up your data and remove $incompatible before installing"
	fi
done
tmp_free="$(df -Pk /tmp | awk 'END {print $4}')"
root_free="$(df -Pk /usr/bin | awk 'END {print $4}')"
[ "$tmp_free" -ge 65536 ] || fail 'At least 64 MiB free in /tmp is required'
[ "$root_free" -ge 98304 ] || fail 'At least 96 MiB free on the system filesystem is required'
printf 'Compatible: OpenWrt %s / %s; release %s\n' "$DISTRIB_RELEASE" "$DISTRIB_ARCH" "$RELEASE_TAG"
[ "$check_only" -eq 0 ] || exit 0

download() {
	local url="$1" output="$2" accept="$3"
	rm -f "$output"
	if command -v uclient-fetch >/dev/null 2>&1; then
		uclient-fetch -T 30 --header="Accept: $accept" -O "$output" "$url"
	elif command -v wget >/dev/null 2>&1; then
		wget -T 30 --header="Accept: $accept" -O "$output" "$url"
	elif command -v curl >/dev/null 2>&1; then
		curl -fLsS --connect-timeout 20 --max-time 300 -H "Accept: $accept" "$url" -o "$output"
	else
		fail 'Install uclient-fetch, wget or curl with HTTPS support'
	fi
}

fetch_api() {
	local asset_id tag
	command -v jsonfilter >/dev/null 2>&1 || return 1
	if [ "$api_attempted" -eq 0 ]; then
		api_attempted=1
		printf '%s\n' 'Reading release metadata from api.github.com...'
		if download "$API_URL/releases/tags/$RELEASE_TAG" "$temporary/release.json" application/vnd.github+json; then
			tag="$(jsonfilter -i "$temporary/release.json" -e '@.tag_name')" || return 1
			[ "$tag" = "$RELEASE_TAG" ] || return 1
			api_ready=1
		fi
	fi
	[ "$api_ready" -eq 1 ] || return 1
	asset_id="$(jsonfilter -i "$temporary/release.json" -e "@.assets[@.name=\"$1\"].id")" || return 1
	case "$asset_id" in ''|*[!0-9]*) return 1 ;; esac
	printf 'Downloading %s through api.github.com\n' "$1"
	download "$API_URL/releases/assets/$asset_id" "$2" application/octet-stream
}

fetch() {
	if [ "$download_source" != github ]; then
		if fetch_api "$1" "$2"; then return 0; fi
		printf 'GitHub API download failed for %s.\n' "$1" >&2
	fi
	if [ "$download_source" != api ]; then
		printf 'Downloading %s through github.com\n' "$1"
		if download "$BASE_URL/$1" "$2" application/octet-stream; then return 0; fi
	fi
	fail "Cannot download $1. Check access to api.github.com and release-assets.githubusercontent.com (or github.com). No packages were changed."
}

temporary="$(mktemp -d /tmp/torrserver-install.XXXXXX)"
trap 'rm -rf "$temporary"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
for asset in SHA256SUMS "$SERVER_PACKAGE" "$LUCI_PACKAGE"; do
	if [ -n "$source_dir" ]; then
		cp "$source_dir/$asset" "$temporary/$asset"
	else
		fetch "$asset" "$temporary/$asset"
	fi
done
cd "$temporary"
for package in "$SERVER_PACKAGE" "$LUCI_PACKAGE"; do
	awk -v name="$package" '$2 == name || $2 == "./" name {print $1 "  " name; found++} END {if (found != 1) exit 1}' SHA256SUMS > selected.sha256 || fail "Missing or duplicate checksum: $package"
	sha256sum -c selected.sha256 || fail 'Checksum verification failed; no packages were installed'
	[ "$(head -c 3 "$package")" = ADB ] || fail 'Expected an OpenWrt APKv3 package'
done

if [ "$download_only" -eq 1 ]; then
	printf '%s\n' 'PASS: packages downloaded and verified; no packages were installed.'
	exit 0
fi

backup=''
if [ -f /etc/config/torrserver ]; then
	backup="/etc/torrserver-backups/$(date +%Y%m%d-%H%M%S)-$$"
	(umask 077; mkdir -p "$backup"; cp /etc/config/torrserver "$backup/torrserver")
	chmod 700 /etc/torrserver-backups "$backup"
	data_path="$(uci -q get torrserver.main.path || true)"
	[ -n "$data_path" ] || data_path=/opt/torrserver
	if [ -f "$data_path/accs.db" ]; then
		(umask 077; cp "$data_path/accs.db" "$backup/accs.db")
	fi
	printf 'Configuration and authentication backup: %s\n' "$backup"
fi
printf '%s\n' 'Updating OpenWrt package indexes...'
apk update
if [ "$reinstall" -eq 1 ]; then
	apk add --allow-untrusted --force-reinstall "$temporary/$SERVER_PACKAGE" "$temporary/$LUCI_PACKAGE"
else
	apk add --allow-untrusted "$temporary/$SERVER_PACKAGE" "$temporary/$LUCI_PACKAGE"
fi
printf '%s\n' 'Installed. Open LuCI > Services > TorrServer (reload the browser page).' \
	'Your data directory, authentication and UCI configuration are retained.' \
	'No firewall rules were changed. Full data-directory backups remain your responsibility.'
/usr/bin/torrserver --version
if [ -n "$backup" ]; then
	printf 'Backup retained at %s (contains credentials; do not share it).\n' "$backup"
fi
