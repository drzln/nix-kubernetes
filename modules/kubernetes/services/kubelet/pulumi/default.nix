{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.kubelet.pulumi;
  pulumiScript = pkgs.writeShellScript "run-pulumi" ''
    export KUBECONFIG=${cfg.kubeconfigPath}
    ${cfg.pulumiBin}/bin/pulumi login ${cfg.pulumiBackend}
    cd ${cfg.projectDir}
    ${cfg.pulumiBin}/bin/pulumi up --yes --non-interactive
  '';
in {
  options.blackmatter.components.kubernetes.kubelet.pulumi = {
    enable = lib.mkEnableOption "Enable automatic Pulumi provisioning after Kubernetes is ready";

    projectDir = lib.mkOption {
      type = lib.types.path;
      description = "The path to your Pulumi Golang project's root directory";
    };

    kubeconfigPath = lib.mkOption {
      type = lib.types.str;
      default = "/run/secrets/kubernetes/configs/admin/kubeconfig";
      description = "Path to the kubeconfig for Pulumi to use";
    };

    pulumiBin = lib.mkOption {
      type = lib.types.package;
      default = pkgs.pulumi;
      description = "The Pulumi binary package to use";
    };

    pulumiBackend = lib.mkOption {
      type = lib.types.str;
      default = "file:///var/lib/pulumi-state";
      description = "Pulumi backend URL (local file-based or cloud-based)";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.pulumi-provision = {
      description = "Pulumi provisioning after Kubernetes is ready";
      wantedBy = ["multi-user.target"];
      after = [
        "kubelet.service"
        "static-pods.service"
        "network-online.target"
      ];
      wants = ["kubelet.service" "network-online.target"];

      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = ''
          # Wait for Kubernetes API to be reachable and ready
          until ${pkgs.kubernetes}/bin/kubectl --kubeconfig=${cfg.kubeconfigPath} get nodes >/dev/null 2>&1; do
            echo "[Pulumi] Waiting for Kubernetes API..."
            sleep 3
          done
        '';

        ExecStart = "${pulumiScript}";

        Environment = [
          "PATH=${lib.makeBinPath [
            pkgs.kubernetes
            pkgs.git
            pkgs.openssh
            pkgs.openssl
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.gnused
            pkgs.curl
          ]}"
        ];
      };
    };
  };
}
