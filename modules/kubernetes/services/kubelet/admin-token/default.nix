# modules/kubernetes/services/kubelet/admin-token/default.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.blackmatter.components.kubernetes.kubelet.admin-token;

  provisionScript = pkgs.writeShellScriptBin "generate-admin-token" ''
    set -euo pipefail

    echo "[+] Creating Kubernetes service account 'admin'..."
    ${pkgs.kubernetes}/bin/kubectl apply -f - <<EOF
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: admin
      namespace: default
    EOF

    echo "[+] Binding cluster-admin role to 'admin' service account..."
    ${pkgs.kubernetes}/bin/kubectl create clusterrolebinding admin-binding \
      --clusterrole=cluster-admin \
      --serviceaccount=default:admin \
      --dry-run=client -o yaml | ${pkgs.kubernetes}/bin/kubectl apply -f -

    echo "[+] Extracting token for 'admin' service account..."
    SECRET=$(${pkgs.kubernetes}/bin/kubectl get sa admin -o jsonpath='{.secrets[0].name}')
    TOKEN=$(${pkgs.kubernetes}/bin/kubectl get secret "$SECRET" -o jsonpath='{.data.token}' | ${pkgs.coreutils}/bin/base64 --decode)

    echo "[+] Saving token securely..."
    mkdir -p /var/lib/blackmatter/secrets
    echo "$TOKEN" > /var/lib/blackmatter/secrets/admin.token
    chmod 600 /var/lib/blackmatter/secrets/admin.token

    echo "[✓] Token generated and saved at /var/lib/blackmatter/secrets/admin.token"
  '';
in {
  options.blackmatter.components.kubernetes.kubelet.admin-token.enable =
    lib.mkEnableOption "Enable provisioning of admin service account and token.";

  config = lib.mkIf cfg.enable {
    system.activationScripts.restart-admin-token = ''
      echo "[+] Restarting admin-token service..."
      ${pkgs.systemd}/bin/systemctl restart admin-token.service
    '';

    systemd.services.admin-token = {
      description = "Provision Kubernetes admin service account and token";
      after = ["kubelet.service" "static-pods.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${provisionScript}/bin/generate-admin-token";
      };
    };
  };
}
