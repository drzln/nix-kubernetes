{
  config,
  lib,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.kubelet.service;
in
  lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /etc/kubernetes/manifests 0755 root root -"
      "d /etc/kubernetes/kubelet   0755 root root -"
      "d /etc/cni/net.d            0755 root root -"
      "d /var/run/etcd             0700 root root -"
    ];
  }
