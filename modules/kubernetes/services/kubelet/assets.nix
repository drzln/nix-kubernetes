# modules/kubernetes/services/kubelet/assets.nix
{
  pkgs,
  lib,
  cfg,
}: {
  environment.etc."kubernetes/scripts/generate-assets.sh".text = builtins.readFile ./generate-assets.sh;
  environment.etc."kubernetes/scripts/verify-assets.sh".text = builtins.readFile ./verify-assets.sh;
  systemd.services.kubelet-generate-assets = lib.mkIf cfg.generateAssets {
    description = "Generate TLS certs and configs for kubelet";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /etc/kubernetes/scripts/generate-assets.sh ${cfg.nodeIP} ${cfg.nodeName}";
    };
  };
  systemd.services.kubelet-verify-assets = lib.mkIf cfg.generateAssets {
    description = "Verify TLS assets for kubelet";
    wantedBy = ["multi-user.target"];
    before = ["kubelet.service"];
    after = ["kubelet-generate-assets.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /etc/kubernetes/scripts/verify-assets.sh";
    };
  };
}
