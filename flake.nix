{
  description = "kubernetes";

  inputs = {
    nixpkgs      .url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils  .url = "github:numtide/flake-utils";

    # working linter inputs
    nixpkgs-lint .url = "github:nix-community/nixpkgs-lint";
    # pin statix at a tag to avoid GitHub HEAD lookup
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
    ...
  }: let
    overlayList = import ./overlays;
  in
    flake-utils.lib.eachDefaultSystem (system: let
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
          ${statixBin} check \
            --ignore W03 \
            --ignore W04 \
          ${self}
          touch $out
        '';
      };
    })
    // {
      nixosModules.kubernetes = ./modules;
    };
}
