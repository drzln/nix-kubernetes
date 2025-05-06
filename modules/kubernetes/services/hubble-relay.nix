# modules/kubernetes/services/hubble-relay.nix
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  pkg = pkgs.blackmatter.k8s.hubble-relay;
  cfg = config.blackmatter.components.kubernetes.services.hubble-relay;
in {
  options.blackmatter.components.kubernetes.services.hubble-relay = {
    enable = mkEnableOption "Enable hubble-relay";
  };
  config = mkIf cfg.enable {
    systemd.services.hubble-relay = {
      description = "blackmatter.hubble-relay";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target" "cilium-agent.service"];
      wants = ["network-online.target" "cilium-agent.service"];
      serviceConfig = {
        ExecStart = ''
          ${pkg}/bin/hubble-relay \
            --config=/etc/hubble/relay.yaml
        '';
        Restart = "always";
        RestartSec = 2;
        LimitNOFILE = 1048576;
      };
      environment = {
        PATH = lib.makeBinPath [pkg pkgs.coreutils];
      };
    };
    environment.systemPackages = [pkg];
    systemd.tmpfiles.rules = [
      "d /etc/hubble 0755 root root -"
    ];
    environment.etc."hubble/relay.yaml".text = ''
      peer-service: 127.0.0.1:4244
      listen-address: 127.0.0.1:4245
      dial-timeout: 5s
      retry-timeout: 30s
      log-level: info
    '';
  };
}
