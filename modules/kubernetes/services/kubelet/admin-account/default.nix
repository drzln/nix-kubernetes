# modules/kubernetes/services/kubelet/admin-account/default.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.kubelet.admin-account;
  provisionScript = pkgs.writeShellScriptBin "generate-admin-account" ''
    set -euo pipefail

    export KUBECONFIG=/run/secrets/kubernetes/configs/admin/kubeconfig

    # Wait until the API server is up
    echo "[+] Waiting for Kubernetes API server at https://192.168.50.2:6443 to become available..."
    until curl -k -s https://192.168.50.2:6443/healthz >/dev/null; do
      echo "[-] Kubernetes API server not yet available. Retrying in 5 seconds..."
      sleep 5
    done

    if ${pkgs.kubernetes}/bin/kubectl get secret admin-basic-auth -n kube-system >/dev/null 2>&1; then
      echo "[✓] Admin account already exists. Skipping."
      exit 0
    fi

    echo "[+] Creating admin user with basic auth credentials..."
    ${pkgs.kubernetes}/bin/kubectl -n kube-system create secret generic admin-basic-auth \
      --from-literal=username=admin \
      --from-literal=password=admin

    echo "[+] Binding cluster-admin role to 'admin' basic-auth user..."
    ${pkgs.kubernetes}/bin/kubectl create clusterrolebinding admin-basic-auth-binding \
      --clusterrole=cluster-admin \
      --user=admin \
      --dry-run=client -o yaml | ${pkgs.kubernetes}/bin/kubectl apply -f -

    echo "[✓] Admin account provisioned with username/password: admin/admin"
  '';
in {
  options.blackmatter.components.kubernetes.kubelet.admin-account.enable =
    lib.mkEnableOption "Enable provisioning of admin basic-auth account.";

  config = lib.mkIf cfg.enable {
    systemd.services.kubelet-admin-account = {
      description = "Provision Kubernetes admin basic-auth account";
      after = ["kubelet.service" "static-assets.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${provisionScript}/bin/generate-admin-account";
      };
    };
  };
}
