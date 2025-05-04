{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.kubernetes;
in {
  options.blackmatter.components.kubernetes = {
    enable = mkEnableOption "Kubernetes";

    role = mkOption {
      type = types.enum ["master" "worker" "single"];
      default = "master";
      description = "What part of the cluster this node should run.";
    };

    overlay = mkOption {
      type = types.nullOr types.anything;
      default = null;
      description = "Optional Nixpkgs overlay that will be applied to the cluster packages.";
    };

    etcdPackage = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = "Custom etcd build to use instead of the default.";
    };

    containerdPackage = mkOption {
      type = types.nullOr types.package;
      default = null;
    };

    nodePortRange = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "30000-32767";
    };

    extraApiArgs = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    extraKubeletOpts = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    kubeadmExtra = mkOption {
      type = types.str;
      default = "";
    };

    firewallOpen = mkOption {
      type = types.bool;
      default = false;
      description = "Open all required Kubernetes ports on the host firewall.";
    };

    join.address = mkOption {
      type = types.str;
      default = "";
    };
    join.token = mkOption {
      type = types.str;
      default = "";
    };
    join.caHash = mkOption {
      type = types.str;
      default = "";
    };
  };
  config =
    mkIf cfg.enable {
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
