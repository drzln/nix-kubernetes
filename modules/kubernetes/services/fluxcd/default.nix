# modules/kubernetes/services/fluxcd/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.kubernetes.services.fluxcd;
  fluxBootstrapScript = import ./fluxcd-bootstrap-script.nix {inherit pkgs cfg;};
in {
  options.blackmatter.components.kubernetes.services.fluxcd = {
    enable = mkEnableOption "Enable FluxCD bootstrap module.";
    owner = mkOption {
      type = types.str;
      description = "GitHub username or organization.";
    };
    repo = mkOption {
      type = types.str;
      description = "GitHub repository name for FluxCD.";
    };
    branch = mkOption {
      type = types.str;
      default = "main";
      description = "Git branch FluxCD should track.";
    };
    path = mkOption {
      type = types.str;
      description = "Path in repository for Flux to sync.";
    };
    personal = mkOption {
      type = types.bool;
      default = false;
      description = "Use personal repository on GitHub.";
    };
    patFile = mkOption {
      type = types.str;
      default = "/run/secrets/fluxcd/kube-clusters/pat";
      description = "Path to SOPS-decrypted GitHub PAT file.";
    };
    runAtBoot = mkOption {
      type = types.bool;
      default = false;
      description = "Run FluxCD bootstrap script automatically at first boot.";
    };
    lockFile = mkOption {
      type = types.str;
      default = "/var/lib/fluxcd-bootstrap.lock";
      description = "Path to lock file to ensure one-time bootstrap.";
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.fluxcd pkgs.kubectl fluxBootstrapScript];
    systemd.services.fluxcd-bootstrap = mkIf cfg.runAtBoot {
      wantedBy = lib.mkForce [];
      description = "FluxCD Bootstrap (one-time)";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      unitConfig = {
        ConditionPathExists = "!${cfg.lockFile}";
        ConditionKernelCommandLine = "!systemd.unit=sysinit-reactivation.target";
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${fluxBootstrapScript}/bin/fluxcd-bootstrap";
        ExecStartPost = "${pkgs.coreutils}/bin/touch ${cfg.lockFile}";
        TimeoutStartSec = "300s";
      };
    };
  };
}
