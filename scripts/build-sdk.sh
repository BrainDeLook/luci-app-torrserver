#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
archive=openwrt-sdk-25.12.5-armsr-armv8_gcc-14.3.0_musl.Linux-x86_64.tar.zst
archive_sha256=1b0316604a3e820b2b008a1baff3f9dac6716af942bef800930e58c7de98c98b
sdk_dir="$repo_dir/.build/sdk"
mkdir -p "$sdk_dir" "$repo_dir/.build/sdk-output"
curl --http1.1 --fail --location --show-error --retry 3 --retry-all-errors \
	--speed-time 30 --speed-limit 1024 --connect-timeout 20 --max-time 300 \
	"https://downloads.openwrt.org/releases/25.12.5/targets/armsr/armv8/$archive" \
	-o "$repo_dir/.build/$archive"
printf '%s  %s\n' "$archive_sha256" "$repo_dir/.build/$archive" | sha256sum -c
tar --zstd -xf "$repo_dir/.build/$archive" --strip-components=1 -C "$sdk_dir"
curl --fail --location --show-error --retry 2 --connect-timeout 20 --max-time 60 \
	https://raw.githubusercontent.com/openwrt/gh-action-sdk/f5813d30eeef3534b58ac7e79c5d8842b6035434/entrypoint.sh \
	-o "$repo_dir/.build/sdk-entrypoint.sh"
printf '%s  %s\n' e78cc3ca3ffe9a15d47096e2e9a2aa07399a22a77acdca31f4e5aef2fa0e6a9c "$repo_dir/.build/sdk-entrypoint.sh" | sha256sum -c
docker run --rm --user "$(id -u):$(id -g)" --entrypoint /bin/bash \
	--env HOME=/builder --env FEEDNAME=torrserver --env 'PACKAGES=torrserver luci-app-torrserver' \
	--env INDEX=0 --env NO_REFRESH_CHECK=1 --env NO_SHFMT_CHECK=1 --env BUILD_LOG=1 \
	--env GIT_CONFIG_COUNT=2 --env GIT_CONFIG_KEY_0=http.lowSpeedLimit --env GIT_CONFIG_VALUE_0=1024 \
	--env GIT_CONFIG_KEY_1=http.lowSpeedTime --env GIT_CONFIG_VALUE_1=60 \
	-v "$sdk_dir:/builder" -v "$repo_dir/packages:/feed" \
	-v "$repo_dir/.build/sdk-output:/artifacts" \
	-v "$repo_dir/.build/sdk-entrypoint.sh:/entrypoint.sh:ro" \
	-w /builder ghcr.io/openwrt/sdk:aarch64_generic-25.12.5 /entrypoint.sh
