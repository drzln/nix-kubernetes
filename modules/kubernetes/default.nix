# modules/kubernetes/default.nix
{
  lib,
  # config,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.kubernetes;
in {
  imports = [
    ./services/containerd.nix
  ];

  options.blackmatter.components.kubernetes = {
    enable = mkEnableOption "Kubernetes";

    role = mkOption {
      type = types.enum ["master" "worker" "single"];
      default = "master";
      description = "node type";
    };
  };
  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.role != null;
        message = "You must specify a valid Kubernetes role.";
      }
    ];
  };
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
