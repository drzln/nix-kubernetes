# modules/kubernetes/services/spire-agent.nix
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  pkg = pkgs.blackmatter.k8s.spire-agent;
  cfg = config.blackmatter.components.kubernetes.services.spire-agent;
in {
  options.blackmatter.components.kubernetes.services.spire-agent = {
    enable = mkEnableOption "Enable SPIRE agent";
  };
  config = mkIf cfg.enable {
    users.users.spire = {
      isSystemUser = true;
      group = "spire";
    };
    users.groups.spire = {};
    systemd.services.spire-agent = {
      description = "blackmatter.spire-agent";
      after = ["network.target" "spire-server.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkg}/bin/spire-agent run -config /etc/spire/agent.conf";
        Restart = "always";
        RestartSec = 2;
        User = "spire";
        Group = "spire";
        RuntimeDirectory = "spire-agent";
      };
      environment = {
        PATH = lib.makeBinPath [pkg pkgs.coreutils];
      };
    };
    environment.systemPackages = [pkg];
    systemd.tmpfiles.rules = [
      "d /etc/spire 0755 spire spire -"
      "d /var/lib/spire-agent 0700 spire spire -"
      "d /run/spire 0755 spire spire -"
    ];
    # Example config — assumes spire-server is on the same node
    environment.etc."spire/agent.conf".text = ''
      agent {
        data_dir = "/var/lib/spire-agent"
        log_level = "INFO"
        socket_path = "/run/spire/agent.sock"
      }

      plugins {
        NodeAttestor "join_token" {
          plugin_data {}
        }

        KeyManager "memory" {
          plugin_data {}
        }

        WorkloadAttestor "unix" {
          plugin_data {}
        }
      }

      server_address = "127.0.0.1"
      server_port = "8081"
      trust_bundle_path = "/etc/spire/ca.crt"
      trust_domain = "example.org"
    '';
    environment.etc."spire/ca.crt".text = "REPLACE_ME";
  };
}
