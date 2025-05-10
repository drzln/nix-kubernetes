# modules/kubernetes/services/etcd.nix
{
  lib,
  pkgs,
  config,
  blackmatterPkgs,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.services.etcd;
  pkg = blackmatterPkgs.etcd;
  pki = "/run/secrets/kubernetes";
  scheme =
    if cfg.useTLS
    then "https"
    else "http";
in {
  options.blackmatter.components.kubernetes.services.etcd = {
    enable = lib.mkEnableOption "Enable the etcd service";
    advertiseAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "IP address etcd advertises to clients/peers (e.g. 127.0.0.1 or host IP)";
    };
    useTLS = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable TLS for etcd using secrets from /run/secrets/kubernetes";
    };
  };
  config = lib.mkIf cfg.enable {
    users.users.etcd = {
      isSystemUser = true;
      group = "etcd";
    };
    users.groups.etcd = {};
    environment.systemPackages = [
      pkg
      blackmatterPkgs.etcdctl
      blackmatterPkgs.etcdutl
    ];
    systemd.tmpfiles.rules = [
      "d /var/lib/etcd 0700 etcd etcd -"
    ];
    systemd.services.etcd = {
      description = "blackmatter.etcd";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        User = "etcd";
        Group = "etcd";
        ExecStart = lib.concatStringsSep " " (
          [
            "${pkg}/bin/etcd"
            "--name node1"
            "--data-dir /var/lib/etcd"
            "--listen-client-urls ${scheme}://${cfg.advertiseAddress}:2379,${scheme}://127.0.0.1:2379"
            "--advertise-client-urls ${scheme}://${cfg.advertiseAddress}:2379"
            "--listen-peer-urls ${scheme}://${cfg.advertiseAddress}:2380"
            "--initial-advertise-peer-urls ${scheme}://${cfg.advertiseAddress}:2380"
            "--initial-cluster node1=${scheme}://${cfg.advertiseAddress}:2380"
            "--initial-cluster-token etcd-cluster-1"
            "--initial-cluster-state new"
          ]
          ++ lib.optionals cfg.useTLS [
            "--cert-file=${pki}/etcd/crt"
            "--key-file=${pki}/etcd/key"
            "--trusted-ca-file=${pki}/ca/crt"
            "--client-cert-auth=true"
            "--peer-cert-file=${pki}/etcd/crt"
            "--peer-key-file=${pki}/etcd/key"
            "--peer-trusted-ca-file=${pki}/ca/crt"
            "--peer-client-cert-auth=true"
          ]
        );
        Restart = "always";
        RestartSec = 2;
        LimitNOFILE = 40000;
      };
      environment = {
        PATH = lib.mkForce (lib.makeBinPath [
          pkg
          pkgs.bash
          pkgs.coreutils
          pkgs.nettools
          blackmatterPkgs.etcdctl
        ]);
      };
    };
  };
}
