# modules/kubernetes/services/kubelet/service.nix
{
  blackmatterPkgs,
  pkgs,
  lib,
  cfg,
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
    wantedBy = ["multi-user.target"];
    after = ["network.target" "containerd.service" "systemd-tmpfiles-setup.service"];
    environment.PATH = lib.mkForce (lib.makeBinPath [
      blackmatterPkgs.cilium-cni
      pkgs.containerd
      pkgs.util-linux
      pkgs.coreutils
      pkgs.iproute2
      pkgs.runc
      pkg
    ]);
    serviceConfig = {
      After = ["kubelet-verify-assets.service"];
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
      ExecStart = lib.concatStringsSep " " (
        [
          "${pkg}/bin/kubelet"
          "--config=${scr}/configs/kubelet/config"
          "--kubeconfig=${scr}/configs/kubelet/kubeconfig"
        ]
        ++ cfg.extraFlags
      );
    };
  };
}
