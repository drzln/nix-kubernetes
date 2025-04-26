{inputs, ...}: {
  meta = {
    nixpkgs = import inputs.nixpkgs {system = "x86_64-linux";};
  };

  defaults = {
    config,
    pkgs,
    ...
  }: {
    # Shared things all nodes inherit (optional):
    environment.systemPackages = with pkgs; [vim wget curl];
    system.stateVersion = "24.05";
  };

  nodes = {
    "master" = {
      deployment.targetHost = "192.168.1.10";
      deployment.tags = ["masters"];

      config = {
        config,
        pkgs,
        ...
      }: {
        imports = [./modules];
        blackmatter.components.kubernetes.enable = true;
        networking.hostName = "master";
        networking.firewall.allowedTCPPorts = [6443];
      };
    };

    "worker-1" = {
      deployment.targetHost = "192.168.1.11";
      deployment.tags = ["workers"];

      config = {
        config,
        pkgs,
        ...
      }: {
        imports = [./modules];
        blackmatter.components.kubernetes.enable = true;
        networking.hostName = "worker-1";
      };
    };

    "worker-2" = {
      deployment.targetHost = "192.168.1.12";
      deployment.tags = ["workers"];

      config = {
        config,
        pkgs,
        ...
      }: {
        imports = [./modules];
        blackmatter.components.kubernetes.enable = true;
        networking.hostName = "worker-2";
      };
    };
  };
}
