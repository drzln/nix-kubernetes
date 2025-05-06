# modules/kubernetes/services/kubelet.nix
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  pkg = pkgs.blackmatter.k8s.kubelet;
  cfg = config.blackmatter.components.kubernetes.services.kubelet;
in {
  options.blackmatter.components.kubernetes.services.kubelet = {
    enable = mkEnableOption "kubelet";
  };
  config = mkIf cfg.enable {
    systemd.services.kubelet = {
      description = "blackmatter.kubelet";
      after = ["network.target" "containerd.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkg}/bin/kubelet \
          --config=/etc/kubernetes/kubelet/config.yaml \
          --container-runtime-endpoint=unix:///run/containerd/containerd.sock \
          --pod-manifest-path=/etc/kubernetes/manifests";
        Restart = "always";
        RestartSec = 2;
        KillMode = "process";
        Delegate = true;
        LimitNOFILE = 1048576;
      };
      environment = {
        PATH = lib.makeBinPath [pkg pkgs.containerd pkgs.iproute2 pkgs.util-linux];
      };
    };
    environment.systemPackages = [pkg];
    systemd.tmpfiles.rules = [
      "d /etc/kubernetes/manifests 0755 root root -"
      "d /etc/kubernetes/kubelet 0755 root root -"
    ];
    environment.etc."kubernetes/kubelet/config.yaml".text = ''
      kind: KubeletConfiguration
      apiVersion: kubelet.config.k8s.io/v1beta1
      cgroupDriver: systemd
      runtimeRequestTimeout: "15m"
      rotateCertificates: true
      failSwapOn: false
    '';
  };
}
