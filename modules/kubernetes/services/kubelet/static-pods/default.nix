# modules/kubernetes/services/kubelet/static-pods/default.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.static-pods;
  script = pkgs.writeShellScriptBin "setup-manifests" (builtins.readFile ./setup-manifests.sh);
  podManifests = lib.flatten [
    (import ./etcd {inherit config pkgs lib;}).manifest
    (import ./kube-apiserver {inherit config pkgs lib;}).manifest
    (import ./kube-controller-manager {inherit config pkgs lib;}).manifest
    (import ./kube-scheduler {inherit config pkgs lib;}).manifest
  ];
in {
  imports = [
    ./etcd
    ./kube-apiserver
    ./kube-controller-manager
    ./kube-scheduler
  ];
  options.blackmatter.components.kubernetes.static-pods.enable =
    lib.mkEnableOption "Enable static pods for Kubernetes components";
  config = lib.mkIf cfg.enable {
    systemd.services.static-pods = {
      description = "Setup static pod manifests";
      before = ["kubelet.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ''
          ${script}/bin/setup-manifests ${lib.concatStringsSep " " podManifests}
        '';
      };
    };
  };
}
