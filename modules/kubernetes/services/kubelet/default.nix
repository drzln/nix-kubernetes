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
    (import ./service.nix {
      inherit lib pkgs cfg blackmatterPkgs;
    })

    (import ./assets.nix {
      inherit lib pkgs;
      cfg = cfg;
    })

    (lib.mkIf cfg.staticControlPlane.enable (
      lib.mkMerge (
        (import ./static-pods.nix {inherit lib cfg;})
        ++ [
          {
            networking.firewall.allowedTCPPorts = [
              10257
              10259
              6443
              2379
              2380
            ];
          }
        ]
      )
    ))
  ]);
}
