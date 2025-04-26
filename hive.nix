{inputs, ...}:
inputs.colmena.lib.makeHive {
  meta.nixpkgs = import inputs.nixpkgs {system = "x86_64-linux";};

  # ─────────────────────────── Defaults ────────────────────────────
  defaults = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [vim wget curl];
    system.stateVersion = "24.05";

    # tmp root so evaluation succeeds on the CI host
    fileSystems."/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["mode=755"];
    };
    boot.loader.grub.enable = false;

    # simple no-op overlay value used by all nodes
    _module.args.testOverlay = self: super: {}; # <- attrset fulfils type
  };

  # ─────────────────────────── Nodes ───────────────────────────────

  master = {
    pkgs,
    testOverlay,
    ...
  }: {
    imports = [./modules];

    blackmatter.components.kubernetes = {
      enable = true;
      role = "master";
      overlay = testOverlay; # exercised
      etcdPackage = pkgs.etcd;
      containerdPackage = pkgs.containerd;

      nodePortRange = "80-32000";
      extraApiArgs = {"audit-log-maxage" = "10";};
      extraKubeletOpts = "--fail-swap-on=false";
      kubeadmExtra = {apiServer = {timeoutForControlPlane = "10m0s";};};

      firewallOpen = true; # open the host firewall
      # join.* not used on masters
    };

    networking.hostName = "master";
    networking.firewall.allowedTCPPorts = [6443];
    deployment.targetHost = "192.168.1.10";
    deployment.tags = ["masters"];
  };

  "worker-1" = {
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
      extraApiArgs = {"profiling" = "false";};
      extraKubeletOpts = "--node-labels=node-role.kubernetes.io/worker=";
      kubeadmExtra = {nodeRegistration = {criSocket = "/run/containerd/containerd.sock";};};

      firewallOpen = false; # keep host firewall disabled

      join = {
        address = "192.168.1.10:6443";
        token = "abcdef.0123456789abcdef";
        caHash = "sha256:deadbeefcafebabe0123456789abcdef0123456789abcdef0123456789abcd";
      };
    };

    networking.hostName = "worker-1";
    deployment.targetHost = "192.168.1.11";
    deployment.tags = ["workers"];
  };

  "worker-2" = {
    pkgs,
    testOverlay,
    ...
  }: {
    imports = [./modules];

    blackmatter.components.kubernetes = {
      enable = true;
      role = "single"; # all-in-one worker-master
      overlay = testOverlay;
      etcdPackage = pkgs.etcd;
      containerdPackage = pkgs.containerd;

      nodePortRange = "10000-20000";
      extraApiArgs = {"enable-aggregator-routing" = "true";};
      extraKubeletOpts = "--cgroups-per-qos=false";
      kubeadmExtra = {apiServerExtraSANs = ["worker-2.local"];};

      firewallOpen = true;

      # join unused on a “single” node
    };

    networking.hostName = "worker-2";
    deployment.targetHost = "192.168.1.12";
    deployment.tags = ["workers"];
  };
}
