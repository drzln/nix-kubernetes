# pkgs/default.nix
{
  lib,
  callPackage,
}: {
  containerd = callPackage ./containerd {};
  # kube-apiserver = callPackage ./kube-apiserver {};
  # kube-scheduler = callPackage ./kube-scheduler {};
  # kube-controller = callPackage ./kube-controller {};
  # kubelet = callPackage ./kubelet {};
  # kubectl = callPackage ./kubectl {};
  #
  # etcd = callPackage ./etcd {};
  # etcdctl = callPackage ./etcd/ctl.nix {};
  # etcdutl = callPackage ./etcd/utl.nix {};
  #
  # cilium-cli = callPackage ./cilium-cli {};
  # runc = callPackage ./runc {};
}
