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
      kubernetes.enable = true;
      networking.hostName = "master";
      system.stateVersion = "24.05";
    };
  };
}
