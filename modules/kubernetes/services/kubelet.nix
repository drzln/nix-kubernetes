# modules/kubernetes/services/kubelet.nix
{
  lib,
  pkgs,
  config,
  blackmatterPkgs,
  ...
}:
with lib; let
  pkg = blackmatterPkgs.kubelet;
  cfg = config.blackmatter.components.kubernetes.services.kubelet;
in {
  options.blackmatter.components.kubernetes.services.kubelet = {
    enable = mkEnableOption "Enable the kubelet service";
    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional flags to pass to kubelet binary.";
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [pkg];
    systemd.tmpfiles.rules = [
      "d /etc/kubernetes/manifests 0755 root root -"
      "d /etc/kubernetes/kubelet 0755 root root -"
      "d /etc/cni/net.d 0755 root root -"
    ];
    environment.etc."kubernetes/kubelet/config.yaml".text = ''
      apiVersion: kubelet.config.k8s.io/v1beta1
      kind: KubeletConfiguration
      logging:
        format: "json"
        verbosity: 2
      authentication:
        x509:
          clientCAFile: /var/lib/blackmatter/pki/ca.crt
      authorization:
        mode: Webhook
      clusterDomain: cluster.local
      clusterDNS:
        - 10.96.0.10
      tlsCertFile: /var/lib/blackmatter/pki/kubelet.crt
      tlsPrivateKeyFile: /var/lib/blackmatter/pki/kubelet.key
      failSwapOn: false
      staticPodPath: /etc/kubernetes/manifests
    '';
    environment.etc."kubernetes/kubelet/kubeconfig.yaml".text = ''
      apiVersion: v1
      kind: Config
      clusters:
      - cluster:
          certificate-authority: /var/lib/blackmatter/pki/ca.crt
          server: https://127.0.0.1:6443
        name: local-cluster
      users:
      - name: kubelet
        user:
          client-certificate: /var/lib/blackmatter/pki/kubelet.crt
          client-key: /var/lib/blackmatter/pki/kubelet.key
      contexts:
      - context:
          cluster: local-cluster
          user: kubelet
        name: default
      current-context: default
    '';
    systemd.services.kubelet = {
      description = "blackmatter.kubelet";
      after = ["network.target" "containerd.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        User = "root";
        ExecStartPre = "${pkgs.bash}/bin/bash -c 'until [ -S /run/containerd/containerd.sock ]; do sleep 1; done'";
        ExecStart = concatStringsSep " " (
          [
            "${pkg}/bin/kubelet"
            "--config=/etc/kubernetes/kubelet/config.yaml"
            "--kubeconfig=/etc/kubernetes/kubelet/kubeconfig.yaml"
          ]
          ++ cfg.extraFlags
        );
        Restart = "always";
        RestartSec = 2;
        KillMode = "process";
        Delegate = true;
        LimitNOFILE = 1048576;
        CapabilityBoundingSet = ["CAP_SYSLOG" "CAP_SYS_ADMIN"];
        AmbientCapabilities = ["CAP_SYSLOG" "CAP_SYS_ADMIN"];
        DeviceAllow = "/dev/kmsg r";
        PrivateDevices = false; # must disable to use DeviceAllow
        ProtectKernelLogs = false;
      };
      environment = {
        PATH = lib.mkForce (lib.makeBinPath [
          pkg
          pkgs.containerd
          pkgs.iproute2
          pkgs.util-linux
          pkgs.coreutils
          blackmatterPkgs.cilium-cni
        ]);
      };
    };
  };
}
