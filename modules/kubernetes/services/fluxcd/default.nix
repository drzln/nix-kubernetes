{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.fluxcd = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable the FluxCD bootstrap module. When enabled, a script to bootstrap FluxCD
        is generated, optionally accompanied by a one-time systemd service.
      '';
    };
    owner = mkOption {
      type = types.str;
      description = "GitHub username or organization that owns the repository for GitOps.";
    };
    repo = mkOption {
      type = types.str;
      description = "Name of the GitHub repository to use for FluxCD GitOps.";
    };
    branch = mkOption {
      type = types.str;
      default = "main";
      description = "Git branch of the repository to track (e.g., main).";
    };
    path = mkOption {
      type = types.str;
      description = "Path within the Git repository for cluster manifests (e.g., 'clusters/my-cluster').";
    };
    personal = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If true, indicates the repo is under a personal GitHub account (not an organization).
        This will add the --personal flag to the flux bootstrap command.
      '';
    };
    patFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to a file containing the GitHub Personal Access Token (PAT) for Flux authentication.
        This should be a decrypted secret file (e.g., managed by SOPS). The bootstrap script will
        read this file at runtime if GITHUB_TOKEN is not already set in the environment.
      '';
    };
    runAtBoot = mkOption {
      type = types.bool;
      default = false;
      description = "If true, enable a one-time systemd service that runs the FluxCD bootstrap script on first boot.";
    };
    lockFile = mkOption {
      type = types.str;
      default = "/var/lib/fluxcd-bootstrap.lock";
      description = "Path of the lock file that ensures the bootstrap script runs only once.";
    };
  };

  # Only apply configuration if the module is enabled
  config = let
    inherit (pkgs) bash coreutils;
  in
    mkIf config.fluxcd.enable (
      let
        # Generate the FluxCD bootstrap script
        fluxBootstrapScript = pkgs.writeShellScriptBin "fluxcd-bootstrap" ''
          #!${bash}/bin/bash
          set -euo pipefail

          echo "Waiting for Kubernetes API to respond..."
          until ${pkgs.kubectl}/bin/kubectl cluster-info &>/dev/null; do
            sleep 5
            echo "Waiting for Kubernetes API to respond..."
          done
          echo "Kubernetes API is available."

          # If FluxCD is already installed (flux-system namespace exists), exit
          if ${pkgs.kubectl}/bin/kubectl get namespace flux-system &>/dev/null; then
            echo "FluxCD already bootstrapped (flux-system namespace exists). Exiting."
            exit 0
          fi

          # Ensure GitHub PAT is available in environment
          if [ -z "$GITHUB_TOKEN" ]; then
            ${optionalString (config.fluxcd.patFile != null) ''
            if [ -f "${config.fluxcd.patFile}" ]; then
              export GITHUB_TOKEN="$(cat "${config.fluxcd.patFile}")"
            fi
          ''}
            if [ -z "$GITHUB_TOKEN" ]; then
              echo "Error: GitHub PAT not provided. Set GITHUB_TOKEN or configure fluxcd.patFile." >&2
              exit 1
            fi
          fi

          echo "Bootstrapping FluxCD with repository ${config.fluxcd.owner}/${config.fluxcd.repo} (${config.fluxcd.branch}@${config.fluxcd.path})..."
          ${pkgs.fluxcd}/bin/flux bootstrap github \
            --token-auth \
            --owner="${config.fluxcd.owner}" \
            --repository="${config.fluxcd.repo}" \
            --branch="${config.fluxcd.branch}" \
            --path="${config.fluxcd.path}" \
            ${optionalString config.fluxcd.personal "--personal"}
        '';
      in {
        assertions = [
          {
            assertion = (config.fluxcd ? owner) && (config.fluxcd ? repo) && (config.fluxcd ? path);
            message = "fluxcd.owner, fluxcd.repo, and fluxcd.path must be set when fluxcd.enable is true.";
          }
        ];
        environment.systemPackages = [pkgs.fluxcd pkgs.kubectl fluxBootstrapScript];
        systemd.services.fluxcd-bootstrap = mkIf config.fluxcd.runAtBoot {
          description = "FluxCD GitOps bootstrap (one-time)";
          wants = ["network-online.target"];
          after = ["network-online.target"];
          unitConfig.ConditionPathExists = "!${config.fluxcd.lockFile}";
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ["${fluxBootstrapScript}/bin/fluxcd-bootstrap"];
            ExecStartPost = ["${coreutils}/bin/touch" "${config.fluxcd.lockFile}"];
            TimeoutStartSec = "300s";
          };
          wantedBy = ["multi-user.target"];
        };
      }
    );
}
