# modules/kubernetes/services/kubelet/options.nix
{lib, ...}: {
  options.blackmatter.components.kubernetes.services.kubelet = {
    enable = lib.mkEnableOption "Run the kubelet service";
  };
}
