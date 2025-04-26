{
  description = "nix-kubernetes infra";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.ruby-nix.url = "github:inscapist/ruby-nix";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.pangea.url = "path:gems/pangea";

  outputs = {
    nixpkgs,
    ruby-nix,
    flake-utils,
    pangea,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ruby-nix.overlays.ruby];
      };
      rnix = ruby-nix.lib pkgs;
      rnix-env = rnix {
        name = "nix";
        gemset = ./gemset.nix;
      };
      env = rnix-env.env;
      ruby = rnix-env.ruby;
    in {
      packages = {
        inherit env ruby;
        pangea = pangea.packages.${system}.pangea;
      };
      devShells = rec {
        default = dev;
        dev = pkgs.mkShell {
          buildInputs = with pkgs; [
            pangea.packages.${system}.pangea
            aws-nuke
            opentofu
            minikube
            kubernetes-helm
            kubectl
            packer
            ruby
            env
          ];
          shellHook = ''
            export AWS_REGION=us-east-1
            export PANGEA_NAMESPACE=pleme
            export AWS_PROFILE=pleme
            export PATH=$PATH:bin
          '';
        };
      };
    });
}
