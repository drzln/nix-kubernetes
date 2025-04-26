{
  description = "kubernetes";

  inputs = {
    nixpkgs      .url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils  .url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }: let
    overlayList = import ./overlays;
  in
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = overlayList;
        };
      in {
        packages = with import ./pkgs/etcd pkgs;
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
      }
    )
    // {
      nixosModules.kubernetes = ./modules;
    };
}
