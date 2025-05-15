#!/usr/bin/env bash
set -euo pipefail

manifest_dir="/etc/kubernetes/manifests"
mkdir -p "$manifest_dir"

for manifest in "$@"; do
  base_name=$(basename "$manifest" | sed 's/^.*-\(.*\)$/\1/') # remove nix hash
  install -m644 "$manifest" "$manifest_dir/$base_name"
done
