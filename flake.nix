###############################################################################
#  flake.nix  – blackmatter.k8s namespace (fixed devShell & checks)
###############################################################################
{
  description = "Self-contained Kubernetes stack built entirely with Nix";

  #######################################
  ## ░░ Inputs
  #######################################
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

  #######################################
  ## ░░ Outputs
  #######################################
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
    # Overlay puts packages under pkgs.blackmatter.k8s
    blackmatterOverlay = import ./overlays/blackmatter-k8s.nix;
  in
    flake-utils.lib.eachSystem ["x86_64-linux"]
    ({
      system,
      pkgs,
      inputs',
      ...
    }: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [blackmatterOverlay];
      };

      # external tools for checks
      lintBin = "${nixpkgs-lint.packages.${system}.nixpkgs-lint}/bin/nixpkgs-lint";
      statixBin = "${inputs'.statix.packages.${system}.default}/bin/statix";
      deadnixBin = "${inputs'.deadnix.packages.${system}.default}/bin/deadnix";
    in {
      ######################################################################
      # 1. Packages
      ######################################################################
      packages = pkgs.blackmatter.k8s;
      defaultPackage = pkgs.blackmatter.k8s.cilium-cli or pkgs.blackmatter.k8s.kubectl;

      ######################################################################
      # 2. Dev shell  (fixed buildInputs)
      ######################################################################
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          go
          git
          openssh
          nixpkgs-fmt
          inputs'.statix.packages.${system}.default
          inputs'.deadnix.packages.${system}.default
          inputs'.nil.packages.${system}.default
          colmena.packages.${system}.colmena
        ];
      };

      ######################################################################
      # 3. Checks
      ######################################################################
      checks = {
        treefmt = treefmt-nix.lib.${system}.run {
          directories = ["."];
          programs.nixpkgs-fmt.enable = true;
        };

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
    ## ────────────────────────────────────────────────────────────────────
    ##  Top-level outputs
    ## ────────────────────────────────────────────────────────────────────
    // {
      overlays.default = blackmatterOverlay;
      nixosModules.kubernetes = ./modules/kubernetes/default.nix;
      colmenaHive = import ./hive.nix {inherit inputs;};
    };
}
