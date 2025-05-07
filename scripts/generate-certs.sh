#!/usr/bin/env sh
set -euo pipefail

OUTDIR="./secrets/generated"
mkdir -p "$OUTDIR"

# Define the DNS and IPs we'll SAN across all certs
cat >"$OUTDIR/san.cnf" <<EOF
[ req ]
req_extensions = v3_req
distinguished_name = dn
[ dn ]
[ v3_req ]
subjectAltName = @alt_names
[ alt_names ]
DNS.1 = localhost
DNS.2 = single
DNS.3 = single.cluster.local
DNS.4 = etcd.single.cluster.local
DNS.5 = kubernetes
DNS.6 = kubernetes.default
DNS.7 = kubernetes.default.svc
DNS.8 = kubernetes.default.svc.cluster.local
IP.1  = 127.0.0.1
IP.2  = 10.96.0.1
IP.3  = 10.96.0.10
EOF

echo "[+] Generating self-signed CA"
openssl genrsa -out "$OUTDIR/ca.key" 2048
openssl req -x509 -new -nodes -key "$OUTDIR/ca.key" -sha256 -days 10000 \
  -subj "/CN=kubernetes-ca" -out "$OUTDIR/ca.crt"

generate_cert() {
  local name="$1"
  local cn="$2"
  local org="$3"

  echo "[+] Generating cert for $name (CN=$cn, O=$org)"

  openssl genrsa -out "$OUTDIR/${name}.key" 2048
  openssl req -new -key "$OUTDIR/${name}.key" \
    -subj "/CN=${cn}/O=${org}" \
    -out "$OUTDIR/${name}.csr"

  openssl x509 -req -in "$OUTDIR/${name}.csr" \
    -CA "$OUTDIR/ca.crt" -CAkey "$OUTDIR/ca.key" -CAcreateserial \
    -out "$OUTDIR/${name}.crt" -days 365 \
    -extensions v3_req -extfile "$OUTDIR/san.cnf"
}

# Generate certs for core roles
generate_cert apiserver "kube-apiserver" "kubernetes"
generate_cert kubelet "system:node:single" "system:nodes"
generate_cert etcd "etcd" "kubernetes"
generate_cert admin "admin" "system:masters"

echo "[✓] Cert generation complete. Output written to: $OUTDIR"
