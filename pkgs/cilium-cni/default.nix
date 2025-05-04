{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  # Keep this aligned with the agent / operator version
  version = "1.15.4";
in
  buildGoModule {
    pname = "cilium-cni";
    inherit version;

    ############################################################################
    # Source – Cilium monorepo
    ############################################################################
    src = fetchFromGitHub {
      owner = "cilium";
      repo = "cilium";
      rev = "v${version}";
      # Prefetch once and replace ↓
      sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
    };

    ############################################################################
    # Go-module vendoring
    ############################################################################
    vendorHash = null; # first build prints the correct hash

    ############################################################################
    # Build the CNI plugin package
    ############################################################################
    subPackages = ["plugins/cilium-cni"];

    # produce a static binary
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X github.com/cilium/cilium/pkg/version.Version=v${version}"
    ];

    doCheck = false; # tests require privileged network access

    meta = with lib; {
      description = "Cilium CNI plugin invoked by kubelet";
      homepage = "https://github.com/cilium/cilium";
      license = licenses.asl20;
      maintainers = [maintainers.yourGithubHandle];
      platforms = platforms.linux;
    };
  }
