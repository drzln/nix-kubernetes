#  modules/kubernetes/services/kubelet/static-pods/kube-scheduler/default.nix
{
  pkgs,
  lib,
  ...
}: let
  scr = "/run/secrets/kubernetes";
  podLib = import ../pod-lib.nix {inherit pkgs lib;};
  image = "registry.k8s.io/kube-scheduler:v1.30.1";
in {
  options.manifest = lib.mkOption {
    type = lib.types.package;
    description = "The generated static pod manifest for kube-scheduler";
  };

  config.manifest = podLib.manifestFile "kube-scheduler.json" (
    podLib.mkSchedulerPod scr image
  );
}
