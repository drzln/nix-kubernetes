{lib, ...}:
with lib; {
  options.kubernetes = {
    enable = mkEnableOption "bare-metal Kubernetes";
    role = mkOption {
      type = types.enum ["master" "worker" "single"];
      default = "master";
    };

    overlay = mkOption {
      type = types.nullOr types.anything;
      default = null;
    };

    etcdPackage = mkOption {
      type = types.nullOr types.package;
      default = null;
    };

    containerdPackage = mkOption {
      type = types.nullOr types.package;
      default = null;
    };

    nodePortRange = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    extraApiArgs = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    extraKubeletOpts = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    kubeadmExtra = mkOption {
      type = types.str;
      default = "";
    };

    firewallOpen = mkOption {
      type = types.bool;
      default = false;
    };

    join.address = mkOption {
      type = types.str;
      default = "";
    };

    join.token = mkOption {
      type = types.str;
      default = "";
    };

    join.caHash = mkOption {
      type = types.str;
      default = "";
    };
  };
}
