# modules/kubernetes/services/kube-apiserver.nix
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  pkg = pkgs.blackmatter.k8s.kube-apiserver;
  cfg = config.blackmatter.components.kubernetes.services.kube-apiserver;
in {
  options.blackmatter.components.kubernetes.services.kube-apiserver = {
    enable = mkEnableOption "Enable kube-apiserver";
  };
  config = mkIf cfg.enable {
    systemd.services.kube-apiserver = {
      description = "blackmatter.kube-apiserver";
      wantedBy = ["multi-user.target"];
      after = ["network.target" "etcd.service"];
      serviceConfig = {
        ExecStart = ''
          ${pkg}/bin/kube-apiserver \
            --advertise-address=127.0.0.1 \
            --bind-address=127.0.0.1 \
            --secure-port=6443 \
            --etcd-servers=http://127.0.0.1:2379 \
            --service-cluster-ip-range=10.96.0.0/12 \
            --allow-privileged=true \
            --authorization-mode=Node,RBAC \
            --enable-bootstrap-token-auth=true \
            --runtime-config=api/all=true \
            --service-account-signing-key-file=/var/lib/kubernetes/sa.key \
            --service-account-key-file=/var/lib/kubernetes/sa.pub \
            --service-account-issuer=https://kubernetes.default.svc
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
      "d /var/lib/kubernetes 0755 root root -"
    ];
    # Placeholder for service account signing keys
    environment.etc."kubernetes/sa.key".text = "REPLACE_ME";
    environment.etc."kubernetes/sa.pub".text = "REPLACE_ME";
  };
}
