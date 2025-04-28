{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.kubernetes;
  overlay = cfg.overlay or inputs.nix-kubernetes.overlays.default;

  pkgs' = import inputs.nixpkgs {
    system = pkgs.system;
    overlays = [overlay];
  };

  k8sPkgs =
    pkgs'.kubernetesPackages
    // {
      kube-apiserver = pkgs'.kube-apiserver;
      kube-controller-manager = pkgs'.kube-controller-manager;
      kube-scheduler = pkgs'.kube-scheduler;
    };

  etcdPkg = cfg.etcdPackage or pkgs'.etcd;
  containerdPkg = cfg.containerdPackage or pkgs'.containerd;

  isMaster = lib.elem cfg.role ["master" "single"];
  isWorker = lib.elem cfg.role ["worker" "single"];
in {
  options = {
    blackmatter.components.kubernetes = {
      enable = mkEnableOption "Activate Kubernetes on this host";

      role = mkOption {
        type = types.enum ["master" "worker" "single"];
        default = "single";
        description = "Control-plane, worker or all-in-one node.";
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
  };

  config = mkIf cfg.enable (mkMerge [
    {networking.firewall.enable = cfg.firewallOpen;}

    (mkIf isWorker {
      virtualisation.containerd = {
        enable = true;
        package = containerdPkg;
        settings.plugins."io.containerd.grpc.v1.cri".systemdCgroup = true;
      };
    })

    (mkIf isMaster {
      services.kubernetes = {
        roles = ["master"];

        kubelet.package = k8sPkgs.kubelet;
        apiserver.package = k8sPkgs.kube-apiserver;
        controllerManager.package = k8sPkgs.kube-controller-manager;
        scheduler.package = k8sPkgs.kube-scheduler;

        etcd = {
          enable = true;
          package = etcdPkg;
        };

        kubelet.extraOpts = ''
          --container-runtime-endpoint=unix:///run/containerd/containerd.sock
          ${cfg.extraKubeletOpts}
        '';

        kubeadm.extraConfig =
          lib.recursiveUpdate
          {
            apiServer.extraArgs =
              cfg.extraApiArgs
              // {"service-node-port-range" = cfg.nodePortRange;};
          }
          cfg.kubeadmExtra;
      };
    })

    (mkIf (isWorker && !isMaster) {
      services.kubernetes = {
        roles = ["node"];
        kubelet.package = k8sPkgs.kubelet;
        kubelet.extraOpts = ''
          --container-runtime-endpoint=unix:///run/containerd/containerd.sock
          ${cfg.extraKubeletOpts}
        '';
        kubeadm.join = {
          enable = true;
          address = cfg.join.address;
          token = cfg.join.token;
          caCertHash = cfg.join.caHash;
        };
      };
      virtualisation.containerd = {
        enable = true;
        package = containerdPkg;
        settings.plugins."io.containerd.grpc.v1.cri".systemdCgroup = true;
      };
    })
  ]);
}
