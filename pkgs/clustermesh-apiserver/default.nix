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
      sha256 = "sha256-dHdpVXTHLh7UjBXgKMeM0l8Dl555zY8IN65nEtbtycA=";
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
