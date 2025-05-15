# modules/kubernetes/services/kubelet/cleanup/default.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.kubelet.cleanup;

  cleanupScript = pkgs.writeShellScriptBin "kubelet-cleanup" ''
    set -euo pipefail

    echo "[+] Cleaning up Kubernetes CRI state..."

    ${pkgs.cri-tools}/bin/crictl rm -af || true
    ${pkgs.cri-tools}/bin/crictl rmp -af || true

    echo "[✓] Cleanup complete."
  '';
in {
  options.blackmatter.components.kubernetes.kubelet.cleanup.enable = lib.mkEnableOption "Enable cleanup of Kubernetes CRI state before kubelet starts.";

  config = lib.mkIf cfg.enable {
    systemd.services.kubelet-cleanup = {
      description = "Cleanup Kubernetes CRI state";
      before = ["kubelet.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${cleanupScript}/bin/kubelet-cleanup";
      };
    };
  };
}
