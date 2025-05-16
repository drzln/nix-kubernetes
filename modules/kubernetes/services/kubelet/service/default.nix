# modules/kubernetes/services/kubelet/service/default.nix
{...}: {
  imports = [
    ./config.nix
    ./tmpfiles.nix
    ./service.nix
    ./activation.nix
  ];
}
