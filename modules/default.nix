# modules/kubernetes/default.nix
{
  lib,
  pkgs, # host pkgs
  config,
  inputs, # flake inputs (pass via specialArgs)
  ...
}: let
  inherit (lib) mkIf mkOption mkEnableOption types recursiveUpdate concatStringsSep mapAttrsToList;

  cfg = config.blackmatter.components.kubernetes;

  overlay = cfg.overlay or inputs.nix-kubernetes.overlays.default;

  pkgs' = import inputs.nixpkgs {
    system = pkgs.system;
    overlays = [overlay];
  };

  # --- packages we run --------------------------------------------------------
  k8sPkgs =
    pkgs'.kubernetesPackages
    // {
      kube-apiserver = pkgs'.kube-apiserver;
      kube-controller-manager = pkgs'.kube-controller-manager;
      kube-scheduler = pkgs'.kube-scheduler;
      kubeadm = pkgs'.kubeadm;
    };

  etcdPkg = cfg.etcdPackage       or pkgs'.etcd;
  containerdPkg = cfg.containerdPackage or pkgs'.containerd;

  isMaster = cfg.role == "master" || cfg.role == "single";
  isWorker = cfg.role == "worker" || cfg.role == "single";

  # tiny containerd config: systemd-cgroup on, pull in default CNI dir
  containerdConf = ''
    version = 2
    [plugins."io.containerd.grpc.v1.cri"]
      sandbox_image = "registry.k8s.io/pause:3.9"
      systemd_cgroup = true
  '';

  kubeadmConfig = lib.generators.toYAML {} (recursiveUpdate {
      apiVersion = "kubeadm.k8s.io/v1beta3";
      kind = "ClusterConfiguration";
      kubernetesVersion = "v1.30.0";
      networking.serviceSubnet = "10.96.0.0/12";
      networking.podSubnet = "10.244.0.0/16";
      apiServer.extraArgs =
        cfg.extraApiArgs
        // {"service-node-port-range" = cfg.nodePortRange;};
    }
    cfg.kubeadmExtra);
in {
  ###########################################################################
  ## Options
  ###########################################################################
  options.blackmatter.components.kubernetes = {
    enable = mkEnableOption "BlackMatter self-contained Kubernetes";

    role = mkOption {
      type = types.enum ["master" "worker" "single"];
      default = "single";
    };

    overlay = mkOption {
      type = types.nullOr types.attrs;
      default = null;
    };
    etcdPackage = mkOption {
      type = types.nullOr types.package;
      default = null;
    };
    containerdPackage = mkOption {
      type = types.nullOr types.package;
      default = null;
    };

    nodePortRange = mkOption {
      type = types.str;
      default = "30000-32767";
    };
    extraApiArgs = mkOption {
      type = types.attrsOf types.str;
      default = {};
    };
    extraKubeletOpts = mkOption {
      type = types.str;
      default = "";
    };
    kubeadmExtra = mkOption {
      type = types.attrs;
      default = {};
    };

    firewallOpen = mkOption {
      type = types.bool;
      default = false;
    };

    join = {
      address = mkOption {
        type = types.str;
        default = "";
      };
      token = mkOption {
        type = types.str;
        default = "";
      };
      caHash = mkOption {
        type = types.str;
        default = "";
      };
    };
  };

  ###########################################################################
  ## Implementation
  ###########################################################################
  config = mkIf cfg.enable (lib.mkMerge [
    # ───── Common bits ──────────────────────────────────────────────────────
    {
      networking.firewall.enable = cfg.firewallOpen;

      ############### containerd (self-managed) ################
      systemd.services.containerd = {
        description = "Self-contained containerd runtime";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        environment = {PATH = "/run/wrappers/bin:${pkgs.coreutils}/bin";};
        serviceConfig = {
          ExecStart = "${containerdPkg}/bin/containerd --config /etc/containerd/config.toml";
          Restart = "always";
          Delegate = true; # for cgroup v2
        };
      };

      environment.etc."containerd/config.toml".text = containerdConf;

      systemd.tmpfiles.rules = [
        "d /etc/containerd 0755 root root - -"
        "d /var/lib/containerd 0710 root root - -"
        "d /etc/kubernetes/manifests 0755 root root - -"
        "d /var/lib/kubelet 0755 kubelet kubelet - -"
      ];

      users.users.kubelet = {
        isSystemUser = true;
        group = "kubelet";
      };
      users.groups.kubelet = {};
    }

    # ───── kubelet (all nodes) ─────────────────────────────────────────────
    {
      systemd.services.kubelet = {
        description = "Kubernetes kubelet";
        wantedBy = ["multi-user.target"];
        after = ["containerd.service"];
        environment = {HOME = "/var/lib/kubelet";};
        serviceConfig = {
          ExecStart = ''
            ${k8sPkgs.kubelet}/bin/kubelet \
              --container-runtime-endpoint=unix:///run/containerd/containerd.sock \
              --fail-swap-on=false \
              --pod-manifest-path=/etc/kubernetes/manifests \
              --kubeconfig=/etc/kubernetes/kubelet.conf \
              ${cfg.extraKubeletOpts}
          '';
          Restart = "always";
        };
      };
    }

    # ───── Control-plane only ──────────────────────────────────────────────
    (mkIf isMaster {
      ########## Etcd #######################################################
      users.users.etcd = {
        isSystemUser = true;
        group = "etcd";
      };
      users.groups.etcd = {};
      systemd.tmpfiles.rules = ["d /var/lib/etcd 0700 etcd etcd - -"];

      systemd.services.etcd = {
        description = "Embedded etcd";
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          ExecStart = ''
            ${etcdPkg}/bin/etcd \
              --data-dir=/var/lib/etcd \
              --advertise-client-urls=http://127.0.0.1:2379 \
              --listen-client-urls=http://127.0.0.1:2379
          '';
          Restart = "always";
        };
      };

      ########## API-server #################################################
      systemd.services.kube-apiserver = {
        description = "Kubernetes API server";
        wantedBy = ["multi-user.target"];
        after = ["etcd.service"];
        serviceConfig = {
          ExecStart = ''
            ${k8sPkgs.kube-apiserver}/bin/kube-apiserver \
              --etcd-servers=http://127.0.0.1:2379 \
              --advertise-address=127.0.0.1 \
              --allow-privileged=true \
              ${concatStringsSep " "
              (mapAttrsToList (k: v: "--${k}=${v}") cfg.extraApiArgs)} \
              --service-node-port-range=${cfg.nodePortRange}
          '';
          Restart = "always";
        };
      };

      ########## Controller-manager #########################################
      systemd.services.kube-controller-manager = {
        wantedBy = ["multi-user.target"];
        after = ["kube-apiserver.service"];
        serviceConfig.ExecStart = ''
          ${k8sPkgs.kube-controller-manager}/bin/kube-controller-manager \
            --kubeconfig=/etc/kubernetes/controller-manager.conf \
            --leader-elect=true
        '';
        Restart = "always";
      };

      ########## Scheduler ###################################################
      systemd.services.kube-scheduler = {
        wantedBy = ["multi-user.target"];
        after = ["kube-apiserver.service"];
        serviceConfig.ExecStart = ''
          ${k8sPkgs.kube-scheduler}/bin/kube-scheduler \
            --kubeconfig=/etc/kubernetes/scheduler.conf \
            --leader-elect=true
        '';
        Restart = "always";
      };

      ########## kubeadm init (one-shot) ####################################
      systemd.services.kubeadm-init = {
        wantedBy = ["multi-user.target"];
        after = ["etcd.service" "containerd.service"];
        before = ["kube-apiserver.service"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''
            ${k8sPkgs.kubeadm}/bin/kubeadm init \
              --skip-token-print \
              --config /etc/kubeadm.yaml
          '';
          RemainAfterExit = true;
        };
      };

      environment.etc."kubeadm.yaml".text = kubeadmConfig;
    })

    # ───── Worker only ─────────────────────────────────────────────────────
    (mkIf (isWorker && !isMaster) {
      systemd.services.kubeadm-join = {
        wantedBy = ["multi-user.target"];
        after = ["containerd.service"];
        before = ["kubelet.service"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''
            ${k8sPkgs.kubeadm}/bin/kubeadm join \
              ${cfg.join.address} \
              --token ${cfg.join.token} \
              --discovery-token-ca-cert-hash ${cfg.join.caHash}
          '';
          RemainAfterExit = true;
        };
      };
    })
  ]);
}
