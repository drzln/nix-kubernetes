{
  description = "kubernetes";

  inputs = {
    nixpkgs      .url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils  .url = "github:numtide/flake-utils";
    nixpkgs-lint .url = "github:nix-community/nixpkgs-lint";
    statix = {
      url = "github:oppiliappan/statix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    colmena = {
      url = "github:zhaofengli/colmena?=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    statix,
    nixpkgs-lint,
    colmena,
    ...
  } @ inputs: let
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
        colmena = pkgs.runCommand "colmena-check" {} ''
          ${pkgs.colmena}/bin/colmena build \
            -- --flake ${./hive.nix}
          touch $out
        '';
      };

      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixpkgs-fmt
          git
          openssh
          colmena.packages.${system}.colmena
        ];
      };
    })
    // {
      nixosModules.kubernetes = ./modules;

      colmenaHive = import ./hive.nix {inherit inputs;};
    };
}
