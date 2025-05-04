{
  lib,
  config,
  ...
} @ args: let
  cfg = config.blackmatter.components.kubernetes;
  # inherit (lib) mkIf mkMerge;
  isMaster = cfg.role == "master" || cfg.role == "single";
  isWorker = cfg.role == "worker";
in {
  imports =
    [
      # ./options.nix
      # ./pkgs.nix
      # ./assertions.nix
      # ./files.nix
      # ./firewall.nix

      # ./services/containerd.nix
      # ./services/kubelet.nix
      # ./services/kubeadm.nix
      # ./services/proxy.nix
    ]
    ++ lib.optional isWorker [
    ]
    ++ lib.optional isMaster [
      # ./services/etcd.nix
      # ./services/apiserver.nix
      # ./services/controller.nix
      # ./services/scheduler.nix
    ];
}
