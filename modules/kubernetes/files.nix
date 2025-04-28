{
  lib,
  pkgs,
  config,
  pkgsK8s,
  ...
}: let
  cfg = config.kubernetes;
  containerdConf = ''
    version = 2
    [plugins."io.containerd.grpc.v1.cri"]
      systemd_cgroup = true
      sandbox_image = "registry.k8s.io/pause:3.9"
  '';

  kubeadmConf =
    ''
      apiVersion: kubeadm.k8s.io/v1beta3
      kind: InitConfiguration
      nodeRegistration:
        criSocket: /run/containerd/containerd.sock
      ---
      apiVersion: kubeadm.k8s.io/v1beta3
      kind: ClusterConfiguration
      kubernetesVersion: "${pkgsK8s.kubelet.version or "1.27.0"}"
    ''
    + cfg.kubeadmExtra;
in {
  systemd.tmpfiles.rules = [
    "d /var/lib/etcd    0700 etcd    etcd"
    "d /var/lib/kubelet 0750 kubelet kubelet"
    "d /etc/kubernetes  0755 root    root"
  ];

  environment.etc."containerd/config.toml".text = containerdConf;
  environment.etc."kubeadm-init.yaml".text =
    lib.mkIf (cfg.role != "worker") kubeadmConf;
}
