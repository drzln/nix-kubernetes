# infra/hive.nix
{
  inputs,
  dynamicHosts ? import ./dynamic-nodes.nix // {},
  ...
}:
inputs.colmena.lib.makeHive {
  meta.nixpkgs = import inputs.nixpkgs {system = "x86_64-linux";};
  defaults = {pkgs, ...}: {
    # deployment.order = ["master-1" "master-2" "worker-1" "worker-2"];
    environment.systemPackages = with pkgs; [vim wget curl];
    system.stateVersion = "24.05";
    # nix.settings.lock-protocol-timeout = 300; # seconds, default is 30
    # systemd.services.nixos-upgrade.enable = lib.mkForce false;
    # systemd.timers.nixos-upgrade.enable = lib.mkForce false;
    fileSystems."/" = {
      device = "/dev/xvda1"; # first EBS volume
      fsType = "ext4";
    };
    boot.loader.grub = {
      enable = true;
      devices = ["/dev/xvda"];
    };
    # boot.loader.grub.enable = false;
    _module.args.testOverlay = self: super: {};
  };

  # "master-1" = {
  #   pkgs,
  #   testOverlay,
  #   ...
  # }: {
  #   imports = [inputs.self.nixosModules.kubernetes];
  #   services.cloud-init.enable = false;
  #   services.cloud-init.network.enable = true;
  #   # services.amazon-ec2-agent.enable = true;
  #   services.amazon-ssm-agent.enable = true;
  #   services.openssh.enable = true;
  #   services.openssh.settings.PermitRootLogin = "prohibit-password";
  #   blackmatter.components.kubernetes = {
  #     enable = true;
  #     role = "master";
  #     overlay = testOverlay;
  #     etcdPackage = pkgs.etcd;
  #     containerdPackage = pkgs.containerd;
  #     nodePortRange = "80-32000";
  #     extraApiArgs = {"audit-log-maxage" = "10";};
  #     extraKubeletOpts = "--fail-swap-on=false";
  #     kubeadmExtra = {apiServer = {timeoutForControlPlane = "10m0s";};};
  #     firewallOpen = true;
  #   };
  #   networking.hostName = "master-1";
  #   networking.firewall.allowedTCPPorts = [6443];
  #   deployment.targetHost = dynamicHosts.master-1 or "192.168.1.10";
  #   deployment.tags = ["masters"];
  # };

  # "master-2" = {
  #   pkgs,
  #   testOverlay,
  #   ...
  # }: {
  #   imports = [inputs.self.nixosModules.kubernetes];
  #   services.cloud-init.enable = false;
  #   services.cloud-init.network.enable = true;
  #   # services.amazon-ec2-agent.enable = true;
  #   services.amazon-ssm-agent.enable = true;
  #   services.openssh.enable = true;
  #   services.openssh.settings.PermitRootLogin = "prohibit-password";
  #   blackmatter.components.kubernetes = {
  #     enable = true;
  #     role = "master";
  #     overlay = testOverlay;
  #     etcdPackage = pkgs.etcd;
  #     containerdPackage = pkgs.containerd;
  #     nodePortRange = "80-32000";
  #     extraApiArgs = {"audit-log-maxage" = "15";};
  #     extraKubeletOpts = "--fail-swap-on=false";
  #     kubeadmExtra = {apiServer = {timeoutForControlPlane = "10m0s";};};
  #     firewallOpen = true;
  #   };
  #   networking.hostName = "master-2";
  #   networking.firewall.allowedTCPPorts = [6443];
  #   deployment.targetHost = dynamicHosts.master-2 or "192.168.1.20";
  #   deployment.tags = ["masters"];
  # };

  "worker-1" = {
    pkgs,
    testOverlay,
    ...
  }: {
    imports = [inputs.self.nixosModules.kubernetes];
    services.cloud-init.enable = false;
    services.cloud-init.network.enable = true;
    # services.amazon-ec2-agent.enable = true;
    services.amazon-ssm-agent.enable = true;
    services.openssh.enable = true;
    services.openssh.settings.PermitRootLogin = "prohibit-password";
    blackmatter.components.kubernetes = {
      enable = true;
      role = "worker-1";
      overlay = testOverlay;
      etcdPackage = pkgs.etcd;
      containerdPackage = pkgs.containerd;
      nodePortRange = "30000-32767";
      extraApiArgs = {"profiling" = "false";};
      extraKubeletOpts = "--node-labels=node-role.kubernetes.io/worker=";
      kubeadmExtra = {nodeRegistration = {criSocket = "/run/containerd/containerd.sock";};};
      firewallOpen = false;
      join = {
        address = "${dynamicHosts.master-1 or "192.168.1.10"}:6443";
        token = "abcdef.0123456789abcdef";
        caHash = "sha256:deadbeefcafebabe0123456789abcdef0123456789abcdef0123456789abcd";
      };
    };
    networking.hostName = "worker-1";
    deployment.targetHost = dynamicHosts.worker-1 or "192.168.1.11";
    deployment.tags = ["workers"];
  };
  # "worker-2" = {
  #   pkgs,
  #   testOverlay,
  #   ...
  # }: {
  #   imports = [inputs.self.nixosModules.kubernetes];
  #   services.cloud-init.enable = false;
  #   services.cloud-init.network.enable = true;
  #   services.amazon-ssm-agent.enable = true;
  #   # services.amazon-ec2-agent.enable = true;
  #   services.openssh.enable = true;
  #   services.openssh.settings.PermitRootLogin = "prohibit-password";
  #   blackmatter.components.kubernetes = {
  #     enable = true;
  #     role = "worker-2";
  #     overlay = testOverlay;
  #     etcdPackage = pkgs.etcd;
  #     containerdPackage = pkgs.containerd;
  #     nodePortRange = "30000-32767";
  #     extraApiArgs = {"profiling" = "false";};
  #     extraKubeletOpts = "--node-labels=node-role.kubernetes.io/worker=";
  #     kubeadmExtra = {nodeRegistration = {criSocket = "/run/containerd/containerd.sock";};};
  #     firewallOpen = false;
  #     join = {
  #       address = "${dynamicHosts.master-2 or "192.168.1.10"}:6443";
  #       token = "abcdef.0123456789abcdef";
  #       caHash = "sha256:deadbeefcafebabe0123456789abcdef0123456789abcdef0123456789abcd";
  #     };
  #   };
  #   networking.hostName = "worker-2";
  #   deployment.targetHost = dynamicHosts.worker-1 or "192.168.1.11";
  #   deployment.tags = ["workers"];
  # };
}
