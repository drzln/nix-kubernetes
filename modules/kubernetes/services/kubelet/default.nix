# modules/kubernetes/services/kubelet/default.nix
{...}: {
  imports = [
    ./options.nix
    # ./certs.nix
    # ./service.nix
    # ./static-pods.nix
  ];
}
