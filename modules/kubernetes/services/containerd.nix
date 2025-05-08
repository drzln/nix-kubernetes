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
  defaultConfigPath = "${pkg}/etc/containerd/config.toml";

  baseConfig =
    if builtins.pathExists defaultConfigPath
    then builtins.readFile defaultConfigPath
    else "";

  overrides = ''
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
      runtime_type   = "io.containerd.runc.v2"
      runtime_engine = "${runcBin}"

    [dns]
      resolv_conf = "/etc/dnsmasq-resolv.conf"
  '';

  mergedConfig =
    if baseConfig == ""
    then overrides
    else baseConfig + "\n\n" + overrides;
in {
  options.blackmatter.components.kubernetes.services.containerd = {
    enable = mkEnableOption "Enable the containerd service";
    configPath = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "If set, use this file instead of our generated config.toml";
    };
    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra flags to append to the containerd daemon command line";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkg pkgs.runc];
    systemd.tmpfiles.rules = [
      "d /etc/containerd 0755 root root -"
      "d /run/containerd 0755 root root -"
    ];

    # Only one entry here—no nulls!
    environment.etc."containerd/config.toml" =
      if cfg.configPath != null
      then [{source = cfg.configPath;}]
      else [{text = mergedConfig;}];

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
