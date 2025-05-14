#!/usr/bin/env sh
set -euo pipefail
OPENSSL_BIN=openssl
CA_CRT="./secrets/generated/ca.crt"
CERT_DIR="./secrets/generated"
echo "[✓] Verifying all generated Kubernetes certs against CA: $CA_CRT"
echo
for name in apiserver kubelet etcd admin controller-manager scheduler; do
  CRT="$CERT_DIR/$name.crt"
  KEY="$CERT_DIR/$name.key"
  echo "[*] Verifying $name.crt"
  "$OPENSSL_BIN" verify -CAfile "$CA_CRT" "$CRT"
  "$OPENSSL_BIN" x509 -in "$CRT" -noout -text | grep -E 'Subject:|Issuer:|Key Usage|Extended Key Usage'
  CERT_HASH=$(openssl x509 -in "$CRT" -noout -modulus | openssl md5)
  KEY_HASH=$(openssl rsa -in "$KEY" -noout -modulus | openssl md5)
  if [ "$CERT_HASH" != "$KEY_HASH" ]; then
    echo "❌ [FAIL] Key does not match certificate for $name"
    exit 1
  fi
  echo "✅ [PASS] $name.crt is valid and matches key"
  echo
done
echo "[✓] All certs verified successfully."
