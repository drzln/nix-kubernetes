# flake.nix
{
  description = "kubernetes built with nix";
  inputs = {
    nil.url = "github:oxalica/nil";
    deadnix.url = "github:astro/deadnix";
    statix.url = "github:nerdypepper/statix";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-lint.url = "github:nix-community/nixpkgs-lint";
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {
    nil,
    self,
    statix,
    colmena,
    nixpkgs,
    deadnix,
    flake-utils,
    treefmt-nix,
    nixpkgs-lint,
    ...
  }: let
    blackmatterOverlay = import ./overlays/blackmatter-k8s.nix;
  in
    flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [blackmatterOverlay];
      };
      lintBin = "${nixpkgs-lint.packages.${system}.nixpkgs-lint}/bin/nixpkgs-lint";
      statixBin = "${statix.packages.${system}.default}/bin/statix";
      deadnixBin = "${deadnix.packages.${system}.default}/bin/deadnix";
      treefmtBin = "${treefmt-nix.packages.${system}.default}/bin/treefmt";
    in {
      packages = pkgs.blackmatter.k8s;
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          go
          git
          openssh
          nixpkgs-fmt
          nil.packages.${system}.default
          statix.packages.${system}.default
          deadnix.packages.${system}.default
          colmena.packages.${system}.colmena
        ];
      };
      checks = {
        treefmt = pkgs.runCommand "treefmt-check" {} ''
          ${treefmtBin} --fail .
          touch $out
        '';
        nixpkgs-lint = pkgs.runCommand "nixpkgs-lint" {} ''
          ${lintBin} ${self}
          touch $out
        '';
        statix = pkgs.runCommand "statix" {} ''
          ${statixBin} check --ignore W03 --ignore W04 ${self}
          touch $out
        '';
        deadnix = pkgs.runCommand "deadnix" {} ''
          ${deadnixBin} --fail ${self}
          touch $out
        '';
      };
    })
    // {
      overlays.default = blackmatterOverlay;
      nixosModules.kubernetes = ./modules/kubernetes/default.nix;
      colmenaHive = import ./hive.nix {inherit inputs;};
    };
}
