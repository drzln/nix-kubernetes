# service/config.nix
{lib, ...}: {
  options.blackmatter.components.kubernetes.kubelet.service.enable =
    lib.mkEnableOption "Enable the kubelet systemd service unit";
}
