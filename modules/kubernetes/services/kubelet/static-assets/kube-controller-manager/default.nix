# modules/kubernetes/services/kubelet/static-assets/kube-controller-manager/default.nix
{
  pkgs,
  lib,
  ...
}: let
  pki = "/var/lib/blackmatter/certs";
  scr = "/run/secrets/kubernetes";
  podLib = import ../pod-lib.nix {inherit pkgs lib;};
  image = "registry.k8s.io/kube-controller-manager:v1.30.1";
in {
  options.manifest = lib.mkOption {
    type = lib.types.package;
    description = "The generated static pod manifest for kube-controller-manager";
  };

  config.manifest = podLib.manifestFile "kube-controller-manager.json" (
    podLib.mkControllerManagerPod {
      inherit pki scr image;
    }
  );
}
