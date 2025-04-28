{
  require,
  config,
  ...
}: let
  containerdPkg = config.kubernetes.containerdPackage or require "containerd";
in {
  systemd.services.containerd = {
    description = "Containerd";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${containerdPkg}/bin/containerd --config /etc/containerd/config.toml";
      Restart = "always";
    };
  };
}
