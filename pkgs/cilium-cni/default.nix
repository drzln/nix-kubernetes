# pkgs/cilium-cni/default.nix
{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  version = "1.17.3";
in
  buildGoModule {
    pname = "cilium-cni";
    inherit version;
    src = fetchFromGitHub {
      owner = "cilium";
      repo = "cilium";
      rev = "v${version}";
      sha256 = "sha256-aHdpVXTHLh7UjBXgKMeM0l8Dl555zY8IN65nEtbtycA=";
    };
    vendorHash = null;
    subPackages = ["plugins/cilium-cni"];
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X github.com/cilium/cilium/pkg/version.Version=v${version}"
    ];
    doCheck = false;
  }
