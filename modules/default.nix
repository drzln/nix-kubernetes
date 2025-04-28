# modules/kubernetes/default.nix
{
  lib,
  pkgs, # ← pkgs of the *host* system
  config,
  inputs, # ← flake inputs handed in via specialArgs
  ...
}: let
  inherit (lib) mkIf mkOption mkEnableOption types recursiveUpdate;

  cfg = config.blackmatter.components.kubernetes;
  # --------------------------------------------------------------
  # Pull in the overlay (or the caller’s override) that provides
  # the *custom* Kubernetes build from github:drzln/nix-kubernetes
  # --------------------------------------------------------------
  overlay = cfg.overlay or inputs.nix-kubernetes.overlays.default;

  pkgs' = import inputs.nixpkgs {
    system = pkgs.system;
    overlays = [overlay];
  };

  # ── binaries we are going to run ───────────────────────────────
  k8sPkgs =
    pkgs'.kubernetesPackages
    // {
      kube-apiserver = pkgs'.kube-apiserver;
      kube-controller-manager = pkgs'.kube-controller-manager;
      kube-scheduler = pkgs'.kube-scheduler;
      kubeadm = pkgs'.kubeadm;
    };

  etcdPkg = cfg.etcdPackage        or pkgs'.etcd;
  containerdPkg = cfg.containerdPackage  or pkgs'.containerd;

  isMaster = cfg.role == "master" || cfg.role == "single";
  isWorker = cfg.role == "worker" || cfg.role == "single";

  # A minimal kubeadm-config that we render to /etc/kubeadm.yaml
  kubeadmConfig = lib.generators.toYAML {} (recursiveUpdate {
      apiVersion = "kubeadm.k8s.io/v1beta3";
      kind = "ClusterConfiguration";
      kubernetesVersion = "v1.30.0"; # kubeadm insists on it
      networking.serviceSubnet = "10.96.0.0/12";
      networking.podSubnet = "10.244.0.0/16";
      apiServer = {
        extraArgs =
          cfg.extraApiArgs
          // {"service-node-port-range" = cfg.nodePortRange;};
      };
    }
    cfg.kubeadmExtra);
in {
  options.blackmatter.components.kubernetes = {
    enable = mkEnableOption "BlackMatter – self-contained Kubernetes";
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

  config = mkIf cfg.enable (lib.mkMerge [
    # ─────────── generic pieces (used by every role) ────────────
    {
      networking.firewall.enable = cfg.firewallOpen;

      # Run containerd via existing nixpkgs module – we only
      # change the package.  Works on every NixOS revision.
      virtualisation.containerd = {
        enable = true;
        package = containerdPkg;
        settings.plugins."io.containerd.grpc.v1.cri".systemdCgroup = true;
      };

      # Kubelet service (shared by master + worker)
      systemd.services.kubelet = {
        wantedBy = ["multi-user.target"];
        after = ["containerd.service"];
        environment = {HOME = "/var/lib/kubelet";};
        serviceConfig = {
          ExecStart = ''
            ${k8sPkgs.kubelet}/bin/kubelet \
              --fail-swap-on=false \
              --container-runtime-endpoint=unix:///run/containerd/containerd.sock \
              --pod-manifest-path=/etc/kubernetes/manifests \
              --kubeconfig=/etc/kubernetes/kubelet.conf \
              ${cfg.extraKubeletOpts}
          '';
          Restart = "always";
        };
      };

      # a tmpfiles rule so kubelet has its dirs
      systemd.tmpfiles.rules = [
        "d /etc/kubernetes/manifests 0755 root root - -"
        "d /var/lib/kubelet         0755 kubelet kubelet - -"
      ];
      users.users.kubelet = {
        isSystemUser = true;
        group = "kubelet";
      };
      users.groups.kubelet = {};
    }

    # ─────────── control-plane only ─────────────────────────────
    (mkIf isMaster {
      # Etcd service
      systemd.services.etcd = {
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
      systemd.tmpfiles.rules = ["d /var/lib/etcd 0700 etcd etcd - -"];
      users.users.etcd = {
        isSystemUser = true;
        group = "etcd";
      };
      users.groups.etcd = {};

      # kube-apiserver
      systemd.services.kube-apiserver = {
        wantedBy = ["multi-user.target"];
        after = ["etcd.service"];
        serviceConfig.ExecStart = ''
          ${k8sPkgs.kube-apiserver}/bin/kube-apiserver \
            --etcd-servers=http://127.0.0.1:2379 \
            --advertise-address=127.0.0.1 \
            --allow-privileged=true \
            ${lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "--${k}=${v}") cfg.extraApiArgs)} \
            --service-node-port-range=${cfg.nodePortRange}
        '';
        Restart = "always";
      };

      # controller-manager
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

      # scheduler
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

      # kube-adm one-shot to write the kubeconfigs (runs *once*)
      systemd.services.kubeadm-init = {
        wantedBy = ["multi-user.target"];
        after = ["etcd.service" "containerd.service"];
        before = ["kube-apiserver.service"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''
            ${k8sPkgs.kubeadm}/bin/kubeadm init --skip-token-print --config /etc/kubeadm.yaml
          '';
          # Don’t re-run if it succeeds once
          RemainAfterExit = true;
        };
      };

      environment.etc."kubeadm.yaml".text = kubeadmConfig;
    })

    # ─────────── worker only  (incl. single) ────────────────────
    (mkIf (isWorker && !isMaster) {
      # join the cluster once
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
