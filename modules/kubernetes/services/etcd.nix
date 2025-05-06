# modules/kubernetes/services/etcd.nix
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  pkg = pkgs.blackmatter.k8s.etcd;
  cfg = config.blackmatter.components.kubernetes.services.etcd;
in {
  options.blackmatter.components.kubernetes.services.etcd = {
    enable = mkEnableOption "Enable etcd";
  };
  config = mkIf cfg.enable {
    systemd.services.etcd = {
      description = "blackmatter.etcd";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = ''
          ${pkg}/bin/etcd \
            --name node1 \
            --data-dir /var/lib/etcd \
            --listen-client-urls http://127.0.0.1:2379,http://[::1]:2379 \
            --advertise-client-urls http://127.0.0.1:2379 \
            --listen-peer-urls http://127.0.0.1:2380 \
            --initial-advertise-peer-urls http://127.0.0.1:2380 \
            --initial-cluster node1=http://127.0.0.1:2380 \
            --initial-cluster-token etcd-cluster-1 \
            --initial-cluster-state new
        '';
        Restart = "always";
        RestartSec = 2;
        LimitNOFILE = 40000;
      };
      environment = {
        PATH = lib.makeBinPath [pkg pkgs.coreutils];
      };
    };
    environment.systemPackages = [
      pkgs.blackmatter.k8s.etcdctl
    ];
    systemd.tmpfiles.rules = [
      "d /var/lib/etcd 0700 etcd etcd -"
    ];
    users.users.etcd = {
      isSystemUser = true;
      group = "etcd";
    };
    users.groups.etcd = {};
  };
}
