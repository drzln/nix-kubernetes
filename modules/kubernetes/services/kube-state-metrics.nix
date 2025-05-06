# modules/kubernetes/services/kube-state-metrics.nix
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  pkg = pkgs.blackmatter.k8s.metrics-server;
  cfg = config.blackmatter.components.kubernetes.services.metrics-server;
in {
  options.blackmatter.components.kubernetes.services.metrics-server = {
    enable = mkEnableOption "Enable metrics-server";
  };
  config = mkIf cfg.enable {
    systemd.services.metrics-server = {
      description = "blackmatter.metrics-server";
      after = ["network.target" "kube-apiserver.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = ''
          ${pkg}/bin/metrics-server \
            --kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP \
            --kubelet-insecure-tls \
            --cert-dir=/var/lib/metrics-server/certs \
            --secure-port=4443 \
            --metric-resolution=15s
        '';
        Restart = "always";
        RestartSec = 2;
        LimitNOFILE = 65536;
      };
      environment = {
        PATH = lib.makeBinPath [pkg pkgs.coreutils];
      };
    };
    environment.systemPackages = [pkg];
    systemd.tmpfiles.rules = [
      "d /var/lib/metrics-server/certs 0755 root root -"
    ];
  };
}
