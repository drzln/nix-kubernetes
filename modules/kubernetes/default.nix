{ lib, config, pkgs, ... }:

with lib;

let 
  cfg = config.kubernetes;

  # If an overlay is provided via options, apply it to nixpkgs to get an overlaid pkgs set
  pkgsK8s = if cfg.overlay != null then 
    import config.nixpkgs.path { 
      inherit (config.nixpkgs) config; 
      overlays = [ cfg.overlay ]; 
    } 
    else pkgs;

  # Helper to require a package from pkgsK8s or throw error if not present
  requirePkg = name: lib.mkIf (! builtins.hasAttr name pkgsK8s) (mkThrow "Required package '${name}' not found in provided overlay") // (pkgsK8s.${name});
  
  # Define all the packages we will use, or throw if missing
  etcdPkg       = cfg.etcdPackage or (if pkgsK8s ? etcd then pkgsK8s.etcd else lib.mkThrow "Etcd package not found in overlay. Please provide kubernetes.etcdPackage.");
  containerdPkg = cfg.containerdPackage or (if pkgsK8s ? containerd then pkgsK8s.containerd else lib.mkThrow "Containerd package not found in overlay. Please provide kubernetes.containerdPackage.");
  kubeadmPkg    = if pkgsK8s ? kubeadm then pkgsK8s.kubeadm else lib.mkThrow "kubeadm not found in overlay.";
  kubeletPkg    = if pkgsK8s ? kubelet then pkgsK8s.kubelet else lib.mkThrow "kubelet not found in overlay.";
  kubectlPkg    = if pkgsK8s ? kubectl then pkgsK8s.kubectl else lib.mkThrow "kubectl (kubectl client) not found in overlay.";
  apiserverPkg  = if pkgsK8s ? kube-apiserver then pkgsK8s."kube-apiserver" else lib.mkThrow "kube-apiserver not found in overlay.";
  controllerMgrPkg = if pkgsK8s ? kube-controller-manager then pkgsK8s."kube-controller-manager" else lib.mkThrow "kube-controller-manager not found in overlay.";
  schedulerPkg  = if pkgsK8s ? kube-scheduler then pkgsK8s."kube-scheduler" else lib.mkThrow "kube-scheduler not found in overlay.";
  proxyPkg      = if pkgsK8s ? kube-proxy then pkgsK8s."kube-proxy" else lib.mkThrow "kube-proxy not found in overlay.";
  # Also ensure runc and iptables are available for containerd and kube-proxy
  runcPkg       = if pkgsK8s ? runc then pkgsK8s.runc else lib.mkThrow "runc not found in overlay (needed for containerd runtime).";
  iptablesPkg   = pkgsK8s.iptables;  # iptables is usually in base Nixpkgs

  # Derive common config values
  isMaster = cfg.role == "master" || cfg.role == "single";
  isWorker = cfg.role == "worker";
  hostname = config.networking.hostName or "${config.networking.hostId or "node"}";

  # Paths to config files we will generate
  containerdConfigPath = "/etc/containerd/config.toml";
  kubeadmInitConfPath  = "/etc/kubeadm-init.yaml";
  # (Workers will use CLI args for join, no separate config file needed)
  kubeProxyKubeconfig  = "/etc/kubernetes/kube-proxy.conf";

  # Generate containerd config.toml (minimal, enabling systemd cgroup driver)
  containerdConfig = ''
    [plugins."io.containerd.grpc.v1.cri".containerd]
      snapshotter = "overlayfs"
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
        runtime_type = "io.containerd.runc.v2"
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
          SystemdCgroup = true
  '';

  # Generate kubeadm init configuration YAML (as a string)
  kubeadmInitConfig = let 
    tokenStr = cfg.join.token or null;
    caHashStr = cfg.join.caHash or null;
    extraYaml = cfg.kubeadmExtra or "";
    apiServerExtraArgsMap = builtins.listToAttrs (map (arg:
      let parts = lib.splitString "=" arg;
      in { name = builtins.elemAt parts 0; value = builtins.elemAt parts 1; }
    ) cfg.extraApiArgs) // (if cfg.nodePortRange != null then { "service-node-port-range" = cfg.nodePortRange; } else {});
  in ''
    apiVersion: kubeadm.k8s.io/v1beta3
    kind: InitConfiguration
    localAPIEndpoint:
      advertiseAddress: ${if config.networking.primaryAddress or "" != "" then "${config.networking.primaryAddress}" else "0.0.0.0"}
      bindPort: 6443
    nodeRegistration:
      # CRI socket for containerd
      criSocket: /run/containerd/containerd.sock
      name: ${hostname}
    ---
    apiVersion: kubeadm.k8s.io/v1beta3
    kind: ClusterConfiguration
    kubernetesVersion: "${pkgsK8s.kubelet.version or "1.27.0"}"
    clusterName: "kubernetes"
    networking:
      # Use default serviceSubnet (10.96.0.0/12) and podSubnet left empty (to be set by CNI)
      serviceSubnet: "10.96.0.0/12"
    apiServer:
      extraArgs: { ${concatStringsSep ", " (map (argName: "${argName}: ${toString apiServerExtraArgsMap.${argName}}") (attrNames apiServerExtraArgsMap))} }
    controllerManager:
      extraArgs: {
        "port": "0"
      }
    scheduler:
      extraArgs: {
        "port": "0"
      }
    ${if isMaster then ''
    # External etcd configuration for master
    etcd:
      external:
        endpoints: ["http://127.0.0.1:2379"]''
    else ""}
    ${if tokenStr != null then ''
    bootstrapTokens:
      - token: "${tokenStr}"''
    else ""}
    ${extraYaml}
  '';

in {
  #### Module option definitions ####
  options.kubernetes = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable the custom Kubernetes cluster module.";
    };
    role = mkOption {
      type = types.enum [ "master" "worker" "single" ];
      default = "master";
      description = "Role of this node in the Kubernetes cluster (master/control-plane, worker, or single for all-in-one).";
    };
    overlay = mkOption {
      type = types.nullOr types.anything;
      default = null;
      description = "Optional Nixpkgs overlay to use for Kubernetes packages. If not set, expects that pkgs already includes the necessary Kubernetes package overrides.";
    };
    etcdPackage = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = "Package to use for etcd. If not provided, uses pkgs.etcd from the overlay.";
    };
    containerdPackage = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = "Package to use for containerd. If not provided, uses pkgs.containerd from the overlay.";
    };
    nodePortRange = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "30000-32767";
      description = "Port range for NodePort services (e.g. \"30000-32767\"). If set, the API server will be configured to allow NodePorts in this range.";
    };
    extraApiArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "--enable-admission-plugins=NamespaceLifecycle,NodeRestriction" ];
      description = "Extra arguments to pass to the kube-apiserver process.";
    };
    extraKubeletOpts = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "--node-labels=env=test" ];
      description = "Extra command-line options to pass to the kubelet service.";
    };
    kubeadmExtra = mkOption {
      type = types.str;
      default = "";
      description = "Extra YAML to append to the kubeadm init configuration (for advanced customization).";
    };
    firewallOpen = mkOption {
      type = types.bool;
      default = false;
      description = "If true, open Kubernetes-related ports in the firewall (API server, NodePort range, etc.).";
    };
    join = {
      address = mkOption {
        type = types.str;
        default = "";
        description = "API server address (host or host:port) to join for worker nodes.";
      };
      token = mkOption {
        type = types.str;
        default = "";
        description = "Kubeadm discovery token for joining the cluster (worker nodes).";
      };
      caHash = mkOption {
        type = types.str;
        default = "";
        description = "SHA256 hash of the cluster CA cert (from kubeadm init) for secure join (worker nodes).";
      };
    };
  };

  #### Configuration when module is enabled ####
  config = mkIf cfg.enable {
    # Ensure the role is properly set if enabled
    assertions = mkIf cfg.enable [
      {
        condition = cfg.role == "master" || cfg.role == "worker" || cfg.role == "single";
        message = "kubernetes.role must be one of \"master\", \"worker\", or \"single\".";
      } // {
        condition = !isWorker || (cfg.join.address != "" && cfg.join.token != "" && cfg.join.caHash != "");
        message = "When kubernetes.role = \"worker\", you must set join.address, join.token, and join.caHash.";
      }
    ];

    # Define system user and group for etcd (for running etcd service as non-root)
    users.groups.etcd = { };
    users.users.etcd = {
      description = "etcd user";
      isSystemUser = true;
      group = "etcd";
      home = "/var/lib/etcd";
      shell = "/run/current-system/sw/bin/nologin";
    };
    # Optionally, we could also run kubelet as non-root, but root is typically needed for kubelet. So no separate kubelet user.
    users.groups.kubelet = { };
    users.users.kubelet = {
      description = "kubelet user";
      isSystemUser = true;
      group = "kubelet";
      home = "/var/lib/kubelet";
      shell = "/run/current-system/sw/bin/nologin";
    };

    # Persistent directories and file permissions
    systemd.tmpfiles.rules = [
      # Etcd data directory
      "d /var/lib/etcd 0700 etcd etcd"
      # Kubelet directory
      "d /var/lib/kubelet 0750 kubelet kubelet"
      # Kubernetes etc directory for configs/certs (persist across rebuilds)
      "d /etc/kubernetes 0755 root root"
      # CNI config directory (in case user deploys a CNI plugin; empty by default)
      "d /etc/cni/net.d 0755 root root"
    ];

    # Etc configuration files
    environment.etc = {
      "containerd/config.toml" = {
        text = containerdConfig;
        mode = "0644";
      };
      "kubeadm-init.yaml" = mkIf (isMaster) {
        text = kubeadmInitConfig;
        mode = "0644";
      };
      # Generate a kube-proxy kubeconfig using admin.conf (for simplicity)
      "kubernetes/kube-proxy.conf" = {
        text = ''
          apiVersion: v1
          kind: Config
          clusters:
          - cluster:
              certificate-authority: "/etc/kubernetes/pki/ca.crt"
              server: https://127.0.0.1:6443
            name: kubernetes
          contexts:
          - context:
              cluster: kubernetes
              user: kube-proxy
            name: kube-proxy@kubernetes
          current-context: kube-proxy@kubernetes
          preferences: {}
          users:
          - name: kube-proxy
            user:
              client-certificate: "/etc/kubernetes/pki/apiserver-kubelet-client.crt"
              client-key: "/etc/kubernetes/pki/apiserver-kubelet-client.key"
        '';
        # ^ We reuse the apiserver-kubelet-client credentials for kube-proxy authentication.
        mode = "0644";
      };
    };

    # systemd services
    systemd.services = {

      # Etcd service (only on master/single nodes)
      etcd = mkIf isMaster {
        description = "Etcd key-value store for Kubernetes";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        user = "etcd";
        group = "etcd";
        # Run etcd on localhost client interface for security (no TLS for simplicity)
        environment = {
          ETCD_NAME = hostname;
          ETCD_DATA_DIR = "/var/lib/etcd";
          ETCD_LISTEN_CLIENT_URLS = "http://127.0.0.1:2379";
          ETCD_ADVERTISE_CLIENT_URLS = "http://127.0.0.1:2379";
          # Peer URLs not used as single node (if multi-node etcd, these would need to be configured)
          ETCD_LISTEN_PEER_URLS = "http://127.0.0.1:2380";
          ETCD_INITIAL_ADVERTISE_PEER_URLS = "http://127.0.0.1:2380";
          ETCD_INITIAL_CLUSTER = "${hostname}=http://127.0.0.1:2380";
          ETCD_INITIAL_CLUSTER_STATE = "new";
          ETCD_INITIAL_CLUSTER_TOKEN = "etcd-cluster";
        };
        serviceConfig = {
          ExecStart = "${etcdPkg}/bin/etcd";
          Restart = "on-failure";
        };
      };

      # Containerd service (on all nodes)
      containerd = {
        description = "Containerd container runtime";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        environment = { 
          # No special env needed, but ensure PATH has runc and other deps
        };
        path = [ containerdPkg runcPkg ];
        serviceConfig = {
          ExecStart = "${containerdPkg}/bin/containerd --config ${containerdConfigPath}";
          Restart = "always";
        };
      };

      # Kubeadm init (oneshot on master)
      "kubeadm-init" = mkIf isMaster {
        description = "Kubernetes cluster initialization (kubeadm)";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "containerd.service" "etcd.service" ];
        # Only run if not already initialized (i.e., if CA cert doesn't exist yet)
        conditionPathExists = "!/etc/kubernetes/pki/ca.crt";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${kubeadmPkg}/bin/kubeadm init --config ${kubeadmInitConfPath} --skip-phases=etcd,wait-control-plane,control-plane,kubelet-start,mark-control-plane,addon/kube-proxy,addon/coredns";
          # The above skips: etcd & control-plane (we manage them), waiting for control-plane (we'll start it), marking the master (we'll do manually), and addon deployments.
          # It still generates certs and kubeconfigs.
          Restart = "no";
        };
      };

      # Kubeadm join (oneshot on workers)
      "kubeadm-join" = mkIf isWorker {
        description = "Join Kubernetes cluster (kubeadm)";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "network-online.target" "containerd.service" ];
        # Only run if this node isn't already joined (use absence of kubelet.conf as indicator)
        conditionPathExists = "!/etc/kubernetes/kubelet.conf";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = ''
            ${kubeadmPkg}/bin/kubeadm join ${cfg.join.address} \
              --token ${cfg.join.token} \
              --discovery-token-ca-cert-hash sha256:${cfg.join.caHash} \
              --cri-socket unix:///run/containerd/containerd.sock
          '';
          Restart = "no";
        };
      };

      # Kubernetes API server (master only)
      "kube-apiserver" = mkIf isMaster {
        description = "Kubernetes API Server";
        after = [ "kubeadm-init.service" "etcd.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = ''
            ${apiserverPkg}/bin/kube-apiserver \
              --advertise-address=0.0.0.0 \
              --bind-address=0.0.0.0 \
              --secure-port=6443 \
              --cert-dir=/etc/kubernetes/pki \
              --tls-cert-file=/etc/kubernetes/pki/apiserver.crt \
              --tls-private-key-file=/etc/kubernetes/pki/apiserver.key \
              --client-ca-file=/etc/kubernetes/pki/ca.crt \
              --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt \
              --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key \
              --etcd-servers=http://127.0.0.1:2379 \
              --etcd-cafile=/dev/null --etcd-certfile=/dev/null --etcd-keyfile=/dev/null \
              --service-cluster-ip-range=10.96.0.0/12 \
              --authorization-mode=Node,RBAC \
              --insecure-port=0 \
              ${optionalString (cfg.nodePortRange != null) "--service-node-port-range=${cfg.nodePortRange}"} \
              ${concatStringsSep " " cfg.extraApiArgs}
          '';
          User = "root";  # apiserver needs to bind 6443 (root) and access certs
          Restart = "always";
          LimitNOFILE = 65536;
        };
      };

      # Kubernetes Controller Manager (master only)
      "kube-controller-manager" = mkIf isMaster {
        description = "Kubernetes Controller Manager";
        after = [ "kube-apiserver.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = ''
            ${controllerMgrPkg}/bin/kube-controller-manager \
              --bind-address=127.0.0.1 \
              --secure-port=10257 \
              --kubeconfig=/etc/kubernetes/controller-manager.conf \
              --cluster-name=kubernetes \
              --leader-elect=true \
              --controllers=*,bootstrapsigner,tokencleaner \
              --cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt \
              --cluster-signing-key-file=/etc/kubernetes/pki/ca.key \
              --root-ca-file=/etc/kubernetes/pki/ca.crt \
              --service-account-private-key-file=/etc/kubernetes/pki/sa.key \
              --use-service-account-credentials=true \
              --port=0
          '';
          User = "root";
          Restart = "always";
        };
      };

      # Kubernetes Scheduler (master only)
      "kube-scheduler" = mkIf isMaster {
        description = "Kubernetes Scheduler";
        after = [ "kube-apiserver.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = ''
            ${schedulerPkg}/bin/kube-scheduler \
              --bind-address=127.0.0.1 \
              --kubeconfig=/etc/kubernetes/scheduler.conf \
              --leader-elect=true \
              --port=0
          '';
          User = "root";
          Restart = "always";
        };
      };

      # Kubelet service (runs on all nodes)
      kubelet = {
        description = "Kubernetes Kubelet";
        after = lib.optional isMaster "kube-apiserver.service" ++ lib.optional isWorker "kubeadm-join.service" ++ [ "containerd.service" "network-online.target" ];
        requires = [ "containerd.service" ];
        wantedBy = [ "multi-user.target" ];
        environment = {
          KUBELET_EXTRA_ARGS = "${concatStringsSep " " cfg.extraKubeletOpts}";
          HOME = "/var/lib/kubelet";
        };
        # Only start kubelet when it has a kubeconfig (master will have /etc/kubernetes/kubelet.conf from kubeadm init; worker will have bootstrap conf after join)
        conditionPathExists = mkIf isMaster "/etc/kubernetes/kubelet.conf" // mkIf isWorker "/etc/kubernetes/bootstrap-kubelet.conf";
        path = [ kubeletPkg ];
        serviceConfig = {
          ExecStart = ''
            ${kubeletPkg}/bin/kubelet \
              --container-runtime=remote \
              --container-runtime-endpoint=unix:///run/containerd/containerd.sock \
              --fail-swap-on=false \
              --cgroup-driver=systemd \
              --pod-manifest-path=/etc/kubernetes/manifests-empty \
              --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf \
              --kubeconfig=/etc/kubernetes/kubelet.conf \
              --network-plugin=cni \
              --register-node=true \
              --v=2
          '';
          # Note: /etc/kubernetes/manifests-empty is an empty dir we don't create, but passing a non-existent path disables static pod check.
          # Alternatively, we could omit --pod-manifest-path to not use static pods at all.
          Restart = "always";
        };
      };

      # Kube-Proxy service (runs on all nodes)
      "kube-proxy" = {
        description = "Kubernetes Proxy (runs on each node to handle Service networking)";
        after = [ "kubelet.service" "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        path = [ proxyPkg iptablesPkg ];
        serviceConfig = {
          ExecStart = ''
            ${proxyPkg}/bin/kube-proxy \
              --hostname-override=${hostname} \
              --kubeconfig=${kubeProxyKubeconfig} \
              --cluster-cidr=0.0.0.0/0 \
              --v=2
          '';
          # (cluster-cidr can be set to your pod network CIDR if known; 0.0.0.0/0 here means accept all for iptables rules if unknown)
          Restart = "always";
        };
      };

      # Service to label/taint master nodes appropriately (and untaint if single)
      "kube-mark-master" = mkIf isMaster {
        description = "Label and Taint master node (and untaint if single)";
        after = [ "kube-apiserver.service" "kubelet.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''
            #!/bin/bash
            set -e
            export KUBECONFIG=/etc/kubernetes/admin.conf
            # Label node as master
            ${kubectlPkg}/bin/kubectl label node ${hostname} node-role.kubernetes.io/master="";
            ${if cfg.role == "single" then ''
            # Remove master NoSchedule taint for single node so it can schedule pods
            ${kubectlPkg}/bin/kubectl taint nodes ${hostname} node-role.kubernetes.io/master:NoSchedule- || true
            '' else ''
            # Add master NoSchedule taint to prevent workload pods on master
            ${kubectlPkg}/bin/kubectl taint nodes ${hostname} node-role.kubernetes.io/master:NoSchedule || true
            ''}
          '';
        };
      };
    };

    # Firewall settings if enabled
    networking.firewall = mkIf cfg.firewallOpen {
      enable = true;
      # Determine NodePort range (default if not set)
      allowedTCPPorts = let 
        range = cfg.nodePortRange or "30000-32767";
        portsList = builtins.elemAt (lib.splitString "-" range) 0;
      in [ 6443 2379 2380 10250 ] ++ (if cfg.nodePortRange or null != null then [ (import <nixpkgs> {}).lib.range (builtins.parseInt (builtins.elemAt (lib.splitString "-" range) 0)) (builtins.parseInt (builtins.elemAt (lib.splitString "-" range) 1)) ] else []);
      # The above opens:
      #  - 6443 (API server)
      #  - 2379-2380 (etcd peer/client; etcd is local so these could be optional, but include for completeness in multi-master)
      #  - 10250 (secure kubelet port for API->kubelet communications)
      #  - NodePort range (all ports in the specified range)
    };
  };
}
