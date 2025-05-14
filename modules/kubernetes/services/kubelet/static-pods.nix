# modules/kubernetes/services/kubelet/static-pods.nix
{
  lib,
  cfg,
  ...
}: let
  scr = "/run/secrets/kubernetes";
  pki = "/var/lib/blackmatter/certs";
  svcCIDR = cfg.staticControlPlane.serviceCIDR;
  version = cfg.staticControlPlane.kubernetesVersion;
  images = {
    etcd = "quay.io/coreos/etcd:v3.5.9";
    kubeApiserver = "registry.k8s.io/kube-apiserver:${version}";
    kubeControllerManager = "registry.k8s.io/kube-controller-manager:${version}";
    kubeScheduler = "registry.k8s.io/kube-scheduler:${version}";
  };
  podLib = import ./pod-lib.nix {inherit lib;};
in [
  (podLib.manifestFile "etcd.json" (podLib.mkPod pki "etcd" [
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
    images.etcd {}))
  (podLib.manifestFile "kube-apiserver.json" (podLib.mkPod pki "kube-apiserver" [
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
    images.kubeApiserver {}))
  (podLib.manifestFile "kube-controller-manager.json" (podLib.mkPod pki "kube-controller-manager" [
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
    }))
  (podLib.manifestFile "kube-scheduler.json" (podLib.mkPod pki "kube-scheduler" [
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
    }))
]
