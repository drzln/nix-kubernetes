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
      environment.systemPackages = [
        blackmatterPkgs.blackmatter.k8s.kubectl
        blackmatterPkgs.blackmatter.k8s.containerd
        pkgs.runc
        pkgs.cri-tools
      ];
      _module.args.blackmatterPkgs = blackmatterPkgs;
    }
    (mkIf (cfg.role == "single") {
      blackmatter.components.kubernetes.containerd.enable = true;
      blackmatter.components.kubernetes.kubelet.enable = true;
    })
  ]);
}
