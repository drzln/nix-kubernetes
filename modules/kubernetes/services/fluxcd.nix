# modules/kubernetes/services/fluxcd.nix
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  sourceController = pkgs.blackmatter.k8s.fluxcd-source-controller;
  kustomizeController = pkgs.blackmatter.k8s.fluxcd-kustomize-controller;
  cfg = config.blackmatter.components.kubernetes.services.fluxcd;
in {
  options.blackmatter.components.kubernetes.services.fluxcd = {
    enable = mkEnableOption "Enable FluxCD GitOps controllers";
  };
  config = mkIf cfg.enable {
    systemd.services.fluxcd-source-controller = {
      description = "blackmatter.fluxcd-source-controller";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = "${sourceController}/bin/source-controller";
        Restart = "always";
        RestartSec = 2;
        LimitNOFILE = 65536;
      };
    };
    systemd.services.fluxcd-kustomize-controller = {
      description = "blackmatter.fluxcd-kustomize-controller";
      wantedBy = ["multi-user.target"];
      after = ["network.target" "fluxcd-source-controller.service"];
      serviceConfig = {
        ExecStart = "${kustomizeController}/bin/kustomize-controller";
        Restart = "always";
        RestartSec = 2;
        LimitNOFILE = 65536;
      };
    };
    environment.systemPackages = [
      sourceController
      kustomizeController
    ];
  };
}
