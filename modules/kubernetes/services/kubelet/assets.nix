# modules/kubernetes/services/kubelet/assets.nix
{pkgs, ...}: {
  environment.etc."kubernetes/scripts/generate-certs.sh".text = builtins.readFile ./generate-certs.sh;
  environment.etc."kubernetes/scripts/verify-certs.sh".source = pkgs.replaceVars {
    src = ./verify-certs.sh;
    openssl = "${pkgs.openssl}/bin/openssl";
  };
  systemd.services.kubelet-generate-certs = {
    description = "Generate TLS certs and configs for kubelet";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /etc/kubernetes/scripts/generate-certs.sh";
    };
  };
  systemd.services.kubelet-verify-certs = {
    description = "Verify TLS certs for kubelet";
    wantedBy = ["multi-user.target"];
    before = ["kubelet.service"];
    after = ["kubelet-generate-certs.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /etc/kubernetes/scripts/verify-certs.sh";
    };
  };
}
