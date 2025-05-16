# modules/kubernetes/services/kubelet/static-pods/cilium/default.nix
{
  config,
  pkgs,
  lib,
  ...
}: {
  options.blackmatter.components.kubernetes.kubelet.static-pods.cilium.enable =
    lib.mkEnableOption "Enable Cilium as static pod";
  config = lib.mkIf config.blackmatter.components.kubernetes.kubelet.static-pods.cilium.enable {
    environment.etc."kubernetes/manifests/cilium.yaml".source = import ./manifest.nix {inherit config pkgs lib;};
  };
}
