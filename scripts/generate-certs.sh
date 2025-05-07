#!/usr/bin/env sh
set -euo pipefail

OUTDIR="./secrets/generated"
mkdir -p "$OUTDIR"

echo "[+] Generating Kubernetes CA"
openssl genrsa -out "$OUTDIR/ca.key" 2048
openssl req -x509 -new -nodes -key "$OUTDIR/ca.key" -sha256 -days 10000 \
  -subj "/CN=kubernetes-ca" \
  -out "$OUTDIR/ca.crt"

# Function to sign component certs
generate_cert() {
  local name="$1"
  local cn="$2"
  local org="$3"

  echo "[+] Generating cert for $name"
  openssl genrsa -out "$OUTDIR/${name}.key" 2048

  openssl req -new -key "$OUTDIR/${name}.key" \
    -subj "/CN=${cn}/O=${org}" \
    -out "$OUTDIR/${name}.csr"

  openssl x509 -req -in "$OUTDIR/${name}.csr" \
    -CA "$OUTDIR/ca.crt" -CAkey "$OUTDIR/ca.key" -CAcreateserial \
    -out "$OUTDIR/${name}.crt" -days 365 \
    -extensions v3_req -extfile <(echo "
[ v3_req ]
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth,clientAuth
")
}

# Generate kubelet cert
generate_cert kubelet "system:node:single" "system:nodes"

# API server cert
generate_cert apiserver "kube-apiserver" "kubernetes"

# etcd cert
generate_cert etcd "etcd" "kubernetes"

# admin user (for kubeconfig)
generate_cert admin "admin" "system:masters"

echo "[✓] All certs generated in $OUTDIR"

