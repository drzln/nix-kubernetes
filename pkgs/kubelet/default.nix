{
  lib,
  buildGoModule,
  fetchFromGitHub,
  stdenv,
  pkgs,
  ...
}: let
  # Bump this to the Kubernetes version you want
  version = "1.30.1";
in
  buildGoModule rec {
    pname = "kubelet";
    inherit version;

    ############################################################################
    # Source
    ############################################################################
    src = fetchFromGitHub {
      owner = "kubernetes";
      repo = "kubernetes";
      rev = "v${version}";
      # Prefetch once and replace:
      sha256 = "sha256-nTVjgNMnB6775ubzK7ezOxR5Z0z5PBxx88CxtbxGxrY=";
    };

    ############################################################################
    # Go module vendor hash – leave null on first commit
    ############################################################################
    vendorHash = null; # build → copy hash → rebuild

    ############################################################################
    # Build only the kubelet binary from the monorepo
    ############################################################################
    subPackages = ["cmd/kubelet"];

    # Fully static, stripped binary
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X=k8s.io/component-base/version.gitVersion=v${version}"
      "-X=k8s.io/component-base/version.gitTreeState=clean"
    ];

    doCheck = false;

    meta = with lib; {
      description = "Kubernetes node agent (kubelet)";
      homepage = "https://github.com/kubernetes/kubernetes";
      license = licenses.asl20;
      platforms = platforms.linux;
      maintainers = [maintainers.yourGithubHandle];
    };
  }
