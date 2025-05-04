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
  cilium-agent = callPackage ./cilium-agent {};
  cilium-operator = callPackage ./cilium-operator {};
  cilium-cni = callPackage ./cilium-cni {};
  cilium-health = callPackage ./cilium-health {};
}
