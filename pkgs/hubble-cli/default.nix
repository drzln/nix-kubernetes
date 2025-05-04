{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  # Latest stable CLI release as of May 2025
  version = "0.13.2";
in
  buildGoModule {
    pname = "hubble-cli";
    inherit version;

    ############################################################################
    # Source  –  separate hubble repository
    ############################################################################
    src = fetchFromGitHub {
      owner = "cilium";
      repo = "hubble";
      rev = "v${version}";
      # First time:  nix-prefetch-url --type sha256 \
      #              https://github.com/cilium/hubble/archive/refs/tags/v0.13.2.tar.gz
      sha256 = "sha256-0SCuQzRwluowF48lzyLxY+0rvTOyDbpkMI7Iwb6GHJo=";
    };

    ############################################################################
    # Vendored Go modules
    ############################################################################
    vendorHash = null; # build once → copy printed hash here

    ############################################################################
    # Build the CLI (main.go is at repo root)
    ############################################################################
    subPackages = ["."];

    # fully static
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X github.com/cilium/hubble/pkg/version.Version=v${version}"
    ];

    doCheck = false; # unit tests need CAP_NET_RAW / privileged net

    meta = with lib; {
      description = "Hubble flow-observability command-line interface";
      homepage = "https://github.com/cilium/hubble";
      license = licenses.asl20;
      maintainers = [maintainers.yourGithubHandle];
      platforms = platforms.linux;
    };
  }
