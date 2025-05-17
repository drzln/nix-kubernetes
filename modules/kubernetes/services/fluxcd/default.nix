{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.kubernetes.services.fluxcd;
  fluxBootstrapScript = pkgs.writeShellScriptBin "fluxcd-bootstrap" ''
    #!/usr/bin/env bash
    set -euo pipefail

    retries=60
    until ${pkgs.kubectl}/bin/kubectl cluster-info &>/dev/null; do
      retries=$((retries-1))
      if [ $retries -le 0 ]; then
        echo "[fluxcd-bootstrap] Kubernetes API not responding in time"
        exit 1
      fi
      echo "[fluxcd-bootstrap] Waiting for Kubernetes API..."
      sleep 5
    done

    if ! ${pkgs.kubectl}/bin/kubectl get namespace flux-system &>/dev/null; then
      if [ -z "$GITHUB_TOKEN" ]; then
        if [ -f "${cfg.patFile}" ]; then
          export GITHUB_TOKEN=$(cat "${cfg.patFile}")
        else
          echo "GitHub token file missing at ${cfg.patFile}. Exiting."
          exit 1
        fi
      fi

      echo "[fluxcd-bootstrap] Bootstrapping FluxCD..."
      ${pkgs.fluxcd}/bin/flux bootstrap github \
        --token-auth \
        --owner=${cfg.owner} \
        --repository=${cfg.repo} \
        --branch=${cfg.branch} \
        --path=${cfg.path} \
        ${optionalString cfg.personal "--personal"}
    else
      echo "[fluxcd-bootstrap] FluxCD already bootstrapped; skipping."
    fi
  '';
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
      description = "FluxCD Bootstrap (one-time)";
      wants = ["network-online.target" "multi-user.target"];
      after = ["network-online.target" "multi-user.target"];
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
      wantedBy = ["multi-user.target"];
    };
  };
}
