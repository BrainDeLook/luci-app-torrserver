#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
sdk_dir="$(realpath "${1:?SDK directory required}")"
binary="$(realpath "${2:?ARM64 binary required}")"
test -f "$sdk_dir/include/package.mk"
test -s "$binary"
mkdir -p "$repo_dir/dist"
cd "$sdk_dir"
./scripts/feeds update -a
./scripts/feeds install -a
make -C feeds/luci/modules/luci-base/src po2lmo CC=gcc
feeds/luci/modules/luci-base/src/po2lmo "$repo_dir/luci/i18n/ru.po" "$repo_dir/.build/torrserver.ru.lmo"
cp -R "$repo_dir/packages/torrserver" package/torrserver
cp -R "$repo_dir/packages/luci-app-torrserver" package/luci-app-torrserver
printf '%s\n' \
	'CONFIG_TARGET_armsr=y' \
	'CONFIG_TARGET_armsr_armv8=y' \
	'CONFIG_TARGET_armsr_armv8_DEVICE_generic=y' \
	'# CONFIG_ALL is not set' \
	'# CONFIG_ALL_NONSHARED is not set' \
	'# CONFIG_ALL_KMODS is not set' \
	'CONFIG_PACKAGE_torrserver=m' \
	'CONFIG_PACKAGE_luci-app-torrserver=m' \
	'# CONFIG_SIGNED_PACKAGES is not set' > .config
make defconfig
make -j2 package/torrserver/compile package/luci-app-torrserver/compile \
	TORRSERVER_BINARY="$binary" LUCI_SOURCE_DIR="$repo_dir/luci" LUCI_LMO="$repo_dir/.build/torrserver.ru.lmo" V=s
find bin/packages -name 'torrserver-*.apk' -exec cp '{}' "$repo_dir/dist/" \;
find bin/packages -name 'luci-app-torrserver-*.apk' -exec cp '{}' "$repo_dir/dist/" \;
test "$(find "$repo_dir/dist" -maxdepth 1 -name '*.apk' | wc -l)" -eq 2
cp "$repo_dir/.build/BUILDINFO.txt" "$repo_dir/.build/TORRSERVER-LICENSE.txt" "$repo_dir/dist/"
printf 'package_source=%s\nopenwrt=25.12.5\n' "$(git -C "$repo_dir" rev-parse HEAD)" >> "$repo_dir/dist/BUILDINFO.txt"
for feed in "$sdk_dir"/feeds/*; do
	if [ -d "$feed/.git" ] || [ -f "$feed/.git" ]; then
		printf 'feed_%s=%s\n' "$(basename "$feed")" "$(git -C "$feed" rev-parse HEAD)" >> "$repo_dir/dist/BUILDINFO.txt"
	fi
done
cd "$repo_dir/dist"
sha256sum ./*.apk BUILDINFO.txt TORRSERVER-LICENSE.txt > SHA256SUMS
