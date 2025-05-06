{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  pkg = pkgs.blackmatter.k8s.kube-controller-manager;
  cfg = config.blackmatter.components.kubernetes.services.kube-controller;
in {
  options.blackmatter.components.kubernetes.services.kube-controller = {
    enable = mkEnableOption "Enable kube-controller-manager";
  };
  config = mkIf cfg.enable {
    systemd.services.kube-controller-manager = {
      description = "blackmatter.kube-controller-manager";
      wantedBy = ["multi-user.target"];
      after = ["network.target" "kube-apiserver.service"];
      serviceConfig = {
        ExecStart = ''
          ${pkg}/bin/kube-controller-manager \
            --bind-address=127.0.0.1 \
            --cluster-name=kubernetes \
            --cluster-signing-cert-file=/var/lib/kubernetes/sa.crt \
            --cluster-signing-key-file=/var/lib/kubernetes/sa.key \
            --kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \
            --root-ca-file=/var/lib/kubernetes/ca.crt \
            --service-account-private-key-file=/var/lib/kubernetes/sa.key \
            --use-service-account-credentials=true \
            --leader-elect=true
        '';
        Restart = "always";
        RestartSec = 2;
        LimitNOFILE = 1048576;
      };
      environment = {
        PATH = lib.makeBinPath [pkg pkgs.coreutils];
      };
    };
    environment.systemPackages = [pkg];
    systemd.tmpfiles.rules = [
      "d /etc/kubernetes 0755 root root -"
      "d /var/lib/kubernetes 0755 root root -"
    ];
    # Placeholder service account + CA certs
    environment.etc."kubernetes/kube-controller-manager.kubeconfig".text = "REPLACE_ME";
    environment.etc."kubernetes/sa.key".text = "REPLACE_ME";
    environment.etc."kubernetes/sa.crt".text = "REPLACE_ME";
    environment.etc."kubernetes/ca.crt".text = "REPLACE_ME";
  };
}
