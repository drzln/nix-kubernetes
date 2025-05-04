###############################################################################
#  nix-kubernetes/flake.nix   (namespace = pkgs.blackmatter.k8s.*)
###############################################################################
{
  description = "Bare-Metal Kubernetes";

  #######################################
  ## ░░ Inputs
  #######################################
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Tooling / formatting / linting
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nixpkgs-lint.url = "github:nix-community/nixpkgs-lint";
    statix.url = "github:nerdypepper/statix";
    deadnix.url = "github:astro/deadnix";
    nil.url = "github:oxalica/nil";

    # Deployment
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
    # ── Overlay: put everything under pkgs.blackmatter.k8s ────────────────
    blackmatterOverlay = import ./overlays/blackmatter-k8s.nix;
  in
    flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [blackmatterOverlay];
      };

      # Paths to external tooling (for checks)
      lintBin = "${nixpkgs-lint.packages.${system}.nixpkgs-lint}/bin/nixpkgs-lint";
      statixBin = "${statix.packages.${system}.default}/bin/statix";
      deadnixBin = "${deadnix.packages.${system}.default}/bin/deadnix";
    in {
      ######################################################################
      # 1. Packages  – surfaced directly under pkgs.blackmatter.k8s
      ######################################################################
      packages = pkgs.blackmatter.k8s;
      defaultPackage = pkgs.blackmatter.k8s.cilium-cli or pkgs.blackmatter.k8s.kubectl;

      ######################################################################
      # 2. Dev shell
      ######################################################################
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          go
          git
          openssh
          nixpkgs-fmt
          statix.deadnix
          nil
          colmena.packages.${system}.colmena
        ];
      };

      ######################################################################
      # 3. Checks wired into `nix flake check`
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
    ##  Top-level, system-independent outputs
    ## ────────────────────────────────────────────────────────────────────
    // {
      overlays.default = blackmatterOverlay;
      nixosModules.kubernetes = ./modules/kubernetes/default.nix;
      colmenaHive = import ./hive.nix {inherit inputs;};
    };
}
