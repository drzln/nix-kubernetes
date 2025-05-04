{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  version = "1.17.3";
in
  buildGoModule {
    pname = "cilium-health";
    inherit version;
    src = fetchFromGitHub {
      owner = "cilium";
      repo = "cilium";
      rev = "v${version}";
      sha256 = "sha256-dHdpVXTHLh7UjBXgKMeM0l8Dl555zY8IN65nEtbtycA=";
    };
    vendorHash = null; # build → copy printed hash here
    subPackages = ["cilium-health"];
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X github.com/cilium/cilium/pkg/version.Version=v${version}"
    ];
    doCheck = false;
  }
