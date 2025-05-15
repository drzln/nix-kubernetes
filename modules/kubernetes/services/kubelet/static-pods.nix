# modules/kubernetes/services/kubelet/static-pods.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.kubelet.static-pods;
  # scr = "/run/secrets/kubernetes";
  pki = "/var/lib/blackmatter/certs";
  # svcCIDR = cfg.serviceCIDR;
  # version = cfg.kubernetesVersion;

  images = {
    etcd = "quay.io/coreos/etcd:v3.5.9";
    # kubeApiserver = "registry.k8s.io/kube-apiserver:${version}";
    # kubeControllerManager = "registry.k8s.io/kube-controller-manager:${version}";
    # kubeScheduler = "registry.k8s.io/kube-scheduler:${version}";
  };

  podLib = import ./pod-lib.nix {inherit lib pkgs;};
  manifests = {
    "etcd.json" =
      podLib.manifestFile "etcd.json"
      (podLib.mkEtcdPod pki images.etcd);

    # "kube-apiserver.json" =
    #   podLib.manifestFile "kube-apiserver.json"
    #   (podLib.mkApiServerPod pki svcCIDR images.kubeApiserver);

    # "kube-controller-manager.json" =
    #   podLib.manifestFile "kube-controller-manager.json"
    #   (podLib.mkControllerManagerPod pki scr images.kubeControllerManager);

    # "kube-scheduler.json" =
    #   podLib.manifestFile "kube-scheduler.json"
    #   (podLib.mkSchedulerPod scr images.kubeScheduler);
  };
in {
  options.blackmatter.components.kubernetes.kubelet.static-pods = {
    enable = lib.mkEnableOption "Generate static pod manifests for kubelet";
    kubernetesVersion = lib.mkOption {
      type = lib.types.str;
      default = "v1.30.1";
      description = "Kubernetes control plane version.";
    };
    serviceCIDR = lib.mkOption {
      type = lib.types.str;
      default = "10.96.0.0/12";
      description = "Service IP CIDR block.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.static-pods = {
      description = "Setup static pod manifests for kubelet";
      before = ["kubelet.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;

        ExecStart = let
          manifestsDir = "/etc/kubernetes/manifests";
          copyCmds = lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              file: json: let
                jsonFile = pkgs.writeText "${file}" (builtins.toJSON json);
              in "${pkgs.coreutils}/bin/install -m644 ${jsonFile} ${manifestsDir}/${file}"
            )
            manifests
          );
        in ''
          ${pkgs.coreutils}/bin/mkdir -p ${manifestsDir}
          ${copyCmds}
        '';
      };
    };
  };
}
