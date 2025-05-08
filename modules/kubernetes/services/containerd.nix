# modules/kubernetes/services/containerd.nix
{
  lib,
  pkgs,
  config,
  blackmatterPkgs,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.services.containerd;
  pkg = blackmatterPkgs.containerd;
  runcBin = "${pkgs.runc}/bin/runc";

  # Read in the default containerd config and append your overrides
  baseConfig = builtins.readFile "${pkg}/etc/containerd/config.toml";
  dnsOverrides = ''
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
      runtime_type   = "io.containerd.runc.v2"
      runtime_engine = "${runcBin}"

    [dns]
      # Point at the file dnsmasq populates with real upstream servers
      resolv_conf = "/etc/dnsmasq-resolv.conf"
  '';
  mergedConfig = lib.concatStringsSep "\n\n" [baseConfig dnsOverrides];
in {
  options.blackmatter.components.kubernetes.services.containerd = {
    enable = lib.mkEnableOption "Enable the containerd service";
    configPath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to override /etc/containerd/config.toml (if you want something totally custom)";
    };
    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra flags to pass to `containerd` on startup.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkg pkgs.runc];
    # Drop in our merged config.toml
    environment.etc."containerd/config.toml".text = mergedConfig;

    # Make sure your dnsmasq upstream file exists where we expect it:
    # (dnsmasq by default writes /etc/dnsmasq-resolv.conf with the real nameservers)
    # If your dnsmasq is configured differently, point here at its resolv-file.
    # No need to touch /etc/resolv.conf—pods will still see the stub, but containerd
    # will use the real upstream list.

    systemd.services.containerd = {
      description = "blackmatter.containerd";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = lib.concatStringsSep " " (
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
        # make sure both containerd *and* runc are on $PATH
        PATH = lib.mkForce (lib.makeBinPath [pkg pkgs.runc pkgs.iproute2 pkgs.coreutils]);
      };
    };
  };
}
