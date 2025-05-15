# modules/kubernetes/services/kubelet/pod-lib.nix
{pkgs, ...}: let
  # Create JSON manifest file from podSpec
  manifestFile = name: podSpec:
    pkgs.writeText name (builtins.toJSON podSpec);

  # Common base volume definitions
  volumes = {
    pki = pkiPath: {
      name = "pki";
      hostPath = {
        path = pkiPath;
        type = "DirectoryOrCreate";
      };
    };

    kubeconfig = kubeconfigPath: {
      name = "kubeconfig";
      hostPath = {
        path = kubeconfigPath;
        type = "File";
      };
    };
  };

  # Common container volume mount definitions
  volumeMounts = {
    pki = mountPath: {
      name = "pki";
      mountPath = mountPath;
      readOnly = true;
    };

    kubeconfig = mountPath: {
      name = "kubeconfig";
      mountPath = mountPath;
      readOnly = true;
    };
  };

  # Base Pod constructor
  mkPod = {
    name,
    image,
    command,
    podVolumes ? [],
    containerVolumeMounts ? [],
    hostNetwork ? true,
    extraOpts ? {},
  }: {
    apiVersion = "v1";
    kind = "Pod";
    metadata = {inherit name;};
    spec =
      {
        inherit hostNetwork;
        containers = [
          {
            inherit name image command;
            volumeMounts = containerVolumeMounts;
          }
        ];
        volumes = podVolumes;
      }
      // extraOpts;
  };
in {
  inherit manifestFile;

  # ETCD pod specification
  mkEtcdPod = {
    pki,
    image,
  }:
    mkPod {
      name = "etcd";
      inherit image;
      command = [
        "etcd"
        "--name=node0"
        "--data-dir=/var/run/etcd"
        "--advertise-client-urls=https://0.0.0.0:2379"
        "--listen-client-urls=https://0.0.0.0:2379"
        "--client-cert-auth=true"
        "--trusted-ca-file=${pki}/ca.crt"
        "--cert-file=${pki}/etcd.crt"
        "--key-file=${pki}/etcd.key"
      ];
      podVolumes = [(volumes.pki pki)];
      containerVolumeMounts = [(volumeMounts.pki pki)];
    };

  # kube-apiserver pod specification
  mkApiServerPod = {
    pki,
    svcCIDR,
    image,
  }:
    mkPod {
      name = "kube-apiserver";
      inherit image;
      command = [
        "kube-apiserver"
        "--advertise-address=0.0.0.0"
        "--secure-port=6443"
        "--etcd-servers=https://127.0.0.1:2379"
        "--etcd-cafile=${pki}/ca.crt"
        "--etcd-certfile=${pki}/apiserver.crt"
        "--etcd-keyfile=${pki}/apiserver.key"
        "--client-ca-file=${pki}/ca.crt"
        "--tls-cert-file=${pki}/apiserver.crt"
        "--tls-private-key-file=${pki}/apiserver.key"
        "--service-account-issuer=https://kubernetes.default.svc.cluster.local"
        "--service-account-signing-key-file=${pki}/sa.key"
        "--service-account-key-file=${pki}/sa.pub"
        "--service-cluster-ip-range=${svcCIDR}"
        "--authorization-mode=Node,RBAC"
      ];
      podVolumes = [(volumes.pki pki)];
      containerVolumeMounts = [(volumeMounts.pki pki)];
    };

  # kube-controller-manager pod specification
  mkControllerManagerPod = {
    pki,
    scr,
    image,
  }:
    mkPod {
      name = "kube-controller-manager";
      inherit image;
      command = [
        "kube-controller-manager"
        "--kubeconfig=${scr}/configs/controller-manager/kubeconfig"
        "--cluster-signing-cert-file=${pki}/ca.crt"
        "--cluster-signing-key-file=${pki}/ca.key"
        "--root-ca-file=${pki}/ca.crt"
        "--service-account-private-key-file=${pki}/ca.key"
      ];
      podVolumes = [
        (volumes.pki pki)
        (volumes.kubeconfig "${scr}/configs/controller-manager/kubeconfig")
      ];
      containerVolumeMounts = [
        (volumeMounts.pki pki)
        (volumeMounts.kubeconfig "${scr}/configs/controller-manager/kubeconfig")
      ];
    };

  # kube-scheduler pod specification
  mkSchedulerPod = {
    scr,
    pki,
    image,
  }:
    mkPod {
      name = "kube-scheduler";
      inherit image;
      command = [
        "kube-scheduler"
        "--kubeconfig=${scr}/configs/scheduler/kubeconfig"
      ];
      podVolumes = [
        (volumes.pki pki)
        (volumes.kubeconfig "${scr}/configs/scheduler/kubeconfig")
      ];
      containerVolumeMounts = [
        (volumeMounts.pki pki)
        (volumeMounts.kubeconfig "${scr}/configs/scheduler/kubeconfig")
      ];
    };
}
