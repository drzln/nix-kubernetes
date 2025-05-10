# modules/kubernetes/services/kubelet/service.nix
{
  lib,
  pkgs,
  cfg,
  blackmatterPkgs,
}: let
  scr = "/run/secrets/kubernetes";
  pkg = blackmatterPkgs.kubelet;
in {
  environment.systemPackages = [pkg];

  systemd.tmpfiles.rules = [
    "d /etc/kubernetes/manifests 0755 root root -"
    "d /etc/kubernetes/kubelet   0755 root root -"
    "d /etc/cni/net.d            0755 root root -"
    "d /var/run/etcd             0700 root root -"
  ];

  systemd.services.kubelet = {
    description = "blackmatter.kubelet";
    after = ["network.target" "containerd.service" "systemd-tmpfiles-setup.service"];
    wantedBy = ["multi-user.target"];
    environment.PATH = lib.mkForce (lib.makeBinPath [
      pkg
      pkgs.runc
      pkgs.iproute2
      pkgs.coreutils
      pkgs.util-linux
      pkgs.containerd
      blackmatterPkgs.cilium-cni
    ]);
    serviceConfig = {
      User = "root";
      ExecStart = lib.concatStringsSep " " (
        [
          "${pkg}/bin/kubelet"
          "--config=${scr}/configs/kubelet/config"
          "--kubeconfig=${scr}/configs/kubelet/kubeconfig"
        ]
        ++ cfg.extraFlags
      );
      Restart = "always";
      RestartSec = 2;
      KillMode = "process";
      Delegate = true;
      LimitNOFILE = 1048576;
      CapabilityBoundingSet = ["CAP_SYSLOG" "CAP_SYS_ADMIN"];
      AmbientCapabilities = ["CAP_SYSLOG" "CAP_SYS_ADMIN"];
      DeviceAllow = ["/dev/kmsg r"];
      PrivateDevices = false;
      ProtectKernelLogs = false;
    };
  };
}
