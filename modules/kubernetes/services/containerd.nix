{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  pkg = pkgs.blackmatter.k8s.containerd;
  cfg = config.blackmatter.components.kubernetes.services.containerd;
in {
  options.blackmatter.components.kubernetes.services.containerd = {
    enable = mkEnableOption "containerd";
  };

  config = mkIf cfg.enable {
    systemd.services.containerd = {
      description = "blackmatter.containerd";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = "${pkg}/bin/containerd";
        Restart = "always";
        RestartSec = 2;
        LimitNOFILE = 1048576;
        Delegate = true;
        KillMode = "process";
      };
      environment = {
        PATH = lib.makeBinPath [pkg pkgs.iproute2 pkgs.coreutils];
      };
    };
    environment.systemPackages = [pkg];
    systemd.tmpfiles.rules = [
      "d /etc/containerd 0755 root root -"
      "d /run/containerd 0755 root root -"
    ];
    environment.etc."containerd/config.toml".source = "${pkg}/etc/containerd/config.toml";
  };
}
