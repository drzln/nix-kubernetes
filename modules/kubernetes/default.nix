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
  config = mkIf cfg.enable ({
      assertions = [
        {
          assertion = cfg.role != null;
          message = "You must specify a valid Kubernetes role.";
        }
      ];

      environment.systemPackages = [
        pkgs.blackmatter.k8s.kubectl
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
