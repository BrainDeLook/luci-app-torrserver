#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
binary="$(realpath "${1:?ARM64 binary required}")"
test -s "$binary"
install -m 0755 "$binary" "$repo_dir/packages/torrserver/files/torrserver"
root="$repo_dir/packages/luci-app-torrserver/root"
install -Dm 0644 "$repo_dir/luci/view/torrserver/overview.js" "$root/www/luci-static/resources/view/torrserver/overview.js"
install -Dm 0644 "$repo_dir/luci/menu.d/luci-app-torrserver.json" "$root/usr/share/luci/menu.d/luci-app-torrserver.json"
install -Dm 0644 "$repo_dir/luci/acl.d/luci-app-torrserver.json" "$root/usr/share/rpcd/acl.d/luci-app-torrserver.json"
install -Dm 0755 "$repo_dir/luci/rpcd/luci.torrserver" "$root/usr/libexec/rpcd/luci.torrserver"
install -Dm 0644 "$repo_dir/luci/i18n/ru.po" "$repo_dir/packages/luci-app-torrserver/po/ru.po"
mkdir -p "$repo_dir/.build/sdk-output"
