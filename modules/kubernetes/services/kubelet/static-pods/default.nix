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
    ./cilium
  ];

  options.blackmatter.components.kubernetes.kubelet.static-pods.enable =
    lib.mkEnableOption "Enable static pods for Kubernetes components";

  config = lib.mkIf cfg.enable {
    blackmatter.components.kubernetes.kubelet.static-pods.cilium.enable = true;
    system.activationScripts.restart-static-pods = ''
      echo "[+] Restarting static-pods service..."
      ${pkgs.systemd}/bin/systemctl restart static-pods.service
    '';

    systemd.services.static-pods = {
      description = "Setup static pod manifests";

      # Fix applied here: Move Wants and After to [Unit] section.
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
