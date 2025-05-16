# modules/kubernetes/services/kubelet/static-assets/default.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.kubelet.static-assets;

  script = pkgs.writeShellScriptBin "setup-manifests" (builtins.readFile ./setup-manifests.sh);

  podManifests = lib.flatten [
    (import ./etcd {inherit config pkgs lib;}).config.manifest
    (import ./kube-apiserver {inherit config pkgs lib;}).config.manifest
    (import ./kube-scheduler {inherit config pkgs lib;}).config.manifest
    (import ./kube-controller-manager {inherit config pkgs lib;}).config.manifest
    (import ./cilium {inherit config pkgs lib;}).config.manifest
  ];
in {
  imports = [
    ./etcd
    ./kube-apiserver
    ./kube-scheduler
    ./kube-controller-manager
    ./cilium
  ];
  options.blackmatter.components.kubernetes.kubelet.static-assets.enable =
    lib.mkEnableOption "Enable static pods for Kubernetes components";
  config = lib.mkIf cfg.enable {
    system.activationScripts.restart-static-assets = ''
      echo "[+] Restarting static-assets service..."
      ${pkgs.systemd}/bin/systemctl restart static-assets.service
    '';
    systemd.services.static-assets = {
      description = "Setup static pod manifests";
      wants = [
        "kubelet-generate-certs.service"
        "network.target"
        "containerd.service"
      ];
      after = [
        "network.target"
        "containerd.service"
        "systemd-tmpfiles-setup.service"
        "kubelet-generate-certs.service"
      ];
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
