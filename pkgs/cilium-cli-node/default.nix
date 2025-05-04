{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  # Keep in sync with the agent/operator tag
  version = "1.15.4";
in
  buildGoModule {
    pname = "cilium-nodecli"; # output name; see postInstall below
    inherit version;

    ############################################################################
    # Source – Cilium monorepo
    ############################################################################
    src = fetchFromGitHub {
      owner = "cilium";
      repo = "cilium";
      rev = "v${version}";
      # Prefetch once: nix-prefetch-url --type sha256 \
      #   https://github.com/cilium/cilium/archive/refs/tags/v1.15.4.tar.gz
      sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
    };

    ############################################################################
    # Go-module vendoring
    ############################################################################
    vendorHash = null; # build once → copy printed hash here

    ############################################################################
    # Build the CLI (main.go in cilium/)
    ############################################################################
    subPackages = ["cilium"];

    env.CGO_ENABLED = "0"; # static binary
    ldflags = [
      "-s"
      "-w"
      "-X github.com/cilium/cilium/pkg/version.Version=v${version}"
    ];

    # rename binary to plain “cilium” for muscle memory
    postInstall = ''
      mv "$out/bin/cilium-nodecli" "$out/bin/cilium"
    '';

    doCheck = false;

    meta = with lib; {
      description = "On-node Cilium debug CLI (talks to local agent)";
      homepage = "https://github.com/cilium/cilium";
      license = licenses.asl20;
      maintainers = [maintainers.yourGithubHandle];
      platforms = platforms.linux;
    };
  }
