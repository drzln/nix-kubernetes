# modules/kubernetes/services/kubelet/default.nix
{...}: {
  imports = [
    ./options.nix
    ./assets.nix
    ./service.nix
    ./static-pods.nix
  ];

  config.blackmatter.components.kubernetes.services.kubelet = {
    enable = false;
    assets.enable = false;
    service.enable = false;
    static-pods.enable = false;
    staticControlPlane.enable = false;
  };
}
