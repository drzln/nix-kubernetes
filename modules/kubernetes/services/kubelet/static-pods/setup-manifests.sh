#!/usr/bin/env bash
set -euo pipefail

manifest_dir="/etc/kubernetes/manifests"
rm -rf "$manifest_dir"
mkdir -p "$manifest_dir"

for manifest in "$@"; do
  base_name=$(basename "$manifest" | sed 's/^[a-z0-9]\{32\}-//') # explicitly remove 32-char nix hash
  install -m644 "$manifest" "$manifest_dir/$base_name"
done
