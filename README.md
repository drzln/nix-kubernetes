# nix-kubernetes

**Build Kubernetes with Nix, component by component.**

`nix-kubernetes` is a modular, declarative framework for provisioning Kubernetes clusters using Nix. It enables reproducible, composable, and secure infrastructure by leveraging Nix's functional configuration model.

---

## ✨ Features

- **Modular Design**: Configure Kubernetes components (e.g., kubelet, etcd, API server) individually using NixOS modules.
- **Flake-Based**: Utilizes Nix flakes for reproducible builds and streamlined dependency management.
- **Secrets Management**: Integrates with `sops-nix` for secure handling of secrets.
- **Home Manager & Darwin Support**: Supports both NixOS and macOS configurations via `home-manager` and `nix-darwin`.
- **Composable Overlays**: Easily extend or override packages and configurations.
- **Static Control Plane**: Optionally deploy Kubernetes control plane components as static pods.

---

## 📁 Repository Structure

```
.
├── flake.nix               # Entry point for the flake
├── flake.lock              # Flake lock file for reproducibility
├── parts/                  # Flake parts for overlays, packages, NixOS, home, and Darwin configurations
├── modules/
│   └── kubernetes/         # NixOS modules for Kubernetes components
├── nixosConfigurations/    # NixOS host configurations
├── overlays/               # Custom package overlays
├── pkgs/                   # Custom packages
├── scripts/                # Utility scripts
└── hive.nix                # Colmena deployment configuration
```

---

## 🚀 Getting Started

### Prerequisites

- Install [Nix](https://nixos.org/download.html) with flakes enabled.
- Install [direnv](https://direnv.net/) and [lorri](https://github.com/target/lorri) for environment management (optional but recommended).

### Clone the Repository

```bash
git clone https://github.com/drzln/nix-kubernetes.git
cd nix-kubernetes
```

### Explore Configurations

```bash
# List available NixOS configurations
nix flake show

# Build a specific configuration (e.g., 'plo')
nix build .#nixosConfigurations.plo.config.system.build.toplevel
```

### Deploy with Colmena

```bash
# Apply the 'plo' configuration to the target host
colmena apply --node plo
```

---

## 🧩 Example: Enabling Kubelet with Static Control Plane

In your NixOS configuration:

```nix
{
  blackmatter.components.kubernetes.services.kubelet = {
    enable = true;
    staticControlPlane = {
      enable = true;
      kubernetesVersion = "v1.30.1";
      serviceCIDR = "10.96.0.0/12";
    };
  };
}
```

This configuration sets up the kubelet service and deploys the control plane components (API server, controller manager, scheduler, etcd) as static pods.

---

## 🔐 Secrets Management with sops-nix

To manage secrets securely:

1. Define secrets in your configuration:

   ```nix
   {
     sops.secrets."kubernetes/ca.key" = {
       sopsFile = ./secrets.yaml;
     };
   }
   ```

2. Ensure the `sops-nix` module is included and properly configured.

This setup allows you to manage sensitive data securely and declaratively.

---

## 📚 Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)
- [Home Manager](https://nix-community.github.io/home-manager/)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [Colmena](https://github.com/zhaofengli/colmena)

---

## 🤝 Contributing

Contributions are welcome! Please open issues or submit pull requests for enhancements, bug fixes, or documentation improvements.

---

## 📄 License

This project is licensed under the [Apache 2.0 License](LICENSE).
