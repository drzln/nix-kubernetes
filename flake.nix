{
  description = "drzzln – custom Kubernetes builds & NixOS module";

  inputs = {
    nixpkgs     .url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils .url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = import ./overlays;
          config = {allowUnfree = true;};
        };
        call = path: pkgs.callPackage path {};
        kubelet = call ./pkgs/kubelet;
        kubectl = call ./pkgs/kubectl;
        kube-apiserver = call ./pkgs/kube-apiserver;
        kube-controller-manager = call ./pkgs/kube-controller-manager;
        kube-scheduler = call ./pkgs/kube-scheduler;
        etcdserver = call ./pkgs/etcd/server.nix;
        etcdctl = call ./pkgs/etcd/ctl.nix;
        etcdutl = call ./pkgs/etcd/utl.nix;
        etcd = call ./pkgs/etcd;
        containerd = call ./pkgs/containerd;
        runc = call ./pkgs/runc;
        # cilium-cli = call ./pkgs/cilium;
      in {
        packages = rec {
          inherit
            kubelet
            kubectl
            kube-apiserver
            kube-controller-manager
            kube-scheduler
            etcdserver
            containerd
            # cilium-cli
            etcdctl
            etcdutl
            etcd
            runc
            ;
          # default = cilium-cli;
        };
      }
    )
    // {
      # nixosModules.kubernetes = import ./modules/kubernetes;
    };
}
