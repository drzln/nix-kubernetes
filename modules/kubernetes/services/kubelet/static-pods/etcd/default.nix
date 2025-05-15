# modules/kubernetes/services/kubelet/static-pods/etcd/default.nix
{
  pkgs,
  lib,
  ...
}: let
  pki = "/var/lib/blackmatter/certs";
  podLib = import ../pod-lib.nix {inherit pkgs lib;};
  image = "quay.io/coreos/etcd:v3.5.9";
in {
  options.manifest = lib.mkOption {
    type = lib.types.package;
    description = "The generated static pod manifest for etcd";
  };

  config.manifest =
    podLib.manifestFile "etcd.json" (podLib.mkEtcdPod pki image);
}
