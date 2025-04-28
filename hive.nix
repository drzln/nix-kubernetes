{inputs, ...}:
inputs.colmena.lib.makeHive {
  # ── Flake-level Nixpkgs ──────────────────────────────────────────────────
  meta.nixpkgs = import inputs.nixpkgs {system = "x86_64-linux";};

  # ── Defaults applied to every node ───────────────────────────────────────
  defaults = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [vim wget curl];
    system.stateVersion = "24.05";

    fileSystems."/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["mode=755"];
    };

    boot.loader.grub.enable = false;

    # ◀────────── pass extra arguments to *all* modules
    _module.args = {
      # an empty overlay every node can override
      testOverlay = self: super: {};

      # **the important line** – make the flake inputs visible
      inputs = inputs;
    };
  };

  # ── Hosts ────────────────────────────────────────────────────────────────
  "master-1" = {
    pkgs,
    testOverlay,
    ...
  }: {
    imports = [./modules];
    blackmatter.components.kubernetes = {
      enable = true;
      role = "master";
      overlay = testOverlay;
      etcdPackage = pkgs.etcd;
      containerdPackage = pkgs.containerd;
      nodePortRange = "80-32000";
      extraApiArgs = {"audit-log-maxage" = "10";};
      extraKubeletOpts = "--fail-swap-on=false";
      kubeadmExtra = {apiServer.timeoutForControlPlane = "10m0s";};
      firewallOpen = true;
    };

    networking.hostName = "master-1";
    networking.firewall.allowedTCPPorts = [6443];

    deployment.targetHost = "192.168.1.10";
    deployment.tags = ["masters"];
  };

  "master-2" = {
    pkgs,
    testOverlay,
    ...
  }: {
    imports = [./modules];
    blackmatter.components.kubernetes = {
      enable = true;
      role = "master";
      overlay = testOverlay;
      etcdPackage = pkgs.etcd;
      containerdPackage = pkgs.containerd;
      nodePortRange = "80-32000";
      extraApiArgs = {"audit-log-maxage" = "15";};
      extraKubeletOpts = "--fail-swap-on=false";
      kubeadmExtra = {apiServer.timeoutForControlPlane = "10m0s";};
      firewallOpen = true;
    };

    networking.hostName = "master-2";
    networking.firewall.allowedTCPPorts = [6443];

    deployment.targetHost = "192.168.1.20";
    deployment.tags = ["masters"];
  };

  "worker" = {
    pkgs,
    testOverlay,
    ...
  }: {
    imports = [./modules];
    blackmatter.components.kubernetes = {
      enable = true;
      role = "worker";
      overlay = testOverlay;
      etcdPackage = pkgs.etcd;
      containerdPackage = pkgs.containerd;
      nodePortRange = "30000-32767";
      extraApiArgs = {profiling = "false";};
      extraKubeletOpts = "--node-labels=node-role.kubernetes.io/worker=";
      kubeadmExtra = {
        nodeRegistration.criSocket = "/run/containerd/containerd.sock";
      };
      firewallOpen = false;
      join = {
        address = "192.168.1.10:6443";
        token = "abcdef.0123456789abcdef";
        caHash = "sha256:deadbeefcafebabe0123456789abcdef0123456789abcdef0123456789abcd";
      };
    };

    networking.hostName = "worker";

    deployment.targetHost = "192.168.1.11";
    deployment.tags = ["workers"];
  };

  "single" = {
    pkgs,
    testOverlay,
    ...
  }: {
    imports = [./modules];
    blackmatter.components.kubernetes = {
      enable = true;
      role = "single";
      overlay = testOverlay;
      etcdPackage = pkgs.etcd;
      containerdPackage = pkgs.containerd;
      nodePortRange = "10000-20000";
      extraApiArgs = {"enable-aggregator-routing" = "true";};
      extraKubeletOpts = "--cgroups-per-qos=false";
      kubeadmExtra = {apiServerExtraSANs = ["single.local"];};
      firewallOpen = true;
    };

    networking.hostName = "single";

    deployment.targetHost = "192.168.1.12";
    deployment.tags = ["single"];
  };
}
