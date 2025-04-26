{inputs, ...}:
inputs.colmena.lib.makeHive {
  meta = {
    nixpkgs = import inputs.nixpkgs {system = "x86_64-linux";};
  };

  nodes = {
    master = {
      config,
      pkgs,
      ...
    }: {
      imports = [./modules];
      blackmatter.components.kubernetes.enable = true;
      networking.hostName = "master";
      networking.firewall.allowedTCPPorts = [6443];
      system.stateVersion = "24.05";

      deployment = {
        targetHost = "192.168.1.10"; # <-- important
        tags = ["masters"];
      };
    };

    worker-1 = {
      config,
      pkgs,
      ...
    }: {
      imports = [./modules];
      blackmatter.components.kubernetes.enable = true;
      networking.hostName = "worker-1";
      system.stateVersion = "24.05";

      deployment = {
        targetHost = "192.168.1.11"; # <-- important
        tags = ["workers"];
      };
    };

    worker-2 = {
      config,
      pkgs,
      ...
    }: {
      imports = [./modules];
      blackmatter.components.kubernetes.enable = true;
      networking.hostName = "worker-2";
      system.stateVersion = "24.05";

      deployment = {
        targetHost = "192.168.1.12"; # <-- important
        tags = ["workers"];
      };
    };
  };
}
