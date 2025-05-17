# modules/kubernetes/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.kubernetes;
  blackmatterPkgs = import ../../overlays/blackmatter-k8s.nix pkgs pkgs;
  service = name: ./services + "/${name}";
in {
  imports = [
    (service "containerd")
    (service "kubelet")
    (service "fluxcd")
    ./crictl.nix
  ];
  options.blackmatter.components.kubernetes = {
    enable = mkEnableOption "Enable Kubernetes";
    role = mkOption {
      type = types.enum ["master" "worker" "single"];
      default = "master";
      description = "The role this node will play in the cluster.";
    };
    fluxcd = {
      enable = mkEnableOption "Enable FluxCD bootstrap.";
      owner = mkOption {
        type = types.str;
        default = "";
        description = "GitHub username or organization for FluxCD.";
      };
      repo = mkOption {
        type = types.str;
        default = "";
        description = "GitHub repository for FluxCD manifests.";
      };
      branch = mkOption {
        type = types.str;
        default = "main";
        description = "Git branch FluxCD should synchronize.";
      };
      path = mkOption {
        type = types.str;
        default = "clusters/default";
        description = "Path within the repo for FluxCD to sync.";
      };
      personal = mkOption {
        type = types.bool;
        default = false;
        description = "Indicate if the repository is under a personal GitHub account.";
      };
      patFile = mkOption {
        type = types.str;
        default = "/run/secrets/github-pat";
        description = "Path to the GitHub PAT file (managed by SOPS).";
      };
      runAtBoot = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to bootstrap FluxCD automatically on first boot.";
      };
      lockFile = mkOption {
        type = types.str;
        default = "/var/lib/fluxcd-bootstrap.lock";
        description = "Lock file path for FluxCD one-time bootstrap.";
      };
    };
  };
  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.role != null;
          message = "You must specify a valid Kubernetes role.";
        }
      ];
      environment.sessionVariables = {
        KUBECONFIG = "/run/secrets/kubernetes/configs/admin/kubeconfig";
      };
      environment.systemPackages = with pkgs; [
        blackmatterPkgs.blackmatter.k8s.kubectl
        blackmatterPkgs.blackmatter.k8s.containerd
        runc
        cri-tools
        go
        delve
        gopls
        pulumi
        pulumictl
        pulumi-esc
        pulumi-bin
        pulumiPackages.pulumi-go
        pulumiPackages.pulumi-command
        pulumiPackages.pulumi-aws-native
        pulumiPackages.pulumi-python
      ];
      _module.args.blackmatterPkgs = blackmatterPkgs;
    }
    (mkIf (cfg.role == "single") {
      blackmatter.components.kubernetes.containerd.enable = true;
      blackmatter.components.kubernetes.kubelet.enable = true;
      blackmatter.components.kubernetes.services.fluxcd = {
        enable = config.blackmatter.componnts.kubernetes.fluxcd.enable;
        owner = config.blackmatter.componnts.kubernetes.fluxcd.owner;
        repo = config.blackmatter.componnts.kubernetes.fluxcd.repo;
        branch = config.blackmatter.componnts.kubernetes.fluxcd.branch;
        path = config.blackmatter.componnts.kubernetes.fluxcd.path;
        personal = config.blackmatter.componnts.kubernetes.fluxcd.personal;
        patFile = config.blackmatter.componnts.kubernetes.fluxcd.patFile;
        runAtBoot = config.blackmatter.componnts.kubernetes.fluxcd.runAtBoot;
        lockFile = config.blackmatter.componnts.kubernetes.fluxcd.lockFile;
      };
    })
  ]);
}
