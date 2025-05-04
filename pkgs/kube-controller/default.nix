{
  lib,
  buildGoModule,
  fetchFromGitHub,
  stdenv,
  pkgs,
  ...
}: let
  # Kubernetes release tag you want
  version = "1.30.1";
in
  buildGoModule rec {
    pname = "kube-controller-manager";
    inherit version;

    ############################################################################
    # Source
    ############################################################################
    src = fetchFromGitHub {
      owner = "kubernetes";
      repo = "kubernetes";
      rev = "v${version}";
      # Prefetch once, replace this placeholder
      sha256 = "sha256-nTVjgNMnB6775ubzK7ezOxR5Z0z5PBxx88CxtbxGxrY=";
    };

    ############################################################################
    # Go module vendoring
    ############################################################################
    vendorHash = null; # build once, copy real hash back here

    ############################################################################
    # Build only this component from the monorepo
    ############################################################################
    subPackages = ["cmd/kube-controller-manager"];

    # Produce a small static binary
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X=k8s.io/component-base/version.gitVersion=v${version}"
      "-X=k8s.io/component-base/version.gitTreeState=clean"
    ];

    doCheck = false; # integration tests heavy / require Docker

    meta = with lib; {
      description = "Kubernetes controller manager component";
      homepage = "https://github.com/kubernetes/kubernetes";
      license = licenses.asl20;
      platforms = platforms.linux;
      maintainers = [maintainers.yourGithubHandle];
    };
  }
