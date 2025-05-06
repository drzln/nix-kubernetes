# modules/kubernetes/services/vector.nix
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  pkg = pkgs.blackmatter.k8s.vector;
  cfg = config.blackmatter.components.kubernetes.services.vector;
in {
  options.blackmatter.components.kubernetes.services.vector = {
    enable = mkEnableOption "Enable Vector telemetry pipeline";
  };
  config = mkIf cfg.enable {
    users.users.vector = {
      isSystemUser = true;
      group = "vector";
    };
    users.groups.vector = {};
    systemd.services.vector = {
      description = "blackmatter.vector";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkg}/bin/vector --config /etc/vector/vector.toml";
        Restart = "always";
        RestartSec = 2;
        User = "vector";
        Group = "vector";
        RuntimeDirectory = "vector";
        LimitNOFILE = 65536;
      };
      environment = {
        PATH = lib.makeBinPath [pkg pkgs.coreutils];
      };
    };
    environment.systemPackages = [pkg];
    systemd.tmpfiles.rules = [
      "d /etc/vector 0755 vector vector -"
      "d /var/lib/vector 0755 vector vector -"
    ];
    environment.etc."vector/vector.toml".text = ''
      [sources.kubernetes_logs]
      type = "kubernetes_logs"

      [transforms.add_host]
      type = "remap"
      inputs = ["kubernetes_logs"]
      source = '.host = "${config.networking.hostName}"'

      [sinks.loki]
      type = "loki"
      inputs = ["add_host"]
      endpoint = "http://127.0.0.1:3100"
    '';
  };
}
