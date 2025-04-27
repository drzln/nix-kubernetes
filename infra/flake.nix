{
  description = "nix-kubernetes infra";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.ruby-nix.url = "github:inscapist/ruby-nix";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.colmena = {
    url = "github:zhaofengli/colmena?=master";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {
    nixpkgs,
    ruby-nix,
    flake-utils,
    colmena,
    ...
  } @ inputs:
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
            colmena.packages.${system}.colmena
            aws-nuke
            opentofu
            packer
            ruby
            env
          ];
          shellHook = ''
            export PANGEA_NAMESPACE=pleme
            export AWS_REGION=us-east-1
            export AWS_PROFILE=pleme
            export PATH=$PATH:bin
          '';
        };
      };
    })
    // {
      colmenaHive = import ./hive.nix {inherit inputs;};
    };
}
