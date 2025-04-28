{
  lib,
  config,
  require,
  ...
}: let
  cfg = config.kubernetes;
  isCP = cfg.role == "master" || cfg.role == "single";
  apiPkg = require "kube-apiserver";
in
  lib.mkIf isCP {
    systemd.services.kube-apiserver = {
      description = "Kubernetes API server";
      wantedBy = ["multi-user.target"];
      after = ["etcd.service"];
      serviceConfig = {
        ExecStart = lib.concatStringsSep " " ([
            "${apiPkg}/bin/kube-apiserver"
            "--etcd-servers=http://127.0.0.1:2379"
            "--advertise-address=127.0.0.1"
            "--allow-privileged=true"
            "--service-node-port-range=${cfg.nodePortRange}"
          ]
          ++ cfg.extraApiArgs);
        Restart = "always";
      };
    };
  }
