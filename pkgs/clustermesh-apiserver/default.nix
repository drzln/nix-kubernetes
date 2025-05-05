# pkgs/clustermesh-apiserver/default.nix
{
  buildGoModule,
  fetchFromGitHub,
  ...
}: let
  version = "1.15.4";
in
  buildGoModule {
    pname = "clustermesh-apiserver";
    inherit version;
    src = fetchFromGitHub {
      owner = "cilium";
      repo = "cilium";
      rev = "v${version}";
      sha256 = "sha256-dHdpVXTHLh7UjBXgKMeM0l8Dl555zY8IN65nEtbtycA=";
    };
    vendorHash = null;
    subPackages = ["clustermesh-apiserver"];
    env.CGO_ENABLED = "0";
    ldflags = [
      "-s"
      "-w"
      "-X github.com/cilium/cilium/pkg/version.Version=v${version}"
    ];
    doCheck = false;
  }
