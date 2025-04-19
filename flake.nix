{
  description = "kubernetes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
      in {
        packages = with import ./pkgs/etcd pkgs;
        with import ./pkgs/cilium pkgs;
        with import ./pkgs/containerd pkgs; {
          inherit
            etcd
            etcdserver
            etcdctl
            etcdutl
            containerd
            # cilium
            ;
          default = etcd;
        };
      }
    );
}
