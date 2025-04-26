# ╭────────────────────────────────────────────────────────────────────────────╮
# │  blackmatter.components.kubernetes ─ QUICK-START CHEAT-SHEET              │
# ╰────────────────────────────────────────────────────────────────────────────╯
#
# 1)  Single-node “all-in-one” dev laptop
#
#     imports = [ inputs.self.nixosModules.kubernetes ];
#     blackmatter.components.kubernetes.enable = true;          # role defaults to "single"
#
# 2)  Dedicated control-plane VM with custom overlay and extra API flags
#
#     imports = [ inputs.self.nixosModules.kubernetes ];
#     blackmatter.components.kubernetes = {
#       enable = true;
#       role   = "master";
#       overlay = inputs.my-k8s-overlay;        # optional overlay
#       extraApiArgs."feature-gates" = "MixedProtocolLBService=true";
#     };
#
# 3)  Worker node that joins the cluster
#
#     imports = [ inputs.self.nixosModules.kubernetes ];
#     blackmatter.components.kubernetes = {
#       enable = true;
#       role   = "worker";
#       join.address = "10.0.0.5";
#       join.token   = "abcdef.0123456789abcdef";
#       join.caHash  = "sha256:deadbeef...";
#     };
#
# 4)  Override etcd / containerd builds from your own derivations
#
#     blackmatter.components.kubernetes = {
#       enable          = true;
#       etcdPackage     = inputs.myEtcd.packages.${pkgs.system}.etcd;
#       containerdPackage = inputs.myCtrd.packages.${pkgs.system}.containerd;
#     };
#
# 5)  Open NodePorts <1024 (e.g., expose HTTP/HTTPS 80/443)
#
#     blackmatter.components.kubernetes.nodePortRange = "80-32767";
#
#  (Uncomment the service sections below to activate the real Kubernetes
#   services—left commented so this file compiles even on systems that don’t
#   want K8s yet.)
#
{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib;
##############################################################################
  let
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

    isMaster = cfg.role == "master" || cfg.role == "single";
    isWorker = cfg.role == "worker" || cfg.role == "single";
  in {
    options.blackmatter.components.kubernetes = {
      inherit enable;

      role = mkOption {
        type = types.enum ["master" "worker" "single"];
        default = "single";
        description = "Control-plane, worker or all-in-one node.";
      };

      overlay = mkOption {
        type = types.nullOr types.attrs;
        default = null;
        description = "Overlay that provides custom k8s/etcd/containerd builds.";
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

    ############################ Configuration #################################
    config = mkIf cfg.enable (mkMerge [
      ################################ firewall ################################
      {networking.firewall.enable = cfg.firewallOpen;}

      ########################## container runtime #############################
      (mkIf isWorker {
        # services.containerd = {
        #   enable = true;
        #   package = containerdPkg;
        #   settings.plugins."io.containerd.grpc.v1.cri".systemdCgroup = true;
        # };
      })

      ########################### control-plane ################################
      (mkIf isMaster {
        # services.kubernetes = {
        #   roles = ["master"];
        #
        #   kubelet.package = k8sPkgs.kubelet;
        #   apiserver.package = k8sPkgs.kube-apiserver;
        #   controllerManager.package = k8sPkgs.kube-controller-manager;
        #   scheduler.package = k8sPkgs.kube-scheduler;
        #
        #   etcd = {
        #     enable = true;
        #     package = etcdPkg;
        #   };
        #
        #   kubelet.extraOpts = ''
        #     --container-runtime-endpoint=unix:///run/containerd/containerd.sock
        #     ${cfg.extraKubeletOpts}
        #   '';
        #
        #   kubeadm.extraConfig =
        #     lib.recursiveUpdate
        #     {apiServer.extraArgs = cfg.extraApiArgs // {"service-node-port-range" = cfg.nodePortRange;};}
        #     cfg.kubeadmExtra;
        # };
      })

      ############################ worker join #################################
      (mkIf (isWorker && !isMaster) {
        # services.kubernetes = {
        #   roles = ["node"];
        #   kubelet.package = k8sPkgs.kubelet;
        #   kubelet.extraOpts = ''
        #     --container-runtime-endpoint=unix:///run/containerd/containerd.sock
        #     ${cfg.extraKubeletOpts}
        #   '';
        #   kubeadm.join = {
        #     enable = true;
        #     address = cfg.join.address;
        #     token = cfg.join.token;
        #     caCertHash = cfg.join.caHash;
        #   };
        # };

        # services.containerd = {
        #   enable = true;
        #   package = containerdPkg;
        #   settings.plugins."io.containerd.grpc.v1.cri".systemdCgroup = true;
        # };
      })

      ########################### build-info file ##############################
      {
        # environment.etc."k8s-build-info".text = ''
        #   role=${cfg.role}
        #   k8s=${k8sPkgs.kubelet.version}
        #   etcd=${etcdPkg.version}
        #   containerd=${containerdPkg.version}
        # '';
      }
    ]);
  }
