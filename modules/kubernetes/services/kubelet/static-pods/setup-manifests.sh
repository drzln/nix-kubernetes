#!/usr/bin/env bash
set -euo pipefail
MANIFESTS_DIR="/etc/kubernetes/manifests"
mkdir -p "$MANIFESTS_DIR"
for manifest in "$@"; do
  install -m644 "$manifest" "$MANIFESTS_DIR/"
done
