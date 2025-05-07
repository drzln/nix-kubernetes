{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.kubernetes;
  blackmatterPkgs = pkgs.blackmatter.k8s;
  service = name:
    import (./services + "/${name}.nix") {
      inherit lib config pkgs blackmatterPkgs;
    };
in {
  imports = [
    (service "containerd")
    # Add more services like this:
    # (service "kubelet")
    # (service "etcd")
  ];

  options.blackmatter.components.kubernetes = {
    enable = mkEnableOption "Kubernetes";
    role = mkOption {
      type = types.enum ["master" "worker" "single"];
      default = "master";
      description = "role";
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
