{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  # Keep this aligned with the Cilium datapath you plan to deploy.
  version = "0.15.16";
in
  buildGoModule {
    pname = "cilium-cli";
    inherit version;

    ############################################################################
    # Source
    ############################################################################
    src = fetchFromGitHub {
      owner = "cilium";
      repo = "cilium-cli";
      rev = "v${version}";
      # First run: set to lib.fakeHash or leave null, prefetch to fill in
      sha256 = "sha256-nTVjgNMnB6775ubzK7ezOxR5Z0z5PBxx88CxtbxGxrY=";
    };

    ############################################################################
    # Go vendor hash
    ############################################################################
    vendorHash = null; # build once → copy printed hash here

    # The CLI’s main package lives in ./cmd/cilium
    subPackages = ["."];

    # Static, stripped binary
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X github.com/cilium/cilium-cli/internal/cli/cmd.Version=v${version}"
    ];

    doCheck = false;

    meta = with lib; {
      description = "Cilium command-line client";
      homepage = "https://github.com/cilium/cilium-cli";
      license = licenses.asl20;
      maintainers = [maintainers.yourGithubHandle];
      platforms = platforms.linux;
    };
  }
