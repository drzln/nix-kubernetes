{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  # Keep this in lock-step with the agent version you deploy
  version = "1.17.3";
in
  buildGoModule {
    pname = "cilium-operator";
    inherit version;

    ############################################################################
    # Source: github.com/cilium/cilium
    ############################################################################
    src = fetchFromGitHub {
      owner = "cilium";
      repo = "cilium";
      rev = "v${version}";
      # Replace after: nix-prefetch-url --type sha256 https://github.com/cilium/cilium/archive/refs/tags/v1.15.4.tar.gz
      sha256 = "sha256-dHdpVXTHLh7UjBXgKMeM0l8Dl555zY8IN65nEtbtycA=";
    };

    ############################################################################
    # Go-module vendoring (first build prints the real hash)
    ############################################################################
    vendorHash = null;

    ############################################################################
    # Build ONLY the operator’s main package
    ############################################################################
    subPackages = ["operator"]; # <repo>/operator/cmd/main.go

    # Static build (no CGO / libc dependency)
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X github.com/cilium/cilium/pkg/version.Version=v${version}"
    ];

    doCheck = false; # upstream integration tests need a running cluster

    meta = with lib; {
      description = "Cilium Kubernetes operator (cluster-wide controller)";
      homepage = "https://github.com/cilium/cilium";
      license = licenses.asl20;
      maintainers = [maintainers.yourGithubHandle];
      platforms = platforms.linux;
    };
  }
