# modules/kubernetes/services/scheduler.nix
{
  lib,
  config,
  require,
  ...
}: let
  cfg = config.kubernetes;
  isCP = cfg.role == "master" || cfg.role == "single";
  schedPkg = require "kube-scheduler";
in
  lib.mkIf isCP {
    systemd.services.kube-scheduler = {
      description = "Kubernetes scheduler";
      wantedBy = ["multi-user.target"];
      after = ["kube-apiserver.service"];
      serviceConfig = {
        ExecStart =
          "${schedPkg}/bin/kube-scheduler "
          + "--kubeconfig=/etc/kubernetes/scheduler.conf "
          + "--leader-elect=true";
        Restart = "always";
      };
    };
  }
