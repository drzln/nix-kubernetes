{
  lib,
  config,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes;
in {
  # imports =
  #   [
  #     # ./options.nix
  #     # ./pkgs.nix
  #     # ./assertions.nix
  #     # ./files.nix
  #     # ./firewall.nix
  #     # ./services/etcd.nix
  #     # ./services/apiserver.nix
  #     # ./services/controller.nix
  #     # ./services/scheduler.nix
  #     # ./services/containerd.nix
  #     # ./services/kubelet.nix
  #     # ./services/kubeadm.nix
  #     # ./services/proxy.nix
  #   ];
}
