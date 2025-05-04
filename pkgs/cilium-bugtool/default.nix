{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  # Keep in lock-step with the rest of your Cilium stack
  version = "1.15.4";
in
  buildGoModule {
    pname = "cilium-bugtool";
    inherit version;

    ############################################################################
    # Source  –  Cilium monorepo
    ############################################################################
    src = fetchFromGitHub {
      owner = "cilium";
      repo = "cilium";
      rev = "v${version}";
      # Prefetch once and paste here:
      sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
    };

    ############################################################################
    # Go-module vendoring
    ############################################################################
    vendorHash = null; # build once → copy printed hash

    ############################################################################
    # Build the bugtool binary
    ############################################################################
    subPackages = ["bugtool"];

    env.CGO_ENABLED = "0"; # static build, no libc
    ldflags = [
      "-s"
      "-w"
      "-X github.com/cilium/cilium/pkg/version.Version=v${version}"
    ];

    doCheck = false; # skips integration tests

    meta = with lib; {
      description = "Cilium debug bundle collector";
      homepage = "https://github.com/cilium/cilium";
      license = licenses.asl20;
      maintainers = [maintainers.yourGithubHandle];
      platforms = platforms.linux;
    };
  }
