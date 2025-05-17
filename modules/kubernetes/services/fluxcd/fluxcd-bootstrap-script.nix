# modules/kubernetes/services/fluxcd/fluxcd-bootstrap-script.nix
{
  pkgs,
  cfg,
}:
pkgs.writeShellScriptBin "fluxcd-bootstrap" ''
  #!/usr/bin/env bash
  set -euo pipefail

  export KUBECONFIG="/run/secrets/kubernetes/configs/admin/kubeconfig"

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
    if [ ! -f "${cfg.patFile}" ]; then
      echo "GitHub token file missing at ${cfg.patFile}. Exiting."
      exit 1
    fi

    echo "[fluxcd-bootstrap] Bootstrapping FluxCD..."
    ${pkgs.fluxcd}/bin/flux bootstrap github \
      --token-auth \
      --owner=${cfg.owner} \
      --repository=${cfg.repo} \
      --branch=${cfg.branch} \
      --path=${cfg.path} \
      --token="$(cat "${cfg.patFile}")" \
      ${pkgs.lib.optionalString cfg.personal "--personal"}
  else
    echo "[fluxcd-bootstrap] FluxCD already bootstrapped; skipping."
  fi
''
