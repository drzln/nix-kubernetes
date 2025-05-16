# modules/kubernetes/services/kubelet/default.nix
{
  lib,
  config,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.kubelet;
in {
  imports = [
    ./cleanup
    ./service
    ./certs.nix
    ./static-assets
  ];
  options.blackmatter.components.kubernetes.kubelet = {
    enable = lib.mkEnableOption "Run the kubelet service";
  };
  config = lib.mkIf cfg.enable {
    blackmatter.components.kubernetes.kubelet.certs.enable = true;
    blackmatter.components.kubernetes.kubelet.service.enable = true;
    blackmatter.components.kubernetes.kubelet.cleanup.enable = true;
    blackmatter.components.kubernetes.kubelet.static-assets.enable = true;
  };
}
