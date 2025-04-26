# hive.nix
{
  meta = {
    nixpkgs = import <nixpkgs> {};
  };

  master = {
    config,
    pkgs,
    ...
  }: {
    imports = [
      ./modules
    ];

    kubernetes.enable = true;
    networking.hostName = "master";
    system.stateVersion = "24.05";
  };
}
