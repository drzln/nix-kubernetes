# modules/kubernetes/services/spire-server.nix
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  pkg = pkgs.blackmatter.k8s.spire-server;
  cfg = config.blackmatter.components.kubernetes.services.spire-server;
in {
  options.blackmatter.components.kubernetes.services.spire-server = {
    enable = mkEnableOption "Enable SPIRE server";
  };
  config = mkIf cfg.enable {
    users.users.spire = {
      isSystemUser = true;
      group = "spire";
    };
    users.groups.spire = {};
    systemd.services.spire-server = {
      description = "blackmatter.spire-server";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkg}/bin/spire-server run -config /etc/spire/server.conf";
        Restart = "always";
        RestartSec = 2;
        User = "spire";
        Group = "spire";
        RuntimeDirectory = "spire";
      };
      environment = {
        PATH = lib.makeBinPath [pkg pkgs.coreutils];
      };
    };
    environment.systemPackages = [pkg];
    systemd.tmpfiles.rules = [
      "d /etc/spire 0755 spire spire -"
      "d /var/lib/spire 0700 spire spire -"
    ];
    # Example static config — replace with rendered config later
    environment.etc."spire/server.conf".text = ''
      server {
        bind_address = "127.0.0.1"
        bind_port = "8081"
        data_dir = "/var/lib/spire"
        log_level = "INFO"
      }

      plugins {
        DataStore "memory" {
          plugin_data {}
        }

        NodeAttestor "join_token" {
          plugin_data {}
        }

        KeyManager "memory" {
          plugin_data {}
        }

        UpstreamAuthority "disk" {
          plugin_data {
            cert_file_path = "/etc/spire/ca.crt"
            key_file_path = "/etc/spire/ca.key"
          }
        }
      }
    '';
    environment.etc."spire/ca.crt".text = "REPLACE_ME";
    environment.etc."spire/ca.key".text = "REPLACE_ME";
  };
}
