# pkgs/hubble-cli/default.nix
{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  version = "0.17.3";
in
  buildGoModule {
    pname = "hubble-cli";
    inherit version;
    src = fetchFromGitHub {
      owner = "cilium";
      repo = "hubble";
      rev = "v${version}";
      sha256 = "sha256-0SCuQzRwluowF48lzyLxY+0rvTOyDbpkMI7Iwb6GHJo=";
    };
    vendorHash = null;
    subPackages = ["."];
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X github.com/cilium/hubble/pkg/version.Version=v${version}"
    ];
    doCheck = false;
  }
