# service/service.nix
{
  blackmatterPkgs,
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.kubelet.service;
  scr = "/run/secrets/kubernetes";
  pkg = blackmatterPkgs.blackmatter.k8s.kubelet;
in
  lib.mkIf cfg.enable {
    environment.systemPackages = [pkg];
    systemd.services.kubelet = {
      description = "blackmatter.kubelet";
      wantedBy = ["multi-user.target"];
      environment.PATH = lib.mkForce (lib.makeBinPath [
        blackmatterPkgs.blackmatter.k8s.cilium-cni
        pkgs.containerd
        pkgs.util-linux
        pkgs.coreutils
        pkgs.iproute2
        pkgs.runc
        pkg
      ]);
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
          "static-pods.service"
        ];
        CapabilityBoundingSet = ["CAP_SYSLOG" "CAP_SYS_ADMIN"];
        AmbientCapabilities = ["CAP_SYSLOG" "CAP_SYS_ADMIN"];
        DeviceAllow = ["/dev/kmsg r"];
        ProtectKernelLogs = false;
        PrivateDevices = false;
        LimitNOFILE = 1048576;
        KillMode = "process";
        Restart = "always";
        Delegate = true;
        RestartSec = 2;
        User = "root";
        ExecStart = lib.concatStringsSep " " [
          "${pkg}/bin/kubelet"
          "--config=${scr}/configs/kubelet/config"
          "--kubeconfig=${scr}/configs/kubelet/kubeconfig"
        ];
      };
    };
  }
