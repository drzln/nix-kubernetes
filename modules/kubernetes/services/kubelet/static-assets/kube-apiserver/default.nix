# modules/kubernetes/services/kubelet/static-pods/kube-apiserver/default.nix
{
  pkgs,
  lib,
  ...
}: let
  pki = "/var/lib/blackmatter/certs";
  svcCIDR = "10.96.0.0/12";
  podLib = import ../pod-lib.nix {inherit pkgs lib;};
  image = "registry.k8s.io/kube-apiserver:v1.30.1";
in {
  options.manifest = lib.mkOption {
    type = lib.types.package;
    description = "The generated static pod manifest for kube-apiserver";
  };
  config.manifest = podLib.manifestFile "kube-apiserver.json" (podLib.mkApiServerPod {
    inherit pki svcCIDR image;
  });
}
