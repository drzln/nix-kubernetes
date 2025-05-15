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
  svcCIDR = cfg.serviceCIDR;
  version = cfg.kubernetesVersion;

  images = {
    etcd = "quay.io/coreos/etcd:v3.5.9";
    kubeApiserver = "registry.k8s.io/kube-apiserver:${version}";
    kubeControllerManager = "registry.k8s.io/kube-controller-manager:${version}";
    kubeScheduler = "registry.k8s.io/kube-scheduler:${version}";
  };

  podLib = import ./pod-lib.nix {inherit lib;};

  manifests = {
    "etcd.json" = podLib.manifestFile "etcd.json" (podLib.mkPod pki "etcd" [
        "etcd"
        "--name=node0"
        "--data-dir=/var/run/etcd"
        "--advertise-client-urls=https://127.0.0.1:2379"
        "--listen-client-urls=https://0.0.0.0:2379"
        "--client-cert-auth=true"
        "--trusted-ca-file=${pki}/ca.crt"
        "--cert-file=${pki}/etcd.crt"
        "--key-file=${pki}/etcd.key"
      ]
      images.etcd {});

    "kube-apiserver.json" = podLib.manifestFile "kube-apiserver.json" (podLib.mkPod pki "kube-apiserver" [
        "kube-apiserver"
        "--kubelet-client-certificate=${pki}/apiserver.crt"
        "--kubelet-client-key=${pki}/apiserver.key"
        "--kubelet-certificate-authority=${pki}/ca.crt"
        "--kubelet-preferred-address-types=InternalIP,Hostname,InternalDNS,ExternalIP"
        "--advertise-address=127.0.0.1"
        "--secure-port=6443"
        "--etcd-servers=https://127.0.0.1:2379"
        "--etcd-cafile=${pki}/ca.crt"
        "--etcd-certfile=${pki}/etcd.crt"
        "--etcd-keyfile=${pki}/etcd.key"
        "--client-ca-file=${pki}/ca.crt"
        "--tls-cert-file=${pki}/apiserver.crt"
        "--tls-private-key-file=${pki}/apiserver.key"
        "--service-cluster-ip-range=${svcCIDR}"
        "--service-account-issuer=https://kubernetes.default.svc"
        "--service-account-key-file=${pki}/ca.crt"
        "--service-account-signing-key-file=${pki}/ca.key"
        "--authorization-mode=Node,RBAC"
      ]
      images.kubeApiserver {});

    "kube-controller-manager.json" = podLib.manifestFile "kube-controller-manager.json" (podLib.mkPod pki "kube-controller-manager" [
        "kube-controller-manager"
        "--kubeconfig=${scr}/configs/controller-manager/kubeconfig"
        "--cluster-signing-cert-file=${pki}/ca.crt"
        "--cluster-signing-key-file=${pki}/ca.key"
        "--root-ca-file=${pki}/ca.crt"
        "--service-account-private-key-file=${pki}/ca.key"
        "--controllers=*,bootstrapsigner,tokencleaner"
      ]
      images.kubeControllerManager {
        volumes = [
          {
            name = "kubeconfig";
            hostPath.path = "${scr}/configs/controller-manager/kubeconfig";
            hostPath.type = "File";
          }
        ];
        volumeMounts = [
          {
            name = "kubeconfig";
            mountPath = "${scr}/configs/controller-manager/kubeconfig";
            readOnly = true;
          }
        ];
      });

    "kube-scheduler.json" = podLib.manifestFile "kube-scheduler.json" (podLib.mkPod pki "kube-scheduler" [
        "kube-scheduler"
        "--kubeconfig=${scr}/configs/scheduler/kubeconfig"
      ]
      images.kubeScheduler {
        volumes = [
          {
            name = "kubeconfig";
            hostPath.path = "${scr}/configs/scheduler/kubeconfig";
            hostPath.type = "File";
          }
        ];
        volumeMounts = [
          {
            name = "kubeconfig";
            mountPath = "${scr}/configs/scheduler/kubeconfig";
            readOnly = true;
          }
        ];
      });
  };

  manifestsDir = "/etc/kubernetes/manifests";
in {
  options.blackmatter.components.kubernetes.kubelet.static-pods = {
    enable = lib.mkEnableOption "Generate static pod manifests as systemd service";
    kubernetesVersion = lib.mkOption {
      type = lib.types.str;
      default = "v1.30.1";
      description = "Control plane image version.";
    };
    serviceCIDR = lib.mkOption {
      type = lib.types.str;
      default = "10.96.0.0/12";
      description = "Service IP range for the cluster.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.static-pods = {
      description = "Generate static Kubernetes pod manifests";
      wantedBy = ["multi-user.target"];
      before = ["kubelet.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${manifestsDir}";
        ExecStart = lib.concatMapStringsSep "\n" (
          file: let
            manifest = manifests.${file};
          in "${pkgs.coreutils}/bin/install -m644 ${manifest.source} ${manifestsDir}/${file}"
        ) (builtins.attrNames manifests);
      };
    };
  };
}
