{
  description = "kubernetes";

  inputs = {
    nixpkgs      .url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils  .url = "github:numtide/flake-utils";
    nixpkgs-lint .url = "github:nix-community/nixpkgs-lint";
    nmt = {
      url = "github:jooooscha/nmt";
      flake = false;
    };
    statix = {
      url = "github:oppiliappan/statix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    statix,
    nixpkgs-lint,
    nmt,
    ...
  } @ outputs: let
    overlayList = import ./overlays;
  in
    flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = overlayList;
      };

      packages' = with import ./pkgs/etcd pkgs;
      with import ./pkgs/cilium pkgs;
      with import ./pkgs/containerd pkgs;
      with pkgs; {
        inherit
          kubelet
          kubectl
          kube-apiserver
          kube-controller-manager
          kube-scheduler
          etcdserver
          containerd
          cilium-cli
          etcdctl
          etcdutl
          etcd
          runc
          ;
        default = pkgs.cilium-cli;
      };

      lintBin = "${nixpkgs-lint.packages.${system}.nixpkgs-lint}/bin/nixpkgs-lint";
      statixBin = "${statix.packages.${system}.default}/bin/statix";
    in {
      packages = packages';

      checks = {
        nixpkgs-lint = pkgs.runCommand "nixpkgs-lint-check" {} ''
          ${lintBin} ${self}
          touch $out
        '';
        statix = pkgs.runCommand "statix-check" {} ''
          ${statixBin} check --ignore W03 W04 ${self}
          touch $out
        '';
        nmt-check = pkgs.stdenv.mkDerivation {
          name = "nmt-check";
          src = nmt;
          buildInputs = [pkgs.nix];
          dontBuild = true;
          installPhase = ''
            mkdir -p $out
            export PATH=$PATH:${pkgs.nix}/bin
            nix-instantiate --eval -E "(import ./tests/k8s/options.nix {})"
          '';
        };
      };
    })
    // {
      nixosModules.kubernetes = ./modules;
    };
}
