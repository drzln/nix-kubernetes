# hive.nix
{
  inputs, # <-- required by Colmena >= 0.5
  ...
}:
inputs.colmena.lib.makeHive {
  ##########################################################################
  ## Global metadata & defaults (apply to all nodes)
  ##########################################################################
  meta.nixpkgs = import inputs.nixpkgs {
    system = "x86_64-linux"; # host platform used for evaluation
  };

  defaults = {pkgs, ...}: {
    ##################################
    ## Make flake inputs visible to every module
    _module.args.inputs = inputs;

    ## (optional) overlay stub you can override per-node
    _module.args.testOverlay = self: super: {};

    ##################################
    ## Small, common base system
    environment.systemPackages = with pkgs; [vim wget curl];
    system.stateVersion = "24.05";

    fileSystems."/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["mode=755"];
    };

    boot.loader.grub.enable = false;
  };

  ##########################################################################
  ## Nodes
  ##########################################################################

  # ─────────────── Masters ────────────────────────────────────────────────
  master-1 = {
    pkgs,
    testOverlay,
    ...
  }: {
    imports = [./modules]; # directory that contains your BM module

    blackmatter.components.kubernetes = {
      enable = true;
      role = "master";
      overlay = testOverlay; # leave as null if you don’t override
      etcdPackage = pkgs.etcd;
      containerdPackage = pkgs.containerd;

      nodePortRange = "80-32000";
      extraApiArgs = {"audit-log-maxage" = "10";};
      extraKubeletOpts = "--fail-swap-on=false";
      kubeadmExtra = {
        apiServer = {timeoutForControlPlane = "10m0s";};
      };
      firewallOpen = true;
    };

    networking.hostName = "master-1";
    networking.firewall.allowedTCPPorts = [6443];

    deployment.targetHost = "192.168.1.10";
    deployment.tags = ["masters"];
  };

  master-2 = {
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
      kubeadmExtra = {
        apiServer = {timeoutForControlPlane = "10m0s";};
      };
      firewallOpen = true;
    };

    networking.hostName = "master-2";
    networking.firewall.allowedTCPPorts = [6443];

    deployment.targetHost = "192.168.1.20";
    deployment.tags = ["masters"];
  };

  # ─────────────── Worker ────────────────────────────────────────────────
  worker = {
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
      kubeadmExtra = {
        nodeRegistration = {
          criSocket = "/run/containerd/containerd.sock";
        };
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

  # ─────────────── All-in-one node ───────────────────────────────────────
  single = {
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
      kubeadmExtra = {
        apiServerExtraSANs = ["single.local"];
      };
      firewallOpen = true;
    };

    networking.hostName = "single";

    deployment.targetHost = "192.168.1.12";
    deployment.tags = ["single"];
  };
}
