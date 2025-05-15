# modules/kubernetes/services/kubelet/static-pods.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.kubelet.static-pods;
  scr = "/run/secrets/kubernetes";
  pki = "/var/lib/blackmatter/certs";
  manifestsDir = "/etc/kubernetes/manifests";
  podLib = import ./pod-lib.nix {inherit lib pkgs;};

  images = {
    etcd = "quay.io/coreos/etcd:v3.5.9";
    kubeApiserver = "registry.k8s.io/kube-apiserver:${cfg.kubernetesVersion}";
    kubeControllerManager = "registry.k8s.io/kube-controller-manager:${cfg.kubernetesVersion}";
    kubeScheduler = "registry.k8s.io/kube-scheduler:${cfg.kubernetesVersion}";
  };

  manifests = {
    "etcd.json" = podLib.manifestFile "etcd.json" (podLib.mkEtcdPod pki images.etcd);
    "kube-apiserver.json" = podLib.manifestFile "kube-apiserver.json" (podLib.mkApiServerPod pki cfg.serviceCIDR images.kubeApiserver);
    "kube-controller-manager.json" = podLib.manifestFile "kube-controller-manager.json" (podLib.mkControllerManagerPod pki scr images.kubeControllerManager);
    "kube-scheduler.json" = podLib.manifestFile "kube-scheduler.json" (podLib.mkSchedulerPod scr images.kubeScheduler);
  };
in {
  options.blackmatter.components.kubernetes.kubelet.static-pods = {
    enable = lib.mkEnableOption "Generate static pod manifests";
    kubernetesVersion = lib.mkOption {
      type = lib.types.str;
      default = "v1.30.1";
      description = "Kubernetes control plane version";
    };
    serviceCIDR = lib.mkOption {
      type = lib.types.str;
      default = "10.96.0.0/12";
      description = "Cluster service IP range";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.static-pods = {
      description = "Install Kubernetes static pod manifests";
      wantedBy = ["multi-user.target"];
      before = ["kubelet.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${manifestsDir}";
        ExecStart = lib.concatMapStringsSep "\n" (
          file: "${pkgs.coreutils}/bin/install -m644 ${manifests.${file}} ${manifestsDir}/${file}"
        ) (builtins.attrNames manifests);
      };
    };
  };
}
