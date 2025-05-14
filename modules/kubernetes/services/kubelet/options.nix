# modules/kubernetes/services/kubelet/options.nix
{lib, ...}: let
  inherit (lib) mkEnableOption mkOption types;
in {
  options.blackmatter.components.kubernetes.services.kubelet = {
    enable = mkEnableOption "Run the kubelet service";
    generateAssets = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to run kubelet asset generation before starting the kubelet service";
    };
    assetGeneratorScript = mkOption {
      type = types.lines;
      default = "";
      description = "Shell script content to generate kubelet certs/configs";
    };
    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional CLI flags passed verbatim to kubelet.";
    };
    staticControlPlane = {
      enable = mkEnableOption "Generate static-pod manifests for etcd + control-plane components.";
      kubernetesVersion = mkOption {
        type = types.str;
        default = "v1.30.1";
        description = "Control plane image version (e.g. v1.30.1).";
      };
      serviceCIDR = mkOption {
        type = types.str;
        default = "10.96.0.0/12";
        description = "Service IP range for the cluster.";
      };
    };
  };
}
