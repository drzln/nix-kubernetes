{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  # Current stable runc – change when you need a new release
  version = "1.1.12";
in
  buildGoModule {
    pname = "runc";
    inherit version;

    ############################################################################
    # Source
    ############################################################################
    src = fetchFromGitHub {
      owner = "opencontainers";
      repo = "runc";
      rev = "v${version}";
      # First run: use lib.fakeHash, prefetch or let nix print the real one
      sha256 = "sha256-nTVjgNMnB6775ubzK7ezOxR5Z0z5PBxx88CxtbxGxrY=";
    };

    ############################################################################
    # Go modules
    ############################################################################
    vendorHash = null; # build once → copy printed hash back here

    # runc’s main package lives in the repo root
    subPackages = ["."];

    # Produce a static, stripped binary
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X main.gitCommit=${version}"
      "-X main.version=${version}"
    ];

    doCheck = false;

    meta = with lib; {
      description = "CLI tool for spawning and running OCI containers";
      homepage = "https://github.com/opencontainers/runc";
      license = licenses.asl20;
      maintainers = [maintainers.yourGithubHandle];
      platforms = platforms.linux;
    };
  }
