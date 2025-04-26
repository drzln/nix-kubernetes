{inputs, ...}:
inputs.colmena.lib.makeHive {
  meta.nixpkgs = import inputs.nixpkgs {system = "x86_64-linux";};

  defaults = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [vim wget curl];
    system.stateVersion = "24.05";
    fileSystems."/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["mode=755"];
    };
    boot.loader.grub.enable = false;
  };

  master = {pkgs, ...}: {
    imports = [./modules];

    blackmatter.components.kubernetes.enable = true;
    networking.hostName = "master";
    networking.firewall.allowedTCPPorts = [6443];

    deployment.targetHost = "192.168.1.10";
    deployment.tags = ["masters"];
  };

  "worker-1" = {pkgs, ...}: {
    imports = [./modules];
    blackmatter.components.kubernetes.enable = true;
    networking.hostName = "worker-1";

    deployment.targetHost = "192.168.1.11";
    deployment.tags = ["workers"];
  };

  "worker-2" = {pkgs, ...}: {
    imports = [./modules];
    blackmatter.components.kubernetes.enable = true;
    networking.hostName = "worker-2";

    deployment.targetHost = "192.168.1.12";
    deployment.tags = ["workers"];
  };
}
