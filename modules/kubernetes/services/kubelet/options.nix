# modules/kubernetes/services/kubelet/options.nix
{lib, ...}: {
  options.blackmatter.components.kubernetes.services.kubelet = {
    enable = lib.mkEnableOption "Run the kubelet service";
    staticControlPlane = {
      enable = lib.mkEnableOption "Generate static-pod manifests for etcd + control-plane components.";
      kubernetesVersion = lib.mkOption {
        type = lib.types.str;
        default = "v1.30.1";
        description = "Control plane image version (e.g. v1.30.1).";
      };
      serviceCIDR = lib.mkOption {
        type = lib.types.str;
        default = "10.96.0.0/12";
        description = "Service IP range for the cluster.";
      };
    };
  };
}
