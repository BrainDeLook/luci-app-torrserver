#!/usr/bin/env bash
set -euo pipefail

source_dir="$(realpath "${1:?upstream source directory required}")"
output_dir="$(realpath -m "${2:?output directory required}")"
expected_commit=a86d8fa7fd4e07605f240fe69bf299392f7cb023
test "$(git -C "$source_dir" rev-parse HEAD)" = "$expected_commit"
mkdir -p "$output_dir"
cd "$source_dir"
export NODE_OPTIONS=--openssl-legacy-provider
export SOURCE_DATE_EPOCH
SOURCE_DATE_EPOCH="$(git show -s --format=%ct HEAD)"
export TZ=UTC
export LC_ALL=C
(
	cd web
	yarn install --frozen-lockfile
	yarn build
)
go run gen_web.go
cd server
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build \
	-trimpath -buildvcs=false -tags nosqlite \
	-ldflags='-s -w -checklinkname=0 -buildid= -X server/version.Version=MatriX.147' \
	-o "$output_dir/torrserver" ./cmd
file "$output_dir/torrserver"
readelf -h "$output_dir/torrserver" | grep AArch64
if readelf -l "$output_dir/torrserver" | grep -q INTERP; then
	echo 'Unexpected dynamic ELF interpreter' >&2
	exit 1
fi
printf 'upstream=YouROK/TorrServer\nversion=MatriX.147\ncommit=%s\narch=aarch64_generic\ncgo=0\ntags=nosqlite\n' "$expected_commit" > "$output_dir/BUILDINFO.txt"
go version >> "$output_dir/BUILDINFO.txt"
cp ../LICENSE "$output_dir/TORRSERVER-LICENSE.txt"
