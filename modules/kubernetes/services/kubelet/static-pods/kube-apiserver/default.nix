{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.static-pods;
  pki = "/var/lib/blackmatter/certs";
  podLib = import ../pod-lib.nix {inherit pkgs lib;};
  image = "registry.k8s.io/kube-apiserver:${cfg.kubernetesVersion}";
  svcCIDR = cfg.serviceCIDR;
  manifest =
    podLib.manifestFile "kube-apiserver.json"
    (podLib.mkApiServerPod pki svcCIDR image {});
in {inherit manifest;}
