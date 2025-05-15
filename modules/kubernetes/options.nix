# modules/kubernetes/options.nix
{lib, ...}:
with lib; {
  options.kubernetes = {
    enable = mkEnableOption "kubernetes";
    role = mkOption {
      type = types.enum ["single" "master" "worker"];
      default = "single";
    };
  };
}
