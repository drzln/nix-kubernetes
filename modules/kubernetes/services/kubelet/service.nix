# modules/kubernetes/services/kubelet/service.nix
{
  lib,
  config,
  pkgs,
  blackmatterPkgs,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.kubelet;
  scr = "/run/secrets/kubernetes";
  pkg = blackmatterPkgs.blackmatter.k8s.kubelet;
in {
  options.blackmatter.components.kubernetes.kubelet = {
    enable = lib.mkEnableOption "Enable the kubelet systemd service unit";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkg];

    systemd.tmpfiles.rules = [
      "d /etc/kubernetes/manifests 0755 root root -"
      "d /etc/kubernetes/kubelet   0755 root root -"
      "d /etc/cni/net.d            0755 root root -"
      "d /var/run/etcd             0700 root root -"
    ];

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
        After = [
          "network.target"
          "containerd.service"
          "systemd-tmpfiles-setup.service"
          "kubelet-generate-certs.service"
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
  };
}
