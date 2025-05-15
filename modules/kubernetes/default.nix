# modules/kubernetes/default.nix
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.kubernetes;

  # Internal encapsulation of your custom packages via your overlay
  blackmatterPkgs = import ../../overlays/blackmatter-k8s.nix pkgs pkgs;

  # Helper function now simplified (no need to explicitly pass args here)
  service = name: ./services + "/${name}";
in {
  imports = [
    (service "containerd")
    (service "kubelet")
    (service "etcd")
  ];

  options.blackmatter.components.kubernetes = {
    enable = mkEnableOption "Enable Kubernetes";
    role = mkOption {
      type = types.enum ["master" "worker" "single"];
      default = "master";
      description = "The role this node will play in the cluster.";
    };
  };

  # Pass internal packages explicitly down to all imported modules
  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.role != null;
          message = "You must specify a valid Kubernetes role.";
        }
      ];

      environment.systemPackages = [
        blackmatterPkgs.blackmatter.k8s.kubectl
        blackmatterPkgs.blackmatter.k8s.containerd
        pkgs.runc
        pkgs.cri-tools
      ];

      # Explicitly expose blackmatterPkgs internally via _module.args
      _module.args.blackmatterPkgs = blackmatterPkgs;
    }

    # Node role-specific configuration
    (mkIf (cfg.role == "single") {
      blackmatter.components.kubernetes.services.containerd.enable = true;
      blackmatter.components.kubernetes.kubelet.enable = false;
      # blackmatter.components.kubernetes.services.etcd.enable = false;

      systemd.services.kubernetes-single-hint = {
        description = "Hint: Kubernetes is running in single-node mode";
        wantedBy = ["multi-user.target"];
        serviceConfig.ExecStart = "${pkgs.coreutils}/bin/echo 'Single-node mode enabled'";
      };
    })
  ]);
}
