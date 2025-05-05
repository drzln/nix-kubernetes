{
  description = "Self-contained Kubernetes stack built entirely with Nix";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nixpkgs-lint.url = "github:nix-community/nixpkgs-lint";
    statix.url = "github:nerdypepper/statix";
    deadnix.url = "github:astro/deadnix";
    nil.url = "github:oxalica/nil";
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    treefmt-nix,
    nixpkgs-lint,
    statix,
    deadnix,
    nil,
    colmena,
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
          statix.packages.${system}.default
          deadnix.packages.${system}.default
          nil.packages.${system}.default
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
