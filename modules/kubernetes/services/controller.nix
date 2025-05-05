# modules/kubernetes/services/controller.nix
{
  lib,
  config,
  require,
  ...
}: let
  cfg = config.kubernetes;
  isCP = cfg.role == "master" || cfg.role == "single";
  ctrlPkg = require "kube-controller-manager";
in
  lib.mkIf isCP {
    systemd.services.kube-controller-manager = {
      description = "Kubernetes controller-manager";
      wantedBy = ["multi-user.target"];
      after = ["kube-apiserver.service"];
      serviceConfig = {
        ExecStart =
          "${ctrlPkg}/bin/kube-controller-manager "
          + "--kubeconfig=/etc/kubernetes/controller-manager.conf "
          + "--leader-elect=true";
        Restart = "always";
      };
    };
  }
