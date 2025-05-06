# modules/kubernetes/services/cilium-operator.nix
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  pkg = pkgs.blackmatter.k8s.cilium-operator;
  cfg = config.blackmatter.components.kubernetes.services.cilium-operator;
in {
  options.blackmatter.components.kubernetes.services.cilium-operator = {
    enable = mkEnableOption "Enable cilium-operator";
  };
  config = mkIf cfg.enable {
    systemd.services.cilium-operator = {
      description = "blackmatter.cilium-operator";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target" "cilium-agent.service"];
      wants = ["network-online.target" "cilium-agent.service"];
      serviceConfig = {
        ExecStart = ''
          ${pkg}/bin/cilium-operator \
            --config-dir=/etc/cilium \
            --enable-cilium-endpoint-slice=true \
            --cluster-name=blackmatter \
            --k8s-kubeconfig-path=/etc/kubernetes/kubeconfig
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
    ];
  };
}
