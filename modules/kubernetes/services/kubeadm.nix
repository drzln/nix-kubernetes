# modules/kubernetes/services/kubeadm.nix
{
  lib,
  config,
  require,
  ...
}: let
  cfg = config.kubernetes;
  kubeadm = require "kubeadm";
  isMaster = cfg.role == "master" || cfg.role == "single";
  isWorker = cfg.role == "worker";
in {
  systemd.services = lib.mkMerge [
    (lib.mkIf isMaster {
      kubeadm-init = {
        description = "kubeadm init (first boot)";
        wantedBy = ["multi-user.target"];
        after = ["containerd.service"];
        before = ["kube-apiserver.service"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${kubeadm}/bin/kubeadm init --skip-token-print --config /etc/kubeadm-init.yaml";
          RemainAfterExit = true;
        };
      };
    })

    (lib.mkIf isWorker {
      kubeadm-join = {
        description = "kubeadm join (first boot)";
        wantedBy = ["multi-user.target"];
        after = ["containerd.service"];
        before = ["kubelet.service"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.concatStringsSep " " [
            "${kubeadm}/bin/kubeadm"
            "join"
            cfg.join.address
            "--token"
            cfg.join.token
            "--discovery-token-ca-cert-hash"
            cfg.join.caHash
          ];
          RemainAfterExit = true;
        };
      };
    })
  ];
}
