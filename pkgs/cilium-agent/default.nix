{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  # Pick the Cilium release you run in the cluster
  version = "1.15.4";
in
  buildGoModule {
    pname = "cilium-agent";
    inherit version;

    ############################################################################
    # Source: github.com/cilium/cilium
    ############################################################################
    src = fetchFromGitHub {
      owner = "cilium";
      repo = "cilium";
      rev = "v${version}";
      # run `nix-prefetch-url --type sha256 <url>` once and paste the hash:
      sha256 = "sha256-dHdpVXTHLh7UjBXgKMeM0l8Dl555zY8IN65nEtbtycA=";
    };

    ############################################################################
    # Go-module vendoring (fill after first build)
    ############################################################################
    vendorHash = null; # let the first build print the correct hash

    ############################################################################
    # Build only the agent’s main package
    #   main.go lives in daemon/cmd/
    ############################################################################
    subPackages = ["daemon/cmd"];

    # produce a fully-static binary
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X github.com/cilium/cilium/pkg/version.Version=v${version}"
    ];

    doCheck = false; # integration tests require privileged env

    meta = with lib; {
      description = "Cilium datapath daemon (node agent)";
      homepage = "https://github.com/cilium/cilium";
      license = licenses.asl20;
      maintainers = [maintainers.yourGithubHandle];
      platforms = platforms.linux;
    };
  }
