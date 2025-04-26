{
  description = "kubernetes";

  inputs = {
    nixpkgs      .url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils  .url = "github:numtide/flake-utils";
    nixpkgs-lint .url = "github:nix-community/nixpkgs-lint";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
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
    in {
      packages = packages';

      checks = {
        nixpkgs-lint = pkgs.runCommand "nixpkgs-lint-check" {} ''
          ${lintBin} ${self}
          touch $out
        '';
      };
    })
    // {
      nixosModules.kubernetes = ./modules;
    };
}
