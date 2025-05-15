# modules/kubernetes/services/kubelet/static-pods/default.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.kubelet.static-pods;
  script = pkgs.writeShellScriptBin "setup-manifests" (builtins.readFile ./setup-manifests.sh);
  podManifests = lib.flatten [
    (import ./etcd {inherit config pkgs lib;}).config.manifest
    (import ./kube-apiserver {inherit config pkgs lib;}).config.manifest
    (import ./kube-scheduler {inherit config pkgs lib;}).config.manifest
    (import ./kube-controller-manager {inherit config pkgs lib;}).config.manifest
  ];
in {
  imports = [
    ./etcd
    ./kube-apiserver
    ./kube-scheduler
    ./kube-controller-manager
  ];
  options.blackmatter.components.kubernetes.kubelet.static-pods.enable =
    lib.mkEnableOption "Enable static pods for Kubernetes components";
  config = lib.mkIf cfg.enable {
    system.activationScripts.restart-static-pods = ''
      echo "[+] Restarting static-pods service..."
      ${pkgs.systemd}/bin/systemctl restart static-pods.service
    '';
    systemd.services.static-pods = {
      description = "Setup static pod manifests";
      before = ["kubelet.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Wants = [
          "kubelet-generate-certs.service"
          "static-pods.service"
        ];
        After = [
          "network.target"
          "containerd.service"
          "systemd-tmpfiles-setup.service"
          "kubelet-generate-certs.service"
        ];
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ''
          ${script}/bin/setup-manifests ${lib.concatStringsSep " " podManifests}
        '';
      };
    };
  };
}
