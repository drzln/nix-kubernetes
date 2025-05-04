{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  # Align with the rest of the Cilium stack
  version = "1.15.4";
in
  buildGoModule {
    pname = "cilium-health";
    inherit version;

    ############################################################################
    # Source – Cilium monorepo
    ############################################################################
    src = fetchFromGitHub {
      owner = "cilium";
      repo = "cilium";
      rev = "v${version}";
      # Prefetch once: nix-prefetch-url --type sha256 ... > sha256
      sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
    };

    ############################################################################
    # Vendored Go modules
    ############################################################################
    vendorHash = null; # build → copy printed hash here

    ############################################################################
    # Build the health binary
    ############################################################################
    subPackages = ["cilium-health"];

    env.CGO_ENABLED = "0"; # fully static
    ldflags = [
      "-s"
      "-w"
      "-X github.com/cilium/cilium/pkg/version.Version=v${version}"
    ];

    doCheck = false; # skips integration tests

    meta = with lib; {
      description = "Cilium connectivity-probe daemon & CLI";
      homepage = "https://github.com/cilium/cilium";
      license = licenses.asl20;
      maintainers = [maintainers.yourGithubHandle];
      platforms = platforms.linux;
    };
  }
