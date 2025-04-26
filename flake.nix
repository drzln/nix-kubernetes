{
  description = "kubernetes";

  inputs = {
    nixpkgs           .url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils       .url = "github:numtide/flake-utils";
    # statix            .url = "github:srid/statix";
    nixpkgs-lint      .url = "github:nix-community/nixpkgs-lint";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    # statix,
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
    in {
      packages = packages';

      checks = {
        # statix = pkgs.runCommand "statix-check" {} ''
        #   ${statix.defaultPackage.${system} /bin/statix} check ${self}
        #   touch $out
        # '';

        nixpkgs-lint = pkgs.runCommand "nixpkgs-lint-check" {} ''
          ${nixpkgs-lint.defaultPackage.${system} /bin/nixpkgs-lint} ${self}
          touch $out
        '';
      };
    })
    // {
      nixosModules.kubernetes = ./modules;
    };
}
