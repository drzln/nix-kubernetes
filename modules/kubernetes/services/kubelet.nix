# modules/kubernetes/services/kubelet.nix
{
  lib,
  pkgs,
  config,
  blackmatterPkgs,
  ...
}:
##############################################################################
#   kubelet service (plus optional single-node control-plane)                #
##############################################################################
let
  inherit (lib) mkIf mkMerge mkEnableOption mkOption types concatStringsSep;

  pki = "/var/lib/blackmatter/pki";
  pkg = blackmatterPkgs.kubelet;
  cfg = config.blackmatter.components.kubernetes.services.kubelet;

  # -------------------------------------------------------------------------
  # Helper: build a minimal static-pod JSON definition
  # -------------------------------------------------------------------------
  mkPod = name: args: {
    apiVersion = "v1";
    kind = "Pod";
    metadata.name = name;
    spec = {
      hostNetwork = true;
      priorityClassName = "system-cluster-critical";

      volumes = [
        {
          name = "pki";
          hostPath = {
            path = pki;
            type = "Directory";
          };
        }
      ];

      containers = [
        {
          name = name;
          image = "registry.k8s.io/${name}:${cfg.staticControlPlane.kubernetesVersion}";
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
    };
  };

  # turn a pod value into an attr-set that drops a file in /etc/kubernetes/manifests
  manifestFile = filename: pod: {
    "environment.etc.\"kubernetes/manifests/${filename}\".text" =
      builtins.toJSON pod;
  };

  # List of attr-sets – each a manifest
  staticManifests = let
    svcCIDR = cfg.staticControlPlane.serviceCIDR;
  in [
    (manifestFile "etcd.json" (mkPod "etcd" [
      "etcd"
      "--name=node0"
      "--data-dir=/var/run/etcd"
      "--advertise-client-urls=https://127.0.0.1:2379"
      "--listen-client-urls=https://0.0.0.0:2379"
      "--client-cert-auth=true"
      "--trusted-ca-file=${pki}/ca.crt"
      "--cert-file=${pki}/etcd.crt"
      "--key-file=${pki}/etcd.key"
    ]))

    (manifestFile "kube-apiserver.json" (mkPod "kube-apiserver" [
      "kube-apiserver"
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
    ]))

    (manifestFile "kube-controller-manager.json"
      (mkPod "kube-controller-manager" [
        "kube-controller-manager"
        "--kubeconfig=${pki}/controller-manager.kubeconfig"
        "--cluster-signing-cert-file=${pki}/ca.crt"
        "--cluster-signing-key-file=${pki}/ca.key"
        "--root-ca-file=${pki}/ca.crt"
        "--service-account-private-key-file=${pki}/ca.key"
        "--controllers=*,bootstrapsigner,tokencleaner"
      ]))

    (manifestFile "kube-scheduler.json"
      (mkPod "kube-scheduler" [
        "kube-scheduler"
        "--kubeconfig=${pki}/scheduler.kubeconfig"
      ]))
  ];
in
  ##############################################################################
  #   Module options                                                           #
  ##############################################################################
  {
    options.blackmatter.components.kubernetes.services.kubelet = {
      enable = mkEnableOption "Run the kubelet service";

      extraFlags = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional CLI flags passed verbatim to kubelet.";
      };

      staticControlPlane = {
        enable = mkEnableOption ''
          Generate static-pod manifests for etcd + control-plane components,
          so the kubelet can bootstrap a single-node cluster by itself.
        '';

        kubernetesVersion = mkOption {
          type = types.str;
          default = "v1.30.1";
          description = "Container image tag for control-plane pods.";
        };

        serviceCIDR = mkOption {
          type = types.str;
          default = "10.96.0.0/12";
          description = "Service-IP range passed to the API-server.";
        };
      };
    };

    ##############################################################################
    #   Implementation                                                           #
    ##############################################################################

    config = mkIf cfg.enable (mkMerge [
      ############################################################
      # ---- Kubelet service itself ------------------------------
      ############################################################
      {
        environment.systemPackages = [pkg];

        systemd.tmpfiles.rules = [
          "d /etc/kubernetes/manifests 0755 root root -"
          "d /etc/kubernetes/kubelet   0755 root root -"
          "d /etc/cni/net.d            0755 root root -"
        ];

        environment.etc."kubernetes/kubelet/config.yaml".text = ''
          apiVersion: kubelet.config.k8s.io/v1beta1
          kind: KubeletConfiguration
          logging:
            format: "json"
            verbosity: 2
          authentication:
            x509:
              clientCAFile: ${pki}/ca.crt
          authorization:
            mode: Webhook
          clusterDomain: cluster.local
          clusterDNS:
            - 10.96.0.10
          tlsCertFile:       ${pki}/kubelet.crt
          tlsPrivateKeyFile: ${pki}/kubelet.key
          failSwapOn:  false
          staticPodPath: /etc/kubernetes/manifests
        '';

        environment.etc."kubernetes/kubelet/kubeconfig.yaml".text = ''
          apiVersion: v1
          kind: Config
          clusters:
          - cluster:
              certificate-authority: ${pki}/ca.crt
              server: https://127.0.0.1:6443
            name: local-cluster
          users:
          - name: kubelet
            user:
              client-certificate: ${pki}/kubelet.crt
              client-key:        ${pki}/kubelet.key
          contexts:
          - context:
              cluster: local-cluster
              user:    kubelet
            name: default
          current-context: default
        '';

        systemd.services.kubelet = {
          description = "blackmatter.kubelet";
          after = ["network.target" "containerd.service"];
          wantedBy = ["multi-user.target"];

          environment.PATH = lib.mkForce (lib.makeBinPath [
            pkg
            pkgs.containerd
            pkgs.iproute2
            pkgs.util-linux
            pkgs.coreutils
            blackmatterPkgs.cilium-cni
          ]);

          serviceConfig = {
            User = "root";

            ExecStartPre = ''
              ${pkgs.bash}/bin/bash -c 'until [ -S /run/containerd/containerd.sock ]; do sleep 1; done'
            '';

            ExecStart = concatStringsSep " " ([
                "${pkg}/bin/kubelet"
                "--config=/etc/kubernetes/kubelet/config.yaml"
                "--kubeconfig=/etc/kubernetes/kubelet/kubeconfig.yaml"
              ]
              ++ cfg.extraFlags);

            Restart = "always";
            RestartSec = 2;
            KillMode = "process";
            Delegate = true;
            LimitNOFILE = 1048576;

            # ---- allow access to /dev/kmsg inside a systemd-nspawn/NixOS-container
            CapabilityBoundingSet = ["CAP_SYSLOG" "CAP_SYS_ADMIN"];
            AmbientCapabilities = ["CAP_SYSLOG" "CAP_SYS_ADMIN"];
            DeviceAllow = ["/dev/kmsg r"];
            PrivateDevices = false;
            ProtectKernelLogs = false;
          };
        };
      }

      ############################################################
      # ---- Optional control-plane static-pods ------------------
      ############################################################
      (mkIf cfg.staticControlPlane.enable (mkMerge (
        staticManifests
        ++ [
          {
            networking.firewall.allowedTCPPorts = [6443 2379 2380 10257 10259];
          }
        ]
      )))
    ]);
  }
