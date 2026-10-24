#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
cp "$repo_dir/install.sh" "$repo_dir/dist/install.sh"
printf 'installer_source=%s\npackage_release=v147-r2\n' "$(git -C "$repo_dir" rev-parse HEAD)" > "$repo_dir/dist/INSTALLER-BUILDINFO.txt"
cd "$repo_dir/dist"
sha256sum ./*.apk BUILDINFO.txt TORRSERVER-LICENSE.txt install.sh INSTALLER-BUILDINFO.txt > SHA256SUMS
