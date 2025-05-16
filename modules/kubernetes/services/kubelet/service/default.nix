# modules/kubernetes/services/kubelet/service/default.nix
{...}: {
  imports = [
    ./config.nix
    ./service.nix
    ./tmpfiles.nix
    ./activation.nix
  ];
}
