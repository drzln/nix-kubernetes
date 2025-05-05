# infra/packer/templates/kubernetes/configuration.nix
{
  # config,
  pkgs,
  ...
}: {
  # Import the default AWS EC2 profile for NixOS to get EC2-friendly defaults
  imports = [
    <nixpkgs/nixos/modules/virtualisation/amazon-image.nix>
  ];
  system.stateVersion = "24.11";

  networking.firewall.enable = false; # disable firewall (K8s will manage networking)&#8203;:contentReference[oaicite:6]{index=6}
  networking.hostName = "nixos-k8s-base"; # default hostname (can be overridden via EC2 metadata)

  # NTP for clock sync (important for distributed systems like K8s)
  services.ntp.enable = true;

  # CRI-O Container Runtime Configuration
  virtualisation.cri-o.enable = true; # Enable CRI-O service&#8203;:contentReference[oaicite:7]{index=7}
  virtualisation.cri-o.storageDriver = "overlay"; # Use overlay FS for containers (good on Amazon Linux/EBS)
  # (By default CRI-O will listen on /var/run/crio/crio.sock for the kubelet)

  # Boot and Kernel settings for AWS and Kubernetes
  boot.kernelPackages = pkgs.linuxPackages_latest; # Use latest kernel for eBPF features&#8203;:contentReference[oaicite:1]{index=1}
  boot.kernelModules = ["br_netfilter" "overlay" "nvme" "ena"];
  # - `br_netfilter` and `overlay` are needed for container networking and storage&#8203;:contentReference[oaicite:2]{index=2}.
  # - `nvme` and `ena` ensure NVMe EBS volumes and enhanced networking (ENA) are supported on AWS.
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1; # enable IP forwarding (for pod networking)&#8203;:contentReference[oaicite:3]{index=3}
    "net.ipv6.conf.all.forwarding" = 1;
    "net.bridge.bridge-nf-call-iptables" = 1; # ensure iptables sees bridged traffic&#8203;:contentReference[oaicite:4]{index=4}
    "net.bridge.bridge-nf-call-ip6tables" = 1;
  };
  # boot.swapDevices = []; # disable swap - Kubernetes requires swap off&#8203;:contentReference[oaicite:5]{index=5}

  # Kubernetes components installation (kubelet, kubectl, kubeadm, etc.)
  # We won't auto-start the cluster (no kubeadm init here), just prepare binaries and config.
  environment.systemPackages = with pkgs; [
    kubernetes.kubeadm # kubeadm tool (for initializing or joining clusters later)
    kubernetes.kubectl # kubectl CLI for managing Kubernetes
    kubernetes.kubelet # kubelet binary (node agent)
    cni-plugins # base CNI plugins (e.g. loopback) required by Cilium
    cilium-cli
    awscli # AWS CLI for any AWS API interactions (optional, for S3, etc.)
    etcd # Etcd (if this node may serve as control-plane, e.g. for kube-apiserver)
    # (Etcd is included so a control-plane node can run its own etcd if needed in a future role)
  ];

  # Kubernetes kubelet configuration (not starting by default, but ready to run)
  services.kubernetes.kubelet.enable = true;
  # services.kubernetes.kubelet.configureIPv6 = false;
  services.kubernetes.kubelet.cni.packages = [pkgs.cni-plugins];
  # ^ Use only Cilium for CNI (replacing flannel)&#8203;:contentReference[oaicite:8]{index=8}. The cni-plugins package provides essentials like loopback.
  services.kubernetes.kubelet.containerRuntimeEndpoint = "unix:///var/run/crio/crio.sock";
  # ^ Tell kubelet to use CRI-O's socket for CRI instead of Docker. This integrates kubelet with CRI-O runtime.
  services.kubernetes.kubelet.extraOpts = "--cgroup-driver=systemd";
  # ^ Use systemd for cgroups (matches NixOS system, ensures compatibility between kubelet and CRI-O).

  # (We do **not** enable the Kubernetes master components by default. The image is a generic base;
  # to make a control-plane node, one can enable `services.kubernetes.apiserver` and others via config or use kubeadm on boot.)

  # Minimal security hardening (can be expanded later)
  security.sudo.enable = true;
  users.users.root.openssh.authorizedKeys.keyFiles = ["/root/.ssh/authorized_keys"];
  # (SSH key will be provided by AWS at instance launch via EC2 userdata/metadata)
}
