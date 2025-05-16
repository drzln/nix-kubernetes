# flake.nix
{
  description = "golang pulumi";
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
        pulumi-go-env = pkgs.buildGoModule {
          pname = "kubelet-provisioning";
          version = "0.1.0";
          src = ./.;
          vendorHash = null;
          nativeBuildInputs = [pkgs.pulumi pkgs.git];
          buildPhase = ''
            go build -o $out/bin/pulumi-kubelet
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp pulumi-kubelet $out/bin/
          '';
        };
      in {
        packages.default = pulumi-go-env;
        devShells.default = pkgs.mkShell {
          buildInputs = [
            # pkgs.pulumiPackages.pulumi-kubernetes
            pkgs.go
            pkgs.gopls
            pkgs.gotools
            pkgs.pulumi
            pkgs.kubectl
          ];
          shellHook = ''
            export KUBECONFIG=/run/secrets/kubernetes/configs/admin/kubeconfig
          '';
        };
      }
    );
}
