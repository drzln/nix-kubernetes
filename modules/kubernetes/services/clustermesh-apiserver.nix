# modules/kubernetes/services/clustermesh-apiserver.nix
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  pkg = pkgs.blackmatter.k8s.clustermesh-apiserver;
  cfg = config.blackmatter.components.kubernetes.services.clustermesh-apiserver;
in {
  options.blackmatter.components.kubernetes.services.clustermesh-apiserver = {
    enable = mkEnableOption "Enable cilium clustermesh-apiserver";
  };
  config = mkIf cfg.enable {
    systemd.services.clustermesh-apiserver = {
      description = "blackmatter.clustermesh-apiserver";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target" "cilium-agent.service"];
      serviceConfig = {
        ExecStart = ''
          ${pkg}/bin/clustermesh-apiserver \
            --config-dir=/etc/cilium \
            --clustermesh-config-directory=/etc/cilium/clustermesh
        '';
        Restart = "always";
        RestartSec = 2;
        LimitNOFILE = 1048576;
      };
      environment = {
        PATH = lib.makeBinPath [pkg pkgs.coreutils];
      };
    };
    environment.systemPackages = [pkg];
    systemd.tmpfiles.rules = [
      "d /etc/cilium 0755 root root -"
      "d /etc/cilium/clustermesh 0755 root root -"
    ];
    environment.etc."cilium/clustermesh/config.yaml".text = ''
      # placeholder config for future mesh
    '';
  };
}
