{inputs, ...}:
inputs.colmena.lib.makeHive {
  meta = {
    # Pin Nixpkgs for consistent builds
    nixpkgs = import inputs.nixpkgs {system = "x86_64-linux";};
  };

  defaults = {pkgs, ...}: {
    # Common configuration for all nodes
    environment.systemPackages = with pkgs; [vim wget curl];
    system.stateVersion = "24.05";
  };

  # Node definitions as top-level attributes (not nested under "nodes")
  master = {
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
}
