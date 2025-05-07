# modules/kubernetes/services/etcd.nix
{
  lib,
  pkgs,
  config,
  blackmatterPkgs,
  ...
}:

with lib; let
  pkg = blackmatterPkgs.etcd;
  cfg = config.blackmatter.components.kubernetes.services.etcd;
in {
  options.blackmatter.components.kubernetes.services.etcd = {
    enable = mkEnableOption "Enable the etcd service";

    advertiseAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "IP address etcd advertises to clients/peers (e.g. 127.0.0.1 or your host IP)";
    };
    useTLS = mkOption {
      type = types.bool;
      default = false;
      description = "Enable serving over TLS with certs from /var/lib/kubernetes/pki";
    };
  };

  config = mkIf cfg.enable {
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
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        User = "etcd";
        Group = "etcd";

        # Wait until the advertise address is routable before starting
        ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in {1..30}; do nc -z ${cfg.advertiseAddress} 2379 && exit 0 || sleep 1; done; exit 1'";

        ExecStart = concatStringsSep " " (
          [ "${pkg}/bin/etcd"
            "--name node1"
            "--data-dir /var/lib/etcd"
            "--listen-client-urls http://${cfg.advertiseAddress}:2379,http://127.0.0.1:2379"
            "--advertise-client-urls http://${cfg.advertiseAddress}:2379"
            "--listen-peer-urls http://${cfg.advertiseAddress}:2380"
            "--initial-advertise-peer-urls http://${cfg.advertiseAddress}:2380"
            "--initial-cluster node1=http://${cfg.advertiseAddress}:2380"
            "--initial-cluster-token etcd-cluster-1"
            "--initial-cluster-state new"
          ] ++ (cfg.useTLS then [
            "--cert-file=/var/lib/kubernetes/pki/etcd.pem"
            "--key-file=/var/lib/kubernetes/pki/etcd-key.pem"
            "--trusted-ca-file=/var/lib/kubernetes/pki/ca.pem"
            "--client-cert-auth=true"
            "--peer-client-cert-auth=true"
          ] else [])
        );

        Restart = "always";
        RestartSec = 2;
        LimitNOFILE = 40000;
      };

      environment = {
        PATH = lib.mkForce (lib.makeBinPath [ pkg pkgs.coreutils pkgs.nettools pkgs.bash ]);
      };
    };
  };
}

