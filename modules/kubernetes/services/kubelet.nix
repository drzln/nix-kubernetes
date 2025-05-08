# modules/kubernetes/services/kubelet.nix
{
  lib,
  pkgs,
  config,
  blackmatterPkgs,
  ...
}: let
  inherit (lib) mkIf mkMerge mkEnableOption mkOption types concatStringsSep;
  pki = "/run/secrets/kubernetes";
  pkg = blackmatterPkgs.kubelet;
  cfg = config.blackmatter.components.kubernetes.services.kubelet;
  mkStaticPodVolumeMounts = extraMounts:
    [
      {
        name = "pki";
        mountPath = pki;
        readOnly = true;
      }
      {
        name = "etcd-data";
        mountPath = "/var/run/etcd";
      }
    ]
    ++ extraMounts;
  mkStaticPodVolumes = extraVolumes:
    [
      {
        name = "pki";
        hostPath.path = pki;
        hostPath.type = "Directory";
      }
      {
        name = "etcd-data";
        hostPath.path = "/var/run/etcd";
        hostPath.type = "DirectoryOrCreate";
      }
    ]
    ++ extraVolumes;
  mkPod = name: args: image: extra: {
    apiVersion = "v1";
    kind = "Pod";
    metadata.name = name;
    spec = {
      hostNetwork = true;
      priorityClassName = "system-cluster-critical";
      volumes = mkStaticPodVolumes (extra.volumes or []);
      containers = [
        {
          name = name;
          image = image;
          command = args;
          volumeMounts = mkStaticPodVolumeMounts (extra.volumeMounts or []);
        }
      ];
    };
  };
  manifestFile = filename: pod: {
    environment.etc."kubernetes/manifests/${filename}".text = builtins.toJSON pod;
  };
  staticManifests = let
    svcCIDR = cfg.staticControlPlane.serviceCIDR;
    images = {
      etcd = "quay.io/coreos/etcd:v3.5.9";
      kubeApiserver = "registry.k8s.io/kube-apiserver:${cfg.staticControlPlane.kubernetesVersion}";
      kubeControllerManager = "registry.k8s.io/kube-controller-manager:${cfg.staticControlPlane.kubernetesVersion}";
      kubeScheduler = "registry.k8s.io/kube-scheduler:${cfg.staticControlPlane.kubernetesVersion}";
    };
  in [
    (manifestFile "etcd.json" (mkPod "etcd" [
        "etcd"
        "--name=node0"
        "--data-dir=/var/run/etcd"
        "--advertise-client-urls=https://127.0.0.1:2379"
        "--listen-client-urls=https://0.0.0.0:2379"
        "--client-cert-auth=true"
        "--trusted-ca-file=${pki}/ca/crt"
        "--cert-file=${pki}/etcd/crt"
        "--key-file=${pki}/etcd/key"
      ]
      images.etcd {}))
    (manifestFile "kube-apiserver.json" (mkPod "kube-apiserver" [
        "kube-apiserver"
        "--advertise-address=127.0.0.1"
        "--secure-port=6443"
        "--etcd-servers=https://127.0.0.1:2379"
        "--etcd-cafile=${pki}/ca/crt"
        "--etcd-certfile=${pki}/etcd/crt"
        "--etcd-keyfile=${pki}/etcd/key"
        "--client-ca-file=${pki}/ca/crt"
        "--tls-cert-file=${pki}/apiserver/crt"
        "--tls-private-key-file=${pki}/apiserver/key"
        "--service-cluster-ip-range=${svcCIDR}"
        "--service-account-issuer=https://kubernetes.default.svc"
        "--service-account-key-file=${pki}/ca/crt"
        "--service-account-signing-key-file=${pki}/ca/key"
        "--authorization-mode=Node,RBAC"
      ]
      images.kubeApiserver {}))
    (manifestFile "kube-controller-manager.json" (mkPod "kube-controller-manager" [
        "kube-controller-manager"
        "--kubeconfig=${pki}/configs/controller-manager/kubeconfig"
        "--cluster-signing-cert-file=${pki}/ca/crt"
        "--cluster-signing-key-file=${pki}/ca/key"
        "--root-ca-file=${pki}/ca/crt"
        "--service-account-private-key-file=${pki}/ca/key"
        "--controllers=*,bootstrapsigner,tokencleaner"
      ]
      images.kubeControllerManager {
        volumes = [
          {
            name = "kubeconfig";
            hostPath.path = "${pki}/configs/controller-manager/kubeconfig";
            hostPath.type = "File";
          }
        ];
        volumeMounts = [
          {
            name = "kubeconfig";
            mountPath = "${pki}/configs/controller-manager/kubeconfig";
            readOnly = true;
          }
        ];
      }))
    (manifestFile "kube-scheduler.json" (mkPod "kube-scheduler" [
        "kube-scheduler"
        "--kubeconfig=${pki}/configs/scheduler/kubeconfig"
      ]
      images.kubeScheduler {
        volumes = [
          {
            name = "kubeconfig";
            hostPath.path = "${pki}/configs/scheduler/kubeconfig";
            hostPath.type = "File";
          }
        ];
        volumeMounts = [
          {
            name = "kubeconfig";
            mountPath = "${pki}/configs/scheduler/kubeconfig";
            readOnly = true;
          }
        ];
      }))
    {}
  ];
in {
  options.blackmatter.components.kubernetes.services.kubelet = {
    enable = mkEnableOption "Run the kubelet service";
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
  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = [pkg];
      systemd.tmpfiles.rules = [
        "d /etc/kubernetes/manifests 0755 root root -"
        "d /etc/kubernetes/kubelet   0755 root root -"
        "d /etc/cni/net.d            0755 root root -"
        "d /var/run/etcd             0700 root root -"
      ];
      systemd.services.kubelet = {
        description = "blackmatter.kubelet";
        after = ["network.target" "containerd.service" "systemd-tmpfiles-setup.service"];
        wantedBy = ["multi-user.target"];
        environment.PATH = lib.mkForce (lib.makeBinPath [
          pkg
          pkgs.runc
          pkgs.iproute2
          pkgs.coreutils
          pkgs.util-linux
          pkgs.containerd
          blackmatterPkgs.cilium-cni
        ]);
        serviceConfig = {
          User = "root";
          ExecStart = concatStringsSep " " ([
              "${pkg}/bin/kubelet"
              "--config=${pki}/configs/kubelet/config"
              "--kubeconfig=${pki}/configs/kubelet/kubeconfig"
            ]
            ++ cfg.extraFlags);
          Restart = "always";
          RestartSec = 2;
          KillMode = "process";
          Delegate = true;
          LimitNOFILE = 1048576;
          CapabilityBoundingSet = ["CAP_SYSLOG" "CAP_SYS_ADMIN"];
          AmbientCapabilities = ["CAP_SYSLOG" "CAP_SYS_ADMIN"];
          DeviceAllow = ["/dev/kmsg r"];
          PrivateDevices = false;
          ProtectKernelLogs = false;
        };
      };
    }
    (mkIf cfg.staticControlPlane.enable (mkMerge (
      staticManifests
      ++ [
        {networking.firewall.allowedTCPPorts = [6443 2379 2380 10257 10259];}
      ]
    )))
  ]);
}
