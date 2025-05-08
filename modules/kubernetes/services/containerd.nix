# modules/kubernetes/services/containerd.nix
{
  lib,
  pkgs,
  config,
  blackmatterPkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.kubernetes.services.containerd;
  pkg = blackmatterPkgs.containerd;
in {
  options.blackmatter.components.kubernetes.services.containerd = {
    enable = mkEnableOption "Enable the containerd service";
    settings = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Structured containerd configuration that can be merged with or override
        the default config.toml. Use this to declaratively express runtime settings.
      '';
    };
    configPath = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional override for the containerd config.toml path.";
    };
    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional flags to pass to containerd binary.";
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkg
      pkgs.runc
    ];
    systemd.tmpfiles.rules = [
      "d /etc/containerd 0755 root root -"
      "d /run/containerd 0755 root root -"
    ];
    environment.etc."containerd/config.toml".source =
      mkIf (cfg.configPath == null) "${pkg}/etc/containerd/config.toml";
    systemd.services.containerd = {
      description = "blackmatter.containerd";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = concatStringsSep " " (
          ["${pkg}/bin/containerd"] ++ cfg.extraFlags
        );
        Restart = "always";
        RestartSec = 2;
        LimitNOFILE = 1048576;
        Delegate = true;
        KillMode = "process";
      };
      environment = {
        PATH = lib.mkForce (lib.makeBinPath [pkg pkgs.iproute2 pkgs.coreutils pkgs.runc]);
      };
    };
  };
}
