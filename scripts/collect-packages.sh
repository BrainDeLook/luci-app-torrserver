#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
sdk_output="$(realpath "${1:?SDK artifact directory required}")"
mkdir -p "$repo_dir/dist"
find "$sdk_output/bin" -name 'torrserver-*.apk' -exec cp '{}' "$repo_dir/dist/" \;
find "$sdk_output/bin" -name 'luci-app-torrserver-*.apk' -exec cp '{}' "$repo_dir/dist/" \;
test "$(find "$repo_dir/dist" -maxdepth 1 -name '*.apk' | wc -l)" -eq 2
for package in "$repo_dir"/dist/*.apk; do
	test "$(head -c 3 "$package")" = ADB
done
cp "$repo_dir/.build/BUILDINFO.txt" "$repo_dir/.build/TORRSERVER-LICENSE.txt" "$repo_dir/dist/"
printf 'package_source=%s\nopenwrt=25.12.5\nsdk_image=ghcr.io/openwrt/sdk:aarch64_generic-25.12.5\nsdk_action=f5813d30eeef3534b58ac7e79c5d8842b6035434\nsdk_archive=openwrt-sdk-25.12.5-armsr-armv8_gcc-14.3.0_musl.Linux-x86_64.tar.zst\nsdk_sha256=1b0316604a3e820b2b008a1baff3f9dac6716af942bef800930e58c7de98c98b\n' "$(git -C "$repo_dir" rev-parse HEAD)" >> "$repo_dir/dist/BUILDINFO.txt"
cd "$repo_dir/dist"
sha256sum ./*.apk BUILDINFO.txt TORRSERVER-LICENSE.txt > SHA256SUMS
