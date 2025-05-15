# modules/kubernetes/services/kubelet/options.nix
{lib, ...}: {
  options.blackmatter.components.kubernetes.kubelet = {
    enable = lib.mkEnableOption "Run the kubelet service";
  };
}
