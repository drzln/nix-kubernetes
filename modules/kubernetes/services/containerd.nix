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
  runcBin = "${pkgs.runc}/bin/runc";

  # Path where the package might ship a default config.toml
  defaultConfigPath = "${pkg}/etc/containerd/config.toml";

  # Only read it if it actually exists in the store
  baseConfig =
    if builtins.pathExists defaultConfigPath
    then builtins.readFile defaultConfigPath
    else "";

  # Your DNS + runc overrides
  dnsAndRuncOverrides = ''
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
      runtime_type   = "io.containerd.runc.v2"
      runtime_engine = "${runcBin}"

    [dns]
      # Use the file dnsmasq maintains with real upstream servers
      resolv_conf = "/etc/dnsmasq-resolv.conf"
  '';

  # Merge them, dropping the blank baseConfig if none
  mergedConfig =
    lib.concatStringsSep "\n\n"
    (builtins.filterString (c: c != "") [baseConfig dnsAndRuncOverrides]);
in {
  options.blackmatter.components.kubernetes.services.containerd = {
    enable = mkEnableOption "Enable the containerd service";
    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Structured containerd config overrides (merges into default).";
    };
    configPath = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "If set, skip our generated config.toml and use this path instead.";
    };
    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra flags to pass to the containerd daemon.";
    };
  };

  config = mkIf cfg.enable {
    # install the binaries
    environment.systemPackages = [pkg pkgs.runc];

    # directory placeholders
    systemd.tmpfiles.rules = [
      "d /etc/containerd 0755 root root -"
      "d /run/containerd 0755 root root -"
    ];

    # drop in either user-specified configPath or our merged blob
    environment.etc."containerd/config.toml".source =
      mkIf (cfg.configPath != null) (toString cfg.configPath);

    environment.etc."containerd/config.toml".text =
      mkIf (cfg.configPath == null) mergedConfig;

    systemd.services.containerd = {
      description = "blackmatter.containerd";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = concatStringsSep " " (
          [
            "${pkg}/bin/containerd"
            "--config"
            "/etc/containerd/config.toml"
          ]
          ++ cfg.extraFlags
        );
        Restart = "always";
        RestartSec = 2;
        Delegate = true;
        KillMode = "process";
        LimitNOFILE = 1048576;
      };
      environment = {
        PATH = mkForce (makeBinPath [pkg pkgs.runc pkgs.iproute2 pkgs.coreutils]);
      };
    };
  };
}
