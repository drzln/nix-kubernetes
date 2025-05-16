# flake.nix
{
  description = "Flake for Golang-based Pulumi Kubernetes provisioning";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages.default = pkgs.buildGoModule {
          pname = "kubelet-provisioning";
          version = "0.1.0";
          src = ./.;
          vendorHash = null;
          nativeBuildInputs = [pkgs.pulumi pkgs.git];
          ldflags = ["-s" "-w"];
        };
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.go
            pkgs.gopls
            pkgs.gotools
            pkgs.pulumi
            # pkgs.pulumiPackages.pulumi-kubernetes
            pkgs.kubectl
          ];
          shellHook = ''
            export KUBECONFIG=/run/secrets/kubernetes/configs/admin/kubeconfig
          '';
        };
      }
    );
}
