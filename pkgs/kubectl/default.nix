{
  lib,
  buildGoModule,
  fetchFromGitHub,
  stdenv,
  pkgs,
  ...
}: let
  # Match the cluster control-plane version
  version = "1.30.1";
in
  buildGoModule rec {
    pname = "kubectl";
    inherit version;

    ############################################################################
    # Source
    ############################################################################
    src = fetchFromGitHub {
      owner = "kubernetes";
      repo = "kubernetes";
      rev = "v${version}";
      # Fill with real SRI after first nix-prefetch
      sha256 = "sha256-nTVjgNMnB6775ubzK7ezOxR5Z0z5PBxx88CxtbxGxrY=";
    };

    ############################################################################
    # Go module vendoring (fill after first build)
    ############################################################################
    vendorHash = null;

    ############################################################################
    # Build only the CLI from the monorepo
    ############################################################################
    subPackages = ["cmd/kubectl"];

    # Produce a tiny static binary
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X=k8s.io/component-base/version.gitVersion=v${version}"
      "-X=k8s.io/component-base/version.gitTreeState=clean"
    ];

    doCheck = false;

    meta = with lib; {
      description = "Kubernetes command-line interface";
      homepage = "https://github.com/kubernetes/kubernetes";
      license = licenses.asl20;
      platforms = platforms.linux;
      maintainers = [maintainers.yourGithubHandle];
    };
  }
