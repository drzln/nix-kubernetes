# modules/kubernetes/options.nix
{lib, ...}:
with lib; {
  imports = [./services/fluxcd];
  options.kubernetes = {
    enable = mkEnableOption "Enable Kubernetes.";
    role = mkOption {
      type = types.enum ["single" "master" "worker"];
      default = "single";
      description = "The role of this Kubernetes node.";
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
}
