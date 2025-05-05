# pkgs/default.nix
{
  lib,
  callPackage,
}: {
  containerd = callPackage ./containerd {};
  kube-apiserver = callPackage ./kube-apiserver {};
  kube-scheduler = callPackage ./kube-scheduler {};
  kube-controller = callPackage ./kube-controller {};
  kubelet = callPackage ./kubelet {};
  kubectl = callPackage ./kubectl {};
  inherit
    (callPackage ./etcd {})
    etcd
    etcdserver
    etcdctl
    etcdutl
    ;
  runc = callPackage ./runc {};
  cilium-cli = callPackage ./cilium-cli {};
  cilium-dbg = callPackage ./cilium-dbg {};
  cilium-agent = callPackage ./cilium-agent {};
  cilium-operator = callPackage ./cilium-operator {};
  cilium-cni = callPackage ./cilium-cni {};
  cilium-health = callPackage ./cilium-health {};
  cilium-bugtool = callPackage ./cilium-bugtool {};
  clustermesh-apiserver = callPackage ./clustermesh-apiserver {};
  hubble-relay = callPackage ./hubble-relay {};
  hubble-cli = callPackage ./hubble-cli {};
  coredns = callPackage ./coredns {};
  metrics-server = callPackage ./metrics-server {};
  kube-state-metrics = callPackage ./kube-state-metrics {};
  node-problem-detector = callPackage ./node-problem-detector {};
  csi-driver-host-path = callPackage ./csi-driver-host-path {};
  csi-snapshot-controller = callPackage ./csi-snapshot-controller {};
  csi-snapshot-validation-webhook = callPackage ./csi-snapshot-validation-webhook {};
  aws-ebs-csi-driver = callPackage ./aws-ebs-csi-driver {};
  external-dns = callPackage ./external-dns {};
  cmctl = callPackage ./cmctl {};
  spire-server = callPackage ./spire-server {};
  spire-agent = callPackage ./spire-agent {};
  oidc-discovery-provider = callPackage ./oidc-discovery-provider {};
  woodpecker-server = callPackage ./woodpecker-server {};
  woodpecker-agent = callPackage ./woodpecker-agent {};
  woodpecker-cli = callPackage ./woodpecker-cli {};
  tekton-pipelines-controller = callPackage ./tekton-pipelines-controller {};
  tkn = callPackage ./tkn {};
  k9s = callPackage ./k9s {};
  popeye = callPackage ./popeye {};
  stern = callPackage ./stern {};
}
