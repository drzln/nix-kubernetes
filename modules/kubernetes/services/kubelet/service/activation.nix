{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.kubelet.service;
in
  lib.mkIf cfg.enable {
    system.activationScripts.restart-kubelet = ''
      echo "[+] Restarting kubelet service..."
      ${pkgs.systemd}/bin/systemctl restart kubelet.service
    '';
  }
