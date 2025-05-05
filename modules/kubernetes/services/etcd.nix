# modules/kubernetes/services/etcd.nix
{
  lib,
  config,
  require,
  ...
}: let
  cfg = config.kubernetes;
  isCP = cfg.role == "master" || cfg.role == "single";
  etcdPkg = cfg.etcdPackage or require "etcd";
in
  lib.mkIf isCP {
    users.users.etcd = {
      isSystemUser = true;
      group = "etcd";
    };
    users.groups.etcd = {};

    systemd.tmpfiles.rules = ["d /var/lib/etcd 0700 etcd etcd"];

    systemd.services.etcd = {
      description = "Embedded etcd";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart =
          "${etcdPkg}/bin/etcd --data-dir=/var/lib/etcd "
          + "--advertise-client-urls=http://127.0.0.1:2379 "
          + "--listen-client-urls=http://127.0.0.1:2379";
        Restart = "always";
      };
    };
  }
