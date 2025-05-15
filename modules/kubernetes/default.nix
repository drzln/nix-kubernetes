# modules/kubernetes/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.kubernetes;
  blackmatterPkgs = import ../../overlays/blackmatter-k8s.nix pkgs pkgs;
  service = name: ./services + "/${name}";
in {
  imports = [
    (service "containerd")
    (service "kubelet")
    ./crictl.nix
  ];
  options.blackmatter.components.kubernetes = {
    enable = mkEnableOption "Enable Kubernetes";
    role = mkOption {
      type = types.enum ["master" "worker" "single"];
      default = "master";
      description = "The role this node will play in the cluster.";
    };
  };
  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.role != null;
          message = "You must specify a valid Kubernetes role.";
        }
      ];
      environment.sessionVariables = {
        KUBECONFIG = "/run/secrets/kubernetes/configs/admin/kubeconfig";
      };
      environment.systemPackages = with pkgs;[
        blackmatterPkgs.blackmatter.k8s.kubectl
        blackmatterPkgs.blackmatter.k8s.containerd
        runc
        cri-tools
        go
        delve
        gopls
        pulumi
        pulumictl
        pulumi-esc
        pulumi-bin
        pulumiPackages.pulumi-go
        pulumiPackages.pulumi-command
        pulumiPackages.pulumi-aws-native
        pulumiPackages.pulumi-kubernetes
        pulumiPackages.pulumi-python
      ];
      _module.args.blackmatterPkgs = blackmatterPkgs;
    }
    (mkIf (cfg.role == "single") {
      blackmatter.components.kubernetes.containerd.enable = true;
      blackmatter.components.kubernetes.kubelet.enable = true;
    })
  ]);
}
