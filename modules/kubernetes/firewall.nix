{
  lib,
  config,
  ...
}: let
  cfg = config.kubernetes;
in {
  networking.firewall = lib.mkIf cfg.firewallOpen {
    enable = true;
    allowedTCPPorts = [6443 10250];
  };
}
