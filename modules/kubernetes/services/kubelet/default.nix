# modules/kubernetes/services/kubelet/default.nix
{...}: {
  imports = [
    ./options.nix
    ./certs.nix
    ./service.nix
    # ./static-pods.nix
  ];
  # config.blackmatter.components.kubernetes.services.kubelet = {
  #   enable = false;
  #   staticControlPlane.enable = false;
  # };
}
