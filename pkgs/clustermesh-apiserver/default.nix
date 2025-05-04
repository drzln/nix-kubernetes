{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  # Stay in sync with the agent/operator version
  version = "1.15.4";
in
  buildGoModule {
    pname = "clustermesh-apiserver";
    inherit version;

    ############################################################################
    # Source  ── Cilium monorepo
    ############################################################################
    src = fetchFromGitHub {
      owner = "cilium";
      repo = "cilium";
      rev = "v${version}";
      # Prefetch once, paste the SRI hash below
      sha256 = "1q2akgwi1r5xpc2gs7k2k96mfkdq2q9n4f4s3p37gbsm3dd5aspn";
    };

    ############################################################################
    # Go modules
    ############################################################################
    vendorHash = null; # first build prints the real hash

    ############################################################################
    # Build ONLY the clustermesh-apiserver binary
    ############################################################################
    subPackages = ["clustermesh-apiserver"];

    env.CGO_ENABLED = "0"; # static build
    ldflags = [
      "-s"
      "-w"
      "-X github.com/cilium/cilium/pkg/version.Version=v${version}"
    ];

    doCheck = false; # skips large integration tests

    meta = with lib; {
      description = "Cilium ClusterMesh API server for multi-cluster connectivity";
      homepage = "https://github.com/cilium/cilium";
      license = licenses.asl20;
      maintainers = [maintainers.yourGithubHandle];
      platforms = platforms.linux;
    };
  }
