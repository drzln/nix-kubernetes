# pkgs/cilium-cli/default.nix
{
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  version = "0.18.3";
in
  buildGoModule {
    pname = "cilium-cli";
    inherit version;
    src = fetchFromGitHub {
      owner = "cilium";
      repo = "cilium-cli";
      rev = "v${version}";
      sha256 = "sha256-9+nNZEXjSoNB/Ftn/CtoBcR/uaD71C1jzDEaEG3Wpb4=";
    };
    vendorHash = null;
    subPackages = ["cmd/cilium"];
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X github.com/cilium/cilium-cli/internal/cli/cmd.Version=v${version}"
    ];
    doCheck = false;
  }
