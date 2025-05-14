# modules/kubernetes/services/kubelet/default.nix
{
  # lib,
  # config,
  ...
}: let
  # cfg = config.blackmatter.components.kubernetes.services.kubelet;
in {
  imports = [
    ./options.nix
    ./assets.nix
    ./service.nix
    # (lib.mkIf cfg.staticControlPlane.enable ./static-pods.nix)
  ];
}
