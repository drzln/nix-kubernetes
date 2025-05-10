# modules/kubernetes/services/kubelet/default.nix
{
  lib,
  pkgs,
  config,
  blackmatterPkgs,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.services.kubelet;
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (import ./service.nix {inherit lib pkgs cfg blackmatterPkgs;})
    (lib.mkIf cfg.staticControlPlane.enable (
      lib.mkMerge (
        (import ./static-pods.nix {inherit lib cfg;})
        ++ [{networking.firewall.allowedTCPPorts = [6443 2379 2380 10257 10259];}]
      )
    ))
  ]);
}
