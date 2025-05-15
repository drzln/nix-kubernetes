# modules/kubernetes/services/kubelet/static-pods/kube-apiserver/default.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.static-pods;
  pki = "/var/lib/blackmatter/certs";
  svcCIDR = cfg.serviceCIDR;
  podLib = import ../pod-lib.nix {inherit pkgs lib;};
  image = "registry.k8s.io/kube-apiserver:${cfg.kubernetesVersion}";
in {
  options.manifest = lib.mkOption {
    type = lib.types.package;
    description = "The generated static pod manifest for kube-apiserver";
  };

  config.manifest =
    podLib.manifestFile "kube-apiserver.json" (podLib.mkApiServerPod pki svcCIDR image);
}
