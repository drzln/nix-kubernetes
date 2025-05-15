{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  # cfg = config.blackmatter.components.kubernetes;
  # blackmatterPkgs = import ../../pkgs {
  #   callPackage = pkgs.callPackage;
  # };
  # service = name:
  #   import (./services + "/${name}") {
  #     inherit lib config pkgs blackmatterPkgs;
  #   };
in {
  imports = [
    ./services/containerd
    ./services/kubelet
    # (service "containerd")
    # (service "kubelet")
    # (service "etcd")
    # Add others here as you wire them:
    # (service "kube-apiserver")
    # (service "cilium-agent")
  ];
  options.blackmatter.components.kubernetes = {
    enable = mkEnableOption "Enable Kubernetes";
    role = mkOption {
      type = types.enum ["master" "worker" "single"];
      default = "master";
      description = "The role this node will play in the cluster.";
    };
  };
  # config = mkIf cfg.enable ({
  #     assertions = [
  #       {
  #         assertion = cfg.role != null;
  #         message = "You must specify a valid Kubernetes role.";
  #       }
  #     ];
  #     environment.systemPackages = [
  #       blackmatterPkgs.kubectl
  #       blackmatterPkgs.containerd
  #       pkgs.runc
  #       pkgs.cri-tools
  #     ];
  #   }
  #   // mkIf (cfg.role == "single") {
  #     blackmatter.components.kubernetes.services.containerd.enable = true;
  #     blackmatter.components.kubernetes.services.kubelet = {
  #       enable = true;
  #     };
  #     blackmatter.components.kubernetes.services.etcd.enable = false;
  #     systemd.services.kubernetes-single-hint = {
  #       description = "hint: running in single-node mode";
  #       wantedBy = ["multi-user.target"];
  #       serviceConfig.ExecStart = "${pkgs.coreutils}/bin/echo single node mode enabled";
  #     };
  #   });
}
