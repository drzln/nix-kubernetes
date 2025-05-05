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
      description = "node type";
    };

    # nodePortRange = mkOption {
    #   type = types.nullOr types.str;
    #   default = null;
    #   example = "30000-32767";
    # };

    # extraApiArgs = mkOption {
    #   type = types.listOf types.str;
    #   default = [];
    # };

    # extraKubeletOpts = mkOption {
    #   type = types.listOf types.str;
    #   default = [];
    # };

    # kubeadmExtra = mkOption {
    #   type = types.str;
    #   default = "";
    # };
    
    # firewallOpen = mkOption {
    #   type = types.bool;
    #   default = false;
    #   description = "Open all required Kubernetes ports on the host firewall.";
    # };

    # join.address = mkOption {
    #   type = types.str;
    #   default = "";
    # };

    # join.token = mkOption {
    #   type = types.str;
    #   default = "";
    # };

    # join.caHash = mkOption {
    #   type = types.str;
    #   default = "";
    # };
  };
  config =
    mkIf cfg.enable {
      imports = [
        ./services/containerd.nix;
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
