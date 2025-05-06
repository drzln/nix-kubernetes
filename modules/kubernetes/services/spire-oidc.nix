# modules/kubernetes/services/spire-oidc.nix
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  pkg = pkgs.blackmatter.k8s.oidc-discovery-provider;
  cfg = config.blackmatter.components.kubernetes.services.spire-oidc;
in {
  options.blackmatter.components.kubernetes.services.spire-oidc = {
    enable = mkEnableOption "Enable SPIRE OIDC Discovery Provider";
  };

  config = mkIf cfg.enable {
    systemd.services.spire-oidc = {
      description = "blackmatter.spire-oidc-discovery-provider";
      after = ["spire-server.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        ExecStart = ''
          ${pkg}/bin/oidc-discovery-provider run \
            -config /etc/spire/oidc.conf
        '';
        Restart = "always";
        RestartSec = 2;
        User = "spire";
        Group = "spire";
      };

      environment = {
        PATH = lib.makeBinPath [pkg pkgs.coreutils];
      };
    };

    environment.systemPackages = [pkg];

    systemd.tmpfiles.rules = [
      "d /etc/spire 0755 spire spire -"
    ];

    environment.etc."spire/oidc.conf".text = ''
      issuer = "https://oidc.example.org"
      audience = ["example-app"]
      listen_socket_path = "/run/spire/oidc.sock"
      ca_bundle_path = "/etc/spire/ca.crt"
      log_level = "INFO"
    '';

    environment.etc."spire/ca.crt".text = "REPLACE_ME";
  };
}
