# pkgs/default.nix
{callPackage}: {
  # Kubernetes core
  kube-apiserver = callPackage ./kube-apiserver {};
  kube-controller = callPackage ./kube-controller {};
  kube-scheduler = callPackage ./kube-scheduler {};
  kubelet = callPackage ./kubelet {};
  kubectl = callPackage ./kubectl {};
  containerd = callPackage ./containerd {};
  runc = callPackage ./runc {};

  # etcd suite
  inherit (callPackage ./etcd {}) etcd etcdserver etcdctl etcdutl;

  # Cilium
  cilium-agent = callPackage ./cilium-agent {};
  cilium-operator = callPackage ./cilium-operator {};
  cilium-cli = callPackage ./cilium-cli {};
  cilium-cni = callPackage ./cilium-cni {};
  cilium-dbg = callPackage ./cilium-dbg {};
  cilium-bugtool = callPackage ./cilium-bugtool {};
  cilium-health = callPackage ./cilium-health {};
  clustermesh-apiserver = callPackage ./clustermesh-apiserver {};
  hubble-relay = callPackage ./hubble-relay {};
  hubble-cli = callPackage ./hubble-cli {};

  # Observability
  loki = callPackage ./loki {};
  otelcol = callPackage ./otelcol {};
  metrics-server = callPackage ./metrics-server {};
  kube-state-metrics = callPackage ./kube-state-metrics {};
  node-problem-detector = callPackage ./node-problem-detector {};
  coredns = callPackage ./coredns {};

  # CSI
  csi-driver-host-path = callPackage ./csi-driver-host-path {};
  csi-snapshot-controller = callPackage ./csi-snapshot-controller {};
  csi-snapshot-validation-webhook = callPackage ./csi-snapshot-validation-webhook {};
  aws-ebs-csi-driver = callPackage ./aws-ebs-csi-driver {};

  # SPIRE
  spire-server = callPackage ./spire-server {};
  spire-agent = callPackage ./spire-agent {};
  oidc-discovery-provider = callPackage ./oidc-discovery-provider {};

  # Secrets
  external-secrets-operator = callPackage ./external-secrets-operator {};
  kubeseal = callPackage ./kubeseal {};
  cmctl = callPackage ./cmctl {};

  # GitOps / CI / Tooling
  woodpecker-server = callPackage ./woodpecker-server {};
  woodpecker-agent = callPackage ./woodpecker-agent {};
  woodpecker-cli = callPackage ./woodpecker-cli {};
  tekton-pipelines-controller = callPackage ./tekton-pipelines-controller {};
  tkn = callPackage ./tkn {};
  k9s = callPackage ./k9s {};
  popeye = callPackage ./popeye {};
  stern = callPackage ./stern {};
  external-dns = callPackage ./external-dns {};
}
