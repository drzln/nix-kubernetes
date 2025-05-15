# modules/kubernetes/services/kubelet/pod-lib.nix
{pkgs, ...}: rec {
  # Writes a JSON manifest file from a podSpec
  manifestFile = name: podSpec:
    pkgs.writeText name (builtins.toJSON podSpec);

  # Base Pod constructor
  mkPod = pki: name: args: image: extraOpts:
    {
      apiVersion = "v1";
      kind = "Pod";
      metadata = {inherit name;};
      spec = {
        containers = [
          {
            inherit name image;
            command = args;
            volumeMounts = [
              {
                name = "pki";
                mountPath = pki;
                readOnly = true;
              }
            ];
          }
        ];
        hostNetwork = true;
        volumes = [
          {
            name = "pki";
            hostPath.path = pki;
            hostPath.type = "DirectoryOrCreate";
          }
        ];
      };
    }
    // extraOpts;

  # etcd pod specification
  mkEtcdPod = pki: image:
    mkPod pki "etcd" [
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
    image {};

  # kube-apiserver pod specification
  mkApiServerPod = pki: svcCIDR: image:
    mkPod pki "kube-apiserver" [
      "kube-apiserver"
      "--advertise-address=127.0.0.1"
      "--secure-port=6443"
      "--etcd-servers=https://127.0.0.1:2379"
      "--client-ca-file=${pki}/ca.crt"
      "--tls-cert-file=${pki}/apiserver.crt"
      "--tls-private-key-file=${pki}/apiserver.key"
      "--service-account-issuer=https://kubernetes.default.svc.cluster.local"
      "--service-account-signing-key-file=${pki}/sa.key"
      "--service-account-key-file=${pki}/sa.pub"
      "--service-cluster-ip-range=${svcCIDR}"
      "--authorization-mode=Node,RBAC"
    ]
    image {};

  # kube-controller-manager pod specification
  mkControllerManagerPod = pki: scr: image:
    mkPod pki "kube-controller-manager" [
      "kube-controller-manager"
      "--kubeconfig=${scr}/configs/controller-manager/kubeconfig"
      "--cluster-signing-cert-file=${pki}/ca.crt"
      "--cluster-signing-key-file=${pki}/ca.key"
      "--root-ca-file=${pki}/ca.crt"
      "--service-account-private-key-file=${pki}/ca.key"
    ]
    image {
      spec = {
        volumes = [
          {
            name = "kubeconfig";
            hostPath = {
              path = "${scr}/configs/controller-manager/kubeconfig";
              type = "File";
            };
          }
        ];
        containers = [
          {
            name = "kube-controller-manager";
            volumeMounts = [
              {
                name = "kubeconfig";
                mountPath = "${scr}/configs/controller-manager/kubeconfig";
                readOnly = true;
              }
            ];
          }
        ];
      };
    };

  # kube-scheduler pod specification
  mkSchedulerPod = scr: image:
    mkPod "/dev/null" "kube-scheduler" [
      "kube-scheduler"
      "--kubeconfig=${scr}/configs/scheduler/kubeconfig"
    ]
    image {
      spec = {
        volumes = [
          {
            name = "kubeconfig";
            hostPath = {
              path = "${scr}/configs/scheduler/kubeconfig";
              type = "File";
            };
          }
        ];
        containers = [
          {
            name = "kube-scheduler";
            volumeMounts = [
              {
                name = "kubeconfig";
                mountPath = "${scr}/configs/scheduler/kubeconfig";
                readOnly = true;
              }
            ];
          }
        ];
      };
    };
}
