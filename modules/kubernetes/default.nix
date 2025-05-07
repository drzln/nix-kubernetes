{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.kubernetes;

  # Load your prebuilt Kubernetes binaries
  blackmatterPkgs = import ../../pkgs {inherit pkgs;};

  # Helper to import service modules with blackmatterPkgs injected
  service = name:
    import (./services + "/${name}.nix") {
      inherit lib config pkgs blackmatterPkgs;
    };
in {
  imports = [
    (service "containerd")
    # Add others here as you wire them:
    # (service "kubelet")
    # (service "kube-apiserver")
    # (service "etcd")
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

  config = mkIf cfg.enable ({
      assertions = [
        {
          assertion = cfg.role != null;
          message = "You must specify a valid Kubernetes role.";
        }
      ];

      environment.systemPackages = [
        blackmatterPkgs.kubectl
      ];
    }
    // mkIf (cfg.role == "single") {
      blackmatter.components.kubernetes.services.containerd.enable = true;

      systemd.services.kubernetes-single-hint = {
        description = "hint: running in single-node mode";
        wantedBy = ["multi-user.target"];
        serviceConfig.ExecStart = "${pkgs.coreutils}/bin/echo single node mode enabled";
      };
    });
}
