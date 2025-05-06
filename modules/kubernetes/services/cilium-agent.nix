# modules/kubernetes/services/cilium-agent.nix
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  pkg = pkgs.blackmatter.k8s.cilium-agent;
  cfg = config.blackmatter.components.kubernetes.services.cilium-agent;
in {
  options.blackmatter.components.kubernetes.services.cilium-agent = {
    enable = mkEnableOption "Enable cilium-agent";
  };
  config = mkIf cfg.enable {
    systemd.services.cilium-agent = {
      description = "blackmatter.cilium-agent";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        ExecStart = ''
          ${pkg}/bin/cilium-agent \
            --config-dir=/etc/cilium \
            --enable-ipv4=true \
            --enable-ipv6=false \
            --kube-apiserver=https://127.0.0.1:6443 \
            --k8s-require-ipv4-pod-cidr=true
        '';
        Restart = "always";
        RestartSec = 2;
        LimitNOFILE = 1048576;
        MountFlags = "shared";
        CapabilityBoundingSet = "CAP_NET_ADMIN CAP_BPF CAP_SYS_ADMIN";
      };
      environment = {
        PATH = lib.makeBinPath [pkg pkgs.coreutils pkgs.iproute2];
      };
    };
    environment.systemPackages = [pkg];
    systemd.tmpfiles.rules = [
      "d /etc/cilium 0755 root root -"
      "d /var/run/cilium 0755 root root -"
    ];
    networking.firewall.allowedUDPPorts = [8472];
  };
}
