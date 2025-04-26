{
  description = "nix-kubernetes infra";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.ruby-nix.url = "github:inscapist/ruby-nix";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = {
    nixpkgs,
    ruby-nix,
    flake-utils,
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
      };
      devShells = rec {
        default = dev;
        dev = pkgs.mkShell {
          buildInputs = with pkgs; [
            aws-nuke
            opentofu
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
