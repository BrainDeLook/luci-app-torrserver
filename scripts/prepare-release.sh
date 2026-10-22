#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
cp "$repo_dir/install.sh" "$repo_dir/dist/install.sh"
cd "$repo_dir/dist"
sha256sum ./*.apk BUILDINFO.txt TORRSERVER-LICENSE.txt install.sh > SHA256SUMS
