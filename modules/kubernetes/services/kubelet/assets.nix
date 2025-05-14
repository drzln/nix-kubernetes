# modules/kubernetes/services/kubelet/assets.nix
{
  config,
  lib,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.services.kubelet.assets;
in {
  options.blackmatter.components.kubernetes.services.kubelet.assets.enable = lib.mkEnableOption "Kubelet asset generation";

  config = lib.mkIf cfg.enable {
    imports = [./certs.nix];
  };
}
