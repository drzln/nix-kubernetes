{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  # Keep all Cilium components at the same tag
  version = "1.15.4";
in
  buildGoModule {
    pname = "hubble-relay";
    inherit version;

    ############################################################################
    # Source  –  Cilium monorepo
    ############################################################################
    src = fetchFromGitHub {
      owner = "cilium";
      repo = "cilium";
      rev = "v${version}";
      # run once:  nix-prefetch-url --type sha256 https://github.com/cilium/cilium/archive/refs/tags/v1.15.4.tar.gz
      sha256 = "sha256-dHdpVXTHLh7UjBXgKMeM0l8Dl555zY8IN65nEtbtycA=";
    };

    ############################################################################
    # Go-module vendor hash (fill after first build)
    ############################################################################
    vendorHash = null; # let the first build print it

    ############################################################################
    # Build the relay binary
    ############################################################################
    subPackages = ["hubble-relay"];

    env.CGO_ENABLED = "0"; # fully static
    ldflags = [
      "-s"
      "-w"
      "-X github.com/cilium/cilium/pkg/version.Version=v${version}"
    ];

    doCheck = false; # skips integration tests

    meta = with lib; {
      description = "Cilium Hubble Relay – cluster-wide flow aggregator";
      homepage = "https://github.com/cilium/cilium";
      license = licenses.asl20;
      maintainers = [maintainers.yourGithubHandle];
      platforms = platforms.linux;
    };
  }
