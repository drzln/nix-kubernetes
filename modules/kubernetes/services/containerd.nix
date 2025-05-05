{
  lib,
  config,
  pkgs,
  ...
}: let
  containerdPkg = pkgs.blackmatter.k8s.containerd;
in {
  systemd.services.containerd = {
    description = "blackmatter.containerd";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    serviceConfig = {
      ExecStart = "${containerdPkg}/bin/containerd";
      Restart = "always";
      RestartSec = 2;
      LimitNOFILE = 1048576;
      Delegate = true;
      KillMode = "process";
    };
    environment = {
      PATH = lib.makeBinPath [containerdPkg pkgs.iproute2 pkgs.coreutils];
    };
  };
  environment.systemPackages = [containerdPkg];
  systemd.tmpfiles.rules = [
    "d /etc/containerd 0755 root root -"
    "d /run/containerd 0755 root root -"
  ];
  environment.etc."containerd/config.toml".source = "${containerdPkg}/etc/containerd/config.toml";
}
