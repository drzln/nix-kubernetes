{
  lib,
  config,
  require,
  ...
}: let
  cfg = config.kubernetes;
  kubeletPkg = require "kubelet";
in {
  systemd.services.kubelet = {
    description = "Kubernetes kubelet";
    wantedBy = ["multi-user.target"];
    after = ["containerd.service"];
    environment = {HOME = "/var/lib/kubelet";};
    serviceConfig = {
      ExecStart = lib.concatStringsSep " " ([
          "${kubeletPkg}/bin/kubelet"
          "--container-runtime-endpoint=unix:///run/containerd/containerd.sock"
          "--fail-swap-on=false"
          "--pod-manifest-path=/etc/kubernetes/manifests"
          "--kubeconfig=/etc/kubernetes/kubelet.conf"
        ]
        ++ cfg.extraKubeletOpts);
      Restart = "always";
    };
  };
}
